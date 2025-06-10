#Requires -Version 3.0
# Python 3.9 Embedded Enhancement Script
# Must be run from within the Python39 directory
# Version 1.6 - Fixed package installation and verification issues

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
    $upgradeOutput = & ".\python.exe" -m pip install --upgrade pip setuptools wheel --no-warn-script-location --disable-pip-version-check 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Upgrade failed with error:"
        $upgradeOutput | Select-Object -First 10 | ForEach-Object { Write-Host $_ }
    }
    else {
        Write-Host "Successfully upgraded core packages"
        # Verify versions using direct command execution
        try {
            $versions = & ".\python.exe" -c "import pip, setuptools, wheel; print(f'pip: {pip.__version__}\nsetuptools: {setuptools.__version__}\nwheel: {wheel.__version__}')" 2>&1
            Write-Host "Current versions:`n$versions"
        }
        catch {
            Write-Host "Version verification failed: $_"
        }
    }
}
catch {
    Write-Host "Error upgrading packages: $_"
    Write-Host "Manual upgrade command: .\python.exe -m pip install --upgrade pip setuptools wheel"
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
        "pathlib2",        # Pathlib backport
        "typing_extensions", # Additional typing support
        
        # Additional utilities
        "six",             # Python 2/3 compatibility
        "pywin32",         # Windows API access
        "psutil"           # Process utilities
    )
    
    # Add enum34 only if needed for older Python versions
    $pythonVersion = & ".\python.exe" -c "import sys; print(sys.version.split()[0])" 2>&1
    if ([System.Version]::Parse($pythonVersion) -lt [System.Version]::Parse("3.4.0")) {
        $essentialPackages += "enum34"
    }
    
    foreach ($package in $essentialPackages) {
        $safePackageName = $package -replace '[;<>|&]', '_'  # Sanitize package name
        Write-Host "Installing $package..."
        
        try {
            $packageOutput = & ".\python.exe" -m pip install $package --disable-pip-version-check --no-warn-script-location 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "$package installation failed:"
                $packageOutput | Select-Object -First 5 | ForEach-Object { Write-Host $_ }
            }
            else {
                Write-Host "Successfully installed $package"
                
                # Verification for non-conditional packages
                $moduleName = $package -replace "-", "_"
                $verificationResult = & ".\python.exe" -c "try: import $moduleName; print('$moduleName imported successfully'); exit(0) except ImportError: print('$moduleName not found'); exit(1) except Exception as e: print('Verification error: ' + str(e)); exit(2)" 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Verified: $verificationResult"
                }
                else {
                    Write-Host "Verification failed: $verificationResult"
                }
            }
        }
        catch {
            Write-Host "Error installing $package : $_"
        }
    }
}
catch {
    Write-Host "Error installing essential packages: $_"
}

