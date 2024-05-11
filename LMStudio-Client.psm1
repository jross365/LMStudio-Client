#This function prompts for server name and port:
    # it prompts to create a new history file, or to load an existing one. 
    # If loading an existing one, it needs to verify it.
function Create-LMConfigFile {
    #Structure: 
    $T = [pscustomobject]@{"Server" = "localhost"; "Port" = 1234; "HistoryFile" = "C:\Users\jason\Documents\WindowsPowershell\LMStudio-Client\LMHistory.index"}
}

#This function reads the local LMConfigFile.json, verifies it (unless skipped), and then writes the values to the $Global:LMStudioVars
function Import-LMConfigFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$ConfigFile = "$($Env:USERPROFILE)\Documents\WindowsPowerShell\Modules\LMStudio-Client\lmcfg.json",
        [Parameter(Mandatory=$false)][switch]$SkipVerification
    )
begin {
    
    try {$ConfigData = Get-Content $ConfigFile -ErrorAction Stop | ConvertFrom-Json -Depth 2 -ErrorAction Stop}
    catch {throw $_.Exception.Message}

    #region Verify config file properties
    [System.Collections.ArrayList]$Properties = "Server", "Port", "HistoryFilePath"

    $ConfigData.psobject.Properties.Name | Foreach-Object {

        If ($_ -ieq "Server" -or $_ -ieq "Port" -or $_ -ieq "HistoryFile"){$Properties.Remove($_) | Out-Null}
    }

    If ($Properties.Count -ne 0){throw "Config file missing property $($Propoerties -join ',') ($ConfigFile)"}
    #endregion

    #region Verify property values are valid
    $PropertyErrors = 0

    If ($ConfigData.Server.Length -eq 0 -or $null -eq $ConfigData.Server){Write-Error "'Server' property is empty."; $PropertyErrors++}
    If ($ConfigData.Port.Length -eq 0 -or $null -eq $ConfigData.Port){Write-Error "'Port' property is empty."; $PropertyErrors++}

    try {$PortAsInt = [int]$ConfigData.Port}
    catch {Write-Error "Property 'Port' is not an integer '($($ConfigData.Port))'"$PropertyErrors++}

    If ($PortAsInt -lt 0 -or $PortAsInt -gt 65535){Write-Error "Property 'Port' is not a value between 0 and 65535 ($PortAsInt)"}

    If ($ErrorActionPreference -eq 'SilentlyContinue'){Write-Host "Errors:" -ForegroundColor red; $Error[0..$PropertyErrors].Exception.Message}

    If ($PropertyErrors -gt 0){throw 'Errors with the Config File were encountered. Please run the Create-ConfigFile cmdlet'}
    #endregion

    #region Confirm parameters are acceptable types:
    $PropertyErrors = 0

    If ($ConfigData.Server.Length -eq 0 -or $null -eq $ConfigData.Server){Write-Error "'Server' property is empty."; $PropertyErrors++}
    If ($ConfigData.Port.Length -eq 0 -or $null -eq $ConfigData.Port){Write-Error "'Port' property is empty."; $PropertyErrors++}

    try {$PortAsInt = [int]$ConfigData.Port}
    catch {Write-Error "Property 'Port' is not an integer '($($ConfigData.Port))'"$PropertyErrors++}

    If ($PortAsInt -lt 0 -or $PortAsInt -gt 65535){Write-Error "Property 'Port' is not a value between 0 and 65535 ($PortAsInt)"}

    If ($ErrorActionPreference -eq 'SilentlyContinue'){Write-Host "Errors:" -ForegroundColor red; $Error[0..$PropertyErrors].Exception.Message}

    If ($PropertyErrors -gt 0){throw 'Errors with the Config File were encountered. Please run the Create-ConfigFile cmdlet'}
    #endregion

}
process {

    if (!$SkipVerification){

        try {$ModelRetrieval = Get-LMModel -Server $ConfigData.Server -Port $ConfigData.Port -AsTest}
        catch {throw $_.Exception.Message}

        If ($ModelRetrieval -eq $False){throw "Unable to connect to server $($ConfigData.Server) on port $($ConfigData.Port). This could be a server issue (Web server started?)"}

        If (Test-Path $ConfigFile.HistoryFilePath){throw $_.Exception.Message}

        try {$CheckHistoryFile = Get-LMHistoryFile -FilePath} ###LEFT OFF HERE, NEED TO GIVE GET-LMHISTORYFILE PARAMETERS
        catch {}

    }

}
end {}
}


