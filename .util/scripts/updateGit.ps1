function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $asset = $rest.assets | Where-Object { $_.name -like "Git*64-bit.exe" }
    $filename = $asset.name
    $link = $asset.browser_download_url
    return "Git", $filename, "Git*64-bit.exe", $link
}
return main