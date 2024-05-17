# PostForStream: Uses the "new" C# web client (experimental)
# This does not work as expected, and has crashed when I've tested it.
# However, it uses the HttpClient() method avaiilable to C#.
# Might be worth trying to get this to work, so I can loop everything into "modern" C# code (not using an obsolete client)

$PostForStreamNew = @"
using System;
using System.IO;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;

namespace LMStudio
{
    public class WebRequestHandler : IDisposable
    {
        private CancellationTokenSource _cancellationTokenSource;
        private readonly HttpClient _httpClient;

        public CancellationTokenSource CancellationTokenSource
        {
            get { return _cancellationTokenSource; }
            private set { _cancellationTokenSource = value; }
        }

        public WebRequestHandler()
        {
            _httpClient = new HttpClient();
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

                // Create a HTTP content with the request body
                var content = new StringContent(requestBody, System.Text.Encoding.UTF8, "application/json");

                // Send the request
                var response = await _httpClient.PostAsync(url, content, CancellationTokenSource.Token);

                // Ensure success status code
                response.EnsureSuccessStatusCode();

                // Read the response stream
                using (var responseStream = await response.Content.ReadAsStreamAsync())
                using (var fileWriter = new StreamWriter(outputPath, append: true))
                using (var reader = new StreamReader(responseStream))
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
                File.AppendAllText(outputPath, $"ERROR!?! Error occurred while sending request to URL: {url}, Exception Message: {ex.Message}" + Environment.NewLine);
                throw new Exception("An error has occurred: " + ex.Message, ex);
            }
        }

        public void Cancel()
        {
            CancellationTokenSource.Cancel();
        }

        public void Dispose()
        {
            _httpClient.Dispose();
            CancellationTokenSource.Dispose();
        }
    }
}

"@