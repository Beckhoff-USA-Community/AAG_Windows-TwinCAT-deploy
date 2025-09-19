# TwinCAT Installation files

This directory contains all the files needed for automated TwinCAT installation and configuration. The twincat-deploy script uses a modular architecture that automatically discovers and executes deployment scripts, while also detecting and using the first folder found in each subdirectory for file artifacts.

## Directory Structure

```
files/
├── README.md                           # This documentation file
├── POWERSHELL SCRIPTS/                 # 🔧 Modular deployment scripts
│   ├── Shared/TwinCATDeployUtils.psm1  # ← Shared utilities module
│   ├── 01-PackageManagement/           # ← Package installation scripts
│   ├── 02-SystemConfiguration/         # ← System setup scripts
│   ├── 03-TwinCATConfiguration/        # ← TwinCAT configuration scripts
│   ├── 04-UIClientSetup/               # ← UI Client setup scripts
│   ├── 99-SystemRestart/               # ← Optional reboot script
│   └── README.md                       # ← Extensibility documentation
├── TCPKG PACKAGES/                     # Offline TwinCAT packages
│   └── [your-package-folder]/          # ← Place your TcPkg packages here
│       ├── TwinCAT.Standard.XAR
│       ├── TF2000.HMIServer.XAR
│       └── [other packages]
├── TWINCAT BOOT FOLDER/                # Runtime configuration
│   └── [your-boot-folder]/             # ← Place TwinCAT boot folder here
│       ├── CurrentConfig.xml
│       ├── Port_851.app
│       └── [project files]
└── HMI PROJECTS/                       # HMI projects and configuration
    ├── TcHmiSrv.Service.Config.json    # ← Place HMI server config here
    ├── [hmi-project-1]/                # ← Place HMI project folders here
    │   ├── www/
    │   ├── storage.db
    │   └── [web server files]
    └── [hmi-project-2]/                # ← Multiple projects supported
        ├── www/
        ├── storage.db
        └── [web server files]
```

## Setup Instructions

1. **Populate each directory** according to the sections below
2. **Verify completeness** - ensure all required files are present
3. **Customize deployment** (optional) - add/remove PowerShell scripts as needed
4. **Run the deployment script** - execute `twincat-deploy.ps1` to automate the installation

---

<details>
<summary><h2>🔧 POWERSHELL SCRIPTS</h2></summary>

### Purpose
Contains modular PowerShell scripts that define the deployment process. The main `twincat-deploy.ps1` script automatically discovers and executes these scripts in numerical order.

### Architecture
**Fully Dynamic Discovery:**
- Scripts organized in numbered phases (01-, 02-, 03-...)
- Each phase contains numbered steps (01-, 02-, 03-...)
- No hardcoded references in main script - completely plug-and-play

### Current Script Structure
```
POWERSHELL SCRIPTS/
├── Shared/
│   └── TwinCATDeployUtils.psm1         # Shared utilities and functions
├── 01-PackageManagement/               # Install TwinCAT packages
│   ├── 01-CopyPackagesOffline.ps1
│   ├── 02-AddPackageSource.ps1
│   └── 03-InstallPackages.ps1
├── 02-SystemConfiguration/             # Configure Windows system
│   ├── 01-SetCoreIsolation.ps1
│   ├── 02-RenameEthernetAdapters.ps1
│   └── 03-InstallRealtimeDriver.ps1
├── 03-TwinCATConfiguration/            # Configure TwinCAT runtime
│   ├── 01-SetTwinCATRunModeOnBoot.ps1
│   ├── 02-CopyTwinCATBoot.ps1
│   ├── 03-CopyHMIProject.ps1
│   └── 04-CopyHMIConfig.ps1
├── 04-UIClientSetup/                   # Configure UI Client
│   ├── 01-ConfigureTF1200.ps1
│   └── 02-ConfigureTF1200AutoLaunch.ps1
├── 99-SystemRestart/                   # Optional system reboot
│   └── 01-RebootSystem.ps1
└── README.md                           # Detailed extensibility guide
```

### Customization Options
**Add Custom Scripts:**
1. Create new phase folder: `05-CustomPhase/`
2. Add scripts: `01-CustomScript.ps1`
3. Scripts run automatically in numerical order

**Control Reboot Behavior:**
- **Enable reboot**: Keep `99-SystemRestart/` folder
- **Skip reboot**: Delete or rename `99-SystemRestart/` folder

**Modify Existing Steps:**
- Edit individual scripts without affecting others
- Add new steps between existing ones (e.g., `02.5-ExtraStep.ps1`)

### Script Requirements
Each script must:
- Return `$true` on success, `$false` on failure
- Use shared functions from `TwinCATDeployUtils.psm1`
- Follow logging conventions with `Write-Log`

### Deployment Usage
The main script will:
1. **Scan** for numbered phase folders
2. **Sort** phases and steps numerically
3. **Execute** each script in order
4. **Abort** deployment if any script fails

📖 **For complete extensibility documentation, see [`POWERSHELL SCRIPTS/README.md`](POWERSHELL%20SCRIPTS/README.md)**

</details>

---

<details>
<summary><h2>📦 TCPKG PACKAGES</h2></summary>

### Purpose
Contains offline TwinCAT packages required for installation in air-gapped environments.

### Required Structure
Place a folder containing TwinCAT package files (folder name can be anything, e.g., `packagesoffline`, `twincat-packages`, etc.):

```
TCPKG PACKAGES/
└── [any-folder-name]/
    ├── TwinCAT.Standard.XAR
    ├── TF2000.HMIServer.XAR
    ├── TF1200.UiClient.XAR
    ├── [other .XAR packages]
    └── [any TwinCAT package]
```

### How to Obtain

