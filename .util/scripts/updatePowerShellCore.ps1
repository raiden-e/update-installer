function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $asset = $rest.assets | Where-Object { $_.name -like "*64*.msi" }
    $filename = $asset.name
    $link = $asset.browser_download_url
    return "PowerShell Core", $filename, "PowerShell*.msi", $link
}
return main