
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
        ${function:Copy-File} = ${using:function:Copy-File}
        Write-Verbose "Init: $ScriptPath"

        $name, $latest, $searchTerm, $link = . $ScriptPath
        $name, $latest, $searchTerm, $link | ForEach-Object {
            if ([string]::isNullOrWhiteSpace($_)) { throw "Returned invalid Value: $ScriptPath" }
        }

        $local = Get-ChildItem -Path $updatePath -File -Filter $searchTerm
        if ($local) {
            if ($local.name -eq $latest) {
                Write-Host "latest: $name" -ForegroundColor Green
                return
            }
        }

        Write-Host "Updating: $name, Link: {$link}" -ForegroundColor Cyan
        try {
            Copy-File -From $link -To "$updatePath\$latest"
        } catch {
            $host.UI.WriteErrorLine("Copy-File failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
            return
        }
        if ($local) {
            Remove-Item $local.FullName
        }
    }
    [System.Collections.ArrayList]$jobs = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$finished = [System.Collections.ArrayList]::new()

    foreach ($script in (Get-ChildItem "$PSScriptRoot\.util\scripts" -Filter "*.ps1").FullName) {
        $jobs.Add((Start-Job -ArgumentList $script, $Path -ScriptBlock $Code -Verbose))
    }

    while ('Running' -in $jobs.State) {
        $jobs | Wait-Job -Timeout 2
        $jobs | Show-JobProgress
        foreach ($job in ($jobs | Where-Object { $_.State -eq "Completed" })) {
            Receive-Job $job
            $finished += $job
            $jobs.Remove($job)
        }
    }
}