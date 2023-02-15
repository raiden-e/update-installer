function main {
    param()
    $page = Invoke-WebRequest 'https://www.videolan.org/vlc/download-windows.html' -UseBasicParsing
    $link = "https://" + ($page.Links.href | ? { $_ -like "*win64.exe" }).TrimStart("/")
    $file = $link.Substring($link.LastIndexOf("/") + 1)
    return "VLC MediaPlayer", $file, "vlc*win64.exe", "$link"
}
return main
