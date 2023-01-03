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
            $job = Start-BitsTransfer -Source $From -Destination $To `
                -Description "Moving: $From => $To" `
                -DisplayName "copy_$hash" -Credential $Credential `
                -ErrorAction Stop -Asynchronous;
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        while ($job.JobState.ToString() -ne "Transferred") {
            if ($job.JobState.ToString() -notin "Connecting", "Transferring", "Transferred") {
                throw $job.JobState.ToString() + " unexpected BITS state.";
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
    }
}