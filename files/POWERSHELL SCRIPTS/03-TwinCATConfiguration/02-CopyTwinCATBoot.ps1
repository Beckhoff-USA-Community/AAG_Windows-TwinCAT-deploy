# @Title: Copy TwinCAT Boot Configuration
# @Description: Copies TwinCAT boot folder with configuration files
# @Phase: 03-TwinCATConfiguration
# @Order: 02
# @Dependencies: None
# @Optional: false

# Copy TwinCAT boot folder
Write-Log "Copying TwinCAT boot folder..." "SUCCESS"

$bootBasePath = Join-Path (Get-FilesPath) "TWINCAT BOOT FOLDER"
$bootFolders = Get-ChildItem -Path $bootBasePath -Directory | Where-Object { $_.Name -ne ".git" }

if ($bootFolders.Count -eq 0) {
    Write-Error "No TwinCAT boot folders found in: $bootBasePath"
    return $false
}

$sourcePath = $bootFolders[0].FullName
$targetPath = "C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot"

Write-Log "  Found boot folder: $($bootFolders[0].Name)"

Write-Log "  Source: $sourcePath"
Write-Log "  Target: $targetPath"

New-Item -Path (Split-Path $targetPath) -ItemType Directory -Force | Out-Null
if (Test-Path $targetPath) {
    Remove-Item $targetPath -Recurse -Force
}
Copy-Item $sourcePath $targetPath -Recurse
Write-Log "  ✓ TwinCAT boot folder copied successfully" "SUCCESS"

return $true