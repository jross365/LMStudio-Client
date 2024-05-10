
function Initialize-LMVarStore {
    $Global:LMStudioServer = @{}
    $Global:LMStudioServer.Add("ServerInfo",@{})
    $Global:LMStudioServer.ServerInfo.Add("Server","")
    $Global:LMStudioServer.ServerInfo.Add("Port","")
    $Global:LMStudioServer.Add("HistoryFilepath","")

}
function Set-LMStudioServer ([string]$Server,[int]$Port, [switch]$Show){
    If ($Port.Length -eq 0 -or ($Port -lt 0 -or $Port -gt 65535)){throw "$Port must be in a range of 0-65535"}
    If (($Server.Length -eq 0 -or $null -eq $Server) -and $Port.Length -gt 0){throw "Please provide a name or IP address for parameter -Server"}

    If ($Server.Length -ne 0 -and $Port.Length -ne 0){

        try {$Global:LMStudioServer.ServerInfo.Server = $Server}
        catch {throw "Unable to set Global variable LMStudioServer for value Server: $Server"}
        
        try {$Global:LMStudioServer.ServerInfo.Port = $Port}
        catch {throw "Unable to set Global variable LMStudioServer for value Port: $Port"}

    }

    If ($Show.IsPresent){$Global:LMStudioServer}

}

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

    try {$Global:LMStudioServer.HistoryFilepath = $FolderPath}
    catch {throw "Unable to set HistoryFilepath. Run Initialize-LMVarStore to create it."}

    if ($null -eq $Global:LMStudioServer.HistoryFilepath -or $Global:LMStudioServer.HistoryFilepath.Length -eq 0){throw "HistoryFilepath is empty. Please Run Initialize-LMVarStore to fix it."}
}

 function New-GreetingPrompt {
    
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

function New-HistoryObject {
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

function Get-HistoryFile {

    #Check the Global Variable Store for the value
    If ($Global:LMStudioServer.HistoryFilepath.Length -eq 0 -or $null -eq $Global:LMStudioServer.HistoryFilepath){throw "Historyfilepath is empty. Run Set-LMHistoryPath to fix it :-)"}
    $HistoryFile = $Global:LMStudioServer.HistoryFilepath

    #Import the original History file
    try {$HistoryContent = Get-Content $HistoryFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
    catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message))"}

    If ($HistoryContent.Histories[0].Opener -ne "This is a dummy entry."){throw "History file $HistoryFile is missing the history dummy entry (bad format)"}
    If ($HistoryContent.Greetings[0].role -ne "dummy"){throw "History file $HistoryFile is missing the greeting dummy entry (bad format)"}
    If ($HistoryContent.Models.0 -ne "dummymodel"){throw "History file $HistoryFile is missing the models dummy entry (bad format)"}

    #move over content from Fixed-Length arrays to New ArrayLists:
    $NewHistory = New-HistoryObject

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

function Set-HistoryFile ($History){
If ($Global:LMStudioServer.HistoryFilepath.Length -eq 0 -or $null -eq $Global:LMStudioServer.HistoryFilepath){throw "Historyfilepath is empty. Run Set-LMHistoryPath to fix it :-)"}
$HistoryFile = $Global:LMStudioServer.HistoryFilepath

try {$History | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $HistoryFile -ErrorAction Stop}
catch {throw "Unable to save history to `$HistoryFile; $($_.Exception.Message)"}

return $True

}

function Show-Help {
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = “LMStudio-Client Help”
    $Messageboxbody = “!h - Displays this help`r`n!s - Change the system prompt`r`n!t - Change the temperature`r`n!f - Change the history file`r`n!q - Save and Quit”
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

}

function Get-LMModel {
    
    #region Check LMStudioServer values
    If ($null -eq $Global:LMStudioServer){throw "Please run Set-LMStudioServer first."}
    
    If ($Global:LMStudioServer.Server.Length -eq 0 -or $null -eq $Global:LMStudioServer.Server){

        If ($Global:LMStudioServer.Port.Length -eq 0 -or $null -eq $Global:LMStudioServer.Port){

            throw "Server and Port are not valid, please run Set-LMStudioServer again"

        }

    }
    
    If ($Global:LMStudioServer.Port.Length -eq 0 -or $null -eq $Global:LMStudioServer.Port){

        throw "Port is not valid, please run Set-LMStudioServer again"

    }
    #endregion
    
    [string]$EndPoint = $Server + ":" + $Port
    $ModelURI = "http://$EndPoint/v1/models"
    
    try {$ModelData = Invoke-RestMethod -Uri $ModelURI -ErrorAction Stop}
    catch {throw "Unable to retrieve model information: $($_.Exception.Message)"}

    $Model = $ModelData.data.id

    If ($Model.Length -eq 0 -or $null -eq $Model.Length){throw "`$Model.data.id is empty."}

    return $Model

}
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
        
        Set-HistoryFile -HistoryFile $HistoryFile -History $History

    } #Close If
    Else {$ModelIndex = ($History.Models.GetEnumerator() | Where-Object {$_.Value -eq "$Model"}).Name}



}

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