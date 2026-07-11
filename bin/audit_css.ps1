# audit_css.ps1
<# ----------------------------------------------------
   Audits a repository for all CSS style definitions.
   - Lists every *.css file under the supplied root.
   - Optionally prints the selectors defined in each file.
   ---------------------------------------------------- #>

param(
    [string]$RootDir = ".\mission-editor\src",          # Default to your Vue app folder
    [switch]$ShowSelectors                        # If set, list selectors per file
)

# Resolve to an absolute path and normalise slashes
$rootPath = Resolve-Path -LiteralPath $RootDir | ForEach-Object {$_.Path}

Write-Host "   Scanning for CSS files in:" -ForegroundColor Cyan
Write-Host "$rootPath" -ForegroundColor White

# Gather all .css files recursively
$cssFiles = Get-ChildItem -Path $rootPath -Recurse -Filter *.css -File

if ($cssFiles.Count -eq 0) {
    Write-Warning "  No CSS files found under $rootPath."
    return
}

Write-Host "   Found $($cssFiles.Count) CSS file(s):" -ForegroundColor Green

# List relative paths for readability
$cssFiles | ForEach-Object {
    $rel = $_.FullName.Substring($rootPath.Length + 1)
    Write-Host "   • $rel"
}

if ($ShowSelectors) {
    Write-Host " Extracting selectors…" -ForegroundColor Cyan

    foreach ($file in $cssFiles) {
        # Simple regex: starts with a dot, word chars or dash/underscore,
        # followed by optional whitespace then an opening brace
        $selectorPattern = '^[\.\w\-]+[^\{]*\{'

        Write-Host "$($file.FullName):" -ForegroundColor Yellow

        Get-Content -LiteralPath $file.FullName | Select-String -Pattern $selectorPattern |
            ForEach-Object { $_.Line.Trim() } |
            Where-Object { $_ -ne '' } |
            ForEach-Object { Write-Host "  - $_" }
    }
}

Write-Host "Audit complete." -ForegroundColor Green
