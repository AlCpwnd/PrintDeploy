# PrintDeploy

PowerShell script for deploying network printers through script.

## Preperation

In order to correctly document the name of the driver in the script, you will first need to manually install it on a device and run:

```ps
Get-PrinterDriver
```

And document the "Name" value of the driver you just added.

---

## Printers.csv

CSV file containing the configuration of multiple printers.
The file need to have the following headers in order to work:

- Name
- DriverName
- DriverPath
- IP

## PrintDeploy.ps1

### Synopsis

Adds a network printer to the current computer.

### Syntax

```
PrintDeploy.ps1 -Name <String> -DriverName <String> -DriverPath <String> -IP <String> [<CommonParameters>]
PrintDeploy.ps1 -Path <String> [<CommonParameters>]
```

### Description

Verifies if the required port and drivers are present on the device before
trying to add the requested printer to the device.

### Examples


#### Example 1

```ps
Add-NetworkPrinter -Name "Admin Printer" -DriverName "KONICA MINOLTA Universal PCL" -DriverPath ".\Drivers\KOAWUJ__.inf" -IP "10.10.0.1"
```

### Parameters

#### -Name

Name given to the printer.

```
Type: String
Parameter Sets: Printer

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

#### -DriverName

Name of the driver.

```
Type: String
Parameter Sets: Printer

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

#### -DriverPath

Path to the INF file to install the driver.

```
Type: String
Parameter Sets: Printer

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

#### -IP

IP on which the printer can be found and port that will be configured on the device.

```
Type: String
Parameter Sets: Printer

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

#### -File

CSV configuration file containing the multiple printers you want to add to the current device.

```
Type: String
Parameter Sets: File

Required: true
Position: named
Default value: None
Accept pipeline: false
Accept wildcard characters: false
```

### Related Links

* [Get-Printer](https://learn.microsoft.com/powershell/module/printmanagement/get-printer?view=windowsserver2025-ps&wt.mc_id=ps-gethelp
* [Get-PrinterDriver](https://learn.microsoft.com/powershell/module/printmanagement/get-printerdriver?view=windowsserver2025-ps&wt.mc_id=ps-gethelp
* [Get-PrinterPort](https://learn.microsoft.com/powershell/module/printmanagement/get-printerport?view=windowsserver2025-ps&wt.mc_id=ps-gethelp
