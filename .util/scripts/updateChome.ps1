function main {
    $notesLink = "https://omahaproxy.appspot.com/json"
    $notes = Invoke-WebRequest -Uri $notesLink -UseBasicParsing

    $data = $notes.Content | ConvertFrom-Json
    $data = $data.versions | Where-Object { $_.channel -eq "stable" -and $_.os -eq "win64" }
    $version = $data.version

    return "Chrome", "Chrome-$version.msi", "Chrome-*.msi", "https://dl.google.com/chrome/install/googlechromestandaloneenterprise64.msi"
}
return main