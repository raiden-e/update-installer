function main {
    param()
    $link1 = "https://www.wireshark.org/download.html"
    $page = Invoke-WebRequest $link1 -UseBasicParsing
    $latestLink = ($page.Links | Where-Object { $_.href -like "*Wireshark-win64*exe" } | Select-Object -First 1).href
    $filename = $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "Wireshark", $filename, "Wireshark*.exe", $latestLink
}
return main