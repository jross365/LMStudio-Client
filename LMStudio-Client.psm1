#This function prompts for server name and port:
    # it prompts to create a new history file, or to load an existing one. 
    # If loading an existing one, it needs to verify it.
function New-LMConfig { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$ConfigFilePath = "$($Env:USERPROFILE)\Documents\LMStudio-PSClient\lmsc.cfg",

        
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Server,
        
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 65535)
        ][int]$Port,
        
        [Parameter(Mandatory=$false)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$HistoryFilePath,

        [Parameter(Mandatory=$false)][switch]$SkipValidation,

        [Parameter(Mandatory=$false)][switch]$Import,

        [Parameter(Mandatory=$false)][switch]$ReuseHistoryFile
    )#Structure: 
    
    begin {

        #Request Server parameter
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

        #Region Validate History file input
        If (!($PSBoundParameters.ContainsKey('HistoryFilePath'))){
            
            $HistoryFilePathValid = $False

            $DefaultHistoryFilePath = "$($Env:USERPROFILE)\Documents\LMStudio-PSClient\$($ENV:USERNAME)-HF.index"

            Write-Verbose "Default path for history file is $DefaultHistoryFilePath" -Verbose

            $HFPathAnswered = $False

            do {

                $DefaultAnswer = Read-Host "Accept the default? (y/N)"

                If ($DefaultAnswer -ine 'y' -and $DefaultAnswer -ine 'n'){
                    
                    $HFPathAnswered = $False
                    Write-Host "Please enter 'Y' or 'N' (no quotes, but not case sensitive)" -ForegroundColor Yellow

                }
                Else {$HFPathAnswered = $True}

            }
            until ($HFPathAnswered -eq $True)

            switch ($DefaultAnswer){

                {$_ -ieq "n"}{

                    $PathProvided = $False

                    do {
    
                        $HistoryFilePath = Read-host "Please provide a complete file path, including name ($($Env:USERNAME)-HF.cfg recommended)"
                        $PathProvided = (![bool](($null -eq $HistoryFilePath -or $HistoryFilePath.Length -eq 0)))
                    
                    }
                    until ($PathProvided -eq $True)

                }

                {$_ -ieq "y"}{$HistoryFilePath = $DefaultHistoryFilePath}

            }


        } #Close If $null -eq HistoryFilePath

        #Validate History File path
        $HistFileDirPath  = ([System.IO.FileInfo]::new("$HistoryFilePath")).Directory.FullName

        If (!(Test-Path $HistFileDirPath)){

            $CreatePath = $True

            Write-Host "Directory: $HistFileDirPath" -ForegroundColor Yellow

            $CreatePathAnswered = $False

            do {

                $DefaultAnswer = Read-Host "Path doesn't exist. Create it? (y/N)"

                If ($DefaultAnswer -ine 'y' -and $DefaultAnswer -ine 'n'){
                    
                    $CreatePathAnswered = $False
                    Write-Host "Please enter 'Y' or 'N' (no quotes, but not case sensitive)" -ForegroundColor Yellow
                }
                Else {$CreatePathAnswered = $True}

            }
            until ($CreatePathAnswered -eq $True)

            If ($DefaultAnswer -ieq 'n'){throw "Provided directory path must be created. Please rerun New-LMConfig."}
            Else {$CreatePath = $True}

        }

        Else {$CreatePath = $False}

        #endregion

    } #End Begin

    process {

        if (!$SkipVerification){

            If ($HistoryFilePath.Substring(($HistoryFilePath.Length - 6),6) -ine ".index"){$HistoryFilePath = $HistoryFilePath + ".index"}

            $Warnings = 0

            #region Test Model retrieval (webserver connection)
            try {$ModelRetrieval = Get-LMModel -Server $Server -Port $Port -AsTest}
            catch {
                Write-Warning "Unable to connect to server $Server on port $Port. This could be a server issue (Web server started?)"
                $Warnings++
            }
            #endregion
    
            #region Create History File's directory path, format
            try {Set-LMHistoryPath -HistoryFile $HistoryFilePath -CreatePath}
            catch {Write-Warning "Unable to create the history file path."}
            #endregion

        }
    }

    end {

        If ($Warnings -gt 0){
            Write-Host "Attention: " -ForegroundColor White -NoNewline
            Write-Host "$Warning settings could not be verified." -ForegroundColor Yellow
            Write-Host "If these settings are incorrect, please exit and re-run New-LMConfig." -ForegroundColor Green
        }

        #region Set creation variables
        If (!($PSBoundParameters.ContainsKey('ConfigFilePath'))){$ConfigFilePath = "$($Env:USERPROFILE)\Documents\LMStudio-PSClient\lmsc.cfg"}
    
        
        $DialogFolder = $HistoryFilePath.TrimEnd('.index') + '-DialogFiles'
        $GreetingFilePath = $HistoryFilePath.TrimEnd('.index') + '-DialogFiles\hello.greetings'
        $StreamCachePath = "($env:USERPROFILE)\Documents\LMStudio-PSClient\stream.cache"

        $ConfigFileObj = Get-LMTemplate -Type ConfigFile

        $ConfigFileObj.ServerInfo.Server = $Server
        $ConfigFileObj.ServerInfo.Port = $Port
        $ConfigFileObj.FilePaths.HistoryFilePath = $HistoryFilePath
        $ConfigFileObj.FilePaths.GreetingFilePath = $GreetingFilePath
        $ConfigFileObj.FilePaths.StreamCachePath = $StreamCachePath
        $ConfigFileObj.ChatSettings.temperature = 0.7
        $ConfigFileObj.ChatSettings.max_tokens = -1
        $ConfigFileObj.ChatSettings.stream = $True
        $ConfigFileObj.ChatSettings.ContextDepth = 10
        #$ConfigFileObj.URIs.CompletionURI = {} #Maybe
        #$ConfigFileObj.URIs.ModelURI = {} #Maybe
        #endregion

        #region Display information and prompt for creation
        Write-Host "Config File Settings:" -ForegroundColor White

        $ConfigFileObj | Format-List

        Write-Host ""; Write-Host "History File location:" -ForegroundColor Green
        Write-Host "$HistoryFilePath"
        Write-Host ""; Write-Host "Greeting File location:" -ForegroundColor Green
        Write-Host "$GreetingFilePath"
        Write-Host ""; Write-Host "Stream Cachce location:" -ForegroundColor Green
        Write-Host "$StreamCachePath"
        Write-Host ""; Write-Host "The following subdirectory will also be created:" -ForegroundColor Green
        Write-Host "$DialogFolder"
        Write-Host ""; Write-Host "Config File Path:" -ForegroundColor Green
        Write-Host "$ConfigFilePath"

        $Proceed = Read-Host -Prompt "Proceed? (y/N)"
        #endregion

        If ($Proceed -ine "y"){throw "Input other than 'y' provided, halting creation."}
        
        switch ($ReuseHistoryFile.IsPresent){

            $true {
                If (!(Test-Path $HistoryFilePath)){
                    
                    Write-Warning "History File $HistoryFilePath not found, creating."

                    try {@((Get-LMTemplate -Type HistoryEntry)) | ConvertTo-Json | Out-File -FilePath $HistoryFilePath -ErrorAction Stop}
                    catch {throw "History file creation failed: $($_.Exception.Message)"}
                }

                If (!(Test-Path $DialogFolder)){
                    
                    Write-Warning "Dialog Folder $DialogFolder not found, creating."

                    try {mkdir $DialogFolder -ErrorAction Stop | out-null}
                    catch {throw "Dialog folder creation failed ($DialogFolder)"}
                }

            }

            $false {
                try {mkdir $DialogFolder -ErrorAction Stop | out-null}
                catch {throw "Dialog folder creation failed ($DialogFolder)"}
        
                try {@((Get-LMTemplate -Type HistoryEntry)) | ConvertTo-Json | Out-File -FilePath $HistoryFilePath -ErrorAction Stop}
                catch {throw "History file creation failed: $($_.Exception.Message)"}
            }

        } #Close Switch

        If (Test-Path $ConfigFilePath){Remove-Item $ConfigFilePath}

        try {$ConfigFileObj | ConvertTo-Json -Depth 3 -ErrorAction Stop | Out-File $ConfigFilePath -ErrorAction Stop}
        catch {throw "Config file creation failed: $($_.Exception.Message)"}
        

    If ($Import.IsPresent){

        try {$Imported = Import-LMConfig -ConfigFile $ConfigFilePath}
        catch {throw "Unable to import configuration: $($_.Exception.Message)"}

    }

    } #Close End

}

