# The History File and Dialog Files
This section covers common tasks involving the History File and/or Dialog Files.

The steps below assume the prerequisites have been completed:
- The module has been imported;
- A Config has been imported.

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
The History File is not a repository of unique information: it is constructed entirely from the attributes of your Dialog Files:

- **Created**: Timestamp of when the Dialog File was created
- **Modified**: Timestamp of when the Dialog File was last modified
- **Title**: Title assigned to Dialog File via *Start-LMChat*
- **Opener**: The first user statement in the chat dialog
- **Model**: The last model used in the chat dialog
- **FilePath**: Relative path of the Dialog File
- **Tags**: Tags assigned to Dialog File via *Start-LMChat*

For this reason, there is no harm in a History File being deleted and recreated.

To reconstruct the History File, run the following command:
```
Repair-LMHistoryFile -WriteProgress
```

If you see the following warning, *for example*:
```
PS C:\Windows\System32> Repair-LMHistoryFile -WriteProgress
WARNING: Import succeeded: 58, Import failed: 0, History file update failed: 9
```
It is safe to disregard: the History File updates will fail on 'empty' Dialog Files.

## Remove a Dialog File and History Entry

## Searching Dialog Files

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

## Assign a Title to a Dialog File

## Assign Tags to a Dialog File



```
$R = Import-LMDialogFile -FilePath $(Select-LMHistoryEntry)

```
