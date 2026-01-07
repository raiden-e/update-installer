function Write-Log {
    <#
    .SYNOPSIS
        Writes log messages to both console and a log file
    .DESCRIPTION
        Provides structured logging with timestamp, level, and message
        Supports different log levels: INFO, WARNING, ERROR, SUCCESS, DEBUG
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG', 'VERBOSE')]
        [string]$Level = 'INFO',
        
        [Parameter()]
        [string]$LogFile,
        
        [switch]$NoConsole
    )
    
    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        # Write to log file if specified
        if ($LogFile) {
            try {
                $logEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8 -ErrorAction Stop
            } catch {
                Write-Warning "Failed to write to log file: $_"
            }
        }
        
        # Write to console with appropriate color
        if (-not $NoConsole) {
            $color = switch ($Level) {
                'INFO'    { 'White' }
                'WARNING' { 'Yellow' }
                'ERROR'   { 'Red' }
                'SUCCESS' { 'Green' }
                'DEBUG'   { 'Gray' }
                'VERBOSE' { 'Cyan' }
                default   { 'White' }
            }
            
            Write-Host $logEntry -ForegroundColor $color
        }
    }
}
