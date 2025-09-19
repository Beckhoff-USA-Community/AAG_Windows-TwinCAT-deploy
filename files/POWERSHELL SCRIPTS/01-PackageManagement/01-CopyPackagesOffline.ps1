# @Title: Copy TwinCAT Packages
# @Description: Copies offline TcPkg packages to system cache
# @Phase: 01-PackageManagement
# @Order: 01
# @Dependencies: None
# @Optional: false

# Copy packagesoffline folder
Write-Log "Copying TcPkg packages folder..." "SUCCESS"

$tcpkgBasePath = Join-Path (Get-FilesPath) "TCPKG PACKAGES"
$packagesFolders = Get-ChildItem -Path $tcpkgBasePath -Directory | Where-Object { $_.Name -ne ".git" }

if ($packagesFolders.Count -eq 0) {
    Write-Log "No package folders found in: $tcpkgBasePath" "ERROR"
    return $false
}

$sourcePath = $packagesFolders[0].FullName
$targetPath = "C:\packagesoffline"

Write-Log "  Found packages folder: $($packagesFolders[0].Name)"

Write-Log "  Source: $sourcePath"
Write-Log "  Target: $targetPath"

if (Test-Path $targetPath) {
    Remove-Item $targetPath -Recurse -Force
}
Copy-Item $sourcePath $targetPath -Recurse
Write-Log "  ✓ Packages copied successfully" "SUCCESS"

return $true