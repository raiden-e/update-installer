function main {
    param()
    $notes = Invoke-WebRequest -UseBasicParsing "https://www.mozilla.org/en-US/firefox/notes/"
    $currentVersion = [regex]::Matches($notes.Content, '<div class="c-release-version">(.+)</div>').Groups[1].Value
    return "Mozilla Firefox", "firefox-$currentVersion.exe", "firefox*.exe", "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
}
return main