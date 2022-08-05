
[CmdletBinding()]
param(
    [parameter(ValueFromPipeline)]
    $thing
)

$mainlink = "https://www.python.org/ftp/python/"
$a = Invoke-WebRequest $mainlink -UseBasicParsing
$latestVersion = $(($a.Links | Where-Object { $_.href -match "(\d+\.){2}\d+" } | Select-Object -Last 1).href.trim("/\"))

return "Python", "python-$latestVersion.exe", "python-*.exe", "$mainLink$latestVersion/python-$latestVersion.exe"