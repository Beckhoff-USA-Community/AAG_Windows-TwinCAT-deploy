# TwinCAT Bootstrap Playbook
# Automates the installation and configuration of TwinCAT on CX20x3 Windows 11 systems
# Based on: StepsToBootStrapTwinCATInstall.txt

param(
    [switch]$SkipReboot
)

# Global variables
$ScriptRoot = $PSScriptRoot
$ArtifactsPath = Join-Path $ScriptRoot "artifacts"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TwinCAT Bootstrap Playbook" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Copy packagesoffline folder
function Step-CopyPackagesOffline {
    Write-Host "Copying TcPkg packages folder..." -ForegroundColor Green

    $tcpkgBasePath = Join-Path $ArtifactsPath "TCPKG PACKAGES"
    $packagesFolders = Get-ChildItem -Path $tcpkgBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($packagesFolders.Count -eq 0) {
        Write-Error "No package folders found in: $tcpkgBasePath"
        return $false
    }

    $sourcePath = $packagesFolders[0].FullName
    $targetPath = "C:\packagesoffline"

    Write-Host "  Found packages folder: $($packagesFolders[0].Name)"

    Write-Host "  Source: $sourcePath"
    Write-Host "  Target: $targetPath"

    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $sourcePath $targetPath -Recurse
    Write-Host "  ✓ Packages copied successfully" -ForegroundColor Green

    return $true
}

# Add package source to TcPkg
function Step-AddPackageSource {
    Write-Host "Adding local package source to TcPkg..." -ForegroundColor Green

    $command = 'tcpkg source add -n=local -s="c:\packagesoffline" --priority=1'
    Write-Host "  Command: $command"

    try {
        Invoke-Expression $command
        Write-Host "  ✓ Package source added successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to add package source: $_"
        return $false
    }

    return $true
}

# Install required packages
function Step-InstallPackages {
    Write-Host "Installing required TwinCAT packages..." -ForegroundColor Green

    $packages = @(
        "TwinCAT.Standard.XAR",
        "TF20000.HMIServer.XAR",
        "TF1200.UiClient.XAR"
    )

    foreach ($package in $packages) {
        $command = "tcpkg install $package -y"
        Write-Host "  Installing: $package"

        try {
            Invoke-Expression $command
            Write-Host "  ✓ $package installed successfully" -ForegroundColor Green
        } catch {
            Write-Error "Failed to install $package : $_"
            return $false
        }
    }

    return $true
}

# Install PowerShell modules
function Step-InstallTcXaeMgmt {
    Write-Host "Installing PowerShell modules..." -ForegroundColor Green

    $modulesBasePath = Join-Path $ArtifactsPath "POWERSHELL MODULES"
    $modulesFolders = Get-ChildItem -Path $modulesBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($modulesFolders.Count -eq 0) {
        Write-Error "No PowerShell modules found in: $modulesBasePath"
        return $false
    }

    $success = $true
    foreach ($moduleFolder in $modulesFolders) {
        $sourcePath = $moduleFolder.FullName
        $targetPath = "C:\Program Files\WindowsPowerShell\7\Modules\$($moduleFolder.Name)"

        Write-Host "  Installing module: $($moduleFolder.Name)"

        Write-Host "    Source: $sourcePath"
        Write-Host "    Target: $targetPath"

        try {
            if (Test-Path $targetPath) {
                Remove-Item $targetPath -Recurse -Force
            }
            New-Item -Path (Split-Path $targetPath) -ItemType Directory -Force | Out-Null
            Copy-Item $sourcePath $targetPath -Recurse
            Write-Host "    ✓ $($moduleFolder.Name) module installed successfully" -ForegroundColor Green
        } catch {
            Write-Error "Failed to install module $($moduleFolder.Name): $_"
            $success = $false
        }
    }

    if (-not $success) {
        return $false
    }

    return $true
}

# Set execution policy
function Step-SetExecutionPolicy {
    Write-Host "Setting PowerShell execution policy..." -ForegroundColor Green

    try {
        Set-ExecutionPolicy RemoteSigned -Force
        Write-Host "  ✓ Execution policy set to RemoteSigned" -ForegroundColor Green
    } catch {
        Write-Error "Failed to set execution policy: $_"
        return $false
    }

    return $true
}

