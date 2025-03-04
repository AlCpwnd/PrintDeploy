#Requires -Modules PrintManagement -RunAsAdministrator 

param(
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$Name,
    [Parameter(ParameterSetName='Printer')][String]$DriverName,
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverPath,
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$IP,
    [Parameter(Mandatory,ParameterSetName='File')][String]$Path
)

# Creates a log file in the Windows temp directory.
$LogPath = "$env:windir\Temp\$((Split-Path $PSCommandPath -Leaf).Replace('.ps1','.log'))"
$Global:Parameters = @{
    FilePath = $LogPath
    Encoding = "utf8"
    Append = $true
}

function Add-NetworkPrinter {
    param(
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$Name,
        [Parameter(ParameterSetName='Printer')][AllowEmptyString()][String]$DriverName,
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverPath,
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$IP
    )

    "`n$(Get-Date -Format 'yyyyMMdd - HH:mm:ss' ) - Start printer install : $Name" | Out-File @Global:Parameters

    # Replaces relative paths with fully defined ones.
    if($DriverPath -match '\.\\'){
        $DriverPath = $DriverPath.Replace('.\',"$PSScriptRoot\")
        "Relative path replaced with literalpath : $DriverPath" | Out-File @Global:Parameters
    }

    # Recovers the driver's name from the INF file.
    if(!$DriverName){
        "No Driver Name given, recovering it from the INF file." | Out-File @Global:Parameters
        $DriverName = (Get-Content -Path $DriverPath | Where-Object{$_ -match "DiskName="}).Replace('"','').Split('=')[1]
        "DriverName found : $DriverName" | Out-File @Global:Parameters
    }

    "Attempting to add printer : $Name" | Out-File @Global:Parameters

    # Portconfiguration.
    $IPs = Get-PrinterPort 
    if($IPs.PrinterHostAddress -notcontains $IP){
        "Port added for : $IP" | Out-File @Global:Parameters
        Add-PrinterPort -Name $IP -PrinterHostAddress $IP
        $Port = $IP
    }else{
        "Port $IP already present" | Out-File @Global:Parameters
        $Port = $IPs[$IPs.PrinterHostAddress.IndexOf($IP)].Name
    }

    # Driverconfiguration.
    $Drivers = Get-PrinterDriver
    if($Drivers.Name -notcontains $DriverName){
        "Driver added for : $DriverName" | Out-File @Global:Parameters
        & pnputil.exe /a $DriverPath
        Add-PrinterDriver $DriverName
    }else{
        "Driver $DriverName already present" | Out-File @Global:Parameters
    }

    # PrinterConfiguration.
    $Printers = Get-Printer
    if($Printers.Name -notcontains $Name){
        "Printer $Name has been added" | Out-File @Global:Parameters
        Add-Printer -Name $Name -DriverName $DriverName -PortName $Port
    }else{
        "Printer $Name is already present" | Out-File @Global:Parameters
    }
    return

    <#
        .SYNOPSIS
        Adds a network printer to the current computer.

        .DESCRIPTION
        Verifies if the required port and drivers are present on the device before
        trying to add the requested printer to the device.

        .PARAMETER Name
        Name given to the printer.

        .PARAMETER DriverName
        Name of the driver.

        .PARAMETER DriverPath
        Path to the INF file to install the driver.

        .PARAMETER IP
        IP on which the printer can be found and port that will be configured on the device.

        .INPUTS
        None. You can't pipe objects to Add-NetworkPrinter.

        .OUTPUTS
        The script will create a log file in the script's current directory named after the script.

        .EXAMPLE
        PS> Add-NetworkPrinter -Name "Admin Printer" -DriverName "KONICA MINOLTA Universal PCL" -DriverPath ".\Drivers\KOAWUJ__.inf" -IP "10.10.0.1"

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
        Add-NetworkPrinter -Name $Name -DriverName $DriverName -DriverPath $DriverPath -IP $IP
    }
    "File" {
        # Replaces relative paths with fully defined ones.
        if($Path -match '\.\\'){
            $Path = $Path.Replace('.\',"$PSScriptRoot\")
            "Relative path replaced with literalpath : $Path" | Out-File @Global:Parameters
        }
        "Recovering printers from config file : $Path"
        Import-Csv -Path $Path -OutVariable Printers | Out-File @Global:Parameters
        foreach($Printer in $Printers){
            Add-NetworkPrinter -Name $Printer.Name -DriverName $Printer.DriverName -DriverPath $Printer.DriverPath -IP $Printer.IP
        }
    }
}



<#
    .SYNOPSIS
    Adds a network printer to the current computer.

    .DESCRIPTION
    Verifies if the required port and drivers are present on the device before
    trying to add the requested printer to the device.

    .PARAMETER Name
    Name given to the printer.

    .PARAMETER DriverName
    Name of the driver.

    .PARAMETER DriverPath
    Path to the INF file to install the driver.

    .PARAMETER IP
    IP on which the printer can be found and port that will be configured on the device.

    .PARAMETER File
    CSV configuration file containing the multiple printers you want to add to the current device.

    .INPUTS
    None. You can't pipe objects to Add-NetworkPrinter.

    .OUTPUTS
    The script will create a log file in the current 

    .EXAMPLE
    PS> Add-NetworkPrinter -Name "Admin Printer" -DriverName "KONICA MINOLTA Universal PCL" -DriverPath ".\Drivers\KOAWUJ__.inf" -IP "10.10.0.1"

    .LINK
    Online version: https://github.com/AlCpwnd/PrintDeploy

    .LINK
    Get-Printer

    .LINK
    Get-PrinterDriver

    .LINK
    Get-PrinterPort
#>