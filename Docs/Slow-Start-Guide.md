
🚧 CONSTRUCTION ZONE 🚧

# Slow-Start Guide
Come on in, and make yourself at home!

## Config Management
This section covers tools to create, import and modify the Config File.

### Create a New Config

**New-LMConfig** requires two parameters:
```
New-LMConfig -Server <Name/IP> -Port <1234>
```

Other parameters are also available:
```
-BasePath <C:\Path\To\Folder> # Change the starting directory
-Verify                       # Check the Config File parameters and check server connectivity
-Import                       # Import after creating:
```

The default Config path is *C:\Users\<YourName>\Documents\LMStudio-PSClient*.

*Usage Example:*
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/new-lmconfig-example.png)

### Import an Existing Config

**Import-LMConfig** requires one parameter:
```
Import-LMConfig -ConfigFile <C:\Path\To\Folder\lmsc.cfg>

```

An additional parameter is also available:
```
-Verify     # Check the Config File parameters and check server connectivity
```

*Usage Example:*

![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/import-lmconfig-example.png)

### View a Config

To view your current, loaded Config in a text file, run the following command:
```
Show-LMSettings
```
To view the output in a console, run the following command:
```
Show-LMSettings -InConsole
```

*Usage Example:*
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/show-lm-settings-example.png)

### Modify Config Settings

**Set-LMConfigOptions** requires two parameters:
```
Set-LMConfigOptions -Branch <Branch Name> -Options @{"HashKey"="HashValue}
```

An additional parameter is also available:
```
-Commit     # Write the config option to your Config File (lmsc.cfg)
```

**-Options** can accept multiple key-value pairs. 

However, all settings must be under the same Branch: **ChatSettings**, **FilePaths**, **ServerInfo** or **URIs**

JSON-formatted example of the Config File key/value pairs under each Branch:
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/lmsc-cfg-example.png)

*Usage Example:*
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/set-lmconfigoptions-example.png)




