
# Config Management
This section covers tools to create, import and modify the Config File.

## Create a New Config

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

## Import an Existing Config

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

## View a Config

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

## Modify Config Settings

**Set-LMConfigOptions** requires two parameters:
```
Set-LMConfigOptions -Branch <Branch Name> -Options @{"HashKey"="HashValue}
```

An additional parameter is also available:
```
-Commit     # Write the config option to your Config File (lmsc.cfg)
```

**-Options** can accept multiple key-value pairs. 

However, all settings must be under the same Branch: **ChatSettings**, **FilePaths**, or **ServerInfo**

*Usage Example:*
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/set-lmconfigoptions-example.png)

## List of Config Settings

**ServerInfo**
```
Server   : localhost        # LMStudio Server Hostname/IP address
Port     : 1234             # LMStudio Server Port
Endpoint : localhost:1234   # Combined Server/Port (mostly unused)
```

**ChatSettings**
```
temperature  : 0.5          # Temperature (creativity)
max_tokens   : -1           # Maximum tokens to generate (-1 = no limit)
stream       : True         # Stream output (False = Lump Sum output)
ContextDepth : 10           # Prior assistant/user dialog context
Greeting     : False        # Enable/disable the start-up "greeting"
SystemPrompt : You are a helpful, smart, kind, personal and open chat partner. You always fulfill the user's requests to the best of your ability.
Markdown     : True         # Interpret markdown in output
SavePrompt   : True         # Prompt for new filename when starting new chat 
```

**FilePaths**
```
HistoryFilePath  : C:\Users\JoeBob\Documents\LMStudio-PSClient\JoeBob-HF.index
DialogFolderPath : C:\Users\JoeBob\Documents\LMStudio-PSClient\JoeBob-HF-DialogFiles
GreetingFilePath : C:\Users\JoeBob\Documents\LMStudio-PSClient\JoeBob-HF-DialogFiles\hello.greetings
StreamCachePath  : C:\Users\JoeBob\Documents\LMStudio-PSClient\stream.cache
SystemPromptPath : C:\Users\JoeBob\Documents\LMStudio-PSClient\system.prompts
DialogFilePath   : C:\Users\JoeBob\Documents\LMStudio-PSClient\JoeBob-HF-DialogFiles\llama-3.1-test.dialog
```