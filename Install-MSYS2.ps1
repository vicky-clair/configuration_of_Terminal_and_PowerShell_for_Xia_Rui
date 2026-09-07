<#
.SYNOPSIS
    MSYS2 现代化开发终端环境一键安装与美化配置脚本
.DESCRIPTION
    1. 自动执行全终端前置统合备份 (Backup-AllTerminalConfigurations)，支持一键回退；
    2. 包管理器容错降级策略：优先尝试 Chocolatey (最多重试2次)，失败自动配置 WinGet 软件源仓库并安装，最后以 Scoop 兜底；
    3. 自动配置 MSYS2 环境与 ~/.bashrc，注入 Windows PATH 环境变量继承 (MSYS2_PATH_TYPE=inherit)；
    4. 自动配置 UTF-8 中文编码支持、Starship 赛博朋克提示符、Fastfetch 启动横幅及现代别名；
    5. 自动检测并注册 Windows Terminal MSYS2 终端配置文件；
    6. 兼容 Windows 11、Windows 10 与 Windows 8.1，兼容 pwsh 与 powershell.exe。
#>
[CmdletBinding()]
param(
    [switch]$NonInteractive,
    [switch]$SkipBackup,
    [string]$Msys2InstallPath = 'C:\msys64'
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
. (Join-Path $projectRoot 'scripts\TerminalSetupCommon.ps1')

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始执行 MSYS2 现代化开发终端环境安装与美化配置" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 跨平台环境初始化
Initialize-SetupEnvironment

# 2. 全自动前置统合备份
if (-not $SkipBackup) {
    $null = Backup-AllTerminalConfigurations
}

# 3. 检查或安装 MSYS2
Write-Host "`n[1/3] 检查并定位 MSYS2 安装环境..." -ForegroundColor Yellow

$msys2Candidates = @(
    $Msys2InstallPath,
    'C:\msys64',
    "$env:SystemDrive\msys64",
    (Join-Path $env:USERPROFILE 'scoop\apps\msys2\current'),
    'C:\tools\msys64'
)

$msys2Root = $null
foreach ($cand in $msys2Candidates) {
    if (Test-Path (Join-Path $cand 'usr\bin\bash.exe')) {
        $msys2Root = $cand
        break
    }
}

if (-not $msys2Root) {
    Write-Host "[*] 未在常用路径检测到 MSYS2，启动容错安装流程..." -ForegroundColor Yellow
    $null = Install-AppWithChocoWingetFallback -Name "MSYS2" -ChocoId "msys2" -WingetId "MSYS2.MSYS2" -ScoopId "msys2" -PathCheck "C:\msys64"
    foreach ($cand in $msys2Candidates) {
        if (Test-Path (Join-Path $cand 'usr\bin\bash.exe')) {
            $msys2Root = $cand
            break
        }
    }
}

if (-not $msys2Root) {
    throw "未能成功定位或安装 MSYS2。请确认安装路径或通过 winget/choco/scoop 手动安装。"
}

$bashExe = Join-Path $msys2Root 'usr\bin\bash.exe'
Write-Host "[OK] 已定位 MSYS2 环境: $msys2Root (bash: $bashExe)" -ForegroundColor Green
Ensure-FastfetchConfigured

# 4. 初始化 MSYS2 运行环境与配置 ~/.bashrc
Write-Host "`n[2/3] 初始化 MSYS2 运行环境与配置 ~/.bashrc ..." -ForegroundColor Yellow

# 配置 MSYS2_PATH_TYPE 用户环境变量及 ini 设置
try {
    [System.Environment]::SetEnvironmentVariable('MSYS2_PATH_TYPE', 'inherit', 'User')
    $env:MSYS2_PATH_TYPE = 'inherit'
    foreach ($iniName in @('msys2.ini', 'ucrt64.ini', 'mingw64.ini', 'clang64.ini')) {
        $iniPath = Join-Path $msys2Root $iniName
        if (Test-Path $iniPath) {
            $iniContent = [System.IO.File]::ReadAllText($iniPath, [System.Text.Encoding]::UTF8)
            if ($iniContent -match '#MSYS2_PATH_TYPE=inherit') {
                $iniContent = $iniContent -replace '#MSYS2_PATH_TYPE=inherit', 'MSYS2_PATH_TYPE=inherit'
                [System.IO.File]::WriteAllText($iniPath, $iniContent, [System.Text.Encoding]::UTF8)
            }
        }
    }
    Write-Host "[OK] 已配置 MSYS2_PATH_TYPE=inherit 环境变量与启动策略" -ForegroundColor Green
} catch {
    Write-Verbose "MSYS2 PATH_TYPE configuration note: $_"
}

# 触发 bash 一次性初始化 /etc/skel
try {
    & $bashExe -lc "exit" 2>$null
} catch {}

$msysHomeDir = Join-Path $msys2Root "home\$env:USERNAME"
if (-not (Test-Path $msysHomeDir)) {
    New-Item -ItemType Directory -Path $msysHomeDir -Force | Out-Null
}

$bashrcPath = Join-Path $msysHomeDir '.bashrc'
$originalBashrc = ''
if (Test-Path $bashrcPath) {
    $originalBashrc = [System.IO.File]::ReadAllText($bashrcPath, [System.Text.Encoding]::UTF8)
}

$startMarker = '# >>> Windows Terminal Beautification for MSYS2 >>>'
$endMarker = '# <<< Windows Terminal Beautification for MSYS2 <<<'

$beautifyConfig = @'
# >>> Windows Terminal Beautification for MSYS2 >>>
# 1. 继承与补充 Windows 本机环境变量（允许直接调用 Windows 原生安装的 starship, fastfetch, eza, git, yazi 等工具）
export MSYS2_PATH_TYPE=inherit
WIN_USER="${USERNAME:-$USER}"
for p in \
    "/c/Users/$WIN_USER/scoop/shims" \
    "/c/Users/$WIN_USER/AppData/Local/Microsoft/WinGet/Links" \
    "/c/Users/$WIN_USER/AppData/Local/Microsoft/WindowsApps" \
    "/c/Program Files/Neovim/bin"; do
    [ -d "$p" ] && [[ ":$PATH:" != *":$p:"* ]] && export PATH="$PATH:$p"
done

# 2. 强制 UTF-8 与中文语言环境
export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

# 3. Starship 赛博朋克提示符集成
if command -v starship &> /dev/null; then
    eval "$(starship init bash)"
fi

# 4. Fastfetch 终端横幅展示
if command -v fastfetch &> /dev/null && [ "${PROFILE_BANNER:-1}" != "0" ] && [ -t 1 ]; then
    FF_CONF="/c/Users/$WIN_USER/.config/fastfetch/config.jsonc"
    if [ -f "$FF_CONF" ]; then
        fastfetch -c "$FF_CONF" 2>/dev/null
    else
        fastfetch 2>/dev/null
    fi
fi

# 5. 现代化功能就绪卡片
if [ "${PROFILE_TIPS:-1}" != "0" ] && [ "${PROFILE_BANNER:-1}" != "0" ] && [ -t 1 ]; then
    command -v yazi &> /dev/null && echo -e "  \033[32m✓ yazi 文件管理器已集成 (命令: yazi)\033[0m"
    command -v bat &> /dev/null && command -v eza &> /dev/null && echo -e "  \033[32m✓ bat + eza 现代化预览集成完成\033[0m"
    command -v eza &> /dev/null && echo -e "  \033[32m✓ eza 现代化 ls 已启用 (别名: ll, la, lt)\033[0m"
    command -v bat &> /dev/null && echo -e "  \033[32m✓ bat 代码高亮查看已启用 (别名: cat)\033[0m"
    command -v git &> /dev/null && echo -e "  \033[36m✓ Git 快捷别名已加载 (g, gst, gco, gb, glog)\033[0m"
    command -v zoxide &> /dev/null && echo -e "  \033[33m✓ zoxide 智能跳转已启用 (命令: z)\033[0m"
    command -v starship &> /dev/null && echo -e "  \033[35m✓ Starship 赛博朋克提示符已加载\033[0m"
    command -v fastfetch &> /dev/null && echo -e "  \033[90m✓ fastfetch 系统信息工具已启动\033[0m"
    echo ""
fi

# 5. 现代化命令行常用别名 (Eza, Bat, Git)
if command -v eza &> /dev/null; then
    alias ll='eza -l --icons --git --header'
    alias la='eza -la --icons --git --header'
    alias lt='eza --tree --level=2 --icons'
else
    alias ll='ls -lh'
    alias la='ls -lah'
fi

if command -v bat &> /dev/null; then
    alias cat='bat --paging=never'
fi

alias g='git'
alias gst='git status'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias gpull='git pull'
alias gps='git push'
# <<< Windows Terminal Beautification for MSYS2 <<<
'@

# 规范化换行并安全替换或追加
$newBashrc = ''
if ($originalBashrc -match "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))") {
    $newBashrc = $originalBashrc -replace "(?s)$([regex]::Escape($startMarker)).*?$([regex]::Escape($endMarker))", $beautifyConfig
} else {
    if ($originalBashrc.Trim().Length -gt 0) {
        $newBashrc = $originalBashrc.TrimEnd() + "`n`n" + $beautifyConfig + "`n"
    } else {
        $newBashrc = $beautifyConfig + "`n"
    }
}

# 统一写入为 Unix 风格 LF 换行且无 BOM 的 UTF-8 文件
$newBashrc = $newBashrc.Replace("`r`n", "`n")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($bashrcPath, $newBashrc, $utf8NoBom)
Write-Host "[OK] 已更新 MSYS2 配置: $bashrcPath" -ForegroundColor Green

# 5. 注册 Windows Terminal MSYS2 配置文件 (若已安装 WT)
Write-Host "`n[3/3] 检查并注册 Windows Terminal MSYS2 终端配置..." -ForegroundColor Yellow
$wtStable = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$wtPreview = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'
foreach ($wtPath in @($wtStable, $wtPreview)) {
    if (Test-Path $wtPath) {
        try {
            $wtJson = Get-Content -LiteralPath $wtPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $hasMsys = $false
            if ($wtJson.profiles -and $wtJson.profiles.list) {
                foreach ($p in $wtJson.profiles.list) {
                    if ($p.name -like '*msys*' -or $p.commandline -like '*msys2_shell*') {
                        $hasMsys = $true
                        break
                    }
                }
                if (-not $hasMsys) {
                    $msysShellCmd = Join-Path $msys2Root 'msys2_shell.cmd'
                    $newProfile = [PSCustomObject]@{
                        guid = '{16d4cd58-c9b9-4c8f-8e9e-9b7c4d8f3e2a}'
                        name = 'MSYS2 UCRT64'
                        commandline = "$msysShellCmd -defterm -here -no-start -ucrt64"
                        startingDirectory = '%USERPROFILE%'
                        hidden = $false
                    }
                    $wtJson.profiles.list += $newProfile
                    $wtJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $wtPath -Encoding UTF8
                    Write-Host "[OK] 已在 Windows Terminal 中注册 MSYS2 终端配置项" -ForegroundColor Green
                } else {
                    Write-Host "[OK] Windows Terminal 已存在 MSYS2 终端配置项" -ForegroundColor DarkGray
                }
            }
        } catch {
            Write-Verbose "Windows Terminal 配置文件更新提示: $_"
        }
    }
}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "[OK] MSYS2 安装与美化配置完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "[提示] 您可以在 Windows Terminal 中打开 MSYS2 标签页体验全新的终端环境！" -ForegroundColor Cyan
