try{
    Get-Printer -Name '<PrinterName>' -ErrorAction Stop
    $ExitCode = 0
}catch{
    $ExitCode = 1
}

exit $ExitCode