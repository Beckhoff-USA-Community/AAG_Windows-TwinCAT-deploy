# @Title: Set CPU Core Isolation
# @Description: Configures CPU core isolation for TwinCAT real-time performance
# @Phase: 02-SystemConfiguration
# @Order: 01
# @Dependencies: None
# @Optional: false

# Set Core Isolation
Write-Log "Configuring CPU core isolation..." "SUCCESS"

# Isolate one CPU core using bcdedit
$logicalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$logicalProcessorsNew = $logicalProcessors - 1

Write-Log "  Total logical processors: $logicalProcessors"
Write-Log "  Configuring shared processors: $logicalProcessorsNew"
Write-Log "  Command: bcdedit /set numproc $logicalProcessorsNew"

try {
    Start-Process -Wait -WindowStyle Hidden -FilePath "bcdedit" -ArgumentList "/set", "numproc", "$logicalProcessorsNew"
    Write-Log "  ✓ Core isolation configured: $logicalProcessors -> $logicalProcessorsNew shared cores" "SUCCESS"
} catch {
    Write-Error "Failed to configure core isolation: $_"
    return $false
}

return $true