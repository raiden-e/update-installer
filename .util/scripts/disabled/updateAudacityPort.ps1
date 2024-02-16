function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://sourceforge.net/projects/portableapps/files/Audacity%20Portable/"
    $latestLink = $page.Links.href | ? { $_ -like "*Audacity*exe*/download" } | Select-Object -First 1
    $filename = $latestLink -replace '/download', ""
    $filename = $filename.Substring($filename.LastIndexOf("/") + 1)
    return "AudaCity Portable", $filename, "AudacityPortable*.exe", $latestLink
}
return main