#Requires -Modules PrintManagement

param(
    [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    # Name of the printer.
    [System.String]$Name,

    [Parameter()]
    [ValidateScript({
            if (Test-Path -Path $_ -IsValid -Filter "*.dat") {
                return $true
            }
            else {
                throw "Invalid file format. Please only use '.dat' files."
            }
        })]
    # Name to give to the exported file.
    [System.IO.FileInfo]$ConfigFile
)
begin {
    if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM") {
        $system32Path = "C:\Windows\sysnative"
        # Source: https://www.itninja.com/question/pnputil-exe-is-not-recognized-as-the-name-of-a-cmdlet-only-through-kace
    }
    else {
        $system32Path = "C:\Windows\System32"
    }
    
    $runDllPath = $system32Path + "\rundll32.exe"
    $dllPath = $system32Path + "\printui.dll"
}
process {
    try {
        Write-Verbose "Checking local printer for: $Name"
        Get-Printer -Name $Name -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Host "Could not find a corresponding printer: $Name" -ForegroundColor Red
        return
    }
    if (-not $ConfigFile) {
        Write-Verbose "Checking export file name availability"
        $ConfigFile = (Get-Location).Path + "\$Name.dat"
        $i = 1
        while (Test-Path -Path $ConfigFile) {
            Write-Verbose $ConfigFile
            if ($ConfigFile -match '\(\d+\)') {
                $i++
                $ConfigFile = $ConfigFile -replace '\(\d+\)', "($i)"
            }
            else {
                $ConfigFile = $ConfigFile -replace "\.dat", "($i).dat"
            }
        }
    }
    
    Write-Verbose "Starting export"
    Start-Process -FilePath $runDllPath -ArgumentList "$dllPath,PrintUIEntry /Ss /n `"$Name`" /a `"$ConfigFile`"" -Wait
    $fileSize = Get-ChildItem -Path $ConfigFile
    if ($fileSize -eq 0) {
        Write-Host "Failed to export printer settings for: $Name" -ForegroundColor Red
    }
    else {
        Write-Host "Printer config file exported: $ConfigFile" -ForegroundColor Green
    }
    Remove-Variable -Name ConfigFile
}

<#
    .SYNOPSIS
    Exports the printer's printing preferences.

    .DESCRIPTION
    Uses the 'printui.dll' library to export the given printer's configuration into a dat file.

    .NOTES
    If no file name is given, the file will be named after the target printer.

    .INPUTS
    The printer names can be piped into the script.

    .OUTPUTS
    A dat-file containing the printer's printing preferences.

    .EXAMPLE
    PS> .\ExportPrinterSettings.ps1 -Name "HP Home Printer" -ConfigFile "PrinterConfig.dat"
    Printer config file exported: C:\Users\john.doe\Desktop\PrinterConfig.dat

    .EXAMPLE
    PS> .\ExportPrinterSettings.ps1 -Name "HP Home Printer"
    Printer config file exported: C:\Users\john.doe\Desktop\HP Home Printer.dat

    .EXAMPLE
    PS> Get-Printer | .\ExportPrinterSettings.ps1
    Printer config file exported: C:\Users\john.doe\Desktop\HP Home Printer.dat
    Printer config file exported: C:\Users\admin\Git\PrintDeploy\Microsoft XPS Document Writer.dat
    Printer config file exported: C:\Users\admin\Git\PrintDeploy\Microsoft Print to PDF.dat
    Printer config file exported: C:\Users\admin\Git\PrintDeploy\Fax.dat
#>

