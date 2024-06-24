function Confirm-LMYesNo {

    $Answered = $False

    do {

        $DefaultAnswer = Read-Host "Accept? (y/N)"

        If ($DefaultAnswer -ine 'y' -and $DefaultAnswer -ine 'n'){

            Write-Host "Please enter 'Y' or 'N' (no quotes, but not case sensitive)" -ForegroundColor Yellow

        }
        Else {$Answered = $True}

    }
    until ($Answered -eq $True)

    switch ($DefaultAnswer){

        {$_ -ieq 'y'}{return $True}
        {$_ -ieq 'n'}{return $False}

    }

}

#This function prompts for server name and port:
    # it prompts to create a new history file, or to load an existing one. 
    # If loading an existing one, it needs to verify it.
function New-LMConfig { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Server,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 65535)
        ][int]$Port,

        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$BasePath = "$($Env:USERPROFILE)\Documents\LMStudio-PSClient",

        [Parameter(Mandatory=$false)][switch]$Import
        
    )#Structure: 
    
    begin {

        #region Request Server parameter
        If (!($PSBoundParameters.ContainsKey('Server'))){

            $InputAccepted = $false

            do {
                $Server = Read-Host "Please provide a valid server hostname or IP address"
                $InputAccepted = (!([boolean]($null -eq $Server -or $Server.Count -eq 0)))
            }
            until ($InputAccepted -eq $true)

        }
        #endregion

        #region Validate Port input
        If (!($PSBoundParameters.ContainsKey('Port'))){

            $InputValid = $false

            do {
                $Port = Read-Host "Please provide a port (1-65535)"

                $InputValid = $False

                If ($Null -eq $Port -or $Port.Length -eq 0){$InputValid = $False}
                Else {
                
                    try {$PortAsInt = [int]$Port}
                    catch {Write-Warning "$Port is not a valid integer"; continue}
                    
                    If ($PortAsInt -le 0 -or $PortAsInt -gt 65535){
                        Write-Warning "Port $Port is not in a range of 1-65535"
                        $InputValid = $False
                    }
                    Else {$InputValid = $True}
                }
                
            }
            until ($InputValid -eq $true)

        }
        #endregion

        #region Set the Base Path
        If (!($PSBoundParameters.ContainsKey('BasePath'))){

            $SuggestedBasePath = "$Env:UserProfile\Documents\LMStudio-PSClient"

            Write-Host "Default directory path is $SuggestedBasePath"

            $ConfirmBasePath = Confirm-LMYesNo

            switch ($ConfirmBasePath){

                $True {$BasePath = $SuggestedBasePath}

                $False {

                    try {$BasePath = Invoke-LMOpenFolderUI}
                    catch {$_.Exception.Message}

                }

                Default {throw "Selection prompt was canceled"}
            }

        }
        #endregion

        #region Define files and folders from Base Path
        $ConfigFile = "$BasePath\lmsc.cfg"
        $HistoryFilePath = "$BasePath\$($ENV:USERNAME)-HF.index"
        $DialogFolder = $HistoryFilePath.TrimEnd('.index') + '-DialogFiles'
        $GreetingFilePath = "$DialogFolder\hello.greetings"
        $StreamCachePath = "$BasePath\stream.cache"
        $SystemPromptPath = "$BasePath\system.prompts"
        #endregion
     
    } #End Begin

    process {

        #region Create base path
        If (!(Test-Path $BasePath)){

            try {mkdir $BasePath}
            catch {throw "Unable to create directory path $BasePath"}

        }
        #endregion

        #region Set creation variables        
        $ConfigFileObj = New-LMTemplate -Type ConfigFile
        $SystemPromptsObj = New-LMTemplate -Type SystemPrompts

        $ConfigFileObj.ServerInfo.Server = $Server
        $ConfigFileObj.ServerInfo.Port = $Port
        $ConfigFileObj.ServerInfo.Endpoint = "$Server`:$Port"
        $ConfigFileObj.FilePaths.HistoryFilePath = $HistoryFilePath
        $ConfigFileObj.FilePaths.DialogFolderPath = $DialogFolder
        $ConfigFileObj.FilePaths.GreetingFilePath = $GreetingFilePath
        $ConfigFileObj.FilePaths.StreamCachePath = $StreamCachePath
        $ConfigFileObj.FilePaths.SystemPromptPath = $SystemPromptPath
        $ConfigFileObj.ChatSettings.temperature = 0.7
        $ConfigFileObj.ChatSettings.max_tokens = -1
        $ConfigFileObj.ChatSettings.stream = $True
        $ConfigFileObj.ChatSettings.ContextDepth = 10
        $ConfigFileObj.ChatSettings.Greeting = $True
        $ConfigFileObj.ChatSettings.SystemPrompt = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
        $ConfigFileObj.ChatSettings.Markdown = &{If ($PSVersionTable.PSVersion.Major -ge 7){$true} else {$False}}
        $ConfigFileObj.ChatSettings.SavePrompt = $True
        $ConfigFileObj.URIs.CompletionURI = $ConfigFileObj.URIs.CompletionURI -replace 'X', "$($ConfigFileObj.ServerInfo.Endpoint)" 
        $ConfigFileObj.URIs.ModelURI = $ConfigFileObj.URIs.ModelURI -replace 'X', "$($ConfigFileObj.ServerInfo.Endpoint)" 
        #endregion

    }

    end {

        #region Display information and prompt for creation
        Write-Host "Config File Settings:" -ForegroundColor White

        $ConfigFileObj | Format-List

        Write-Host ""; Write-Host "History File location:" -ForegroundColor Green
        Write-Host "$HistoryFilePath"
        Write-Host ""; Write-Host "Dialog subdirectory:" -ForegroundColor Green
        Write-Host "$DialogFolder"
        Write-Host ""; Write-Host "Greeting File location:" -ForegroundColor Green
        Write-Host "$GreetingFilePath"
        Write-Host ""; Write-Host "Stream Cache location:" -ForegroundColor Green
        Write-Host "$StreamCachePath"
        Write-Host ""; Write-Host "System Prompts location:" -ForegroundColor Green
        Write-Host "$SystemPromptPath"
        Write-Host ""; Write-Host "Config File location:" -ForegroundColor Green
        Write-Host "$ConfigFile"

        $Proceed = Confirm-LMYesNo
        #endregion

        If ($Proceed -ne $true){throw "Configuration creation cancelled"}

        If (!(Test-Path $HistoryFilePath)){
            
            Write-Host "History File $HistoryFilePath not found, creating."

            try {@((New-LMTemplate -Type HistoryEntry)) | ConvertTo-Json | Out-File -FilePath $HistoryFilePath -ErrorAction Stop}
            catch {throw "History file creation failed: $($_.Exception.Message)"}
        }

        If (!(Test-Path $DialogFolder)){
            
            Write-Host "Dialog Folder $DialogFolder not found, creating."

            try {mkdir $DialogFolder -ErrorAction Stop | out-null}
            catch {throw "Dialog folder creation failed: $($_.Exception.Message)"}
        }

        If (!(Test-Path $GreetingFilePath)){

            Write-Host "Greeting file $GreetingFilePath not found, creating."

            try {(New-LMTemplate -Type ChatGreeting | Export-csv $GreetingFilePath -NoTypeInformation)}
            catch {throw "Greeting file creation failed: $($_.Exception.Message)"}

        }

        If (!(Test-Path $SystemPromptPath)){

            Write-Host "System prompts file $SystemPromptPath not found, creating."

            try {($SystemPromptsObj | Export-csv $SystemPromptPath -NoTypeInformation)}
            catch {throw "System prompts file creation failed: $($_.Exception.Message)"}

        }

        $HistoryArray = New-Object System.Collections.ArrayList

        $HistoryArray.Add((New-LMTemplate -Type HistoryEntry)) | Out-Null
        $HistoryArray.Add((New-LMTemplate -Type HistoryEntry)) | Out-Null

        try {$HistoryArray | ConvertTo-Json -depth 5 | Out-File -FilePath $HistoryFilePath -ErrorAction Stop}
        catch {throw "History file creation failed: $($_.Exception.Message)"}

        If (Test-Path $ConfigFile){Remove-Item $ConfigFile}

        try {$ConfigFileObj | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $ConfigFile -ErrorAction Stop}
        catch {throw "Config file creation failed: $($_.Exception.Message)"}
        

    If ($Import.IsPresent){

        try {$null = Import-LMConfig -ConfigFile $ConfigFile}
        catch {throw "Unable to import configuration: $($_.Exception.Message)"}

        $Global:LMConfigFile = $ConfigFile

    }

    } #Close End

}

#This function reads the local LMConfigFile.cfg, verifies it (unless skipped), and then writes the values to the $Global:LMStudioVars
function Import-LMConfig { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "Config file path does not exist" } else { $true } })]
        [string]$ConfigFile,

        [Parameter(Mandatory=$false)]
        [switch]$Verify        
    )
begin {

    #region If we don't have a config file specified, try to open one
    If (!($PSBoundParameters.ContainsKey('ConfigFile'))){
        
        try {$ConfigFile = Invoke-LMSaveOrOpenUI -Action Open -Extension cfg -StartPath "$Env:USERPROFILE\Documents\LMStudio-PSClient" -FileName "lmsc.cfg"}
        catch {throw $_.Exception.Message}

    }
    #endregion
    
    #region Import config file
    try {$ConfigData = Get-Content $ConfigFile -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
    catch {throw $_.Exception.Message}
    #endregion

}#Close Begin
process {

    try {$Global:LMStudioVars = $ConfigData}
    catch {throw $_.Exception.Message}

    $Global:LMConfigFile = $ConfigFile

    } #Close Process
end {

    if ($Verify.IsPresent){

    #region Verify config file properties exist:
    Write-Host "Checking Global Variables: " -NoNewline
    $CheckGlobalVars = Confirm-LMGlobalVariables -ReturnBoolean
    
    switch ($CheckGlobalVars){

        $True {Write-Host "Good" -ForegroundColor Green}
        $False {Write-Host "Errors in loaded variables" -ForegroundColor Yellow}
    }

    #endregion

    Write-Host "Checking access to LMStudio Web Server: " -NoNewline
    $ModelRetrieval = Get-LMModel -AsTest
    
    switch ($ModelRetrieval){

        $True {Write-Host "Good" -ForegroundColor Green}
        $False {Write-Host "Unable to connect to server (webserver started?)" -ForegroundColor Yellow}

    }

    Write-Host "Checking history file path: " -NoNewline
    $CheckHistoryFilePath = Test-Path ($Global:LMStudioVars.FilePaths.HistoryFilePath)

    switch ($CheckHistoryFilePath){

        $True {Write-Host "Good" -ForegroundColor Green}
        $False {Write-Host "History File path is not valid" -ForegroundColor Yellow}

    }
    
    Write-Host "Checking history file format: " -NoNewline
    If ($CheckHistoryFilePath -eq $False){Write-Host "Path not found, skipping" -ForegroundColor Yellow}
    Else {

        $CheckHistoryFileContents = Import-LMHistoryFile -FilePath ($Global:LMStudioVars.FilePaths.HistoryFilePath) -AsTest

        switch ($CheckHistoryFileContents){

            $True {Write-Host "Good" -ForegroundColor Green}
            $False {Write-Host "History File contents not valid" -ForegroundColor Yellow}
    
        }
    }
        
    Write-Host "Done." -ForegroundColor Green
   
        }

    } #Close End
}

#This function updates values in $GLobal:LMConfigVars. It also offers a -Commit function, that writes the changes to the Config file
function Set-LMConfigOptions {
    [CmdletBinding()]
    param(
        # Param1 help description
        [Parameter(Mandatory=$true)][ValidateSet('ServerInfo', 'ChatSettings', 'FilePaths',"URIs")][string]$Branch,
        [Parameter(Mandatory=$true)][hashtable]$Options,
        [Parameter(Mandatory=$false, ParameterSetName='SaveChanges')][switch]$Commit
    )

    If ((Confirm-LMGlobalVariables -ReturnBoolean) -ne $True){throw "Something went wrong when running Confirm-LMGlobalVariables (didn't return True)"}

    $GlobalKeys = $Global:LMStudioVars.$Branch.psobject.Properties.Name

    $ConfigFile = $Global:LMConfigFile #Created by Import-Config/Export-Config

    $RequestedKeys = $Options.GetEnumerator().Name

    $DiffDeltas = (Compare-Object -ReferenceObject $GlobalKeys -DifferenceObject $RequestedKeys).Where({$_.SideIndicator -eq '=>'})

    If ($CompareKeys.Count -gt 0){throw "Keys not found in $Branch - $($DiffDeltas.InputObject -join ', ')"}

    Foreach ($Key in $RequestedKeys){$Global:LMStudioVars.$Branch.$Key = ($Options.$Key)}

    If ($Commit.IsPresent){

        If (!(Test-Path $ConfigFile)){

            try {"" | Out-File $ConfigFile -ErrorAction Stop}
            catch {throw "Settings applied, but unable to create $ConfigFile to save settings [Set-LMConfigOptions]"}

        }

        try {$Global:LMStudioVars | ConvertTo-Json -depth 5 -ErrorAction Stop | out-file $ConfigFile -ErrorAction Stop}
        catch {throw "Settings applied, but unable to save settings to $ConfigFile [Set-LMConfigOptions]"}
    }

    }

