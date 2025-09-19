# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains automation scripts and artifacts for configuring a TwinCAT industrial automation system on Windows devices. The primary goal is to create a complete USB-bootable installation package that automates the TwinCAT bootstrap process.

## Repository Structure

- `twincat-deploy.ps1` - Main deployment script that automates the entire TwinCAT installation process
- `files/` - Contains all required installation components organized by function:
  - `TCPKG PACKAGES/packagesoffline/` - Offline TwinCAT packages (*.XAR files)
  - `TWINCAT BOOT FOLDER/TwinCAT RT (x64)/` - TwinCAT boot configuration with CurrentConfig.xml
  - `HMI PROJECTS/HMI/` - Complete HMI project with www folder structure
  - `HMI PROJECTS/TcHmiSrv.Service.Config.json` - HMI Server configuration

## Target Environment

- Windows 11 x64 devices without TwinCAT (tested on CX2043 with CX1800-1191-1017_v2025-01-0004V image)
- Contains TcPkg version 2.1.134
- Designed for offline/air-gapped installations
- Requires PowerShell 7 for TcXaeMgmt module compatibility

## Key TwinCAT Packages

The deployment installs these essential packages:
- `TwinCAT.Standard.XAR` - Core TwinCAT runtime
- `TF2000.HMIServer.XAR` - HMI Server functionality
- `TF1200.UiClient.XAR` - UI Client components

## Network Configuration

The script automatically renames network adapters for TwinCAT fieldbus operation:
- `Ethernet 4` → `Fieldbus` (for real-time communication)
- `Ethernet 3` → `Programming` (for development access)

## Error Handling and Troubleshooting

- All deployment steps return boolean success/failure status
- Comprehensive logging to `twincat-deploy.log` with timestamps
- Automatic cleanup of existing installations before new deployments
- Script exits immediately on any step failure to prevent partial installations
- Color-coded console output for easy visual debugging

## Critical System Paths

### Runtime Paths (Deployment Targets)
- TwinCAT Boot: `C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot`
- HMI Service: `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service\`
- HMI Config: `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\`
- Package Cache: `C:\packagesoffline`
- Realtime Driver: `C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\System\TcRteInstall.exe`

### Repository Source Paths
- Script Root: `$PSScriptRoot` (base directory for twincat-deploy.ps1)
- Files Root: `$PSScriptRoot\files` (all deployment artifacts)
- Packages: `files\TCPKG PACKAGES\packagesoffline`
- Boot Config: `files\TWINCAT BOOT FOLDER\TwinCAT RT (x64)`
- HMI Projects: `files\HMI PROJECTS`

## Registry Configuration

TwinCAT startup state is controlled via registry:
- 64-bit: `HKLM:\SOFTWARE\WOW6432Node\Beckhoff\TwinCAT3\System`
- 32-bit: `HKLM:\SOFTWARE\Beckhoff\TwinCAT3\System`
- Key: `SysStartupState` = 5 (Run mode)

## Common Commands

### Deployment
- `./twincat-deploy.ps1` - Run full TwinCAT deployment process
- `./twincat-deploy.ps1 -SkipReboot` - Deploy without automatic reboot

### Manual Testing/Debugging
- `tcpkg source list` - View configured package sources
- `tcpkg list --local` - List locally installed packages
- `bcdedit` - View current boot configuration including processor settings
- `Get-NetAdapter` - List network adapters for renaming verification

## Script Architecture

The `twincat-deploy.ps1` script follows a modular step-based architecture:

1. **Initialization**: Sets up logging, validates file paths, and defines global variables
2. **Step Functions**: Each deployment task is isolated in its own function (Step-*)
3. **Main Execution**: Sequential execution of all steps with error handling
4. **Logging**: Comprehensive logging to both console and file with timestamps and color coding

### Key Design Patterns
- Robust error handling with try/catch blocks in each step
- File path validation before operations
- Automatic cleanup of existing installations before new deployments
- Platform-aware registry path selection (32-bit vs 64-bit)
- Direct bcdedit approach for reliable core isolation configuration

### Deployment Flow
The script executes these steps in a specific order to ensure proper system configuration:

1. **Package Management**
   - `Step-CopyPackagesOffline` - Copy packages to local cache
   - `Step-AddPackageSource` - Configure tcpkg source
   - `Step-InstallPackages` - Install all TwinCAT packages

2. **System Configuration**
   - `Step-SetCoreIsolation` - Configure CPU core isolation via bcdedit
   - `Step-RenameEthernetAdapters` - Rename network adapters for fieldbus
   - `Step-InstallRealtimeDriver` - Install TwinCAT realtime driver

3. **TwinCAT Configuration**
   - `Step-SetTwinCATRunModeOnBoot` - Set registry for run mode startup
   - `Step-CopyTwinCATBoot` - Deploy boot configuration files
   - `Step-CopyHMIProject` - Deploy HMI project files
   - `Step-CopyHMIConfig` - Deploy HMI server configuration

4. **UI Client Setup**
   - `Step-ConfigureTF1200` - Configure TF1200 UI Client
   - `Step-ConfigureTF1200AutoLaunch` - Set UI Client auto-launch

5. **System Restart** (optional, skipped by default)
   - `Step-RebootSystem` - Restart to apply all changes