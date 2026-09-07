<#
.SYNOPSIS
    Windows PowerShell 5.1 极速美化环境一键安装脚本
.DESCRIPTION
    面向 Windows 10/11 内置 PowerShell 及 Windows 8.1 (WMF 5.1)。
    自动配置 Scoop 与高效工具链、修复 UTF-8 控制台中文输出、
    支持随机丰富主题 (Oh My Posh)、固定 Catppuccin Mocha 主题或极速 Starship 赛博朋克主题，兼顾颜值与启动性能。
#>
[CmdletBinding()]
param(
    [ValidateSet('Random', 'CatppuccinMocha', 'Starship')]
    [string]$Theme = 'Random',
    [switch]$SkipBackup,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts\TerminalSetupCommon.ps1')

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始安装与配置 Windows PowerShell 5.1 终端环境" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 基础运行环境与 TLS 1.2 强制启用 (兼容 Windows 8.1)
Initialize-SetupEnvironment

if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Warning "[!] 当前 PowerShell 版本为 $($PSVersionTable.PSVersion)。"
    Write-Warning "若运行在 Windows 8.1 上，请先安装 Windows Management Framework 5.1 (WMF 5.1) 以获得最佳支持。"
}

# 2. 全自动前置备份：捕获当前所有终端配置，支持一键无损回退
if (-not $SkipBackup) { $null=Backup-AllTerminalConfigurations -Components @('WinPS51','Shared') }

# 3. 检查并准备 Scoop 包管理器
Write-Host "`n[1/4] 检查并准备 Scoop 包管理器及仓库..." -ForegroundColor Yellow
Ensure-ScoopBuckets @('main', 'extras', 'nerd-fonts')

# 3. 安装工具链与字体
Write-Host "`n[2/4] 检查并安装 CLI 软件及 JetBrainsMono 字体..." -ForegroundColor Yellow
$appsToInstall = @(
    'git',
    'fastfetch',
    'starship',
    'eza',
    'bat',
    'nerd-fonts/JetBrainsMono-NF'
)
if ($Theme -in @('CatppuccinMocha', 'Random')) {
    $appsToInstall += 'oh-my-posh'
}
Install-ScoopAppsIfMissing $appsToInstall
Ensure-FastfetchConfigured
Ensure-StarshipConfigured
if ($Theme -in @('CatppuccinMocha', 'Random')) {
    $null = Ensure-OhMyPoshThemes
}

# 4. 准备 PSReadLine 模块 (Windows PowerShell 5.1 自带 2.0，推荐升级)
Write-Host "`n[3/4] 检查 PowerShell 模块..." -ForegroundColor Yellow
Install-PSModulesIfMissing @('PSReadLine') -Edition Desktop

# 5. 生成并部署 Windows PowerShell 5.1 Profile
Write-Host "`n[4/4] 部署配置文件至 WindowsPowerShell Profile..." -ForegroundColor Yellow
$winPsProfileTarget = Join-Path (Get-TerminalDocumentsPath) 'WindowsPowerShell/Microsoft.PowerShell_profile.ps1'
$winPsDir = Split-Path -Parent $winPsProfileTarget
if (-not (Test-Path $winPsDir)) {
    New-Item -ItemType Directory -Path $winPsDir -Force | Out-Null
}

# 自动备份旧配置
if (Test-Path -LiteralPath $winPsProfileTarget) {
    $backupPath = "$winPsProfileTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $winPsProfileTarget -Destination $backupPath -Force
    Write-Host "[备份] 已备份现有 Profile: $backupPath" -ForegroundColor DarkGray
}

$mode = switch ($Theme) {
    'Starship'        { 'starship' }
    'CatppuccinMocha' { 'fixed' }
    default           { 'random' }
}
$header = @"
# ============================================================================
# 用户环境模式变量 (由 Install-WinPowerShell51.ps1 自动生成)
# ============================================================================
if (-not `$env:POWERSHELL_THEME_MODE) { `$env:POWERSHELL_THEME_MODE = '$mode' }

"@
$sourceContent = [IO.File]::ReadAllText((Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'), [System.Text.Encoding]::UTF8)
$winPsContent = $header + $sourceContent

Set-TerminalText $winPsProfileTarget $winPsContent -Bom

Write-Host "[OK] Windows PowerShell 5.1 Profile 已成功安装至: $winPsProfileTarget" -ForegroundColor Green
Write-Host "`n[+] 安装成功！请打开 powershell.exe 查看全新终端效果。" -ForegroundColor Cyan
