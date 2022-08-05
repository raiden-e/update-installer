function Read-Timestamp {
    [CmdletBinding()]
    param (
        $Path
    )
    if (Test-Path $Path) {
        try {
            $timestamp = Get-Content $Path
            if ($timestamp -ge [int](Get-Date -Format "yyyyMMdd")) {
                Write-Verbose "Timestamped today. No update needed"
                return $false
            }
        } catch {
            Write-Warning "Couldn't read timestamp`n$_"
        }
    }
    return $true
}