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

# Import the shared utilities module
$SharedModulePath = Join-Path $FilesPath "POWERSHELL SCRIPTS\Shared\TwinCATDeployUtils.psm1"
if (-not (Test-Path $SharedModulePath)) {
    Write-Log "Shared utilities module not found: $SharedModulePath" "ERROR"
    Write-Log "Please ensure the modular scripts are properly installed" "ERROR"
    exit 1
}

Import-Module $SharedModulePath -Force

# Initialize the deployment module with current settings
Initialize-DeploymentModule -LogFilePath $LogFile -ScriptRootPath $ScriptRoot -FilesRootPath $FilesPath


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

    # Use modular deployment approach - automatically discover and execute scripts
    $scriptsPath = Join-Path $FilesPath "POWERSHELL SCRIPTS"

    if (Test-Path $scriptsPath) {
        Write-Log "Using modular deployment approach" "SUCCESS"
        Write-Log "Scripts path: $scriptsPath"

        $result = Invoke-ModularDeployment -ScriptsPath $scriptsPath

        if (-not $result) {
            Write-Log "Modular deployment failed. Aborting execution." "ERROR"
            exit 1
        }
    } else {
        Write-Log "Modular scripts folder not found: $scriptsPath" "ERROR"
        Write-Log "Please ensure the POWERSHELL SCRIPTS folder exists in the files directory" "ERROR"
        Write-Log "Expected structure:" "ERROR"
        Write-Log "  files/POWERSHELL SCRIPTS/01-Phase/01-Script.ps1" "ERROR"
        exit 1
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