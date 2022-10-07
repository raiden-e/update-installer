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
        param ($ScriptPath, $updatePath)

        $name, $latest, $searchTerm, $link = . $ScriptPath
        $name, $latest, $searchTerm, $link | ForEach-Object {
            if ([string]::isNullOrWhiteSpace($_)) { throw "Returned invalid Value: $ScriptPath" }
        }

        return @($name, $latest, $searchTerm, $link)
    }

    function Watch-Job {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory, ValueFromPipeline)]
            [ValidateNotNullOrEmpty()]
            [System.Management.Automation.Job[]]
            $InputJobs
        )
        [System.Collections.ArrayList]$results = [System.Collections.ArrayList]::new()

        function collect {
            [CmdletBinding()]
            param ()
            foreach ($job in ($InputJobs | Where-Object { $_.State -eq "Completed" })) {
                $result = Receive-Job $job -Wait -AutoRemoveJob
                if ($result.Exception) {
                    Write-Error $result
                } else {
                    $null = $results.Add($result)
                }
            }
        }

        do {
            collect
            Start-Sleep 2
        } while ('Running' -in $InputJobs.State)
        collect

        return $results
    }

    [System.Collections.ArrayList]$jobs = [System.Collections.ArrayList]::new()
    foreach ($script in (Get-ChildItem "$PSScriptRoot\.util\scripts" -Filter "*.ps1").FullName) {
        $null = $jobs.Add((Start-Job -ArgumentList $script, $Path -ScriptBlock $checkCode -Verbose))
    }

    $results = Watch-Job $jobs

    $downloadJob = {
        param(
            $from,
            $to,
            $local
        )
        ${function:Copy-File} = ${using:function:Copy-File}
        try {
            Copy-File -From $from -To $to
        } catch {
            $host.UI.WriteErrorLine("Copy-File failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
            return $_
        }
        if ($local) {
            Remove-Item $local.FullName
        }
    }

    $null = $jobs.Clear()
    Write-Host $results
    foreach ($result in $results) {
        # $name, $latest, $searchTerm, $link = $result
        $local = Get-ChildItem -Path $updatePath -File -Filter $result[2]
        if ($local) {
            if ($local.Name -eq $result[1]) {
                Write-Host "latest: $($result[0])" -ForegroundColor Green
                continue
            }
        }
        Write-Host "Updating: $($result[0]), Link: {$($result[3])}" -ForegroundColor Cyan

        $null = $jobs.Add((Start-Job -ArgumentList $result[3], "$updatePath\$($result[1])", $local -ScriptBlock $downloadJob -Verbose))
    }

    return Watch-Job $jobs
}