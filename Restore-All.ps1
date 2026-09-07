<#
.SYNOPSIS
    Windows 全终端配置一键无损回退脚本
.DESCRIPTION
    将系统中的所有终端配置（PowerShell 7、Windows PowerShell 5.1、Windows Terminal、CMD 注册表与 Clink 等）
    一键精确还原至安装前的原始状态。
    支持 Windows 11、Windows 10 及 Windows 8.1，兼容 pwsh 与 powershell.exe。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$BackupDirectory
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

# 1. 确定备份源目录
$backupDir = $BackupDirectory
if (-not $backupDir) {
    $lastBackupFile = Join-Path $projectRoot '.last-install-backup'
    if (Test-Path $lastBackupFile) {
        $candidate = (Get-Content -LiteralPath $lastBackupFile -Raw).Trim()
        if (Test-Path $candidate) {
            $backupDir = $candidate
        }
    }
}

if (-not $backupDir) {
    # 查找最近的 install-backup 快照
    $backupsBase = Join-Path $projectRoot 'backups'
    $latest = Get-ChildItem -Path $backupsBase -Directory -Filter 'install-backup-*' -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1
    if ($latest) {
        $backupDir = $latest.FullName
    }
}

if (-not $backupDir) {
    # 尝试兼容旧版 deployment 快照
    $deployPathFile = Join-Path $projectRoot '.deployment-path'
    if (Test-Path $deployPathFile) {
        $candidate = (Get-Content -LiteralPath $deployPathFile -Raw).Trim()
        if (Test-Path $candidate) {
            $backupDir = $candidate
        }
    }
}

if (-not $backupDir -or -not (Test-Path $backupDir)) {
    throw "未找到有效的终端配置备份快照目录。请使用 -BackupDirectory 指定备份路径。"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[回退] 开始执行终端配置一键无损回退" -ForegroundColor Cyan
Write-Host "[来源] 备份源目录: $backupDir" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$manifestFile = Join-Path $backupDir 'manifest.json'
$isModernManifest = Test-Path $manifestFile

function Get-FileSHA256([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $fileStream = [System.IO.File]::OpenRead($Path)
    try {
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $hasher.ComputeHash($fileStream)
        return [System.BitConverter]::ToString($hashBytes).Replace('-', '')
    } finally {
        $fileStream.Dispose()
    }
}

if ($isModernManifest) {
    $manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json

    # 1. 还原/清理文件
    Write-Host "`n[1/2] 正在还原各终端配置文件..." -ForegroundColor Yellow
    foreach ($entry in $manifest.Files) {
        $target = $entry.Target
        $desc = $entry.Desc
        $existed = [bool]$entry.Existed

        if ($existed) {
            $backupFilePath = Join-Path $backupDir $entry.Name
            if (-not (Test-Path $backupFilePath)) {
                Write-Warning "[!] 备份文件缺失，跳过还原: $backupFilePath"
                continue
            }

            # 校验备份完整性 (使用纯 .NET SHA256，避免 PS 5.1 在 WhatIf 模式下阻断哈希计算)
            if ($entry.SHA256) {
                $actualHash = Get-FileSHA256 $backupFilePath
                if ($actualHash -ne $entry.SHA256) {
                    Write-Warning "[!] 备份文件校验和不匹配，为确保安全跳过还原: $backupFilePath"
                    continue
                }
            }

            if ($PSCmdlet.ShouldProcess($target, "还原原始文件 ($desc)")) {
                $targetDir = Split-Path -Parent $target
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }
                Copy-Item -LiteralPath $backupFilePath -Destination $target -Force
                Write-Host "[OK] 已精确还原: $desc -> $target" -ForegroundColor Green
            }
        } else {
            # 安装前不存在，清理新生成的文件
            if (Test-Path -LiteralPath $target) {
                if ($PSCmdlet.ShouldProcess($target, "清理安装时新生成的文件 ($desc)")) {
                    Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
                    Write-Host "[清理] 已清理安装生成项: $desc -> $target" -ForegroundColor DarkGray
                }
            } else {
                Write-Host "[*] 目标原本不存在且当前未生成: $desc" -ForegroundColor DarkGray
            }
        }
    }

    # 2. 还原/清理 CMD AutoRun 注册表
    Write-Host "`n[2/2] 正在还原注册表状态..." -ForegroundColor Yellow
    if ($manifest.Registry) {
        $regKey = $manifest.Registry.Key
        $regName = $manifest.Registry.Name
        $regExisted = [bool]$manifest.Registry.Existed
        $regVal = $manifest.Registry.Value

        if ($regExisted -and $regVal) {
            if ($PSCmdlet.ShouldProcess("$regKey\$regName", "还原原始注册表值: $regVal")) {
                Set-ItemProperty -Path $regKey -Name $regName -Value $regVal -Force
                Write-Host "[OK] 已还原 CMD AutoRun 注册表项" -ForegroundColor Green
            }
        } else {
            if (Test-Path $regKey) {
                $existingProp = Get-ItemProperty -Path $regKey -Name $regName -ErrorAction SilentlyContinue
                if ($existingProp -and $existingProp.$regName -ne $null) {
                    if ($PSCmdlet.ShouldProcess("$regKey\$regName", "清理 AutoRun 注册表属性")) {
                        Remove-ItemProperty -Path $regKey -Name $regName -Force -ErrorAction SilentlyContinue
                        Write-Host "[清理] 已清理 CMD AutoRun 注册表项" -ForegroundColor Green
                    }
                } else {
                    Write-Host "[*] CMD AutoRun 注册表项已处于纯净状态" -ForegroundColor DarkGray
                }
            }
        }
    }
} else {
    # 兼容旧版 deployment.json 快照
    $oldDeploymentJson = Join-Path $backupDir 'deployment.json'
    if (Test-Path $oldDeploymentJson) {
        Write-Host "检测到旧版部署快照，正在调用 Manage-TerminalConfiguration.ps1 恢复..." -ForegroundColor Yellow
        $manageScript = Join-Path $backupDir 'Manage-TerminalConfiguration.ps1'
        if (-not (Test-Path $manageScript)) {
            $manageScript = Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1'
        }
        & $manageScript -Mode Rollback -BackupDirectory $backupDir -WhatIf:$WhatIfPreference

        # 清理 CMD
        $cmdInstaller = Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1'
        if (Test-Path $cmdInstaller) {
            & $cmdInstaller -Uninstall -WhatIf:$WhatIfPreference
        }
    } else {
        throw "无法识别备份快照格式: $backupDir"
    }
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "[OK] [一键回退完成] 系统中所有终端配置已成功恢复至安装前状态！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "[提示] 重新打开各个终端（pwsh / cmd / powershell.exe）即可生效。" -ForegroundColor Cyan
