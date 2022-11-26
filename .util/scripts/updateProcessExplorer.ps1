function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://learn.microsoft.com/en-us/sysinternals/downloads/"
    $ver = [regex]::Matches($page.Content, '(?:Process Explorer)(?:<.*>|\n)+?(v(?:\d+\.)+\d+)').Groups[1].Value
    return "Process Explorer", "ProcessExplorer-$ver.zip", "ProcessExplorer*.zip", "https://download.sysinternals.com/files/ProcessExplorer.zip"
}
return main