#This function returns different kinds of objects needed by various functions
function New-LMTemplate { #Complete
    [CmdletBinding()]
    param(
        # Param1 help description
        [Parameter(Mandatory=$true)]
        [ValidateSet('ConfigFile', 'HistoryEntry', 'ChatGreeting', 'ChatDialog','DialogMessage', 'Body', 'ManualSettings','SystemPrompts')]
        [string]$Type
    )

    $DummyValue = "dummyvalue"

    switch ($Type){

        {$_ -ieq "ConfigFile"}{

            $ServerInfoObj = [pscustomobject]@{
                "Server" = "";
                "Port" = "";
                "Endpoint" = "";
            }

            $FilePathsObj = [pscustomobject]@{
                "HistoryFilePath" = "";
                "DialogFolderPath" = "";
                "GreetingFilePath" = "";
                "StreamCachePath" = "";
                "SystemPromptPath" = "";
            }            

            $ChatSettingsObj = [pscustomobject]@{
                "temperature" = 0.7;
                "max_tokens" = -1;
                "stream" = $True;
                "ContextDepth" = 10;
                "Greeting" = $True;
                "SystemPrompt" = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
                "Markdown" = &{If ($PSVersionTable.PSVersion.Major -ge 7){$true} else {$False}}
                "SavePrompt" = $True
            }
                        
            $URIsObj = [pscustomobject]@{
                "ModelURI" = "http://X/v1/models";
                "CompletionURI" = "http://X/v1/chat/completions";

            }

            $Object = [pscustomobject]@{"ServerInfo" = $ServerInfoObj; "ChatSettings" = $ChatSettingsObj; "FilePaths" = $FilePathsObj; "URIs" = $URIsObj}
        }
        {$_ -ieq "HistoryEntry"}{
            
            $Object = [pscustomobject]@{
                "Created" = "$DummyValue";
                "Modified" = "$DummyValue";
                "Title" = "$DummyValue";
                "Opener" = "$DummyValue";
                "Model" = "$DummyValue";
                "FilePath" = "$DummyValue"
                "Tags" = @("$DummyValue","$DummyValue")
                }
        
        }
        {$_ -ieq "ChatGreeting"}{

            $Object = [pscustomobject]@{

                "TimeStamp" = "$((Get-Date).ToString())"
                "System" = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."; #System Prompt
                "User" = $DummyValue;   #User Prompt
                "Assistant" = $DummyValue;
                "Model" = $DummyValue;
                "Temperature" = $Global:LMStudioVars.ChatSettings.temperature
                "Max_Tokens" = $Global:LMStudioVars.ChatSettings.max_tokens
                "Stream" = $Global:LMStudioVars.ChatSettings.stream
                "ContextDepth" = $Global:LMStudioVars.ChatSettings.ContextDepth

            }

            If ($null -eq $Object.Temperature){$Object.Temperature = 0.7}
            If ($null -eq $Object.Max_Tokens){$Object.Max_Tokens = -1}
            If ($null -eq $Object.Stream){$Object.Stream = $True}
            If ($null -eq $Object.ContextDepth){$Object.ContextDepth = 10}
        }
        {$_ -ieq "ChatDialog"}{
            
            #The "Info" portion of the file
            $Info = @{}

            $InfoFields = @("Model","Title","Tags","Created","Modified","Opener")

            $InfoFields.ForEach({$Info.Add($_,"$DummyValue")})
            
            $Info.Created = "$((Get-Date).ToString())"
            $Info.Modified = "$((Get-Date).ToString())"
            $Info.Tags = New-Object System.Collections.ArrayList

            (0..1).ForEach({$Info.Tags.Add("$DummyValue") | out-null})

            #The "Messages" portion of the file.
            $Messages = New-Object System.Collections.ArrayList

            $DummyRow = New-LMTemplate -Type DialogMessage

            If ($null -eq $DummyRow.temperature){$DummyRow.temperature = 0.7}
            If ($null -eq $DummyRow.max_tokens){$DummyRow.max_tokens = -1}
            If ($null -eq $DummyRow.stream){$DummyRow.stream = $True} #default
            If ($null -eq $DummyRow.ContextDepth){$DummyRow.ContextDepth = 10} #default

            $Messages.Add($DummyRow) | Out-Null

            $Object = [pscustomobject]@{"Info" = $Info; "Messages" = $Messages}

        }
        {$_ -ieq "DialogMessage"}{
            
            $Object = [pscustomobject]@{
                "TimeStamp" = ((Get-Date).ToString());
                "temperature" = $Global:LMStudioVars.ChatSettings.temperature;
                "max_tokens" = $Global:LMStudioVars.ChatSettings.max_tokens;
                "stream" = $Global:LMStudioVars.ChatSettings.stream;
                "ContextDepth" = $Global:LMStudioVars.ChatSettings.ContextDepth;
                "Role" = "system";
                "Content" = "Please be polite, concise and informative."
            }

        }
        {$_ -ieq "Body"}{

            $Object = '{ 
                "model": "MODELHERE",
                "messages": [ 
                  { "role": "system", "content": "SYSPROMPTHERE" },
                  { "role": "user", "content": "USERPROMPTHERE" }
                ], 
                "temperature": "TEMPHERE", 
                "max_tokens": "MAXTOKENSHERE",
                "stream": "STREAMHERE"
            }' 

            If ($null -ne $Global:LMStudioVars.ChatSettings){
            
                $Object = $Object -replace '"TEMPHERE"',$($Global:LMStudioVars.ChatSettings.temperature)
                $Object = $Object -replace '"MAXTOKENSHERE"',$($Global:LMStudioVars.ChatSettings.max_tokens)
                $Object = $Object -replace 'STREAMHERE',$($Global:LMStudioVars.ChatSettings.stream)
                }
            
            Else {

                $Object = $Object -replace '"TEMPHERE"', 0.7
                $Object = $Object -replace '"MAXTOKENSHERE"', -1
                $Object = $Object -replace 'STREAMHERE', $True

            }

                $Object = $Object | ConvertFrom-Json

        }
        {$_ -ieq "ManualSettings"}{

            $Object = @{}
            $Object.Add("server", "localhost")
            $Object.Add("port", 1234)
            $Object.Add("temperature", 0.7)
            $Object.Add("max_tokens", -1)
            $Object.Add("ContextDepth", 10)
            $Object.Add("SystemPrompt", $Global:LMStudioVars.ChatSettings.SystemPrompt)
            $Object.Add("UserPrompt", "")
            $Object.Add("DialogFile", $null)
            $Object.Add("stream", $True)
            $Object.Add("Markdown", (&{If ($PSVersionTable.PSVersion.Major -ge 7){$true} else {$False}}))

        }

        {$_ -ieq "SystemPrompts"}{
$Object = @'
"Name","Prompt"
"ChatML","Perform the task to the best of your ability."
"CodeLlama Instruct","You are a helpful coding AI assistant. Please keep your responses concise, unless explicitly asked to expand further on the topic."
"CodeLlama WizardCoder","Below is an instruction that describes a task. Write a response that appropriately completes the request."
"Deepseek Coder","You are an AI programming assistant, utilizing the Deepseek Coder model, developed by Deepseek Company, and you only answer questions related to computer science."
"Llama 3","You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
"MetaAI Llama 2 Chat","You are a helpful coding AI assistant."
"Moistral","You are the Moistral large language model. Your main function is to transform any ordinary text into a work of art making it moist and interesting. "
"Phind CodeLlama","You are an intelligent programming assistant."
"Vicuna v1.5 16K","A chat between a curious user and an artificial intelligence assistant. The assistant gives helpful, detailed, and polite answers to the user's questions."
'@ | ConvertFrom-Csv 

        }

    } #Close switch

    return $Object

}

#This function validates $Global:LMStudioVars is fully populated
function Confirm-LMGlobalVariables ([switch]$ReturnBoolean) { #Complete, rewrote this to be completely property name-agnostic

    $Errors = New-Object System.Collections.ArrayList
    
    $GlobalVarsTemplate = New-LMTemplate -Type ConfigFile

    If ($null -ne $Global:LMStudioVars){

       :bloop Foreach ($Branch in $GlobalVarsTemplate.psobject.Properties.Name){

            If ($null -ne $Global:LMStudioVars.$Branch) {

                $Leafs = $GlobalVarsTemplate.$Branch.psobject.Properties.Name

                Foreach ($Leaf in $Leafs){

                    If ($Global:LMStudioVars.$Branch.$Leaf.Length -eq 0 -or $null -eq $Global:LMStudioVars.$Branch.$Leaf){

                        $Errors.Add($("$Branch.$Leaf"))

                    }

                }
            }

            Else {$Errors.Add("$Branch") | out-null}

        }
    }

    Else {$Errors.Add('$Global:LMStudioVars')}
        
    Switch ($ReturnBoolean.IsPresent){

        $True {
        
            If ($Errors.Count -gt 0){return $False}
            Else {return $True}
        
        }

        $False {

            If ($Errors.Count -gt 0){throw "`$Global:LMStudioVars missing values: $($Errors -join ', ')"}

        }

    } #Close Switch

}

#This function imports the content of an existing history file, for either use or to verify the format is correct
function Import-LMHistoryFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$FilePath,

        [Parameter(Mandatory=$false)][switch]$AsTest
        )

    begin {

        #region Validate FilePath
        If (!($PSBoundParameters.ContainsKey('FilePath'))){

             try {$HistoryFileCheck = Confirm-LMGlobalVariables}
            catch {throw "Required -FilePath is missing, and `$Global:LMStudioVars is not populated. Please Create or Import a config file"}
           
            $FilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath
        
            }
        #endregion

        #region Import the History file
        try {$HistoryContent = Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
        catch {throw "Unable to import history file $FilePath : $($_.Exception.Message))"}
        #endregion

        #region Validate columns and first entry of the history file:

    }

    process {
    
        $HistoryColumns = (New-LMTemplate -Type HistoryEntry).psobject.Properties.Name
        
        If ($HistoryContent.Count -eq 1){

            $FileColumns = $HistoryContent.psobject.Properties.Name
            $ColumnComparison = Compare-Object -ReferenceObject $HistoryColumns -DifferenceObject $FileColumns

            If ($ColumnComparison.Count -eq 0){$ValidContents = $True}
            If ($ColumnComparison.Count -gt 0){$ValidContents = $False}

        }
        If ($HistoryContent.Count -gt 1){

            $ValidContents = $True

            Foreach ($Entry in $HistoryContent){
                
                $FileColumns = $Entry.psobject.Properties.Name

                $ColumnComparison = Compare-Object -ReferenceObject $HistoryColumns -DifferenceObject $FileColumns

                If ($ColumnComparison.Count -gt 0){$ValidContents = $False}

            }

        }

    #region If not a test, move over content from Fixed-Length arrays to New ArrayLists:
    If (!($AsTest.IsPresent)){
    
        $NewHistory = New-Object System.Collections.ArrayList

        If ($HistoryContent.Count -eq 1){$NewHistory.Add((New-LMTemplate -Type HistoryEntry)) | Out-Null}

        $HistoryContent | ForEach-Object {$NewHistory.Add($_) | Out-Null}
    }
    #endregion

    } #Close Process

    end {
    
        If ($AsTest.IsPresent){return $ValidContents}
        else {return $NewHistory}
    
    }

} #Close Function

#This function reads the contents of a dialog folder, and rebuilds a history file from the contents
function Repair-LMHistoryFile {
    param (
    [Parameter(Mandatory=$False)]
    [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
    [string]$FilePath,

    [Parameter(Mandatory=$False)]
    [switch]$WriteProgress
    )

    begin {
            #region Check history file location in global variables, or use provided FilePath
            If (!($PSBoundParameters.ContainsKey('FilePath'))){
    
            If ((Confirm-LMGlobalVariables -ReturnBoolean) -ne $True){throw "Global:LMStudioVars variables don't seem to be correct."}
        
            $FilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath
            $DirectoryPath = $Global:LMStudioVars.FilePaths.DialogFolderPath
    
            }
            Else {$DirectoryPath = $FilePath.TrimEnd('.index') + "-DialogFiles"}

            If (!(Test-Path $DirectoryPath)){throw "'Dialog files' folder is not valid or accessible ($DirectoryPath)"}
            #endregion

            $DialogFiles = Get-ChildItem -Path $DirectoryPath -File -Filter *.dialog

            If ($DialogFiles.Count -eq 0){throw "Folder $DirectoryPath does not contain any .dialog files"}
    }

    process {

        $Succeeded = 0
        $ImportFailed = 0
        $UpdateFailed = 0
        $FileCount = $DialogFiles.Count
        $CurrentOne = 0

        If (Test-Path $FilePath){Move-Item $FilePath -Destination "$FilePath.old"}

        New-LMTemplate -Type HistoryEntry | ConvertTo-Json | Out-File -FilePath $FilePath

        :dfloop foreach ($File in $DialogFiles){

            $CurrentOne++

            if ($WriteProgress.IsPresent){Write-Progress -Activity "Importing Dialog Files" -Status "$($File.Name)" -PercentComplete ([int](($CurrentOne / $FileCount) * 100))}

            try {$Dialog = Import-LMDialogFile -FilePath ($File.FullName)}
            catch {

                $ImportFailed++
                $FileCount++
                coninue dfloop

            }

            try {$Dialog.Info.Opener = (($Dialog.Messages | Sort-Object TimeStamp) | Where-Object {$_.role -eq "user"})[0].Content}
            catch {
                $UpdateFailed++
                $FileCount++
                continue dfloop
            
            }

            try {Update-LMHistoryFile -FilePath $FilePath -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $($File.FullName))}
            catch {
            
                $UpdateFailed++
                $FileCount++
                continue dfloop

                }

            $Succeeded++

        }

        Write-Progress -Activity "Importing Dialog Files" -Completed

    }

    end {

        if ($Succeeded.Count -eq 0){Write-Error "Repair failed: unable to import any dialog files in $DirectoryPath"}

        ElseIf ($Succeeded.Count -gt 0 -and ($ImportFailed.Count -gt 0 -or $UpdateFailed -gt 0)){

            Write-Warning "Import succeeded: $Succeeded, Import failed: $ImportFailed, History file update failed: $UpdateFailed"

        }
        
        Else {Write-Host "Import succeeded for all $Succeeded files. History File repair complete"}

        Remove-Item "$FilePath.old" -ErrorAction SilentlyContinue

    }

}

