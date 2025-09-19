# @Title: Copy HMI Server Configuration
# @Description: Copies HMI Server configuration file to system location
# @Phase: 03-TwinCATConfiguration
# @Order: 04
# @Dependencies: None
# @Optional: false

# Copy HMI Server config file
Write-Log "Copying HMI Server configuration..." "SUCCESS"

$sourceFile = Join-Path (Get-FilesPath) "HMI PROJECTS\TcHmiSrv.Service.Config.json"
$targetPath = "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server"
$targetFile = Join-Path $targetPath "TcHmiSrv.Service.Config.json"

if (-not (Test-Path $sourceFile)) {
    Write-Error "HMI config file not found: $sourceFile"
    return $false
}

Write-Log "  Source: $sourceFile"
Write-Log "  Target: $targetFile"

New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
Copy-Item $sourceFile $targetFile -Force
Write-Log "  ✓ HMI Server config copied successfully" "SUCCESS"

return $true