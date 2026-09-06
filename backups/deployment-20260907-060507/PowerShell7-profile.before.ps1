# ===============================
# PowerShell 增强启动脚本（UTF-8 + vfox + Oh My Posh + Fastfetch + zoxide + PSReadLine增强）
# 作者：开发者配置
# 版本：2.1（性能优化版 - PowerShell 7+）
# ===============================

# =======================================================
# 🚀 性能优化：工具检测缓存函数
# =======================================================
$script:ToolCache = @{}
function Test-Tool {
    param([string]$CommandName)

    if (-not $script:ToolCache.ContainsKey($CommandName)) {
        $script:ToolCache[$CommandName] = [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
    }
    return $script:ToolCache[$CommandName]
}

# Scoop 环境路径防丢失
if ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\scoop\shims")) {
    $scoopShims = "$env:USERPROFILE\scoop\shims"
    if ($env:PATH -notlike "*$scoopShims*") {
        $env:PATH += ";$scoopShims"
    }
}

# 启动 vfox 环境（带错误处理）
if (Test-Tool "vfox") {
    try {
        Invoke-Expression "$(vfox activate pwsh)"
    } catch {
        Write-Warning "⚠️ vfox 激活失败: $_"
    }
}

# 初始化 zoxide（智能 cd）
if (Test-Tool "zoxide") {
    try {
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Warning "⚠️ zoxide 初始化失败: $_"
    }
}

# 全局 UTF-8 编码支持
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# 清屏
Clear-Host

# Fastfetch 系统信息（带配置文件检查 + 美化输出）
if (Test-Tool "fastfetch") {
    Write-Host "`n🧠 系统加载信息 ---------------------`n" -ForegroundColor Cyan
    $fastfetchConfig = "$env:USERPROFILE/.config/fastfetch/config.jsonc"
    if (Test-Path $fastfetchConfig) {
        fastfetch -c $fastfetchConfig 2>$null
    } else {
        fastfetch 2>$null
    }
    Write-Host ""
}

# Oh My Posh 随机主题（优化版 - PowerShell 7+）
if (Test-Tool "oh-my-posh") {
    $themesPath = "$env:USERPROFILE/oh-my-posh-themes"

    # 确保主题目录存在
    if (-not (Test-Path $themesPath)) {
        New-Item -ItemType Directory -Path $themesPath -Force | Out-Null
    }

    # 检查是否有主题文件（修复通配符问题）
    $existingThemes = Get-ChildItem -Path $themesPath -Filter "*.omp.json" -ErrorAction SilentlyContinue

    if ($existingThemes.Count -eq 0) {
        Write-Host "📥 首次运行，正在下载 Oh My Posh 主题..." -ForegroundColor Yellow
        try {
            $themesZip = "$themesPath/themes.zip"
            # PowerShell 7+ 不需要 -UseBasicParsing
            Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" `
                -OutFile $themesZip -TimeoutSec 10 -ErrorAction Stop
            Expand-Archive -Force $themesZip -DestinationPath $themesPath
            Remove-Item $themesZip -Force
            $existingThemes = Get-ChildItem -Path $themesPath -Filter "*.omp.json"
            Write-Host "✅ 主题下载成功！" -ForegroundColor Green
        } catch {
            Write-Warning "⚠️ 无法下载 Oh My Posh 主题：$($_.Exception.Message)"
            Write-Host "💡 提示：您可以手动下载主题：" -ForegroundColor Yellow
            Write-Host "   1. 访问：https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest" -ForegroundColor Gray
            Write-Host "   2. 下载 themes.zip 并解压到：$themesPath" -ForegroundColor Gray
        }
    }

    # 应用随机主题
    if ($existingThemes.Count -gt 0) {
        $theme = $existingThemes | Get-Random
        Write-Host "✨ 今日随机主题: $($theme.BaseName) ✨" -ForegroundColor Cyan
        try {
            oh-my-posh init pwsh --config $theme.FullName | Invoke-Expression
        } catch {
            Write-Warning "⚠️ Oh My Posh 初始化失败: $_"
        }
    }
}

