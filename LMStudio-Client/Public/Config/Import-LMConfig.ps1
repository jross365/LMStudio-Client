<#
.SYNOPSIS
Imports a Configuration File

.DESCRIPTION
Imports an existing Configuration File (lmsc.cfg).
The configuration file contains various settings. These settings
control different server, file and console settings.

.PARAMETER ConfigFile
The full path to the Configuration File

.PARAMETER Verify
Optional. Validates Config File contents, and server accessibility

.INPUTS
No pipeline inputs accepted.

.OUTPUTS
If -Verify is specified, returns verification status.

.EXAMPLE
PS> Import-LMConfig $env:UserProfile\Documents\LMStudio-PSClient\lmsc.cfg

.EXAMPLE
PS> Import-LMConfig $env:UserProfile\Documents\LMStudio-PSClient\lmsc.cfg -Verify

.LINK
GitHub Repository: https://github.com/jross365/LMStudio-Client

#>