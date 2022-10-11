function Wait-JobWithProgress {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        $InputObject,

        [parameter()]
        [int] $TimeOut = [int]::MaxValue,

        [switch]$PassThru
    )

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $jobs = [System.Collections.ArrayList]::new()
    $results = [System.Collections.ArrayList]::new()

    foreach ($job in $InputObject) {
        $null = $jobs.Add($job)
    }
    $total = $jobs.Count; $completed = 0
    do {
        $progress = @{
            Activity        = 'Waiting for Downloads'
            Status          = 'Remaining Jobs {0} of {1}' -f ($jobs.State -eq 'Running').Count, $total
            PercentComplete = $completed / $total * 100
        }
        Write-Progress @progress

        $id = [System.Threading.WaitHandle]::WaitAny($jobs.Finished, 200)
        if ($id -eq [System.Threading.WaitHandle]::WaitTimeout) { continue }
        # output this job
        try {
            if ($PassThru) {
                $null = $results.Add((Receive-Job $jobs[$id]))
            } else {
                Receive-Job $jobs[$id]
            }
        } catch {
            Write-Progress @progress -Completed
            $host.UI.WriteErrorLine("Job failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
        }

        # remove this job
        $jobs.RemoveAt($id)
        $completed++
    } while ($timer.Elapsed.Seconds -le $TimeOut -and $jobs)

    # Stop the jobs not yet Completed and remove them
    $jobs | Stop-Job -PassThru | ForEach-Object {
        Write-Warning ("Job [#{0} - {1}] did not complete on time and was removed..." -f $_.Id, $_.Name)
        Remove-Job $_
    }
    Write-Progress @progress -Completed
    if ($PassThru) {
        return $results
    }
}
