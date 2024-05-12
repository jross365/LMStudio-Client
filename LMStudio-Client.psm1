#This function prompts for server name and port:
    # it prompts to create a new history file, or to load an existing one. 
    # If loading an existing one, it needs to verify it.
function New-LMConfigFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$Server,
        [Parameter(Mandatory=$false)][int]$Port,
        [Parameter(Mandatory=$false)][string]$HistoryFilePath,
        [Parameter(Mandatory=$false)][switch]$SkipValidation,
        [Parameter(Mandatory=$false)][switch]$Import
    )#Structure: 

    begin {

        #region Validate Server input
        If ($null -eq $Server -or $Server.Length -eq 0){

            $InputAccepted = $false

            do {
                $Server = Read-Host "Please provide a valid server hostname or IP address"
                $InputAccepted = (!([boolean]($null -eq $Server -or $Server.Count -eq 0)))
            }
            until ($InputAccepted -eq $true)

        }
        #endregion

        #region Validate Port input
        $PortValid = $False

        try {
            $PortAsInt = [int]$Port
            $PortValid = $True
            If ($PortAsInt -lt 0 -or $PortAsInt -gt 65535){$PortValid = $False}
        }
        catch {$PortValid = $False}

        If (($null -eq $Port -or $Port.Length -eq 0) -or (!$PortValid)){

            $InputAccepted = $false

            do {
                $Port = Read-Host "Please provide a port (0-65535)"

                $InputValid = $False

                try {
                    $PortAsInt = [int]$Port
                    $InputValid = $True
                    If ($PortAsInt -lt 0 -or $PortAsInt -gt 65535){$InputValid = $False}
                }
                catch {$InputValid = $False}
                
            }
            until ($InputAccepted -eq $true)

        }
        #endregion

        #Region Validate History file input
        If ($null -eq $HistoryFilePath -or $HistoryFilePath.Length -eq 0){
            
            $HistoryFilePathValid = $False

            $DefaultHistoryFilePath = "$($Env:USERPROFILE)\Documents\WindowsPowershell\Modules\LMStudio-Client\$($ENV:USERNAME)-HF.cfg"

            Write-Verbose: "Default path for history file is $DefaultHistoryFilePath"

            $HFPathAnswered = $False

            do {

                $DefaultAnswer = Read-Host "Accept the default? (y/N)"

                If ($DefaultAnswer -ine 'y' -and $DefaultAnswer -ine 'n'){
                    
                    $HFPathAnswered = $False
                    Write-Verbose "Please enter 'Y' or 'N' (no quotes, but not case sensitive)" -Verbose

                }
                Else {$HFPathAnswered = $False}

            }
            until ($HFPathAnswered -eq $True)

            If ($DefaultAnswer -ieq "n"){

                $PathProvided = $False

                do {

                    $HistoryFilePath = Read-host "Please provide a complete file path, including name ($($Env:USERNAME)-HF.cfg recommended)"
                    $PathProvided = (![bool](($null -eq $HistoryFilePath -or $HistoryFilePath.Length -eq 0)))
                
                }
                until ($PathProvided -eq $True)

            }

        }

        #Validate History File path
        $HistFileDirPath  = ([System.IO.FileInfo]::new("$HistoryFilePath")).Directory.FullName

        If (!(Test-Path $HistFileDirPath)){

            $CreatePath = $True

            Write-Verbose "Chosen: $HistFileDirPath)" -Verbose

            $CreatePathAnswered = $False

            do {

                $DefaultAnswer = Read-Host "Path doesn't exist. Create it? (y/N)"

                If ($DefaultAnswer -ine 'y' -and $DefaultAnswer -ine 'n'){
                    
                    $CreatePathAnswered = $False
                    Write-Verbose "Please enter 'Y' or 'N' (no quotes, but not case sensitive)" -Verbose

                }
                Else {$CreatePathAnswered = $False}

            }
            until ($CreatePathAnswered -eq $True)

            If ($DefaultAnswer -ine 'n'){throw "Provided directory path must be created. Please rerun New-LMConfigFile."}

        }

        Else {$CreatePath = $False}

        #endregion

    } #End Begin

    process {

        if (!$SkipVerification){

            If ($HistoryFile.Substring(($HistoryFile.Length - 6),6) -ine ".index"){$HistoryFile = $HistoryFile + ".index"}

            $Warnings = 0

            #region Test Model retrieval (webserver connection)
            try {$ModelRetrieval = Get-LMModel -Server $Server -Port $Port -AsTest}
            catch {
                Write-Warning "Unable to connect to server $Server on port $Port. This could be a server issue (Web server started?)"
                $Warnings++
            }
            #endregion
    
            #region Test History File path, format
            try {Set-LMHistoryPath -HistoryFile $HistoryFilePath -CreatePath}
            catch {Write-Warning "Unable to create the history file path."}
            #endregion

        }

    }

    end {

        If ($Warnings -gt 0){
            Write-Host "Attention: " -ForegroundColor Yellow -NoNewline
            Write-Host "$Warning settings could not be verified." -ForegroundColor Green
            Write-Host "If these settings are incorrect, please exit and re-run New-LMConfigFile." -ForegroundColor Green
        }

        #region Set creation variables
        $ConfigFilePath = "$($Env:USERPROFILE)\Documents\WindowsPowerShell\Modules\LMStudio-Client\lmsc.cfg"
        
        $DialogFolder = $HistoryFilePath.TrimEnd('.index') + '\' + "$(([System.IO.FileInfo]::new("$HistoryFilePath")).Name.TrimEnd('.index'))"

        $ConfigFileObj = [pscustomobject]@{"Server"=$Server; "Port"=$Port; "HistoryFilePath"=$HistoryFilePath}
        #endregion

        #region Display information and prompt for creation
        Write-Host "Config File Settings:" -ForegroundColor Yellow

        $ConfigFileObj | Format-List

        Write-Host ""; Write-Host "History File location:" -ForegroundColor Yellow

        Write-Host "Directory: $HistoryFilePath"

        Write-Host "The following subdirectory will also be created:"

        Write-Host "Directory: $DialogFolder"

        $Proceed = Read-Host -Prompt "Proceed? (y/N)"
        #endregion

        If ($Proceed -ine "y"){throw "Input other than 'y' provided, halting creation."}
        Else {

            try {mkdir $DialogFolder -ErrorAction Stop}
            catch {throw "Dialog folder creation failed ($DialogFolder)"}

            try {New-LMHistoryFile -FilePath $HistoryFilePath -ErrorAction Stop}
            catch {throw "History file creation failed: $($_.Exception.Message)"}

            try {$ConfigFileObj | ConvertTo-Json -Depth 2 -ErrorAction Stop | Out-File $ConfigFilePath -ErrorAction Stop}
            catch {throw "Config file creation failed: $($_.Exception.Message)"}
        }

    If ($Import.IsPresent){

        try {$Imported = Import-LMConfigFile -ConfigFile $ConfigFilePath -SkipVerification}
        catch {throw "Unable to import configuration: $($_.Exception.Message)"}

    }

    } #Close End

}

