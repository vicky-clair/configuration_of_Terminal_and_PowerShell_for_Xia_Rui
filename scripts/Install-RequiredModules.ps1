param([string]$ModuleNames)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'TerminalSetupCommon.ps1')
Install-PSModulesIfMissing -Modules ($ModuleNames -split ',') -Edition Current
