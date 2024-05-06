#region Setup to make testing easier
$Server = "localhost"
$Port = 1234
[string]$EndPoint = $Server + ":" + $Port
$ModelURI = "http://$EndPoint/v1/models"
$CompletionURI = "http://$EndPoint/v1/chat/completions"

$Body = get-content .\bodyexample.json | ConvertFrom-Json
$Body.stream = $True

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




#endregion

#region My favorite working rework, as a job:
$StreamJob = {

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

Add-Type -TypeDefinition $PostForStream

$CompletionURI = $args[0]
 $Body = $args[1]

 $StringWriter=New-Object IO.StringWriter
 [Console]::SetOut($StringWriter)
 
[POSTForStreamRenewed]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON")
 
 $StringWriter.ToString("fu")


}
#endregion

#region Running the job:
#StartJob:
$StartJob = Start-Job -ScriptBlock $StreamJob -ArgumentList @($CompletionURI,$Body)

#Preserve the working console stdout setting
$OldConsoleOut=[Console]::Out

# stdout redirect to StringWriter:
$StringWriter=New-Object IO.StringWriter
[Console]::SetOut($StringWriter)

$JobOutput = $StartJob | Receive-Job

#Restore the console
[Console]::SetOut($OldConsoleOut)

$JobOutput
#endregion

#region 05/05/2024: This test pattern works perfect:
#from: https://stackoverflow.com/questions/33111014/redirecting-output-from-an-external-dll-in-powershell#:~:text=You%20have%20to%20spawn%20new%20PowerShell%20process%2C%20and,of%20that%20new%20process%3A%20powershell%20-Command%20%22%5BConsole%5D%3A%3AWriteLine%28%27SomeText%27%29%22%7COut-File%20Test.txt
$OldConsoleOut=[Console]::Out
$StringWriter=New-Object IO.StringWriter
[Console]::SetOut($StringWriter)

[POSTForStreamRenewed]::PostData($CompletionURI, ($Body | ConvertTo-Json), "Application/JSON")
#[Console]::WriteLine('SomeText') # That command will not print on console.

[Console]::SetOut($OldConsoleOut)

#Capturing stringwriting
$StringWriter.ToString()


#endregion

#region "Stream testing...it works!
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


#region Tinkering with returning line instead of writing it to console: Working better!
$src6 = @"
using System;  
using System.IO;  
using System.Net;  
public class TestF {  
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
                                  Console.WriteLine(line);    // Process and/or store this chunk of data as needed      
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
