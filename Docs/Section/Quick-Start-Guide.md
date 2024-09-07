**Ready to get your alpha groove on?** 
This quick-start guide assumes LMStudio is configured and running.

If you need help understanding the LMStudio Server configuration, check out [the official LM Studio docs](https://lmstudio.ai/docs/local-server).

## 1. Save the Module:
Put *LMStudio-Client* in your **Documents\WindowsPowerShell\Modules** folder.

## 2. Import the module:
```
Import-Module LMStudio-Client
```

## 3. Create a Config:
 If a Config has never been created, create one:
```
New-LMConfig -Server <Name/IP> -Port <1234>
```
  - Creates the "root" folder
  - Creates a new Config File (*lmsc.cfg*)
  - Creates a new History File (*username-HF.index*)
  - Creates a Dialog Files folder (*username-HF-DialogFiles*)

## 4. Import the config:
```
Import-LMConfig -ConfigFile "$Env:USERPROFILE\Documents\LMStudio-PSClient\lmsc.cfg" -Verify
```
  - Imports the Config File (*lmsc.cfg*)
  - Stores settings in *$Global:LMStudioVars*

## 5. Start the chat program:
```
Start-LMChat
```
  - No Parameters: Creates a new *.dialog* file
  - **-Resume**: Opens *.dialog* file in *$Global:LMStudioVars.FilePaths.DialogFilePath*
  - **-Resume -FromSelection**: Opens *.dialog* file from selection prompt


## 6. Get help:
For help changing chat settings, in the chat prompt run this command:
```
:help
```

This diagram outlines the actions taken in each of the above steps:
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/quickstart-diagram.png)