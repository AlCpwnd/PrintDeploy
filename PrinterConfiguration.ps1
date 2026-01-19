#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    # Name of the printer.
    [System.String]$PrinterName,

    [Parameter()]
    [ValidateScript({
        if(Test-Path -Path $_ -IsValid -Filter "*.dat"){
            return $true
        }else{
            return $false
        }
    })]
    # Configuration file you want to apply to the printer.
    [System.String]$ConfigFile,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Import","Export")]
    # Action to perform on the selected printer.
    [System.String]$Action
)

try{
    Get-Printer -Name $PrinterName -ErrorAction Stop | Out-Null
}catch{
    Write-Host "Printer could not be found on the current computer: $PrinterName" -ForegroundColor Red
    return 1
}

$command = "printui.dll,PrintUIEntry /$c /n `"$PrinterName`" /a `"$ConfigFile`" c d g"

if ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "NT AUTHORITY\SYSTEM") {
    $runDllPath = "C:\Windows\sysnative\rundll32.exe"
    # Source: https://www.itninja.com/question/pnputil-exe-is-not-recognized-as-the-name-of-a-cmdlet-only-through-kace
}else {
    $runDllPath = "C:\Windows\System32\rundll32.exe"
}

if($Action -eq 'Import'){
    if(-not (Test-Path -Path $ConfigFile)){
        Write-Host "Configuration file could not be found: $ConfigFile" -ForegroundColor Red
        return 1
    }
    $command = "printui.dll,PrintUIEntry /Sr /n `"$PrinterName`" /a `"$ConfigFile`" c d g r p"
}elseif($Action -eq 'Export'){
    if(-not $ConfigFile){
        if($PSScriptRoot){
            $ConfigFile = $PSScriptRoot + "\$PrinterName.dat"
        }else{
            $ConfigFile = (Get-Location).Path + "\$PrinterName.dat"
        }
    }
    $i = 1
    while(Test-Path -Path $ConfigFile){
        if($ConfigFile -match '\(\d+\)'){
            $ConfigFile = $ConfigFile -replace '\(\d+\)',"($i)"
            $i++
        }else{
            $ConfigFile = $ConfigFile.Replace('.dat',"($i).dat")
        }
    }
    $command = "printui.dll,PrintUIEntry /Ss /n `"$PrinterName`" /a `"$ConfigFile`" c d g"
}

Start-Process -FilePath $runDllPath -ArgumentList $command

if($Action -eq 'Export'){
    Write-Host "Configuration file generated: $ConfigFile" -ForegroundColor Green
}