#This function reads the local LMConfigFile.cfg, verifies it (unless skipped), and then writes the values to the $Global:LMStudioVars
function Import-LMConfigFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$ConfigFile,
        [Parameter(Mandatory=$false)][switch]$SkipVerification
    )
begin {
    
    #region Import config file
    try {$ConfigData = Get-Content $ConfigFile -ErrorAction Stop | ConvertFrom-Json -Depth 2 -ErrorAction Stop}
    catch {throw $_.Exception.Message}
    #endregion

    #region Verify config file properties exist:
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

}#Close Begin
process {

    if (!$SkipVerification){

        #region Test Model retrieval (webserver connection)
        try {$ModelRetrieval = Get-LMModel -Server $ConfigData.Server -Port $ConfigData.Port -AsTest}
        catch {throw $($_.Exception.Message)}

        If ($ModelRetrieval -ne $True){throw "Unable to connect to server $($ConfigData.Server) on port $($ConfigData.Port). This could be a server issue (Web server started?)"}
        #endregion

        #region Test History File path, format
        If (Test-Path $ConfigFile.HistoryFilePath){throw "History file path $($ConfigData.HistoryFilePath) is not valid or accessible. Please check the path."}

        try {$CheckHistoryFile = Import-LMHistoryFile -FilePath $ConfigData.HistoryFilePath -AsTest}
        catch {throw "History file format validation failed: $($_.Exception.Message)"}

        If ($CheckHistoryFile -ne $true){throw "History file format validation failed for $($ConfigData.HistoryFilePath)"}
        #endregion        
        }

    } #Close Process
end {

    Initialize-LMVarStore

    $LMVars = @{
        "Server" = ($ConfigData.Server);
        "Port" = ($ConfigData.Port);
        "FilePath" = ($ConfigData.HistoryFilePath)
    }

    try {Set-LMGlobalVariables @LMVars}
    catch {throw "Unable to set Global variables"}

    } #Close End
}

