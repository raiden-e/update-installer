function main {
    $notesLink = "https://www.mozilla.org/en-US/firefox/notes/"
    $notes = Invoke-WebRequest -Uri $notesLink -UseBasicParsing

    $null = $notes.Content -match "<div class=""c-release-version"">.+</div>"
    $currentVersion = $Matches.Values
    $currentVersion = ([xml]$currentVersion).div."#text"

    return "Mozilla Firefox", "firefox-$currentVersion.exe", "firefox*.exe", "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
}
return main