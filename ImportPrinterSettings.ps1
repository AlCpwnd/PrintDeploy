#Requires -Modules PrintManagement -RunAsAdministrator

param(
    [Parameter(Mandatory = $true, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    # Name of the printer.
    [System.String]$Name,

    [Parameter()]
    [AllowEmptyString()]
    # Configuration file you want to apply to the printer. If none are given, the script will look for a dat-file matching the printer name.
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
        return 1
    }
    if ($ConfigFile) {
        if ($ConfigFile -match '\.\') {
            $ConfigFile = $ConfigFile -replace '\.\', "$PSScriptRoot\"
            Write-Verbose "Cleaned up ConfigGile path to: $ConfigFile"
        }
    }
    else {
        Write-Verbose "No configuration file given. Searching for corresponding file."
        $ConfigFile = (Get-ChildItem -Path $PSScriptRoot -Filter *.dat | Where-Object { $_.Name -match $Name }).FullName

    }
    if ($ConfigFile) {
        Write-Verbose "Corresponding file found: $($ConfigFile.Name)"
        Start-Process -FilePath $runDllPath -ArgumentList "$dllPath,PrintUIEntry /Sr /n `"$Name`" /a `"$($ConfigFile.FullName)`" c d g u r p H" -Wait
    }
    else {
        Write-Verbose "No matching config file found in the directory."
        return 1
    }
}


<#
    .SYNOPSIS
    Applies printing preferences to the chosen printer.

    .DESCRIPTION
    Applies a given dat-file to a printer, updating the printing preferences accordingly.
    If no dat-file is given, it will look for a dat-file matching the given printer name.

    .LINK
    Get-Printer

    .INPUTS
    You can pipe the printer names into the script.

    .OUTPUTS
    None. This will only output an error code if it didn't manage to find the dat-file.

    .EXAMPLE
    PS> .\ImportPrinterSettings.ps1 -Name Printer01 -ConfigFile .\Printer01.dat

    .EXAMPLE
    PS> Get-Printer | .\ImportPrinterSettings.ps1
#>

