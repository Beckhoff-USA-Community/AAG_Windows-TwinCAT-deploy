# @Title: Add Package Source
# @Description: Adds local package source to TcPkg
# @Phase: 01-PackageManagement
# @Order: 02
# @Dependencies: 01-CopyPackagesOffline.ps1
# @Optional: false

# Add package source to TcPkg
Write-Log "Adding local package source to TcPkg..." "SUCCESS"

Write-Log "  Command: tcpkg source add -n=local -s=`"c:\packagesoffline`" --priority=1"

try {
    Start-Process -Wait -WindowStyle Hidden -FilePath "tcpkg" -ArgumentList "source", "add", "-n=local", "-s=c:\packagesoffline", "--priority=1"
    Write-Log "  ✓ Package source added successfully" "SUCCESS"
} catch {
    Write-Error "Failed to add package source: $_"
    return $false
}

return $true