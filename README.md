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

I update my [**development journal**](./Docs/Dev-Journal.md) when I work on this project.
**Last Update:** July 16, 2024

This project is not complete, and documentation is in the works. Things will change, but what I have in mind is usually in the journal.

## Alpha Quick-Start Guide:

Ready to get your alpha groove on? This quick-start guide assumes LMStudio is configured and running.

1. Rename *LMStudio-Client.psm1* to *LMStudio-Client.ps1*.

2. Import the functions:
```
. .\LMStudio-Client.ps1
```

3. Create a new config:
```
New-LMConfig -Server <Name/IP> -Port <1234>
```

4. Import the config:
```
Import-LMConfig -ConfigFile "$Env:USERPROFILE\Documents\LMStudio-PSClient\lmsc.cfg" -Verify
```

5. Start the chat program:
```
Start-LMChat
```

6. For help changing settings, in the chat prompt run this command:
```
:help
```

## Notes/Addendum:

**07/07/2024** ~~The current version of the code does **not** work with Powershell 5. I will attempt to resolve this issue, and I'm not sure when it was first introduced.~~ This issue is caused by the use of the **clean {}** block in Powershell, which I learned was only introduced in 7.3.

I've commented out the **clean {}** block (for now).