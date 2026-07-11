
# ======================================================
# Script: Find CSS Selector Usage (PowerShell Equivalent to Grep)
# Goal: Recursively search multiple file types for old .btn-* class usage.
# NOTE: Runs in the current working directory context.
# ======================================================

# --- Configuration ---
$rootDir = ".\mission-editor\src" # Start searching from the 'src' folder inside the project root
$oldButtonPattern = '(u-btn-[a-z0-9\-]+)'
$extensionsToSearch = @("*.js", "*.vue", "*.css")
# Patterns: \. means literal dot, [a-z0-9\-] is for letters/numbers/dashes

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Starting comprehensive search for .btn-* selectors." -ForegroundColor Green
Write-Host "Target Directory: $rootPath" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor Cyan

$foundCount = 0

# Get all relevant files to check
$targetFiles = Get-ChildItem -Path $rootDir -Recurse -Include $extensionsToSearch -ErrorAction SilentlyContinue;


foreach ($file in $targetFiles) {
    Write-Host "`n[Scanning File: $($file.FullName)]" -ForegroundColor Yellow

    try {
        # Use Select-String to find all matches, ignoring case (-I for case-insensitive)
        $matches = Get-Content -LiteralPath $file.FullName | Select-String -Pattern $oldButtonPattern -AllMatches -CaseSensitive:$false;

        if ($matches) {
            Write-Host "     FOUND MATCHES: $($matches.Count)" -ForegroundColor Green
            $foundCount += 1

            # Loop through every match found in this file to display line number and context
            foreach ($match in $matches) {
                $lineNum = $match.LineNumber;
                $matchedText = $match.Value;
                Write-Host "   [L$($lineNum)] Found: $($matchedText)" -ForegroundColor Cyan
            }
        } else {
            Write-Host "     No instances of .btn-* found." -ForegroundColor DarkGray
        }

    } catch {
        Write-Warning "Skipping file due to error: $_"
    }
}

# Final Summary
Write-Host "`n=============================================" -ForegroundColor Cyan
if ($foundCount -gt 0) {
    Write-Host "  SUCCESS! Found usage patterns in $foundCount files." -ForegroundColor Green
} else {
    Write-Host "  Scan Complete: No instances of `.btn-*` found across the specified file types and directories." -ForegroundColor Yellow
}
Write-Host "=============================================" -ForegroundColor Cyan