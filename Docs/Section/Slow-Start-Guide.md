
# User Guide
Come on in, and make yourself at home!

## LMStudio Configuration


## Config Management
Persistent user settings are recorded and maintained with a JSON-formatted configuration file, typically named **lmsc.cfg**.

The articles below provide instruction for how to create and modify different settings in the Config File.

 [Creating a New Configuration File](./config-management.md#create-a-new-config)

 [Importing a Configuration](./config-management.md#import-an-existing-config)

 [View Config Settings](./config-management.md#view-a-config)

 [Modify Config Settings](./config-management.md#modify-config-settings)

 [List of Config Settings](./config-management.md#list-of-config-settings)

## Start-LMChat
**Start-LMChat** is an interactive, console-based chat client for LM Studio.

The articles below cover different ways to use the chat client.

[Start a New Chat](./start-lmchat.md#start-a-new-chat)

[Start a Private Chat](./start-lmchat.md#start-a-private-chat)

[Resume the Previous Chat](./start-lmchat.md#resume-previous-chat)

[Resume Chat from Selection Prompt](./start-lmchat.md#select-and-resume-chat)

[Options and Settings](./start-lmchat.md#options-and-settings)

## Manage History & Dialog Files
Dialog Files and the History File are important features for this module.

They enable the ability to continue, read or search a previous chat dialog with an LLM.

### Dialog Files

Each **Start-LMChat** session produces a **Dialog File** (*excluding when using Privacy Mode*).

Dialog Files are JSON-formatted records of interactions with LM Studio. They contain:
- Timestamped user and assistant interactions
- Creation/Modification timestamps
- Chat settings (temperature, max tokens, model, system prompt)
- User-defined Title and Tags

### History and Dialog Files

Dialog Files are not user-friendly, and can become numerous. A **History File** is used to make Dialog Files easier to manage.

The History File is an index containing an entry for each Dialog File. It stores identifying information about each Dialog File, such as:
- Creation/Modification timestamps
- The "opener" (first submitted user prompt)
- Title
- Tags
- Relative file path

The History File is used by **Start-LMChat** to select a prompt, and by several other functions.

The articles below detail different actions involving Dialog Files and/or the History File:

🚧 **Below in progress:** (Updated 07/31/2024)
[View History File Contents](./history-and-dialog.md#view-history-file-contents)

[Repair History File](./history-and-dialog.md#repair-history-file)

[Remove a Dialog File and History Entry](./history-and-dialog.md#remove-a-dialog-file-and-history-entry)

[Searching Dialog Files](./history-and-dialog.md#searching-dialog-files)

[Read a Dialog File](./history-and-dialog.md#read-a-dialog-file)

[Assign a Title to a Dialog File](./history-and-dialog.md#assign-a-title-to-a-dialog-file)

[Assign Tags to a Dialog File](./history-and-dialog.md#assign-tags-to-a-dialog-file)


## Other Tools and Utilities

[Retrieve Loaded LMStudio Model]()

[Using the Module Programmatically]()

[The Greeting Toy]()
