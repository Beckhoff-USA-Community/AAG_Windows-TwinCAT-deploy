# TwinCAT Modular Deployment Scripts

This folder contains modular PowerShell scripts that are **automatically discovered and executed** by the main `twincat-deploy.ps1` script. The main script has **zero hardcoded references** - it dynamically finds and runs whatever scripts you place here.

## 🚀 Fully Dynamic Architecture

The `twincat-deploy.ps1` script:
- **Scans** for numbered phase folders (`01-`, `02-`, `03-`...)
- **Discovers** all `.ps1` files in each phase
- **Executes** them in numerical order automatically
- **No hardcoding** - completely plug-and-play extensible

### Current Folder Structure
```
POWERSHELL SCRIPTS/
├── Shared/
│   └── TwinCATDeployUtils.psm1     # Shared utilities module
├── 01-PackageManagement/           # TwinCAT package installation
│   ├── 01-CopyPackagesOffline.ps1
│   ├── 02-AddPackageSource.ps1
│   └── 03-InstallPackages.ps1
├── 02-SystemConfiguration/         # Windows system configuration
│   ├── 01-SetCoreIsolation.ps1
│   ├── 02-RenameEthernetAdapters.ps1
│   └── 03-InstallRealtimeDriver.ps1
├── 03-TwinCATConfiguration/        # TwinCAT-specific configuration
│   ├── 01-SetTwinCATRunModeOnBoot.ps1
│   ├── 02-CopyTwinCATBoot.ps1
│   ├── 03-CopyHMIProject.ps1
│   └── 04-CopyHMIConfig.ps1
├── 04-UIClientSetup/               # UI Client configuration
│   ├── 01-ConfigureTF1200.ps1
│   └── 02-ConfigureTF1200AutoLaunch.ps1
└── 99-SystemRestart/               # System restart (if needed)
    └── 01-RebootSystem.ps1
```

## ⚡ Execution Flow

**Automatic Discovery Process:**
1. `twincat-deploy.ps1` scans for phase folders matching `^\d+` pattern
2. Sorts phases numerically: `01-`, `02-`, `03-`...
3. For each phase, finds all `.ps1` files and sorts numerically
4. Executes each script, checking return value
5. Aborts entire deployment if any script returns `$false`

**Example execution order:**
```
01-PackageManagement/01-CopyPackagesOffline.ps1
01-PackageManagement/02-AddPackageSource.ps1
01-PackageManagement/03-InstallPackages.ps1
02-SystemConfiguration/01-SetCoreIsolation.ps1
02-SystemConfiguration/02-RenameEthernetAdapters.ps1
... and so on
```

## 🔧 Adding New Scripts (Plug-and-Play)

### 1. Create New Phase (Optional)
```bash
mkdir "05-CustomPhase"
```

### 2. Add Script to Any Phase
```bash
# Create script in existing or new phase
files/POWERSHELL SCRIPTS/05-CustomPhase/01-MyCustomScript.ps1
```

### 3. Script Requirements
- **Return Value**: Must return `$true` (success) or `$false` (failure)
- **Naming**: Follow `01-ScriptName.ps1` convention for ordering
- **Dependencies**: Use shared functions from `TwinCATDeployUtils.psm1`

### 4. Script Template
```powershell
# @Title: Custom Operation
# @Description: Does something custom for deployment
# @Phase: 05-CustomPhase
# @Order: 01
# @Dependencies: None
# @Optional: false

Write-Log "Performing custom operation..." "SUCCESS"

# Use shared functions:
# - Write-Log for logging
# - Get-FilesPath for files directory
# - Get-ScriptRoot for script root directory

try {
    # Your custom logic here
    $result = $true

    if ($result) {
        Write-Log "  ✓ Custom operation completed successfully" "SUCCESS"
        return $true
    } else {
        Write-Log "  ✗ Custom operation failed" "ERROR"
        return $false
    }
} catch {
    Write-Log "  ✗ Custom operation error: $_" "ERROR"
    return $false
}
```

## 📋 Available Shared Functions

All scripts have access to these functions from `TwinCATDeployUtils.psm1`:
- `Write-Log $Message $Level` - Unified logging with colors and file output
- `Get-FilesPath` - Returns path to files directory
- `Get-ScriptRoot` - Returns main script root directory
- `Test-IsElevated` - Checks for administrator privileges

## 📝 Metadata Tags (Optional)

Include metadata in script comments for documentation:
```powershell
# @Title: Human-readable title
# @Description: Detailed description
# @Phase: Phase folder name
# @Order: Execution order within phase
# @Dependencies: Required previous scripts
# @Optional: true/false
```

## ✅ Key Benefits

**🔄 True Extensibility**
- Drop new `.ps1` files anywhere in the structure
- Main script automatically discovers and runs them
- Zero changes needed to `twincat-deploy.ps1`

**📦 Modular Design**
- Each script handles single responsibility
- Easy to test, debug, and maintain individual steps
- Reusable across different deployments

**🎯 Automatic Ordering**
- Numerical naming ensures predictable execution order
- Easy to insert new steps between existing ones (e.g., `01.5-NewStep.ps1`)

**🛡️ Error Handling**
- Deployment stops immediately on any script failure
- Comprehensive logging for troubleshooting
- Clean abort prevents partial installations

**⚙️ Reboot Control**
- Want to reboot? Keep the `99-SystemRestart/01-RebootSystem.ps1` script
- Don't want to reboot? Delete or rename the `99-SystemRestart` folder
- No parameters needed - presence/absence of script controls behavior

## 🚀 Usage

**Same as always - no changes needed:**
```powershell
.\twincat-deploy.ps1                 # Uses modular approach automatically
```

**Control reboot behavior by file presence:**
```bash
# To skip reboot - remove or rename the restart folder
mv "files/POWERSHELL SCRIPTS/99-SystemRestart" "files/POWERSHELL SCRIPTS/99-SystemRestart.disabled"

# To enable reboot - ensure the restart folder exists
mv "files/POWERSHELL SCRIPTS/99-SystemRestart.disabled" "files/POWERSHELL SCRIPTS/99-SystemRestart"
```

The magic happens automatically - the main script discovers and executes whatever scripts you've placed in the numbered folders!