function main {
    param()
    $link1 = "https://www.7-zip.de/download.html"
    $page = Invoke-WebRequest $link1 -UseBasicParsing
    $latestLink = ($page.Links | Where-Object { $_.href -like "https://7-zip.org/a/7z*x64.msi" }).href | Select-Object -First 1
    $latest = $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "7-Zip", $latest, "7z*x64.msi", $latestLink
}

return main