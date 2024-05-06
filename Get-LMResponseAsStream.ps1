function Invoke-LMStream{
    [CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$CompletionURI,
    [Parameter(Mandatory=$true)][pscustomobject]$Body,
    [Parameter(Mandatory=$true)][string]$File
    )

    begin {

        #region Define Jobs


$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]    
    $File = $args[2]

    "$PID" | out-File "$File.pid"

$PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class LMStudio {  
     public static string PostDataForStream(string url, string data, string contentType, string outFile) 
     {   
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);  
        byte[] byteArray = System.Text.Encoding.UTF8.GetBytes(data);  
        request.ContentLength = byteArray.Length;  
        request.ContentType = contentType;   
        request.Method = "POST"; 
              
         try {    
            using (Stream dataStream = request.GetRequestStream()) {     
                dataStream.Write(byteArray, 0, byteArray.Length);      
             }   
             
             using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {  
                 Stream streamResponse = response.GetResponseStream();
                 string responseData="";   // To hold the received chunks of text from server responses
                 if (streamResponse != null){  // Check for a valid data source     
                     using (StreamReader reader = new StreamReader(streamResponse))   
                     {      
                         string line;
                             
                         while ((line = reader.ReadLine()) != null)   // Read the response in chunks    
                         {        
                             File.AppendAllText(outFile, line + Environment.NewLine);  // Write to file instead of console
                             responseData += line + Environment.NewLine;
                         }  
                     responseData += reader.ReadToEnd();     // Read the remaining part if any
                 }} 
                 return responseData;      // Return complete server's text                    
              }      
         } catch (WebException ex) {                      // Handle exceptions properly here  
            File.AppendAllText(outFile, "ERROR!?! Error occurred while sending request to URL :{url}, Exception Message: {ex.Message}" + Environment.NewLine);
            throw new Exception ("An error has occurred: " + ex.Message, ex);
        } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
            File.AppendAllText(outFile, "ERROR!?! Error occurred while sending request to URL :{url}, Exception Message: {ex.Message}" + Environment.NewLine);
            throw new Exception ("An error has occured: " + ex.Message, ex);
        }  
     } 
}
"@

Add-Type -TypeDefinition $PostForStream
 
Remove-Item $File -ErrorAction SilentlyContinue

try {$Output = [LMStudio]::PostDataForStream($CompletionURI, ($Body | ConvertTo-Json), "application/json",$File)}
catch {$_.Exception.Message}
  
return $Output

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

#Capture Control+C
#[Console]::TreatControlCAsInput = $True
#Start-Sleep -Seconds 1
#$Host.UI.RawUI.FlushInputBuffer()

$StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)# 

#Used to force-kill the job, if necessary
$Global:LMStreamPID = Get-Content "$File.pid" -First 1
$StartParseJob = Start-Job -ScriptBlock $ParseJob -ArgumentList @($File)

$MessageBuffer = ""
        
}
process {

    $x = 1

    do {

        #Intercept Escape
        If ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
            If ([Int]$Key.Character -eq 27) {
        
            Write-Warning "Escape was used - Shutting down any running jobs before exiting the script."
            
            $LMStreamPID = Get-Content "$File.pid" -First 1
            
            Stop-Process -Id $LMStreamPID -Force
            $StopJobs = get-Job | Stop-Job
            $RemoveJobs = Get-Job | Remove-Job
            
            Remove-Item "$File.pid" -Force
            Remove-Item $File -Force
        
            throw "Function was interrupted with SIGINT during execution"
            }
        }
    
        $Output = Receive-Job $StartParseJob | Where-Object {$_ -match 'data:|ERROR!?!'}
    
        :oloop foreach ($Line in $Output){
    
            if ($Line -match "ERROR!?!"){throw "Exception: $($Line -replace 'ERROR!?!')"}
            else {
    
                $LineAsObj = $Line.TrimStart('data: ') | ConvertFrom-Json
                If ($LineAsObj.id.Length -eq 0){continue oloop}
    
                $Word = $LineAsObj.choices.delta.content
                Write-Host "$Word" -NoNewline
                $MessageBuffer += $Word
            
                If ($null -ne $LineAsObj.choices.finish_reason){
                    Write-Host ""; Write-Host "Finish reason: $($LineAsObj.choices.finish_reason)"
                    $x = 5
                }
    
            }
    
        }
    
    
    }
    until ($x -eq 5)
    

}
end {
    $StopJobs = get-Job | Stop-Job
    $RemoveJobs = Get-Job | Remove-Job
    
    return $MessageBuffer

}
}

#endregion

# Change the default behavior of CTRL-C so that the script can intercept and use it versus just terminating the script.
#[Console]::TreatControlCAsInput = $True
#Start-Sleep -Milliseconds 250
#$Host.UI.RawUI.FlushInputBuffer()

#   out any running jobs and setting CTRL-C back to normal.
If ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
    If ([Int]$Key.Character -eq 27) {

    Write-Warning "Escape was used - Shutting down any running jobs before exiting the script."

    Stop-Process -Id ($Global:LMStreamPID) -Force
    $StopJobs = get-Job | Stop-Job
    $RemoveJobs = Get-Job | Remove-Job

    throw "Function was interrupted with SIGINT during execution"
    }
}
# Flush the key buffer again for the next loop.

$Host.UI.RawUI.FlushInputBuffer()


 