#This function builds the hierarchy of hash tables at $Global:LMstudiovars to store configuration information (server, port, history file)
function Initialize-LMVarStore { #Complete
    $Global:LMStudioVars = @{}
    $Global:LMStudioVars.Add("ServerInfo",@{})
    $Global:LMStudioVars.ServerInfo.Add("Server","")
    $Global:LMStudioVars.ServerInfo.Add("Port","")
    $Global:LMStudioVars.Add("HistoryFilePath","")

}

#This function sets the Global variables for Server, Port and HistoryFile; it ASSUMES validation has been completed
function Set-LMGlobalVariables { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][string]$Server,
        [Parameter(Mandatory=$true)][int]$Port,
        [Parameter(Mandatory=$true)][string]$FilePath,
        [Parameter(Mandatory=$false)][switch]$Show       

    )

    try {$VarStoreCheck = $Global:LMStudioVars.GetType().Name}
    catch {Initialize-LMVarStore}

    If ($VarStoreCheck -ne "Hashtable"){Initialize-LMVarStore}

    try {$Global:LMStudioVars.ServerInfo.Server = $Server}
    catch {throw "Unable to set Global variable LMStudioServer for value Server: $Server"}
    
    try {$Global:LMStudioVars.ServerInfo.Port = $Port}
    catch {throw "Unable to set Global variable LMStudioServer for value Port: $Port"}

    try {$Global:LMStudioVars.HistoryFilePath = $FilePath}
    catch {throw "Unable to set Global variable LMStudioServer for value History File Path: $FilePath"}

    If ($Show.IsPresent){$Global:LMStudioVars}

}

#This function validates $Global:LMStudioVars is fully populated
#CAN PROBABLY REMOVE THIS FUNCTION, error checking is part of all of the import/export processes
function Confirm-LMGlobalVariables { #Complete

    If ($null -eq $Global:LMStudioVars){throw "Please run Set-LMSGlobalVariables first."}
    
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

function Set-LMHistoryPath ([string]$HistoryFile,[switch]$CreatePath){ #Complete
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

}


#This function generates and returns an empty history file template with dummy entries (doesn't save)
function New-LMHistoryFileTemplate ([switch]$NoDummyEntries){ #Complete

    $Histories = New-Object System.Collections.ArrayList

    If ($NoDummyEntries.IsPresent){$DummyValue = ""}
    Else {$DummyValue = "dummyvalue"}
    
    $Entry = [pscustomobject]@{
        "Created" = "$DummyValue";
        "Modified" = "$DummyValue";
        "Title" = "$DummyValue;"
        "Opener" = "$DummyValue";
        "Model" = "$DummyValue";
        "FilePath" = "$DummyValue"
        "Tags" = @("$DummyValue","$DummyValue")
        }

    $Histories.Add($Entry) | out-null
    
    $History = [pscustomobject]@{"Histories" = $Histories}

    return $History       

}

#This function Creates a new (empty) history file
function New-LMHistoryFile ([string]$FilePath){ #Complete
    
    $HistoryTemplate = New-LMHistoryFileTemplate

    try {$HistoryTemplate | ConvertTo-Json -Depth 3 -ErrorAction Stop | Out-File $FilePath -ErrorAction Stop}
    catch {Throw "Unable to create new history file: $($_.Exception.Message)"}

}

#This function imports the content of an existing history file, for either use or to verify the format is correct
function Import-LMHistoryFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$FilePath,
        [Parameter(Mandatory=$false)][switch]$AsTest
        )

    begin {

        #region Validate FilePath
        If ($null -eq $FilePath -or $FilePath.Length -eq 0){

             try {$HistoryFileCheck = Confirm-LMGlobalVariables}
            catch {throw "Required variables (Server, Port) are missing, and `$Global:LMStudioVars is not populated. Please run Set-LMGlobalVariables or Import-LMConfigFile"}
           
            $FilePath = $Global:LMStudioVars.HistoryFilePath
        
            }
        #endregion

        #region Import the History file
        try {$HistoryContent = Get-Content $FilePath -ErrorAction Stop | ConvertFrom-Json -Depth 3 -ErrorAction Stop}
        catch {throw "Unable to import history file $FilePath : $($_.Exception.Message))"}
        #endregion

        #region Validate columns and first entry of the history file (for "dummy" content):
        $HistoryColumns = @("FilePath","Created","Title","Tags","Modified","Model","Opener")

        $FileErrors = -1

        $FirstEntry = $HistoryContent.Histories[0]

        Foreach ($Column in $HistoryColumns){

            If (($FirstEntry.$Column.Length -eq 0 -or $null -eq $FirstEntry.$Column) -and $FirstEntry.$Column -inotmatch "dummy"){
                Write-Error "Column $Column of history file $FilePath does not contain the expected 'dummy' value"
                $FileErrors++
            }

        }
        #endregion

        #region Report back errors, and throw:
        If ($FileErrors -ne -1){
            if ($ErrorActionPreference -eq 'SilentlyContinue' -and !(($AsTest.IsPresent))){
                
                Write-Host "Errors encountered:" -ForegroundColor Red
                $Error[0..$FileErrors] | Foreach-Object {Write-Host "$($_.Exception.Message)"}

            }

            throw "Errors encountered when validating history file $FilePath columns ($($HistoryColumns -join ', '))"

        } #Close FileErrors -ne -1
        #endregion

    }

    process {
    
    #region If not a test, move over content from Fixed-Length arrays to New ArrayLists:
    If (!($AsTest.IsPresent)){
    
        $NewHistory = New-LMHistoryFileTemplate -NoDummyEntries

        $HistoryContent.Histories | ForEach-Object {$NewHistory.Histories.Add($_) | Out-Null}
    }
    #endregion

    } #Close Process

    end {
    
        If ($AsTest.IsPresent){return $True}
        else {return $NewHistory}
    
    }

} #Close Function