#This function saves a history entry to the history file
function Update-LMHistoryFile { #Complete, requires testing
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if ($_.GetType().Name -ne "PSCustomObject"){throw "Expected object of type [pscustomobject]"} else { $true } })]
        [pscustomobject]$Entry,
        
        [Parameter(Mandatory=$False)]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "History file path does not exist" } else { $true } })]
        [string]$FilePath,
        
        [Parameter(Mandatory=$False)]
        [switch]$ReturnAsObject

    )

    begin {

        #region Validate $Entry:
        $StandardFields = (New-LMTemplate -Type HistoryEntry).psobject.Properties.Name

        $EntryFields = $Entry.PSObject.Properties.Name

        $FieldsCheck = Compare-Object -ReferenceObject $StandardFields -DifferenceObject $EntryFields

        If ($FieldsCheck.Count -ne 0){throw "The provided Entry does contain the required fields ($($StandardFields -join ', '))"}
        #endregion

        #region Check history file location in global variables, or use provided FilePath
        If (!($PSBoundParameters.ContainsKey('FilePath'))){
        
            If ((Confirm-LMGlobalVariables -ReturnBoolean) -ne $True){throw "Something went wrong when running Confirm-LMGlobalVariables (didn't return True)"}
        
            $FilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath

             If (!(Test-Path $FilePath)){throw "Provided history file path is not valid or accessible ($FilePath)"}             
    
        }
        #endregion

    }

    process {

        $History = New-Object System.Collections.ArrayList

        try {(Import-LMHistoryFile -FilePath $FilePath) | Foreach-Object {$History.Add($_) | Out-Null}}
        catch {throw "History File import (for write) failed: $($_.Exception.Message)"}

        $MatchingEntries = $History | Where-Object {($_.Created -eq $Entry.Created) -and ($_.FilePath -eq $Entry.FilePath)}

        If ($null -eq $MatchingEntries){$History += $Entry}
        
        Else {

            switch ($MatchingEntries.Count){

                #If there's one matching value, update it in-place:
                {$_ -eq 1}{

                    $Index = $History.IndexOf($MatchingEntries)
                    
                    break

                } #Close Case -eq 1

                #If there's more than one matching value, find the most recent one and remove the old ones
                {$_ -gt 1}{

                    $SortedEntries = $MatchingEntries | Sort-Object Modified -Descending
                    
                    $TargetEntry = $SortedEntries[0]

                    $SortedEntries[1..($SortedEntries.Count - 1)] | ForEach-Object {$History.Remove($_) | out-null}

                    $Index = $History.IndexOf($TargetEntry)

                    break

                } #Close Case -gt 1

                Default {$Index = 0} #PS5/7 difference: PS5 doesn't assign a ".Count" property to most non-array objects, PS7 does. This Default addresses a PS5 behavior
                #Default {throw "[Update-LMHistoryFile] : Something went wrong while trying to find/remove duplicates"}

            } #Close switch

            @("Modified", "Title", "Opener", "Model", "Tags").ForEach({$History[$Index].$_ = $Entry.$_})

        }
       
    } #Close Process

    end {

        #If we have 2+ 'real' entries, we don't need the dummy values anymore to preserve the array structure in JSON:
        If ($History.Where({$_.Created -ne 'dummyvalue'}).Count -ge 2){$History = $History.Where({$_.Created -ne 'dummyvalue'})}

        If (!($ReturnAsObject.IsPresent)){
            try {$History | Sort-Object Modified -Descending | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $FilePath -ErrorAction Stop}
            catch {throw "[Update-LMHistoryFile] : Unable to save history to File Path: $($_.Exception.Message)"}
        }

        Else {return ($History | Sort-Object Modified -Descending)}

    }

}

#This function allows the removal and/or deletion of History Entries and their dialogs
function Remove-LMHistoryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "History file path does not exist" } else { $true } })]
        [string]$FilePath,

        [Parameter(Mandatory=$false)]
        [switch]$BulkRemoval,
    
        [Parameter(Mandatory=$false)]
        [switch]$DeleteDialogFiles
    
    )

    begin {

        #region Check history file location in global variables, or use provided FilePath
        If ((Confirm-LMGlobalVariables -ReturnBoolean) -ne $True){throw "Something went wrong when running Confirm-LMGlobalVariables (didn't return True)"}
        
            $FilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath

             If (!(Test-Path $FilePath)){throw "Provided history file path is not valid or accessible ($FilePath)"}
        #endregion

        #region Import History File as Array List
        $History = New-Object System.Collections.ArrayList

        #Create "Cancel" entry
        $CancelEntry = New-LMTemplate -Type HistoryEntry 
        $CancelEntry.Title = "Select This Entry To Cancel"
        ("Created", "Modified", "Opener","Model","FilePath").ForEach({$CancelEntry.$_ = ""})
        $History.Add($CancelEntry) | Out-Null

        try {Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction stop | Foreach-Object {$History.Add($_) | Out-Null}}
        catch {throw "Couldn't import History File: $($_.Exception.Message)"}
        #endregion

        }

    process {

        switch ($BulkRemoval.IsPresent){

            $True {

                $RemoveEntries = $History | Select-Object @{N="Created"; E={Get-Date ($_.Created)}}, @{N="Modified"; E={Get-Date ($_.Modified)}}, Title, Opener, FilePath, @{N = "Tags"; E = {(($_.Tags) -join ', ') -replace 'dummyvalue, ','' -replace 'dummyvalue',''}} | Out-GridView -Title "Select History Entries for Removal/Deletion" -OutputMode Multiple

                $CancelEntries = $RemoveEntries | Where-Object {$_.Title -eq "Select This Entry To Cancel"}

                If ($CancelEntries.Count -gt 0){return "Cancelled."}

                Foreach ($Entry in $RemoveEntries){

                    $History = $History | Where-Object {$_.FilePath -ne $Entry.FilePath}

                    If ($DeleteDialogFiles.IsPresent){

                        $DialogFilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath.TrimEnd('.index') + ($Entry.FilePath)

                        If (Test-Path $DialogFilePath){Remove-Item -Path $DialogFilePath -Confirm:$true} #side of caution                        
                    }

                }

            }

            $False {

                $Entry = $History | Out-GridView -Title "Select History Entry for Removal/Deletion" -OutputMode Single

                If ($Entry.Title -eq "Select This Entry To Cancel"){return "Cancelled."}
                $History.Remove($Entry) | Out-Null

                If ($DeleteDialogFiles.IsPresent){

                    $DialogFilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath.TrimEnd('.index') + ($Entry.FilePath)

                    If (Test-Path $DialogFilePath){Remove-Item -Path $DialogFilePath -Confirm:$true} #side of caution                        
                }
            }


        }
    }

    end {

        $History = $History | Where-Object {$_.Title -ne "Select This Entry To Cancel"}
        
        try {$History | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File -FilePath $Global:LMStudioVars.FilePaths.HistoryFilePath -ErrorAction Stop}
        catch {throw "Unable to save History file modifications: $($_.Exception.Message)"}

    }

}

#$This function imports a dialog file, converts it to a non-fixed sized format [array => arraylist], and then returns it
function Import-LMDialogFile {
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({ if (!(Test-Path -Path $_)) { throw "Dialog file path does not exist" } else { $true } })]
    [string]$FilePath,

    [Parameter(Mandatory=$false)][switch]$AsTest
    )

begin {

    $DialogTemplate = New-LMTemplate -Type ChatDialog

    try {$Dialog = Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop}
    catch {throw "Unable to read $FilePath : $($_.Exception.Message)"}

}

process { 
    
    $IsValid = $True

    #A fancier way of "hard coding" property paths
    $TemplateKeys = @("Info")

    $BadKeys = New-Object System.Collections.ArrayList

    foreach ($Key in $TemplateKeys){
       
        switch ($DialogTemplate.$Key.GetType().Name){

            {$_ -eq "ArrayList"}{$KeyProperties = ($DialogTemplate.$Key | Get-Member -MemberType NoteProperty).Name}
            {$_ -eq "HashTable"}{$KeyProperties = $DialogTemplate.$Key.GetEnumerator().Name}

        }

        :ploop Foreach ($Property in $KeyProperties){
            
            If ($DialogTemplate.$Key.$Property.GetType().Name -imatch 'Array|hash'){continue ploop} #Check these in a second loop

            If ($null -eq $Dialog.$Key.$Property){
                
                $IsValid = $False; 
                $BadKeys.Add("$Key.$Property") | Out-Null
                continue ploop
            
            }
            Else {$DialogTemplate.$Key.$Property = $Dialog.$Key.$Property}

        }

    }
    
    $DialogTemplate.Messages = New-Object System.Collections.ArrayList
    Foreach ($Message in $Dialog.Messages){$DialogTemplate.Messages.Add($Message) | out-null}

    $DialogTemplate.Info.Tags = New-Object System.Collections.ArrayList
    Foreach ($Tag in $Dialog.Info.Tags){$DialogTemplate.Info.Tags.Add($Tag) | out-null}
}

end {

    switch ($AsTest.IsPresent){

        $True {return ([boolean]$IsValid)}

        $False {

            If ($IsValid){return $DialogTemplate}
            Else {throw "Missing values in keys: $($BadKeys -join '; ')"}

        }

    }

}

}

#This function retrieves the model information from the server.
#It can also be used as a connection test with the -AsTest parameter
function Get-LMModel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Server,
        
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [switch]$AsTest

    )

    If (!($PSBoundParameters.ContainsKey('Server')) -or !($PSBoundParameters.ContainsKey('Port'))){

        try {$VariablesCheck = Confirm-LMGlobalVariables}
        catch {
                throw "Required variables (Server, Port) are missing, and `$Global:LMStudioVars is not populated. Please run Import-LMConfig"
    
            }

        $Server = $Global:LMStudioVars.ServerInfo.Server
        $Port = $Global:LMStudioVars.ServerInfo.Port

    }
    #region Check LMStudioServer values
       
    [string]$EndPoint = $Server + ":" + $Port
    $ModelURI = "http://$EndPoint/v1/models"
    
    try {

        $ModelData = Invoke-RestMethod -Uri $ModelURI -ErrorAction Stop
        $TestResult = $True

    }
    catch {
        
        $TestResult = $False
        If (!($AsTest.IsPresent)){throw "Unable to retrieve model information: $($_.Exception.Message)"}
    
    }

    If ($TestResult){
        $Model = $ModelData.data.id
        If ($Model.Length -eq 0 -or $null -eq $Model.Length){throw "`$Model.data.id is empty."}
    } #Close if TestResult true

    switch ($AsTest.IsPresent){

        $True {return $TestResult}

        $False {return $Model}

    }

}

#Searches the HistoryFile for strings and provides multiple ways to output the contents
function Search-LMChatDialog { #Started, ways to go
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateSet('Any','All','Exact')]
    [string]$Match,

    [Parameter(Mandatory=$true)]
    [ValidateScript({ if ($_.GetType().Name -ne "String" -and $_.GetType().BaseType.Name -ne "Array") { throw "'-SearchTerms' parameter type must be a string or an array" } else { $true } })]
    $SearchTerms,

    [Parameter(Mandatory=$False)]
    [ValidateSet('Assistant','User','All')]
    [string]$SearchScope = "All",

    [Parameter(Mandatory=$False)]
    [ValidateScript({ if (!(Test-Path -Path $_)) { throw "History file path does not exist" } else { $true } })]
    [string]$SaveAs,

    [Parameter(Mandatory=$false)]
    [ValidateScript({ if ($_.GetType().Name -ne "DateTime" -and (try {$ConvToBDate = Get-Date "$_" -ErrorAction Stop; return $true} catch {return $false}) -eq $False) { throw "'-Before' parameter is not a valid date" } else { $true } })]
    $BeforeDate,

    [Parameter(Mandatory=$false)]
    [ValidateScript({ if ($_.GetType().Name -ne "DateTime" -and (try {$ConvToADate = Get-Date "$_" -ErrorAction Stop; return $true} catch {return $false}) -eq $False) { throw "'-After' parameter is not a valid date" } else { $true } })]
    $AfterDate,

    [Parameter(Mandatory=$false)]
    [int]$PriorContext = 0,

    [Parameter(Mandatory=$false)]
    [int]$LatterContext = 0,
    
    [Parameter(Mandatory=$false)]
    [int]$ResultSetSize = 0,

    [Parameter(Mandatory=$False)]
    [ValidateScript({ if (!(Test-Path -Path $_)) { throw "History file path does not exist" } else { $true } })]
    [string]$FilePath,

    [Parameter(Mandatory=$false)]
    [switch]$WriteProgress,

    [Parameter(Mandatory=$false)]
    [switch]$ShowAsCapitalLetters

)
begin {
    If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}

    If (!($PSBoundParameters.ContainsKey('FilePath'))){
        
        $FilePath = $Global:LMStudioVars.FilePaths.HistoryFilePath
        $DirectoryPath = $Global:LMStudioVars.FilePaths.DialogFolderPath

    }
    Else {$DirectoryPath = $FilePath.TrimEnd('.index') + "-DialogFiles"}

    try {$RootFolder = (Get-Item $FilePath -ErrorAction Stop).Directory.FullName}
    catch {throw "History file error: $($_.Exception.Message)"}

    try {$History = Import-LMHistoryFile -FilePath $FilePath}
    catch {throw "Unable to import history file [$FilePath]"}

    If (!(Test-Path $DirectoryPath)){throw "Dialog Files folder doesn't exist [$DirectoryPath]"}
    
}

process {

    $Results = New-Object System.Collections.ArrayList

    :dialogloop Foreach ($Entry in $History){

        $DialogFilePath = $RootFolder + '\' + ($Entry.FilePath)

        try {$Dialog = Import-LMDialogFile -FilePath $DialogFilePath}
        catch {
            Write-Warning "Failed to import $($Entry.FilePath)"
            continue dialogloop
            
        }

        #06/23/2024: LEFT OFF HERE


    }

}

end {}

}

