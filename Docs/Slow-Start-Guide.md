
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
# Change the starting directory:
-BasePath <C:\Path\To\Folder> 

# Check the Config File parameters and check server connectivity
-Verify

# Import after creating:
-Import
```

The default Config path is *C:\Users\<YourName>\Documents\LMStudio-PSClient*.

*Usage Example:*
![](/images/new-lmconfig-example.png)

### Import an Existing Config

**Import-LMConfig** requires one parameter:
```
Import-LMConfig -ConfigFile <C:\Path\To\Folder\lmsc.cfg>

```

An additional parameter is also available:
```
# Check the Config File parameters and check server connectivity
-Verify
```

*Usage Example:*

![](/images/import-lmconfig-example.png)

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
![](/images/show-lm-settings-example.png)

### Modify Config Settings

**Set-LMConfigOptions** requires two parameters:
```
Set-LMConfigOptions -Branch <Branch Name> -Options @{"HashKey"="HashValue}
```

An additional parameter is also available:
```
# Write the config option to your Config File (lmsc.cfg)
-Commit
```

**-Options** can accept multiple key-value pairs. 

However, all settings must be under the same Branch: **ChatSettings**, **FilePaths**, **ServerInfo** or **URIs**

JSON-formatted example of the Config File key/value pairs under each Branch:
![](/images/lmsc-cfg-example.png)

*Usage Example:*
![](/images/set-lmconfigoptions-example.png)




