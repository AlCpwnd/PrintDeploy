$printerName = '<Printer Name>'

try{
    Get-Printer -Name $printerName -ErrorAction Stop
    $ExitCode = 0
}catch{
    $ExitCode = 1
}

exit $ExitCode


<#
    .SYNOPSIS
    Script meant for confirming printer installation.

    .DESCRIPTION
    Modify the "$printerName" variable to correspond to
    the printer you want to confirm the installation of,
    and upload it to the detection rules of your app.

    .LINK
    Get-Printer
#>