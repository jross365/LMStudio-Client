### This is an archive of all the variations of the C# code I tried 
### for the job's webclient, all for the purpose of getting that
### sweet, sweet character streaming

#region Original, Fixed
$source = @"
using System;  
using System.IO;  
using System.Net;  
public class Test {  
     public static string GetData(string url) { 
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);  
        request.Method = "GET";   
         try {  
            using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {    
                Stream streamResponse = response.GetResponseStream(); 
                StreamReader streamRead = new StreamReader(streamResponse);     
                return streamRead.ReadToEnd();   
             }      
         } catch (Exception ex) {      
            throw new Exception("Occurred in GetResponse", ex);  
        }  
     }
     public static string PostData(string url, string data, string contentType) { 
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
                 StreamReader streamRead = new StreamReader(streamResponse);     
                 return streamRead.ReadToEnd();   
              }      
         } catch (Exception ex) {      
            throw new Exception("Occurred in datastream", ex);       
        }
     } 
}
"@
Add-Type -TypeDefinition $source

[Test]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON")
#endregion

#region 05/05/2024 My favorite working rework:
$PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStreamRenewed {  
     public static string PostData(string url, string data, string contentType) 
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
             string responseData="";   // To hold the received chunks of text from server responses         
             using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {  
                 Stream streamResponse = response.GetResponseStream();    
                 if (streamResponse != null){  // Check for a valid data source     
                     using (StreamReader reader = new StreamReader(streamResponse))   
                     {      
                         string line;
                             
                         while ((line = reader.ReadLine()) != null)   // Read the response in chunks    
                         {        
                             // if(line.Contains("data: "))  // Check for "data: {}" text     
                                 Console.WriteLine(line);    // Process and/or store this chunk of data as needed, #1 - works
                                 // Console.Error.WriteLine(line); // Try to send it to stderr, then redirect, #2 - doesn't work
                                 // Console.Out.(line); // Try to send it via System.IO.TextWriter, #3 - Doesn't work
                                 // return line;    // Try to return line instead - doesn't work
                             // else                       
                                // continue;               
                         }  
                     responseData = reader.ReadToEnd();     // Read the remaining part if any         
                 }} 
             return responseData;      // Return complete server's text   
              }      
         } catch (WebException ex) {                      // Handle exceptions properly here  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        }  
     } 
}

"@

[PostForStreamRenewed]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON", $delegate)
#endregion

#region My favorite working rework, as a job:
$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]

    & {
    $PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStreamRenewed {  
     public static string PostData(string url, string data, string contentType) 
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
             string responseData="";   // To hold the received chunks of text from server responses         
             using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {  
                 Stream streamResponse = response.GetResponseStream();    
                 if (streamResponse != null){  // Check for a valid data source     
                     using (StreamReader reader = new StreamReader(streamResponse))   
                     {      
                         string line;
                             
                         while ((line = reader.ReadLine()) != null)   // Read the response in chunks    
                         {        
                             
                             Console.WriteLine(line);    // Process and/or store this chunk of data as needed, #1 - works
                             
                         }  
                     responseData = reader.ReadToEnd();     // Read the remaining part if any         
                 }} 
             return responseData;      // Return complete server's text   
              }      
         } catch (WebException ex) {                      // Handle exceptions properly here  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        }  
     } 
}

"@

Add-Type -TypeDefinition $PostForStream

#$StringWriter=New-Object IO.StringWriter
# [Console]::SetOut($StringWriter)
 
[POSTForStreamRenewed]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON")

} *>&1 | Out-Host
  
}
#endregion

#region Running the job:
#StartJob:

# stdout redirect to StringWriter:
$StringWriter=New-Object IO.StringWriter
[Console]::SetOut($StringWriter)

$StartJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body)# -StreamingHost $Host

#Preserve the working console stdout setting
$OldConsoleOut=[Console]::Out


$JobOutput = $StartJob | Receive-Job

#Restore the console
[Console]::SetOut($OldConsoleOut)

$JobOutput
#endregion

#region 05/05/2024: Testing: This test pattern works somewhat:

$OldConsoleOut=[Console]::Out
$StringWriter=New-Object IO.StringWriter
[Console]::SetOut($StringWriter)

[POSTForStreamRenewed]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON")
#[Console]::WriteLine('SomeText') # That command will not print on console.

[Console]::SetOut($OldConsoleOut)

