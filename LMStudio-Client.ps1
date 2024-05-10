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


