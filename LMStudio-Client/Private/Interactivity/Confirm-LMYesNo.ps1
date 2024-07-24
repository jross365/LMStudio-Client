<#
.SYNOPSIS
Prompts a user for confirmation

.DESCRIPTION
Presents a user with a repeating "(y/N)" prompt.
Returns $True (for Yes) or $False (for No.)

.INPUTS
No pipeline inputs accepted.

.OUTPUTS
Returns a boolean value [$True | $False]

.EXAMPLE
PS> $Question = Confirm-LMYesNo
Accept? (y/N): y
PS> $Question
$True

.EXAMPLE
PS> $Question = Confirm-LMYesNo
Accept? (y/N): n
PS> $Question
$False

.LINK
GitHub Repository: https://github.com/jross365/LMStudio-Client

#>