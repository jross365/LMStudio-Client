<#
.SYNOPSIS
Modifies Configuration Settings

.DESCRIPTION
Writes new values to the Configuration hive ($Global:LMStudioVars).
Can also save new values to the Configuration File (lmsc.cfg).

.PARAMETER Branch
The Configuration hive branch containing the setting(s) to modify.
Valid options are 'ServerInfo', 'ChatSettings', 'FilePaths', 'URIs'


.PARAMETER Options
The settings to modify under the designated branch.

.PARAMETER Commit
Optional. Saves the Configuration hive to the Configuration file.

.OUTPUTS
None.

.EXAMPLE
PS> Set-LMConfigOptions -Branch ChatSettings -Options @{"Greeting"=$False}

.EXAMPLE
PS> Set-LMConfigOptions -Branch ChatSettings -Options @{"ContextDepth"=6, "temperature"=0.8} -Commit

.LINK
GitHub Repository: https://github.com/jross365/LMStudio-Client

#>