#This function builds the hierarchy of hash tables at $Global:LMstudiovars to store configuration information (server, port, history file)
function Initialize-LMVarStore {
    $Global:LMStudioVars = @{}
    $Global:LMStudioVars.Add("ServerInfo",@{})
    $Global:LMStudioVars.ServerInfo.Add("Server","")
    $Global:LMStudioVars.ServerInfo.Add("Port","")
    $Global:LMStudioVars.Add("HistoryFilePath","")

}

#This function sets the Global variables for Server and Port
function Set-LMGlobalVariables ([string]$Server,[int]$Port, [string]$HistoryFile, [switch]$Show){
    If ($Port.Length -eq 0 -or ($Port -lt 0 -or $Port -gt 65535)){throw "$Port must be in a range of 0-65535"}
    If (($Server.Length -eq 0 -or $null -eq $Server) -and $Port.Length -gt 0){throw "Please provide a name or IP address for parameter -Server"}

    If ($Server.Length -ne 0 -and $Port.Length -ne 0){

        try {$Global:LMStudioVars.ServerInfo.Server = $Server}
        catch {throw "Unable to set Global variable LMStudioServer for value Server: $Server"}
        
        try {$Global:LMStudioVars.ServerInfo.Port = $Port}
        catch {throw "Unable to set Global variable LMStudioServer for value Port: $Port"}

    }

    If ($Show.IsPresent){$Global:LMStudioVars}

}

#This function validates $Global:LMStudioVars is fully populated
function Confirm-LMGlobalVariables {

    If ($null -eq $Global:LMStudioVars){throw "Please run Set-LMStudioServer first."}
    
    If ($Global:LMStudioVars.Server.Length -eq 0 -or $null -eq $Global:LMStudioVars.Server){

        If ($Global:LMStudioVars.Port.Length -eq 0 -or $null -eq $Global:LMStudioVars.Port){

            throw "Server and Port are not valid, please run Set-LMSGlobalVariables"

        }

    }
    
    If ($Global:LMStudioVars.Port.Length -eq 0 -or $null -eq $Global:LMStudioVars.Port){

        throw "Port is not valid, please run Set-LMSGlobalVariables again"

    }

    return $True    

}


# This function "Carves The Way" to the path where the history file should be saved. 
# It verifies the path validity and tries to create the path, if specified
# Used by the Create-HistoryFile (I think)

function Set-LMHistoryPath ([string]$HistoryFile,[switch]$CreatePath){
    If ($HistoryFile.Length -eq 0 -or $null -eq $HistoryFile){throw "Please enter a valid path to the history file"}

    $HistFileDirs = $HistoryFile -split '\\'

    $HistFileDirs = $HistFileDirs[0..($HistFileDirs.GetUpperBound(0) -1)]

    switch (Test-Path "$($HistFileDirs -join '\')"){

        $True {if ($CreatePath.IsPresent){Write-Verbose "Folder paths exists, path creation not necessary :-) " -Verbose}}

        $False {

            if ($CreatePath.IsPresent){

                (0..($HistFileDirs.GetUpperBound(0))).ForEach({

                    $Index = $_
        
                    if ($Index -eq 0){
        
                        $Drive = $HistFileDirs[$Index]
        
                        try {&$Drive}
                        catch {throw "Drive $Drive is not valid or accessible. Cannot create path :-( "}
        
                    }
                    else {
                        $ThisFolder = $HistFileDirs[0..$Index] -join '\'
                        
                        try {$F = New-Item -Path $ThisFolder -ItemType Directory -Confirm:$false -ErrorAction Stop}
                        catch {throw "Unable to create $ThisFolder : $($_.Exception.Message)"}

                    }           
        
                })

            }
            else {throw "Provided directory path does not exist. Try using the -CreatePath parameter to create it :-) "}

        }

    }

    $FolderPath = (0..($HistFileDirs.GetUpperBound(0))) -join '\'

    try {$Global:LMStudioVars.HistoryFilePath = $FolderPath}
    catch {throw "Unable to set HistoryFilePath. Run Initialize-LMVarStore to create it."}

    if ($null -eq $Global:LMStudioVars.HistoryFilePath -or $Global:LMStudioVars.HistoryFilePath.Length -eq 0){throw "HistoryFilePath is empty. Please Run Initialize-LMVarStore to fix it."}
}


