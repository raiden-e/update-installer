# update-installer

PowerShell tool that keeps a folder of Windows installers up to date for VM deployments. Each app has a small script that resolves the latest version; the main script checks them in parallel and downloads only what is missing or outdated.

## Quick start

From the parent folder, run `update.bat`, or:

```powershell
. .\Start-Update.ps1
Start-Update -Path "F:\windows\_install"
```

Installers are written to `-Path`. Old files matching the same search pattern are removed after a successful download.

## Options

| Parameter | Description |
|-----------|-------------|
| `-Path` | Target directory for installers |
| `-Force` | Run even if already executed today |
| `-enableAll` | Include scripts from `.util\scripts\disabled` |
| `-LogFile` | Custom log path (default: `logs\update-yyyyMMdd-HHmmss.log`) |
| `-Verbose` | Extra console output |

A `timestamp.txt` file in the target directory limits runs to once per day unless `-Force` is used.

## Supported applications

**Active:** 7-Zip, AutoRuns, BGInfo, Brave, Git, Notepad++, PowerToys, Process Explorer, Python, RustDesk, SumatraPDF, VLC, VS Code, Wireshark

**Disabled** (use `-enableAll`): Audacity Portable, Chrome, Firefox, GnuPG, GPG, Office, nVidia drivers, PowerShell Core, VMware Tools, WinDirStat Portable

## Adding an application

Create `.util\scripts\updateMyApp.ps1`:

```powershell
function main {
    $rest = Invoke-RestMethod "https://api.github.com/repos/owner/repo/releases/latest"
    $asset = $rest.assets | Where-Object { $_.Name -like "*pattern*" } | Select-Object -First 1
    if (-not $asset) { throw "No matching asset found" }
    return "My App", $asset.Name, "MyApp*.exe", $asset.browser_download_url
}
return main
```

Return values: display name, target filename, local search pattern, download URL. An optional fifth value is a `PSCredential` for authenticated downloads.

Move scripts to `disabled\` to exclude them without deleting.

## How it works

1. Load helpers from `.util\`
2. Run each update script in a background job to fetch version info
3. Compare against files already in `-Path`
4. Download updates in parallel via BITS (resume-capable, 30 min timeout per file)
5. Write `timestamp.txt` on success

Logs go to `logs\` with levels INFO, WARNING, ERROR, SUCCESS, and DEBUG.

## Requirements

- PowerShell 5.1+
- BITS service running
- Internet access and write access to the target directory

## Troubleshooting

- **No updates / API errors:** Check connectivity and review the latest log in `logs\`
- **Download failures:** Verify disk space, firewall, and BITS: `Get-Service BITS`
- **Permission errors:** Ensure write access to `-Path`; some installers may need an elevated shell

See LICENSE for license details.
