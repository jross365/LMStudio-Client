**New-LMConfigFile** - Creates a new config file (LMStudio-Client\lmsc.cfg)
    * PUBLIC
    * COMPLETE
    * Prompt-based
    * Also creates History file
    * Also creates Dialog folder
    * Also can validate Server/Port and file/directory paths
    * Can import config after completion [Import-LMConfigFile]

**Import-LMConfigFile** - Import an existing config file (LMStudio-Client\lmsc.cfg)
    * PUBLIC
    * COMPLETE
    * Validates contents of lmsc.cfg
    * Writes values to $Global:LMStudioVars [Set-LMGlobalVariables]

**Initialize-LMVarStore** - Creates empty global variable store ($Global:LMStudioVars)
    * PRIVATE
    * COMPLETE

**Set-LMGlobalVariables** - Provisions global variable store ($Global:LMStudioVars)
    * PRIVATE
    * COMPLETE

**Confirm-LMGlobalVariables** - Validates variable store values are not null ($Global:LMStudioVars)
    * PRIVATE
    * COMPLETE

**Set-LMHistoryPath** - Validates the directory path of a proposed history file
    * PRIVATE
    * COMPLETE
    * Also can create the directory path (-CreatePath)

**New-LMHistoryFileTemplate** - Returns an empty, correct history file object
    * PRIVATE
    * COMPLETE

**New-LMHistoryFile** - Creates and writes history file out to a provided path.
    * PRIVATE
    * COMPLETE
    * Invokes [New-LMHistoryFileTemplate]

**Import-LMHistoryFile** - Reads, validates and returns the contents of a history file.
    * PRIVATE
    * COMPLETE
    * Invokes [Confirm-LMGlobalVariables] if no filepath is provided

**New-HistoryEntryTemplate** - Returns an empty, correct history file object
    * PRIVATE
    * NOT STARTED

**Update-LMHistoryFile** - Appends an entry to a history file, and saves it.
    * PRIVATE
    * Invokes [Confirm-LMGlobalVariables] if no filepath is provided
    * Invokes [Import-LMHistoryFile] to read the existing history file
    
**Get-LMModel** - Queries LMStudio for the current, running model information.
    * PUBLIC
    * Invokes [Confirm-LMGlobalVariables] if no server/port is provided
    * Also can be run as a connectivity test (-AsTest)

**New-LMGreetingTemplate** - Returns an empty, correct greeting file object.
    * PRIVATE
    * NOT STARTED
    * Output format: CSV

**Import-LMGreetingDialog** - Reads, validates and returns the contents of a greeting file.
    * PRIVATE
    * NOT STARTED
    * Used for LMClient greeting (setting response context)

**Update-LMGreetingDialog** - Appends a greeting to the greeting file, and saves it.
    * PRIVATE
    * NOT STARTED
    * Used by LMClient greeting (saving LLM response to greeting file)

**New-LMChatDialogTemplate** - Returns an empty, correct chat dialog file object.
    * PRIVATE
    * NOT STARTED
    * Used by LMClient (Creating new chat dialog)

**Import-LMChatDialog** - Reads, validates and returns the contents of an existing chat dialog.
    * PRIVATE
    * NOT STARTED
    * Used for:
        * Continuing an existing chat dialog (LMClient)
        * Searching chat dialog files for keywords [Search-LMChatDialogs]
        * Rebuilding history file from a given directory [Repair-LMHistoryFile]




