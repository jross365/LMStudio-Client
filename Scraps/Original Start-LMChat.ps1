
function Start-LMChat {
    [CmdletBinding(DefaultParameterSetName="Auto")]
    param (
        #Use $Global:LMGlobalVars
        [Parameter(Mandatory=$true, ParameterSetName='Auto')]
        [switch]$UseConfig, 

        #Signals a prompt to select an entry from the History File
        [Parameter(Mandatory=$False, ParameterSetName='Auto')]
        [switch]$ResumeChat, 

        [Parameter(Mandatory=$true, ParameterSetName='Manual')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Server,
        
        [Parameter(Mandatory=$true, ParameterSetName='Manual')]
        [ValidateRange(1, 65535)][int]$Port,


        [Parameter( Mandatory=$False,ParameterSetName='Auto')]
        [Parameter(Mandatory=$false, ParameterSetName='Manual')]
        [switch]$ChooseSystemPrompt,

        [Parameter( Mandatory=$False,ParameterSetName='Auto')]
        [Parameter(Mandatory=$false, ParameterSetName='Manual')]
        [switch]$SkipSavePrompt,        

        [Parameter(Mandatory=$false, ParameterSetName='Manual')]
        [ValidateScript({ if ($_.GetType().Name -ne "Hashtable") { throw "Parameter must be a hashtable" } else { $true } })]
        [hashtable]$Settings

        )

begin {

    #region Evaluate and set Variables
    switch ($UseConfig.IsPresent){

        $True {
            If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}

            $Server = $Global:LMStudioVars.ServerInfo.Server
            $Port = $Global:LMStudioVars.ServerInfo.Port
            $Endpoint = $Global:LMStudioVars.ServerInfo.Endpoint
            $CompletionURI = "http://" + $EndPoint + "/v1/chat/completions"
            $HistoryFile = $Global:LMStudioVars.FilePaths.HistoryFilePath
            $DialogFolder = $Global:LMStudioVars.FilePaths.DialogFolderPath
            $StreamCachePath = $Global:LMStudioVars.FilePaths.StreamCachePath
            $Greeting = $Global:LMStudioVars.ChatSettings.Greeting
            $Stream = $Global:LMStudioVars.ChatSettings.stream
            $Temperature = $Global:LMStudioVars.ChatSettings.temperature
            $MaxTokens = $Global:LMStudioVars.ChatSettings.max_tokens
            $ContextDepth = $Global:LMStudioVars.ChatSettings.ContextDepth
            $MarkDown = $Global:LMStudioVars.ChatSettings.MarkDown
            $ShowSavePrompt = $Global:LMStudioVars.ChatSettings.SavePrompt
            $SystemPrompt = $Global:LMStudioVars.ChatSettings.SystemPrompt
            
    
        }

        $False { #Not tested, but straightforward: Takes a "ManualChatSettings" template

            $Endpoint = "$Server" + ":" + "$Port"
            $CompletionURI = "http://" + $EndPoint + "/v1/chat/completions"
            $StreamCachePath = (Get-Location).Path + '\lmstream.cache'

            #Set tunables via hash table
            If (!$PSBoundParameters.ContainsKey('Settings')){$Settings = Get-LMTemplate -Type ManualChatSettings}

            If ($null -ne $Settings.temperature){$Temperature = ([double]($Settings.temperature))}
            Else {$Temperature = 0.7} #Default
            
            If ($null -ne $Settings.max_tokens){$MaxTokens = ([int]($Settings.max_tokens))}
            Else {$MaxTokens = -1} #Default

            If ($null -ne $Settings.ContextDepth){$ContextDepth = ([int]($Settings.ContextDepth))}
            Else {$ContextDepth = 10} #Default

            If ($null -ne $Settings.Stream){$Stream = ([boolean]($Settings.Stream))}
            Else {$Stream = $True} #Default

            If ($null -ne $Settings.ShowSavePrompt){$ShowSavePrompt = ([boolean]($Settings.ShowSavePrompt))}
            Else {$ShowSavePrompt = $True} #Default

            If ($null -ne $Settings.SystemPrompt){$SystemPrompt = $Settings.SystemPrompt}
            Else {$SystemPrompt = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."} #Default

            If ($null -ne $Settings.MarkDown){$MarkDown = ([boolean]($Settings.MarkDown))}
            Else {$MarkDown = &{If ($PSVersionTable.PSVersion.Major -ge 7){$true} else {$False}}}

            }
            
        }
    #endregion

    #region Get Model (Connection Test)
    try {$Model = Get-LMModel -Server $Server -Port $Port}
    catch {throw $_.Exception.Message}
    #endregion

    #region Check/set if we can use markdown
    $MarkDownAvailable = Show-LMDialog -CheckMarkdown
    $UseMarkDown = ([bool]($MarkDown -and $MarkDownAvailable))
    #endregion
    
    #region -ResumeChat Selector
    switch ($ResumeChat.IsPresent){ #Not Yet Tested

        #This section requires everything goes right (terminates with [throw] if it doesn't)
        $true { 
                #If the history file doesn't exist, find it:
                If (!(Test-Path $HistoryFile)){
        
                    #Prompt to browse and "open" it
                    try {$HistoryFile = Invoke-LMSaveOrOpenUI -Action Open -Extension index -StartPath "$env:Userprofile\Documents"}
                    catch {throw $_.Exception.Message}
        
                }
                
                #Open a GridView selector from the history file
                try {$DialogFilePath = Select-LMHistoryEntry -HistoryFile $HistoryFile}
                catch {
                    If ($_.Exception.Message -match 'selection cancelled'){throw "Selection cancelled"}
                    else {Write-Warning "$($_.Exception.Message)"; return}

                }

                #Otherwise: Read the contents of the chosen Dialog file
                try {$Dialog = Import-LMDialogFile -FilePath $DialogFilePath -ErrorAction Stop}
                catch {throw $_.Exception.Message}

                #If we made it this far, Let's set $Greeting and $DialogFIleExists
                $Greeting = $False
                $DialogFileExists = $True

        } #Close Case $True

        #This section can accommodate a failure to create a new Dialog file
        $false { #If not Resume Chat, then Create New Dialog File

                $Dialog = Get-LMTemplate -Type ChatDialog
                
                $Dialog.Info.Model = $Model
                $Dialog.Info.Modified = "$((Get-Date).ToString())"
                $Dialog.Messages[0].temperature = $Temperature
                $Dialog.Messages[0].max_tokens = $MaxTokens
                $Dialog.Messages[0].stream = $Stream
                $Dialog.Messages[0].ContextDepth = $ContextDepth
                $Dialog.Messages[0].Content = $SystemPrompt

                $NewFile = $True

                # Set the directory path for the chat file:
                #
                # We need this set even if we skip the save prompt,
                # in case we decide to save during the prompt (:s to save?)
                # This is why it's outside of (!($SkipSavePrompt.IsPresent))
                If ($UseConfig.IsPresent){$DialogStartPath = $global:LMStudioVars.FilePaths.DialogFolderPath}
                Else {$DialogStartPath = "$($env:USERPROFILE)\Documents"}

                #If we didn't opt to skip this prompt:
                If (!($SkipSavePrompt.IsPresent)){
        
                    try { # Prompt to create the full file path
                        $DialogFilePath = Invoke-LMSaveOrOpenUI -Action Save -Extension dialog -StartPath $DialogStartPath
                        $DialogFileExists = $True
                    }
                    catch {
                        Write-Warning "$($_.Exception.Message)"
                        $DialogFileExists = $False
                    }

                    # If the path creation prompt succeeds, export the contents of the Chat Dialog template to the file:
                    If ($DialogFileExists){

                        try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFilePath -ErrorAction Stop}
                        catch {
                            Write-Warning "$($_.Exception.Message)"
                            $DialogFileExists = $False
                        }

                    }

                } #Close SkipSavePrompt Not Present
                Else {
                    $DialogFileExists = Test-Path $DialogFilePath
                    Write-Warning "Dialog file not saved to file. In the User prompt, enter ':Save' to save."
                }

                } #Close Case $False
            
            } #Close Switch
    #endregion
    
    #region -ChooseSystemPrompt triggers System Prompt selector (FUNCTION NOT BUILT YET)
    If ($ChooseSystemPrompt.IsPresent){
    
        $SystemPrompt = Get-LMSystemPrompt
    
        If ($SystemPrompt -eq "Cancelled" -or $null -eq $SystemPrompt -or $SystemPrompt.Length -eq 0){$SystemPrompt = "Please be polite, concise and informative."} 
    
    }
    Else {$SystemPrompt = "Please be polite, concise and informative."} #Set to "default" - Need to move this out to $Global:LMGlobalVars

    #endregion

    #region Initiate Greeting
    If ($Greeting){

        If ($UseConfig.IsPresent){Get-LMGreeting -UseConfig}
        Else {Get-LMGreeting -Server $Server -Port $Port -Stream $Stream}
        
    }
    #endregion
 
} #begin

process {
    
    $BreakDialog = $False
    $OpenerSet = ([boolean](($Dialog.Info.Opener.Length -ne 0) -and ($null -ne $Dialog.Info.Opener) -and ($Dialog.Info.Opener -ne "dummyvalue")))
    

    #Set $BodySettings for use with Convert-LMDialogToBody:
    $BodySettings = @{}
    $BodySettings.Add('model',$Model)
    $BodySettings.Add('temperature', $Temperature)
    $BodySettings.Add('max_tokens', $MaxTokens)
    $BodySettings.Add('stream', $Stream)
    $BodySettings.Add('SystemPrompt', $SystemPrompt)

    If ($ResumeChat.IsPresent){ #Play the previous conversation back to the 

        switch ($UseMarkDown){

            $True {Show-LMDialog -DialogMessages ($Dialog.Messages) -AsMarkdown}

            $False {Show-LMDialog -DialogMessages ($Dialog.Messages)} #Close False
        }

    }

    #The magic is here:
:main do { 

        #region Prevent empty responses
        do {

            Write-Host "You: " -ForegroundColor Green -NoNewline
            $UserInput = Read-Host 
        
        }
        until ($UserInput.Length -gt 0)
        #endregion

        #region Construct the user Dialog Message and append to the Dialog:
        $UserMessage = Get-LMTemplate -Type DialogMessage
      
        $UserMessage.TimeStamp = (Get-Date).ToString()
        $UserMessage.temperature = $Temperature
        $UserMessage.max_tokens = $MaxTokens
        $UserMessage.stream = $Stream
        $UserMessage.ContextDepth = $ContextDepth
        $UserMessage.Role = "user"
        $UserMessage.Content = "$UserInput"

        $Dialog.Messages.Add($UserMessage) | out-null
        #endregion


        #region Send $Dialog.Messages to Convert-DialogToBody:
        $Body = Convert-LMDialogToBody -DialogMessages ($Dialog.Messages) -ContextDepth $ContextDepth -Settings $BodySettings
        #endregion

        Write-Host ""
        Write-Host "AI: " -ForegroundColor Magenta -NoNewline

        switch ($Stream){

            $True {$LMOutput = Invoke-LMStream -Body $Body -CompletionURI $CompletionURI -File $StreamCachePath}
            $False {$LMOutput = Invoke-LMBlob -Body $Body -CompletionURI $CompletionURI -StreamSim}

        }

        Write-Host ""

        If ($LMOutput -eq "[stream_interrupted]"){continue main}

        #region Construct the assistant Dialog message and append to the Dialog:
        $AssistantMessage = Get-LMTemplate -Type DialogMessage
        
        $AssistantMessage.TimeStamp = (Get-Date).ToString()
        $AssistantMessage.temperature = $Temperature
        $AssistantMessage.max_tokens = $MaxTokens
        $AssistantMessage.stream = $Stream
        $AssistantMessage.ContextDepth = $ContextDepth
        $AssistantMessage.Role = "assistant"
        $AssistantMessage.Content = "$LMOutput"
        #endregion

        
        #region Append the response to the Dialog::
        $Dialog.Messages.Add($AssistantMessage) | out-null
        #endregion

        #region Update Dialog Object
        $Dialog.Info.Modified = $AssistantMessage.TimeStamp
        #endregion

        #region Apply Markdown, if enabled
        If ($UseMarkDown){Show-LMDialog -DialogMessages $Dialog.Messages -AsMarkdown}
        #endregion

        #region Update Dialog File, History File
        If ($DialogFileExists){

             #region Set Opener
            If (!($OpenerSet)){
                $Dialog.Info.Opener = (($Dialog.Messages | Sort-Object TimeStamp) | Where-Object {$_.role -eq "user"})[0].Content
                $OpenerSet = $False
            }
            #endregion

            # Save the Dialog File
            try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFilePath -ErrorAction Stop}
            catch {
                Write-Warning "Dialog file save failed; Disabling file saving (:Save to recreate a Dialog file)"
                $DialogFileExists = $False
            }

            # Update the History File
            If ($DialogFileExists){ 
            
                try {Update-LMHistoryFile -FilePath $HistoryFile -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                catch { #Sleep and then try once more, in case we're stepping on our own feet (multiple)
                    
                    Start-Sleep -Seconds 2

                    try {Update-LMHistoryFile -FilePath $HistoryFile -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                    catch {
                    
                        Write-Warning "Unable to append Dialog updates to History file; Disabling file-saving (:Save to recreate a Dialog file)"
                        $DialogFileExists = $False
                    }
                }

            }

        }
        #endregion       
        
    }
    until ($BreakDialog -eq $True)
}

end {

    #HERE:
        # - Need to Update the "opener" line for the Dialog object
        # - Need to update the History File with the new Dialog object information

    }

}
