function main {
    param()
    function Get-Version ($link) {
        return $page.Links.href | ? { $_ -match "(?:\d+\.){2}\d+" } | % { [System.Version]($_.Trim("/\")) } | Sort-Object
    }
    $mainlink = "https://www.python.org/ftp/python"
    $page = Invoke-WebRequest -UseBasicParsing $mainlink
    $latestVersion = "$((Get-Version)[-1])"
    $page2 = Invoke-WebRequest -UseBasicParsing "$mainlink/$latestVersion"
    if ("python-$latestVersion-amd64.exe" -notin $page2.Links.href) {
        $latestVersion = "$((Get-Version)[-2])"
    }
    return "Python", "python-$latestVersion-amd64.exe", "python-*amd64.exe", "$mainLink/$latestVersion/python-$latestVersion-amd64.exe"
}
return main