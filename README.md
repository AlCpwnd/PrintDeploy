# :printer: PrintDeploy

PowerShell script for deploying network printers through Intune without having a print server.  
Information regarding the use of the script can be found by running the [Documentation](./Documentation/) folder.

## Requirements

In order to correctly complete the installation command, you will need the driver name.  
You van find it either by reading the `.INF` file, or by first manually installing the printer and running the following command:

```ps
Get-PrinterDriver | ft Manufacturer,Name -AutoSize
```

The `Name` of the recently installed driver is what you're looking for.

---

## :book: Script Documentation

Detailed information on the working of the various script can be found in the [Documentation](./Documentation/) folder:

- [PrintDeploy.ps1](./Documentation/PrintDeploy.md)
- [Detect.ps1](./Documentation/Detect.md)
- [ExportPrinterSettings.ps1](./Documentation/ExportPrinterSettings.md)
- [ImportPrinterSettings.ps1](./Documentation/ImportPrinterSettings.md)

---

## :wrench: Intune Configuration

:warning: In case you want to use this to deploy printers through Intune, be warned that only the 'single printer' function has been tested for now.

### Settings

:information_source: If you plan on deploying custom printing settings with the printer, you will need to:

1. Install the printer on a device (with the same drivers)
2. Configure your printing settings on said printer as required
3. Export that configuration in a dat-file using the [ExportPrinterSettings.ps1](./ExportPrinterSettings.ps1)

Once exported, you can add and reference that dat-file in your installation command.

If you only with to apply configuration files to existing printers, you can use the [ImportPrinterSettings.ps1](./ImportPrinterSettings.ps1) script in a separate package.

#### Program

Install Command: `powershell.exe -ExecutionPolicy Bypass -NoProfile -File PrintDeploy.ps1 -Name "<Printer Name>" -DriverName "<Driver Name>" -DriverPath "<Driver Path>" -IP "<Printer Port>" [-PrinterSettings <FileInfo>]`

Uninstall Command: `powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "Remove-Printer -Name <Printer Name>"`

#### Detection Rules

Choose one of the following options for detecting the printer installation.

##### Registry Detection

> This will only work after a reboot of the device.

Rules format: `Manually configured detection rules`

Detection rules:

- Type: `Registry`
- Key path: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers\<Printer Name>`
- Detection method: `Key exists`

##### Custom Script

Update the [Detect.ps1](./Detect.ps1) for it to correspond to the printer name you want to deploy, and upload it to the portal.
