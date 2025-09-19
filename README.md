# Windows TwinCAT Deploy

A plug-and-play automation solution for configuring the Windows environment, installing TwinCAT packages, and deploying application code. Simply prepare your USB drive, connect to the target system, and run the deployment script.

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

Comprehensive PowerShell automation tool that executes in phases:
- **Package Management**: Install TwinCAT runtime components
- **System Configuration**: CPU isolation, network setup, real-time drivers
- **TwinCAT Configuration**: Boot setup, HMI deployment
- **UI Client Setup**: Configuration and auto-launch

Features robust error handling, comprehensive logging, and automatic privilege elevation.

## Quick Start

```powershell
# Deploy TwinCAT system (run as Administrator)
.\twincat-deploy.ps1
```

📁 **For detailed setup instructions and file organization, see [`files/README.md`](files/README.md)**
