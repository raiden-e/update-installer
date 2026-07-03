function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
    $asset = $rest.assets | Where-Object { $_.Name -like "rustdesk-*-x86_64.exe" } | Select-Object -First 1
    if (-not $asset) { throw "No RustDesk Windows x64 asset found" }
    return "RustDesk", $asset.Name, "rustdesk*.exe", $asset.browser_download_url
}
return main