#This function reads the local LMConfigFile.cfg, verifies it (unless skipped), and then writes the values to the $Global:LMStudioVars
function Import-LMConfig { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "Greeting file path does not exist" } else { $true } })]
        [string]$ConfigFile,

        [Parameter(Mandatory=$false)]
        [switch]$Verify        
    )
begin {
    
    #region Import config file
    try {$ConfigData = Get-Content $ConfigFile -ErrorAction Stop | ConvertFrom-Json -Depth 3 -ErrorAction Stop}
    catch {throw $_.Exception.Message}
    #endregion

}#Close Begin
process {

    Initialize-LMVarStore

    $LMVars = @{
        "Server" = ($ConfigData.ServerInfo.Server);
        "Port" = ($ConfigData.ServerInfo.Port);
        "FilePath" = ($ConfigData.FilePaths.HistoryFilePath);
        "Temperature" = ($ConfigData.ChatSettings.temperature);
        "MaxTokens" = ($ConfigData.ChatSettings.max_tokens);
        "Stream" = ([boolean]($ConfigData.ChatSettings.Stream));
        "ContextDepth" = $ConfigData.ChatSettings.ContextDepth;
        "Greeting" = ([boolean]($ConfigData.ChatSettings.Greeting))
    }

    try {Set-LMGlobalVariables @LMVars}
    catch {throw "Set-LMGlobalVariables: $($_.Exception.Message)"}

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
        [Parameter(Mandatory=$true)][ValidateSet('ServerInfo', 'ChatSettings', 'FilePaths')][string]$Branch,
        [Parameter(Mandatory=$true)][hashtable]$Options,
        [Parameter(Mandatory=$false, ParameterSetName='SaveChanges')][switch]$Commit,
        [Parameter(Mandatory=$true, ParameterSetName='SaveChanges')][string]$ConfigFile
    )

    $GlobalKeys = $Global:LMStudioVars.$Branch.GetEnumerator().Name

    $RequestedKeys = $Options.GetEnumerator().Name

    $DiffDeltas = (Compare-Object -ReferenceObject $GlobalKeys -DifferenceObject $RequestedKeys).Where({$_.SideIndicator -eq '=>'})

    If ($CompareKeys.Count -gt 0){throw "Keys not found in $Branch - $($DiffDeltas.InputObject -join ', ')"}

    Foreach ($Key in $RequestedKeys){$Global:LMStudioVars.$Branch.$Key = ($Options.$Key)}

    If ($Commit.IsPresent){

        If (!(Test-Path $ConfigFile)){

            try {"" | Out-File $ConfigFile -ErrorAction Stop}
            catch {throw "Settings applied, but unable to create $ConfigFile to save settings [Set-LMConfigOptions]"}

        }

        try {$Global:LMStudioVars | ConvertTo-Json -depth 4 -error Stop | out-file $ConfigFile -ErrorAction Stop}
        catch {throw "Settings applied, but unable to save settings to $ConfigFile [Set-LMConfigOptions]"}
    }

    }


