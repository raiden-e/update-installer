function main {
    $rest = Invoke-RestMethod "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest"
    $asset = $rest.assets | Where-Object { $_.name -like "npp*Installer.x64.exe" }
    $filename = $asset.name
    $link = $asset.browser_download_url
    return "Notepad++", $filename, "npp*Installer.x64.exe", $link
}
return main