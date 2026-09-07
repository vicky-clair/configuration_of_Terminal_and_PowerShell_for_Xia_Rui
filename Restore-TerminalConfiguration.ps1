# Restore the exact configuration captured before the latest installation/deployment.
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$BackupDirectory,
    [switch]$IncludeCmd
)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

# 优先尝试现代全量回退
$restoreAllScript = Join-Path $projectRoot 'Restore-All.ps1'
if (Test-Path $restoreAllScript) {
    $params = @{}
    if ($BackupDirectory) { $params['BackupDirectory'] = $BackupDirectory }
    & $restoreAllScript @params -WhatIf:$WhatIfPreference
    return
}

# 降级备用：旧版 deployment 快照回退
$deploymentPathFile = Join-Path $projectRoot '.deployment-path'
$snapshotRoot = if (Test-Path $deploymentPathFile) {
    (Get-Content $deploymentPathFile -Raw).Trim()
} else {
    Join-Path $projectRoot 'backups\deployment-20260907-060507'
}

if (-not (Test-Path $snapshotRoot)) {
    throw "Backup directory not found: $snapshotRoot"
}

& (Join-Path $snapshotRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $snapshotRoot -WhatIf:$WhatIfPreference

if ($IncludeCmd) {
    $cmdInstaller = Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1'
    if (Test-Path $cmdInstaller) {
        & $cmdInstaller -Uninstall -WhatIf:$WhatIfPreference
    }
}

