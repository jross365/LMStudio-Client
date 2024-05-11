(04/27 - 05/05) - Built prototype, built greeting system, built history file system, began functionalizing
05/06 - Found a way to simulate asynchronous HTTP stream, built a working "streaming" response system; converted over to Powershell 7 standards; began functionalizing the code.
Left off: Moving all inputs for $HistoryFile over to $Global:LMStudioServer.HistoryFilepath, with checks for the path's validity
05/09 - Re-ordered functions according to the dependencies and processes. Built shells for many (but not all) of the functions I'll need to write and incorporate.

* Have decided to "fragment" Dialogs from the History File: 
    * History File will keep an index of Dialog files and some information about them (Date, opening line, model, Dialog (array))
    * Dialogs themselves will be stored as either random or sequentially named files, with the following columns:
        * Index, prompt type [system, assistant, user], body (statement/response)
    * Dialog files will be colocated in a folder next to the history file
    * Dialog files will have a "header" in the JSON that contains same information as is assigned to the History File index

Have decided to "fragment" Greetings from the History File:
    * No greeting information kept in the History File
    * Greeting file will be called "greetings.diasht" and will be kept in the above folder
    * Greeting will keep a "flat" format - Will likely use CSV
        * Will contain simple columns: Index, Date, Model, Prompt Type, Statement/response

I have also built some of the functionality for a "master" configuration file, which will serve the following purpose:
    * Required input will be consumed/validated (server, port, history file):
        * Config file created
    * Config file will be imported:
        * Global Variable Store $Global:LMStudioVars will be provisioned and populated (w/ config file info)
        * Values will all be validated (server, port, history file)
        * History file legibility will be checked (History files won't be validated)
    * From this system, startup will be much easier
        * input server info once, create history file, and everything is saved
        * When module is imported, everything that was predefined will be used to provision the required information (server, port, history file)

A lot has gotten done. There is still a lot to do. I think the first thing I'll do is create a "Lite" client to use in the meantime. Perhaps build in the "SaveAs" for use

05/09 - Started building out Import-LMConfigFile; this required parameterizing Get-LMModel. I need to parameterize Import-LMHistoryFile so I can test it during the Import-LMConfigFile process.

I'll keep working from top to bottom to build out the functions this module needs. NOTE: I also should build a "Start-LMStudioLiteClient" to get a working to play with

05/10 - Finished Import-LMConfigFile, which required parameterizing a whole bunch of functions and fixing various checks/validations. New-LMConfigFile comes next.
    * Create-LMConfigFile will have the following parameters:
        * Server
        * Port
        * HistoryFile
            * Defaults to $Env:UserProfile\Documents\LMStudio-Client\
        * SkipServerValidation (Doesn't check Server/Port)
        * NewHistory 
            * If History file is detected:
                * moves File and its folder to a ".bkp" folder
                * creates a new file/Folder
                * Notifies user
    * Create-LMConfigFile will not have mandatory parameters
        * If any parameters are missing, they'll be prompted for


