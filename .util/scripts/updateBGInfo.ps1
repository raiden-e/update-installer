function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://learn.microsoft.com/en-us/sysinternals/downloads/"
    $ver = [regex]::Matches($page.Content, '(?:BgInfo)(?:<.*>|\n)+?(v(?:\d+\.)+\d+)').Groups[1].Value
    return "BGInfo", "Bginfo64-$ver.exe", "Bginfo*.exe", "https://live.sysinternals.com/Bginfo.exe"
}
return main