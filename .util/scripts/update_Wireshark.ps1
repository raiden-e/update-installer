function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://www.wireshark.org/download.html"
    $latestLink = ($page.Links | ? { $_.href -like "*Wireshark*x64*exe" } | Select-Object -First 1).href
    $filename = $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "Wireshark", $filename, "Wireshark*.exe", $latestLink
}
return main