<#
.SYNOPSIS
    终端配置回退委托入口脚本
.DESCRIPTION
    调度 Restore-All.ps1 或调用历史 deployment 快照，
    将系统中所有终端配置安全恢复至部署前的状态。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$BackupDirectory,
    [switch]$IncludeCmd
)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

# 1. 优先调用现代全量回退引擎 (Restore-All.ps1)
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