#Capturing stringwriting
$StringWriter.ToString()


#endregion

#region "Stream testing...it works! 05/04/2024
$source3 = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStream3 {  
     public static string PostData(string url, string data, string contentType) 
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
             string responseData="";   // To hold the received chunks of text from server responses         
             using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {  
                 Stream streamResponse = response.GetResponseStream();    
                 if (streamResponse != null){  // Check for a valid data source     
                     using (StreamReader reader = new StreamReader(streamResponse))   
                     {      
                         string line;
                             
                         while ((line = reader.ReadLine()) != null)   // Read the response in chunks    
                         {        
                             if(line.Contains("data: "))  // Check for "data: {}" text     
                                 Console.WriteLine(line);    // Process and/or store this chunk of data as needed, #1 - works
                                 // Console.Error.WriteLine(line); // Try to send it to stderr, then redirect, #2 - doesn't work
                                 // Console.Out.(line); // Try to send it via System.IO.TextWriter, #3 - Doesn't work
                                 // return line;    // Try to return line instead - doesn't work
                             else                       
                                 continue;               
                         }  
                     responseData = reader.ReadToEnd();     // Read the remaining part if any         
                 }} 
             return responseData;      // Return complete server's text   
              }      
         } catch (WebException ex) {                      // Handle exceptions properly here  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
            Console.WriteLine("Error occurred while sending request to URL :"+ url);    
            Console.WriteLine(ex.Message);                 // Print the exception message 
            return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
        }  
     } 
}

"@

Add-Type -TypeDefinition $source3

#endregion

#region try writing to a file as a job: #05/06: Works!!! LEAVE THIS ALONE, COPY IT TO TINKER WITH IT
$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]
    $File = $args[2]

    $PostForStream = @"
    using System;  
    using System.IO;  
    using System.Net;  
    public class POSTForStreamToFile {  
         public static string PostData(string url, string data, string contentType, string outFile) 
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
                 string responseData="";   // To hold the received chunks of text from server responses         
                 using(HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {  
                     Stream streamResponse = response.GetResponseStream();    
                     if (streamResponse != null){  // Check for a valid data source     
                         using (StreamReader reader = new StreamReader(streamResponse))   
                         {      
                             string line;
                                 
                             while ((line = reader.ReadLine()) != null)   // Read the response in chunks    
                             {        
                                 File.AppendAllText(outFile, line + Environment.NewLine);  // Write to file instead of console
                             }  
                         responseData = reader.ReadToEnd();     // Read the remaining part if any         
                     }} 
                 return responseData;      // Return complete server's text   
                  }      
             } catch (WebException ex) {                      // Handle exceptions properly here  
                Console.WriteLine("Error occurred while sending request to URL :"+ url);    
                Console.WriteLine(ex.Message);                 // Print the exception message 
                return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
            } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
                File.AppendAllText(outFile, "Error occurred while sending request to URL :{url}, Exception Message: {ex.Message}");  // Write error message into file, #3 - works    
                return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
            }  
         } 
    }
  
"@

Add-Type -TypeDefinition $PostForStream

#$StringWriter=New-Object IO.StringWriter
# [Console]::SetOut($StringWriter)
 
$Output = [POSTForStreamToFile]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON",$File)
  
return $Output

}

$StartJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)# -StreamingHost $Host

#endregion

#region 05/06: Copy of the LEAVE THIS ALONE code: This works perfectly:
# Writes the strings to the file
# Returns the code via the variable

$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]
    $File = $args[2]

    $PostForStream = @"
    using System;  
    using System.IO;  
    using System.Net;  
    public class POSTForStreamToFile {  
         public static string PostData(string url, string data, string contentType, string outFile) 
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
                Console.WriteLine("Error occurred while sending request to URL :"+ url);    
                Console.WriteLine(ex.Message);                 // Print the exception message 
                return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
            } catch (Exception ex) {                          // Catch any other exceptions not specifically handled above  
                File.AppendAllText(outFile, "Error occurred while sending request to URL :{url}, Exception Message: {ex.Message}");  // Write error message into file, #3 - works    
                return "An error has occured: "+ex.Message;    // Return an appropriate default value in case of errors     
            }  
         } 
    }
  
"@


Add-Type -TypeDefinition $PostForStream
 
Remove-Item $File -ErrorAction SilentlyContinue

try {$Output = [POSTForStreamToFile14]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON",$File)}
catch {write-host "Error hit"}
  
return $Output

}

$StartJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)# -StreamingHost $Host

#endregion

#region 05/06: Working, direct console execution:

$PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStreamToFile {  
     public static string PostData(string url, string data, string contentType, string outFile) 
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

rm $File -ErrorAction SilentlyContinue

try {$Output = [POSTForStreamToFile2]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON",$File)}
catch {$_.Exception.Message; write-host "nope"}
#endregion

#region 05/06: WORKING PROTOTYPE of the above (LEAVE IT ALONE):
$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]
    $File = $args[2]

$PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStreamToFile {  
     public static string PostData(string url, string data, string contentType, string outFile) 
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

try {$Output = [POSTForStreamToFile]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON",$File)}
catch {write-host "Error hit"}
  
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

$StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)# 

$StartParseJob = Start-Job -ScriptBlock $ParseJob -ArgumentList @($File)

$MessageBuffer = ""

$x = 1

do {

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

$StopJobs = get-Job | Stop-Job
$RemoveJobs = Get-Job | Remove-Job

#endregion

#region Same as the above, but testing Termination
$StreamJob = {
    
    $CompletionURI = $args[0]
    $Body = $args[1]
    $File = $args[2]

    "$PID" | out-File "$File.pid"

$PostForStream = @"
using System;  
using System.IO;  
using System.Net;  
public class POSTForStreamToFile {  
     public static string PostData(string url, string data, string contentType, string outFile) 
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

try {$Output = [POSTForStreamToFile]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON",$File)}
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

$StartStreamJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body,$File)# 

#Used to force-kill the job, if necessary
$StreamPID = Get-Content "$File.pid"
Remove-item "$File.pid" -ErrorAction SilentlyContinue


$StartParseJob = Start-Job -ScriptBlock $ParseJob -ArgumentList @($File)

$MessageBuffer = ""

$x = 1

do {

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

$StopJobs = get-Job | Stop-Job
$RemoveJobs = Get-Job | Remove-Job




#endregion

#region Good, but doesn't expose canceltask:
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
{
    public class WebRequestHandler
    {
        private CancellationTokenSource _cancellationTokenSource;

        public async Task PostAndStreamResponse(string url, string requestBody, string outputPath)
        {
            try
            {
                _cancellationTokenSource = new CancellationTokenSource();

                // Register SIGINT and SIGTERM handlers
                Console.CancelKeyPress += (_, e) =>
                {
                    e.Cancel = true;
                    _cancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    _cancellationTokenSource.Cancel();
                };

                // Create a HTTP request
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "POST";
                request.ContentType = "application/json";

                // Write request body
                using (var streamWriter = new StreamWriter(request.GetRequestStream()))
                {
                    await streamWriter.WriteAsync(requestBody);
                    await streamWriter.FlushAsync();
                }

                // Get response
                using (HttpWebResponse response = (HttpWebResponse)await request.GetResponseAsync())
                using (Stream responseStream = response.GetResponseStream())
                using (FileStream fileStream = new FileStream(outputPath, FileMode.Create))
                {
                    // Stream response to file
                    await responseStream.CopyToAsync(fileStream, 81920, _cancellationTokenSource.Token);
                }
            }
            catch (OperationCanceledException)
            {
                // Clean up resources
                Console.WriteLine("Operation canceled. Closing connection...");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: {ex.Message}");
	throw new Exception ("An error has occured: " + ex.Message, ex);
            }
        }
    }
}
"@
#endregion

#region Test to expose canceltask: THIS WORKS!!! And it's properly async, BUT it writes/dumps all at once:
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                    CancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    CancellationTokenSource.Cancel();
                };

                // Create a HTTP request
                HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
                request.Method = "POST";
                request.ContentType = "application/json";

                // Write request body
                using (var streamWriter = new StreamWriter(request.GetRequestStream()))
                {
                    await streamWriter.WriteAsync(requestBody);
                    await streamWriter.FlushAsync();
                }

                // Get response
                using (HttpWebResponse response = (HttpWebResponse)await request.GetResponseAsync())
                using (Stream responseStream = response.GetResponseStream())
                using (FileStream fileStream = new FileStream(outputPath, FileMode.Create))
                {
                    // Stream response to file
                    await responseStream.CopyToAsync(fileStream, 81920, CancellationTokenSource.Token);
                }
            }
            catch (OperationCanceledException)
            {
                // Clean up resources
                Console.WriteLine("Operation canceled. Closing connection...");
            }
            catch (Exception ex)
            {
            File.AppendAllText(outputPath, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
            throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Dispose()
        {
            CancellationTokenSource.Dispose();
        }
    }
}
"@
#endregion

#region Test to expose canceltask: Attempting to write line-by-line: TESTING: Still dumps all-at-once:
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                    CancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    CancellationTokenSource.Cancel();
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
                    }
                }

                // Get response
                using (HttpWebResponse response = (HttpWebResponse)await request.GetResponseAsync())
                using (Stream responseStream = response.GetResponseStream())
                using (FileStream fileStream = new FileStream(outputPath, FileMode.Create))
                {
                    // Stream response to file
                    await responseStream.CopyToAsync(fileStream, 81920, CancellationTokenSource.Token);
                }
            }
            catch (OperationCanceledException)
            {
                // Clean up resources
                Console.WriteLine("Operation canceled. Closing connection...");
            }
            catch (Exception ex)
            {
                File.AppendAllText(outputPath, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
                throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Dispose()
        {
            CancellationTokenSource.Dispose();
        }
    }
}
"@
#endregion

#region Test #2 to write line by line:
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                    CancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    CancellationTokenSource.Cancel();
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
                File.AppendAllText(outputPath, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
                throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Dispose()
        {
            CancellationTokenSource.Dispose();
        }
    }
}


