<#
.SYNOPSIS
    CMD (命令提示符) 现代化美化环境一键安装脚本
.DESCRIPTION
    配置 Windows 11/10/8.1 下的 cmd.exe 现代化运行环境。
    自动配置 Scoop 与 Clink、Starship、Eza、Bat、Ripgrep 依赖，
    固定配置赛博朋克霓虹 Starship 提示符、UTF-8 字符集 (65001) 与现代 Doskey 别名，
    通过当前用户注册表 AutoRun 自动化挂载，无需管理员权限，支持干净卸载。
#>
[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts\TerminalSetupCommon.ps1')

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始安装与配置 CMD 命令提示符现代化环境" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 基础环境与 TLS 准备
Initialize-SetupEnvironment

if ($Uninstall) {
    & (Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1') -Uninstall
    return
}

# 2. 全自动前置备份：捕获当前所有终端配置，支持一键无损回退
Backup-AllTerminalConfigurations

# 3. 检查并准备 Scoop 包管理器
Write-Host "`n[1/4] 检查并准备 Scoop 包管理器及仓库..." -ForegroundColor Yellow
Ensure-ScoopBuckets @('main', 'extras', 'nerd-fonts')

# 3. 安装 CMD 现代化所需的核心软件与字体
Write-Host "`n[2/4] 检查并安装 Clink、Starship 及现代 CLI 工具..." -ForegroundColor Yellow
$cmdApps = @(
    'clink',
    'fastfetch',
    'starship',
    'eza',
    'bat',
    'ripgrep',
    'nerd-fonts/JetBrainsMono-NF'
)
Install-ScoopAppsIfMissing $cmdApps
Ensure-FastfetchConfigured
Ensure-StarshipConfigured

# 5. 部署 CMD AutoRun 脚本与 Clink Lua 脚本并注册
Write-Host "`n[4/4] 部署 CMD 初始化脚本与当前用户 AutoRun 注册表..." -ForegroundColor Yellow
& (Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1')

Write-Host "`n[+] CMD 现代化配置已全部就绪！打开 cmd.exe 即可立即查看全套效果。" -ForegroundColor Cyan