#This function generates and returns an empty history file template with dummy entries (doesn't save)
function New-HistoryFileTemplate {
    try {

        $History = New-Object System.Collections.ArrayList

        $Greetings = New-Object System.Collections.ArrayList
        (0..1).ForEach({$Greetings.Add(([pscustomobject]@{"role" = "dummy"; "content" = "This is a dummy entry."})) | Out-Null})

        $DummyContent = New-Object System.Collections.ArrayList
        (0..1).ForEach({$DummyContent.Add(([pscustomobject]@{"timestamp" = $((Get-Date).ToString()); "role" = "dummy"; "content" = "This is a dummy entry."})) | Out-Null})

        $DummyEntry = [pscustomobject]@{"StartDate" = "$((Get-Date).ToString())"; "Opener" = "This is a dummy entry."; "Content" = $DummyContent}

        $Histories = New-Object System.Collections.ArrayList
        $Histories.Add($DummyEntry) | Out-Null

        $Models = @{}
        (0..1).ForEach({$Models.Add("$_","dummymodel")})

        $History.Add([pscustomobject]@{"Models" = $Models; "Greetings" = $Greetings; "Histories" = $Histories}) | Out-Null
    }
    catch{throw "Unable to create history file $HistoryFile : $($_.Exception.Message))"}

return $History       

}


#This function imports the content of an existing history file
function Import-LMHistoryFile {
    ##NEED TO PUT PARAMETERS IN HERE


    #Check the Global Variable Store for the value
    try {$HistoryFileCheck = Confirm-LMHistoryVariables}
    catch {throw $_.Exception.Message}

    If ($HistoryFileCheck -ne $True){throw "Something went wrong when running Confirm-LMHistoryVariables (didn't return True)"}
   
    $HistoryFile = $Global:LMStudioVars.HistoryFilePath
   
    #Import the original History file
    try {$HistoryContent = Get-Content $HistoryFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
    catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message))"}

    If ($HistoryContent.Histories[0].Opener -ne "This is a dummy entry."){throw "History file $HistoryFile is missing the history dummy entry (bad format)"}
    If ($HistoryContent.Greetings[0].role -ne "dummy"){throw "History file $HistoryFile is missing the greeting dummy entry (bad format)"}
    If ($HistoryContent.Models.0 -ne "dummymodel"){throw "History file $HistoryFile is missing the models dummy entry (bad format)"}

    #move over content from Fixed-Length arrays to New ArrayLists:
    $NewHistory = New-HistoryFileTemplate

    #.Where({$_.Role -ne "dummy"}) removed:
    $HistoryContent.Greetings | ForEach-Object {$NewHistory.Greetings.Add($_) | Out-Null}

    $NewHistory.Histories.Remove($NewHistory.Histories[0]) | Out-Null

    $HistoryContent.Histories.Foreach({
    
        $Entry = $_
        $Content = New-Object System.Collections.ArrayList
        $Entry.Content | ForEach-Object {$Content.Add($_) | out-null}
        
        $EntryCopy = [pscustomobject]@{"Date" = $Entry.Date; "Opener" = $Entry.Opener; "Content" = $Content}

        $NewHistory.Histories.Add($EntryCopy) | Out-Null

    })

    #move over models from PSCustomObject to HashTable
    $NewHistory.Models = @{}
    $History.Models.psobject.Properties.Name.ForEach({$NewHistory.Models.Add("$_","$($H.Models.$_)")})

    Remove-Variable HistoryContent -ErrorAction SilentlyContinue

    return $NewHistory

} #Close Function

