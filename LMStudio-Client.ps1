[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$Server,
    [Parameter(Mandatory=$false)][ValidateRange(0, 65535)][int]$Port = 1234,
    [Parameter(Mandatory=$false)][string]$HistoryFile,
    [Parameter(Mandatory=$false)][double]$Temperature = 0.7,
    [Parameter(Mandatory=$false)][switch]$NoTimestamps,
    [Parameter(Mandatory=$false)][switch]$SkipGreeting
    )

begin {

    function Initialize-LMVarStore {
        $Global:LMStudioServer = @{}
        $Global:LMStudioServer.Add("ServerInfo",@{})
        $Global:LMStudioServer.Add("HistoryFilepath","")

    }
    function Set-LMStudioServer ([string]$Server,[int]$Port, [switch]$Show){
        If ($Port.Length -gt 0 -and ($Port -lt 0 -or $Port -gt 65535)){throw "$Port must be in a range of 0-65535"}
        If ($Server.Length -ne 0 -and $null -ne $Server -and $Port.Length -gt 0){throw "Please provide a name or IP address for parameter -Server"}

        If ($Server.Length -ne 0 -and $Port.Length -ne 0){

            If$Global:LMStudioServer = @{}

            try {$Global:LMStudioServer.ServerInfo.Add($Server)}
            catch {$Global:LMStudioServer.ServerInfo.Server = $Server}
            
            try {$Global:LMStudioServer.ServerInfo.Add($Port)}
            catch {$Global:LMStudioServer.ServerInfo.Port = $Port}

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

    #region Define functions
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

    #endregion
    
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


