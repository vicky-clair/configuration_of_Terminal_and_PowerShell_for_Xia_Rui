# Restore the exact configuration captured before the 2026-09-07 deployment.
[CmdletBinding(SupportsShouldProcess = $true)]
param()
$snapshotRoot = Join-Path $PSScriptRoot 'backups\deployment-20260907-060507'
& (Join-Path $snapshotRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $snapshotRoot -WhatIf:$WhatIfPreference
