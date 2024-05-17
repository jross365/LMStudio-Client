**New-LMConfigFile** - Creates a new config file (LMStudio-Client\\lmsc.cfg)  
\* PUBLIC  
\* COMPLETE  
\* Prompt-based  
\* Also creates History file  
\* Also creates Dialog folder  
\* Also can validate Server/Port and file/directory paths  
\* Can import config after completion \[Import-LMConfigFile\]

**Import-LMConfigFile** - Import an existing config file (LMStudio-Client\\lmsc.cfg)  
\* PUBLIC  
\* COMPLETE  
\* Validates contents of lmsc.cfg  
\* Writes values to $Global:LMStudioVars \[Set-LMGlobalVariables\]

**Initialize-LMVarStore** - Creates empty global variable store ($Global:LMStudioVars)  
\* PRIVATE  
\* COMPLETE

**Set-LMGlobalVariables** - Provisions global variable store ($Global:LMStudioVars)  
\* PRIVATE  
\* COMPLETE

**Confirm-LMGlobalVariables** - Validates variable store values are not null ($Global:LMStudioVars)  
\* PRIVATE  
\* COMPLETE

**Set-LMHistoryPath** - Validates the directory path of a proposed history file  
\* PRIVATE  
\* COMPLETE  
\* Also can create the directory path (-CreatePath)

**New-LMHistoryFileTemplate** - Returns an empty, correct history file object  
\* PRIVATE  
\* COMPLETE

**New-LMHistoryFile** - Creates and writes history file out to a provided path.  
\* PRIVATE  
\* COMPLETE  
\* Invokes \[New-LMHistoryFileTemplate\]

**Import-LMHistoryFile** - Reads, validates and returns the contents of a history file.  
\* PRIVATE  
\* COMPLETE  
\* Invokes \[Confirm-LMGlobalVariables\] if no filepath is provided

**Repair-LMHistoryFile** - Reads .dialog files in history folder to rebuild history file.  
\* PUBLIC  
\* NOT STARTED  
\* Invokes \[New-LMHistoryFile\] to create an empty template  
\* Invokes \[Import-LMChatDialog\] to read contents of each file  
\* Invokes \[Update-LMHistoryFile\] to write the parsed values into the history file

**New-LMHistoryEntryTemplate** - Returns an empty, correct history file object  
\* PRIVATE  
\* NOT STARTED

**Update-LMHistoryFile** - Appends an entry to a history file, and saves it.  
\* PRIVATE  
\* Invokes \[Confirm-LMGlobalVariables\] if no filepath is provided  
\* Invokes \[Import-LMHistoryFile\] to read the existing history file

**Get-LMModel** - Queries LMStudio for the current, running model information.  
\* PUBLIC  
\* Invokes \[Confirm-LMGlobalVariables\] if no server/port is provided  
\* Also can be run as a connectivity test (-AsTest)

**New-LMGreetingTemplate** - Returns an empty, correct greeting file object.  
\* PRIVATE  
\* NOT STARTED  
\* Output format: CSV

**Import-LMGreetingDialog** - Reads, validates and returns the contents of a greeting file.  
\* PRIVATE  
\* NOT STARTED  
\* Used for LMClient greeting (setting response context)

**Update-LMGreetingDialog** - Appends a greeting to the greeting file, and saves it.  
\* PRIVATE  
\* NOT STARTED  
\* Used by LMClient greeting (saving LLM response to greeting file)

**New-LMChatDialogTemplate** - Returns an empty, correct chat dialog file object.  
\* PRIVATE  
\* NOT STARTED  
\* Used by LMClient (Creating new chat dialog)

**Import-LMChatDialog** - Reads, validates and returns the contents of an existing chat dialog.  
\* PRIVATE  
\* NOT STARTED  
\* Used for:  
\* Continuing an existing chat dialog (LMClient)  
\* Searching chat dialog files for keywords \[Search-LMChatDialogs\]  
\* Rebuilding history file from a given directory \[Repair-LMHistoryFile\]

**Update-LMChatDialog** - Appends an LM chat to a dialog file, and saves it.  
\* PRIVATE  
\* NOT STARTED  
\* Used by LMClient (To save dialog information)

**Search-LMChatDialog** - Reads, validates and searches a dialog file.  
\* PUBLIC  
\* NOT STARTED  
\* Invokes \[Import-LMChatDialog\] to import/validate  
\* Searches dialog contents  
\* Can search Titles and Tags

**Show-LMHelp** - Displays a message box with a list of command line options  
\* PRIVATE  
\* (IN)COMPLETE  
\* Used by LMClient (:h)  
\* Intend to update with parameters that display specifics for each option

**New-LMGreetingPrompt** - Generates a novel greeting prompt to get a unique, new greeting from LLM  
\* PRIVATE  
\* (IN)COMPLETE  
\* Intend to update with random system prompt selections:  
\* "Talk like a pirate"  
\* "Talk like a valley girl"  
\* "Be irreverent and sarcastic"  
\* etc.

**Invoke-LMBlob** - Sends and receives LMStudio output as "blob" (synchronous)  
\* PRIVATE  
\* NOT STARTED  
\* Function is strictly utilitarian (Strict inputs, no assistance)  
\* Invokes \[Invoke-RestMethod\]

**Invoke-LMStream** - Sends and receives LMStudio output as "streaming" (asynchrnous)  
\* PRIVATE  
\* COMPLETE  
\* Function is strictly utilitarian (Strict inputs, no assistance)  
\* Returns output as a single string after completion  
\* Enables interruption of stream

**Get-LMGreeting** - Initiates a greeting  
\* PUBLIC  
\* NOT STARTED  
\* Can be run "configless" (No history/greeting file handling)  
\* Invokes \[New-LMGreetingPrompt\] to create a random prompt  
\* Invokes \[Import-LMGreetingDialog\] to set greeting chat context  
\* Invokes \[Update-LMGreetingDialog\] to save the LLM respojnse

**Start-LMChat** - Initiates a new chat dialog  
\* PUBLIC  
\* (IN)COMPLETE  
\* Invokes more things than I care to list