# Terminal-Icons 模块
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# 常用命令别名（带工具检查）
if (Test-Tool "eza") {
    if (Test-Path Alias:dir) { Remove-Item Alias:dir -Force }
    function dir { eza --icons --group-directories-first --color=always @args }
    Set-Alias -Name ls -Value dir -Option AllScope -Force
} else {
    # 如果 eza 不存在，使用增强的 Get-ChildItem
    function dir { Get-ChildItem -Force @args }
    Set-Alias -Name ls -Value dir -Option AllScope -Force
}

if (Test-Tool "bat") {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

Set-Alias -Name grep -Value Select-String -Option AllScope -Force

# Git 常用别名
if (Test-Tool "git") {
    Set-Alias -Name g -Value git -Option AllScope -Force
    function gst { git status @args }
    function gco { git checkout @args }
    function gb  { git branch @args }
    function gl  { git log --oneline --graph --all @args }
    function gp  { git pull @args }
    function gps { git push @args }
}

# 中文随机欢迎语
$chineseQuotes = @(
    "今天又是充满干劲的一天！",
    "学习使人进步，代码让人快乐。",
    "每一次提交都是一次成长。",
    "别忘了喝水，保持专注！",
    "BUG 是程序员的朋友，别害怕它。",
    "早起的鸟儿有虫吃，早写的代码有快感。",
    "保持微笑，代码会更流畅。",
    "今天也要写出漂亮的函数！"
)
Write-Host ("💡 " + ($chineseQuotes | Get-Random)) -ForegroundColor Yellow


# =======================================================
# 🧠 PSReadLine 增强配置（历史预测 + 去重 + 金黄配色）
# PowerShell 7+ 优化：使用 HistoryAndPlugin 支持智能补全
# =======================================================
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine -ErrorAction SilentlyContinue

    try {
        # PowerShell 7+ 推荐使用 HistoryAndPlugin（支持 Azure、Git 等插件补全）
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView
        Set-PSReadLineOption -EditMode Windows
        Set-PSReadLineOption -HistoryNoDuplicates:$true
        Set-PSReadLineOption -ShowToolTips:$true
        Set-PSReadLineOption -BellStyle None
        Set-PSReadLineOption -Colors @{
            Command             = '#E5C07B'
            Parameter           = '#56B6C2'
            Operator            = '#808080'
            Number              = '#D19A66'
            String              = '#98C379'
            Variable            = '#61AFEF'
            Type                = '#C678DD'
            Comment             = '#5C6370'
            InlinePrediction    = '#4B5263'
            ContinuationPrompt  = '#E5C07B'
            Default             = '#FFFFFF'
        }
    } catch {
        Write-Warning "⚠️ PSReadLine 配置失败: $_"
    }
}


# =============== zoxide + PSReadLine 快捷键增强（修复版 - 更通用）===============
if ((Test-Tool "zoxide") -and (Get-Module PSReadLine)) {
    # Ctrl+B：返回上一个目录（避免与 Ctrl+Z 冲突）
    Set-PSReadLineKeyHandler -Chord "Ctrl+b" -BriefDescription "Zoxide back" -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('z -')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }

    # Alt+Z：打开 zoxide 交互式目录选择器（使用完整命令，更通用）
    Set-PSReadLineKeyHandler -Chord "Alt+z" -BriefDescription "Zoxide interactive jump" -ScriptBlock {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('zoxide query -i | ForEach-Object { Set-Location $_ }')
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
    }
}
# ===========================================================

# =======================================================
# 🔍 PSFzf 快捷搜索增强
# =======================================================
if (Get-Module -ListAvailable -Name PSFzf) {
    try {
        Import-Module PSFzf -ErrorAction SilentlyContinue
        if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
            Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
        }
    } catch {
        Write-Warning "⚠️ PSFzf 配置失败: $_"
    }
}


# =======================================================
# 🪶 彩色日志函数（使用标准动词 + 时间戳）
# =======================================================
function Write-InfoLog {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [INFO]  $Message" -ForegroundColor Cyan
}

function Write-WarnLog {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [WARN]  $Message" -ForegroundColor Yellow
}

function Write-ErrorLog {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [ERROR] $Message" -ForegroundColor Red
}


# =======================================================
# 🛠️ 实用工具函数
# =======================================================

# 快速创建目录并进入
function mkcd {
    param([string]$Path)
    if ($Path) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Set-Location $Path
        Write-Host "✅ 已创建并进入目录: $Path" -ForegroundColor Green
    }
}

