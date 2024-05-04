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
            
        $ThreeLetters = (Get-Random -Count 3 -InputObject $TokenSet.U) -join ', '

        $Greetings = @(
            "$TodayIsADay. Chose an adjective that contains these three letters: $ThreeLetters. Then use it to insult me in a short way without hurting my feelings too much.",
            "$TodayIsADay. Please greet me in a unique and fun way!",
            "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Then provide a fact about the chosen proper noun.",
            "$TodayIsADay. Please try to baffle me.",
            "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Then generate a haiku that includes this word.",
            "$TodayIsADay. Choose a proper noun that contains these three letters: $ThreeLetters. Please generate a short poem about this word."
            "$TodayisADay. Please wish me well for today."
        )
        
        $ChosenGreeting = $Greetings[$(Get-Random -Minimum 0 -Maximum $($Greetings.GetUpperBound(0)))]

        return $ChosenGreeting

    } #Close Function

    #endregion
    
    #region Prerequisite Variables
    $OrigProgPref = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    $Version = "0.5"

    [string]$Socket = $Server + ":" + $Port

    $ModelURI = "http://$Socket/v1/models"
    $CompletionURI = "http://$Socket/v1/chat/completions"

    $host.UI.RawUI.WindowTitle = "LM Studio Client v$Version ### Show Help: !h "

    $SystemPrompt = "Please be polite, concise and informative."

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

    If (!(Test-Path $HistoryFile)){

        $IsHistoryFileNew = $True

        try {

            $History = New-Object System.Collections.ArrayList

            $Greetings = New-Object System.Collections.ArrayList
            $Greetings.Add(([pscustomobject]@{"role" = "system"; "content" = "$SystemPrompt"})) | Out-Null
            $Greetings.Add(([pscustomobject]@{"role" = "user"; "content" = "$(New-GreetingPrompt)"})) | Out-Null

            $Histories = New-Object System.Collections.ArrayList
            $DummyContent = New-Object System.Collections.ArrayList
            $DummyContent.Add(([pscustomobject]@{"role" = "system"; "content" = "$SystemPrompt"})) | Out-Null
            $DummyContent.Add(([pscustomobject]@{"role" = "user"; "content" = "This is a dummy entry."})) | Out-Null

            $DummyEntry = [pscustomobject]@{"Date" = "$((Get-Date).ToString())"; "Opener" = "This is a dummy entry."; "Content" = $DummyContent}
            $Histories.Add($DummyEntry) | Out-Null

            $History.Add([pscustomobject]@{"Greetings" = $Greetings; "Histories" = $Histories}) | Out-Null

            $History | ConvertTo-Json -Depth 10 | Out-File -FilePath $HistoryFile -ErrorAction Stop

        }
        catch{throw "Unable to create history file $HistoryFile : $($_.Exception.Message))"}

    }
    Else {
        $IsHistoryFileNew = $False

        try {$History = Get-Content $HistoryFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
        catch {throw "Unable to import history file $HistoryFile : $($_.Exception.Message))"}

        If ($History.Histories[0].Opener -ne "This is a dummy entry."){throw "History file $HistoryFile is missing the dummy entry (bad format)"}

    }
   
    #region Fill in the Model, System Prompt and User Prompt of the $Body:
    $Body = $BodyTemplate | ConvertFrom-Json
    $Body = $Body -replace 'MODELHERE',"$Model"
    $Body = $Body -replace 'SYSPROMPTHERE',"$SystemPrompt"
    $Body = $Body -replace 'USERPROMPTHERE',"$UserPrompt"
    #endregion

    #region Prompt for and receiving greeting
    $GreetingParams = @{
        "Uri" = "$CompletionURI"
        "Method" = "POST"
        "Body" = $Body
        "ContentType" = "application/json"
    }

    try {
        $Response = Invoke-RestMethod @GreetingParams -UseBasicParsing -ErrorAction Stop
        $TrackedGreetings.Add("Answer: $($Response.choices.message.content)") | Out-Null
        $TrackedGreetings.Add(" ") | Out-Null
        $TrackedGreetings | Set-Content $HistoryFile 
        
        Write-Host "AI: " -ForegroundColor DarkMagenta -NoNewline; Write-Host "$($Response.choices.message.content)"
    }
    catch {$_.Exception.Message}

    

    #endregion

    #region Set up log file

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