#This function saves a history stored in a variable to the history file
function Save-LMHistoryFile ($History){

    #Check the Global Variable Store for the value
    try {$HistoryFileCheck = Confirm-LMHistoryVariables}
    catch {throw $_.Exception.Message}

    If ($HistoryFileCheck -ne $True){throw "Something went wrong when running Confirm-LMHistoryVariables (didn't return True)"}

    $HistoryFile = $Global:LMStudioVars.HistoryFilePath

    try {$History | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $HistoryFile -ErrorAction Stop}
    catch {throw "Unable to save history to `$HistoryFile; $($_.Exception.Message)"}

    return $True

}

#This function retrieves the model information from the server.
#It can also be used as a connection test with the -AsTest parameter
function Get-LMModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$Server = "localhost",
        [Parameter(Mandatory=$false)][int]$Port,
        [Parameter(Mandatory=$false)][switch]$AsTest

    )

    If (($null -eq $Server -or $Server.Length -eq 0) -or ($null -eq $Port -or $Port.Length -eq 0)){

        try {$HistoryFileCheck = Confirm-LMHistoryVariables}
        catch {
                throw "Required variables (Server, Port) are missing, and `$Global:LMStudioVars is not populated. Please run Set-LMGlobalVariables or Import-LMConfigFile"
    
            }


    }
    #region Check LMStudioServer values
       
    [string]$EndPoint = $Server + ":" + $Port
    $ModelURI = "http://$EndPoint/v1/models"
    
    try {

        $ModelData = Invoke-RestMethod -Uri $ModelURI -ErrorAction Stop
        $TestResult = $True

    }
    catch {
        
        If ($AsTest.IsPresent){$TestResult = $False}
        Else {throw "Unable to retrieve model information: $($_.Exception.Message)"}
    
    }

    $Model = $ModelData.data.id

    If ($Model.Length -eq 0 -or $null -eq $Model.Length){throw "`$Model.data.id is empty."}

    switch ($AsTest.IsPresent){

        $True {return $TestResult}

        $False {return $Model}

    }

}

#This function Adds a model to the History stored in memory, and saves the file (if switch is specified)
#THIS FUNCTION IS PROBABLY NOT NECESSARY, SHOULD SAVE MODEL INFO TO GREETING AND DIALOG FILES, RESPECTIVELY
function Add-LMModelToHistory ([pscustomobject]$History, [string]$Model, [switch]$Save){

    $Model = $ModelData.data.id

    If (($History.Models.GetEnumerator() | ForEach-Object {$_.Value}) -notcontains "$Model"){

        $ModelAdded = $False
        $ModelIndex = 2

        do {
            try {
                $History.Models.Add("$ModelIndex",$Model)
                $ModelAdded = $True
            }
           catch {$ModelIndex++; $ModelAdded = $False}

        }
        until ($ModelAdded -eq $True)
        
        Save-LMHistoryFile -LMHistoryFile $HistoryFile -LMHistory $History

    } #Close If
    Else {$ModelIndex = ($History.Models.GetEnumerator() | Where-Object {$_.Value -eq "$Model"}).Name}



}

#This function imports the greetings from the greeting file (used for setting greeting context)
function Import-LMGreetingDialog {
}

#This function saves a greeting to the greeting file (if the switch is specified)
function Save-LMGreetingDialog {
}

#This function imports a chat dialog from a dialog file (used for "continuing a conversation")
function Import-LMChatDialog (){
    #Need to figure out a way to index this
}

#This function saves a chat dialog to a dialog file, and updates the history file
function Save-LMChatDialog {[switch]$SkipHistoryAddition}