#This function invokes Windows Forms Open and SaveAs for files:
function Invoke-LMSaveOrOpenUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('Save','Open')]
        [string]$Action,
                
        [Parameter(Mandatory=$true)]
        [ValidateSet('cfg', 'dialog','greeting', 'index')]
        [string]$Extension,
        
        [Parameter(Mandatory=$false)]
        [string]$StartPath,
        
        [Parameter(Mandatory=$false)]
        [string]$FileName

    )

    begin {

        try {Add-Type -AssemblyName PresentationCore,PresentationFramework,System.Windows.Forms -ErrorAction Stop}
        catch {throw "Unable to load UI assemblies"}

        If ($null -eq $StartPath -or $StartPath.Length -eq 0 -or (!(Test-Path $StartPath))){
         
            If (Test-Path "$Env:USERPROFILE\Documents\LMStudio-PSClient"){$StartPath = "$Env:USERPROFILE\Documents\LMStudio-PSClient"}
            Else {$StartPath = "$Env:USERPROFILE\Documents"}

        }

        #If the filename extension doesn't match what I require:
        If ($null -ne $FileName -and $FileName.Length -gt 0){
         
            $SplitFileName = $FileName.Split('.')

            If ($SplitFileName.Count -eq 1){$FileName = $FileName + ".$Extension"}
            Else {

                $SplitFileName[$SplitFileName.GetUpperBound(0)] = $Extension

                $FileName = $SplitFileName -join '.'

            }

            $FileNameSpecified = $True

        }
        Else {$FileNameSpecified = $False}

        switch ($Extension){

            {$_ -ieq 'cfg'}{
                
                $Title = "$Action Configuration"
                $Filter = "Config File (*.cfg)|*.cfg"

                If (!($FileNameSpecified)){$FileName = "lmsc.cfg"}
            
            }

            {$_ -ieq 'dialog'}{
                $Title = "$Action Dialog"
                $Filter = "Dialog File (*.dialog)|*.dialog"

                If (!($FileNameSpecified)){$FileName = "$(get-date -format 'MMddyyyy_hhmm')_lmchat.dialog"}
            }

            {$_ -ieq 'greeting'}{
                $Title = "$Action Greetings"
                $Filter = "Greeting File (*.greeting)|*.greeting"

                If (!($FileNameSpecified)){$FileName = "hello.greeting"}

            }

            {$_ -ieq 'index'}{
                $Title = "$Action History File"
                $Filter = "History File (*.index)|*.index"
                
                If (!($FileNameSpecified)){$FileName = "$($env:USERNAME)-HF.index"}
            }
        }
    }
    process {

        switch ($Action){

            {$_ -eq "Save"}{

                $UI = New-Object System.Windows.Forms.SaveFileDialog

            }

            {$_ -eq "Open"}{

                $UI = New-Object System.Windows.Forms.OpenFileDialog

            }

        }

        $UI.Title = $Title        
        $UI.InitialDirectory = $StartPath
        $UI.Filter = $Filter
        $UI.FileName = $FileName

        $UIResult = $UI.ShowDialog()

    }

    end {

        switch ($UIResult){

            {$_ -eq "Cancel"}{throw "User canceled $Action prompt"}

            {$_ -eq "OK"}{return $UI.FileName}

        }

    }

}

#This function invokes Windows Forms Open, for selecting a directory path:
function Invoke-LMOpenFolderUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$StartPath

    )

    begin {

        try {Add-Type -AssemblyName PresentationCore,PresentationFramework,System.Windows.Forms -ErrorAction Stop}
        catch {throw "Unable to load UI assemblies"}

        If ($null -eq $StartPath -or $StartPath.Length -eq 0 -or (!(Test-Path $StartPath))){
         
            If (Test-Path "$Env:USERPROFILE\Documents\LMStudio-PSClient"){$StartPath = "$Env:USERPROFILE\Documents\LMStudio-PSClient"}
            Else {$StartPath = "$Env:USERPROFILE\Documents"}

        }

    }
    process {

        $UI = New-Object System.Windows.Forms.FolderBrowserDialog

        $UI.InitialDirectory = $StartPath
        $UIResult = $UI.ShowDialog()

    }

    end {

        switch ($UIResult){

            {$_ -eq "Cancel"}{throw "Folder selection cancelled"}

            {$_ -eq "OK"}{return $UI.SelectedPath}

        }

    }

}

#Provides a graphical help interface for the LM-Client
function Show-LMHelp { #Complete
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = “LMStudio-PSClient Help”
$Messageboxbody = @'
SWITCHES
:help   - Displays this Help
:priv   - Enables Privacy Mode
:show   - Shows the current Chat Settings
:quit   - Quits the application
:selp   - Select a System Prompt
:tags   - Show Tags

STRINGS
:newp <[str]>   - Create a System Prompt
:atag <[str]>   - Add a Tag     (comma-separate 2+)
:rtag <[str]>   - Remove a Tag  (comma-separate 2+)

TOGGLES
:gret <true or false>   - Toggles start-up Greeting
:strm <true or false>   - Toggles response Streaming
:save <true or false>   - Toggles Save prompt on launch
:mark <true or false>   - Toggles Markdown rendering

NUMBERS
:cond <[int] of 2 or greater>   - Sets the Context Depth
:mtok <[int] of -1 or greater>  - Sets the Maximum Tokens
:temp <0.0 to 2.0>   - Sets the Temperature

'@
    
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

}

#provides a graphical display of the Client chat settings
function Show-LMSettings { #Complete
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = “LMStudio-PSClient Settings”
$Messageboxbody = @"
SERVER INFORMATION
Server: $($Global:LMStudioVars.ServerInfo.Server)
Port: $($Global:LMStudioVars.ServerInfo.Port)

CHAT SETTINGS
Temperature (0.0 - 2.0):         $($Global:LMStudioVars.ChatSettings.temperature)
Max Tokens (-1 or above):      $($Global:LMStudioVars.ChatSettings.max_tokens)
Context Depth:                        $($Global:LMStudioVars.ChatSettings.ContextDepth)
Interpret Markdown:               $($Global:LMStudioVars.ChatSettings.Markdown)
Stream Console Output:          $($Global:LMStudioVars.ChatSettings.stream)

Prompt for Initial Save:            $($Global:LMStudioVars.ChatSettings.SavePrompt)
Greeting on Start:                     $($Global:LMStudioVars.ChatSettings.Greeting)

System Prompt:
$($Global:LMStudioVars.ChatSettings.SystemPrompt)

"@
    
    $MessageIcon = [System.Windows.MessageBoxImage]::Information
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$MessageIcon)

}
#This function generates a greeting prompt for an LLM, for load in the LMChatClient
function New-LMGreetingPrompt { #Complete
    
    ###FEATURE TO INCLUDE HERE: RETURN A SYSTEM PROMPT
    $Premises = @(
        "Talk like a pirate",
        "Talk like a valley girl",
        "Talk like Arnold Schwarzenegger",
        "Talk like you're porky pig",
        "Talk like you have severe social anxiety",
        "Talk like you're Goofy",
        "Talk like you're Jeremy Clarkson"
    )

    $ChosenPremise = $Premises[$(Get-Random -Minimum 0 -Maximum $($Premises.GetUpperBound(0)) -SetSeed ([System.Environment]::TickCount))]

    $TodayIsADay = "It is $((Get-Date).DayOfWeek)"
    
    $TokenSet = @{U = [Char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZ'}
        
    $ThreeLetters = (Get-Random -Count 3 -InputObject $TokenSet.U -SetSeed ([System.Environment]::TickCount)) -join ', '

    $Greetings = @(
        "$ChosenPremise. Chose an adjective that contains these three letters: $ThreeLetters. Then use it to insult me in a short way without hurting my feelings too much.",
        "$ChosenPremise. Please greet me in a unique and fun way!",
        "$ChosenPremise. Choose a proper noun that contains these three letters: $ThreeLetters. Then provide a fact about the chosen proper noun.",
        "$ChosenPremise. Please try to baffle me.",
        "$ChosenPremise. Choose a proper noun that contains these three letters: $ThreeLetters. Then generate a haiku that includes this word.",
        "$ChosenPremise. Choose a proper noun that contains these three letters: $ThreeLetters. Please generate a short poem about this word."
        "$ChosenPremise. Please wish me well for today."
    )
    
    $ChosenGreeting = $Greetings[$(Get-Random -Minimum 0 -Maximum $($Greetings.GetUpperBound(0)) -SetSeed ([System.Environment]::TickCount))]

    return $ChosenGreeting

} #Close Function

#This function invokes a synchronous connection to "blob" chat output to the console
function Invoke-LMBlob { 
    param (
        [Parameter(Mandatory=$true)][string]$CompletionURI,
        [Parameter(Mandatory=$true)][pscustomobject]$Body,
        [Parameter(Mandatory=$False)][switch]$NoConsoleOut,
        [Parameter(Mandatory=$False)][switch]$StreamSim
        )

        $Body.stream = $False #So there's no ambiguity

        try {$Output = Invoke-restmethod -Uri $CompletionURI -Method POST -Body ($Body | convertto-json -depth 4) -ContentType "application/json"}
        catch {throw $_.Exception.Message}

        if ($null -eq ($Output.choices[0].message.content)){throw "Webserver response did not contain the expected data: property 'choices[0].message.content' is empty"}
        $Response = $Output.choices[0].message.content

        If (!($NoConsoleOut.IsPresent)){

            switch ($StreamSim.IsPresent){

                $True {$Response.Split(' ').ForEach({Write-Host "$_ " -NoNewline; start-sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 20)})}

                $False {Write-Host "$Response" -NoNewline}

            }
            
            Write-Host ""

        }

        return $Response
}

#This function establishes an asynchronous connection to "stream" chat output to the console
function Invoke-LMStream { #Complete
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
    catch {
    
        #$JobOutput.Close() Dispose closes, apparently
        $jobOutput.Dispose()
        return "HALT: ERROR File is not readable"
    
    }
    #$JobOutput.Close() See above
    $jobOutput.Dispose()
    
    Remove-Variable jobOutput -ErrorAction SilentlyContinue
    Remove-Variable StreamSession -ErrorAction SilentlyContinue
    [gc]::Collect()

    } #Close $StreamJob
    
    #Send the right parameters to let the old C# code run:
    $PSVersion = "$($PSVersionTable.PSVersion.Major)" + '.' + "$($PSVersionTable.PSVersion.Minor)"

    if ($PSVersion -match "5.1"){$RunningJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)}
    elseif ($PSVersion -match "7.") {$RunningJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File) -PSVersion 5.1}
    else {throw "PSVersion $PSVersion doesn't match 5.1 or 7.x"}

    $KillProcedure = {
            
        if (!($KeepJob.IsPresent)){Stop-Job -Id ($RunningJob.id) -ErrorAction SilentlyContinue; Remove-job -Id ($RunningJob.Id) -ErrorAction SilentlyContinue}
        If (!($KeepFile.IsPresent)){Remove-Item $File -Force -ErrorAction SilentlyContinue}

    }

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
    
        $jobOutput = Receive-Job $RunningJob
        
        :oloop foreach ($Line in $jobOutput){
    
            If ($Fragmented){ #Added this to try to reassemble fragments, troubleshooting 05/14
                    $Line = "$Fragment" + "$Line"
                    Remove-Variable Fragment -ErrorAction SilentlyContinue
                    
                    If ($Line.TrimEnd().SubString($($Line.TrimEnd().Length - 1),1) -ne '}'){break oloop}
                    $Fragmented = $False
            }
    
            switch ($Line){
                {$_ -notmatch 'data: '}{continue oloop}
    
                {$_.Length -eq 0}{continue oloop}
                
                {$_  -cmatch 'ERROR!?!|"STOP!?! Cancel Detected'}{
                    
                    &$KillProcedure
                    throw "Exception: $($Line -replace 'ERROR!?!' -replace '"STOP!?! Cancel Detected')"
                    $Complete = $True
    
                }
    
                {$_ -match 'data: [DONE]'}{
    
                    $Complete = $True
                    break oloop
                }
    
                {$_ -match 'data: {'}{
                    try {$LineAsObj = ($Line.TrimStart("data: ")) | ConvertFrom-Json -ErrorAction Stop}
                    catch {
                           $Fragment = $Line
                           $Fragmented = $True
                            continue oloop #Fixed this, was "break"
                    }
                    
                    If ($LineAsObj.id.Length -eq 0){continue oloop}
        
                    $Word = $LineAsObj.choices.delta.content
                    Write-Host "$Word" -NoNewline
                    $MessageBuffer += $Word
                    #If ($Fragmented){Start-sleep -Milliseconds 100} #Testing "metering" output
        
                    If ($null -ne $LineAsObj.choices.finish_reason){
                        Write-Host ""
                        #Write-Verbose "Finish reason: $($LineAsObj.choices.finish_reason)" -Verbose
                        $Complete = $True
                        break oloop
                    }
    
                }
    
            }
    
        }
    
        Start-Sleep -Milliseconds 30 #06/15 - Experimenting with ways to reduce CPU demand
    }
    until ($Complete -eq $True)

} #Close Process

end {

    If (!($Interrupted)){
        
        &$KillProcedure
        [gc]::Collect()
        return $MessageBuffer
    }
    Else {return "[stream_interrupted]"}

    Write-Host ""

} #Close End

} #Close function

#This function initiates a "greeting"
function Get-LMGreeting {
    [CmdletBinding(DefaultParameterSetName="Auto")]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='Settings')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [hashtable]$Settings,
        
        [Parameter(Mandatory=$false, ParameterSetName='Settings')]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "Greeting file path does not exist" } else { $true } })]
        [string]$GreetingFile

        )

