function main {
    param()
    $link = "https://packages.vmware.com/tools/releases/latest/windows/x64/"
    $content = Invoke-WebRequest $link -UseBasicParsing
    $file = $content.Links.href | Select-Object -Last 1
    return "VMWare Tools", $file, "VMware-tools-*-x86_64.exe", "$link/$file"
}
return main