**Method 1 - TcPkg Command Line:**
```bash
# Download to specific directory (recommended)
tcpkg download TwinCAT.Standard.XAR -o "C:\packagesoffline"
tcpkg download TF2000.HMIServer.XAR -o "C:\packagesoffline"
tcpkg download TF1200.UiClient.XAR -o "C:\packagesoffline"
```

**Method 2 - TcPkg GUI:**
1. Open TwinCAT Package Manager GUI
2. Navigate to the packages you need
3. Use the download/export functionality to save packages to a folder


### Deployment Usage
The script will:
1. Find the first folder in `TCPKG PACKAGES/`
2. Copy it to `C:\packagesoffline`
3. Add it as a local package source with priority 1
4. Install the required packages using `tcpkg install`

</details>

---

<details>
<summary><h2>⚙️ TWINCAT BOOT FOLDER</h2></summary>

### Purpose
Contains TwinCAT runtime configuration that defines the system's operational behavior and project-specific settings.

### Required Structure
Place a single boot configuration folder (name can vary, e.g., `TwinCAT RT (x64)`, `TwinCAT RT (x86)`):

```
TWINCAT BOOT FOLDER/
└── [boot-folder-name]/
    ├── CurrentConfig.xml
    ├── Port_851.xml
    ├── TcRegistry.xml
    ├── [PLC project files]
    └── [other boot configuration files]
```

### How to Obtain

**From TwinCAT Project (Recommended):**
1. Build your TwinCAT solution successfully in Visual Studio
2. Navigate to: `...\<Solution name>\<Project name>\_Boot\<Platform>\`
3. Copy the entire platform folder (e.g., `TwinCAT RT (x64)` or `TwinCAT RT (x86)`)
4. **Reference**: [Beckhoff TwinCAT Boot Documentation](https://infosys.beckhoff.com/content/1033/tc3_grundlagen/6137492619.html?id=8038354968708727216)

**From existing TwinCAT system:**
Copy contents from: `C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot\`

**Important Notes:**
- Boot folder is generated after a successful build and activation
- Platform folder name indicates target architecture (x64/x86)
- Contains all necessary runtime configuration for your specific project


### Deployment Usage
The script will:
1. Find the first folder in `TWINCAT BOOT FOLDER/`
2. Copy it to `C:\ProgramData\Beckhoff\TwinCAT\3.1\Boot\`
3. This provides the runtime configuration TwinCAT loads on startup

</details>

---

<details>
<summary><h2>🖥️ HMI PROJECTS</h2></summary>

### Purpose
Contains TwinCAT HMI projects and server configuration for web-based interfaces using TwinCAT HMI (TF2000).

### Required Structure
```
HMI PROJECTS/
├── [hmi-project-1]/              # Any name (e.g., "HMI", "MyHMI", "WebInterface")
│   ├── www/
│   │   └── [published HMI files]
│   ├── storage.db
│   ├── logger.db
│   └── [other HMI runtime files]
├── [hmi-project-2]/              # Multiple projects supported
│   ├── www/
│   │   └── [published HMI files]
│   ├── storage.db
│   ├── logger.db
│   └── [other HMI runtime files]
└── TcHmiSrv.Service.Config.json  # Must be named exactly this
```

### How to Obtain

**HMI Project Files:**
1. **Publish your TwinCAT HMI projects** to the local TF2000 instance using TE2000 HMI Engineering
2. **Stop the TwinCAT HMI service** or disable the HMI server instance through the [TwinCAT HMI Service Configuration webpage](http://127.0.0.1:19800)
   - **Important**: Failure to stop the service will cause file permission issues when copying
3. **Copy each published project folder** from: `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service\[hmi-project-name]`
   - **Multiple projects**: Copy all project folders you want to deploy
   - **Maintain folder names**: Each project folder name will be preserved in the target system
4. **Restart the HMI service** after copying is complete

**HMI Server Configuration:**
1. **TcHmiSrv.Service.Config.json**: Copy from `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\`
2. This file configures the HMI service to start the appropriate HMI project instances
3. **Multiple projects**: The config file should reference all projects you want to run simultaneously

**Alternative Method:**
Copy from an existing working HMI system using the same procedure (stop service → copy all project folders → restart)


### Contents Description
- **[project-folder]/www/**: Published web-based HMI interface files
- **[project-folder]/storage.db**: HMI data storage database
- **[project-folder]/logger.db**: HMI logging database
- **TcHmiSrv.Service.Config.json**: Server configuration (ports, security, etc.)

### Deployment Usage
The script will:
1. Find all project folders in `HMI PROJECTS/` (excluding config files)
2. Copy each project folder to `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service\[project-name]\`
3. Copy `TcHmiSrv.Service.Config.json` to `C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\`

</details>

---


## Target Environment

These files are designed for:
- **Hardware**: CX20x3 Windows 11 x64
- **TwinCAT**: Version compatible with TcPkg 2.1.134
- **Use Case**: Offline/air-gapped installations

## Important Notes

- **Modular Architecture**: Deployment logic is fully modular and extensible via PowerShell scripts
- **Flexible naming**: Folder names within artifact categories can be customized
- **Single folder**: Each artifact category expects only one primary folder
- **Script Discovery**: PowerShell scripts are automatically discovered and executed in numerical order
- **File sizes**: Some artifacts (especially HMI projects) can be large
- **Versions**: Ensure artifact versions match target system requirements
- **Security**: Review all files and scripts before deployment in production environments

---

## ⚠️ Disclaimer

All sample code provided by Beckhoff Automation LLC are for illustrative purposes only and are provided "as is" and without any warranties, express or implied. Actual implementations in applications will vary significantly. Beckhoff Automation LLC shall have no liability for, and does not waive any rights in relation to, any code samples that it provides or the use of such code samples for any purpose.
