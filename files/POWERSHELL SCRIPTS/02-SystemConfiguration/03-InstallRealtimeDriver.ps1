# @Title: Install Realtime Ethernet Driver
# @Description: Installs TwinCAT realtime Ethernet driver for fieldbus operations
# @Phase: 02-SystemConfiguration
# @Order: 03
# @Dependencies: 02-RenameEthernetAdapters.ps1
# @Optional: false

# Install realtime Ethernet driver
Write-Log "Installing realtime Ethernet driver..." "SUCCESS"

$driverPath = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\System\TcRteInstall.exe"
$adapterName = "Fieldbus"  # This should match the renamed adapter

Write-Log "  Driver: $driverPath"
Write-Log "  Target adapter: $adapterName"

if (-not (Test-Path $driverPath)) {
    Write-Error "TcRteInstall.exe not found at: $driverPath"
    return $false
}

# Method 1: Try -installnic first (preferred method)
$installnicArgs = "-installnic `"$adapterName`" /S"
Write-Log "  Method 1 - Arguments: $installnicArgs"

try {
    $process = Start-Process -Wait -FilePath $driverPath -ArgumentList "-installnic", "`"$adapterName`"", "/S" -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Log "  ✓ Realtime Ethernet driver installed using -installnic method" "SUCCESS"
        return $true
    } else {
        Write-Log "  Method 1 failed with exit code: $($process.ExitCode)" "WARN"
    }
} catch {
    Write-Log "  Method 1 failed with exception: $_" "WARN"
}

# Method 2: Fallback to -installfilter (legacy method)
Write-Log "  Attempting fallback method..." "WARN"
$installfilterArgs = "-installfilter $adapterName"
Write-Log "  Method 2 - Arguments: $installfilterArgs"

try {
    $process = Start-Process -Wait -FilePath $driverPath -ArgumentList "-installfilter", $adapterName -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Log "  ✓ Realtime Ethernet driver installed using -installfilter method" "SUCCESS"
        return $true
    } else {
        Write-Error "Method 2 also failed with exit code: $($process.ExitCode)"
        return $false
    }
} catch {
    Write-Error "Both installation methods failed. Final error: $_"
    return $false
}