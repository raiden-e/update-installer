function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/brave/brave-browser/releases/latest"
    $asset = $rest.assets | ? { $_.Name -eq "BraveBrowserStandaloneSilentSetup.exe" } | Select-Object -First 1
    if (-not $asset) { throw "No Brave standalone silent setup asset found" }
    $filename = "BraveOfflineSilent $($rest.tag_name).exe"
    $link = $asset.browser_download_url
    return "Brave Browser", $filename, "BraveOfflineSilent*.exe", $link
}
return main
