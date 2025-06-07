# Python-Embed-Install
Status: Beta (Early and Part-Complete)

### Description
Its an installer for the package "Python 3.9 Embedded", otherwise known as "manual install". There is a zip `python-3.9.0-embed-amd64.zip`, and with my installer script it becomes a "Semi-Automatic" process to install. Later versions integrate more features, such as making it a complete downloader/installer/pathUpdater, but for now, I will be making this program to assist the process from the point of having, expanded the zip to the `CORRECT` directory and added python to the path. Additionally having added stuff typically installed with "Python 3.12" exe installer, that were also found available on "Python 3.9", so as to produce somewhat "Python 3.9++".

### Preview
Currently it does this...
```
Dp0'd to Script.

Python 3.9 Embedded Enhancement Installer
========================================

Checking PowerShell version...
Found PowerShell v +3

System Check Complete - All Requirements Met
===========================================
Running Python enhancement...

Added site-packages path to python39._pth
Downloaded get-pip.py to temp directory
Installing pip and setuptools...
Successfully installed pip and setuptools
Verified: pip 25.1.1 from C:\Users\MaStar\AppData\Local\Programs\Python\Python39
\Lib\site-packages\pip (python 3.9)

Upgrading pip, setuptools and wheel...
Successfully upgraded core packages
Error upgrading packages: Traceback (most recent call last):

Installing essential packages...
Installing requests...
Successfully installed requests
Verified: requests version: 2.32.3
Installing urllib3...
Successfully installed urllib3
Verified: urllib3 version: 2.4.0
Installing certifi...
Successfully installed certifi
Verified: certifi version: 2025.04.26
Installing charset-normalizer...
Successfully installed charset-normalizer
Verified: charset-normalizer version: 3.4.2
Installing idna...
Successfully installed idna
Verified: idna version: 3.10
Installing tqdm...
Successfully installed tqdm
Verified: tqdm version: 4.67.1
Installing colorama...
Successfully installed colorama
Verified: colorama version: 0.4.6
Installing packaging...
Successfully installed packaging
Verified: packaging version: 25.0
Installing dataclasses...
Successfully installed dataclasses
Verified: dataclasses version: unknown
Installing enum34; python_version < '3.4'...
enum34; python_version < '3.4' installation failed. Check enum34; python_version
 < '3.4'-install-errors.log
Error installing essential packages: Illegal characters in path.
Check these log files for details:
  - certifi-install-errors.log
  - charset-normalizer-install-errors.log
  - colorama-install-errors.log
  - dataclasses-install-errors.log
  - idna-install-errors.log
  - packaging-install-errors.log
  - pip-install-errors.log
  - requests-install-errors.log
  - tqdm-install-errors.log
  - urllib3-install-errors.log

Running final system checks...
Pip check: pip 25.1.1 from C:\Users\MaStar\AppData\Local\Programs\Python\Python3
9\Lib\site-packages\pip (python 3.9)
Requests check: 2.32.3
SSL check: OpenSSL 1.1.1g  21 Apr 2020
Core Packages check: Check failed: C:\Users\MaStar\AppData\Local\Programs\Python
\Python39\python39.zip\distutils\core.pyc
Backports check: Missing backports: No module named 'pathlib2'
Pip check: pip 25.1.1 from C:\Users\MaStar\AppData\Local\Programs\Python\Python3
9\Lib\site-packages\pip (python 3.9)
Requests check: 2.32.3
SSL check: OpenSSL 1.1.1g  21 Apr 2020
Core Packages check: Check failed: C:\Users\MaStar\AppData\Local\Programs\Python
\Python39\python39.zip\distutils\core.pyc
Backports check: Missing backports: No module named 'pathlib2'

Enhancement complete! Your Python installation now supports:
- Updated pip (pip 25.1.1 from C:\Users\MaStar\AppData\Local\Programs\Python\Pyt
hon39\Lib\site-packages\pip (python 3.9))
- Essential networking packages
- Proper site-packages functionality

Note: This is a portable installation. Add to PATH manually if needed.
Check the log files in this directory:
  pip-install.log
  pip-install-errors.log

=============================
ENHANCEMENT COMPLETED SUCCESSFULLY

Test with:
  python -m pip --version
  python -c "import site; print(site.getsitepackages())"

Script execution finished. Press any key to exit...

```

## Requirements 
- Windows 7-8.1 - Intended for Windows versions where Python 3.9+ exe install dont work otherwise.
- Powershell v3+, the installer is powershell, so as to not have Python requirements to install.
- The file `python-3.9.0-embed-amd64.zip` from "python.org".
- Administrator Rights, preferably with the hack for right click "Run as Administrator"

### Instructions
1. Unpack the Embedded version of "Python 3.9" to the directory `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39` (obviously replacing "**YourUserName**" with the relevant `User Name`. 
2. Put `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39` on the path in the "Control Panel > System > Advanced System Settings > Advanced > Environment Variables". 
3. Put, `Python_Embed_Install.bat` and `instller.py`, in `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39`.
4. To run the tool, right click on `Python_Embed_Install.bat`, then right click "Run as Administrator", if not then elevate a console to admin, go to the relevant directory, and then run `Python_Embed_Install.bat`. 
- When run watch install operation. Follow up on issues, to ensure complete install, or wait for later version that "MAY" address issues found.

## Development
It seemed to install most stuff correctly for me on windows 8, though, I am still developing this currently...
1. Test and update, until working as expected, packaging for each significant update.
2. I know Build-Tools is not installing correctly. It has some error.
2. Make release version when done updating.

### File Structure
```
.\Python_Embed_Install.bat
.\installer.py
```

