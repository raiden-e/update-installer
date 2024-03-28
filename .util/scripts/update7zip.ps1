function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://www.7-zip.de/download.html"
    $latestLink = ($page.Links | ? { $_.href -like "https://7-zip.org/a/7z*x64.exe" }).href | Select-Object -First 1
    $latest = $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "7-Zip", $latest, "7z*x64.exe", $latestLink
}

return main