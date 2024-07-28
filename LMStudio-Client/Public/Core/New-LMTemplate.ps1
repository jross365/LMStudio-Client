<#
.SYNOPSIS
Returns object templates.

.DESCRIPTION
Provides a variety of different pre-constructed Powershell
objects, for use by or with different functions.

.PARAMETER Type
The type of object to return.
Valid options are:
'Body'
'ChatDialog'
'ChatGreeting'
'ConfigFile'
'DialogMessage'
'HistoryEntry'
'ManualSettings'
'SystemPrompts'

.OUTPUTS
Returns the requested object.

.EXAMPLE
PS> $Dialog = New-LMTemplate -Type DialogMessage

.LINK
GitHub Repository: https://github.com/jross365/LMStudio-Client

#>