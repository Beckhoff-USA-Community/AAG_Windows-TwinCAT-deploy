# @Title: Configure TF1200 UI Client
# @Description: Configures TF1200 UI Client startup URL and settings | TF1200.UiClient.XAR = 1.5.0
# @Phase: 04-UIClientSetup
# @Order: 01
# @Dependencies: None
# @Optional: false

# Configure TF1200 UI Client
Write-Log "Configuring TF1200 UI Client..." "SUCCESS"

$configPath = "$env:APPDATA\Beckhoff\TF1200-UI-Client"
$configFile = Join-Path $configPath "config.json"
$tf1200Exe = "C:\Program Files (x86)\Beckhoff\TwinCAT\Functions\TF1200-UI-Client\TF1200-UI-Client.exe"

Write-Log "  Config path: $configPath"
Write-Log "  Config file: $configFile"
Write-Log "  TF1200 executable: $tf1200Exe"

# Check if TF1200 executable exists
if (-not (Test-Path $tf1200Exe)) {
    Write-Error "TF1200 UI Client executable not found: $tf1200Exe"
    Write-Error "Please ensure TF1200.UiClient.XAR package is installed"
    return $false
}

# If config file doesn't exist, launch TF1200 to create it
if (-not (Test-Path $configFile)) {
    Write-Log "  Config file not found, launching TF1200 UI Client to create initial config..."

    try {
        # Start TF1200 UI Client (hidden window, no console output)
        $tf1200Process = Start-Process -FilePath $tf1200Exe -WindowStyle Hidden -PassThru
        Write-Log "  TF1200 UI Client started (PID: $($tf1200Process.Id))"

        # Wait for config file to be created (max 30 seconds)
        $timeout = 30
        $elapsed = 0
        while (-not (Test-Path $configFile) -and $elapsed -lt $timeout) {
            Start-Sleep -Seconds 1
            $elapsed++
            if ($elapsed % 5 -eq 0) {
                Write-Log "  Waiting for config file creation... ($elapsed/$timeout seconds)"
            }
        }

        if (-not (Test-Path $configFile)) {
            Write-Error "Config file was not created after $timeout seconds"
            # Kill the process if it's still running
            if (-not $tf1200Process.HasExited) {
                $tf1200Process.Kill()
            }
            return $false
        }

        Write-Log "  Config file created successfully"

        # Kill the TF1200 process so we can modify the config
        if (-not $tf1200Process.HasExited) {
            $tf1200Process.Kill()
            $tf1200Process.WaitForExit(5000)  # Wait up to 5 seconds for clean exit
            Write-Log "  TF1200 UI Client stopped"
        }

    } catch {
        Write-Error "Failed to launch TF1200 UI Client: $_"
        return $false
    }
}

try {
    # Read existing config.json
    $configContent = Get-Content -Path $configFile -Raw -Encoding UTF8
    $config = $configContent | ConvertFrom-Json

    # Update the startUrl
    $config.startUrl = "http://127.0.0.1:2010/"

    # Write back the modified config
    $configJson = $config | ConvertTo-Json -Depth 10
    $configJson | Set-Content -Path $configFile -Encoding UTF8

    Write-Log "  ✓ TF1200 UI Client startUrl updated to: http://127.0.0.1:2010/" "SUCCESS"
    Write-Log "  ✓ TF1200 configuration complete. UI Client will use new URL on next launch." "SUCCESS"

} catch {
    Write-Error "Failed to configure TF1200 UI Client: $_"
    return $false
}

return $true