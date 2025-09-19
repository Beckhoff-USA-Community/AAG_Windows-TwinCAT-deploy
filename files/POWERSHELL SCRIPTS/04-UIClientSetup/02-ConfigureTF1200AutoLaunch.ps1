# @Title: Configure TF1200 Auto-Launch
# @Description: Sets up TF1200 UI Client to launch automatically with TwinCAT
# @Phase: 04-UIClientSetup
# @Order: 02
# @Dependencies: 01-ConfigureTF1200.ps1
# @Optional: false

# Configure TF1200 Auto-Launch
Write-Log "Configuring TF1200 UI Client auto-launch..." "SUCCESS"

$sourceShortcut = "C:\Users\Public\Desktop\TwinCAT UI Client.lnk"
$startupPath = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Target\StartUp"
$targetShortcut = Join-Path $startupPath "TwinCAT UI Client.lnk"

Write-Log "  Source shortcut: $sourceShortcut"
Write-Log "  Startup folder: $startupPath"
Write-Log "  Target shortcut: $targetShortcut"

# Check if source shortcut exists
if (-not (Test-Path $sourceShortcut)) {
    Write-Error "TF1200 shortcut not found: $sourceShortcut"
    Write-Error "Please ensure TF1200.UiClient.XAR package is installed"
    return $false
}

# Create startup directory if it doesn't exist
if (-not (Test-Path $startupPath)) {
    try {
        New-Item -Path $startupPath -ItemType Directory -Force | Out-Null
        Write-Log "  Created startup directory: $startupPath"
    } catch {
        Write-Error "Failed to create startup directory: $_"
        return $false
    }
}

try {
    # Copy the shortcut to the startup folder
    Copy-Item $sourceShortcut $targetShortcut -Force
    Write-Log "  ✓ TF1200 UI Client shortcut copied to TwinCAT startup folder" "SUCCESS"
    Write-Log "  ✓ TF1200 UI Client will now auto-launch with TwinCAT system" "SUCCESS"
} catch {
    Write-Error "Failed to copy TF1200 shortcut: $_"
    return $false
}

return $true