begin {

    #region Evaluate and set Variables
    switch (($PSBoundParameters.ContainsKey('Settings'))){

        $False {
            If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}
            
            $Server = $Global:LMStudioVars.ServerInfo.Server
            $Port = $Global:LMStudioVars.ServerInfo.Port
            $Endpoint = $Global:LMStudioVars.ServerInfo.Endpoint
            $GreetingFile = $global:LMStudioVars.FilePaths.GreetingFilePath
            $StreamCachePath = $Global:LMStudioVars.FilePaths.StreamCachePath
            $UseGreetingFile = ([boolean](Test-Path -Path $GreetingFile))
            $Stream = $Global:LMStudioVars.ChatSettings.stream
            $Temperature = $Global:LMStudioVars.ChatSettings.temperature
            $MaxTokens = $Global:LMStudioVars.ChatSettings.max_tokens
            $CompletionURI = $Global:LMStudioVars.URIs.CompletionURI
            $ContextDepth = $Global:LMStudioVars.ChatSettings.ContextDepth
            $MarkDown = $Global:LMStudioVars.ChatSettings.MarkDown
            $ShowSavePrompt = $Global:LMStudioVars.ChatSettings.SavePrompt
            $SystemPrompt = $Global:LMStudioVars.ChatSettings.SystemPrompt

        }

        $True {
            #region Validate Settings
            #region Validate Settings structure
            $SettingsFields = (New-LMTemplate -Type ManualSettings).GetEnumerator().Name
            try {$ProvidedFields =$Settings.GetEnumerator().Name}
            catch {throw "[Get-LMResponse] -Settings object is missing requisite properties and methods"}

            $FieldComparison = Compare-Object -ReferenceObject $SettingsFields -DifferenceObject $ProvidedFields

            If ($FieldComparison.Count -gt 0){throw "[Get-LMResponse] properties on -Settings object is missing properties ($($FieldComparison.InputObject -join ', '))"}
            #endregion

            #region Evaluate the provided settings
            $Warnings = New-Object System.Collections.ArrayList
            #endregion

            #region Check Server
            If ($Null -eq $Settings.server -or $Settings.server.Length -eq 0){$Errors.Add("Server is null or empty") | Out-Null}
            #endregion

            #region Check Port
            If ($Null -eq $Settings.port -or $Settings.port.Length -eq 0){$Errors.Add("Port is null or empty") | Out-Null}
            Else {
            
                try {$PortAsInt = [int]$Settings.port}
                catch {throw "Port is not convertable to integer"}
                
                If ($PortAsInt -le 0 -or $PortAsInt -gt 65535){
                    throw "Port not 1-65536 ($($PortAsInt))"
                }
            }
            #endregion

            #region Check Max_Tokens
            If ($Settings.max_tokens.Length -eq 0 -or $null -eq $Settings.max_tokens){
                $Settings.max_tokens = -1
                $Warnings.Add("Max_Tokens is null or empty") | Out-Null
            }
            Else {
            
                try {$TokensAsInt = [int]$Settings.max_tokens}
                catch {
                    $Warnings.Add("Port is not convertable to integer") | Out-Null
                    $Settings.max_tokens = -1
                    continue
                }
                
                If ($TokensAsInt -le -2){
                    $Warnings.Add("Max_Tokens is less than or equal to -2 ($($TokensAsIntAsInt))")
                    $Settings.max_tokens = -1
                }
            }
            #endregion

            #region Check ContextDepth
            If ($Settings.ContextDepth.Length -eq 0 -or $null -eq $Settings.ContextDepth){
                $Settings.ContextDepth = 10
                $Warnings.Add("ContextDepth is null or empty") | Out-Null
            }
            Else {
            
                try {$ContextDepthAsInt = [int]$Settings.ContextDepth}
                catch {
                    $Warnings.Add("ContextDepth is not convertable to integer") | Out-Null
                    $Settings.ContextDepth = 10
                    continue
                }
                
                If ($ContextDepthAsInt -le 0){
                    $Warnings.Add("ContextDepth is less than or equal to 0 ($($TokensAsIntAsInt))")
                    $Settings.ContextDepth = 10
                }
            }
            #endregion
            
            #region Check Temperature
            If ($Settings.temperature.Length -eq 0 -or $null -eq $Settings.temperature){
                $Settings.temperature = 0.7
                $Warnings.Add("Temperature is null or empty") | Out-Null
            }
            Else {
            
                try {$TempAsDouble = [system.math]::Round([double]$Settings.temperature, 1)}
                catch {
                    $Warnings.Add("Temperature isn't convertable to a double") | Out-Null
                    $Settings.temperature = 0.7
                    continue
                }
                
                If ($TempAsDouble -lt 0 -or $TempAsDouble -gt 2){
                    $Warnings.Add("Temperature isn't in a range of 0-2 ($($TempAsDouble))")
                    $Settings.temperature = 0.7
                }
            }
            #endregion

            #region Check System Prompt
            If ($Settings.SystemPrompt.Length -eq 0 -or $null -eq $Settings.SystemPrompt){
                $Settings.SystemPrompt = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
                $Warnings.Add("System Prompt is null or empty") | Out-Null
            }
            #endregion

            #region Check Stream
            If ($Settings.stream.GetType().Name -ne "Boolean"){$Warnings.Add("Stream value is not boolean")}
            #endregion

            #region Check Markdown
            If ($Settings.Markdown.GetType().Name -ne "Boolean"){$Warnings.Add("Markdown value is not boolean")}
            #endregion
            #endregion Validate Settings

            #region Set Variables
            $UseGreetingFile = $PSBoundParameters.ContainsKey('GreetingFile')
            $StreamCachePath = (Get-Location).Path + '\lmstream.cache'
            $Stream = $Settings.stream
            $Temperature = $Settings.temperature
            $MaxTokens = $Settings.max_tokens
            $Server = $Settings.server
            $Port = $Settings.port
            $Endpoint = "$Server" + ":" + "$Port"
            $CompletionURI = "http://$Endpoint/v1/chat/completions"
            $ContextDepth = $Settings.ContextDepth
            $MarkDown = $Settings.markdown
            $ShowSavePrompt = $True
            $SystemPrompt = $Settings.SystemPrompt
            #endregion Set Variables
        }
    
    }
    #endregion

    #region Load or create greeting file
    If ($UseGreetingFile){

        try {$GreetingData = Import-csv $GreetingFile -ErrorAction Stop}
        catch {
            $UseGreetingFile = $False
            $GreetingData = New-LMTemplate -Type ChatGreeting
            $NewFile = $True

            }
    }
    Else {
            $GreetingData = New-LMTemplate -Type ChatGreeting
            $NewFile = $True
  
    }
   #endregion
 
}

process {
    
    #region Get the model and prep the body
    try {$Model = Get-LMModel -Server $Server -Port $Port}
    catch {throw $_.Exception.Message}

    $GreetingPrompt = New-LMGreetingPrompt
    
    $Body = New-LMTemplate -Type Body
    $Body.model = $Model
    $Body.temperature = $Temperature
    $Body.max_tokens =  $MaxTokens
    $Body.Stream = $Stream
    $Body.messages[0].content = $SystemPrompt
    $Body.messages[1].content = $GreetingPrompt
    #endregion

    #region Provision the greeting file, even if we don't save it ($UseGreetingFile)
    If ($NewFile){

        $GreetingData[0].TimeStamp = (Get-Date).ToString()
        $GreetingData[0].System = $Body.messages[0].content
        $GreetingData[0].User = $Body.messages[1].content
        $GreetingData[0].Model = "$Model"        
        $GreetingData[0].Temperature = $Temperature
        $GreetingData[0].Max_Tokens = $MaxTokens
        $GreetingData[0].Stream = $Stream
        $GreetingData[0].ContextDepth = $ContextDepth

    }

    Else { 

        #region Create a new entry to append to existing greeting file:
        $GreetingEntry = New-LMTemplate -Type ChatGreeting

        $GreetingEntry.TimeStamp = (Get-Date).ToString()
        $GreetingEntry.System = $Body.messages[0].content
        $GreetingEntry.User = $Body.messages[1].content
        $GreetingEntry.Model = "$Model"        
        $GreetingEntry.Temperature = $Temperature
        $GreetingEntry.Max_Tokens = $MaxTokens
        $GreetingEntry.Stream = $Stream
        $GreetingEntry.ContextDepth = $ContextDepth
        #endregion

    }

    #region Put the previous requests in Q/A order:
    $ContextEntries = $GreetingData | Select-Object -Last ([int]($ContextDepth / 2))

    $ContextMessages = New-Object System.Collections.ArrayList
    
    $ContextMessages.Add([pscustomobject]@{"role" = "system"; "content" = "$($Body.messages[0].content)"}) | Out-Null

    Foreach ($Entry in $ContextEntries){

        $ContextMessages.Add([pscustomobject]@{"role" = "user"; "content" = "$($Entry.User)"})  | Out-Null
        $ContextMessages.Add([pscustomobject]@{"role" = "assistant"; "content" = "$($Entry.Assistant)"})  | Out-Null

    }

    $ContextMessages.Add([pscustomobject]@{"role" = "user"; "content" = "$($Body.messages[1].content)"})  | Out-Null

    $Body.messages = $ContextMessages
    #endregion

    #endregion

    Write-Host "You: " -ForegroundColor Green -NoNewline; Write-Host "$GreetingPrompt"
    Write-Host ""
    Write-Host "AI: " -ForegroundColor Magenta -NoNewline
    
    switch ($Stream){

        $True {$ServerResponse = Invoke-LMStream -CompletionURI $CompletionURI -Body $Body -File $StreamCachePath}
        $False {$ServerResponse = Invoke-LMBlob -CompletionURI $CompletionURI -Body $Body -StreamSim}
    }

    $ContextMessages.Add([pscustomobject]@{"role" = "assistant"; "content" = "$ServerResponse"})  | Out-Null

    #Write response out as markdown
    If ($MarkDown){Show-LMDialog -DialogMessages ($ContextMessages | Select-Object -Last 2) -AsMarkdown}
    Else {Write-Host ""}
}

end {

    If ($UseGreetingFile){

        If ($NewFile){

            $GreetingData[0].Assistant = "$ServerResponse"

            try {$GreetingData | Export-Csv -Path $GreetingFile -NoTypeInformation -ErrorAction Stop}
            catch {Write-Warning "Unable to save greeting file."}

        }

        Else {

            $GreetingEntry.Assistant = "$ServerResponse"

            try {$GreetingEntry | Export-csv -Path $GreetingFile -Append -NoTypeInformation -ErrorAction Stop}
            catch {Write-Warning "Unable to save greeting file."}

            }

        } #Close If UseGreetingFile

    }

}

#This function presents a selection prompt (Out-Gridview) for the system prompt
function Select-LMSystemPrompt {
    [CmdletBinding(DefaultParameterSetName="Set")]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='Set')]
        [switch]$Pin,
        
        [Parameter(Mandatory=$false, ParameterSetName='Return')]
        [Parameter(Mandatory=$false, ParameterSetName='Bulk')]
            [switch]$AsObject,
        
            [Parameter(Mandatory=$true, ParameterSetName='Bulk')]
                [switch]$Bulk
    )

    #region Prereqs
    If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded. Run [Import-ConfigFile] to load them"}
    Else {$SysPromptFile = $global:LMStudioVars.FilePaths.SystemPromptPath}

    try {$SystemPrompts = Import-Csv $SysPromptFile -ErrorAction Stop}
    catch {throw "Unable to import system.prompts file [$SysPromptFile]"}

    $SystemPrompts += ([pscustomobject]@{"Name"="Cancel"; "Prompt"="Select this prompt to cancel"})
    #endregion

    #region <None> and -Pin
    switch ($AsObject.IsPresent){

        $True {

                switch ($Bulk.IsPresent){

                    $True {$SelectedPrompt = $SystemPrompts | Out-GridView -Title "Please Select a Prompt" -OutputMode Multiple}
        
                    $False {$SelectedPrompt = $SystemPrompts | Out-GridView -Title "Please Select a Prompt" -OutputMode Single}
        
                }
                
                If ($SelectedPrompt.Name -eq 'Cancel' -or $SelectedPrompt -contains 'Cancel' -or $null -eq $SelectedPrompt){throw "System Prompt selection cancelled"}
                
                return $SelectedPrompt

        }

        $False {
            
                $SelectedPrompt = $SystemPrompts | Out-GridView -Title "Please Select a Prompt" -OutputMode Single

                # This isn't generic error checking: $SelectedPrompt really does return null
                If ($SelectedPrompt.Name -eq 'Cancel' -or $null -eq $SelectedPrompt){throw "System Prompt selection cancelled"}
            
                    switch ($Pin.IsPresent){
                    
                        $True {Set-LMConfigOptions -Branch ChatSettings -Options @{"SystemPrompt"=$($SelectedPrompt.Prompt)} -Commit}
                
                        $False {Set-LMConfigOptions -Branch ChatSettings -Options @{"SystemPrompt"=$($SelectedPrompt.Prompt)}}
                
                    }

        }

    }
    #endregion

}

#This function allows you to add or remove system prompt entries
function Edit-LMSystemPrompt {
    [CmdletBinding(DefaultParameterSetName="Auto")]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [switch]$Add,
        [Parameter(Mandatory=$false, ParameterSetName='Remove')]
        [switch]$Remove,
        [Parameter(Mandatory=$false, ParameterSetName='Remove')]
        [switch]$Bulk,
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Name,
        [Parameter(Mandatory=$false, ParameterSetName='Add')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Prompt
    )
    begin {

        If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded. Run [Import-ConfigFile] to load them"}
        Else {$SysPromptFile = $global:LMStudioVars.FilePaths.SystemPromptPath}
    
        if (!(Test-Path $Global:LMStudioVars.FilePaths.SystemPromptPath)){throw "System prompt file does not exist [$($Global:LMStudioVars.FilePaths.SystemPromptPath)]"}

        If (!($Add.IsPresent) -and !($Remove.IsPresent)){throw "You must specify -Add or -Remove"}

        try {$SystemPrompts = Import-Csv $SysPromptFile -ErrorAction Stop}
        catch {throw "Unable to import system.prompts file [$SysPromptFile]"}

    }

    process {
        
        If ($Add.IsPresent){

            If (!$PSBoundParameters.ContainsKey('Name')){

                $Name = Read-Host "Please enter a Name"

                if ($null -eq $Name -or $Name.Length -eq 0){throw "Invalid name provided"}

            }

            If (!$PSBoundParameters.ContainsKey('Prompt')){

                $Prompt = Read-Host "Please enter a Prompt"

                if ($null -eq $Prompt -or $Prompt.Length -eq 0){throw "Invalid prompt provided"}

            }

            $SystemPrompts += ([pscustomobject]@{"Name" = $Name; "Prompt" = $Prompt})

        }

        if ($Remove.IsPresent){

            switch ($Bulk.IsPresent){

                $True {
                    try {$RemovePrompts = Select-LMSystemPrompt -AsObject -Bulk}
                    catch {throw $_.Exception.Message}
                       
                    $PromptGroups = $RemovePrompts | Group-Object Name,Prompt

                    Foreach ($Group in $PromptGroups){

                        $PromptObj = $Group.Group[0]
                        $PromptName = $PromptObj.Name
                        $PromptBody = $PromptObj.Prompt

                        $MatchingPrompts = $SystemPrompts | Where-Object {$_.Name -eq $PromptName -and $_.Prompt -eq $PromptBody}

                        $SystemPrompts = $SystemPrompts | Where-Object {$_.Name -ne $PromptName -and $_.Prompt -ne $PromptBody}

                        $PromptsToPutBack = $MatchingPrompts.Count - $Group.Count

                        If ($PromptsToPutBack -ge 1){ (0..($PromptsToPutBack - 1)) | ForEach-Object {$SystemPrompts += $PromptObj} }

                    }

                }

                $False {

                    try {$RemovePrompt = Select-LMSystemPrompt -AsObject}
                    catch {throw $_.Exception.Message}

                    $PromptName = $RemovePrompt.Name
                    $PromptBody = $RemovePrompt.Prompt

                    $PromptsToPutBack = ($SystemPrompts | Where-Object {$_.Name -eq $PromptName -and $_.Prompt -eq $PromptBody}).Count

                    $SystemPrompts = $SystemPrompts | Where-Object {$_.Name -ne $PromptName -and $_.Prompt -ne $PromptBody}

                    If ($PromptsToPutBack -gt 1){$SystemPrompts += $RemovePrompt}

                }

            }

        }

    }

    end {

        try {$SystemPrompts | Export-csv -Path $SysPromptFile -ErrorAction Stop}
        catch {throw "Unable to save system prompt file [$SysPromptFile]"}

    }
}


