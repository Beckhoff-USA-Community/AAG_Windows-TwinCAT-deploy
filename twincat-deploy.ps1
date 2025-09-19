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
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Determine color based on log level
    $Color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "White" }
        "HEADER" { "Cyan" }
        default { "White" }
    }

    # Write to console with color
    Write-Host $Message -ForegroundColor $Color

    # Write to log file
    Add-Content -Path $LogFile -Value $logEntry -Encoding UTF8
}

# Check for Administrator privileges and elevate if needed
function Test-IsElevated {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsElevated)) {
    Write-Log "Administrator privileges required. Elevating script..." "WARN"

    # Get the script path and arguments
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = @()

    # Preserve the SkipReboot parameter
    if ($SkipReboot) {
        $arguments += "-SkipReboot"
    }

    try {
        # Start elevated PowerShell process
        $argumentString = if ($arguments.Count -gt 0) { "-File `"$scriptPath`" " + ($arguments -join " ") } else { "-File `"$scriptPath`"" }
        Start-Process -FilePath "powershell.exe" -ArgumentList $argumentString -Verb RunAs -Wait
        Write-Log "Elevated script completed successfully" "SUCCESS"
        exit 0
    } catch {
        Write-Log "Failed to elevate script: $_" "ERROR"
        Write-Log "Please run PowerShell as Administrator and try again." "ERROR"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Start deployment
Write-Log "========================================" "HEADER"
Write-Log "TwinCAT Deployment Script" "HEADER"
Write-Log "========================================" "HEADER"
Write-Log "Running with Administrator privileges: $(Test-IsElevated)" "WARN"
Write-Log "Started at: $StartTime" "WARN"
Write-Log "Log file: $LogFile" "WARN"
Write-Log ""

# Copy packagesoffline folder
function Step-CopyPackagesOffline {
    Write-Log "Copying TcPkg packages folder..." "SUCCESS"

    $tcpkgBasePath = Join-Path $FilesPath "TCPKG PACKAGES"
    $packagesFolders = Get-ChildItem -Path $tcpkgBasePath -Directory | Where-Object { $_.Name -ne ".git" }

    if ($packagesFolders.Count -eq 0) {
        Write-Log "No package folders found in: $tcpkgBasePath" "ERROR"
        return $false
    }

    $sourcePath = $packagesFolders[0].FullName
    $targetPath = "C:\packagesoffline"

    Write-Log "  Found packages folder: $($packagesFolders[0].Name)"

    Write-Log "  Source: $sourcePath"
    Write-Log "  Target: $targetPath"

    if (Test-Path $targetPath) {
        Remove-Item $targetPath -Recurse -Force
    }
    Copy-Item $sourcePath $targetPath -Recurse
    Write-Log "  ✓ Packages copied successfully" "SUCCESS"

    return $true
}

# Add package source to TcPkg
function Step-AddPackageSource {
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
}

# Install required packages
function Step-InstallPackages {
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
}

# Set Core Isolation
function Step-SetCoreIsolation {
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
}

# Rename Ethernet adapters
function Step-RenameEthernetAdapters {
    Write-Log "Renaming Ethernet adapters..." "SUCCESS"

    $adapterMappings = @{
        "X001" = "Fieldbus"
    }

    foreach ($oldName in $adapterMappings.Keys) {
        $newName = $adapterMappings[$oldName]
        Write-Log "  Renaming '$oldName' to '$newName'"

        try {
            $adapter = Get-NetAdapter -Name $oldName -ErrorAction SilentlyContinue
            if ($adapter) {
                Rename-NetAdapter -Name $oldName -NewName $newName
                Write-Log "  ✓ Renamed $oldName to $newName" "SUCCESS"
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
}

# Set TwinCAT to start in run mode
function Step-SetTwinCATRunModeOnBoot {
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
}

# Copy TwinCAT boot folder
function Step-CopyTwinCATBoot {
    Write-Log "Copying TwinCAT boot folder..." "SUCCESS"

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
    Write-Log "  ✓ TwinCAT boot folder copied successfully" "SUCCESS"

    return $true
}

# Copy HMI project to service folder
function Step-CopyHMIProject {
    Write-Log "Copying HMI projects to service folder..." "SUCCESS"

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
}

# Copy HMI Server config file
function Step-CopyHMIConfig {
    Write-Log "Copying HMI Server configuration..." "SUCCESS"

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
    Write-Log "  ✓ HMI Server config copied successfully" "SUCCESS"

    return $true
}


# Configure TF1200 UI Client
function Step-ConfigureTF1200 {
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
}

# Configure TF1200 Auto-Launch
function Step-ConfigureTF1200AutoLaunch {
    Write-Log "Configuring TF1200 UI Client auto-launch..." "SUCCESS"

    $sourceShortcut = "C:\Users\Public\Desktop\TwinCAT UI Client.lnk"
    $startupPath = "C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\Target\StartUp"
    $targetShortcut = Join-Path $startupPath "TwinCAT UI Client.lnk"

    Write-Log "  Source shortcut: $sourceShortcut"
    Write-Log "  Startup folder: $startupPath"
    Write-Log "  Target shortcut: $targetShortcut"

    # Check if source shortcut exists
    if (-not (Test-Path $sourceShortcut)) {
        Write-Error "TF1200 shortcut not found: $sourceShortcut"
        Write-Error "Please ensure TF1200.UiClient.XAR package is installed"
        return $false
    }

    # Create startup directory if it doesn't exist
    if (-not (Test-Path $startupPath)) {
        try {
            New-Item -Path $startupPath -ItemType Directory -Force | Out-Null
            Write-Log "  Created startup directory: $startupPath"
        } catch {
            Write-Error "Failed to create startup directory: $_"
            return $false
        }
    }

    try {
        # Copy the shortcut to the startup folder
        Copy-Item $sourceShortcut $targetShortcut -Force
        Write-Log "  ✓ TF1200 UI Client shortcut copied to TwinCAT startup folder" "SUCCESS"
        Write-Log "  ✓ TF1200 UI Client will now auto-launch with TwinCAT system" "SUCCESS"
    } catch {
        Write-Error "Failed to copy TF1200 shortcut: $_"
        return $false
    }

    return $true
}

# Reboot system
function Step-RebootSystem {
    Write-Log "System reboot..." "SUCCESS"

    if ($SkipReboot) {
        Write-Log "  Reboot skipped (--SkipReboot specified)" "WARN"
        return $true
    }

    Write-Log "  System will reboot in 10 seconds..." "WARN"
    Write-Log "  Press Ctrl+C to cancel"
    Start-Sleep -Seconds 10
    Restart-Computer -Force

    return $true
}

# Main execution
function Main {
    Write-Log "Starting TwinCAT deployment process..."
    Write-Log ""

    # Verify files folder exists
    if (-not (Test-Path $FilesPath)) {
        Write-Log "files folder not found: $FilesPath" "ERROR"
        Write-Log "Please ensure the script is run from the correct directory" "ERROR"
        exit 1
    }

    # Execute all steps
    $steps = @(
        { Step-CopyPackagesOffline },
        { Step-AddPackageSource },
        { Step-InstallPackages },
        { Step-SetCoreIsolation },
        { Step-RenameEthernetAdapters },
        { Step-InstallRealtimeDriver },
        { Step-SetTwinCATRunModeOnBoot },
        { Step-CopyTwinCATBoot },
        { Step-CopyHMIProject },
        { Step-CopyHMIConfig },
        { Step-ConfigureTF1200 },
        { Step-ConfigureTF1200AutoLaunch },
        { Step-RebootSystem }
    )

    foreach ($step in $steps) {
        try {
            $result = & $step
            if (-not $result) {
                Write-Log "Step failed. Aborting deployment execution." "ERROR"
                exit 1
            }
        } catch {
            Write-Log "Step encountered an error: $_" "ERROR"
            exit 1
        }

        Write-Log ""
    }

    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime

    Write-Log "========================================" "HEADER"
    Write-Log "TWINCAT DEPLOYMENT COMPLETED SUCCESSFULLY" "SUCCESS"
    Write-Log "========================================" "HEADER"
    Write-Log "Started: $StartTime" "WARN"
    Write-Log "Completed: $EndTime" "WARN"
    Write-Log "Duration: $($Duration.ToString('hh\:mm\:ss'))" "WARN"
    Write-Log "Log saved to: $LogFile" "WARN"
}

# Execute main function
Main