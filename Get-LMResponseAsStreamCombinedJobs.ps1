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
    catch {throw "Unable to write to $File, which is critical for this archaic, cobbled-together computer alchemy"}

    $StreamSession = New-Object LMStudio.WebRequestHandler

    try {$jobOutput = $StreamSession.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "$File")}
    catch {throw $_.Exception.Message}

      # $line has your line

    $LineIndex = -1
    $StopReading = $False

    do {
        $FileStreamReader = [System.IO.StreamReader]::new($File)

        $FileText = ($FileStreamReader.ReadToEnd() -split '\r\n')

        $FileStreamReader.Close()

        If ($FileText.GetUpperBound(0) -ge $LineIndex){$StopReading = $true}

        else {
        #It "should" be the case that the reader is slower than the writer, because of all these conditions:
            :readloop Foreach ($line in ($FileStreamReader.ReadToEnd() -split '\r\n')){
                
                $LineIndex++

                if ($Line -match "ERROR!?!"){
                    $StopReading = $True    
                    return ([string]($Line -replace 'ERROR!?!',"HALT: ERROR"))
                    break readloop
                }

                if ($Line -match "STOP!?! Cancel Detected"){
                    $StopReading = $True    
                    return ([string]($Line -replace 'ERROR!?!',"HALT: CANCELED"))
                    break readloop
                }

                If ($Line -match "data: [DONE]"){
                    $StopReading = $true
                    return "HALT: COMPLETE"
                    break readloop

                }

                If ($Line -match "data: {"){return ([string]($Line.TrimStart('data: ')))}

            }            

        }

    $JobOutput.Close()
    
    $JobOutput.Dispose()
        
    }
    until ($StopReading -eq $True)
      
    } #Close $StreamJob

    $KillProcedure = {
            
        if (!($KeepJob.IsPresent)){

            Start-Sleep -Milliseconds 500

            $EndJobs = Get-Job | Sort-Object -Descending | ForEach-Object {
                $_ | Stop-Job
                $_ | Remove-Job 
            }
 
        }
        
        If (!($KeepFile.IsPresent)){
        Remove-Item "$File.pid" -Force -ErrorAction SilentlyContinue
        Remove-Item $File -Force -ErrorAction SilentlyContinue
        Remove-Item "$File.stop" -Force -ErrorAction SilentlyContinue
        }

    }

if ($PSVersion -match "5.1"){$StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)}
elseif ($PSVersion -match "7.") {$StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File) -PSVersion 5.1}
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