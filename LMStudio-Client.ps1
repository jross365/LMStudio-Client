[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$Server,
    [Parameter(Mandatory=$false)][ValidateRange(0, 65535)][int]$Port = 1234,
    [Parameter(Mandatory=$false)][string]$HistoryFile,
    [Parameter(Mandatory=$false)][double]$Temperature = 0.7,
    [Parameter(Mandatory=$false)][switch]$NoTimestamps,
    [Parameter(Mandatory=$false)][switch]$NoGreeting
    )

begin {

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

    function New-HistoryFile {
        try {

            $History = New-Object System.Collections.ArrayList

            $Greetings = New-Object System.Collections.ArrayList
            (0..1).ForEach({$Greetings.Add(([pscustomobject]@{"role" = "dummy"; "content" = "This is a dummy entry."})) | Out-Null})

            $DummyContent = New-Object System.Collections.ArrayList
            (0..1).ForEach({$DummyContent.Add(([pscustomobject]@{"role" = "dummy"; "content" = "This is a dummy entry."})) | Out-Null})

            $DummyEntry = [pscustomobject]@{"Date" = "$((Get-Date).ToString())"; "Opener" = "This is a dummy entry."; "Content" = $DummyContent}

            $Histories = New-Object System.Collections.ArrayList
            $Histories.Add($DummyEntry) | Out-Null

            $History.Add([pscustomobject]@{"Greetings" = $Greetings; "Histories" = $Histories}) | Out-Null
        }
        catch{throw "Unable to create history file $HistoryFile : $($_.Exception.Message))"}

    return $History       

    }

    function Get-HistoryFile ($HistoryFile) {

        #Import the original History file
        try {$HistoryContent = Get-Content $HistoryFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
        catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message))"}

        If ($HistoryContent.Histories[0].Opener -ne "This is a dummy entry."){throw "History file $HistoryFile is missing the dummy entry (bad format)"}

        #move over content from Fixed-Length arrays to New ArrayLists:
        $NewHistory = New-HistoryFile

        $HistoryContent.Greetings.Where({$_.Role -ne "dummy"}) | ForEach-Object {$NewHistory.Greetings.Add($_) | Out-Null}

        $NewHistory.Histories.Remove($NewHistory.Histories[0]) | Out-Null

        $HistoryContent.Histories.Foreach({
        
            $Entry = $_
            $Content = New-Object System.Collections.ArrayList
            $Entry.Content | ForEach-Object {$Content.Add($_) | out-null}
            
            $EntryCopy = [pscustomobject]@{"Date" = $Entry.Date; "Opener" = $Entry.Opener; "Content" = $Content}

            $NewHistory.Histories.Add($EntryCopy) | Out-Null

        })

        Remove-Variable HistoryContent -ErrorAction SilentlyContinue

        return $NewHistory

    } #Close Function

    function Set-HistoryFile ($HistoryFile, $History){

    try {$History | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $HistoryFile -ErrorAction Stop}
    catch {throw "Unable to save history to $HistoryFile"}

    return $True

    }

    #endregion
    
    #region Prerequisite Variables
    $OrigProgPref = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    $ReplayLimit = 10 #Sets the max number of assistant/user content context entries    

    $Version = "0.5"

    [string]$EndPoint = $Server + ":" + $Port

    $ModelURI = "http://$EndPoint/v1/models"
    $CompletionURI = "http://$EndPoint/v1/chat/completions"

    $host.UI.RawUI.WindowTitle = "LM Studio Client v$Version ### Show Help: !h "

    $SystemPrompt = "Please be polite, concise and informative."
    $NewGreeting = New-GreetingPrompt
    #endregion

    #region Define the BODY Template and Body
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

    #region Connection Test, and Model Name Retrieval
    try {$ModelData = Invoke-RestMethod -Uri $ModelURI -SessionVariable R2D2 -ErrorAction Stop}
    catch {throw "Unable to retrieve model information. Check to see if the server is up."}

    $Model = $ModelData.data.id
    #endregion
   
    #region Try to Load or Create a history
    If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$HistoryFile = "$env:USERPROFILE\Documents\ai_history.json"}

    If (!(Test-Path $HistoryFile)){ #Build a dummy history file

        try {

            $History = New-HistoryFile
            $History | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $HistoryFile -ErrorAction Stop

        }
        catch{throw "Unable to create history file $HistoryFile : $($_.Exception.Message))"}

    }
    Else {

        try {$History = Get-HistoryFile -HistoryFile $HistoryFile}
        catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message)"}

    }
   
    #region Walk backwards through the History.Greetings index to create a correct context replay:
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

    #Set up our Help menus:


    # !s : Set system prompt 
    # !o : Change save file
    # !t : Toggle timestamps"
    # !q : Quit

    #endregion

}

process {

    $Quit = $false

    do {

        $UserPrompt = Read-Host -Prompt "You"

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


