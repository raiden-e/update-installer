function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://sourceforge.net/projects/portableapps/files/WinDirStat%20Portable/"
    $latestLink = $page.Links.href | ? { $_ -like "*WinDirStat*exe*/download" } | Select-Object -First 1
    $filename = $latestLink -replace '/download', ""
    $filename = $filename.Substring($filename.LastIndexOf("/") + 1)
    return "WinDirStat Portable", $filename, "WinDirStat*.exe", $latestLink
}
return main