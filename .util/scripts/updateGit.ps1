function main {
    param()
    $rest = Invoke-RestMethod "https://api.github.com/repos/git-for-windows/git/releases/latest"
    $asset = $rest.assets | ? Name -like "Git*64-bit.exe"
    $filename = $asset.name
    $link = $asset.browser_download_url
    return "Git", $filename, "Git*64-bit.exe", $link
}
return main