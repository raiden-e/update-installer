
function Start-Update {
    [CmdletBinding()]
    param (
        $Path = "$PSScriptRoot\update",
        [switch]$Force
    )

    Get-ChildItem "$PSScriptRoot\.util" -Filter "*.ps1" | ForEach-Object { . $_.FullName }
    if ($Path -isnot [System.IO.DirectoryInfo]) {
        $Path = New-Dir $Path
        if ($Path -isnot [System.IO.DirectoryInfo]) {
            throw "Path must be a directory"
        }
    }
    if (!$Force -and !(Read-Timestamp "$PSScriptRoot\.util\timestamp.txt")) {
        return
    }

    $Code = {
        param ($ScriptPath, $updatePath)
        Write-Verbose "Init: $ScriptPath"
        $name, $latest, $searchTerm, $link = . $ScriptPath
        $name, $latest, $searchTerm, $link | ForEach-Object {
            if ([string]::isNullOrWhiteSpace($_)) { throw "Returned invalid Value: $ScriptPath" }
        }

        # Write-Host "`nName: $name`nLatest: $latest`nTerm: $searchTerm`nLink: $link"

        $local = Get-ChildItem -Path $updatePath -File -Filter $searchTerm
        if ($local) {
            if ($local.name -eq $latest) {
                Write-Host "latest: $name" -ForegroundColor Green
                return
            }
        }

        Write-Host "Updating: $name" -ForegroundColor Cyan
        try {
            Start-BitsTransfer $link -Destination "$updatePath\$latest"
        } catch {
            Write-Host "BitsTransfer failed"
            $null = Invoke-WebRequest -Uri $link -UseBasicParsing -OutFile "$($Path.Name)\$latest"
        }
        if ($? -and $local) {
            Remove-Item $local.FullName
        }
    }
    $jobs = @()
    foreach ($script in (Get-ChildItem "$PSScriptRoot\.util\scripts" -Filter "*.ps1").FullName) {
        $jobs += Start-Job -ArgumentList $script, $Path -ScriptBlock $Code -Verbose
    }
    $null = Wait-Job -Job $jobs
    Receive-Job -Job $jobs
}