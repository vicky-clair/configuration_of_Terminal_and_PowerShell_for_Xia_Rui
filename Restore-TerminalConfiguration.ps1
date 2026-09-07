[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$BackupDirectory, [switch]$IncludeCmd)
$ErrorActionPreference='Stop'
if (-not $BackupDirectory) {
    $pointer=Join-Path $PSScriptRoot '.deployment-path'
    if (-not (Test-Path -LiteralPath $pointer)) { throw 'No deployment snapshot. Specify -BackupDirectory.' }
    $BackupDirectory=[IO.File]::ReadAllText($pointer).Trim()
}
$components=@('PowerShell7','Terminal')
if ($IncludeCmd) { $components += 'Cmd' }
& (Join-Path $PSScriptRoot 'Restore-All.ps1') -BackupDirectory $BackupDirectory -Components $components -WhatIf:$WhatIfPreference
