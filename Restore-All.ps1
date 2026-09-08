<#
.SYNOPSIS
    全终端配置一键回退与灾难恢复脚本
.DESCRIPTION
    读取最近一次安装前自动保存的快照，或用户显式指定的备份目录，
    实现对全套终端配置（PowerShell 7、Windows PowerShell 5.1、Windows Terminal、CMD、NuShell、MSYS2）的原子无损回退。
    支持 -Components 按组件颗粒度恢复，支持 -WhatIf 预演模式。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)]
    [string]$BackupDirectory,
    [string]$Msys2InstallPath,
    [string]$CmdTargetDir,
    [ValidateSet('All', 'PowerShell7', 'WinPS51', 'Terminal', 'Cmd', 'Shared', 'NuShell', 'MSYS2')]
    [string[]]$Components = @('All')
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts/TerminalState.ps1')

# 1. 自动解析快照路径：若未显式指定，则从 .last-install-backup 指针读取
if (-not $BackupDirectory) {
    $pointer = Join-Path $projectRoot '.last-install-backup'
    if (-not (Test-Path -LiteralPath $pointer)) {
        throw '未找到最近一次安装快照指针 (.last-install-backup)。请显式指定 -BackupDirectory 参数。'
    }
    $BackupDirectory = [IO.File]::ReadAllText($pointer).Trim()
    
    # 读取安装上下文元数据 (如关联的 MSYS2 路径)
    $contextPath = Join-Path $projectRoot '.last-install-context.json'
    if (-not $Msys2InstallPath -and [IO.File]::Exists($contextPath)) {
        Assert-TerminalRegularFile $contextPath
        $context = [IO.File]::ReadAllText($contextPath) | ConvertFrom-Json
        if ($context.Version -ne 1) { throw '不支持的本地安装上下文版本。' }
        if ($context.BackupDirectory -and [IO.Path]::GetFullPath($context.BackupDirectory) -eq [IO.Path]::GetFullPath($BackupDirectory)) {
            $Msys2InstallPath = $context.Msys2InstallPath
        }
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始从快照恢复终端配置: $BackupDirectory" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 2. 根据快照类型分派回退逻辑
if (Test-Path -LiteralPath (Join-Path $BackupDirectory 'manifest.json')) {
    # 统合全量快照回退
    Restore-TerminalSnapshot -Directory $BackupDirectory -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir -Components $Components -WhatIf:$WhatIfPreference
    Write-Host "`n[OK] 终端配置已按指定组件恢复完成！" -ForegroundColor Green
} elseif (Test-Path -LiteralPath (Join-Path $BackupDirectory 'deployment.json')) {
    # 原子部署快照数据回退 (通过 Manage-TerminalConfiguration 安全管理)
    & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $BackupDirectory -WhatIf:$WhatIfPreference
    Write-Host "`n[OK] 原子配置已成功回滚！" -ForegroundColor Green
} else {
    throw "无法识别的快照格式: $BackupDirectory (缺少 manifest.json 或 deployment.json)"
}
