function main {
    param()
    function Get-Version ($link) {
        return $page.Links.href | ? { $_ -match "(?:\d+\.){2}\d+" } | % { [System.Version]($_.Trim("/\")) } | Sort-Object
    }
    $mainlink = "https://www.python.org/ftp/python"
    $page = Invoke-WebRequest -UseBasicParsing $mainlink
    $latestVersion = "$((Get-Version)[-1])"
    $page2 = Invoke-WebRequest -UseBasicParsing "$mainlink/$latestVersion"
    if ("python-$latestVersion.exe" -notin $page2.Links.href) {
        $latestVersion = "$((Get-Version)[-2])"
    }
    return "Python", "python-$latestVersion.exe", "python-*.exe", "$mainLink/$latestVersion/python-$latestVersion.exe"
}
return main