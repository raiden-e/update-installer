function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/microsoft/PowerToys/releases/latest"
    $asset = $rest.assets | ? { $_.Name -like "*x64.exe" -and $_.Name -notlike "*User*" } | Select-Object -First 1
    if (-not $asset) { throw "No PowerToys x64 installer asset found" }
    return "PowerToys", $asset.Name, "PowerToys*.exe", $asset.browser_download_url
}
return main
