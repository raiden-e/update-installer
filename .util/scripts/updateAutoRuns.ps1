function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://learn.microsoft.com/en-us/sysinternals/downloads/"
    $ver = [regex]::Matches($page.Content, '(?:Autoruns)(?:<.*>|\n)+?(v(?:\d+\.)+\d+)').Groups[1].Value
    return "Autoruns", "Autoruns-$ver.zip", "Autoruns*.zip", "https://download.sysinternals.com/files/Autoruns.zip"
}
return main