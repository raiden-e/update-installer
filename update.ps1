
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

    $checkCode = {
        param ($ScriptPath)
        Write-Verbose "Init: $ScriptPath"

        $name, $latest, $searchTerm, $link = . $ScriptPath
        $name, $latest, $searchTerm, $link | ForEach-Object {
            if ([string]::isNullOrWhiteSpace($_)) { throw "Returned invalid Value: $ScriptPath" }
        }
        return $name, $latest, $searchTerm, $link
    }

    [System.Collections.ArrayList]$jobs = [System.Collections.ArrayList]::new()
    [System.Collections.ArrayList]$finished = [System.Collections.ArrayList]::new()
    foreach ($script in (Get-ChildItem "$PSScriptRoot\.util\scripts" -Filter "*.ps1").FullName) {
        $null = $jobs.Add((Start-Job -ArgumentList $script -ScriptBlock $checkCode -Verbose))
    }
    $results = Wait-JobWithProgress -InputObject $jobs -PassThru

    $downloadCode = {
        param($from, $to)
        ${function:Copy-File} = ${using:function:Copy-File}

        try {
            Copy-File -From $from -To $to
        } catch {
            $host.UI.WriteErrorLine("Copy-File failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
            return
        }
        if ($local) {
            Remove-Item $local.FullName
        }
    }
    $null = $jobs.Clear()
    foreach ($result in $results) {
        $local = Get-ChildItem -Path $Path -File -Filter $result[2]
        if ($local) {
            if ($local.name -eq $result[1]) {
                Write-Host "latest: $($result[0])" -ForegroundColor Green
                continue
            }
        }
        $to = "$Path\$($result[1])"
        Write-Host "Updating: $($result[0]), Link: {$($result[3])} to: {$to}" -ForegroundColor Cyan
        $null = $jobs.Add((Start-Job -ArgumentList $result[3], $to -ScriptBlock $downloadCode -Verbose))
    }
    Wait-JobWithProgress -InputObject $jobs -PassThru
}