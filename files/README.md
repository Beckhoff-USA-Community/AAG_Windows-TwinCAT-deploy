# TwinCAT Installation files

This directory contains all the files needed for automated TwinCAT installation and configuration. The twincat-deploy script will automatically detect and use the first folder found in each subdirectory.

## Directory Structure

```
files/
├── README.md                           # This documentation file
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
├── HMI PROJECTS/                       # HMI projects and configuration
│   ├── TcHmiSrv.Service.Config.json    # ← Place HMI server config here
│   ├── [hmi-project-1]/                # ← Place HMI project folders here
│   │   ├── www/
│   │   ├── storage.db
│   │   └── [web server files]
│   └── [hmi-project-2]/                # ← Multiple projects supported
│       ├── www/
│       ├── storage.db
│       └── [web server files]
└── LICENSE/                            # TwinCAT license files (optional)
    ├── TwinCAT.lic                     # ← Place license files here
    ├── TF2000.lic                      # ← Function license files
    └── [other-licenses.lic]            # ← Additional licenses as needed
```

## Setup Instructions

1. **Populate each directory** according to the sections below
2. **Verify completeness** - ensure all required files are present
3. **Run the deployment script** - execute `twincat-deploy.ps1` to automate the installation

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

<details>
<summary><h2>📄 LICENSE</h2></summary>

### Purpose
Contains TwinCAT license files required for activating TwinCAT functions and features. This directory is optional - if no license files are provided, TwinCAT will run in demo/trial mode with limited functionality.

### Required Structure
```
LICENSE/
├── TwinCAT.lic                 # Core TwinCAT license (if needed)
├── TF2000.lic                  # HMI Server license
├── TF1200.lic                  # UI Client license
├── [function-licenses.lic]     # Additional function licenses
└── [custom-licenses.lic]       # Customer-specific licenses
```

### How to Obtain

**Method 1 - Beckhoff License Portal:**
1. Log into your Beckhoff customer account
2. Navigate to the license management section
3. Download the appropriate license files for your system
4. Place the `.lic` files in the LICENSE folder

**Method 2 - Existing TwinCAT System:**
Copy license files from: `C:\ProgramData\Beckhoff\TwinCAT\3.1\License\`

**Method 3 - License Server:**
If using a license server, you may not need individual license files

### Important Notes
- **Optional**: License files are not required for basic operation (demo mode)
- **Function-specific**: Each TwinCAT function (TF2000, TF1200, etc.) may require its own license
- **Hardware-bound**: Some licenses are tied to specific hardware (CPU-ID, dongle)
- **Backup**: Keep backup copies of license files in a secure location
- **Support**: Contact Beckhoff support for licensing questions

### Deployment Usage
The script will:
1. Check if `LICENSE/` folder exists
2. Copy all license files recursively to `C:\ProgramData\Beckhoff\TwinCAT\3.1\License\`
3. Log the count and names of copied license files
4. Continue deployment if no license files are found (with warning)

</details>

---

## Target Environment

These files are designed for:
- **Hardware**: CX20x3 Windows 11 x64
- **TwinCAT**: Version compatible with TcPkg 2.1.134
- **Use Case**: Offline/air-gapped installations

## Important Notes

- **Flexible naming**: Folder names within each category can be customized
- **Single folder**: Each category expects only one primary folder (except PowerShell modules)
- **File sizes**: Some artifacts (especially HMI projects) can be large
- **Versions**: Ensure artifact versions match target system requirements
- **Security**: Review all files before deployment in production environments
- **Licensing**: Ensure proper TwinCAT licenses are available on target systems