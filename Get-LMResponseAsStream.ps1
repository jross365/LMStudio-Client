function Invoke-LMStream{
    [CmdletBinding()]
param (
    [Parameter(Mandatory=$true)][string]$CompletionURI,
    [Parameter(Mandatory=$true)][pscustomobject]$Body,
    [Parameter(Mandatory=$true)][string]$File
    )

    begin {

        #region Define Jobs

    $PSVersion = "$($PSVersionTable.PSVersion.Major)" + '.' + "$($PSVersionTable.PSVersion.Minor)"

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

    $x = 1

    do {

        #Intercept Escape
        If ($Host.UI.RawUI.KeyAvailable -and ($Key = $Host.UI.RawUI.ReadKey("AllowCtrlC,NoEcho,IncludeKeyUp"))) {
            If ([Int]$Key.Character -eq 27) {
        
            Write-Host ""; Write-Warning "Escape character detected"
            
            $LMStreamPID = Get-Content "$File.pid" -First 1
            
            Stop-Process -Id $LMStreamPID -Force -ErrorAction SilentlyContinue #If we can't stop it, it's because it ended already.
            
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

} #Close Process

end {

    $StopJobs = get-Job | Stop-Job
    $RemoveJobs = Get-Job | Remove-Job
    Remove-Item "$File.pid" -Force
    Remove-Item "$File" -Force
    return $MessageBuffer

} #Close End
} #Close function
