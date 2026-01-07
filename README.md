# update-installer

Automated software updater for maintaining a collection of installers for VM deployments.

## Features

- 🚀 **Parallel Processing** - Downloads multiple applications simultaneously
- 📊 **Progress Tracking** - Visual feedback during version checks and downloads
- 🔄 **Resume Support** - Uses BITS transfer with automatic resume capability
- 📝 **Comprehensive Logging** - Detailed logs with timestamps and severity levels
- ⚡ **Smart Caching** - Daily timestamp prevents redundant checks
- 🎯 **Version Detection** - Automatically detects and updates only outdated software
- 🛡️ **Error Handling** - Robust error handling with detailed error messages
- 🔌 **Modular Design** - Easy to add new applications

## Usage

### Basic Usage

```powershell
# Load and run the update script
. .\Start-Update.ps1
Start-Update -Path "E:\software\apps\win\_install"
```

### Advanced Options

```powershell
# Force update even if already run today
Start-Update -Path "E:\software\apps\win\_install" -Force

# Enable disabled update scripts
Start-Update -Path "E:\software\apps\win\_install" -enableAll

# Specify custom log file location
Start-Update -Path "E:\software\apps\win\_install" -LogFile "C:\logs\update.log"

# Combine options
Start-Update -Path "E:\software\apps\win\_install" -Force -enableAll -Verbose
```

## Supported Applications

### Active Updaters
- 7-Zip
- AutoRuns (Sysinternals)
- BGInfo (Sysinternals)
- Brave Browser
- Git for Windows
- Notepad++
- Process Explorer (Sysinternals)
- VLC Media Player
- Visual Studio Code
- Wireshark

### Disabled Updaters (enable with `-enableAll`)
- Audacity Portable
- Chrome
- Firefox
- GnuPG
- GPG
- Microsoft Office
- nVidia Drivers
- PowerShell Core
- PowerToys
- Python
- VMware Tools
- WinDirStat Portable

## Logging

Logs are automatically created in the `logs/` directory with timestamps:
- Format: `update-yyyyMMdd-HHmmss.log`
- Log levels: INFO, WARNING, ERROR, SUCCESS, DEBUG, VERBOSE
- Both console output and file logging

Example log output:
```
[2025-11-09 14:30:15] [INFO] Starting update process...
[2025-11-09 14:30:15] [INFO] Found 10 update scripts
[2025-11-09 14:30:20] [SUCCESS] Version checks completed: 10 results
[2025-11-09 14:30:20] [SUCCESS] Already latest: VS Code (VSCodeSetup-x64-1.105.1.exe)
[2025-11-09 14:30:20] [INFO] Update available: Git (Git-2.51.1-64-bit.exe -> Git-2.51.2-64-bit.exe)
[2025-11-09 14:30:45] [SUCCESS] Successfully downloaded: Git
```

## Adding New Applications

Create a new script in `.util\scripts\` following this template:

```powershell
function main {
    param()
    
    # Fetch latest version info (example using GitHub API)
    $rest = Invoke-RestMethod "https://api.github.com/repos/owner/repo/releases/latest"
    $asset = $rest.assets | Where-Object { $_.Name -like "*pattern*" }
    
    $filename = $asset.Name
    $link = $asset.browser_download_url
    
    # Return: DisplayName, Filename, SearchPattern, DownloadLink, [Credentials]
    return "AppName", $filename, "AppName*.exe", $link
}

return main
```

## Error Handling

The script includes comprehensive error handling:
- **Network errors**: Automatically retried with BITS
- **Script failures**: Logged and isolated (won't stop other updates)
- **Timeout protection**: 30-minute timeout per download
- **State validation**: Checks BITS transfer states
- **Graceful degradation**: Failed downloads don't affect successful ones

## Requirements

- PowerShell 5.1 or later
- BITS (Background Intelligent Transfer Service)
- Internet connection
- Write permissions to target directory

## Timestamp Management

The script creates a `timestamp.txt` file to prevent redundant updates:
- Format: `yyyyMMdd`
- Checked before each run
- Updated after successful completion
- Override with `-Force` parameter

## Directory Structure

```
update-installer/
├── Start-Update.ps1          # Main script
├── README.md                 # This file
├── LICENSE                   # License information
├── logs/                     # Auto-generated logs
└── .util/
    ├── Copy-File.ps1         # BITS download wrapper
    ├── New-Dir.ps1           # Directory creation helper
    ├── Read-Timestamp.ps1    # Timestamp validation
    ├── Wait-JobWithProgress.ps1  # Job management
    ├── Write-Log.ps1         # Logging utility
    └── scripts/
        ├── update*.ps1       # Active update scripts
        └── disabled/
            └── update*.ps1   # Disabled update scripts
```

## Troubleshooting

### No updates found
- Check internet connection
- Verify script permissions
- Check logs for API errors

### Download failures
- Verify disk space
- Check firewall settings
- Review BITS service status: `Get-Service BITS`

### Permission errors
- Run PowerShell as Administrator
- Check write permissions on target directory

## License

See LICENSE file for details