# Import TcXaeMgmt module
function Step-ImportModule {
    Write-Host "Importing TcXaeMgmt module..." -ForegroundColor Green

    try {
        Import-Module TcXaeMgmt -Force
        Write-Host "  ✓ TcXaeMgmt module imported successfully" -ForegroundColor Green
    } catch {
        Write-Error "Failed to import TcXaeMgmt module: $_"
        return $false
    }

    return $true
}

# Set Core Isolation
function Step-SetCoreIsolation {
    Write-Host "Configuring CPU core isolation..." -ForegroundColor Green

    try {
        Set-RTimeCpuSettings -SharedCores 3 -force
        Write-Host "  ✓ Core isolation configured (3 shared cores)" -ForegroundColor Green
    } catch {
        Write-Warning "TcXaeMgmt method failed, using alternative approach..."

        # Alternative method using bcdedit
        $logicalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
        $logicalProcessorsNew = $logicalProcessors - 1

        Start-Process -Wait -WindowStyle Hidden -FilePath "bcdedit" -ArgumentList "/set numproc $logicalProcessorsNew"
        Write-Host "  ✓ Core isolation configured: $logicalProcessors -> $logicalProcessorsNew shared cores" -ForegroundColor Green
    }

    return $true
}

# Rename Ethernet adapters
function Step-RenameEthernetAdapters {
    Write-Host "Renaming Ethernet adapters..." -ForegroundColor Green

    $adapterMappings = @{
        "Ethernet 4" = "Fieldbus"
        "Ethernet 3" = "Programming"
    }

    foreach ($oldName in $adapterMappings.Keys) {
        $newName = $adapterMappings[$oldName]
        Write-Host "  Renaming '$oldName' to '$newName'"

        try {
            $adapter = Get-NetAdapter -Name $oldName -ErrorAction SilentlyContinue
            if ($adapter) {
                Rename-NetAdapter -Name $oldName -NewName $newName
                Write-Host "  ✓ Renamed $oldName to $newName" -ForegroundColor Green
            } else {
                Write-Warning "Adapter '$oldName' not found, skipping..."
            }
        } catch {
            Write-Warning "Failed to rename $oldName to $newName : $_"
        }
    }

    return $true
}

# Install realtime Ethernet driver
function Step-InstallRealtimeDriver {
    Write-Host "Installing realtime Ethernet driver..." -ForegroundColor Green

    $driverPath = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\System\TcRteInstall.exe"
    $arguments = "-installfilter Fieldbus"

    Write-Host "  Driver: $driverPath"
    Write-Host "  Arguments: $arguments"

    if (Test-Path $driverPath) {
        try {
            Start-Process -Wait $driverPath -ArgumentList $arguments
            Write-Host "  ✓ Realtime Ethernet driver installed" -ForegroundColor Green
        } catch {
            Write-Error "Failed to install realtime driver: $_"
            return $false
        }
    } else {
        Write-Warning "TcRteInstall.exe not found at expected location"
    }

    return $true
}

# Set TwinCAT to start in run mode
function Step-SetTwinCATRunMode {
    Write-Host "Configuring TwinCAT to start in run mode..." -ForegroundColor Green

    # Determine registry path based on architecture
    if ([System.Environment]::Is64BitProcess) {
        $RegPath = "HKLM:\SOFTWARE\WOW6432Node\Beckhoff\TwinCAT3\System"
    } else {
        $RegPath = "HKLM:\SOFTWARE\Beckhoff\TwinCAT3\System"
    }

    Write-Host "  Registry path: $RegPath"
    Write-Host "  Setting SysStartupState = 5 (Run mode)"

    try {
        Set-ItemProperty $RegPath "SysStartupState" -Value 5 -Type DWord -PassThru
        Write-Host "  ✓ TwinCAT configured for run mode on boot" -ForegroundColor Green
    } catch {
        Write-Error "Failed to set TwinCAT startup state: $_"
        return $false
    }

    return $true
}

