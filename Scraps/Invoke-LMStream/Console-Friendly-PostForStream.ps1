#This is an early prototype of my rudimentary and working web client
$PostForStream = @"
using System;
using System.IO;
using System.Net;
using System.Threading;
using System.Threading.Tasks;

public class LMStudio
{
    public static async Task<string> PostDataForStream(string url, string data, string contentType, string outFile)
    {
        // Create CancellationTokenSource for handling termination signals
        var cancellationTokenSource = new CancellationTokenSource();

        // Register termination signal handler
        Console.CancelKeyPress += (sender, e) =>
        {
            e.Cancel = true; // Prevent normal termination
            cancellationTokenSource.Cancel(); // Cancel ongoing operation
        };

        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        byte[] byteArray = System.Text.Encoding.UTF8.GetBytes(data);
        request.ContentLength = byteArray.Length;
        request.ContentType = contentType;
        request.Method = "POST";

        try
        {
            // Check for cancellation before proceeding
            cancellationTokenSource.Token.ThrowIfCancellationRequested();

            using (Stream dataStream = await request.GetRequestStreamAsync().WithCancellation(cancellationTokenSource.Token))
            {
                await dataStream.WriteAsync(byteArray, 0, byteArray.Length, cancellationTokenSource.Token);

                // Check for cancellation before proceeding
                cancellationTokenSource.Token.ThrowIfCancellationRequested();
            }

            using (HttpWebResponse response = (HttpWebResponse)(await request.GetResponseAsync().WithCancellation(cancellationTokenSource.Token)))
            {
                Stream streamResponse = response.GetResponseStream();
                string responseData = ""; // To hold the received chunks of text from server responses
                if (streamResponse != null) // Check for a valid data source
                {
                    using (StreamReader reader = new StreamReader(streamResponse))
                    {
                        string line;

                        while ((line = await reader.ReadLineAsync().WithCancellation(cancellationTokenSource.Token)) != null) // Read the response in chunks
                        {
                            // Check for cancellation before writing to file
                            cancellationTokenSource.Token.ThrowIfCancellationRequested();

                            File.AppendAllText(outFile, line + Environment.NewLine); // Write to file instead of console
                            responseData += line + Environment.NewLine;
                        }
                        responseData += await reader.ReadToEndAsync().WithCancellation(cancellationTokenSource.Token); // Read the remaining part if any
                    }
                }
                return responseData; // Return complete server's text
            }
        }
        catch (OperationCanceledException)
        {
            // Clean up or handle termination
            Console.WriteLine("Operation canceled due to termination signal.");
            return string.Empty; // Return empty string on cancellation
        }
        catch (WebException ex)
        {
            File.AppendAllText(outFile, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
            throw new Exception("An error has occurred: " + ex.Message, ex);
        }
        catch (Exception ex)
        {
            File.AppendAllText(outFile, "ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
            throw new Exception("An error has occurred: " + ex.Message, ex);
        }
    }
}

public static class TaskExtensions
{
    public static async Task<T> WithCancellation<T>(this Task<T> task, CancellationToken cancellationToken)
    {
        var tcs = new TaskCompletionSource<bool>();
        using (cancellationToken.Register(s => ((TaskCompletionSource<bool>)s).TrySetResult(true), tcs))
        {
            if (task != await Task.WhenAny(task, tcs.Task))
            {
                throw new OperationCanceledException(cancellationToken);
            }
        }
        return await task;
    }

    public static async Task WithCancellation(this Task task, CancellationToken cancellationToken)
    {
        var tcs = new TaskCompletionSource<bool>();
        using (cancellationToken.Register(s => ((TaskCompletionSource<bool>)s).TrySetResult(true), tcs))
        {
            if (task != await Task.WhenAny(task, tcs.Task))
            {
                throw new OperationCanceledException(cancellationToken);
            }
        }
        await task;
    }
}
"@
