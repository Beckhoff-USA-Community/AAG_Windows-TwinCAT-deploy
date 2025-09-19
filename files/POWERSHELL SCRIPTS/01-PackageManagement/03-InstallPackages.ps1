# @Title: Install TwinCAT Packages
# @Description: Installs required TwinCAT packages via TcPkg
# @Phase: 01-PackageManagement
# @Order: 03
# @Dependencies: 02-AddPackageSource.ps1
# @Optional: false

# Install required packages
Write-Log "Installing required TwinCAT packages..." "SUCCESS"

$packages = @(
    "TwinCAT.Standard.XAR",
    "TF2000.HMIServer.XAR",
    "TF1200.UiClient.XAR"
)

foreach ($package in $packages) {
    Write-Log "  Installing: $package"
    Write-Log "  Command: tcpkg install $package -y"

    try {
        Start-Process -Wait -WindowStyle Hidden -FilePath "tcpkg" -ArgumentList "install", $package, "-y"
        Write-Log "  ✓ $package installed successfully" "SUCCESS"
    } catch {
        Write-Error "Failed to install $package : $_"
        return $false
    }
}

return $true