# Copy TwinCAT boot folder
function Step-CopyTwinCATBoot {
    Write-Host "Copying TwinCAT boot folder..." -ForegroundColor Green

    $bootBasePath = Join-Path $ArtifactsPath "TWINCAT BOOT FOLDER"
    $bootFolders = Get-ChildItem -Path $bootBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($bootFolders.Count -eq 0) {
        Write-Error "No TwinCAT boot folders found in: $bootBasePath"
        return $false
    }

    $sourcePath = $bootFolders[0].FullName
    $targetPath = "C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot"

    Write-Host "  Found boot folder: $($bootFolders[0].Name)"

    Write-Host "  Source: $sourcePath"
    Write-Host "  Target: $targetPath"

    New-Item -Path (Split-Path $targetPath) -ItemType Directory -Force | Out-Null
    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $sourcePath $targetPath -Recurse
    Write-Host "  ✓ TwinCAT boot folder copied successfully" -ForegroundColor Green

    return $true
}

# Copy HMI project to service folder
function Step-CopyHMIProject {
    Write-Host "Copying HMI project to service folder..." -ForegroundColor Green

    $hmiBasePath = Join-Path $ArtifactsPath "HMI PROJECTS"
    $hmiFolders = Get-ChildItem -Path $hmiBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($hmiFolders.Count -eq 0) {
        Write-Error "No HMI project folders found in: $hmiBasePath"
        return $false
    }

    $sourcePath = $hmiFolders[0].FullName
    $targetPath = "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service"

    Write-Host "  Found HMI project: $($hmiFolders[0].Name)"

    Write-Host "  Source: $sourcePath"
    Write-Host "  Target: $targetPath"

    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    Copy-Item "$sourcePath\*" $targetPath -Recurse -Force
    Write-Host "  ✓ HMI project '$($hmiFolders[0].Name)' copied successfully" -ForegroundColor Green

    return $true
}

# Copy HMI Server config file
function Step-CopyHMIConfig {
    Write-Host "Copying HMI Server configuration..." -ForegroundColor Green

    $sourceFile = Join-Path $ArtifactsPath "HMI PROJECTS\TcHmiSrv.Service.Config.json"
    $targetPath = "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server"
    $targetFile = Join-Path $targetPath "TcHmiSrv.Service.Config.json"

    if (-not (Test-Path $sourceFile)) {
        Write-Error "HMI config file not found: $sourceFile"
        return $false
    }

    Write-Host "  Source: $sourceFile"
    Write-Host "  Target: $targetFile"

    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    Copy-Item $sourceFile $targetFile -Force
    Write-Host "  ✓ HMI Server config copied successfully" -ForegroundColor Green

    return $true
}

# Reboot system
function Step-RebootSystem {
    Write-Host "System reboot..." -ForegroundColor Green

    if ($SkipReboot) {
        Write-Host "  Reboot skipped (--SkipReboot specified)" -ForegroundColor Yellow
        return $true
    }

    Write-Host "  System will reboot in 10 seconds..." -ForegroundColor Yellow
    Write-Host "  Press Ctrl+C to cancel"
    Start-Sleep -Seconds 10
    Restart-Computer -Force

    return $true
}

# Main execution
function Main {
    Write-Host "Starting TwinCAT bootstrap process..."
    Write-Host ""

    # Verify artifacts folder exists
    if (-not (Test-Path $ArtifactsPath)) {
        Write-Error "Artifacts folder not found: $ArtifactsPath"
        Write-Error "Please ensure the script is run from the correct directory"
        exit 1
    }

    # Execute all steps
    $steps = @(
        { Step-CopyPackagesOffline },
        { Step-AddPackageSource },
        { Step-InstallPackages },
        { Step-InstallTcXaeMgmt },
        { Step-SetExecutionPolicy },
        { Step-ImportModule },
        { Step-SetCoreIsolation },
        { Step-RenameEthernetAdapters },
        { Step-InstallRealtimeDriver },
        { Step-SetTwinCATRunMode },
        { Step-CopyTwinCATBoot },
        { Step-CopyHMIProject },
        { Step-CopyHMIConfig },
        { Step-RebootSystem }
    )

    foreach ($step in $steps) {
        try {
            $result = & $step
            if (-not $result) {
                Write-Error "Step failed. Aborting playbook execution."
                exit 1
            }
        } catch {
            Write-Error "Step encountered an error: $_"
            exit 1
        }

        Write-Host ""
    }

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "BOOTSTRAP COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
}

# Execute main function
Main