function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://www.microsoft.com/en-us/download/confirmation.aspx?id=49117"
    $link = ($page.links | ? href -Match '/officedeploymenttool_\d{5}-\d{5}\.exe$').href | Select-Object -First 1
    $filename = $link.Substring($link.LastIndexOf("/") + 1)
    return "Office Deployment", "$filename", "officedeploymenttool*.exe", "$link"
}
return main