function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest"
    $asset = $rest.assets | ? { $_.name -like "npp*Installer.x64.exe" } | Select-Object -First 1
    if (-not $asset) { throw "No Notepad++ x64 installer asset found" }
    return "Notepad++", $asset.name, "npp*Installer.x64.exe", $asset.browser_download_url
}
return main
