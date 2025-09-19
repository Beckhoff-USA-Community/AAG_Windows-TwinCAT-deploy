# @Title: Set TwinCAT Run Mode on Boot
# @Description: Configures TwinCAT to start in run mode automatically
# @Phase: 03-TwinCATConfiguration
# @Order: 01
# @Dependencies: None
# @Optional: false

# Set TwinCAT to start in run mode
Write-Log "Configuring TwinCAT to start in run mode..." "SUCCESS"

# Determine registry path based on architecture
if ([System.Environment]::Is64BitProcess) {
    $RegPath = "HKLM:\SOFTWARE\WOW6432Node\Beckhoff\TwinCAT3\System"
} else {
    $RegPath = "HKLM:\SOFTWARE\Beckhoff\TwinCAT3\System"
}

Write-Log "  Registry path: $RegPath"
Write-Log "  Setting SysStartupState = 5 (Run mode)"

try {
    Set-ItemProperty $RegPath "SysStartupState" -Value 5 -Type DWord -PassThru
    Write-Log "  ✓ TwinCAT configured for run mode on boot" "SUCCESS"
} catch {
    Write-Error "Failed to set TwinCAT startup state: $_"
    return $false
}

return $true