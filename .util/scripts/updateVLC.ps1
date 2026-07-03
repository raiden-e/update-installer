function main {
    param()
    $page = Invoke-WebRequest 'https://www.videolan.org/vlc/download-windows.html' -UseBasicParsing
    $href = $page.Links.href | ? { $_ -like "*win64.exe" } | Select-Object -First 1
    if (-not $href) { throw "No VLC win64 download link found" }
    $link = if ($href -match '^https?://') { $href } else { "https://$($href.TrimStart('/'))" }
    $file = Split-Path $link -Leaf
    return "VLC MediaPlayer", $file, "vlc*win64.exe", $link
}
return main