#This function consumes a Dialog, and returns a fully-furnished $Body object
function Convert-LMDialogToBody {

    [CmdletBinding(DefaultParameterSetName="Auto")]
    param (
        #Use $Global:LMGlobalVars
        [Parameter(Mandatory=$true)]
        [array]$DialogMessages,

        #Signals a prompt to select an entry from the History File
        [Parameter(Mandatory=$True)]
        [int]$ContextDepth,
        
        [Parameter(Mandatory=$True)]
        [ValidateScript({ if ($_.GetType().Name -ne "Hashtable") { throw "Parameter must be a hashtable" } else { $true } })]
        [HashTable]$Settings
    )
    
    begin {

        $Body = New-LMTemplate -Type Body

        $Body.model = $Settings.model
        $Body.temperature = $Settings.temperature
        $Body.max_tokens = $Settings.max_tokens
        $Body.stream = $Settings.stream
        $Body.messages[0].content = $Settings.SystemPrompt

    }
    process {
        
        $SelectedMessages = New-Object System.Collections.ArrayList

        $Counter = 0
        $Index = 0

        :msgloop do {

            $Message = $DialogMessages[$($DialogMessages.Count - (1 + $Index))]

            If ($Message.role -ne 'user' -and $Message.role -ne 'assistant'){
                $Index++
                continue msgloop
            }

            $SelectedMessages.Add($Message) | Out-Null

            $Index++
            
            #If, the answer before the last one
            # is an 'assistant' entry, then our "user/assistant" pattern isn't broken.
            # If it's not an "assistant" entry, we need to continue without incrementing counter
            # to fix our Q/A Q/A sequence to start with a [user] entry:
            If ($Counter -eq ($ContextDepth - 1) -and $Message.role -ne 'assistant'){continue msgloop}

            #Otherwise, just increment $Counter:
            $Counter++        

        }
        # Until we either get the context depth we want, or we reach the end of the list of messages
        until (($Counter -eq $ContextDepth) -or ($Counter -eq ($DialogMessages.Count - 1)))

    }
    end {
        # Because we started at the end and worked our way backward, we have to "flip" the array back into chronological order:
        If ($SelectedMessages.Count -gt 1){

            $SelectedMessages = $SelectedMessages[$($SelectedMessages.Count - 1)..0]
        
            #Fill the first "provisioned" row from the template with the first entry of the selected messages
            $Body.messages[1].content = $SelectedMessages[0].Content

        #Add the remaining rows to the $Body
            Foreach ($Entry in $SelectedMessages[1..$($SelectedMessages.Count - 1)]){

                $BodyMessage = [pscustomobject]@{"role" = $Entry.Role; "content" = $Entry.content}

                $Body.messages += $BodyMessage

            }
    
        }
        ElseIf ($SelectedMessages.Count -eq 1){

            $Body.messages[1].content = $SelectedMessages[0].Content

        }

        Else {throw "Convert-LMDialogToBody: No messages were ordered: -DialogMessages empty?"}

        return $Body

    }
    

}

#This function intakes a Dialog object, and returns a History File entry object
#Doesn't require a lot of fanciness, or much validation
#This function is an odd duck, because I have the path (which is all I need) but I specify the $DialogObject anyway.
#The reason it does this is because of the way I needed to implement it: it needs the path for the history entry,
#not because it needs to read the file (it already has the contents)
function Convert-LMDialogToHistoryEntry { #Complete
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$true)]
    [pscustomobject]$DialogObject,
    
    [Parameter(Mandatory=$true)]
    [ValidateScript({ if (!(Test-Path -Path $_)) { throw "File path does not exist" } else { $true } })]
    [string]$DialogFilePath
    )

    $HistoryEntry = New-LMTemplate -Type HistoryEntry
    
    $HistoryEntry.Created = $DialogObject.Info.Created
    $HistoryEntry.Modified = $DialogObject.Info.Modified
    $HistoryEntry.Model = $DialogObject.Info.Model

    $Opener = $DialogObject.Info.Opener
    
    If ($null -ne $Opener){$HistoryEntry.Opener = $Opener}
    Else {$Opener = "Unset"} #Not likely to encounter this

    $RelativePath = ($DialogFilePath -split '\\' | Select-Object -Last 2) -join '\'

    $HistoryEntry.FilePath = $RelativePath

    If ($DialogObject.Info.Title -eq 'dummyvalue'){$HistoryEntry.Title = "Unset"}
    Else {$HistoryEntry.Title = $DialogObject.Info.Title}

    $HistoryEntry.Tags = $DialogObject.Info.Tags #Keep it simple

    return $HistoryEntry

}

#This function presents a selection prompt (Out-Gridview) to continue a history file
function Select-LMHistoryEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "File path does not exist" } else { $true } })]
        [string]$HistoryFile
    )
    begin {

        If (!$PSBoundParameters.ContainsKey('HistoryFile')){

            If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded. Run [Import-ConfigFile] to load them"}
            Else {$HistoryFile = $global:LMStudioVars.FilePaths.HistoryFilePath}    
        }

        If (!(Test-Path $HistoryFile)){throw "History file not found - path invalid [$HistoryFile]"}

    }
    process {

        $HistoryData = New-Object System.Collections.ArrayList

        try {$HistoryEntries = Import-LMHistoryFile -FilePath $HistoryFile | Select-Object @{N="Created"; E={Get-Date ($_.Created)}}, @{N="Modified"; E={Get-Date ($_.Modified)}}, Title, Opener, FilePath, @{N = "Tags"; E = {(($_.Tags) -join ', ') -replace 'dummyvalue, ','' -replace 'dummyvalue',''}}}
        catch {throw "History file is not the correct file format [$HistoryFile]"}
    
        $HistoryEntries | ForEach-Object {$HistoryData.Add($_) | out-null}
    
        $HistoryData += ([pscustomobject]@{"Created" = "Select this entry to Cancel"; "Modified" = ""; "Title" = ""; "Opener" = ""; "FilePath" = ""})
    
        $Selection = $HistoryData | Sort-Object -Property Modified -Descending | Out-GridView -Title "Select a Chat Dialog" -OutputMode Single

    }
    end {
        
        If ($Selection.Created -eq 'Select this entry to Cancel' -or $null -eq $Selection){throw "Chat selection cancelled"}

        $DialogFilePath = "$($HistoryFile.TrimEnd('.index'))" + '-DialogFiles\' + "$($Selection.FilePath.Split('\')[1])"

        switch ((Test-Path $DialogFilePath)){

            $false {throw "Selected history entry is invalid (path not found). Please run [Repair-LMHistoryFile]"}

            $true {return $DialogFilePath}
            
        }
        
    }

}

