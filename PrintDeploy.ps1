#Requires -Modules PrintManagement -RunAsAdministrator 

param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Printer')]
    # Name given to the printer.
    [String]$Name,

    [Parameter(Mandatory = $true, ParameterSetName = 'Printer')]
    # Name of the driver.
    [String]$DriverName,

    [Parameter(Mandatory = $true, ParameterSetName = 'Printer')]
    # Path to the INF file to install the driver.
    [System.IO.FileInfo]$DriverPath,

    [Parameter(Mandatory = $true, ParameterSetName = 'Printer')]
    # IP on which the printer can be found and port that will be configured on the device.
    # If an existing port already has the given IP, it will be used.
    [String]$IP,

    [Parameter(Mandatory = $true, ParameterSetName = 'File')]
    # File containing the configuration for deploying multiple printers at once.
    [System.IO.FileInfo]$Path
)

# Creates a log file in the Windows temp directory.
$LogPath = "$env:windir\Temp\$((Split-Path $PSCommandPath -Leaf).Replace('.ps1','.log'))"
$Global:Parameters = @{
    FilePath = $LogPath
    Encoding = "utf8"
    Append   = $true
}

function Test-PnpPrinterDriver {
    param(
        [Parameter(Mandatory = $true)]
        # Name of the driver file.
        [String]$Driver
    )
    $Driver = Split-Path -Path $Driver -Leaf
    if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM") {
        $pnputilPath = "C:\Windows\sysnative\pnputil.exe"
        # Source: https://www.itninja.com/question/pnputil-exe-is-not-recognized-as-the-name-of-a-cmdlet-only-through-kace
    }
    else {
        $pnputilPath = "C:\Windows\System32\pnputil.exe"
    }
    $PnpPrinterDrivers = & $pnputilPath /enum-drivers
    if ($PnpPrinterDrivers | Where-Object { $_ -match $Driver }) {
        return $true
    }
    else {
        return $false
    }

    <#
        .SYNOPSIS
        Checks the driver repository for given file.

        .DESCRIPTION
        List the installed printer drivers through pnputil.exe and return $true if a driver
        with the same name can be found.        

        .INPUTS
        None. You can't pipe objects to Test-PnpPrinterDriver.

        .OUTPUTS
        None. The script will return a bool confirming if the driver is present on the current machine.

        .EXAMPLE
        PS> Test-PnpPrinterDriver .\Drivers\KOAWUJ__.inf
        True
    #>
}