#This function returns different kinds of objects needed by various functions
function Get-LMTemplate { #Complete
    [CmdletBinding()]
    param(
        # Param1 help description
        [Parameter(Mandatory=$true)]
        [ValidateSet('ConfigFile', 'HistoryEntry', 'ChatGreeting', 'ChatDialog', 'Body')]
        [string]$Type
    )

    $DummyValue = "dummyvalue"

    switch ($Type){

        {$_ -ieq "ConfigFile"}{

            $ServerInfoObj = [pscustomobject]@{
                "Server" = "";
                "Port" = "";
            }

            $FilePathsObj = [pscustomobject]@{
                "HistoryFilePath" = "";
                "GreetingFilePath" = "";
                "StreamCachePath" = "";
            }            

            $ChatSettingsObj = [pscustomobject]@{
                "temperature" = 0.7;
                "max_tokens" = -1;
                "stream" = $True;
                "ContextDepth" = 10;
                "Greeting" = $True;
            }            

            $Object = [pscustomobject]@{"ServerInfo" = $ServerInfoObj; "ChatSettings" = $ChatSettingsObj; "FilePaths" = $FilePathsObj}
        }
        {$_ -ieq "HistoryEntry"}{
            
            $Object = [pscustomobject]@{
                "Created" = "$DummyValue";
                "Modified" = "$DummyValue";
                "Title" = "$DummyValue;"
                "Opener" = "$DummyValue";
                "Model" = "$DummyValue";
                "FilePath" = "$DummyValue"
                "Tags" = @("$DummyValue","$DummyValue")
                }
        
        }
        {$_ -ieq "ChatGreeting"}{

            $Object = [pscustomobject]@{

                "TimeStamp" = "$((Get-Date).ToString())"
                "System" = "Please be polite, concise and informative."; #System Prompt
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

            $DummyRow = [pscustomobject]@{"TimeStamp" = ((Get-Date).ToString()); "temperature" = $Global:LMStudioVars.ChatSettings.temperature; "max_tokens" = $Global:LMStudioVars.ChatSettings.max_tokens; "stream" = $Global:LMStudioVars.ChatSettings.stream; "Role" = "system"; "Content" = "Please be polite, concise and informative."}

            $Messages.Add($DummyRow) | Out-Null

            $Object = [pscustomobject]@{"Info" = $Info; "Messages" = $Messages}

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

                $Object = $Object | ConvertFrom-Json -Depth 3

        }

    } #Close switch

    return $Object

}
#This function builds the hierarchy of hash tables at $Global:LMstudiovars to store configuration information (server, port, history file)
function Initialize-LMVarStore { #Complete
    $Global:LMStudioVars = @{}
    $Global:LMStudioVars.Add("ServerInfo",@{})
    $Global:LMStudioVars.ServerInfo.Add("Server","")
    $Global:LMStudioVars.ServerInfo.Add("Port","")
    $Global:LMStudioVars.Add("FilePaths",@{})
    $Global:LMStudioVars.FilePaths.Add("HistoryFilePath","")
    $Global:LMStudioVars.FilePaths.Add("GreetingFilePath","")
    $Global:LMStudioVars.FilePaths.Add("StreamCachePath","")
    $Global:LMStudioVars.Add("ChatSettings",@{})
    $Global:LMStudioVars.ChatSettings.Add("temperature",0.7)
    $Global:LMStudioVars.ChatSettings.Add("max_tokens",-1)
    $Global:LMStudioVars.ChatSettings.Add("stream",$True)
    $Global:LMStudioVars.ChatSettings.Add("ContextDepth",10)
    $Global:LMStudioVars.ChatSettings.Add("Greeting",$True)
}

#This function sets the Global variables for Server, Port and HistoryFile; it ASSUMES validation has been completed
###I NEED TO IMPLEMENT INPUT VALIDATION ON THIS
function Set-LMGlobalVariables { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][int]$Port,
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$true)][double]$Temperature,
        [Parameter(Mandatory=$true)][int]$MaxTokens,
        [Parameter(Mandatory=$true)][boolean]$Stream,
        [Parameter(Mandatory=$true)][int]$ContextDepth,
        [Parameter(Mandatory=$true)][boolean]$Greeting,
        [Parameter(Mandatory=$false)][switch]$Show       

    )

    try {$VarStoreCheck = $Global:LMStudioVars.GetType().Name}
    catch {Initialize-LMVarStore}

    If ($VarStoreCheck -ne "Hashtable"){Initialize-LMVarStore}
    
    $GreetingFilePath = $FilePath.TrimEnd('.index') + '-DialogFiles\hello.greetings'
    $StreamCachePath = "($env:USERPROFILE)\Documents\LMStudio-PSClient\stream.cache"

    try {$Global:LMStudioVars.ServerInfo.Server = $Server}
    catch {throw "Unable to set Global variable LMStudioServer for value Server: $Server"}
    
    try {$Global:LMStudioVars.ServerInfo.Port = $Port}
    catch {throw "Unable to set Global variable LMStudioServer for value Port: $Port"}

    try {$Global:LMStudioVars.FilePaths.HistoryFilePath = $FilePath}
    catch {throw "Unable to set Global variable LMStudioServer for value History File Path: $FilePath"}

    try {$Global:LMStudioVars.FilePaths.GreetingFilePath = $GreetingFilePath}
    catch {throw "Unable to set Global variable LMStudioServer for value History File Path: $GreetingFilePath"}

    try {$Global:LMStudioVars.FilePaths.StreamCachePath = $StreamCachePath}
    catch {throw "Unable to set Global variable LMStudioServer for value History File Path: $StreamCachePath"}

    try {$Global:LMStudioVars.FilePaths.HistoryFilePath = $FilePath}
    catch {throw "Unable to set Global variable LMStudioServer for value History File Path: $FilePath"}

    try {$Global:LMStudioVars.ChatSettings.temperature = $Temperature}
    catch {throw "Unable to set Global variable LMStudioServer for value Temperature: $Temperature"}

    try {$Global:LMStudioVars.ChatSettings.max_tokens = $MaxTokens}
    catch {throw "Unable to set Global variable LMStudioServer for value Max_Tokens: $Temperature"}

    try {$Global:LMStudioVars.ChatSettings.stream = $Stream}
    catch {throw "Unable to set Global variable LMStudioServer for value Stream: $Stream"}

    try {$Global:LMStudioVars.ChatSettings.ContextDepth = $ContextDepth}
    catch {throw "Unable to set Global variable LMStudioServer for value ContextDepth: $ContextDepth"}

    try {$Global:LMStudioVars.ChatSettings.Greeting = $Greeting}
    catch {throw "Unable to set Global variable LMStudioServer for value ContextDepth: $ContextDepth"}

    If ($Show.IsPresent){$Global:LMStudioVars}

}

