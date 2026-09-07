<#
.SYNOPSIS
    Windows PowerShell 5.1 极速美化环境一键安装脚本
.DESCRIPTION
    面向 Windows 10/11 内置 PowerShell 及 Windows 8.1 (WMF 5.1)。
    自动配置 Scoop 与高效工具链、修复 UTF-8 控制台中文输出、
    固定配置高颜值极速 Starship 赛博朋克主题或轻量 Oh My Posh 主题，兼顾颜值与启动性能。
#>
[CmdletBinding()]
param(
    [ValidateSet('Starship', 'CatppuccinMocha')]
    [string]$Theme = 'Starship'
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
Backup-AllTerminalConfigurations

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
if ($Theme -eq 'CatppuccinMocha') {
    $appsToInstall += 'oh-my-posh'
}
Install-ScoopAppsIfMissing $appsToInstall
Ensure-FastfetchConfigured

# 4. 准备 PSReadLine 模块 (Windows PowerShell 5.1 自带 2.0，推荐升级)
Write-Host "`n[3/4] 检查 PowerShell 模块..." -ForegroundColor Yellow
Install-PSModulesIfMissing @('PSReadLine')

# 5. 生成并部署 Windows PowerShell 5.1 Profile
Write-Host "`n[4/4] 部署配置文件至 WindowsPowerShell Profile..." -ForegroundColor Yellow
$winPsProfileTarget = Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1'
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

$promptBlock = ''
if ($Theme -eq 'Starship') {
    $promptBlock = @"
# 固定精选主题：Starship 原生二进制赛博朋克提示符（极速秒开）
if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
"@
} else {
    $promptBlock = @"
# 固定精选主题：Oh My Posh Catppuccin Mocha 主题
`$themePath = "`$env:USERPROFILE\oh-my-posh-themes\catppuccin_mocha.omp.json"
if (-not (Test-Path `$themePath)) {
    `$themePath = "`$env:USERPROFILE\scoop\apps\oh-my-posh\current\themes\catppuccin_mocha.omp.json"
}
if (Test-Path `$themePath) {
    Invoke-Expression (&oh-my-posh init pwsh --config `$themePath | Out-String)
}
"@
}

$winPsContent = @"
# ============================================================================
# Windows PowerShell 5.1 启动配置文件 (由 Install-WinPowerShell51.ps1 自动生成)
# ============================================================================

# 1. 修复控制台与管道 UTF-8 编码，防止中文乱码
`$OutputEncoding = New-Object System.Text.UTF8Encoding `$false
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# 2. Scoop shims 环境变量防丢失
`$scoopShims = Join-Path `$env:USERPROFILE 'scoop\shims'
if (Test-Path `$scoopShims) {
    `$paths = @(`$env:PATH -split ';' | ForEach-Object { `$_.Trim().TrimEnd('\', '/') })
    if (`$paths -notcontains `$scoopShims.TrimEnd('\', '/')) {
        if (`$env:PATH) {
            `$env:PATH = "`$env:PATH;`$scoopShims"
        } else {
            `$env:PATH = `$scoopShims
        }
    }
}

# 3. 现代化别名支持 (eza / bat)
function ll { if (Get-Command eza -ErrorAction SilentlyContinue) { eza -l --icons --group-directories-first @args } else { Get-ChildItem @args } }
function la { if (Get-Command eza -ErrorAction SilentlyContinue) { eza -la --icons --group-directories-first @args } else { Get-ChildItem -Force @args } }
function catc { if (Get-Command bat -ErrorAction SilentlyContinue) { bat --paging=never @args } else { Get-Content @args } }

# 4. Git 常用快捷别名
if (Get-Command git -ErrorAction SilentlyContinue) {
    Set-Alias g git
    function gst { git status @args }
    function gco { git checkout @args }
    function gb  { git branch @args }
    function glog { git log --oneline --graph --all @args }
    function gpull { git pull @args }
    function gps { git push @args }
}

# 5. PSReadLine 基础高亮
if (Get-Module -ListAvailable PSReadLine) {
    try {
        Import-Module PSReadLine -ErrorAction Stop
        Set-PSReadLineOption -BellStyle None -HistoryNoDuplicates:`$true
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    } catch {}
}

# 6. 加载固定提示符主题
$promptBlock

# 7. Fastfetch ASCII 硬件横幅展示 (支持 `$env:POWERSHELL_PROFILE_BANNER 控制)
if (`$env:POWERSHELL_PROFILE_BANNER -ne '0' -and `$env:POWERSHELL_PROFILE_MINIMAL -ne '1') {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        `$confFile = Join-Path `$env:USERPROFILE '.config\fastfetch\config.jsonc'
        if (Test-Path `$confFile) {
            fastfetch -c `$confFile
        } else {
            fastfetch
        }
    }
}

# 8. 现代化功能就绪卡片 (支持 `$env:POWERSHELL_PROFILE_TIPS 控制)
if (`$env:POWERSHELL_PROFILE_BANNER -ne '0' -and `$env:POWERSHELL_PROFILE_MINIMAL -ne '1' -and `$env:POWERSHELL_PROFILE_TIPS -ne '0') {
    if (Get-Command yazi -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ yazi 文件管理器已集成 (命令: yazi)" -ForegroundColor Green
    }
    if (Get-Command eza -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ eza 现代化 ls 已启用 (别名: ll, la)" -ForegroundColor Green
    }
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ bat 代码高亮查看已启用 (命令: catc)" -ForegroundColor Green
    }
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ Git 快捷别名已加载 (g, gst, gco, gb, glog)" -ForegroundColor Cyan
    }
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ Starship 赛博朋克极速提示符已加载" -ForegroundColor Magenta
    }
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        Write-Host "  ✓ fastfetch 系统信息工具已启动" -ForegroundColor DarkGray
    }
    Write-Host ""
}
"@

$utf8WithBom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($winPsProfileTarget, $winPsContent, $utf8WithBom)

Write-Host "[OK] Windows PowerShell 5.1 Profile 已成功安装至: $winPsProfileTarget" -ForegroundColor Green
Write-Host "`n[+] 安装成功！请打开 powershell.exe 查看全新终端效果。" -ForegroundColor Cyan
