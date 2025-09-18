# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains automation scripts and artifacts for configuring a TwinCAT industrial automation system on Windows devices. The primary goal is to create a complete USB-bootable installation package that automates the TwinCAT bootstrap process.

## Repository Structure

- `twincat-deploy.ps1` - Main deployment script that automates the entire TwinCAT installation process
- `StepsToBootStrapTwinCATInstall.txt` - Detailed manual installation steps that serve as the reference for automation
- `files/` - Contains all required installation components organized by function:
  - `TCPKG PACKAGES/packagesoffline/` - Offline TwinCAT packages (*.XAR files)
  - `POWERSHELL MODULES/TcXaeMgmt/` - PowerShell module for TwinCAT management (v7.0.31)
  - `TWINCAT BOOT FOLDER/TwinCAT RT (x64)/` - TwinCAT boot configuration with CurrentConfig.xml
  - `HMI PROJECTS/HMI/` - Complete HMI project with www folder structure
  - `HMI PROJECTS/TcHmiSrv.Service.Config.json` - HMI Server configuration

## Target Environment

- CX20x3 Windows 11 x64 without TwinCAT image (CX1800-1191-1017_v2025-01-0004V)
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
- PowerShell Modules: `C:\Program Files\WindowsPowerShell\7\Modules\`
- Package Cache: `C:\packagesoffline`
- Realtime Driver: `C:\Program Files (x86)\Beckhoff\TwinCAT\3.1\System\TcRteInstall.exe`

### Repository Source Paths
- Script Root: `$PSScriptRoot` (base directory for twincat-deploy.ps1)
- Files Root: `$PSScriptRoot\files` (all deployment artifacts)
- Packages: `files\TCPKG PACKAGES\packagesoffline`
- Modules: `files\POWERSHELL MODULES`
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
- `Get-Module -ListAvailable TcXaeMgmt` - Check if TcXaeMgmt module is available
- `Set-RTimeCpuSettings -SharedCores 3 -force` - Configure CPU core isolation
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
- Graceful fallbacks (e.g., bcdedit when TcXaeMgmt core isolation fails)

### Deployment Flow
The script executes steps in a specific order to ensure proper system configuration:
1. Package management (copy, configure source, install)
2. PowerShell environment setup (modules, execution policy)
3. System configuration (core isolation, network adapters, drivers)
4. TwinCAT configuration (startup state, boot files, HMI deployment)
5. System restart to apply changes