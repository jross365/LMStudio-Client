#
# Module manifest for module 'LMStudio-Client'
#
# Generated by: Jason
#
# Generated on: 7/18/2024
#

@{

# Script module or binary module file associated with this manifest.
 RootModule = 'LMStudio-Client.psm1'

# Version number of this module.
ModuleVersion = '0.5.1'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '805e27d4-0cf4-403e-897b-92c026873408'

# Author of this module
Author = 'jross365'

# Company or vendor of this module
CompanyName = 'jross365'

# Copyright statement for this module
Copyright = '(c) 2024 jross365. All rights reserved.'

# Description of the functionality provided by this module
 Description = 'LMStudio-PSClient is a Powershell-based client for LMStudio'

# Minimum version of the PowerShell engine required by this module
 PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Add-LMSystemPrompt','Confirm-LMGlobalVariables','Confirm-LMYesNo','Convert-LMDialogToBody','Convert-LMDialogToHistoryEntry','Get-LMGreeting','Get-LMModel','Get-LMResponse','Import-LMConfig','Import-LMDialogFile','Import-LMHistoryFile','Invoke-LMBlob','Invoke-LMOpenFolderUI','Invoke-LMSaveOrOpenUI','Invoke-LMStream','New-LMConfig','New-LMGreetingPrompt','New-LMTemplate','Remove-LMHistoryEntry','Remove-LMSystemPrompt','Repair-LMHistoryFile','Search-LMChatDialog','Select-LMHistoryEntry','Select-LMSystemPrompt','Set-LMCLIOption','Set-LMConfigOptions','Set-LMTags','Set-LMTitle','Show-LMDialog','Show-LMHelp','Show-LMSettings','Start-LMChat','Update-LMHistoryFile')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
         Tags = @("lmstudio","client","ai","llm")

        # A URL to the license for this module.
         LicenseUri = 'https://github.com/jross365/LMStudio-Client/blob/main/LICENSE.md'

        # A URL to the main website for this project.
         ProjectUri = 'https://github.com/jross365/LMStudio-Client'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
 HelpInfoURI = 'https://github.com/jross365/LMStudio-Client/blob/main/README.md'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
