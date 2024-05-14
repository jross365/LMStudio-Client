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

05/11 - Finished Import-LMConfigFile, which wasn't an easy step: input validation and caution is important here, because cleaning up mistakes is a hassle when files and folders are created all over the place.

Also touched up a few other functions. I added two new fields to the history file: "Title", and "Tags". It'll make human consumption easier, and make the data easier to search.

I have many of the important pieces together now. I REALLY want to build a functioning client, but it's very important I have the data and file structures right from the start. It's much easier to do right the first time than to have to fix.

[FileInfo] is a really neat class. It's very useful for getting name and paath information from a hypothetical file or folder.

Next up:

* Update Show-LMHelp to include changing the Title/Tags, Change the context message count, Save (without qutting)
* Make an official list of functions, and their purpose
* Update the Client to use the complete functions I have (should shorten the code substantially)
* Review this, and likely simplify/replace it (Client):`

#Need to check if this is still valid:
        If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$Hist...

05/12 - Doing documentation, clean-up and identifying missing functions today. Might break the functions out into Public/Private.

Some Ideas:

    * I can separate out Public and Private functions, and provide a Module Parameter to expose all functions (for an advanced user):
        * https://stackoverflow.com/questions/36897511/powershell-module-pass-a-parameter-while-importing-module

    * I can combine all of my object (template) creations into a single function (simplification)
        * Should include the HTTP $Body in this
    * I can add parameters to Show-LMHelp to give details for each parameter
    * I can build out the "Greeting" functionality as a standalone function
        * Would move a lot of the Start-LMStudioClient code out of the main body
        * Create a standalone "greeting" client
    
    * Need to incorporate other values into the $Global:LMStudioVars and Config File:
        * Subtree "Settings" (To be changed manually):
            * Temperature = 0.7 (default)
            * Context = 10 (default)
            * Stream = $True (default)
            * StreamCacheFile = $env:userprofile\Documents\lmstream.cache (default)

    * Markdown compatibility: If (1) Client is PS7, (2) "Show-Markdown" is an available cmdlet, and (3) a "-Markdown" (or similar) parameter is provided, I can use the Show-Markdown cmdlet to beautify the output
        * The way this would work with "Stream" mode:
            * that a copy of the output would would retained (as per usual:
                 $Output = Invoke-LMStream
            * the screen will be cleared:
                 Clear-Screen
            * The output would be passed:
                Show-Markdown -InputObject $Output

05/12 - Had another thought:
    * I need to convert all "New-LMHistoryFile" calls to the new Template function. 
    * New-LMHistoryFile does nothing but save an arbitrary file, it's a pointless function. I just have to do 
        * [Get a new history entry template] | Convertto-Json -Depth 3 | out-file $somefilepath
    
    I need to do this URGENTLY, because it's one of those small modifications that can create hassle downstream.

    Also, getting rid of an extra function gets rid of the ability and utility to omit "dummy values". For the history file, when I need a template I'll simply re-fill in the dummy fields.

    This also simplifies the way History Files are created and appended to.
        (It also suggests that, since the data is flat, I should be using a CSV!)

05/12 - Finished the New-LMTemplate function; added temperature,max_tokens,stream,ContextDepth to Config file and to global settings incorporation.

TO DO TOMORROW:
    * Move functions over to the New-LMTemplate
    * Remove the old standalone template functions
    * Evaluate whether I can remove functions I've labeled as such
    
05/13 - In moving over functions to use the New-LMTemplate (Which is not done, HistoryFile template has a LOT of hooks), with a sense of doom I realized I absolutely have to get all of the client settings I need into the config management system. If I don't, it'll be a headache to fix later.

I have much of the Config File (object) formatting done. Confirm-LMGlobalVariables needs to be rewritten.

I need to rewrite Import-LMConfigFile to accommodate the new config JSON structure., specifically Lines 261 - 269.
