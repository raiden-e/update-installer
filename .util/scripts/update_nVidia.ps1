function main {
    param()
    $releases64 = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php'
    $releases64 += '?func=DriverManualLookup&psid=101&osID=57&languageCode=1033&beta=0&isWHQL=1&dltype=-1&dch=1&upCRD=0&sort1=0&numberOfResults=1'
    $page = Invoke-WebRequest -UseBasicParsing $releases64
    $latestLink = ($page.Content | ConvertFrom-Json).IDS.downloadInfo.DownloadUrl
    $filename = "nVidiaSD-" + $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "nVidia Studio Driver", $filename, "nVidiaSD-*.exe", $latestLink
}
return main