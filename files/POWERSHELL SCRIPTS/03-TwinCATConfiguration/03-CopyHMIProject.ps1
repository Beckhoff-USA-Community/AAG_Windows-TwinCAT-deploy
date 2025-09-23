# @Title: Copy HMI Projects
# @Description: Copies HMI projects to TwinCAT HMI Server service folder
# @Phase: 03-TwinCATConfiguration
# @Order: 03
# @Dependencies: None
# @Optional: false

# Copy HMI project to service folder
Write-Log "Copying HMI projects to service folder..." "SUCCESS"

$hmiBasePath = Join-Path (Get-FilesPath) "HMI PROJECTS"
$hmiFolders = Get-ChildItem -Path $hmiBasePath -Directory | Where-Object { $_.Name -ne ".git" -and $_.Name -ne "TcHmiSrv.Service.Config.json" }

if ($hmiFolders.Count -eq 0) {
    Write-Error "No HMI project folders found in: $hmiBasePath"
    return $false
}

$servicePath = "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service"
New-Item -Path $servicePath -ItemType Directory -Force | Out-Null

Write-Log "  Found $($hmiFolders.Count) HMI project(s):"

$success = $true
foreach ($hmiFolder in $hmiFolders) {
    $sourcePath = $hmiFolder.FullName
    $targetPath = Join-Path $servicePath $hmiFolder.Name

    Write-Log "    Copying: $($hmiFolder.Name)"
    Write-Log "      Source: $sourcePath"
    Write-Log "      Target: $targetPath"

    try {
        if (Test-Path $targetPath) {
            Remove-Item $targetPath -Recurse -Force
        }
        Copy-Item $sourcePath $targetPath -Recurse
        Write-Log "      ✓ $($hmiFolder.Name) copied successfully" "SUCCESS"
    } catch {
        Write-Error "Failed to copy HMI project $($hmiFolder.Name): $_"
        $success = $false
    }
}

if (-not $success) {
    return $false
}

Write-Log "  ✓ All HMI projects copied successfully" "SUCCESS"
return $true