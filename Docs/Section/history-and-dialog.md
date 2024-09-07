# The History File and Dialog Files
This section covers common tasks involving the History File and/or Dialog Files.

The steps below assume the prerequisites have been completed:
- The module has been imported;
- A Config has been imported.

## About History and Dialog Files
This section covers information about Dialog and History files

### Dialog Files

Each **Start-LMChat** session produces a **Dialog File** (*excluding when using Privacy Mode*).

Dialog Files are JSON-formatted records of interactions with LM Studio. They contain:
- Timestamped user and assistant interactions
- Creation/Modification timestamps
- Chat settings (temperature, max tokens, model, system prompt)
- User-defined Title and Tags

### The History File

Dialog Files are not user-friendly, and can become numerous. A **History File** is used to make Dialog Files easier to manage.

The History File is **not** a repository of unique information: it is constructed entirely from the attributes of your Dialog Files:

- **Created**: Timestamp of when the Dialog File was created
- **Modified**: Timestamp of when the Dialog File was last modified
- **Title**: Title assigned to Dialog File via *Start-LMChat*
- **Opener**: The first user statement in the chat dialog
- **Model**: The last model used in the chat dialog
- **FilePath**: Relative path of the Dialog File
- **Tags**: Tags assigned to Dialog File via *Start-LMChat*

The History File is used by **Start-LMChat** to select a prompt, and by related functions involving Dialog Files.

## View History File
To view the History File in a graphical interface, run the following command:
```
$DialogFile = Select-LMHistoryEntry
```

To view the history file in the console, you can run this command to view it as a list:
```
$HistoryFile = Import-LMHistoryFile
$HistoryFile | Format-List
```

or to view it in table format:
```
$HistoryFile = Import-LMHistoryFile
$HistoryFile | Format-Table
```

## Repair History File
Because the History File is not a repository of unique information, there is no harm in a History File being deleted and recreated.

To reconstruct the History File, run the following command:
```
Repair-LMHistoryFile -WriteProgress
```

If you see the following warning (*for example:*)
```
PS C:\Windows\System32> Repair-LMHistoryFile -WriteProgress
WARNING: Import succeeded: 58, Import failed: 0, History file update failed: 9
```
You can safely disregard **History File update failed**: the History File updates will fail on 'empty' Dialog Files.

## Remove a Dialog File and History Entry
To delete a single Dialog File and its corresponding History File Entry, run the following command:
```
Remove-LMHistoryEntry -DeleteDialogFiles
```
When prompted, select the Entry you wish to delete. Then click **OK**.

If there is more than one Dialog Entry to delete, run the following command to select multiple entries:
```
Remove-LMHistoryEntry -DeleteDialogFiles -BulkRemoval
```
When prompted, Hold the **[Ctrl]** button and select the Entries you wish to delete. Then click **OK**.

To disable deletion confirmations, use the **-Confirm** parameter:
```
Remove-LMHistoryEntry -DeleteDialogFiles -Confirm $False
```

## Searching Dialog Files
**Search-LMChatDialog** is a very feature-rich function. These are the relevant parameters for most users:

 - **-Match** <Any|All|Exact> : The match condition for the search terms
 - **-SearchTerms** "comma","separated","values" : The terms to search for
 - **-SearchScope** <All|User|Assistant> : The prompts to search within
 - **-BeforeDate** <DateTime> : Search all prompts before this date
 - **-AfterDate** <DateTime> : Search all prompts after this date
 - **-PriorContext** [int] : Include [int] number of user/assistant interactions before a matched prompt
 - **-AfterContext** [int] : Include [int] number of user/assistant interactions after a matched prompt
 - **-ShowAsCapitals** : If specified, all matches will be CAPITALIZED

**Examples**
To search your chat history for every occurrence of the phrase "to be" by an LLM, and display in upper-case:
```
Search-LMChatDialog -Match Exact -SearchTerms "to be" -SearchScope Assistant -ShowAsCapitals
```

To search your chat history for every time you wrote "basketball", "baseball" or "football" in a prompt, and display in upper-case:
```
Search-LMChatDialog -Match Any -SearchTerms "basketball","baseball""football" -SearchScope User -ShowAsCapitals
```

To search your chat history for any occurrence of "alpaca", and include the question and answer before the occurrence:
```
Search-LMChatDialog -Match All -SearchTerms "alpaca" -PriorContext 1
```


## Read a Dialog File
*Note:* The following steps will be simplified and improved with a dedicated function for this purpose.

To select and read a Dialog File, you can run the following command:
```
Show-LMDialog -DialogMessages  (Import-LMDialogFile -FilePath $(Select-LMHistoryEntry)).Messages 
```

To do the same, but show the output in Markdown, you can run the following command:
```
Show-LMDialog -DialogMessages  (Import-LMDialogFile -FilePath $(Select-LMHistoryEntry)).Messages -AsMarkdown
```

To read the last Dialog File that was generated, you can run the following command:
```
Show-LMDialog -DialogMessages  (Import-LMDialogFile -FilePath $Global:LMStudioVars.FilePaths.DialogFilePath).Messages 
```