# 查找大文件
function Find-LargeFiles {
    param(
        [string]$Path = ".",
        [int]$TopN = 10
    )
    Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending |
        Select-Object -First $TopN |
        Format-Table Name, @{Label="Size(MB)"; Expression={[math]::Round($_.Length/1MB, 2)}} -AutoSize
}

# 快速编辑 PowerShell 配置文件
function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $PROFILE
    } elseif (Get-Command notepad++ -ErrorAction SilentlyContinue) {
        notepad++ $PROFILE
    } else {
        notepad $PROFILE
    }
}

# 重新加载配置文件
function Update-Profile {
    try {
        . $PROFILE
        Write-Host "✅ PowerShell 配置已重新加载" -ForegroundColor Green
    } catch {
        Write-Host "❌ 配置文件加载失败: $_" -ForegroundColor Red
    }
}

# 显示系统信息摘要
function Get-SystemInfo {
    Write-Host "`n=== 系统信息 ===" -ForegroundColor Cyan
    Write-Host "计算机名: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "用户名: $env:USERNAME" -ForegroundColor Yellow
    Write-Host "PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "操作系统: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Yellow
    Write-Host "当前目录: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "===============`n" -ForegroundColor Cyan
}

# 快速测试网络连接
function Test-Internet {
    param([string]$Target = "8.8.8.8")
    if (Test-Connection -ComputerName $Target -Count 2 -Quiet) {
        Write-Host "✅ 网络连接正常" -ForegroundColor Green
    } else {
        Write-Host "❌ 网络连接失败" -ForegroundColor Red
    }
}

# =======================================================
# 🔍 环境自检函数（一键检查所有工具）
# =======================================================
function Test-Environment {
    Write-Host "`n🔍 检查 PowerShell 环境配置" -ForegroundColor Cyan
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

    $tools = @(
        @{Name="PowerShell 7+"; Command="pwsh"; Required=$true},
        @{Name="Git"; Command="git"; Required=$true},
        @{Name="Oh My Posh"; Command="oh-my-posh"; Required=$false},
        @{Name="Fastfetch"; Command="fastfetch"; Required=$false},
        @{Name="Zoxide"; Command="zoxide"; Required=$false},
        @{Name="Eza"; Command="eza"; Required=$false},
        @{Name="Bat"; Command="bat"; Required=$false},
        @{Name="Fzf"; Command="fzf"; Required=$false},
        @{Name="Vfox"; Command="vfox"; Required=$false}
    )

    $modules = @(
        @{Name="PSReadLine"; Required=$true},
        @{Name="Terminal-Icons"; Required=$false},
        @{Name="PSFzf"; Required=$false}
    )

    Write-Host "`n📦 命令行工具：" -ForegroundColor Yellow
    foreach ($tool in $tools) {
        $installed = Test-Tool $tool.Command
        $status = if ($installed) { "✅" } else { "❌" }
        $color = if ($installed) { "Green" } else { if ($tool.Required) { "Red" } else { "Gray" } }
        $required = if ($tool.Required) { "[必需]" } else { "[可选]" }

        Write-Host "  $status $($tool.Name.PadRight(15)) $required" -ForegroundColor $color
    }

    Write-Host "`n📚 PowerShell 模块：" -ForegroundColor Yellow
    foreach ($module in $modules) {
        $installed = Get-Module -ListAvailable -Name $module.Name
        $status = if ($installed) { "✅" } else { "❌" }
        $color = if ($installed) { "Green" } else { if ($module.Required) { "Red" } else { "Gray" } }
        $required = if ($module.Required) { "[必需]" } else { "[可选]" }

        Write-Host "  $status $($module.Name.PadRight(15)) $required" -ForegroundColor $color
    }

    Write-Host "`n💡 提示：" -ForegroundColor Cyan
    Write-Host "  - 使用 'scoop install <工具名>' 安装命令行工具" -ForegroundColor Gray
    Write-Host "  - 使用 'Install-Module <模块名>' 安装 PowerShell 模块" -ForegroundColor Gray
    Write-Host "  - 查看完整文档：PowerShell配置文档.md`n" -ForegroundColor Gray
}
