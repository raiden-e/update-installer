function Wait-JobWithProgress {
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)]
        [System.Collections.ArrayList]$Jobs,

        [parameter()]
        [int] $TimeOut = [int]::MaxValue,

        [switch]$PassThru
    )

    if (!$Jobs) {
        Write-Verbose "[Wait-JobWithProgress]: No input"
        return
    }

    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    $results = [System.Collections.ArrayList]::new()

    $total = $Jobs.Count; $completed = 0
    do {
        $progress = @{
            Activity        = 'Waiting for Downloads'
            Status          = 'Remaining Jobs {0} of {1}' -f ($Jobs.State -eq 'Running').Count, $total
            PercentComplete = $completed / $total * 100
        }
        Write-Progress @progress

        $id = [System.Threading.WaitHandle]::WaitAny($Jobs.Finished, 200)
        if ($id -eq [System.Threading.WaitHandle]::WaitTimeout) { continue }
        # output this job
        try {
            if ($PassThru) {
                $null = $results.Add((Receive-Job $Jobs[$id]))
            } else {
                Receive-Job $Jobs[$id]
            }
        } catch {
            Write-Progress @progress -Completed
            $host.UI.WriteErrorLine("Job failed: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
        }

        # remove this job
        $Jobs.RemoveAt($id)
        $completed++
    } while ($timer.Elapsed.Seconds -le $TimeOut -and $Jobs)

    # Stop the jobs not yet Completed and remove them
    $Jobs | Stop-Job -PassThru | ForEach-Object {
        Write-Warning ("Job [#{0} - {1}] did not complete on time and was removed..." -f $_.Id, $_.Name)
        Remove-Job $_
    }
    Write-Progress @progress -Completed
    if ($PassThru) {
        return $results
    }
}
