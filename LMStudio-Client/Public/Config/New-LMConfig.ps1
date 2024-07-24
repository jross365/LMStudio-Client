<#
.SYNOPSIS
Creates a new Configuration File

.DESCRIPTION
Uses supplied parameters to generate a configuration file.
The configuration file contains various settings. These settings
control different server, file and console settings.

.PARAMETER Server
The hostname or IP address of the LMStudio server.

.PARAMETER Port
The TCP Port of the LMStudio server.

.PARAMETER BasePath
Optional. A folder where you want to save the config file, and all other files.

.PARAMETER Import
Optional. Import the configuration file into $Global after creation.

.INPUTS
No pipeline inputs accepted.

.OUTPUTS
Produces various file and folder outputs, and some console output.

.EXAMPLE
PS> New-LMConfig -Server localhost -Port 1234

.EXAMPLE
PS> New-LMConfig -Server localhost -Port 1234 -Import

.LINK
GitHub Repository: https://github.com/jross365/LMStudio-Client

#>