# 6. Install virtualenv and create venv compatibility
try {
    Write-Host "`nInstalling virtualenv for venv support..."
    $venvArgs = @(
        "-m", "pip", "install",
        "virtualenv",
        "--disable-pip-version-check",
        "--no-warn-script-location"
    )
    
    $venvInstall = Start-Process -FilePath ".\python.exe" `
                -ArgumentList $venvArgs `
                -Wait -PassThru -NoNewWindow `
                -RedirectStandardOutput "$PWD\venv-install.log" `
                -RedirectStandardError "$PWD\venv-install-errors.log"
    
    if ($venvInstall.ExitCode -ne 0) {
        Write-Host "Virtualenv installation failed. Check venv-install-errors.log"
        Get-Content "$PWD\venv-install-errors.log" | Select-Object -First 10
    }
    else {
        Write-Host "Successfully installed virtualenv"
        
        # Create venv.py symlink for compatibility
        $venvSource = Join-Path -Path $PWD -ChildPath "Scripts\virtualenv.exe"
        $venvTarget = Join-Path -Path $PWD -ChildPath "Scripts\venv.exe"
        
        if (-not (Test-Path $venvTarget)) {
            try {
                cmd /c mklink "$venvTarget" "$venvSource" | Out-Null
                Write-Host "Created venv.exe symlink for compatibility"
            }
            catch {
                Write-Host "Failed to create venv symlink: $_"
                Write-Host "Manual workaround: Open admin command prompt and run:"
                Write-Host "  mklink `"$venvTarget`" `"$venvSource`""
            }
        }
        
        # Verify installation
        Write-Host "Verifying virtual environment creation..."
        $testVenvPath = Join-Path -Path $env:TEMP -ChildPath "test_venv_$([System.IO.Path]::GetRandomFileName())"
        $venvTest = Start-Process -FilePath ".\python.exe" `
                    -ArgumentList @("-m", "virtualenv", $testVenvPath) `
                    -Wait -PassThru -NoNewWindow `
                    -RedirectStandardOutput "$PWD\venv-test.log" `
                    -RedirectStandardError "$PWD\venv-test-errors.log"
        
        if ($venvTest.ExitCode -eq 0) {
            Write-Host "Virtual environment test successful"
            Remove-Item $testVenvPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            Write-Host "Virtual environment test failed. Check venv-test-errors.log"
            Get-Content "$PWD\venv-test-errors.log" | Select-Object -First 10
        }
    }
}
catch {
    Write-Host "Error installing virtualenv: $_"
    Write-Host "Manual installation:"
    Write-Host "  .\python.exe -m pip install virtualenv"
    Write-Host "  mklink `"$PWD\Scripts\venv.exe`" `"$PWD\Scripts\virtualenv.exe`""
}

# 7. Final system check with backport verification
Write-Host "`nRunning final system checks..."
$checks = @(
    @{Name="Pip"; Test={.\python.exe -m pip --version 2>&1}},
    @{Name="Requests"; Test={.\python.exe -c "import requests; print(requests.__version__)" 2>&1}},
    @{Name="SSL"; Test={.\python.exe -c "import ssl; print(ssl.OPENSSL_VERSION)" 2>&1}},
    @{Name="Core Packages"; Test={.\python.exe -c @"
try:
    import pip, setuptools, wheel
    print(f'pip {pip.__version__}, setuptools {setuptools.__version__}, wheel {wheel.__version__}')
except ImportError as e:
    print(f'Missing package: {e.name}')
except Exception as e:
    print(f'Check failed: {str(e)}')
"@ 2>&1}},
    @{Name="Backports"; Test={.\python.exe -c @"
try:
    import dataclasses, typing_extensions
    try:
        import pathlib2
        print('Backports: dataclasses, pathlib2, typing_extensions available')
    except ImportError:
        print('Backports: dataclasses, typing_extensions available (pathlib2 missing)')
except ImportError as e:
    print(f'Missing backport: {e.name}')
except Exception as e:
    print(f'Check failed: {str(e)}')
"@ 2>&1}},
    @{Name="Virtualenv"; Test={.\python.exe -c "import virtualenv; print('virtualenv ' + virtualenv.__version__)" 2>&1}},
    @{Name="Venv Command"; Test={
        $testPath = Join-Path $env:TEMP "venv_test_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $result = & ".\python.exe" -m virtualenv $testPath 2>&1
        if ($LASTEXITCODE -eq 0) {
            if (Test-Path $testPath) { Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue }
            "Working"
        } else {
            if (Test-Path $testPath) { Remove-Item $testPath -Recurse -Force -ErrorAction SilentlyContinue }
            "Failed: $($result -join "`n")"
        }
    }}
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

Write-Host "`nEnhancement complete! Your Python installation now supports:"
Write-Host "- Updated pip ($(.\python.exe -m pip --version | Select-String '\d+\.\d+\.\d+'))"
Write-Host "- Essential networking packages"
Write-Host "- Proper site-packages functionality"
Write-Host "- Virtual environment support (via virtualenv)"
Write-Host "`nNote: This is a portable installation. Add to PATH manually if needed."