#This function intakes a user prompt, interprets an option and executes a command
function Set-LMCLIOption {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$UserInput
    )
    
    begin {
    
        $ResultObj = [pscustomobject]@{"Result" = $False; "Message" = ""}
    
        $Fault = $False
    
        try {$Setting = $UserInput.Substring(0,5)}
        catch {
            $ResultObj.Message = "Option input is invalid. Try ':help' for more information."
            $Fault = $True
        }
    
    }
    process {
        
    If (!$Fault){
        
        switch ($Setting){
    
            {$_ -ieq ":help"}{
                
                Show-LMHelp
                break
    
            } #Test Good
    
            {$_ -ieq ":show"}{
                
                Show-LMSettings
                break
    
            } #Test Good
    
            {$_ -ieq ":selp"}{ #Test Good
    
                try {Select-LMSystemPrompt -Pin}
                catch {
                    $ResultObj.Message = $_.Exception.Message
                    $Fault = $True 
                }
    
                If (!$Fault){$ResultObj.Message = "Prompt successfully selected and pinned"}
    
                break
    
            }
    
            {$_ -ieq ":temp"}{ #Test Good
    
                try {$TempValue = $UserInput.Substring(5,($UserInput.Length - 5))}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed."
                    $Fault = $True
                }
    
                If (!$Fault){
    
                    If (($UserInput.Length -ne 9) -or ($TempValue -notmatch '(\d[.]\d)')){
                        $ResultObj.Message = "Incorrect syntax: expected :temp #.#"
                        $Fault = $True
                    }
        
                }
                
                If (!$Fault){
    
                    try {$TempValue = [double]$TempValue}
                    catch {
                        $ResultObj.Message = "Incorrect syntax: expected :temp [0.0 - 2.0]"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
                    
                    If ($TempValue -lt 0 -or $TempValue -gt 2){
                        $ResultObj.Message = "Temperature must be within the range of 0.0 to 2.0"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
                
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"temperature" = $TempValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Temperature successfully set to $TempValue"}
    
                break
                
            } #:temp
    
            {$_ -ieq ":mtok"}{ #Test Good
    
                try {$MtokValue = $UserInput.SubString(5,(($UserInput.Length - 5)))}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
    
                    If (($UserInput.Length -gt 11) -or ($MtokValue -notmatch '([-]\d+|\d)')){
                        $ResultObj.Message = "Incorrect syntax: expected :mtok number of 1 or greater, or -1, expected"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
    
                    try {$MtokValue = [int]$MtokValue}
                    catch {
                        $ResultObj.Message = "Incorrect syntax: expected :mtok [int]"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
    
                    If ($MtokValue -le -2){
                        $ResultObj.Message = "Max tokens must be -1 or greater"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
                
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"max_tokens" = $MtokValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Max Tokens successfully set to $MtokValue"}
    
                break
                
            } #:temp
    
            {$_ -ieq ":strm"}{ #Test Good
    
                try {$StreamValue = $UserInput.SubString(5,(($UserInput.Length - 5))).Trim()}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
                    
                    switch ($StreamValue){
                    
                        {$_ -ieq "true"}{$StreamValue = $True}
                        {$_ -ieq "false"}{$StreamValue = $False}
    
                        Default {
                            $ResultObj.Message = "Incorrect syntax: expected :strm value of True or False"
                            $Fault = $True
                        }
    
                    }
    
                    break
    
                }
    
                If (!$Fault){
    
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"stream" = $StreamValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Stream successfully set to $StreamValue"}
    
            }
    
            {$_ -ieq ":save"}{ #Test Good
    
                try {$SaveValue = $UserInput.SubString(5,(($UserInput.Length - 5))).Trim()}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
                    
                    switch ($SaveValue){
                    
                        {$_ -ieq "true"}{$SaveValue = $True}
                        {$_ -ieq "false"}{$SaveValue = $False}
    
                        Default {
                            $ResultObj.Message = "Incorrect syntax: expected :save value of True or False"
                            $Fault = $True
                        }
    
                    }
    
                }
    
                If (!$Fault){
    
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"SavePrompt" = $SaveValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Stream successfully set to $SaveValue"}
    
                break
    
            }
    
            {$_ -ieq ":mark"}{ #Test Good
    
                try {$MarkValue = $UserInput.SubString(5,(($UserInput.Length - 5))).Trim()}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
                    
                    switch ($MarkValue){
                    
                        {$_ -ieq "true"}{$MarkValue = $True}
                        {$_ -ieq "false"}{$MarkValue = $False}
    
                        Default {
                            $ResultObj.Message = "Incorrect syntax: expected :mark value of True or False"
                            $Fault = $True
                        }
    
                    }
    
                }
    
                If (!$Fault){
    
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"Markdown" = $MarkValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Stream successfully set to $MarkValue"}
    
                break
    
            }
    
            {$_ -ieq ":gret"}{ #Test Good
    
                try {$GreetValue = $UserInput.SubString(5,(($UserInput.Length - 5))).Trim()}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
                    
                    switch ($GreetValue){
                    
                        {$_ -ieq "true"}{$GreetValue = $True}
                        {$_ -ieq "false"}{$GreetValue = $False}
    
                        Default {
                            $ResultObj.Message = "Incorrect syntax: expected :gret value of True or False"
                            $Fault = $True
                        }
    
                    }
    
                }
    
                If (!$Fault){
    
                    try {Set-LMConfigOptions -Branch ChatSettings -Options @{"Greeting" = $GreetValue} -Commit}
                    catch {
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "Greeting successfully set to $GreetValue"}
    
                break
    
            }
    
            {$_ -ieq ":cond"}{ #Test Good
    
                try {$CondValue = ([int]($UserInput.SubString(5,($UserInput.Length - 5))))}
                catch {
                    $ResultObj.Message = "Incorrect input: cannot be correctly parsed"
                    $Fault = $True
                }
    
                If (!$Fault){
    
                    If (($UserInput.Length -gt 11) -or ($CondValue -notmatch '(\d+)')){
                        $ResultObj.Message = "Incorrect syntax: expected :cond number of 2 or greater expected"
                        $Fault = $True
                    }
    
                }
    
                If (!$Fault){
    
                    switch ($CondValue % 2){
    
                        0 {
    
                            If ($CondValue -le 0){
                                
                                $ResultObj.Message = "Incorrect value: :cond must be greater than or equal to 2"
                                $Fault = $True
    
                            }
                            
                            Else {
                            
                                try {Set-LMConfigOptions -Branch ChatSettings -Options @{"ContextDepth" = $CondValue} -Commit}
                                catch {
                                    $ResultObj.Message = "$($_.Exception.Message)"
                                    $Fault = $True
                                }
    
                            }
                        }
    
                        1 {
    
                            $ResultObj.Message = "Incorrect value: :cond must be an even number"
                            $Fault = $True
    
                        }
    
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = ":cond was successfully set to $CondValue"}
    
                break
                
            } #:temp
    
            {$_ -ieq ":newp"}{ #Test Good
    
                $PromptValue = $UserInput.Substring(5,($UserInput.Length -5))
    
                If ($PromptValue.Length -eq 0){
                    $ResultObj.Message = "No string was provided after :newp"
                    $Fault = $True
    
                }
    
                If (!$Fault){
    
                    try {Edit-LMSystemPrompt -Add -Name "Generated $((Get-Date).ToString())" -Prompt "$PromptValue"}
                    catch {
    
                        $ResultObj.Message = "$($_.Exception.Message)"
                        $Fault = $True
    
                    }
    
                }
    
                If (!$Fault){$ResultObj.Message = "New prompt creation succeeded! Select it with :selp"}
    
                break
                
            } #:temp
    
            Default {
    
                $ResultObj.Message = "Command not recognized. Run :help for Help"
                $Fault = $True
    
            }
    
        } #Close Switch $Setting
    
    } #Close !$Fault
    
    }
    
    end {
    
        $ResultObj.Result = !$Fault
        return $ResultObj
    
    }
    
    } #Close function

#This function converts Dialog Messages to Markdown output
function Show-LMDialog {

    [CmdletBinding(DefaultParameterSetName="Auto")]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='Display')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [array]$DialogMessages,
        
        [Parameter(Mandatory=$false, ParameterSetName='Display')]
        [switch]$AsMarkdown,
        
        [Parameter(Mandatory=$false, ParameterSetName='Test')]
        [switch]$CheckMarkdown
    )
    begin {

        If (!($PSBoundParameters.ContainsKey('DialogMessages')) -and !($PSBoundParameters.ContainsKey('CheckMarkDown'))){throw "No parameters provided: please specify parameter [-DialogMessages or -Check]"}

        $MessageBuffer = New-Object System.Collections.ArrayList

        If ($AsMarkdown.IsPresent -or $CheckMarkdown.IsPresent){

            If (($PSversionTable.PSVersion.Major -ge 7) -and ($null -ne (Get-Command Show-Markdown -ErrorAction SilentlyContinue))){$MarkDownAvailable = $True}
            Else {$MarkDownAvailable = $False}

            If (!($MarkDownAvailable) -and !($CheckMarkdown.IsPresent)){throw "MarkDown not available in this Powershell session"}

        }

    }
    process {

            if (!($CheckMarkDown.IsPresent)){

                Foreach ($Message in $DialogMessages.Where({$_.role -match 'user|assistant'})){

                    switch ($Message.role){

                        {$_ -eq 'user'}{
                            $Title = "You: "
                            $Color = "Green"
                        }
                        {$_ -eq 'assistant'}{
                            $Title = "AI: "
                            $Color = "Magenta"
                        }

                    }

                switch ($AsMarkdown.IsPresent){

                    $True {$MessageBuffer.Add(([pscustomobject]@{"Title" = $Title; "Color" = $Color; "Message" = $((($Message.Content) | Show-Markdown)).TrimEnd("`n")})) | Out-Null}

                    $False {$MessageBuffer.Add(([pscustomobject]@{"Title" = $Title; "Color" = $Color; "Message" = $($Message.Content)})) | Out-Null}

                }

            }

        }

    }
    end {

        if ($CheckMarkdown.IsPresent){return $MarkDownAvailable}
        else {

            If ($AsMarkdown.IsPresent){Clear-Host}

            $MessageBuffer.Foreach({
            
                $Message = $_

                Write-Host "$($Message.Title)" -ForegroundColor "$($Message.Color)" -NoNewline

                switch ($AsMarkdown.IsPresent){ #.Replace("`n`n`n`n","`n`n")
                    $True {Write-Host $($Message.Message.TrimEnd("`r`n"))}
                    $False {Write-Host "$($Message.Message)"}
                }

                Write-Host ""

            })

        }

    }

}

function Start-LMChat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)]
        [switch]$ResumeChat,

        [Parameter(Mandatory=$False)]
        [switch]$PrivacyMode
        )

    begin {


        #region Evaluate variables Variables
        If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}
        
        #endregion

        #region Get Model (Connection Test)
        try {$Model = Get-LMModel -Server $Global:LMStudioVars.ServerInfo.Server -Port $Global:LMStudioVars.ServerInfo.Port}
        catch {throw $_.Exception.Message}
        #endregion

        #region Check/set if we can use markdown
        $MarkDownAvailable = Show-LMDialog -CheckMarkdown
        $UseMarkDown = ([bool]($Global:LMStudioVars.ChatSettings.Markdown -and $MarkDownAvailable))
        #endregion

        If ($PrivacyMode.IsPresent){$PrivacyOn = $True}
        Else {$PrivacyOn = $False}
        
        #region -ResumeChat Selector
        switch ($ResumeChat.IsPresent){ 

            #This section requires everything goes right (terminates with [throw] if it doesn't)
            $true { 
                    #If the history file doesn't exist, find it:
                    If (!(Test-Path $Global:LMStudioVars.FilePaths.HistoryFilePath)){
            
                        #Prompt to browse and "open" it
                        try {$Global:LMStudioVars.FilePaths.HistoryFilePath = Invoke-LMSaveOrOpenUI -Action Open -Extension index -StartPath "$env:Userprofile\Documents"}
                        catch {throw $_.Exception.Message}
            
                    }
                    
                    #Open a GridView selector from the history file
                    try {$DialogFilePath = Select-LMHistoryEntry -HistoryFile $Global:LMStudioVars.FilePaths.HistoryFilePath}
                    catch {
                        If ($_.Exception.Message -match 'selection cancelled'){throw "Selection cancelled"}
                        else {Write-Warning "$($_.Exception.Message)"; return}

                    }

                    #Otherwise: Read the contents of the chosen Dialog file
                    try {$Dialog = Import-LMDialogFile -FilePath $DialogFilePath -ErrorAction Stop}
                    catch {throw $_.Exception.Message}

                    #If we made it this far, Let's set $Global:LMStudioVars.ChatSettings.Greeting and $DialogFIleExists
                    $Global:LMStudioVars.ChatSettings.Greeting = $False
                    $DialogFileExists = $True

            } #Close Case $True

            #This section can accommodate a failure to create a new Dialog file
            $false { #If not Resume Chat, then Create New Dialog File

                    $Dialog = New-LMTemplate -Type ChatDialog
                    
                    $Dialog.Info.Model = $Model
                    $Dialog.Info.Modified = "$((Get-Date).ToString())"
                    $Dialog.Messages[0].temperature = $Global:LMStudioVars.ChatSettings.temperature
                    $Dialog.Messages[0].max_tokens = $Global:LMStudioVars.ChatSettings.max_tokens
                    $Dialog.Messages[0].stream = $Global:LMStudioVars.ChatSettings.stream
                    $Dialog.Messages[0].ContextDepth = $ContextDepth
                    $Dialog.Messages[0].Content = $Global:LMStudioVars.ChatSettings.SystemPrompt

                    # Set the directory path for the chat file:
                    #
                    # We need this set even if we skip the save prompt,
                    # in case we decide to save during the prompt (:s to save?)
                    # This is why it's outside of (!($SkipSavePrompt.IsPresent))

                    #If we didn't opt to skip this prompt:
                    switch (($Global:LMStudioVars.ChatSettings.SavePrompt -and $PrivacyOn -eq $False)){

                        $True {

                            try { # Prompt to create the full file path
                                $DialogFilePath = Invoke-LMSaveOrOpenUI -Action Save -Extension dialog -StartPath $Global:LMStudioVars.FilePaths.DialogFolderPath
                                $DialogFileExists = $True #It doesn't actually exist, UI doesn't create anything
                            }
                            catch {
                                Write-Warning "$($_.Exception.Message)"
                                $DialogFileExists = $False
                            }

                        }

                        $False {

                            $DialogFilePath = "$($Global:LMStudioVars.FilePaths.DialogFolderPath)" + "\$(get-date -format 'MMddyyyy_hhmm')_lmchat.dialog"
                            $DialogFileExists = $True

                        }

                    }

                    If ($DialogFileExists -and $PrivacyOn -eq $False){

                        try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFilePath -ErrorAction Stop}
                        catch {
                            Write-Warning "$($_.Exception.Message)"
                            $DialogFileExists = $False
                        }
                    }

                    Else {
                        $DialogFileExists = Test-Path $DialogFilePath
                        If ($PrivacyOn -eq $True){Write-Host "Privacy mode enabled. Dialog file will not be saved."}
                    }

                    } #Close Case $False
                
                } #Close Switch
        #endregion
        
        #region Initiate Greeting
        If ($Global:LMStudioVars.ChatSettings.Greeting){Get-LMGreeting}
        #endregion
    
    } #begin

    process {
        
        $BreakDialog = $False
        $OpenerSet = ([boolean](($Dialog.Info.Opener.Length -ne 0) -and ($null -ne $Dialog.Info.Opener) -and ($Dialog.Info.Opener -ne "dummyvalue")))
        

        #Set $BodySettings for use with Convert-LMDialogToBody:
        $BodySettings = @{}
        $BodySettings.Add('model',$Model)
        $BodySettings.Add('temperature', $Global:LMStudioVars.ChatSettings.temperature)
        $BodySettings.Add('max_tokens', $Global:LMStudioVars.ChatSettings.max_tokens)
        $BodySettings.Add('stream', $Global:LMStudioVars.ChatSettings.stream)
        $BodySettings.Add('SystemPrompt', $Global:LMStudioVars.ChatSettings.SystemPrompt)

        If ($ResumeChat.IsPresent){ #Play the previous conversation back to the 

            switch ($UseMarkDown){

                $True {Show-LMDialog -DialogMessages ($Dialog.Messages) -AsMarkdown}

                $False {Show-LMDialog -DialogMessages ($Dialog.Messages)} #Close False
            }

        }

        #The magic is here:
    :main do { 

            $UseMarkDown = $global:LMStudioVars.ChatSettings.MarkDown

            #region Prevent empty responses
            do {

                Write-Host "You: " -ForegroundColor Green -NoNewline
                $UserInput = Read-Host 
            
            }
            until ($UserInput.Length -gt 0)
            #endregion

            #region Check input for option:
            $OptTriggered = $False

            try {$OptionKey = $UserInput.Substring(0,5).TrimEnd()}
            catch {$OptionKey = "X"} #Error suppression: I know this is a "bad practice", but I don't like the clunkiness or lack of control for toggling the ErrorActionPreference

            # If ':wxyz ', trimmed at the end (':wxyz') has a length of 5 characters:
            If ($OptionKey.Length -eq 5 -and $OptionKey[0] -eq ':'){$OptTriggered = $True}

            If ($OptTriggered -and $OptionKey -ieq ':quit'){break main}
            
            ElseIf ($OptTriggered -and $OptionKey -ieq ':priv'){
                
                Write-Warning "Privacy Mode can't be turned back off for the duration of this session."
                Write-Host "NOTICE: " -ForegroundColor Green -NoNewline
                Write-Host "The dialog file will also be deleted. " -NoNewline

                $ConfirmPriv = Confirm-LMYesNo

                switch ($ConfirmPriv){

                    $True {

                        If ($DialogFileExists -and !($ResumeChat.IsPresent)){
                            
                            try {Remove-Item -Path ($Global:LMStudioVars.FilePaths.HistoryFilePath)}
                            catch {Write-Warning "Unable to delete history file $($Global:LMStudioVars.FilePaths.HistoryFilePath)"}

                            $PrivacyOn = $True

                            }
                    }

                    $False {
                        
                        Write-Host "Privacy Mode cancelled."
                        continue main
                    
                    }

                }
            }

            #region Show tags:
            ElseIf ($OptTriggered -and $OptionKey -ieq ':tags'){

                Write-Host "Tags: " -ForegroundColor Magenta -NoNewline
                Write-Host "$($Dialog.Info.Tags -join ', ')"

                continue main

            }
            #endregion

            #region Add/Remove tags:
            ElseIf ($OptTriggered -and ($OptionKey -ieq ':atag' -or $OptionKey -ieq ':rtag')){

                try {$TagText = "$($UserInput.Substring(5,$($UserInput.Length - 5)))"}
                catch {
                    Write-host "$OptionKey syntax was incorrect. Use :help" -ForegroundColor Yellow
                    continue :main
                    
                }

                If ($TagText -match ','){[array]$Tags = ($TagText -split ',').Trim().Where({$_ -ne ""})}
                Else {
                
                    $Tags = @()
                    $Tags += "$($TagText.Trim())"

                }

                If ($null -eq $Tags -or $Tags.Count -eq 0){
                    Write-host ":$OptionKey was provided no tags. Use :help" -ForegroundColor Yellow
                    continue :main

                }

                $TagUpdate = $False

                If ($OptionKey -eq ':atag'){

                    $Tags.Foreach({
                        
                        $Tag = $_
                        $Dialog.Info.Tags += "$Tag"
                    
                    })

                    $TagUpdate = $True
                }
                        
                If ($OptionKey -eq ':rtag'){
                    
                    $Tags.Foreach({
                    
                        $Tag = $_
                        $Dialog.Info.Tags = $Dialog.Info.Tags | Where-Object {$_ -ine "$Tag"}
                
                    })

                    $TagUpdate = $True
                
                }

                If ($TagUpdate){

                    #region Update Dialog File, History File
                    If ($DialogFileExists -and $PrivacyOn -eq $False){

                        # Save the Dialog File
                        try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFilePath -ErrorAction Stop}
                        catch {
                            Write-Warning "Dialog file save failed; Disabling file saving (:Save to recreate a Dialog file)"
                            $DialogFileExists = $False
                        }

                        # Update the History File
                        If ($DialogFileExists){ 
                        
                            try {Update-LMHistoryFile -FilePath $Global:LMStudioVars.FilePaths.HistoryFilePath -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                            catch { #Sleep and then try once more, in case we're stepping on our own feet (multiple)
                                
                                Start-Sleep -Seconds 2

                                try {Update-LMHistoryFile -FilePath $Global:LMStudioVars.FilePaths.HistoryFilePath -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                                catch {
                                
                                    Write-Warning "Unable to append Dialog updates to History file; Disabling file-saving (:Save to recreate a Dialog file)"
                                    $DialogFileExists = $False
                                }
                            }

                        }

                    }
                    Else {Write-Host "Unable to complete $OptionKey\: Dialog File cannot be saved" -ForegroundColor Yellow}

                    #endregion


                }

                Remove-Variable TagUpdate,Tag,Tags,OptionKey,TagText -ErrorAction SilentlyContinue
                continue :main

            }
            #endregion

            Else { 

                If ($OptTriggered){

                    $Option = Set-LMCLIOption -UserInput $UserInput

                    switch ($Option.Result){

                        $True {Write-Host "Set option succeeded" -ForegroundColor Green}
                        $False {Write-Host "Set option failed: $($Option.Message)" -ForegroundColor Green}
                        Default {Write-Host "Strange or no result returned from [Set-LMCLIOption]" -ForegroundColor Yellow}

                    }

                    continue main

                }

            }

            #>
            #endregion

            #region Construct the user Dialog Message and append to the Dialog:
            $UserMessage = New-LMTemplate -Type DialogMessage
        
            $UserMessage.TimeStamp = (Get-Date).ToString()
            $UserMessage.temperature = $Global:LMStudioVars.ChatSettings.temperature
            $UserMessage.max_tokens = $Global:LMStudioVars.ChatSettings.max_tokens
            $UserMessage.stream = $Global:LMStudioVars.ChatSettings.stream
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

            switch ($Global:LMStudioVars.ChatSettings.stream){

                $True {$LMOutput = Invoke-LMStream -Body $Body -CompletionURI $Global:LMStudioVars.URIs.CompletionURI -File $Global:LMStudioVars.FilePaths.StreamCachePath}
                $False {$LMOutput = Invoke-LMBlob -Body $Body -CompletionURI $Global:LMStudioVars.URIs.CompletionURI -StreamSim}

            }

            Write-Host ""

            If ($LMOutput -eq "[stream_interrupted]"){continue main}

            #region Construct the assistant Dialog message and append to the Dialog:
            $AssistantMessage = New-LMTemplate -Type DialogMessage
            
            $AssistantMessage.TimeStamp = (Get-Date).ToString()
            $AssistantMessage.temperature = $Global:LMStudioVars.ChatSettings.temperature
            $AssistantMessage.max_tokens = $Global:LMStudioVars.ChatSettings.max_tokens
            $AssistantMessage.stream = $Global:LMStudioVars.ChatSettings.stream
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

            #region Set Opener
            If (!($OpenerSet)){
                $Dialog.Info.Opener = (($Dialog.Messages | Sort-Object TimeStamp) | Where-Object {$_.role -eq "user"})[0].Content
                $OpenerSet = $False
            }
            #endregion

            #region Update Dialog File, History File
            If ($DialogFileExists -and $PrivacyOn -eq $False){

                # Save the Dialog File
                try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFilePath -ErrorAction Stop}
                catch {
                    Write-Warning "Dialog file save failed; Disabling file saving (:Save to recreate a Dialog file)"
                    $DialogFileExists = $False
                }

                # Update the History File
                If ($DialogFileExists){ 
                
                    try {Update-LMHistoryFile -FilePath $Global:LMStudioVars.FilePaths.HistoryFilePath -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                    catch { #Sleep and then try once more, in case we're stepping on our own feet (multiple)
                        
                        Start-Sleep -Seconds 2

                        try {Update-LMHistoryFile -FilePath $Global:LMStudioVars.FilePaths.HistoryFilePath -Entry $(Convert-LMDialogToHistoryEntry -DialogObject $Dialog -DialogFilePath $DialogFilePath)}
                        catch {
                        
                            Write-Warning "Unable to append Dialog updates to History file; Disabling file-saving (:Save to recreate a Dialog file)"
                            $DialogFileExists = $False
                        }
                    }

                }

            }
            #endregion
            
            Start-Sleep -Milliseconds 30 #06/15: Experimenting with trying to reduce CPU demand
            
        }
        until ($BreakDialog -eq $True)
    }

    end {} #Everything in end {} is better off in clean {}, in this case

    clean {

        Remove-Variable Dialog -ErrorAction SilentlyContinue
        Remove-Variable Body -ErrorAction SilentlyContinue

        (Get-Job -ErrorAction SilentlyContinue) | Foreach-Object {
        
            $_ | Stop-Job -ErrorAction SilentlyContinue
            $_ | Remove-Job -ErrorAction SilentlyContinue

        }

        [gc]::Collect()

    }

}

