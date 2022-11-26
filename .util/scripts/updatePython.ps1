function main {
    param()
    $mainlink = "https://www.python.org/ftp/python/"
    $page = Invoke-WebRequest $mainlink -UseBasicParsing
    $latestVersion = ($page.Links.href | ? { $_ -match "(?:\d+\.){2}\d+" } | Select-Object -Last 1).trim("/\")
    return "Python", "python-$latestVersion.exe", "python-*.exe", "$mainLink$latestVersion/python-$latestVersion.exe"
}
return main