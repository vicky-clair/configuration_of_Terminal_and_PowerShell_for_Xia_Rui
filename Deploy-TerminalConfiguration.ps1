<#
.SYNOPSIS
    一键部署终端与 Shell 全套现代化美化配置
.DESCRIPTION
    部署 PowerShell 7 Profile、Windows Terminal Settings 以及 CMD (UTF-8/Doskey/Clink) 配置。
    在部署前自动创建完整字节备份快照，记录 SHA-256 校验和，支持一键无损回退。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$SkipCmd
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot

Write-Host "🚀 开始终端与 Shell 现代化配置部署..." -ForegroundColor Cyan

# 1. 运行配置回归自检 (测试沙箱内部应真实执行，不受 WhatIf 阻断)
Write-Host "`n[1/4] 运行配置静态与语法检查..." -ForegroundColor Yellow
$verifyScript = Join-Path $projectRoot 'tests\Verify-Configuration.ps1'
& pwsh -NoProfile -File $verifyScript

# 2. 获取或创建部署快照
Write-Host "`n[2/4] 准备部署快照与校验清单..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("Live Terminal Configurations", "Create deployment snapshot")) {
    $deployDir = & (Join-Path $projectRoot 'scripts\New-DeploymentSnapshot.ps1')
} else {
    $deploymentPathFile = Join-Path $projectRoot '.deployment-path'
    $deployDir = if (Test-Path $deploymentPathFile) {
        (Get-Content $deploymentPathFile -Raw).Trim()
    } else {
        Join-Path $projectRoot 'backups\deployment-20260907-083202'
    }
    Write-Host "WhatIf 模式：使用快照目录 $deployDir" -ForegroundColor DarkGray
}

# 3. 部署 PowerShell 7 与 Windows Terminal
Write-Host "`n[3/4] 部署 PowerShell 7 Profile 与 Windows Terminal Settings..." -ForegroundColor Yellow
& (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Apply -BackupDirectory $deployDir -WhatIf:$WhatIfPreference

# 4. 部署 CMD 现代化配置
if (-not $SkipCmd) {
    Write-Host "`n[4/4] 部署 CMD 现代化配置 (UTF-8, Doskey, Clink/Starship)..." -ForegroundColor Yellow
    & (Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1') -WhatIf:$WhatIfPreference
} else {
    Write-Host "`n[4/4] 已跳过 CMD 配置部署 (-SkipCmd)" -ForegroundColor DarkGray
}

Write-Host "`n✨ 配置部署流程处理完毕！" -ForegroundColor Green
Write-Host "💡 提示：" -ForegroundColor Cyan
Write-Host "  - 打开新的 PowerShell 7 标签页查看 Fastfetch 专属横幅与 Catppuccin Mocha 提示符" -ForegroundColor Gray
Write-Host "  - 打开新的 Command Prompt 标签页测试 UTF-8 编码、Doskey 别名与 Clink/Starship" -ForegroundColor Gray
Write-Host "  - 如需一键回退，可随时运行: pwsh -NoProfile -File .\Restore-TerminalConfiguration.ps1 -IncludeCmd`n" -ForegroundColor Gray