function Add-NetworkPrinter {
    param(
        [Parameter(Mandatory = $true)]
        # Name given to the printer.
        [String]$Name,

        [Parameter(Mandatory = $true)]
        # Name of the driver.
        [String]$DriverName,

        [Parameter(Mandatory = $true)]
        # Path to the INF file to install the driver.
        [System.IO.FileInfo]$DriverPath,

        [Parameter(Mandatory = $true)]
        # IP on which the printer can be found and port that will be configured on the device.
        # If an existing port already has the given IP, it will be used.
        [String]$IP
    )

    "`n$(Get-Date -Format 'yyyyMMdd - HH:mm:ss') - Start printer install : $Name" | Out-File @Global:Parameters

    # Replaces relative paths with fully defined ones.
    if ($DriverPath -match '\.\\') {
        $DriverPath = $DriverPath.Replace('.\', "$PSScriptRoot\")
        "Relative path replaced with literal path : $DriverPath" | Out-File @Global:Parameters
    }

    "Attempting to add printer : $Name" | Out-File @Global:Parameters

    # Port configuration.
    $IPs = Get-PrinterPort 
    if ($IPs.PrinterHostAddress -notcontains $IP) {
        "Port added for : $IP" | Out-File @Global:Parameters
        Add-PrinterPort -Name $IP -PrinterHostAddress $IP
        $Port = $IP
    }
    else {
        "Port $IP already present" | Out-File @Global:Parameters
        $Port = $IPs[$IPs.PrinterHostAddress.IndexOf($IP)].Name
    }

    # Driver configuration.
    if (Test-PnpPrinterDriver $DriverPath) {
        "Driver file `"$DriverPath`" already present in repository." | Out-File @Global:Parameters
    }
    else {
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM") {
            $pnputilPath = "C:\Windows\sysnative\pnputil.exe"
            # Source: https://www.itninja.com/question/pnputil-exe-is-not-recognized-as-the-name-of-a-cmdlet-only-through-kace
        }
        else {
            $pnputilPath = "C:\Windows\System32\pnputil.exe"
        }
        "Driver file `"$DriverPath`" not found in repository.`nAttempting to add it to printer driver repository." | Out-File @Global:Parameters
        Start-Process -FilePath $pnputilPath -ArgumentList "/add-driver $DriverPath" -Wait
        if (Test-PnpPrinterDriver $DriverPath) {
            "Driver successfully installed." | Out-File @Global:Parameters
        }
        else {
            "Driver file $DriverFile not found in repository post installation. Exiting with retry code." | Out-File @Global:Parameters
            return 1618
        }
    }

    $Drivers = Get-PrinterDriver
    if ($Drivers.Name -notcontains $DriverName) {
        Add-PrinterDriver -Name $DriverName
        "Driver `"$DriverName`" added to the printer driver repository" | Out-File @Global:Parameters 
    }
    else {
        "Driver `"$DriverName`" already present" | Out-File @Global:Parameters
    }

    # Printer configuration.
    $Printers = Get-Printer
    if ($Printers.Name -notcontains $Name) {
        "Printer $Name has been added" | Out-File @Global:Parameters
        Add-Printer -Name $Name -DriverName $DriverName -PortName $Port
    }
    else {
        "Printer $Name is already present" | Out-File @Global:Parameters
    }
    return


    <#
        .SYNOPSIS
        Adds a network printer to the current computer.

        .DESCRIPTION
        Verifies if the required port and drivers are present on the device before
        trying to add the requested printer to the device.

        .INPUTS
        None. You can't pipe objects to Add-NetworkPrinter.

        .OUTPUTS
        The script will create a log file in the script's current directory named after the script.

        .EXAMPLE
        PS> Add-NetworkPrinter -Name "Admin Printer" -DriverName "KONICA MINOLTA Universal PCL" -DriverPath ".\Drivers\KOAWUJ__.inf" -IP "10.10.0.1" -PrinterSettings ".\Admin_color.dat"

        .LINK
        Online version: https://github.com/AlCpwnd/PrintDeploy

        .LINK
        Get-Printer

        .LINK
        Get-PrinterDriver

        .LINK
        Get-PrinterPort
    #>
}

switch ($PsCmdlet.ParameterSetName) {
    "Printer" {
        $params = @{
            Name        = $Name
            DriverName  = $DriverName
            DriverPath  = $DriverPath
            IP          = $IP
            OutVariable = 'ExitCode'
        }
        if ($PrintingSettings) {
            $params['PrintingSettings'] = $PrintingSettings
        }
        Add-NetworkPrinter @params
    }
    "File" {
        # Replaces relative paths with fully defined ones.
        if ($Path -match '\.\\') {
            $Path = $Path.Replace('.\', "$PSScriptRoot\")
            "Relative path replaced with literal path : $Path" | Out-File @Global:Parameters
        }
        "Recovering printers from config file : $Path" | Out-File @Global:Parameters
        Import-Csv -Path $Path -OutVariable Printers | Out-File @Global:Parameters
        $ExitCode = foreach ($Printer in $Printers) {
            $params = @{
                Name        = $Name
                DriverName  = $DriverName
                DriverPath  = $DriverPath
                IP          = $IP
            }
            if ($PrintingSettings) {
                $params['PrintingSettings'] = $PrintingSettings
            }
            Add-NetworkPrinter @params
        }
    }
}

if ($ExitCode) {
    exit $ExitCode
}


<#
    .SYNOPSIS
    Adds a network printer to the current computer.

    .DESCRIPTION
    Verifies if the required port and drivers are present on the device before trying to add the requested printer to the device.
    If a printing configuration file is referenced, the script will attempt to apply it to the printer.

    .INPUTS
    None. You can't pipe objects to Add-NetworkPrinter.

    .OUTPUTS
    The script will create a log file in the current 

    .EXAMPLE
    PS> Add-NetworkPrinter -Name "Admin Printer" -DriverName "KONICA MINOLTA Universal PCL" -DriverPath ".\Drivers\KOAWUJ__.inf" -IP "10.10.0.1" -PrinterSettings ".\KonicaAdmin_color.dat"

    .EXAMPLE
    PS> Add-NetworkPrinter -Path .\Printers.csv

    .LINK
    Online version: https://github.com/AlCpwnd/PrintDeploy

    .LINK
    Get-Printer

    .LINK
    Get-PrinterDriver

    .LINK
    Get-PrinterPort

    .LINK
    pnputil.exe
#>