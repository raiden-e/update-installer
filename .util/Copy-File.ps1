function Copy-File {
    # ref: https://stackoverflow.com/a/55527732
    param(
        # Source file to copy
        [string]$From,
        # Target destination
        [string]$To,
        # Credentialy if you need some
        [pscredential]$Credential
    );

    try {
        $hash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5CryptoServiceProvider]::new().ComputeHash([System.Text.UTF8Encoding]::new().GetBytes($From + $To))).Replace("-", "");
        $jobName = "Copy_$hash";
        $job = Get-BitsTransfer -Name $jobName -ErrorAction SilentlyContinue;
        if ($job) {
            if ($job.JobState -in ("Connecting", "Transferring")) {
                $title = "File copy alredy running...";
                $question = "Do you want to remove the downloaded file?";
                $choices = "&Yes", "&No";
                if (!([Environment]::UserInteractive) -or $null -eq $Host.UI -or (($Host.UI.PromptForChoice($title, $question, $choices, 1)) -ne 0)) {
                    throw "There is another process that downloads this file, abort: $From";
                }
            }
            Complete-BitsTransfer $job -ErrorAction Stop;
            $job = $null;
        }

        if (!($job)) {
            $job = Start-BitsTransfer -Source $From -Destination $To `
                -Description "Moving: $From => $To" `
                -DisplayName $jobName -Credential $Credential `
                -ErrorAction Stop -Asynchronous;
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $maxWaitMinutes = 30
        while ($job.JobState.ToString() -ne "Transferred") {
            if ($job.JobState.ToString() -notin "Connecting", "Transferring", "Transferred") {
                $errorMsg = if ($job.ErrorDescription) { $job.ErrorDescription } else { "Unknown error" }
                throw "BITS transfer failed with state: $($job.JobState). Error: $errorMsg"
            }
            # Timeout check
            if ($sw.Elapsed.TotalMinutes -gt $maxWaitMinutes) {
                throw "Download timeout after $maxWaitMinutes minutes"
            }
            Start-Sleep -Milliseconds 100
        }

        $sw.Stop();
        $sw.Reset();
    } finally {
        if ($job) {
            Complete-BitsTransfer -BitsJob $job;
        }
    }
}