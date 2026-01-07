
function Start-Update {
    [CmdletBinding()]
    param (
        $Path,
        [switch]$Force,
        [switch]$enableAll,
        [string]$LogFile
    )

    # Setup logging
    if (-not $LogFile) {
        $LogFile = Join-Path $PSScriptRoot "logs\update-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    }
    $logDir = Split-Path $LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Load utility functions
    try {
        Get-ChildItem "$PSScriptRoot\.util" -Filter "*.ps1" -ErrorAction Stop | ForEach-Object { 
            . $_.FullName 
        }
        Write-Log "Loaded utility functions" -Level INFO -LogFile $LogFile
    } catch {
        Write-Error "Failed to load utility functions: $_"
        throw
    }

    if(!$Path){
        Write-Log '$Path not provided.' -Level WARNING -LogFile $LogFile
        $confirm = Read-Host "Continue?"
        if ($confirm -notmatch "(con|y)"){
            Write-Log "User cancelled operation" -Level INFO -LogFile $LogFile
            exit
        }
    }

    Write-Log "Starting update process..." -Level SUCCESS -LogFile $LogFile
    Write-Log "Target path: $Path" -Level INFO -LogFile $LogFile
    Write-Log "Force mode: $Force" -Level INFO -LogFile $LogFile
    Write-Log "Enable all scripts: $enableAll" -Level INFO -LogFile $LogFile
    Write-Log "Log file: $LogFile" -Level INFO -LogFile $LogFile
    # Validate and create target directory
    try {
        if ($Path -isnot [System.IO.DirectoryInfo]) {
            Write-Log "Creating target directory: $Path" -Level INFO -LogFile $LogFile
            $Path = New-Dir $Path
            if ($Path -isnot [System.IO.DirectoryInfo]) {
                throw "Path must be a directory"
            }
        }
        Write-Log "Target directory validated: $($Path.FullName)" -Level SUCCESS -LogFile $LogFile
    } catch {
        Write-Log "Failed to create/validate directory: $_" -Level ERROR -LogFile $LogFile
        throw
    }

    # Check timestamp
    if (!$Force -and !(Read-Timestamp "$Path\timestamp.txt")) {
        Write-Log "Update already performed today. Use -Force to override." -Level WARNING -LogFile $LogFile
        return
    }

    $checkCode = {
        param ($ScriptPath)
        Write-Verbose "Init: $ScriptPath"

        try {
            $name, $latest, $searchTerm, $link, $cred = . $ScriptPath
            $name, $latest, $searchTerm, $link | ForEach-Object {
                if ([string]::isNullOrWhiteSpace($_)) { 
                    throw "Returned invalid Value from script: $(Split-Path $ScriptPath -Leaf)" 
                }
            }
            return $name, $latest, $searchTerm, $link, $cred
        } catch {
            $host.UI.WriteErrorLine("Error in script $($ScriptPath): $($_.Exception.Message)")
            throw
        }
    }

    [System.Collections.ArrayList]$jobs = [System.Collections.ArrayList]::new()

    # Discover update scripts
    try {
        $scripts = (Get-ChildItem "$PSScriptRoot\.util\scripts" -Filter "*.ps1" -ErrorAction Stop).FullName
        if ($enableAll) {
            $disabledScripts = Get-ChildItem "$PSScriptRoot\.util\scripts\disabled" -Filter "*.ps1" -ErrorAction SilentlyContinue
            if ($disabledScripts) {
                $scripts = ($scripts + $disabledScripts.FullName) | Sort-Object
                Write-Log "Enabled $($disabledScripts.Count) disabled scripts" -Level INFO -LogFile $LogFile
            }
        }
        Write-Log "Found $($scripts.Count) update scripts" -Level INFO -LogFile $LogFile
    } catch {
        Write-Log "Failed to load update scripts: $_" -Level ERROR -LogFile $LogFile
        throw
    }

    # Start version check jobs
    foreach ($script in $scripts) {
        try {
            $scriptName = Split-Path $script -Leaf
            Write-Log "Queuing version check: $scriptName" -Level DEBUG -LogFile $LogFile
            $null = $jobs.Add((Start-Job -ArgumentList $script -ScriptBlock $checkCode -Verbose))
        } catch {
            Write-Log "Failed to start job for $scriptName : $_" -Level ERROR -LogFile $LogFile
        }
    }
    
    Write-Log "Started $($jobs.Count) version check jobs" -Level INFO -LogFile $LogFile
    if ($jobs.Count -eq 0) {
        Write-Log "No update scripts to run!" -Level ERROR -LogFile $LogFile
        return
    }

    # Wait for version checks to complete
    try {
        $results = Wait-JobWithProgress -Jobs $jobs -PassThru
        Write-Log "Version checks completed: $($results.Count) results" -Level SUCCESS -LogFile $LogFile
    } catch {
        Write-Log "Error during version checks: $_" -Level ERROR -LogFile $LogFile
        throw
    }

    $downloadCode = {
        param($from, $to, $local, $cred, $appName)
        ${function:Copy-File} = ${using:function:Copy-File}

        try {
            Copy-File -From $from -To $to -Credential $cred
            if ($local) {
                Remove-Item $local.FullName -Force -ErrorAction Stop
            }
            return @{Success = $true; App = $appName; File = $to}
        } catch {
            $host.UI.WriteErrorLine("[$appName] Download failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
            return @{Success = $false; App = $appName; Error = $_.Exception.Message}
        }
    }
    
    # Process download results
    $null = $jobs.Clear()
    $updateCount = 0
    $skipCount = 0
    
    foreach ($result in $results) {
        if (-not $result -or $result.Count -lt 4) {
            Write-Log "Skipping invalid result entry" -Level WARNING -LogFile $LogFile
            continue
        }
        
        $appName = $result[0]
        $latestFile = $result[1]
        $searchPattern = $result[2]
        $downloadLink = $result[3]
        $cred = if ($result.length -ge 5) { $result[4] } else { $null }
        
        try {
            $local = Get-ChildItem -Path $Path -File -Filter $searchPattern -ErrorAction SilentlyContinue
            if ($local) {
                if ($local.name -eq $latestFile) {
                    Write-Log "Already latest: $appName ($latestFile)" -Level SUCCESS -LogFile $LogFile
                    $skipCount++
                    continue
                } else {
                    Write-Log "Update available: $appName ($($local.Name) -> $latestFile)" -Level INFO -LogFile $LogFile
                }
            } else {
                Write-Log "New download: $appName ($latestFile)" -Level INFO -LogFile $LogFile
            }
            
            $to = "$Path\$latestFile"
            Write-Log "Downloading: $appName from $downloadLink" -Level INFO -LogFile $LogFile
            $null = $jobs.Add((Start-Job -ArgumentList $downloadLink, $to, $local, $cred, $appName -ScriptBlock $downloadCode -Verbose))
            $updateCount++
        } catch {
            Write-Log "Error processing $appName : $_" -Level ERROR -LogFile $LogFile
        }
    }
    
    Write-Log "Summary: $updateCount updates needed, $skipCount already current" -Level INFO -LogFile $LogFile
    
    if ($jobs.Count -eq 0) {
        Write-Log "No downloads required" -Level SUCCESS -LogFile $LogFile
        return
    }
    
    # Execute downloads
    Write-Log "Starting $($jobs.Count) downloads..." -Level INFO -LogFile $LogFile
    try {
        $downloadResults = Wait-JobWithProgress -Jobs $jobs -PassThru
        
        # Process download results
        $successCount = 0
        $failCount = 0
        
        foreach ($dlResult in $downloadResults) {
            if ($dlResult -and $dlResult.Success) {
                Write-Log "Successfully downloaded: $($dlResult.App)" -Level SUCCESS -LogFile $LogFile
                $successCount++
            } elseif ($dlResult) {
                Write-Log "Failed to download $($dlResult.App): $($dlResult.Error)" -Level ERROR -LogFile $LogFile
                $failCount++
            }
        }
        
        Write-Log "Download summary: $successCount succeeded, $failCount failed" -Level INFO -LogFile $LogFile
        
        if ($failCount -gt 0) {
            Write-Log "Some downloads failed. Check log for details." -Level WARNING -LogFile $LogFile
        }
        
    } catch {
        Write-Log "Error during downloads: $_" -Level ERROR -LogFile $LogFile
        throw
    }
    
    # Update timestamp
    try {
        Write-Log "Updating timestamp..." -Level INFO -LogFile $LogFile
        Get-Date -Format "yyyyMMdd" | Out-File "$Path\timestamp.txt" -Encoding utf8 -Force -ErrorAction Stop
        Write-Log "Timestamp updated successfully" -Level SUCCESS -LogFile $LogFile
    } catch {
        Write-Log "Failed to update timestamp: $_" -Level ERROR -LogFile $LogFile
    }
    
    Write-Log "Update process complete!" -Level SUCCESS -LogFile $LogFile
}