# LMStudio-Client

A feature-rich Powershell LMStudio client.

![](/Docs/images/alpacas-prompt.gif)


## Features:

- Use LMStudio chat from any computer on your network!

- Records and saves LLM chat dialogs locally
  - Built-in file management, indexing (*search* will be included)
  - Previous dialogs can be resumed easily 

- Persistent configuration management:
  - Settings are preserved in a configuration file
  - Settings can be modified and saved easily

- And more!
  - Seriously, there's a lot of functionality built into this module.
  - What these are and how to use them will be included in the documentation.


## Quick-Start Guide
Ready to get your alpha groove on? This quick-start guide assumes LMStudio is configured and running.

![](/Docs/images/quickstart-diagram.png)

1. Save the Module Folder (*LMStudio-Client*) to your **Documents\WindowsPowerShell\Modules** folder.

2. Import the module:
```
Import-Module LMStudio-Client
```

3. If a Config has never been created, create one:
```
New-LMConfig -Server <Name/IP> -Port <1234>
```
  - Creates the "root" folder
  - Creates a new Config File (*lmsc.cfg*)
  - Creates a new History File (*username-HF.index*)
  - Creates a Dialog Files folder (*username-HF-DialogFiles*)

4. Import the config:
```
Import-LMConfig -ConfigFile "$Env:USERPROFILE\Documents\LMStudio-PSClient\lmsc.cfg" -Verify
```
  - Imports the Config File (*lmsc.cfg*)
  - Stores settings in *$Global:LMStudioVars*

5. Start the chat program:
```
Start-LMChat
```
  - No Parameters: Creates a new *.dialog* file
  - **-Resume**: Opens *.dialog* file in *$Global:LMStudioVars.FilePaths.DialogFilePath*
  - **-Resume -FromSelection**: Opens *.dialog* file from selection prompt


6. For help changing chat settings, in the chat prompt run this command:
```
:help
```

## Notes/Addendum:

I update my [**dev journal**](./Docs/Dev-Journal.md) when I work on this project.

Last Update: **July 28, 2024**

I've begun writing the documentation, as [**Slow-Start Guide**](./Docs/Slow-Start-Guide.md).

Last Update: **July 28, 2024**

**07/18/2024** I have created the PSD1 file so these functions can be imported as a proper Powershell module. See the [**dev journal**](./Docs/Dev-Journal.md) for details.

**07/07/2024** ~~The current version of the code does **not** work with Powershell 5. I will attempt to resolve this issue, and I'm not sure when it was first introduced.~~ This issue is caused by the use of the **clean {}** block in Powershell, which I learned was only introduced in 7.3.

I've commented out the **clean {}** block (for now).