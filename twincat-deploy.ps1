# TwinCAT Deployment Script
# Automates the installation and configuration of TwinCAT on CX20x3 Windows 11 systems
# Based on: StepsToBootStrapTwinCATInstall.txt

param(
    [switch]$SkipReboot = $true
)

# Global variables
$ScriptRoot = $PSScriptRoot
$FilesPath = Join-Path $ScriptRoot "files"

# Initialize logging
$LogFile = Join-Path $ScriptRoot "twincat-deploy.log"
$StartTime = Get-Date

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console with color
    Write-Host $Message -ForegroundColor $Color

    # Write to log file
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

# Start deployment
Write-Log "========================================" "INFO" "Cyan"
Write-Log "TwinCAT Deployment Script" "INFO" "Cyan"
Write-Log "========================================" "INFO" "Cyan"
Write-Log "Started at: $StartTime" "INFO" "Yellow"
Write-Log "Log file: $LogFile" "INFO" "Yellow"
Write-Log ""

# Copy packagesoffline folder
function Step-CopyPackagesOffline {
    Write-Log "Copying TcPkg packages folder..." "INFO" "Green"

    $tcpkgBasePath = Join-Path $FilesPath "TCPKG PACKAGES"
    $packagesFolders = Get-ChildItem -Path $tcpkgBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($packagesFolders.Count -eq 0) {
        Write-Log "No package folders found in: $tcpkgBasePath" "ERROR" "Red"
        return $false
    }

    $sourcePath = $packagesFolders[0].FullName
    $targetPath = "C:\packagesoffline"

    Write-Log "  Found packages folder: $($packagesFolders[0].Name)" "INFO" "White"

    Write-Log "  Source: $sourcePath"
    Write-Log "  Target: $targetPath"

    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $sourcePath $targetPath -Recurse
    Write-Log "  ✓ Packages copied successfully" "INFO" "Green"

    return $true
}

# Add package source to TcPkg
function Step-AddPackageSource {
    Write-Log "Adding local package source to TcPkg..." "INFO" "Green"

    Write-Log "  Command: tcpkg source add -n=local -s=\"c:\packagesoffline\" --priority=1"

    try {
        Start-Process -Wait -WindowStyle Hidden -FilePath "tcpkg" -ArgumentList "source", "add", "-n=local", "-s=c:\packagesoffline", "--priority=1"
        Write-Log "  ✓ Package source added successfully" "INFO" "Green"
    } catch {
        Write-Error "Failed to add package source: $_"
        return $false
    }

    return $true
}

# Install required packages
function Step-InstallPackages {
    Write-Log "Installing required TwinCAT packages..." "INFO" "Green"

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
            Write-Log "  ✓ $package installed successfully" "INFO" "Green"
        } catch {
            Write-Error "Failed to install $package : $_"
            return $false
        }
    }

    return $true
}

