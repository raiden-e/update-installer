function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
    $asset = $rest.assets | Where-Object { $_.Name -like "VSCodiumSetup-x64-*.exe" } | Select-Object -First 1
    if (-not $asset) { throw "No VSCodium x64 system installer asset found" }
    return "VSCodium", $asset.Name, "VSCodiumSetup-x64*.exe", $asset.browser_download_url
}
return main
