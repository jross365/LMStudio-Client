
# Importing the Module
There are several different options you can use to import the module:

## Normal Import
The normal way to import this module is:

```
Import-Module LMStudio-Client
```

* Only Public functions are exported
* Config must be imported manually (*Import-LMConfig*)

This is the list of Public functions:
```
PS C:\> Get-Command -Module LMStudio-Client

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Add-LMSystemPrompt                                 0.0        LMStudio-Client
Function        Get-LMGreeting                                     0.0        LMStudio-Client
Function        Get-LMModel                                        0.0        LMStudio-Client
Function        Get-LMResponse                                     0.0        LMStudio-Client
Function        Import-LMConfig                                    0.0        LMStudio-Client
Function        New-LMConfig                                       0.0        LMStudio-Client
Function        New-LMTemplate                                     0.0        LMStudio-Client
Function        Remove-LMSystemPrompt                              0.0        LMStudio-Client
Function        Repair-LMHistoryFile                               0.0        LMStudio-Client
Function        Search-LMChatDialog                                0.0        LMStudio-Client
Function        Select-LMSystemPrompt                              0.0        LMStudio-Client
Function        Set-LMConfigOptions                                0.0        LMStudio-Client
Function        Show-LMSettings                                    0.0        LMStudio-Client
Function        Start-LMChat                                       0.0        LMStudio-Client
```

## Autoload Config
To automatically import the Config (*from the default location*):

```
Import-Module LMStudio-Client -ArgumentList "Auto"
```

* Only "Public" functions are exported
* Module attempts to load *$($env:USERPROFILE)\Documents\LMStudio-PSClient\lmsc.cfg*

## Expose All Functions
To expose *all* functions on import (*and not only user-friendly ones*):

```
Import-Module LMStudio-Client -ArgumentList "ExportAll"
```

* "Public" and "Private" functions are exported

This is the list of Public and Private functions:
```
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Add-LMSystemPrompt                                 0.0        LMStudio-Client
Function        Confirm-LMGlobalVariables                          0.0        LMStudio-Client
Function        Confirm-LMYesNo                                    0.0        LMStudio-Client
Function        Convert-LMDialogToBody                             0.0        LMStudio-Client
Function        Convert-LMDialogToHistoryEntry                     0.0        LMStudio-Client
Function        Get-LMGreeting                                     0.0        LMStudio-Client
Function        Get-LMModel                                        0.0        LMStudio-Client
Function        Get-LMResponse                                     0.0        LMStudio-Client
Function        Import-LMConfig                                    0.0        LMStudio-Client
Function        Import-LMDialogFile                                0.0        LMStudio-Client
Function        Import-LMHistoryFile                               0.0        LMStudio-Client
Function        Invoke-LMBlob                                      0.0        LMStudio-Client
Function        Invoke-LMOpenFolderUI                              0.0        LMStudio-Client
Function        Invoke-LMSaveOrOpenUI                              0.0        LMStudio-Client
Function        Invoke-LMStream                                    0.0        LMStudio-Client
Function        New-LMConfig                                       0.0        LMStudio-Client
Function        New-LMGreetingPrompt                               0.0        LMStudio-Client
Function        New-LMTemplate                                     0.0        LMStudio-Client
Function        Remove-LMHistoryEntry                              0.0        LMStudio-Client
Function        Remove-LMSystemPrompt                              0.0        LMStudio-Client
Function        Repair-LMHistoryFile                               0.0        LMStudio-Client
Function        Search-LMChatDialog                                0.0        LMStudio-Client
Function        Select-LMHistoryEntry                              0.0        LMStudio-Client
Function        Select-LMSystemPrompt                              0.0        LMStudio-Client
Function        Set-LMCLIOption                                    0.0        LMStudio-Client
Function        Set-LMConfigOptions                                0.0        LMStudio-Client
Function        Set-LMTags                                         0.0        LMStudio-Client
Function        Set-LMTitle                                        0.0        LMStudio-Client
Function        Show-LMDialog                                      0.0        LMStudio-Client
Function        Show-LMSettings                                    0.0        LMStudio-Client
Function        Start-LMChat                                       0.0        LMStudio-Client

```

## Autoload Config and Expose All Functions
To expose *all* functions on import, and attempt to auto-load the Config:

```
Import-Module LMStudio-Client -ArgumentList "ExportAll","Auto"
```

* "Public" and "Private" functions are exported
* Module attempts to load *$($env:USERPROFILE)\Documents\LMStudio-PSClient\lmsc.cfg*
