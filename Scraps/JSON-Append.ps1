$data1 = Get-Content .\fruit1.json -Raw | ConvertFrom-Json
$data2 = Get-Content .\fruit2.json -Raw | ConvertFrom-Json

@($data1; $data2) | ConvertTo-Json | Out-File .\combinedfruit.json


function Set-LMSystemPrompt {} #Not started

#This function presents a selection prompt (Out-Gridview) to continue a history file
#For use with Start-LMChat
Function Select-LMHistoryFile {} #Not Started