function Copy-File {
    # ref: https://stackoverflow.com/a/55527732
    param(
        # Source file to copy
        [string]$From,
        # Target destination
        [string]$To,
        # Credentialy if you need some
        [pscredential]$Credential,
        # Optional Id if you are using multiple progressbars
        [int]$ProgressbarId = 0
    );

    try {
        $hash = ([System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider).ComputeHash((New-Object -TypeName System.Text.UTF8Encoding).GetBytes($From + $To)))).Replace("-", "");
        $jobName = "Copy_$hash";
        $job = Get-BitsTransfer -Name $jobName -ErrorAction SilentlyContinue;
        $isPsCore = $PSVersionTable.PSEdition -eq "Core";
        if ($job) {
            if ($job.JobState -in ("Connecting", "Transferring")) {
                $title = "File copy alredy running...";
                $question = "Do you want to remove the downloaded file?";
                $choices = "&Yes", "&No";
                if ($isPsCore -or !([Environment]::UserInteractive) -or (($Host.UI.PromptForChoice($title, $question, $choices, 1)) -ne 0)) {
                    throw "There is another process that downloads this file, abort: $From";
                }
            }
            Complete-BitsTransfer $job -ErrorAction Stop;
            $job = $null;
        }

        if (!($job)) {
            Write-Progress -Id $ProgressbarId -Activity "Starting...";
            $job = Start-BitsTransfer -Source $From -Destination $To `
                -Description "Moving: $From => $To" `
                -DisplayName "copy_$hash" -Credential $Credential `
                -ErrorAction Stop -Asynchronous;
        }

        # Start stopwatch
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        $fileName = [IO.Path]::GetFileName($From);
        while ($job.JobState.ToString() -ne "Transferred") {
            switch ($job.JobState.ToString()) {
                "Connecting" {
                    break
                }
                "Transferring" {
                    $pctcomp = ($job.BytesTransferred / $job.BytesTotal) * 100
                    $elapsed = ($sw.elapsedmilliseconds.ToString()) / 1000

                    if ($elapsed -eq 0) {
                        $xferrate = 0.0
                    } else {
                        $xferrate = (($job.BytesTransferred / $elapsed) / 1mb);
                    }

                    if ($job.BytesTransferred % 1mb -eq 0) {
                        if ($pctcomp -gt 0) {
                            $secsleft = ((($elapsed / $pctcomp) * 100) - $elapsed)
                        } else {
                            $secsleft = 0
                        }

                        $total = $job.BytesTotal;
                        $transferred = $job.BytesTransferred;
                        # TODO: Check this before loop?
                        if ($total -gt 1024) {
                            $total = $total / 1024;
                            $transferred = $transferred / 1024;
                            $symbol = "KB";
                        }
                        if ($total -gt 1024) {
                            $total = $total / 1024;
                            $transferred = $transferred / 1024;
                            $symbol = "MB";
                        }
                        if ($total -gt 10240) {
                            # Show GB if we have more than 10GB
                            $total = $total / 1024;
                            $transferred = $transferred / 1024;
                            $symbol = "GB";
                        }

                        Write-Progress -Id $ProgressbarId -Activity ("Copying file '$fileName' @ " + "{0:n2}" -f $xferrate + "MB/s") `
                            -PercentComplete $pctcomp `
                            -SecondsRemaining $secsleft `
                            -Status ("{0:n2} {2}/{1:n2} {2} Transferred" -f $transferred, $total, $symbol)`
                            ;
                    }
                    break
                }
                "Transferred" {
                    break
                }
                Default {
                    throw $job.JobState.ToString() + " unexpected BITS state.";
                }
            }
            if ($isPsCore) {
                $job = Get-BitsTransfer -Name $jobName -ErrorAction SilentlyContinue;
                if (!($job)) {
                    throw "Job cancelled by another process!";
                }
            }
        }

        $sw.Stop();
        $sw.Reset();
    } finally {
        if ($job) {
            Complete-BitsTransfer -BitsJob $job;
        }
        Write-Progress -Id $ProgressbarId -Activity "Completed" -Completed;
    }
}