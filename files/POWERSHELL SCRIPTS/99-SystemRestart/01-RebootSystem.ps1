# @Title: Reboot System
# @Description: Reboots the system to activate all TwinCAT configurations
# @Phase: 99-SystemRestart
# @Order: 01
# @Dependencies: None
# @Optional: true

# Reboot system to activate all configurations
Write-Log "Rebooting system to activate TwinCAT configurations..." "SUCCESS"

Write-Log "  System will reboot in 10 seconds..." "WARN"
Write-Log "  Press Ctrl+C to cancel"
Start-Sleep -Seconds 10

Write-Log "  Initiating system restart..." "WARN"
Restart-Computer -Force

return $true