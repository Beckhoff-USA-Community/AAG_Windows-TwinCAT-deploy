# TwinCAT Deployment Shared Utilities Module
# Contains common functions and utilities used by all deployment scripts

# Global variables that will be available to all modules
$script:LogFile = $null
$script:ScriptRoot = $null
$script:FilesPath = $null

# Initialize the module with paths and settings
function Initialize-DeploymentModule {
    param(
        [string]$LogFilePath,
        [string]$ScriptRootPath,
        [string]$FilesRootPath
    )

    $script:LogFile = $LogFilePath
    $script:ScriptRoot = $ScriptRootPath
    $script:FilesPath = $FilesRootPath
}

# Logging function - identical to original
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
    Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8
}

# Check for Administrator privileges
function Test-IsElevated {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Get script root path for modules
function Get-ScriptRoot {
    return $script:ScriptRoot
}

# Get files path for modules
function Get-FilesPath {
    return $script:FilesPath
}


# Discover and execute deployment scripts in order
function Invoke-ModularDeployment {
    param(
        [string]$ScriptsPath
    )

    Write-Log "Discovering deployment modules..." "SUCCESS"

    # Get all phase directories, sorted by name (01-, 02-, etc.)
    $phases = Get-ChildItem $ScriptsPath -Directory | Where-Object { $_.Name -match '^\d+' -and $_.Name -ne 'Shared' } | Sort-Object Name

    if ($phases.Count -eq 0) {
        Write-Log "No deployment phases found in: $ScriptsPath" "ERROR"
        return $false
    }

    Write-Log "Found $($phases.Count) deployment phase(s)" "SUCCESS"

    foreach ($phase in $phases) {
        Write-Log ""
        Write-Log "========================================" "HEADER"
        Write-Log "PHASE: $($phase.Name)" "HEADER"
        Write-Log "========================================" "HEADER"

        # Get all PowerShell scripts in the phase, sorted by name
        $scripts = Get-ChildItem $phase.FullName -Filter "*.ps1" | Sort-Object Name

        if ($scripts.Count -eq 0) {
            Write-Log "No scripts found in phase: $($phase.Name)" "WARN"
            continue
        }

        Write-Log "Found $($scripts.Count) script(s) in phase: $($phase.Name)" "SUCCESS"

        foreach ($script in $scripts) {
            Write-Log ""
            Write-Log "Executing: $($script.Name)" "SUCCESS"

            $result = Invoke-DeploymentScript -ScriptPath $script.FullName

            if (-not $result) {
                Write-Log "Script failed: $($script.Name)" "ERROR"
                Write-Log "Aborting deployment execution." "ERROR"
                return $false
            }

            Write-Log "$($script.Name) completed successfully" "SUCCESS"
        }
    }

    return $true
}

# Execute a single deployment script
function Invoke-DeploymentScript {
    param(
        [string]$ScriptPath
    )

    try {
        # Load the script as a module
        $scriptContent = Get-Content -Path $ScriptPath -Raw

        # Create a new script block and execute it
        $scriptBlock = [ScriptBlock]::Create($scriptContent)

        # Execute in a new scope but with access to our shared functions
        $result = & $scriptBlock

        # Scripts should return boolean success/failure
        if ($result -is [bool]) {
            return $result
        } else {
            # If no explicit return, assume success
            return $true
        }

    } catch {
        Write-Log "Error executing script: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Parse script metadata from comments (future enhancement)
function Get-ScriptMetadata {
    param(
        [string]$ScriptPath
    )

    $metadata = @{}

    try {
        $content = Get-Content -Path $ScriptPath

        foreach ($line in $content) {
            if ($line -match '^#\s*@(\w+):\s*(.+)$') {
                $key = $matches[1]
                $value = $matches[2].Trim()
                $metadata[$key] = $value
            }
        }
    } catch {
        Write-Log "Warning: Could not parse metadata from: $ScriptPath" "WARN"
    }

    return $metadata
}

# Export all functions for use by deployment scripts
Export-ModuleMember -Function @(
    'Initialize-DeploymentModule',
    'Write-Log',
    'Test-IsElevated',
    'Get-ScriptRoot',
    'Get-FilesPath',
    'Invoke-ModularDeployment',
    'Invoke-DeploymentScript',
    'Get-ScriptMetadata'
)
