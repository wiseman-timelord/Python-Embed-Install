# Python-Embed-Install
Status: Beta (Early and Part-Complete)

### Description
Its an installer for the package "Python 3.9 Embedded", otherwise known as "manual install". There is a zip `python-3.9.0-embed-amd64.zip`, and with my installer script it becomes a "Semi-Automatic" process to install. Each time I install/reinstall this program, I will integrate more features, such as making it a complete downloader/installer/pathUpdater, but for now, I will be making this program to assist the process from the point of having, expanded the zip to the `CORRECT` directory and added python to the path, and that will be version 1.

### Development
It seemed to install most stuff correctly for me on windows 8, though, I am still developing this currently...
- working through remaining issues, and integrating updates into installer, while using "Chat-Gradio-Gguf" installer for purposes of testing robustness.

### File Structure
```
.\Python_Embed_Install.bat
.\installer.py
```

### Instructions
1. Unpack the Embedded version of "Python 3.9" to the directory `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39` (obviously replacing "**YourUserName**" with the relevant `User Name`. 
2. Put `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39` on the path in the "Control Panel > System > Advanced System Settings > Advanced > Environment Variables". 
3. Put, `Python_Embed_Install.bat` and `instller.py`, in `C:\Users\**YourUserName**\AppData\Local\Programs\Python\Python39`, then run `Python_Embed_Install.bat`.