function Get-LMResponse {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='NoSettings')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$UserPrompt,

        [Parameter(Mandatory=$false, ParameterSetName='NoSettings')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$DialogFile,
        
        [Parameter(Mandatory=$false, ParameterSetName='Settings')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [hashtable]$Settings,
        
        [Parameter(Mandatory=$false)]
        [switch]$IgnoreWarnings
        )

    begin {
        
        #region Ensure either UserPrompt or Settings is used
        If ((!($PSBoundParameters.ContainsKey('UserPrompt')))-and (!($PSBoundParameters.ContainsKey('Settings')))){throw "-UserPrompt and -Settings were missing. One of these two must be used."}
        #endregion

        If (($PSBoundParameters.ContainsKey('Settings'))){

            #region Validate Settings structure
            $SettingsFields = (New-LMTemplate -Type ManualSettings).GetEnumerator().Name
            try {$ProvidedFields =$Settings.GetEnumerator().Name}
            catch {throw "[Get-LMResponse] -Settings object is missing requisite properties and methods"}

            $FieldComparison = Compare-Object -ReferenceObject $SettingsFields -DifferenceObject $ProvidedFields

            If ($FieldComparison.Count -gt 0){throw "[Get-LMResponse] properties on -Settings object is missing properties ($($FieldComparison.InputObject -join ', '))"}
            #endregion

            #region Evaluate the provided settings
            $Warnings = New-Object System.Collections.ArrayList

            #region Check Server
            If ($Null -eq $Settings.server -or $Settings.server.Length -eq 0){$Errors.Add("Server is null or empty") | Out-Null}
            #endregion

            #region Check Port
            If ($Null -eq $Settings.port -or $Settings.port.Length -eq 0){$Errors.Add("Port is null or empty") | Out-Null}
            Else {
            
                try {$PortAsInt = [int]$Settings.port}
                catch {throw "Port is not convertable to integer"}
                
                If ($PortAsInt -le 0 -or $PortAsInt -gt 65535){
                    throw "Port not 1-65536 ($($PortAsInt))"
                }
            }
            #endregion

            #region Check UserPrompt
            If ($Null -eq $Settings.UserPrompt -or $Settings.UserPrompt.Length -eq 0){throw "Server is null or empty"}
            #endregion

            #region Check Max_Tokens
            If ($Settings.max_tokens.Length -eq 0 -or $null -eq $Settings.max_tokens){
                $Settings.max_tokens = -1
                $Warnings.Add("Max_Tokens is null or empty") | Out-Null
            }
            Else {
            
                try {$TokensAsInt = [int]$Settings.max_tokens}
                catch {
                    $Warnings.Add("Port is not convertable to integer") | Out-Null
                    $Settings.max_tokens = -1
                    continue
                }
                
                If ($TokensAsInt -le -2){
                    $Warnings.Add("Max_Tokens is less than or equal to -2 ($($TokensAsIntAsInt))")
                    $Settings.max_tokens = -1
                }
            }
            #endregion

            #region Check ContextDepth
            If ($Settings.ContextDepth.Length -eq 0 -or $null -eq $Settings.ContextDepth){
                $Settings.ContextDepth = 10
                $Warnings.Add("ContextDepth is null or empty") | Out-Null
            }
            Else {
            
                try {$ContextDepthAsInt = [int]$Settings.ContextDepth}
                catch {
                    $Warnings.Add("ContextDepth is not convertable to integer") | Out-Null
                    $Settings.ContextDepth = 10
                    continue
                }
                
                If ($ContextDepthAsInt -le 0){
                    $Warnings.Add("ContextDepth is less than or equal to 0 ($($TokensAsIntAsInt))")
                    $Settings.ContextDepth = 10
                }
            }
            #endregion
            
            #region Check Temperature
            If ($Settings.temperature.Length -eq 0 -or $null -eq $Settings.temperature){
                $Settings.temperature = 0.7
                $Warnings.Add("Temperature is null or empty") | Out-Null
            }
            Else {
            
                try {$TempAsDouble = [system.math]::Round([double]$Settings.temperature, 1)}
                catch {
                    $Warnings.Add("Temperature isn't convertable to a double") | Out-Null
                    $Settings.temperature = 0.7
                    continue
                }
                
                If ($TempAsDouble -lt 0 -or $TempAsDouble -gt 2){
                    $Warnings.Add("Temperature isn't in a range of 0-2 ($($TempAsDouble))")
                    $Settings.temperature = 0.7
                }
            }
            #endregion

            #region Check System Prompt
            If ($Settings.SystemPrompt.Length -eq 0 -or $null -eq $Settings.SystemPrompt){
                $Settings.SystemPrompt = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
                $Warnings.Add("System Prompt is null or empty") | Out-Null
            }
            #endregion

            #region Check Dialog File
            If ($Settings.DialogFile.Length -gt 0){
                $DialogFile = $Settings.DialogFile
                $SaveDialog = $True
            }
            Else {$SaveDialog = $False}
            #endregion

            #endregion Evaluate the provided settings

        } #Close If PSBoundParameters contains settings

        #region If we don't have a Settings Hashtable, use the Config
        Else {

            If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}

            $Settings = New-LMTemplate -Type ManualSettings
            $Settings.max_tokens = $Global:LMStudioVars.ChatSettings.max_tokens
            $Settings.ContextDepth = $Global:LMStudioVars.ChatSettings.ContextDepth
            $Settings.temperature = $Global:LMStudioVars.ChatSettings.temperature
            $Settings.port = $Global:LMStudioVars.ServerInfo.Port            
            $Settings.server = $Global:LMStudioVars.ServerInfo.Server            
            $Settings.SystemPrompt = $Global:LMStudioVars.ChatSettings.SystemPrompt            
            $Settings.UserPrompt = $UserPrompt

            If ($PSBoundParameters.ContainsKey('DialogFile')){
                $Settings.DialogFile = $DialogFile
                $SaveDialog = $true
            }
            Else {$SaveDialog = $False}
                        
        }

        #region Get Model (Connection Test)
        try {$Model = Get-LMModel -Server $Settings.server -Port $Settings.port}
        catch {throw "$($_.Exception.Message)"}
        #endregion

        #region Import or create Dialog File
        If ($SaveDialog -and (Test-Path $DialogFile)){
            
            try {$Dialog = Import-LMDialogFile -FilePath $DialogFile -ErrorAction Stop}
            catch {throw "Dialog file import failed: $($_.Exception.Message)"}

            $OpenerSet = ([boolean]($Dialog.Info.Opener.Length -gt 0 -and $Dialog.Info.Opener -ne "dummyvalue"))              
          
        } 
        Else {
            #Create Dialog
            $Dialog = New-LMTemplate -Type ChatDialog
            $Dialog.Info.Model = $Model
            $Dialog.Info.Modified = "$((Get-Date).ToString())"
            $Dialog.Messages[0].temperature = $Settings.temperature
            $Dialog.Messages[0].max_tokens = $Settings.max_tokens
            $Dialog.Messages[0].stream = $False
            $Dialog.Messages[0].ContextDepth = $Settings.ContextDepth
            $Dialog.Messages[0].Content = $SystemPrompt

            $OpenerSet = $False
        }

        #region Report warnings, throw errors
        If ($Warnings.Count -gt 0){

            if (!($IgnoreWarnings.IsPresent)){Foreach ($Warning in $Warnings){Write-warning "$Warning"}}

        }

        #endregion

        #region Define the CompletionURI endpoint
        $CompletionURI = "http://" + "$($Settings.server)" + ':' + "$($Settings.port)" + "/v1/chat/completions"
        #endregion
    }
    process {

        #region Construct the user Dialog Message and append to the Dialog:
        $UserMessage = New-LMTemplate -Type DialogMessage
      
        $UserMessage.TimeStamp = (Get-Date).ToString()
        $UserMessage.temperature = $Settings.temperature
        $UserMessage.max_tokens = $Settings.max_tokens
        $UserMessage.stream = $False
        $UserMessage.ContextDepth = $Settings.ContextDepth
        $UserMessage.Role = "user"
        $UserMessage.Content = $Settings.UserPrompt

        $Dialog.Messages.Add($UserMessage) | out-null
        #endregion

        #region Create $BodySettings for Invoke-LMBlob
        $BodySettings = @{}
        $BodySettings.Add('model',$Model)
        $BodySettings.Add('temperature', $Settings.temperature)
        $BodySettings.Add('max_tokens', $Settings.max_tokens)
        $BodySettings.Add('stream', $False)
        $BodySettings.Add('SystemPrompt', $Settings.SystemPrompt)
        #endregion

        #region Set Opener

        #endregion

        #region Send $Dialog.Messages to Convert-DialogToBody:
        $Body = Convert-LMDialogToBody -DialogMessages ($Dialog.Messages) -ContextDepth $ContextDepth -Settings $BodySettings
        #endregion

        #region send request
        try {$LMOutput = Invoke-LMBlob -Body $Body -CompletionURI $CompletionURI -NoConsoleOut}
        catch {throw $_.Exception.Message}
        #endregion

        #region Construct the assistant Dialog message and append to the Dialog:
        $AssistantMessage = New-LMTemplate -Type DialogMessage
        
        $AssistantMessage.TimeStamp = (Get-Date).ToString()
        $AssistantMessage.temperature = $Settings.temperature
        $AssistantMessage.max_tokens = $Settings.max_tokens
        $AssistantMessage.stream = $False
        $AssistantMessage.ContextDepth = $Settings.ContextDepth
        $AssistantMessage.Role = "assistant"
        $AssistantMessage.Content = "$LMOutput"
        #endregion

        
        #region Append the response to the Dialog::
        $Dialog.Messages.Add($AssistantMessage) | out-null
        #endregion

        #region Update Dialog Object
        $Dialog.Info.Modified = $AssistantMessage.TimeStamp
        #endregion
        
    }

    end {

        If ($SaveDialog){
            # Set the opener
            If (!($OpenerSet)){$Dialog.Info.Opener = (($Dialog.Messages | Sort-Object TimeStamp) | Where-Object {$_.role -eq "user"})[0].Content}

            try {$Dialog | ConvertTo-Json -Depth 5 -ErrorAction Stop | Out-File $DialogFile -ErrorAction Stop}
            catch {Write-Warning "Dialog file save failed"}

            }

            return $LMOutput

        }

}