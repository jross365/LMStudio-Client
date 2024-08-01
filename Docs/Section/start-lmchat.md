# Start-LMChat

**Start-LMChat** is an interactive client designed to exchange messages specifically with LM Studio, and its limited-scope API.

The sections below assume prerequisite steps have been completed:

1. The module has been imported.
2. A configuration file has been imported.
3. LMStudio is up and running.

## Start a New Chat
Starting a brand new chat with your LM Studio LLM is easy:

Run the following command to initiate a new chat:

```
Start-LMChat
```

When prompted, enter the desired file name and click **Save**.
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/new-start-lmchat.png)


## Start a Private Chat
**Privacy Mode** is a feature that allows you to initiate a new chat or resume a previous chat without saving a dialog file.

Run the following command to initiate a new private chat:

```
Start-LMChat -PrivacyMode
```

## Resume Previous Chat
To resume your previous chat, simply run the following command:

```
Start-LMChat -Resume
```

You can also resume the previous chat with **Privacy Mode**:
```
Start-LMChat -Resume -PrivacyMode
```
In this instance, the previous chat will be resumed, but no user requests or assistant responses will be saved to the Dialog File.

## Select and Resume Chat
To pick the the previous chat you want to resume, run the following command:

```
Start-LMChat -Resume -FromSelection
```

When prompted, select the dialog you wish to resume, and click **OK**
![](https://raw.githubusercontent.com/jross365/LMStudio-Client/main/Docs/images/resume-start-lmchat-selection.png)

You can also resume the previous chat with **Privacy Mode**:
```
Start-LMChat -Resume -FromSelection -PrivacyMode
```
In this instance, the selected chat will be resumed, but no user requests or assistant responses will be saved to the Dialog File.

## Options and Settings
**Start-LMChat** contains commands that change numerous different settings that effect LLM behavior or the console behavior.

Commands are prefaced with a **:** (*colon*). Some examples:

Enables or disables markdown (displays colors and fonts):
```
:markdown <true|false>
```

Assigns tags to the Dialog:
```
:addtags fish,research,aquarium
```

A full list of commands are in these sections of the document:

[Session Management](https://github.com/jross365/LMStudio-Client/blob/main/Docs/Start-LMChat-Options.md#session-management) - Commands that effect the **Start-LMChat** session

[Server Instructions](https://github.com/jross365/LMStudio-Client/blob/main/Docs/Start-LMChat-Options.md#server-instructions) - Settings that change how the LLM behaves

[Session/Output Settings](https://github.com/jross365/LMStudio-Client/blob/main/Docs/Start-LMChat-Options.md#sessionoutput-settings) - Settings that change **Start-LMChat** session behavior

[Interactivity](https://github.com/jross365/LMStudio-Client/blob/main/Docs/Start-LMChat-Options.md#interactivity) - Settings that change identifying names and labels in the Dialog file; show settings

