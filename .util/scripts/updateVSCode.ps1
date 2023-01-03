function main {
    param()
    $info = Invoke-RestMethod "https://update.code.visualstudio.com/api/update/win32-x64/stable/VERSION"
    $latestLink = $info.url
    $filename =  $latestLink.Substring($latestLink.LastIndexOf("/") + 1)
    return "VS Code", $filename, "VSCodeSetup*.exe", $latestLink
}
return main