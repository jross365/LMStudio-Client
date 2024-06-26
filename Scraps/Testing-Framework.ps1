# Testing pre-load to make testing easier
set-location D:\Git\LMStudio-AI-Client

$Server = "localhost"
$Port = 1234
[string]$EndPoint = $Server + ":" + $Port
$ModelURI = "http://$EndPoint/v1/models"
$CompletionURI = "http://$EndPoint/v1/chat/completions"

$Body = get-content .\bodyexample.json | ConvertFrom-Json
$Body.stream = $True

$File = "D:\teststreamfile.txt"

Set-Location D:\Git\LMStudio-AI-Client | Out-Null

Initialize-LMVarStore

Set-LMStudioServer -Server "localhost" -Port 1234

function test-lmstream {


    $Server = "localhost"
    $Port = 1234
    [string]$EndPoint = $Server + ":" + $Port
    $ModelURI = "http://$EndPoint/v1/models"
    $CompletionURI = "http://$EndPoint/v1/chat/completions"

    $Body = get-content .\bodyexample.json | ConvertFrom-Json
    $Body.stream = $True

    $File = "D:\teststreamfile.txt"

    Invoke-LMStream -CompletionURI $CompletionURI -Body $Body -File $File 

}