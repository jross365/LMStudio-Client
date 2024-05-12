function Invoke-LMStream{
    [CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$CompletionURI,
    [Parameter(Mandatory=$true)][pscustomobject]$Body,
    [Parameter(Mandatory=$true)][string]$File,
    [Parameter(Mandatory=$false)][switch]$KeepJobs,
    [Parameter(Mandatory=$false)][switch]$KeepFiles
    )

    begin {

        #region Define Jobs

    $PSVersion = "$($PSVersionTable.PSVersion.Major)" + '.' + "$($PSVersionTable.PSVersion.Minor)"
    
    $StreamJob = {
    
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
                            await fileWriter.WriteLineAsync("ERROR!?! Method Cancelled");
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

"" | out-file $File -Encoding utf8

$StreamSession = New-Object LMStudio.WebRequestHandler

$jobOutput = $StreamSession.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "$File")

#I could probably put the reader into this code as well, and consolidate my jobs
#return $jobOutput
#$jobOutput

}

    $ParseJob = {

        $File = $args[0]
        $FileExists = $False
        $x = 0
        do {

            $FileExists = Test-Path $File
            Start-Sleep -Milliseconds 250
            $x++

        }
        until (($FileExists -eq $True) -or ($x -eq 10))

        If ($FileExists -eq $False){throw "Unable to find $File"}
        Else {Get-Content $File -Tail 4 -Wait}

    }

    $KillProcedure = {
        
        If ($Complete -ne $true){
            try {
                #$LMStreamPID = Get-Content "$File.pid" -First 1 -ErrorAction Stop
                #Write-Verbose "$(&C:\Windows\System32\taskkill.exe /PID $LMStreamPID /F)" -Verbose
                #Stop-Process -Id $LMStreamPID -Force -ErrorAction Stop
            }
            catch {Write-Warning "Unable to read `$File.pid: $($_.Exception.Message)"}
        }
        if (!($KeepJobs.IsPresent)){

            Start-Sleep -Milliseconds 500

            $EndJobs = Get-Job | Sort-Object -Descending | ForEach-Object {
                $_ | Stop-Job
                $_ | Remove-Job 
            }
 
        }
        
        If (!($KeepFiles.IsPresent)){
        Remove-Item "$File.pid" -Force -ErrorAction SilentlyContinue
        Remove-Item $File -Force -ErrorAction SilentlyContinue
        Remove-Item "$File.stop" -Force -ErrorAction SilentlyContinue
        }

    }

if ($PSVersion -match "5.1"){
    $StartParseJob = Start-Job -ScriptBlock $ParseJob -ArgumentList @($File)
    $StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)
}
elseif ($PSVersion -match "7.") {
    $StartParseJob = Start-Job -ScriptBlock $ParseJob -ArgumentList @($File) -PSVersion 5.1
    $StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File) -PSVersion 5.1
}
else {throw "PSVersion $PSVersion doesn't match 5.1 or 7.x"}

#Used to force-kill the job, if necessary

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
    
        $jobOutput = Receive-Job $StartParseJob #| Where-Object {$_ -match 'data:' -or $_ -match '|ERROR!?!'} #Need to move this into :oloop 
    
        :oloop foreach ($Line in $jobOutput){

            if ($Line -match "ERROR!?!"){
            
                &$KillProcedure
                throw "Exception: $($Line -replace 'ERROR!?!')"
            }
            elseif ($Line -match "data: [DONE]"){break oloop}
            elseif ($Line -notmatch "data: "){continue oloop}
            else {
    
                $LineAsObj = $Line.TrimStart('data: ') | ConvertFrom-Json
                
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