<#
.SYNOPSIS
    生产部署专用委托回退脚本
.DESCRIPTION
    读取 .deployment-path 快照指针，定向回退 Windows Terminal、PowerShell 7 及可选的 CMD 配置，
    底层调用 Restore-All.ps1 执行带有 pre-rollback 救援备份的安全还原。
.PARAMETER BackupDirectory
    指定快照目录路径。若缺省则自动从 .deployment-path 中读取最近一次部署的快照路径。
.PARAMETER IncludeCmd
    是否同时还原 CMD (AutoRun 及 Clink) 相关配置。
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$BackupDirectory,
    [switch]$IncludeCmd
)

$ErrorActionPreference = 'Stop'

# 1. 解析部署快照指针
if (-not $BackupDirectory) {
    $pointer = Join-Path $PSScriptRoot '.deployment-path'
    if (-not (Test-Path -LiteralPath $pointer)) {
        throw '未找到最近一次部署的快照指针 (.deployment-path)。请使用 -BackupDirectory 参数显式指定快照路径。'
    }
    $BackupDirectory = [IO.File]::ReadAllText($pointer).Trim()
}

# 2. 组装待恢复的组件列表并执行回退
$components = @('PowerShell7', 'Terminal')
if ($IncludeCmd) { $components += 'Cmd' }
& (Join-Path $PSScriptRoot 'Restore-All.ps1') -BackupDirectory $BackupDirectory -Components $components -WhatIf:$WhatIfPreference