# Install PowerShell modules
function Step-InstallTcXaeMgmt {
    Write-Log "Installing PowerShell modules..." "INFO" "Green"

    $modulesBasePath = Join-Path $FilesPath "POWERSHELL MODULES"
    $modulesFolders = Get-ChildItem -Path $modulesBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($modulesFolders.Count -eq 0) {
        Write-Error "No PowerShell modules found in: $modulesBasePath"
        return $false
    }

    $success = $true
    foreach ($moduleFolder in $modulesFolders) {
        $sourcePath = $moduleFolder.FullName
        $targetPath = "C:\Program Files\WindowsPowerShell\7\Modules\$($moduleFolder.Name)"

        Write-Log "  Installing module: $($moduleFolder.Name)"

        Write-Log "    Source: $sourcePath"
        Write-Log "    Target: $targetPath"

        try {
            if (Test-Path $targetPath) {
                Remove-Item $targetPath -Recurse -Force
            }
            New-Item -Path (Split-Path $targetPath) -ItemType Directory -Force | Out-Null
            Copy-Item $sourcePath $targetPath -Recurse
            Write-Log "    ✓ $($moduleFolder.Name) module installed successfully" "INFO" "Green"
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
    Write-Log "Setting PowerShell execution policy..." "INFO" "Green"

    try {
        Set-ExecutionPolicy RemoteSigned -Force
        Write-Log "  ✓ Execution policy set to RemoteSigned" "INFO" "Green"
    } catch {
        Write-Error "Failed to set execution policy: $_"
        return $false
    }

    return $true
}

# Import TcXaeMgmt module
function Step-ImportModule {
    Write-Log "Importing TcXaeMgmt module..." "INFO" "Green"

    try {
        Import-Module TcXaeMgmt -Force
        Write-Log "  ✓ TcXaeMgmt module imported successfully" "INFO" "Green"
    } catch {
        Write-Error "Failed to import TcXaeMgmt module: $_"
        return $false
    }

    return $true
}

# Set Core Isolation
function Step-SetCoreIsolation {
    Write-Log "Configuring CPU core isolation..." "INFO" "Green"

    try {
        Set-RTimeCpuSettings -SharedCores 3 -force
        Write-Log "  ✓ Core isolation configured (3 shared cores)" "INFO" "Green"
    } catch {
        Write-Warning "TcXaeMgmt method failed, using alternative approach..."

        # Alternative method using bcdedit
        $logicalProcessors = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
        $logicalProcessorsNew = $logicalProcessors - 1

        Start-Process -Wait -WindowStyle Hidden -FilePath "bcdedit" -ArgumentList "/set numproc $logicalProcessorsNew"
        Write-Log "  ✓ Core isolation configured: $logicalProcessors -> $logicalProcessorsNew shared cores" "INFO" "Green"
    }

    return $true
}

# Rename Ethernet adapters
function Step-RenameEthernetAdapters {
    Write-Log "Renaming Ethernet adapters..." "INFO" "Green"

    $adapterMappings = @{
        "Ethernet 4" = "Fieldbus"
        "Ethernet 3" = "Programming"
    }

    foreach ($oldName in $adapterMappings.Keys) {
        $newName = $adapterMappings[$oldName]
        Write-Log "  Renaming '$oldName' to '$newName'"

        try {
            $adapter = Get-NetAdapter -Name $oldName -ErrorAction SilentlyContinue
            if ($adapter) {
                Rename-NetAdapter -Name $oldName -NewName $newName
                Write-Log "  ✓ Renamed $oldName to $newName" "INFO" "Green"
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
    Write-Log "Installing realtime Ethernet driver..." "INFO" "Green"

    $driverPath = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\System\TcRteInstall.exe"
    $arguments = "-installfilter Fieldbus"

    Write-Log "  Driver: $driverPath"
    Write-Log "  Arguments: $arguments"

    if (Test-Path $driverPath) {
        try {
            Start-Process -Wait $driverPath -ArgumentList $arguments
            Write-Log "  ✓ Realtime Ethernet driver installed" "INFO" "Green"
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
function Step-SetTwinCATRunModeOnBoot {
    Write-Log "Configuring TwinCAT to start in run mode..." "INFO" "Green"

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
        Write-Log "  ✓ TwinCAT configured for run mode on boot" "INFO" "Green"
    } catch {
        Write-Error "Failed to set TwinCAT startup state: $_"
        return $false
    }

    return $true
}

# Copy TwinCAT boot folder
function Step-CopyTwinCATBoot {
    Write-Log "Copying TwinCAT boot folder..." "INFO" "Green"

    $bootBasePath = Join-Path $FilesPath "TWINCAT BOOT FOLDER"
    $bootFolders = Get-ChildItem -Path $bootBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($bootFolders.Count -eq 0) {
        Write-Error "No TwinCAT boot folders found in: $bootBasePath"
        return $false
    }

    $sourcePath = $bootFolders[0].FullName
    $targetPath = "C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot"

    Write-Log "  Found boot folder: $($bootFolders[0].Name)"

    Write-Log "  Source: $sourcePath"
    Write-Log "  Target: $targetPath"

    New-Item -Path (Split-Path $targetPath) -ItemType Directory -Force | Out-Null
    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $sourcePath $targetPath -Recurse
    Write-Log "  ✓ TwinCAT boot folder copied successfully" "INFO" "Green"

    return $true
}

# Copy HMI project to service folder
function Step-CopyHMIProject {
    Write-Log "Copying HMI projects to service folder..." "INFO" "Green"

    $hmiBasePath = Join-Path $FilesPath "HMI PROJECTS"
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
            Write-Log "      ✓ $($hmiFolder.Name) copied successfully" "INFO" "Green"
        } catch {
            Write-Error "Failed to copy HMI project $($hmiFolder.Name): $_"
            $success = $false
        }
    }

    if (-not $success) {
        return $false
    }

    Write-Log "  ✓ All HMI projects copied successfully" "INFO" "Green"
    return $true
}

# Copy HMI Server config file
function Step-CopyHMIConfig {
    Write-Log "Copying HMI Server configuration..." "INFO" "Green"

    $sourceFile = Join-Path $FilesPath "HMI PROJECTS\TcHmiSrv.Service.Config.json"
    $targetPath = "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server"
    $targetFile = Join-Path $targetPath "TcHmiSrv.Service.Config.json"

    if (-not (Test-Path $sourceFile)) {
        Write-Error "HMI config file not found: $sourceFile"
        return $false
    }

    Write-Log "  Source: $sourceFile"
    Write-Log "  Target: $targetFile"

    New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    Copy-Item $sourceFile $targetFile -Force
    Write-Log "  ✓ HMI Server config copied successfully" "INFO" "Green"

    return $true
}

# Reboot system
function Step-RebootSystem {
    Write-Log "System reboot..." "INFO" "Green"

    if ($SkipReboot) {
        Write-Log "  Reboot skipped (--SkipReboot specified)" "INFO" "Yellow"
        return $true
    }

    Write-Log "  System will reboot in 10 seconds..." "INFO" "Yellow"
    Write-Log "  Press Ctrl+C to cancel"
    Start-Sleep -Seconds 10
    Restart-Computer -Force

    return $true
}

# Main execution
function Main {
    Write-Log "Starting TwinCAT deployment process..." "INFO" "White"
    Write-Log ""

    # Verify files folder exists
    if (-not (Test-Path $FilesPath)) {
        Write-Log "files folder not found: $FilesPath" "ERROR" "Red"
        Write-Log "Please ensure the script is run from the correct directory" "ERROR" "Red"
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
        { Step-SetTwinCATRunModeOnBoot },
        { Step-CopyTwinCATBoot },
        { Step-CopyHMIProject },
        { Step-CopyHMIConfig },
        { Step-RebootSystem }
    )

    foreach ($step in $steps) {
        try {
            $result = & $step
            if (-not $result) {
                Write-Log "Step failed. Aborting deployment execution." "ERROR" "Red"
                exit 1
            }
        } catch {
            Write-Log "Step encountered an error: $_" "ERROR" "Red"
            exit 1
        }

        Write-Log ""
    }

    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime

    Write-Log "========================================" "INFO" "Cyan"
    Write-Log "TWINCAT DEPLOYMENT COMPLETED SUCCESSFULLY" "INFO" "Green"
    Write-Log "========================================" "INFO" "Cyan"
    Write-Log "Started: $StartTime" "INFO" "Yellow"
    Write-Log "Completed: $EndTime" "INFO" "Yellow"
    Write-Log "Duration: $($Duration.ToString('hh\\:mm\\:ss'))" "INFO" "Yellow"
    Write-Log "Log saved to: $LogFile" "INFO" "Yellow"
}

# Execute main function
Main