#This function validates $Global:LMStudioVars is fully populated
function Confirm-LMGlobalVariables ([switch]$ReturnBoolean) { #INComplete, needs temp,maxtokens,stream additions
    $Errors = New-Object System.Collections.ArrayList

    If ($null -eq $Global:LMStudioVars){$Errors.Add('$Global:LMStudioVars does not exist') | out-null}
    Else {

    #Check ServerInfo
        If ($null -eq $Global:LMStudioVars.ServerInfo){$Errors.Add('$Global.LMStudioVars.ServerInfo does not exist') | out-null}
        Else {
            If ($Global:LMStudioVars.ServerInfo.Server.Length -eq 0 -or $null -eq $Global:LMStudioVars.ServerInfo.Server){$Errors.Add("ServerInfo.Server") | out-null}
            If ($Global:LMStudioVars.ServerInfo.Port.Length -eq 0 -or $null -eq $Global:LMStudioVars.ServerInfo.Port){$Errors.Add("ServerInfo.Port") | out-null}
        }

        #Check ChatSettings
        If ($null -eq $Global:LMStudioVars.ChatSettings){$Errors.Add('$Global.LMStudioVars.ChatSettings does not exist')}
        Else {
            If ($Global:LMStudioVars.ChatSettings.temperature.Length -eq 0 -or $null -eq $Global:LMStudioVars.ChatSettings.temperature){$Errors.Add("ChatSettings.temperature") | out-null}
            If ($Global:LMStudioVars.ChatSettings.max_tokens.Length -eq 0 -or $null -eq $Global:LMStudioVars.ChatSettings.max_tokens){$Errors.Add("ChatSettings.max_tokens") | out-null}
            If ($Global:LMStudioVars.ChatSettings.Stream -ne $True -and $Global:LMStudioVars.ChatSettings.Stream -ne $False){$Errors.Add("ChatSettings.Stream") | out-null}
            If ($Global:LMStudioVars.ChatSettings.ContextDepth -eq 0 -or $null -eq $Global:LMStudioVars.ChatSettings.ContextDepth){$Errors.Add("ChatSettings.ContextDepth") | out-null}
            If ($Global:LMStudioVars.ChatSettings.Greeting -ne $True -and $Global:LMStudioVars.ChatSettings.Greeting -ne $False){$Errors.Add("ChatSettings.Greeting") | out-null}
            }

        #Check FilePaths
        If ($null -eq $Global:LMStudioVars.FilePaths){$Errors.Add('$Global.LMStudioVars.FilePaths does not exist')}
        Else {
            If ($Global:LMStudioVars.FilePaths.HistoryFilePath.Length -eq 0 -or $null -eq $Global:LMStudioVars.FilePaths.HistoryFilePath){$Errors.Add("ServerInfo.HistoryFilePath") | out-null}
            If ($Global:LMStudioVars.FilePaths.GreetingFilePath.Length -eq 0 -or $null -eq $Global:LMStudioVars.FilePaths.GreetingFilePath){$Errors.Add("ServerInfo.GreetingFilePath") | out-null}
            If ($Global:LMStudioVars.FilePaths.StreamCachePath.Length -eq 0 -or $null -eq $Global:LMStudioVars.FilePaths.StreamCachePath){$Errors.Add("ServerInfo.StreamCachePath") | out-null}
            }
    }

    Switch ($ReturnBoolean.IsPresent){

        $True {
        
            If ($Errors.Count -gt 0){return $False}
            Else {return $True}
        
        }

        $False {

            If ($Errors.Count -gt 0){throw "Properties missing values: $($Errors -join ', ')"}

        }

    } #Close Switch

}