"@
#endregion

#region Test #3: Break when line -contains "done":
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                    CancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    CancellationTokenSource.Cancel();
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
                        await fileWriter.WriteLineAsync(line);

                        // Check for termination condition
                        if (line.Trim() == "data: [DONE]")
                            break;
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
                File.AppendAllText(outputPath, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
                throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Dispose()
        {
            CancellationTokenSource.Dispose();
        }
    }
}

"@
#endregion

#region Test #4: trying to interrupt the stream at any time: WORKS, but doesn't output some form of "Cancel" signal
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                    CancellationTokenSource.Cancel();
                };
                AppDomain.CurrentDomain.ProcessExit += (_, __) =>
                {
                    CancellationTokenSource.Cancel();
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
                            break;

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
                File.AppendAllText(outputPath, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
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
#endregion

#region Test #5: attempting to output a "cancel" signal to the above: WORKS, but no error handling to/from console, only text file
    #This one was selected, and is now in Invoke-LMStream
#endregion


#region Test6: trying to fix error handling: NO DIFFERENCE FROM TEST5
$Post = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

namespace MyNamespace
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
                            break; // Changed "throw;" to "break;"
                        }

                        await fileWriter.WriteLineAsync(line);
                    }
                }
            }
catch (OperationCanceledException)
{
    Console.WriteLine("Operation canceled. Closing connection...");
    // Optionally handle cancellation cleanup here
}
catch (Exception exception)
{
    string errorMessage = "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {exception.Message}" + Environment.NewLine;
    File.AppendAllText(outputPath, errorMessage);
    // Re-throw the exception for higher-level handling
throw new ApplicationException(exception.Message);
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
#endregion

#region Testing code
add-type -typedefinition $Post

#File handling
$File = "D:\test.log"
rm $File -ErrorAction SilentlyContinue
cd D:\git\LMStudio-AI-Client\

#Endpoint setup
$Server = "localhost"
$Port = 1234
[string]$EndPoint = $Server + ":" + $Port
$CompletionURI = "http://$EndPoint/v1/chat/completions"

#Build the body:
$Body = get-content .\bodyexample.json | ConvertFrom-Json
$Body.messages[3].content = "Please give me 50 facts about Ohio"
$Body.stream = $True


#cancel testing:
 $handler = New-Object MyNamespace.WebRequestHandler #Recreate handler every time
$N = $handler.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "$File")
start-sleep -seconds 3; $handler.Cancel()


# Initiate the session:
$handler = New-Object MyNamespace.WebRequestHandler #Recreate handler every time
$N = $handler.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "$File")

#Listen to file:
Get-content $File -Wait

#To cancel:
$handler.CancellationTokenSource.Cancel()

rm D:\test.log
$handler = New-Object MyNamespace.WebRequestHandler
$handler.PostAndStreamResponse($CompletionURI, ($Body | Convertto-Json), "D:\test.log")
$handler.CancellationTokenSource.Cancel()
get-content "D:\test.log" -Wait

#endregion