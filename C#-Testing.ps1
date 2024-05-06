#region Setup to make testing easier
$Server = "localhost"
$Port = 1234
[string]$EndPoint = $Server + ":" + $Port
$ModelURI = "http://$EndPoint/v1/models"
$CompletionURI = "http://$EndPoint/v1/chat/completions"

$Body = get-content .\bodyexample.json | ConvertFrom-Json
$Body.stream = $True

$File = "D:\teststreamfile.txt"

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

#region 05/06: WORKING PROTOTYPE of the above:
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
