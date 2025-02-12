#Requires -Modules PrintManagement -RunAsAdministrator 

param(
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$Name,
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverName,
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverPath,
    [Parameter(Mandatory,ParameterSetName='Printer')][String]$IP,
    [Parameter(Mandatory,ParameterSetName='File')][String]$Path
)

function Add-NetworkPrinter {
    param(
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$Name,
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverName,
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$DriverPath,
        [Parameter(Mandatory,ParameterSetName='Printer')][String]$IP
    )

    $LogPath = $PSCommandPath.Replace(".ps1",".log")
    $Parameters = @{
        FilePath = $LogPath
        Encoding = "utf8"
        Append = $true
    }

    "Attempting to add printer : $Name" | Out-File @Parameters

    # Portconfiguration.
    $IPs = Get-PrinterPort 
    if($IPs.PrinterHostAddress -notcontains $IP){
        "Port added for : $IP" | Out-File @Parameters
        Add-PrinterPort -Name $IP -PrinterHostAddress $IP
        $Port = $IP
    }else{
        "Port $IP already present" | Out-File @Parameters
        $Port = $IPs[$IPs.PrinterHostAddress.IndexOf($IP)].Name
    }

    # Driverconfiguration.
    $Drivers = Get-PrinterDriver
    if($Drivers.Name -notcontains $DriverName){
        "Driver added for : $DriverName" | Out-File @Parameters
        & pnputil.exe /a $DriverPath
        Add-PrinterDriver $DriverName
    }else{
        "Driver $DriverName already present" | Out-File @Parameters
        $Driver = $Drivers.Name[$Drivers.Name.IndexOf($DriverName)]
    }

    # PrinterConfiguration.
    $Printers = Get-Printer
    if($Printers.Name -notcontains $Name){
        "Printer $Name has been added" | Out-File @Parameters
        Add-Printer -Name $Name -DriverName $Driver -PortName $Port
    }else{
        "Printer $Name is already present" | Out-File @Parameters
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
        $Printers = Import-Csv -Path $Path
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