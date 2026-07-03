function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $asset = $rest.assets | ? Name -like "Git*64-bit.exe" | Select-Object -First 1
    if (-not $asset) { throw "No Git 64-bit installer asset found" }
    return "Git", $asset.name, "Git*64-bit.exe", $asset.browser_download_url
}
return main
