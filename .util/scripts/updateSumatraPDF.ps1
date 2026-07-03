function main {
    param()
    $page = Invoke-WebRequest -UseBasicParsing "https://www.sumatrapdfreader.org/download-free-pdf-viewer"
    $href = ($page.Links | Where-Object { $_.href -match 'SumatraPDF.*64.*install\.exe' } | Select-Object -First 1).href
    if (-not $href) { throw "No SumatraPDF installer link found" }
    $link = if ($href -match '^https?://') { $href } else { "https://www.sumatrapdfreader.org$href" }
    $filename = Split-Path $link -Leaf
    return "SumatraPDF", $filename, "SumatraPDF*.exe", $link
}
return main