#Searches the HistoryFile for strings and provides multiple ways to output the contents
function Search-LMFileHistory {

    #Params: 
     #History File (not mandatory, defaults to Global:LMstudiovars)
     #Before: Integer, dialogs (line pairs) to capture before each word or phrase-line
     #After: Integer, dialogs (line pairs) to capture after each word or phrase-line
     #Potential parameter: "MarkWord" - console (and textual symbol) indicators to show the word's use
     #ResultSetSize: Integer, how many results to show in each "set" (press enter to continue)
     #SaveTo: File location to save the output
     #ReturnResults - return the results (as an array?)
    #


}

#Provides a graphical help interface for the LM-Client
function Show-LMHelp {
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = “LMStudio-Client Help”
    $Messageboxbody = “!h - Displays this help`r`n!s - Change the system prompt`r`n!t - Change the temperature`r`n!f - Change the history file`r`n!q - Save and Quit”
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

}

#This function generates a greeting prompt for an LLM, for load in the LMChatClient
function New-GreetingPrompt {
    
    ###FEATURE TO INCLUDE HERE: RETURN A SYSTEM PROMPT

    $TodayIsADay = "It is $((Get-Date).DayOfWeek)"
    
    $TokenSet = @{U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'}
        
    $ThreeLetters = (Get-Random -Count 3 -InputObject $TokenSet.U -SetSeed ([System.Environment]::TickCount)) -join ', '

    $Greetings = @(
        "$TodayIsADay. Chose an adjective that contains these three letters: $ThreeLetters. Then use it to insult me in a short way without hurting my feelings too much.",
        "$TodayIsADay. Please greet me in a unique and fun way!",
        "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Then provide a fact about the chosen proper noun.",
        "$TodayIsADay. Please try to baffle me.",
        "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Then generate a haiku that includes this word.",
        "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Please generate a short poem about this word."
        "$TodayisADay. Please wish me well for today."
    )
    
    $ChosenGreeting = $Greetings[$(Get-Random -Minimum 0 -Maximum $($Greetings.GetUpperBound(0)) -SetSeed ([System.Environment]::TickCount))]

    return $ChosenGreeting

} #Close Function


#This function establishes an asynchronous connection to "stream" the chat output to the console
function Invoke-LMStream{
    [CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$CompletionURI,
    [Parameter(Mandatory=$true)][pscustomobject]$Body,
    [Parameter(Mandatory=$true)][string]$File,
    [Parameter(Mandatory=$false)][switch]$KeepJob,
    [Parameter(Mandatory=$false)][switch]$KeepFile
    )

    begin {

        #region Define Jobs

    $StreamJob = { #This job is a ludicrously primitive way to introduce asynchronicity into a stubbornly synchronous language
    
    $CompletionURI = $args[0]
    $Body = $args[1]    
    $File = $args[2]
    
$PostForStream = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace LMStudio
{
    public class WebRequestHandler : IDisposable
    {
        private CancellationTokenSource _cancellationTokenSource;

        public CancellationTokenSource CancellationTokenSource
        {
            get { return _cancellationTokenSource; }
            private set { _cancellationTokenSource = value; }
        }

        public WebRequestHandler()
        {
            CancellationTokenSource = new CancellationTokenSource();
        }

        public async Task PostAndStreamResponse(string url, string requestBody, string outputPath)
        {
            try
            {
                // Register SIGINT and SIGTERM handlers
                Console.CancelKeyPress += (_, e) =>
                {
                    e.Cancel = true;
                    Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    Cancel();
                };

                // Create a HTTP request
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "POST";
                request.ContentType = "application/json";

                // Write each line of request body
                using (StreamWriter streamWriter = new StreamWriter(request.GetRequestStream()))
                {
                    string[] lines = requestBody.Split(new[] { Environment.NewLine }, StringSplitOptions.None);
                    foreach (string line in lines)
                    {
                        await streamWriter.WriteLineAsync(line);
                        if (line == "data: [DONE]")
                        {
                            Cancel();
                            return;
                        }
                    }
                }

                // Get response
                using (HttpWebResponse response = (HttpWebResponse)await request.GetResponseAsync())
                using (Stream responseStream = response.GetResponseStream())
                using (StreamWriter fileWriter = new StreamWriter(outputPath, append: true))
                using (StreamReader reader = new StreamReader(responseStream))
                {
                    // Read response line by line and write to file
                    string line;
                    while ((line = await reader.ReadLineAsync()) != null)
                    {
                        if (CancellationTokenSource.IsCancellationRequested)
                        {
                            await fileWriter.WriteLineAsync("STOP!?! Cancel Detected");
                            return;
                        }

                        await fileWriter.WriteLineAsync(line);
                    }
                }
            }
            catch (OperationCanceledException)
            {
                // Clean up resources
                Console.WriteLine("Operation canceled. Closing connection...");
            }
            catch (Exception ex)
            {
                File.AppendAllText(outputPath,"ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
                throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Cancel()
        {
            CancellationTokenSource.Cancel();
        }

        public void Dispose()
        {
            CancellationTokenSource.Dispose();
        }
    }
}

"@   

    Add-Type -TypeDefinition $PostForStream
    
    Remove-Item $File -ErrorAction SilentlyContinue

    try {"" | out-file $File -Encoding utf8 -ErrorAction Stop}
    catch {throw "Unable to create file $File"}
  
    $StreamSession = New-Object LMStudio.WebRequestHandler

    try {$jobOutput = $StreamSession.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "$File")}
    catch {throw $_.Exception.Message}

     try {Get-Content $File -Tail 10 -Wait}
    catch {return "HALT: ERROR File is not readable"}
 
    $JobOutput.Close()
    $jobOutput.Dispose()
      
    } #Close $StreamJob

    $KillProcedure = {
            
        if (!($KeepJob.IsPresent)){Stop-Job -Id ($RunningJob.id) -ErrorAction SilentlyContinue; Remove-job -Id ($RunningJob.Id) -ErrorAction SilentlyContinue}
        If (!($KeepFile.IsPresent)){Remove-Item $File -Force -ErrorAction SilentlyContinue}

    }
    
    #Send the right parameters to let the old C# code run:
    $PSVersion = "$($PSVersionTable.PSVersion.Major)" + '.' + "$($PSVersionTable.PSVersion.Minor)"

    if ($PSVersion -match "5.1"){$RunningJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)}
    elseif ($PSVersion -match "7.") {$RunningJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File) -PSVersion 5.1}
    else {throw "PSVersion $PSVersion doesn't match 5.1 or 7.x"}

    #To store our return output
    $MessageBuffer = ""
        
}
process {

    $Complete = $False
    $Interrupted = $False

    do {

        #Intercept Escape
        If ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
            If ([Int]$Key.Character -eq 27) {
        
                Write-Host ""; Write-Warning "Escape character detected, this party is over"
                &$KillProcedure
                $Interrupted = $True

            }

        }

        If ($Interrupted){break}
    
        $jobOutput = Receive-Job $RunningJob #| Where-Object {$_ -match 'data:' -or $_ -match '|ERROR!?!'} #Need to move this into :oloop 
    
        :oloop foreach ($Line in $jobOutput){

            If ($Line.Length -eq 0){continue oloop}

            if ($Line -cmatch 'ERROR!?!|"STOP!?! Cancel Detected' ){
            
                &$KillProcedure
                throw "Exception: $($Line -replace 'ERROR!?!' -replace '"STOP!?! Cancel Detected')"
                $Complete = $True

            }
            elseif ($Line -match "data: [DONE]"){
                $Complete = $True
                break oloop
            }
            elseif ($Line -notmatch "data: "){continue oloop}
            else {
    
                $LineAsObj = $Line.TrimStart("data: ") | ConvertFrom-Json
                
                If ($LineAsObj.id.Length -eq 0){continue oloop}
    
                $Word = $LineAsObj.choices.delta.content
                Write-Host "$Word" -NoNewline
                $MessageBuffer += $Word
            
                If ($null -ne $LineAsObj.choices.finish_reason){
                    Write-Host ""
                    #Write-Verbose "Finish reason: $($LineAsObj.choices.finish_reason)" -Verbose
                    $Complete = $True
                    break oloop
                }
    
            }
    
        }
    
    }
    until ($Complete -eq $True)

} #Close Process

end {

    If (!($Interrupted)){
        
        &$KillProcedure
        return $MessageBuffer}

    Write-Host ""

} #Close End

} #Close function

