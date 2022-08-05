function New-Dir {
    # returns a directory in the path if it exists, or creates it and then returns it
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, Mandatory)]
        $Path,
        [switch]$Force
    )
    $item = New-Item $Path -ItemType "Directory" -ErrorAction Ignore -Force:$Force
    if ($item) {
        return $item
    }
    return Get-Item $Path
}