#This function reads the contents of a dialog folder, and rebuilds a history file from the contents
function Repair-LMHistoryFile {

}

#This function creates a new history file entry: not sure if I need this function
function New-LMHistoryEntryTemplate {}

#This function saves a history entry to the history file
function Update-LMHistoryFile { #Complete
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)][pscustomobject]$Entry,
        [Parameter(Mandatory=$False)][string]$FilePath
        )

    begin {

        #region Validate $Entry:
        $StandardFields = @("Created","Modified","Title""Model","Opener","FilePath","Tags")

        $EntryFields = $Entry.PSObject.Properties.Name

        $FieldsCheck = Compare-Object -ReferenceObject $StandardFields -DifferenceObject $EntryFields

        If ($FieldsCheck.Count -ne 0){throw "The provided Entry does contain the required fields ($($StandardFields -join ', '))"}
        #endregion

        #region Check history file location in global variables, or use provided FilePath
        If ($null -eq $FilePath -or $FilePath.Length -eq 0){

            try {$HistoryFileCheck = Confirm-LMGlobalVariables}
            catch {throw "Error validating Global variables: $($_.Exception.Message)"}
        
            If ($HistoryFileCheck -ne $True){throw "Something went wrong when running Confirm-LMGlobalVariables (didn't return True)"}
        
            $FilePath = $Global:LMStudioVars.HistoryFilePath
    
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
        [Parameter(Mandatory=$false)][string]$Server,
        [Parameter(Mandatory=$false)][int]$Port,
        [Parameter(Mandatory=$false)][switch]$AsTest

    )

    If (($null -eq $Server -or $Server.Length -eq 0) -or ($null -eq $Port -or $Port.Length -eq 0)){

        try {$VariablesCheck = Confirm-LMGlobalVariables}
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

#This function creates an empty object for creating a greeting file
function New-LMGreetingTemplate {}

#This function imports the greetings from the greeting file (used for setting greeting context)
function Import-LMGreetingDialog {
}

#This function saves a greeting to the greeting file (if the switch is specified)
function Update-LMGreetingDialog {
}

#This function creates an empty object for creating a Chat dialog
function New-LMChatDialogTemplate {

    #region This was taken from New-LMHistoryFileTemplate:
    try {
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
    #endregion

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
    $MessageboxTitle = “LMStudio-Client Help”
    $Messageboxbody = “!h - Displays this help`r`n!s - Change the system prompt`r`n!t - Change the temperature`r`n!f - Change the history file`r`n!q - Save and Quit”
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

}

#This function generates a greeting prompt for an LLM, for load in the LMChatClient
function New-LMGreetingPrompt { #INCOMPLETE
    
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

#This function invokes a synchronous connection to "blob" chat output to the console
function Invoke-LMBlob { #NOT STARTED
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

#This function initiates a "greeting"
function Get-LMGreeting { #NOT STARTED
}

#This function is the LM Studio Client
function Start-LMChat { #INCMPLETE
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
        If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$HistoryFile = $Global:LMStudioVars.HistoryFilePath}
    
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
        If ($null -eq $HistoryFile -or $HistoryFile.Length -eq 0){$HistoryFile = $Global:LMStudioVars.HistoryFilePath}
    
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
    