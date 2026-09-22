#Requires -Modules PrintManagement,Dism -RunAsAdministrator

param(
    [Parameter(Mandatory = $true)]
    [String]$Provider
)

$params = @{
    FilePath = "$env:windir\Temp\DriverCleanup.log"
    Encoding = "utf8"
    Append   = $true
}

"Script Start: {0}" -f (Get-Date -Format 'dd/MM/yyyy - HH:mm:ss') | Out-File @params

$returnCode = 0

$drivers = Get-WindowsDriver -Online -All
$toBeRemoved = $drivers | Where-Object { $_.ProviderName -eq $Provider }

$printerDriver = Get-PrinterDriver | Where-Object { $_.Manufacturer -eq $Provider }
$affectedPrinters = Get-Printer | Where-Object { $printerDriver.Name -contains $_.DriverName }

foreach ($printer in $affectedPrinters) {
    try{
        Remove-Printer -Name $printer.Name -Confirm:$false -ErrorAction Stop
        "Printer removed: {0}" -f $printer.Name | Out-File @params
    }catch{
        "Failed to remove printer: {0}" -f $printer.Name | Out-File @params
        $returnCode = 1618
    }
}

foreach($driver in $printerDriver){
    try{
        Remove-PrinterDriver -Name $driver.Name -Confirm:$false -ErrorAction Stop
        "Printer driver removed {0}" -f $driver.Name | Out-File @params
    }catch{
        "Failed to remove printer driver {0}" -f $driver.Name | Out-File @params
        $returnCode = 1618
    }
}

if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM") {
    $pnputilPath = "C:\Windows\sysnative\pnputil.exe"
    # Source: https://www.itninja.com/question/pnputil-exe-is-not-recognized-as-the-name-of-a-cmdlet-only-through-kace
}
else {
    $pnputilPath = "C:\Windows\System32\pnputil.exe"
}

if(-not $returnCode){
    foreach($inf in $toBeRemoved){
        Start-Process -FilePath $pnputilPath -ArgumentList "/delete-driver $($inf.Driver)" -Wait
        "Driver removed: {0} - {1}" -f $inf.Driver, $inf.OriginalFileName | Out-File @params
    }
    New-Item -Path "$env:windir\Temp\Cleanup.log"
}

return $returnCode


<#
    .SYNOPSIS
    Script for removing all printer drivers by a specific provider from a device.

    .DESCRIPTION
    Removes all printer drivers from a device that are associated with a specific provide.
    If the driver is associated to a printer, the printer will first be removed before the driver
    removal is attempted.

    .NOTES
    If the script ran without issues, it will create a "Cleanup.log" file within the Windows Temp
    directory.

    .LINK
    Remove-Printer

    .LINK
    Remove-PrinterDriver

    .LINK
    Get-WindowsDriver

    .EXAMPLE
    \DriverCleanup.ps1 -Provider 'KONICA MINOLTA'
#>

