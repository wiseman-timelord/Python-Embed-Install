#Requires -Version 3.0
# Python 3.9 Embedded Enhancement Script
# Must be run from within the Python39 directory
# Version 1.4 - Added pip upgrade step

$ErrorActionPreference = "Stop"

# 1. Create essential directories
$foldersToCreate = @(
    "DLLs",
    "Lib\site-packages",
    "Scripts"
)

foreach ($folder in $foldersToCreate) {
    $fullPath = Join-Path -Path $PWD -ChildPath $folder
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath | Out-Null
        Write-Host "Created directory: $folder"
    }
}

# 2. Fix python39._pth to enable site-packages
$pthFile = "python39._pth"
if (Test-Path $pthFile) {
    $content = Get-Content $pthFile
    if ($content -contains "#import site") {
        $newContent = $content -replace '#import site', 'import site'
        Set-Content $pthFile -Value $newContent -Force
        Write-Host "Enabled site-packages in $pthFile"
    }
    elseif ($content -notcontains "import site") {
        Add-Content $pthFile -Value "import site"
        Write-Host "Added site-packages support to $pthFile"
    }
    # Ensure site-packages path is included
    if ($content -notmatch "\.\\Lib\\site-packages") {
        Add-Content $pthFile -Value ".\Lib\site-packages"
        Write-Host "Added site-packages path to $pthFile"
    }
}
else {
    Set-Content $pthFile -Value @(
        "python39.zip",
        ".",
        "import site",
        ".\Lib\site-packages"
    )
    Write-Host "Created $pthFile with full site-packages support"
}

# 3. Install pip and setuptools
try {
    # Configure TLS for PowerShell v3
    $tlsTypes = @("Tls12", "Tls11", "Tls", "Ssl3")
    $validProtocols = [System.Net.SecurityProtocolType]0
    $tlsTypes | ForEach-Object {
        if ([System.Net.SecurityProtocolType]::TryParse($_, [ref]$validProtocols)) {
            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor $validProtocols
            } catch {
                # Ignore if protocol can't be set
            }
        }
    }

    $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
    $getPipPath = Join-Path -Path $env:TEMP -ChildPath "get-pip.py"
    
    # Download using WebClient
    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($getPipUrl, $getPipPath)
        Write-Host "Downloaded get-pip.py to temp directory"
    } catch {
        Write-Host "Failed to download get-pip.py: $_"
        Write-Host "Attempting fallback to BitsTransfer..."
        Start-BitsTransfer -Source $getPipUrl -Destination $getPipPath
    }
    
    # Execute get-pip.py
    Write-Host "Installing pip and setuptools..."
    $pipArgs = @(
        $getPipPath,
        "--no-warn-script-location",
        "--disable-pip-version-check"
    )
    $pipInstall = Start-Process -FilePath ".\python.exe" `
                -ArgumentList $pipArgs `
                -Wait -PassThru -NoNewWindow `
                -RedirectStandardOutput "$PWD\pip-install.log" `
                -RedirectStandardError "$PWD\pip-install-errors.log"
    
    if ($pipInstall.ExitCode -ne 0) {
        Write-Host "Pip installation failed. Check pip-install-errors.log"
        Get-Content "$PWD\pip-install-errors.log" | Select-Object -First 10
    }
    else {
        Write-Host "Successfully installed pip and setuptools"
        # Verify installation
        $pipVersion = .\python.exe -m pip --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Verified: $pipVersion"
        }
    }
}
catch {
    Write-Host "Error: $_"
    Write-Host "Manual solution:"
    Write-Host "1. Download get-pip.py from https://bootstrap.pypa.io/get-pip.py"
    Write-Host "2. Save to your Desktop"
    Write-Host "3. Run: .\python.exe `"%UserProfile%\Desktop\get-pip.py`""
}

# 4. Upgrade pip, setuptools and wheel
try {
    Write-Host "`nUpgrading pip, setuptools and wheel..."
    $upgradeArgs = @(
        "-m", "pip", "install",
        "--upgrade",
        "pip", "setuptools", "wheel",
        "--no-warn-script-location",
        "--disable-pip-version-check"
    )
    
    $upgradeProcess = Start-Process -FilePath ".\python.exe" `
                    -ArgumentList $upgradeArgs `
                    -Wait -PassThru -NoNewWindow `
                    -RedirectStandardOutput "$PWD\pip-upgrade.log" `
                    -RedirectStandardError "$PWD\pip-upgrade-errors.log"
    
    if ($upgradeProcess.ExitCode -ne 0) {
        Write-Host "Upgrade failed. Check pip-upgrade-errors.log"
        Get-Content "$PWD\pip-upgrade-errors.log" | Select-Object -First 10
    }
    else {
        Write-Host "Successfully upgraded core packages"
        # Verify versions
        $versions = .\python.exe -c "import pip, setuptools, wheel; print(f'pip: {pip.__version__}\nsetuptools: {setuptools.__version__}\nwheel: {wheel.__version__}')" 2>&1
        Write-Host "Current versions:`n$versions"
    }
}
catch {
    Write-Host "Error upgrading packages: $_"
}