# This function "Carves The Way" to the path where the history file should be saved. 
# It verifies the path validity and tries to create the path, if specified

function Set-LMHistoryPath { #Complete
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$HistoryFile,

        [Parameter(Mandatory=$false)]
        [switch]$CreatePath
    )

    If (!($PSBoundParameters.ContainsKey('HistoryFile'))){throw "Please enter a valid path to the history file"}

    $HistFileDirs = $HistoryFile -split '\\'

    $HistFileDirs = $HistFileDirs[0..($HistFileDirs.GetUpperBound(0) -1)]

    $HistoryFolder = $HistFileDirs -join '\'

    
    If (!(Test-Path $HistoryFolder) -and (!($CreatePath.IsPresent))){throw "Directory path $HistoryFolder does not exist. Please specify -CreatePath parameter."}
    ElseIf (Test-path $HistoryFolder){Write-Verbose "Folder path $HistoryFolder exists, path creation not necessary"}
    else {
        $PresentDir = (Get-Location).Path

        $Drive = $HistFileDirs[0]
        
        try {&$Drive}
        catch {throw "Drive $Drive is not valid or accessible"}

        Set-Location -Path $PresentDir | Out-Null

        (1..($HistFileDirs.GetUpperBound(0))) | Foreach-Object {

            $Index = $_

            $SubDir = $HistFileDirs[$Index]

            $FullSubDirPath = $HistFileDirs[0..$Index] -join '\'

            If (!(Test-Path $FullSubDirPath)){

                try {$CreateDirectory = mkdir -Path $FullSubDirPath -ErrorAction Stop}
                catch {throw "Error creating $SubDir : $($_.Exception.Message)"}

            }


        }  #Close (1..) | foreachObject
        
    } #Close Else

    return $True
  
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
        try {$HistoryContent = Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -Depth 4 -ErrorAction Stop}
        catch {throw "Unable to import history file $FilePath : $($_.Exception.Message))"}
        #endregion

        #region Validate columns and first entry of the history file:

    }

    process {
    
        $HistoryColumns = (Get-LMTemplate -Type HistoryEntry).psobject.Properties.Name
        $FileColumns = $HistoryContent.psobject.Properties.name

        $ColumnComparison = Compare-Object -ReferenceObject $HistoryColumns -DifferenceObject $FileColumns

        If ($ColumnComparison.Count -eq 0){$ValidContents = $True}
        If ($ColumnComparison.Count -gt 0){$ValidContents = $False}

    #region If not a test, move over content from Fixed-Length arrays to New ArrayLists:
    If (!($AsTest.IsPresent)){
    
        $NewHistory = @((Get-LMTemplate -Type HistoryEntry))

        $HistoryContent.Histories | ForEach-Object {$NewHistory += ($_)}
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

}

#This function saves a history entry to the history file
function Update-LMHistoryFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({ if ($_.GetType().GetType().Name -ne "PSCustomObject"){throw "Expected object of type [pscustomobject]"} else { $true } })]
        [pscustomobject]$Entry,
        
        [Parameter(Mandatory=$False)]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$FilePath
        )

    begin {

        #region Validate $Entry:
        $StandardFields = (Get-LMTemplate -Type HistoryEntry).psobject.Properties.Name

        $EntryFields = $Entry.PSObject.Properties.Name

        $FieldsCheck = Compare-Object -ReferenceObject $StandardFields -DifferenceObject $EntryFields

        If ($FieldsCheck.Count -ne 0){throw "The provided Entry does contain the required fields ($($StandardFields -join ', '))"}
        #endregion

        #region Check history file location in global variables, or use provided FilePath
        If (!($PSBoundParameters.ContainsKey('FilePath'))){

            try {$HistoryFileCheck = Confirm-LMGlobalVariables}
            catch {throw "Error validating Global variables: $($_.Exception.Message)"}
        
            If ($HistoryFileCheck -ne $True){throw "Something went wrong when running Confirm-LMGlobalVariables (didn't return True)"}
        
            $FilePath = $Global:LMStudioVars.FIlePaths.HistoryFilePath
    
        }
        
        If (!(Test-Path $FilePath)){throw "Provided history file path is not valid or accessible ($FilePath)"}

    }

    process {

        try {$History = Import-LMHistoryFile -FilePath $FilePath}
        catch {throw "History File import (for write) failed: $($_.Exception.Message)"}

        try {$AppendEntry = $History.Histories.Add($Entry)}
        catch {throw "Unable to append Entry to history file (is file malformed?)"}
    }

    end {
        try {$History | ConvertTo-Json -Depth 10 -ErrorAction Stop | Out-File -FilePath $FilePath -ErrorAction Stop}
        catch {throw "Unable to save history to File Path; $($_.Exception.Message)"}
    
        return $True

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
                throw "Required variables (Server, Port) are missing, and `$Global:LMStudioVars is not populated. Please run Set-LMGlobalVariables or Import-LMConfig"
    
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

#This function imports a chat dialog from a dialog file (used for "continuing a conversation")
function Import-LMChatDialog (){

    #The general idea:
$DialogTemplate = New-LMChatDialogTemplate

$DialogContents = Get-Content $DialogFile | ConvertFrom-Json -depth 2

$MessageContents = $DialogContents.Messages | ConvertFrom-Csv

}

#This function saves a chat dialog to a dialog file, and updates the history file
function Update-LMChatDialog {}

#Searches the HistoryFile for strings and provides multiple ways to output the contents
function Search-LMChatDialog { #NOT STARTED

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
function Show-LMHelp { #INCOMPLETE
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = “LMStudio-PSClient Help”
    $Messageboxbody = “!h - Displays this help`r`n!s - Change the system prompt`r`n!t - Change the temperature`r`n!f - Change the history file`r`n!q - Save and Quit”
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

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
        [Parameter(Mandatory=$true)][pscustomobject]$Body
        )
}

#This function establishes an asynchronous connection to "stream" chat output to the console
function Invoke-LMStream{ #Complete
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
    
        $jobOutput = Receive-Job $RunningJob
        
        :oloop foreach ($Line in $jobOutput){

            If ($Fragmented){ #Added this to try to reassemble fragments, troubleshooting 05/14
                    $Line = "$Fragment" + "$Line"
                    Remove-Variable Fragment
                    $Fragmented = $False
            } 

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
                    
                #$TrimLine = $Line.TrimStart("data: ")
                
                #Added this to reassemble fragments: 

                try {
                $LineAsObj = ($Line.TrimStart("data: ")) | ConvertFrom-Json
                }
                catch {
                       $Fragment = $LineAsObj
                       $Fragmented = $True
                        break oloop
                }
                
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

#This function initiates a "greeting"
function Start-LMGreeting {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName='Auto')]
        [switch]$UseLoadedConfig,
        
        [Parameter(Mandatory=$true, ParameterSetName='Manual')]
        [ValidateScript({ if ([string]::IsNullOrEmpty($_)) { throw "Parameter cannot be null or empty" } else { $true } })]
        [string]$Server,
        
        [Parameter(Mandatory=$true, ParameterSetName='Manual')]
        [ValidateRange(1, 65535)][int]$Port,
        
        [Parameter(Mandatory=$false, ParameterSetName='Manual')]
        [ValidateScript({ if (!(Test-Path -Path $_)) { throw "Greeting file path does not exist" } else { $true } })]
        [string]$GreetingFile,
        
        [Parameter(Mandatory=$false, ParameterSetName='Manual')]
        [boolean]$Stream
        )

begin {

    #region Evaluate and set Variables
    switch ($UseLoadedConfig.IsPresent){

        $True {
            If ((Confirm-LMGlobalVariables -ReturnBoolean) -eq $false){throw "Config file variables not loaded, run [Import-ConfigFile] to load them"}
            
            $Server = $Global:LMStudioVars.ServerInfo.Server
            $Port = $Global:LMStudioVars.ServerInfo.Port
            $GreetingFile = $global:LMStudioVars.FilePaths.GreetingFilePath
            $StreamCachePath = $Global:LMStudioVars.FilePaths.StreamCachePath
            $UseGreetingFile = ([boolean](Test-Path -Path $GreetingFile))
            $Stream = $Global:LMStudioVars.ChatSettings.stream
            $Temperature = $Global:LMStudioVars.ChatSettings.temperature
            $MaxTokens = $Global:LMStudioVars.ChatSettings.max_tokens
        }

        $False {
            $UseGreetingFile = $PSBoundParameters.ContainsKey('GreetingFile')
            $StreamCachePath = (Get-Location).Path + '\lmstream.cache'
            If (!$PSBoundParameters.ContainsKey('Stream')){$Stream = $True} #Stream by Default
            $Temperature = 0.7 #Default
            $MaxTokens = -1 #Default
        }
    
    }
    #endregion

    #region Load greeting file
    If ($UseGreetingFile){

        try {$GreetingData = Import-csv $GreetingFile -ErrorAction Stop}
        catch {
            Write-Host "Notice: Unable to import greeting file" -ForegroundColor Blue
            $UseGreetingFile = $False
            }
    }
    #endregion

    #region Set Endpoint information
    $Endpoint = "$Server" + ":" + "$Port"
    $CompletionURI = "http://$Endpoint/v1/chat/completions"
    #endregion
 
}

process {
    
    #region Get the model and prep the body
    try {$Model = Get-LMModel -Server $Server -Port $Port}
    catch {throw $_.Exception.Message}

    $GreetingPrompt = New-LMGreetingPrompt
    
    $Body = Get-LMTemplate -Type Body
    $Body.model = $Model
    $Body.temperature = $Temperature
    $Body.max_tokens =  $MaxTokens
    $Body.Stream = $Stream
    $Body.messages[0].content = "You are a helpful, smart, kind, and efficient AI assistant. You always fulfill the user's requests to the best of your ability."
    $Body.messages[1].content = $GreetingPrompt
    #endregion

    #region If using a Greeting File, prep the Body with context    
    If ($UseGreetingFile){

        If ($NewFile){

            $GreetingData[0].TimeStamp = (Get-Date).ToString()
            $GreetingData[0].System = $Body.messages[0].content
            $GreetingData[0].User = $Body.messages[1].content
            $GreetingData[0].Model = "$Model"        
            $GreetingData[0].Temperature = $Temperature
            $GreetingData[0].Max_Tokens = $MaxTokens
            $GreetingData[0].Stream = $Stream
            $GreetingData[0].ContextDepth = $global:LMStudioVars.ChatSettings.ContextDepth

        }

        Else { #We have to put the previous requests in Q/A order:

            $ContextEntries = $GreetingData | Select-Object -Last ([int]($ContextDepth / 2))

            $ContextMessages = New-Object System.Collections.ArrayList
            
            $ContextMessages.Add([pscustomobject]@{"role" = "system"; "content" = "$($Body.messages[0].content)"})

            Foreach ($Entry in $ContextEntries){

                $ContextMessages.Add([pscustomobject]@{"role" = "user"; "content" = "$($Entry.User)"})
                $ContextMessages.Add([pscustomobject]@{"role" = "assistent"; "content" = "$($Entry.Assistant)"})

            }

            $ContextMessages.Add([pscustomobject]@{"role" = "user"; "content" = "$($Body.messages[1].content)"})

            $Body.messages = $ContextMessages

        }

    } #Close If UseGreetingFile
    #endregion

    Write-Host "You: " -ForegroundColor Green -NoNewline; Write-Host "$GreetingPrompt"
    Write-Host ""
    Write-Host "AI: " -ForegroundColor Magenta -NoNewline
    
    $ServerResponse = Invoke-LMStream -CompletionURI $CompletionURI -Body $Body -File $StreamCachePath

    Write-Host ""
}

end {}

}

