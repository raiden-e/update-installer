function main {
    param()
    $mainlink = 'https://files.gpg4win.org/'
    $page = Invoke-WebRequest -UseBasicParsing $mainlink
    $latestLink = $page.links.href | ? { $_ -match "gpg4win-(\d|\.)+\.exe$" } | Select-Object -Last 1
    return "GPG", "$latestLink", "gpg4win*.exe", "$mainlink/$latestLink"
}
return main
