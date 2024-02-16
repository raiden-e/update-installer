function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/microsoft/PowerToys/releases/latest"
    $asset = $rest.assets | ? { $_.Name -like "*x64.exe" -and $_.Name -notlike "*User*" }
    $filename = $asset.Name
    $link = $asset.browser_download_url
    return "PowerToys", $filename, "PowerToys*.msi", $link
}
return main