function main {
    param()
    $mainlink = 'https://www.gnupg.org'
    $page = Invoke-WebRequest -UseBasicParsing "$mainlink/download/index.en.html"
    $latestLink = $page.Links.href | ? { $_ -like "*cli*exe" }
    $fileName = $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "GPG", "$fileName", "gnupg*.exe", "$mainlink/$latestLink"
}
return main
