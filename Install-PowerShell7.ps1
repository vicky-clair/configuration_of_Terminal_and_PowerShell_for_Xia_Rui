<#
.SYNOPSIS
    PowerShell 7 (pwsh) 现代化美化环境一键安装脚本
.DESCRIPTION
    自动配置 Scoop 与所需软件依赖、PowerShell 模块、Nerd Font 字体，
    并支持交互选择【固定主题 (Catppuccin Mocha)】或【每日随机主题】或【Starship 赛博朋克主题】。
    全面兼容 Windows 11、Windows 10 及 Windows 8.1。
#>
[CmdletBinding()]
param(
    [ValidateSet('Random', 'Fixed', 'Starship')]
    [string]$ThemeMode = 'Random',
    [switch]$ApplyWindowsTerminalSettings,
    [switch]$NonInteractive,
    [switch]$SkipBackup
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts\TerminalSetupCommon.ps1')

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始安装与配置 PowerShell 7 现代化终端环境" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 基础运行环境与 TLS 准备
Initialize-SetupEnvironment

# 2. 全自动前置备份：捕获当前所有终端配置，支持一键无损回退
if (-not $SkipBackup) { $null=Backup-AllTerminalConfigurations -Components @('PowerShell7','Terminal','Shared') }

# 3. 检查并安装 Scoop 与必要仓库
Write-Host "`n[1/5] 检查并准备 Scoop 包管理器及仓库..." -ForegroundColor Yellow
Ensure-ScoopBuckets @('main', 'extras', 'versions', 'nerd-fonts')

# 3. 安装核心 CLI 工具与字体
Write-Host "`n[2/5] 检查并安装所需 CLI 软件及 JetBrainsMono 图标字体..." -ForegroundColor Yellow
$coreApps = @(
    'pwsh',
    'git',
    'oh-my-posh',
    'starship',
    'fastfetch',
    'eza',
    'bat',
    'ripgrep',
    'fd',
    'zoxide',
    'fzf',
    'neovim',
    'lazydocker',
    'lazygit',
    'vfox',
    'nerd-fonts/JetBrainsMono-NF'
)
Install-ScoopAppsIfMissing $coreApps

# 4. 安装 PowerShell 核心模块
Write-Host "`n[3/5] 检查并安装 PowerShell Gallery 模块插件..." -ForegroundColor Yellow
Install-PSModulesIfMissing @('PSReadLine', 'Terminal-Icons', 'PSFzf') -Edition Core

# 5. 确保 Oh My Posh 离线主题库与 Fastfetch 专属横幅就绪
Write-Host "`n[4/5] 检查本地主题与 Fastfetch 专属配置资产..." -ForegroundColor Yellow
$themeCount = Ensure-OhMyPoshThemes
Write-Host "[OK] 本地主题库已就绪 (共找到 $themeCount 个主题)" -ForegroundColor Green
Ensure-FastfetchConfigured
Ensure-StarshipConfigured

# 6. 交互式主题选择 (回车默认: Random 每日随机主题)
if ($PSBoundParameters.ContainsKey('ThemeMode')) {
    # 用户显式指定了参数
} elseif ($NonInteractive) {
    $ThemeMode = 'Random'
} else {
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "[*] 请选择 PowerShell 7 提示符主题模式：" -ForegroundColor Yellow
    Write-Host "  [1] 每日随机主题 (推荐：启动时从本地 120+ 官方主题库智能随机抽取，每天新体验，回车默认)" -ForegroundColor Green
    Write-Host "  [2] 固定主题 (Catppuccin Mocha，与 Windows Terminal 深度契合，极速秒开)" -ForegroundColor Cyan
    Write-Host "  [3] Starship 赛博朋克渐变主题 (与 CMD / NuShell 保持风格完全一致)" -ForegroundColor Magenta
    Write-Host "============================================================" -ForegroundColor Cyan
    $choice = Read-Host "请输入选项 [1-3] (回车默认: 1)"
    $ThemeMode = switch ($choice.Trim()) {
        '2' { 'Fixed' }
        '3' { 'Starship' }
        default { 'Random' }
    }
}

Write-Host "`n已选择提示符模式: [$ThemeMode]" -ForegroundColor Cyan

# 7. 部署与配置 PowerShell 7 Profile
Write-Host "`n[5/5] 部署配置文件至当前用户 Profile..." -ForegroundColor Yellow
$profileTarget = Join-Path (Get-TerminalDocumentsPath) 'PowerShell/Microsoft.PowerShell_profile.ps1'
$profileTargetDir = Split-Path -Parent $profileTarget
if (-not (Test-Path $profileTargetDir)) {
    New-Item -ItemType Directory -Path $profileTargetDir -Force | Out-Null
}

# 自动备份旧配置
if (Test-Path -LiteralPath $profileTarget) {
    $backupPath = "$profileTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $profileTarget -Destination $backupPath -Force
    Write-Host "[备份] 已备份现有 Profile: $backupPath" -ForegroundColor DarkGray
}

$profileSource = Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'
$header = @"
# ============================================================================
# 用户环境模式变量 (由 Install-PowerShell7.ps1 自动生成)
# ============================================================================
if (-not `$env:POWERSHELL_THEME_MODE) { `$env:POWERSHELL_THEME_MODE = '$($ThemeMode.ToLowerInvariant())' }

"@

$sourceContent = Get-Content -LiteralPath $profileSource -Raw -Encoding UTF8
$finalContent = $header + $sourceContent
$utf8WithBom = New-Object System.Text.UTF8Encoding $true
Set-TerminalText $profileTarget $finalContent -Bom

Write-Host "[OK] PowerShell 7 Profile 已成功安装至: $profileTarget" -ForegroundColor Green

# 8. 智能联动 Windows Terminal 深度美化配置 (亚克力毛玻璃/Catppuccin配色/JetBrainsMono字体)
$wtStableDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState'
$wtPreviewDir = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState'
if ((Test-Path $wtStableDir) -or (Test-Path $wtPreviewDir)) {
    $applyWt = $false
    if ($PSBoundParameters.ContainsKey('ApplyWindowsTerminalSettings')) {
        $applyWt = [bool]$ApplyWindowsTerminalSettings
    } elseif ($NonInteractive) {
        $applyWt = $false
    } else {
        Write-Host "`n============================================================" -ForegroundColor Cyan
        Write-Host "[*] 检测到系统中已安装 Windows Terminal！" -ForegroundColor Yellow
        Write-Host "是否同步应用项目推荐的 Windows Terminal 深度美化配置？" -ForegroundColor Yellow
        Write-Host "  (包含: 85% 亚克力磨砂透明、Catppuccin Mocha 配色、JetBrainsMono NF 字体、完整多 Shell 导航)" -ForegroundColor DarkGray
        Write-Host "============================================================" -ForegroundColor Cyan
        $wtChoice = Read-Host "是否应用 Windows Terminal 配置文件？[Y/N] (回车默认: Y)"
        if ($wtChoice.Trim() -ne 'N' -and $wtChoice.Trim() -ne 'n') {
            $applyWt = $true
        }
    }
    if ($applyWt) {
        Ensure-WindowsTerminalConfigured -Force
    }
}

Write-Host "`n[+] 安装成功！请新开一个 pwsh 窗口体验全新终端。" -ForegroundColor Cyan
