#Requires -Version 3.0
# Python 3.9 Embedded Enhancement Script
# Must be run from within the Python39 directory
# Version 1.2 - Optimized for embedded installations

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
}
else {
    Set-Content $pthFile -Value @("python39.zip", ".", "import site")
    Write-Host "Created $pthFile with site-packages support"
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
    $webClient.DownloadFile($getPipUrl, $getPipPath)
    Write-Host "Downloaded get-pip.py to temp directory"
    
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
        Get-Content "$PWD\pip-install-errors.log" | Select-Object -First 5
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

Write-Host "`nEnhancement complete! Your Python installation now supports:"
Write-Host "- Pip package manager (use: .\python.exe -m pip ...)"
Write-Host "- Site-packages directory: $PWD\Lib\site-packages"
Write-Host "- Scripts directory: $PWD\Scripts"
Write-Host "`nNote: This is a portable installation. Add to PATH manually if needed."