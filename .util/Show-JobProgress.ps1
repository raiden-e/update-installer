function Show-JobProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Job[]]
        $Job
    )

    Process {
        $Job.ChildJobs | ForEach-Object {
            if (-not $_.Progress) {
                return
            }

            $_.Progress | Group-Object -Property Activity, StatusDescription | ForEach-Object { $_.Group | Select-Object -Last 1 } | ForEach-Object {
                $ProgressParams = @{}
                if ($_.Activity -and $null -ne $_.Activity) { $ProgressParams.Add('Activity', $_.Activity) }
                if ($_.StatusDescription -and $null -ne $_.StatusDescription) { $ProgressParams.Add('Status', $_.StatusDescription) }
                if ($_.CurrentOperation -and $null -ne $_.CurrentOperation) { $ProgressParams.Add('CurrentOperation', $_.CurrentOperation) }
                if ($_.ActivityId -and $_.ActivityId -gt -1) { $ProgressParams.Add('Id', $_.ActivityId) }
                if ($_.ParentActivityId -and $_.ParentActivityId -gt -1) { $ProgressParams.Add('ParentId', $_.ParentActivityId) }
                if ($_.PercentComplete -and $_.PercentComplete -gt -1) { $ProgressParams.Add('PercentComplete', $_.PercentComplete) }
                if ($_.SecondsRemaining -and $_.SecondsRemaining -gt -1) { $ProgressParams.Add('SecondsRemaining', $_.SecondsRemaining) }

                Write-Progress @ProgressParams
            }
        }
    }
}