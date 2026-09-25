param([Parameter(Mandatory=$true)][string]$Root)

$ErrorActionPreference = 'Stop'
$rootPath = (Resolve-Path -LiteralPath $Root).Path.TrimEnd('\', '/')
$spssPath = $rootPath.Replace('\', '/').Replace("'", "''")
$anchor = "CD '$spssPath'."
$marker = '* BOOKROOT-AUTO-CONFIGURED.'
$syntaxDir = Join-Path $rootPath 'spss'
$files = @(Get-ChildItem -LiteralPath $syntaxDir -Filter '*.sps' -File)
if ($files.Count -eq 0) { throw 'No SPSS chapter files were found.' }

$encoding = New-Object System.Text.UTF8Encoding($false)
foreach ($file in $files) {
    $lines = [System.IO.File]::ReadAllLines($file.FullName, [System.Text.Encoding]::UTF8)
    $found = 0
    for ($i = 0; $i -lt $lines.Length - 1; $i++) {
        if ($lines[$i] -eq $marker) {
            $lines[$i + 1] = $anchor
            $found++
        }
    }
    if ($found -ne 1) { throw "Expected one path marker in $($file.Name); found $found." }
    [System.IO.File]::WriteAllLines($file.FullName, $lines, $encoding)
}

Write-Host "Prepared $($files.Count) SPSS syntax files for this folder."
Write-Host "Data and syntax are together in: $rootPath"