#This function is the LM Studio Client
function Start-LMChat { #INCMPLETE
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False)][string]$Server,
        [Parameter(Mandatory=$false)][ValidateRange(1, 65535)][int]$Port = 1234,
        [Parameter(Mandatory=$false)][string]$HistoryFile = $Global:LMStudioVars.FIlePaths.HistoryFilePath,
        [Parameter(Mandatory=$false)][double]$Temperature = 0.7,
        [Parameter(Mandatory=$false)][switch]$SkipGreeting,
        [Parameter(Mandatory=$false)][ValidateSet('Stream', 'Blob')][string]$ResponseType
        #[Parameter(Mandatory=$false)][switch]$NoTimestamps, #Not sure what to do with this, or where to hide the timestamps
        )
    
    begin {
    
        
        #region Prerequisite Variables
        $OrigProgPref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $ReplayLimit = 10 #Sets the max number of assistant/user content context entries    
    
        $Version = "0.5" #Could pull this information from the Module version information    
        
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
        If (!($PSBoundParameters.ContainsKey('HistoryFile'))){$HistoryFile = $Global:LMStudioVars.FIlePaths.HistoryFilePath}
    
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
            $NewGreeting = New-LMGreetingPrompt
            
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
    

function Start-LMChatLite {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$false)][ValidateRange(0, 65535)][int]$Port = 1234,
        [Parameter(Mandatory=$false)][string]$HistoryFile = $Global:LMStudioVars.FIlePaths.HistoryFilePath,
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
        If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$HistoryFile = $Global:LMStudioVars.FIlePaths.HistoryFilePath}
    
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
            $NewGreeting = New-LMGreetingPrompt
            
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
    