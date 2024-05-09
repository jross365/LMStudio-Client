#region Setup to make testing easier
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

do {

Write-Host "You: " -ForegroundColor Green -NoNewline




}