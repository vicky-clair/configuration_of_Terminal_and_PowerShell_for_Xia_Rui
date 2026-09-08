<#
.SYNOPSIS
    Windows 全终端现代化与美化一键集成总装脚本
.DESCRIPTION
    按序执行：
    1. Install-PowerShell7.ps1 (PowerShell 7 核心工具、字体、模块、横幅及提示符)
    2. Install-WinPowerShell51.ps1 (Windows PowerShell 5.1 默认随机主题与 UTF-8 修复)
    3. Install-Cmd.ps1 (CMD Clink + Starship 赛博朋克固定主题与别名)
    可选/扩展执行：
    4. Install-NuShell.ps1 (NuShell 现代化终端环境与美化配置，-IncludeNuShell 或 -All)
    5. Install-MSYS2.ps1 (MSYS2 现代化开发终端环境与美化配置，-IncludeMSYS2 或 -All)
    兼容 Windows 11、Windows 10 及 Windows 8.1。
#>
[CmdletBinding()]
param(
    [ValidateSet('Random', 'Fixed', 'Starship')]
    [string]$ThemeMode = 'Random',
    [switch]$SkipPowerShell7,
    [switch]$SkipWinPowerShell51,
    [switch]$SkipCmd,
    [switch]$IncludeNuShell,
    [switch]$IncludeMSYS2,
    [switch]$All,
    [switch]$ApplyWindowsTerminalSettings,
    [switch]$NonInteractive,
    [string]$Msys2InstallPath
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts\TerminalSetupCommon.ps1')

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始执行 Windows 全终端现代化与美化一键集成部署" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 自动解除 PowerShell 脚本执行策略限制 (针对当前用户设为 RemoteSigned 并持久化至注册表)
try {
    $policy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    if ($policy -in @('Restricted', 'Undefined')) {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
        Write-Host "[OK] 当前用户执行策略已配置: RemoteSigned" -ForegroundColor Green
    }
    $regPath = 'HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
    if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    Set-ItemProperty -Path $regPath -Name 'ExecutionPolicy' -Value 'RemoteSigned' -Force -ErrorAction SilentlyContinue
} catch {}

# 全自动前置统合备份：捕获当前所有终端配置，支持一键无损回退
$components=@('Shared')
if (-not $SkipPowerShell7) { $components += @('PowerShell7','Terminal') }
if (-not $SkipWinPowerShell51) { $components += 'WinPS51' }
if (-not $SkipCmd) { $components += 'Cmd' }
if ($IncludeNuShell -or $All) { $components += @('NuShell','Terminal') }
if ($IncludeMSYS2 -or $All) { $components += 'Terminal' }
# MSYS2 captures its resolved root immediately before modifying its configuration.
$backup = Backup-AllTerminalConfigurations -Components $components


# 1. PowerShell 7
if (-not $SkipPowerShell7) {
    Write-Host "`n>>> [1/5] 执行 PowerShell 7 环境安装与美化配置..." -ForegroundColor Yellow
    $ps7Params = @{SkipBackup=$true}
    if ($ThemeMode) { $ps7Params['ThemeMode'] = $ThemeMode }
    if ($PSBoundParameters.ContainsKey('ApplyWindowsTerminalSettings')) {
        $ps7Params['ApplyWindowsTerminalSettings'] = $ApplyWindowsTerminalSettings
    }
    if ($NonInteractive) { $ps7Params['NonInteractive'] = $true }
    & (Join-Path $projectRoot 'Install-PowerShell7.ps1') @ps7Params
} else {
    Write-Host "`n>>> [1/5] 跳过 PowerShell 7 配置 (-SkipPowerShell7)" -ForegroundColor DarkGray
}

# 2. Windows PowerShell 5.1
if (-not $SkipWinPowerShell51) {
    Write-Host "`n>>> [2/5] 执行 Windows PowerShell 5.1 环境配置与默认随机主题..." -ForegroundColor Yellow
    & (Join-Path $projectRoot 'Install-WinPowerShell51.ps1') -SkipBackup
} else {
    Write-Host "`n>>> [2/5] 跳过 Windows PowerShell 5.1 配置 (-SkipWinPowerShell51)" -ForegroundColor DarkGray
}

# 3. CMD (命令提示符)
if (-not $SkipCmd) {
    Write-Host "`n>>> [3/5] 执行 CMD (命令提示符) Clink + Starship 现代化配置..." -ForegroundColor Yellow
    & (Join-Path $projectRoot 'Install-Cmd.ps1') -SkipBackup
} else {
    Write-Host "`n>>> [3/5] 跳过 CMD 配置 (-SkipCmd)" -ForegroundColor DarkGray
}

# 4. NuShell (可选或 -All)
if ($IncludeNuShell -or $All) {
    Write-Host "`n>>> [4/5] 执行 NuShell (nu) 现代化终端安装与美化配置..." -ForegroundColor Yellow
    & (Join-Path $projectRoot 'Install-NuShell.ps1') -SkipBackup
} else {
    Write-Host "`n>>> [4/5] 未指定 -IncludeNuShell 或 -All，跳过 NuShell 配置" -ForegroundColor DarkGray
}

# 5. MSYS2 (可选或 -All)
if ($IncludeMSYS2 -or $All) {
    Write-Host "`n>>> [5/5] 执行 MSYS2 现代化开发终端安装与美化配置..." -ForegroundColor Yellow
    & (Join-Path $projectRoot 'Install-MSYS2.ps1') -Msys2InstallPath $Msys2InstallPath -ParentSnapshot $backup
} else {
    Write-Host "`n>>> [5/5] 未指定 -IncludeMSYS2 或 -All，跳过 MSYS2 配置" -ForegroundColor DarkGray
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "[OK] 全终端现代化与美化环境安装完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "[提示] 您可以立即打开各个终端进行体验：" -ForegroundColor Cyan
Write-Host "  - Windows Terminal (PowerShell 7 / CMD / Windows PowerShell / NuShell / MSYS2)" -ForegroundColor Gray
Write-Host "  - 原生 cmd.exe (已自动加载 UTF-8、Doskey 别名与 Starship 赛博朋克提示符)" -ForegroundColor Gray
Write-Host "  - 原生 powershell.exe (已自动修复编码并加载极速固定主题)" -ForegroundColor Gray
if ($IncludeNuShell -or $All) {
    Write-Host "  - NuShell (nu.exe: 已配置 Starship 提示符、Fastfetch 横幅与 Unix 别名)" -ForegroundColor Gray
}
if ($IncludeMSYS2 -or $All) {
    Write-Host "  - MSYS2 (bash: 已继承 Windows PATH、配置 Starship 提示符与 UTF-8)" -ForegroundColor Gray
}
Write-Host "  - 如需回退，可随时运行 .\Restore-All.ps1 恢复所有配置。" -ForegroundColor Yellow
