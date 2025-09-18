# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains automation scripts and artifacts for configuring a TwinCAT industrial automation system on Windows devices. The primary goal is to create a complete USB-bootable installation package that automates the TwinCAT bootstrap process.

## Repository Structure

- `StepsToBootStrapTwinCATInstall.txt` - Detailed manual installation steps that serve as the reference for automation
- `artifacts/` - Contains all required installation components:
  - `packagesoffline/` - Offline TwinCAT packages (TwinCAT.Standard.XAR, TF20000.HMIServer.XAR, TF1200.UiClient.XAR)
  - `TcXaeMgmt/` - PowerShell module for TwinCAT management
  - `TwinCAT RT (x64)/` - TwinCAT boot configuration files
  - `HMI/` - HMI project files for the TwinCAT HMI Server
  - `TcHmiSrv.Service.Config.json` - HMI Server configuration

## Target Environment

- CX20x3 Windows 11 x64 without TwinCAT image (CX1800-1191-1017_v2025-01-0004V)
- Contains TcPkg version 2.1.134
- Designed for offline/air-gapped installations

## Key Automation Tasks

When creating PowerShell automation scripts, the typical workflow includes:

1. **Package Management**: Copy packagesoffline to C:\packagesoffline and configure tcpkg source
2. **Package Installation**: Install TwinCAT packages using tcpkg commands
3. **PowerShell Module Setup**: Install TcXaeMgmt module and configure execution policy
4. **System Configuration**:
   - Configure CPU core isolation for real-time performance
   - Rename network adapters for fieldbus and programming networks
   - Install real-time Ethernet drivers
5. **TwinCAT Configuration**:
   - Set TwinCAT to start in run mode on boot
   - Deploy boot configuration and HMI projects
6. **System Restart**: Final reboot to apply all changes

## Important Paths

- TwinCAT Boot: `C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot`
- HMI Service: `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service\`
- HMI Config: `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\`
- PowerShell Modules: `C:\Program Files\WindowsPowerShell\7\Modules\`

## Registry Configuration

TwinCAT startup state is controlled via registry:
- 64-bit: `HKLM:\SOFTWARE\WOW6432Node\Beckhoff\TwinCAT3\System`
- 32-bit: `HKLM:\SOFTWARE\Beckhoff\TwinCAT3\System`
- Key: `SysStartupState` = 5 (Run mode)