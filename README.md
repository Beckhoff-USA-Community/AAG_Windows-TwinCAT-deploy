# Windows TwinCAT Deploy

A plug-and-play automation solution for configuring the Windows environment, installing TwinCAT packages, and deploying application code. Built with a modular, extensible architecture that automatically discovers and executes deployment scripts. Simply prepare your USB drive, connect to the target system, and run the deployment script.

## How It Works

### 1. Prepare USB Installation Package
1. Clone this repository to a USB drive
2. Populate the `files/` directories with your TwinCAT components (see [`files/README.md`](files/README.md) for details)
3. Verify all required files are present

### 2. Deploy to Target System
1. **Connect USB drive** to target Windows device
2. **Run as Administrator**: `.\twincat-deploy.ps1`
3. **Automated deployment**: Script handles complete installation process
4. **System restart**: Automatically reboots to activate configurations

### 3. Production Ready
- TwinCAT starts automatically in run mode
- HMI interface accessible via web browser
- Real-time Ethernet ready for fieldbus operations
- UI Client launches with system startup

## The `twincat-deploy.ps1` Script

Comprehensive PowerShell automation tool with **modular, extensible architecture**:
- **🔍 Dynamic Discovery**: Automatically finds and executes deployment scripts
- **📁 Phase-Based Execution**: Runs scripts in numbered phases (01-, 02-, 03-...)
- **🔧 Plug-and-Play**: Add new scripts without modifying main script
- **⚙️ Configurable**: Control deployment behavior through file presence

**Current Deployment Phases:**
- **01-PackageManagement**: Install TwinCAT runtime components
- **02-SystemConfiguration**: CPU isolation, network setup, real-time drivers
- **03-TwinCATConfiguration**: Boot setup, HMI deployment
- **04-UIClientSetup**: Configuration and auto-launch
- **99-SystemRestart**: Optional system reboot (remove folder to skip)

Features robust error handling, comprehensive logging, and automatic privilege elevation.

## Quick Start

```powershell
# Deploy TwinCAT system (run as Administrator)
.\twincat-deploy.ps1
```

📁 **For detailed setup instructions and file organization, see [`files/README.md`](files/README.md)**

🔧 **For extending the deployment with custom scripts, see [`files/POWERSHELL SCRIPTS/README.md`](files/POWERSHELL%20SCRIPTS/README.md)**

---

## ⚠️ Disclaimer

All sample code provided by Beckhoff Automation LLC are for illustrative purposes only and are provided "as is" and without any warranties, express or implied. Actual implementations in applications will vary significantly. Beckhoff Automation LLC shall have no liability for, and does not waive any rights in relation to, any code samples that it provides or the use of such code samples for any purpose.