# 5. Install essential packages
try {
    Write-Host "`nInstalling essential packages..."
    $essentialPackages = @(
        # Core networking
        "requests",         # HTTP requests
        "urllib3",         # HTTP client
        "certifi",         # SSL certificates
        "charset-normalizer", # Character encoding
        "idna",            # Internationalized domain names
        
        # Installer dependencies
        "tqdm",            # Progress bars (required by Vulkan installer)
        "colorama",        # Cross-platform colored terminal text
        "packaging",       # Core utilities for Python packages
        
        # Backports for Python 3.9 compatibility
        "dataclasses",     # Data class backport
        "enum34; python_version < '3.4'", # Enum backport (conditional)
        "pathlib2",        # Pathlib backport
        "typing_extensions", # Additional typing support
        
        # Additional utilities
        "six",             # Python 2/3 compatibility
        "pywin32; sys_platform == 'win32'", # Windows API access
        "psutil"          # Process utilities
    )
    
    foreach ($package in $essentialPackages) {
        Write-Host "Installing $package..."
        $packageInstall = Start-Process -FilePath ".\python.exe" `
                    -ArgumentList @(
                        "-m", "pip", "install",
                        $package,
                        "--disable-pip-version-check",
                        "--no-warn-script-location"
                    ) `
                    -Wait -PassThru -NoNewWindow `
                    -RedirectStandardOutput "$PWD\$package-install.log" `
                    -RedirectStandardError "$PWD\$package-install-errors.log"
        
        if ($packageInstall.ExitCode -ne 0) {
            Write-Host "$package installation failed. Check $package-install-errors.log"
            Get-Content "$PWD\$package-install-errors.log" | Select-Object -First 5
        }
        else {
            Write-Host "Successfully installed $package"
            # Handle packages with hyphens and conditional installs
            $moduleName = ($package -split ";")[0].Trim() -replace "-", "_"
            
            # Skip verification for conditional packages
            if ($package -notmatch ";") {
                $verificationScript = @"
try:
    import $moduleName
    version = getattr($moduleName, '__version__', 
             getattr($moduleName, 'version', 
             getattr($moduleName, 'VERSION', 'unknown')))
    print(f'$package version: {version}')
    exit(0)
except Exception as e:
    print(f'Verification failed: {str(e)}')
    exit(1)
"@
                $tempScriptPath = Join-Path -Path $env:TEMP -ChildPath "verify_$($moduleName).py"
                Set-Content -Path $tempScriptPath -Value $verificationScript
                
                $packageCheck = .\python.exe $tempScriptPath 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Verified: $packageCheck"
                }
                else {
                    Write-Host "Verification failed: $packageCheck"
                }
                Remove-Item -Path $tempScriptPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
catch {
    Write-Host "Error installing essential packages: $_"
    Write-Host "Check these log files for details:"
    Get-ChildItem "$PWD\*-install-errors.log" | ForEach-Object {
        Write-Host "  - $($_.Name)"
    }
}

# 6. Final system check with backport verification
Write-Host "`nRunning final system checks..."
$checks = @(
    @{Name="Pip"; Test={.\python.exe -m pip --version 2>&1}},
    @{Name="Requests"; Test={.\python.exe -c "import requests; print(requests.__version__)" 2>&1}},
    @{Name="SSL"; Test={.\python.exe -c "import ssl; print(ssl.OPENSSL_VERSION)" 2>&1}},
    @{Name="Core Packages"; Test={.\python.exe -c @"
try:
    import pip, setuptools, wheel
    print(f'pip {pip.__version__}, setuptools {setuptools.__version__}, wheel {wheel.__version__}')
except Exception as e:
    print(f'Check failed: {str(e)}')
"@ 2>&1}},
    @{Name="Backports"; Test={.\python.exe -c @"
try:
    import dataclasses, pathlib2, typing_extensions
    print('Backports: dataclasses, pathlib2, typing_extensions available')
except Exception as e:
    print(f'Missing backports: {str(e)}')
"@ 2>&1}}
)

foreach ($check in $checks) {
    try {
        $result = & $check.Test
        Write-Host "$($check.Name) check: $result"
    }
    catch {
        Write-Host "$($check.Name) check failed: $_"
    }
}

foreach ($check in $checks) {
    try {
        $result = & $check.Test
        Write-Host "$($check.Name) check: $result"
    }
    catch {
        Write-Host "$($check.Name) check failed: $_"
    }
}

Write-Host "`nEnhancement complete! Your Python installation now supports:"
Write-Host "- Updated pip ($(.\python.exe -m pip --version | Select-String '\d+\.\d+\.\d+'))"
Write-Host "- Essential networking packages"
Write-Host "- Proper site-packages functionality"
Write-Host "`nNote: This is a portable installation. Add to PATH manually if needed."