#This function is the LM Studio Client
function Start-LMStudioClient {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$false)][ValidateRange(0, 65535)][int]$Port = 1234,
        [Parameter(Mandatory=$false)][string]$HistoryFile = $Global:LMStudioVars.HistoryFilePath,
        [Parameter(Mandatory=$false)][double]$Temperature = 0.7,
        [Parameter(Mandatory=$false)][switch]$SkipGreeting,
        [Parameter(Mandatory=$false)][switch]$StreamResponses
        #[Parameter(Mandatory=$false)][switch]$NoTimestamps, #Not sure what to do with this, or where to hide the timestamps
        )
    
    begin {
    
        
        #region Prerequisite Variables
        $OrigProgPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $ReplayLimit = 10 #Sets the max number of assistant/user content context entries    
    
        $Version = "0.5"
    
        
        $CompletionURI = "http://$EndPoint/v1/chat/completions"
    
        $host.UI.RawUI.WindowTitle = "LM Studio Client v$Version ### Show Help: !h "
    
        $SystemPrompt = "Please be polite, concise and informative."
        #endregion
    
        #region Define the BODY Template
        $BodyTemplate = '{ 
            "model": "MODELHERE",
            "messages": [ 
              { "role": "system", "content": "SYSPROMPTHERE" },
              { "role": "user", "content": "USERPROMPTHERE" }
            ], 
            "temperature": 0.7, 
            "max_tokens": -1,
            "stream": false
        }'
    
        #endregion
    
        #region Try to Load or Create a history
    #Need to check if this is still valid:
        If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$HistoryFile = "$env:USERPROFILE\Documents\ai_history.json"}
    
        If (!(Test-Path $HistoryFile)){ #Build a dummy history file
    
            try {
    
                $History = New-HistoryObject
                Set-HistoryFile -HistoryFile $HistoryFile -History $History
    
            }
            catch{throw "Unable to create history file $HistoryFile : $($_.Exception.Message))"}
    
        }
        Else {
    
            try {$History = Get-HistoryFile -HistoryFile $HistoryFile}
            catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message)"}
    
        }
        #endregion
    
        #region Connection Test, and Model Name Retrieval, Add model to History
        try {$Model = Get-LMModel -Server $Server -Port $Port}
        catch {throw "Unable to retrieve model information. Check to see if the server is up."}
    
        $Model = $ModelData.data.id
    
        If (($History.Models.GetEnumerator() | ForEach-Object {$_.Value}) -notcontains "$Model"){
    
            $ModelAdded = $False
            $ModelIndex = 2
    
            do {
                try {
                    $History.Models.Add("$ModelIndex",$Model)
                    $ModelAdded = $True
                }
               catch {$ModelIndex++; $ModelAdded = $False}
    
            }
            until ($ModelAdded -eq $True)
            
            Set-HistoryFile -HistoryFile $HistoryFile -History $History
    
        } #Close If
        Else {$ModelIndex = ($History.Models.GetEnumerator() | Where-Object {$_.Value -eq "$Model"}).Name}
    
        #endregion
        
        If (!$SkipGreeting){
            $NewGreeting = New-GreetingPrompt
            
            #region Walk backwards through the $History.Greetings index to create a correct context replay:
            $ContextReplays = New-Object System.Collections.ArrayList
            
            $x = 1
            $LastGreetingIndex = $History.Greetings.Count - 1
            $SysPromptChainBroken = $False
            
            :iloop Foreach ($Index in $LastGreetingIndex..2){
    
                If ($Index -eq $LastGreetingIndex -and (($History.Greetings[$Index].role -eq "system") -or ($History.Greetings[$Index].role -eq "user"))){continue iloop}
    
                If ($History.Greetings[$Index].role -eq "system" -and $SysPromptChainBroken -eq $False){
                    
                    If ($History.Greetings[$Index].content -ieq "$SystemPrompt"){continue iloop}
                    Else {
                            $ContextReplays.Add(($History.Greetings[$Index])) | Out-Null
                            $SysPromptChainBroken = $True
                            $x++
                        }
                }
    
                If ($History.Greetings[$Index].role -eq "assistant" -or $History.Greetings[$Index].role -eq "user"){
                    $ContextReplays.Add(($History.Greetings[$Index])) | Out-Null
                    $x++
                }
    
                If ($x -eq ($ReplayLimit)){break iloop}
    
            }
            #endregion
    
            #region Fill in the Model, System Prompt and User Prompt of the $Body:
            $Body = $BodyTemplate | ConvertFrom-Json
            $Body.model = $Model
            #$Body.stream = $True #For testing
    
            $Body.messages = @()
            $SystemPromptObj = ([pscustomobject]@{"role" = "system"; "content" = $SystemPrompt})
            $UserPromptObj = ([pscustomobject]@{"role" = "user"; "content" = $NewGreeting})
    
            # Add a "system" role to the top to set the interpretation:
            If ($ContextReplays.role -notcontains "system"){$body.messages += ([pscustomobject]@{"role" = "system"; "content" = $SystemPrompt})}
            # Replay the relevant/captured interactions back into $Body.messages:
            $ContextReplays[($ContextReplays.Count - 1)..0].ForEach({$Body.messages += $_})
            # If we detected a broken system prompt chain, add the current system prompt back in:
            If ($SysPromptChainBroken){$body.messages += ([pscustomobject]@{"role" = "system"; "content" = $SystemPrompt})}
            # Finally, add our new greeting prompt back in:
            $body.messages += $UserPromptObj
                
            #Add the messages to the history, and save the history:
            $History.Greetings.Add($SystemPromptObj) | Out-Null
            $History.Greetings.Add($UserPromptObj) | Out-Null
            $SaveHistory = Set-HistoryFile -HistoryFile $HistoryFile -History $History
            #endregion
    
            #region Write the generated greeting to the console
            Write-Host "You: " -ForegroundColor Green -NoNewline; Write-Host "$NewGreeting"
            Write-Host " "
            #endregion
    
            #region Prompt for and receiving greeting
            $GreetingParams = @{
                "Uri" = "$CompletionURI"
                "Method" = "POST"
                "Body" = ($Body | ConvertTo-Json -Depth 3)
                "ContentType" = "application/json"
            }
    
            try {$Response = Invoke-RestMethod @GreetingParams -UseBasicParsing -ErrorAction Stop}
            catch {$_.Exception.Message}
    
            $ResponseText = $Response.choices.message.content
            #endregion
    
            #region Response and file management
            Write-Host "AI: " -ForegroundColor DarkMagenta -NoNewline; Write-Host "$ResponseText"
    
            $History.Greetings += ([pscustomobject]@{"role" = "assistant"; "content" = "$ResponseText"})
            $SaveHistory = Set-HistoryFile -HistoryFile $HistoryFile -History $History
            #endregion
    
        } #Close If $SkipGreeting isn't Present
    
        #endregion
    
    }
    
    process {
    
        $Quit = $false
    
        do {
    
            write-host "You: " -ForegroundColor Green -NoNewline; $UserPrompt = Read-Host
    
            $Body = $BodyTemplate
            $Body = $Body -replace 'MODELHERE',"$Model"
            $Body = $Body -replace 'SYSPROMPTHERE',"$SystemPrompt"
            $Body = $Body -replace 'USERPROMPTHERE',"$UserPrompt"
    
            
            $Response = Invoke-RestMethod -Uri $CompletionURI -Method POST -Body $Body -WebSession $R2D2 -ContentType "Application/json"
    
            $Response.choices.message.content
    
        }
        until ($Quit -eq $true)
    
    
    }
    
    end {
        $ProgressPreference = $OrigProgPref
    
    
    }
    
    }
    