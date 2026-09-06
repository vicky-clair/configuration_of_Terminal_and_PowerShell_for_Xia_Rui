# windows终端美化相关


### 素材下载：
[https://github.com/viertelo/Ultimate-Win11-Setup](https://github.com/viertelo/Ultimate-Win11-Setup)

https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip

### 修改了Terminal背景和添加了多种终端支持：
```Plain Text
{
    "$help": "https://aka.ms/terminal-documentation",
    "$schema": "https://aka.ms/terminal-profiles-schema",
    "actions": 
    [
        {
            "command": 
            {
                "action": "copy",
                "singleLine": false
            },
            "id": "User.copy.644BA8F2"
        },
        {
            "command": "paste",
            "id": "User.paste"
        },
        {
            "command": "find",
            "id": "User.find"
        },
        {
            "command": 
            {
                "action": "splitPane",
                "split": "auto",
                "splitMode": "duplicate"
            },
            "id": "User.splitPane.A6751878"
        }
    ],
    "alwaysOnTop": false,
    "copyFormatting": "none",
    "copyOnSelect": false,
    "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
    "keybindings": 
    [
        {
            "id": "User.copy.644BA8F2",
            "keys": "ctrl+c"
        },
        {
            "id": "User.find",
            "keys": "ctrl+shift+f"
        },
        {
            "id": "User.paste",
            "keys": "ctrl+v"
        },
        {
            "id": "User.splitPane.A6751878",
            "keys": "alt+shift+d"
        }
    ],
    "newTabMenu": 
    [
        {
            "type": "remainingProfiles"
        }
    ],
    "profiles": 
    {
        "defaults":
        {
            "backgroundImage": "C:\\Users\\xasr2\\Pictures\\壁纸文件\\dde5a5767u6579.jpg",
            "backgroundImageOpacity": 0.4,
            "backgroundImageStretchMode": "uniformToFill",
            "colorScheme": "Catppuccin Mocha",
            "cursorShape": "filledBox",
            "experimental.retroTerminalEffect": false,
            "font":
            {
                "builtinGlyphs": true,
                "cellHeight": "1.2",
                "colorGlyphs": true,
                "face": "JetBrainsMono Nerd Font Mono",
                "size": 10,
                "weight": "extra-black"
            },
            "intenseTextStyle": "all",
            "opacity": 80,
            "padding": "8",
            "useAcrylic": true
        },
        "list": 
        [
            {
                "commandline": "%SystemRoot%\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
                "guid": "{61c54bbd-c2c6-5271-96e7-009a87ff44bf}",
                "hidden": false,
                "name": "Windows PowerShell"
            },
            {
                "commandline": "%SystemRoot%\\System32\\cmd.exe",
                "guid": "{0caa0dad-35be-5f56-a8ff-afceeeaa6101}",
                "hidden": false,
                "name": "Command Prompt"
            },
            {
                "guid": "{b453ae62-4e3d-5e58-b989-0a998ec441b8}",
                "hidden": false,
                "name": "Azure Cloud Shell",
                "source": "Windows.Terminal.Azure"
            },
            {
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "hidden": false,
                "name": "PowerShell",
                "source": "Windows.Terminal.PowershellCore"
            },
            {
                "guid": "{2595cd9c-8f05-55ff-a1d4-93f3041ca67f}",
                "hidden": false,
                "name": "PowerShell Preview (msix)",
                "source": "Windows.Terminal.PowershellCore"
            },
            {
                "guid": "{2ece5bfe-50ed-5f3a-ab87-5cd4baafed2b}",
                "hidden": false,
                "name": "Git Bash",
                "source": "Git"
            },
            {
                "guid": "{f4b2a9c1-5e44-5a2a-9d47-bcb9b6ec77c9}",
                "hidden": false,
                "name": "Ubuntu (WSL)",
                "source": "Windows.Terminal.Wsl"
            },
            {
                "guid": "{17da3cac-b318-431e-8a3e-7fcdefe6d114}",
                "hidden": false,
                "name": "MSYS2 MSYS",
                "commandline": "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -msys",
                "startingDirectory": "%USERPROFILE%",
                "icon": "C:\\msys64\\msys2.ico"
            },
            {
                "guid": "{71160544-14d8-4194-af25-d05feeac7233}",
                "hidden": false,
                "name": "MSYS2 MINGW64",
                "commandline": "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -mingw64",
                "startingDirectory": "%USERPROFILE%",
                "icon": "C:\\msys64\\mingw64.ico"
            },
            {
                "guid": "{2d51fdc4-a03b-4efe-81bc-722b7f6f3820}",
                "hidden": false,
                "name": "MSYS2 MINGW32",
                "commandline": "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -mingw32",
                "startingDirectory": "%USERPROFILE%",
                "icon": "C:\\msys64\\mingw32.ico"
            },
            {
                "guid": "{16d4cd58-c9b9-4c8f-8e9e-9b7c4d8f3e2a}",
                "hidden": false,
                "name": "MSYS2 UCRT64",
                "commandline": "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -ucrt64",
                "startingDirectory": "%USERPROFILE%",
                "icon": "C:\\msys64\\ucrt64.ico"
            },
            {
                "guid": "{5e3c2b8f-9d4e-4a7b-8c3d-1f2e3a4b5c6d}",
                "hidden": false,
                "name": "MSYS2 CLANG64",
                "commandline": "C:\\msys64\\msys2_shell.cmd -defterm -here -no-start -clang64",
                "startingDirectory": "%USERPROFILE%",
                "icon": "C:\\msys64\\clang64.ico"
            }
        ]
    },
    "schemes": 
    [
        {
            "background": "#1E1E2E",
            "black": "#45475A",
            "blue": "#89B4FA",
            "brightBlack": "#585B70",
            "brightBlue": "#89B4FA",
            "brightCyan": "#94E2D5",
            "brightGreen": "#A6E3A1",
            "brightPurple": "#F5C2E7",
            "brightRed": "#F38BA8",
            "brightWhite": "#A6ADC8",
            "brightYellow": "#F9E2AF",
            "cursorColor": "#F5E0DC",
            "cyan": "#94E2D5",
            "foreground": "#CDD6F4",
            "green": "#A6E3A1",
            "name": "Catppuccin Mocha",
            "purple": "#F5C2E7",
            "red": "#F38BA8",
            "selectionBackground": "#585B70",
            "white": "#BAC2DE",
            "yellow": "#F9E2AF"
        },
        {
            "background": "#000000",
            "black": "#0C0C0C",
            "blue": "#0037DA",
            "brightBlack": "#767676",
            "brightBlue": "#3B78FF",
            "brightCyan": "#61D6D6",
            "brightGreen": "#16C60C",
            "brightPurple": "#B4009E",
            "brightRed": "#E74856",
            "brightWhite": "#F2F2F2",
            "brightYellow": "#F9F1A5",
            "cursorColor": "#FFFFFF",
            "cyan": "#3A96DD",
            "foreground": "#FFFFFF",
            "green": "#13A10E",
            "name": "Color Scheme 15",
            "purple": "#881798",
            "red": "#C50F1F",
            "selectionBackground": "#FFFFFF",
            "white": "#CCCCCC",
            "yellow": "#C19C00"
        },
        {
            "background": "#282A36",
            "black": "#21222C",
            "blue": "#BD93F9",
            "brightBlack": "#6272A4",
            "brightBlue": "#D6ACFF",
            "brightCyan": "#A4FFFF",
            "brightGreen": "#69FF94",
            "brightPurple": "#FF92DF",
            "brightRed": "#FF6E6E",
            "brightWhite": "#FFFFFF",
            "brightYellow": "#FFFFA5",
            "cursorColor": "#F8F8F2",
            "cyan": "#8BE9FD",
            "foreground": "#F8F8F2",
            "green": "#50FA7B",
            "name": "Dracula",
            "purple": "#FF79C6",
            "red": "#FF5555",
            "selectionBackground": "#44475A",
            "white": "#F8F8F2",
            "yellow": "#F1FA8C"
        }
    ],
    "tabWidthMode": "titleLength",
    "themes": [],
    "useAcrylicInTabRow": true
}
```
### Microsoft.PowerShell\_profile.ps1美化版：
```Plain Text
# ===============================
# PowerShell 增强启动脚本（UTF-8 + vfox + Oh My Posh + Fastfetch + zoxide + PSReadLine增强版）
# ===============================

# Scoop 环境路径防丢失
$env:PATH += ";$env:USERPROFILE\scoop\shims"

# 启动 vfox 环境
Invoke-Expression "$(vfox activate pwsh)"

# 初始化 zoxide（智能 cd）
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
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

# Fastfetch 系统信息
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c "$env:USERPROFILE/.config/fastfetch/config.jsonc"
} else {
    Write-Host "⚠️  Fastfetch not found in PATH." -ForegroundColor Yellow
}

# Oh My Posh 随机主题
$themesPath = "$env:USERPROFILE/oh-my-posh-themes"
if (-not (Test-Path $themesPath)) { mkdir $themesPath | Out-Null }

if (-not (Test-Path "$themesPath/*.omp.json")) {
    try {
        $themesZip = "$themesPath/themes.zip"
        Invoke-WebRequest -Uri "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip" `
            -OutFile $themesZip -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Force $themesZip -DestinationPath $themesPath
        Remove-Item $themesZip -Force
    } catch {
        Write-Warning "⚠️ 无法下载最新 Oh My Posh 主题：$_"
    }
}

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $themes = Get-ChildItem $themesPath -Filter *.omp.json
    if ($themes.Count -gt 0) {
        $theme = $themes | Get-Random
        Write-Host "✨ 今日随机主题: $($theme.BaseName) ✨" -ForegroundColor Cyan
        oh-my-posh --init --shell pwsh --config $theme.FullName | Invoke-Expression
    }
}

# Terminal-Icons 模块
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# 常用命令别名
if (Test-Path Alias:dir) { Remove-Item Alias:dir -Force }
function dir { eza --icons --group-directories-first --color=always @args }
Set-Alias ls dir
Set-Alias cat bat
Set-Alias grep Select-String

# Git 常用别名
if (Get-Command git -ErrorAction SilentlyContinue) {
    Set-Alias g git
    function gst { git status }
    function gco { git checkout }
    function gb  { git branch }
    function gl  { git log --oneline --graph --all }
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
# 🧠 PSReadLine 增强配置（历史预测 + 去重 + 金黄配色 + 快捷键）
# =======================================================
Import-Module PSReadLine -ErrorAction SilentlyContinue

# 历史预测与界面风格
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# 键盘模式与体验增强
Set-PSReadLineOption -EditMode Windows          # 可改为 Emacs
Set-PSReadLineOption -HistoryNoDuplicates:$true # 去重历史
Set-PSReadLineOption -ShowToolTips:$true        # 显示提示信息
Set-PSReadLineOption -BellStyle None            # 禁用提示音

# 明亮金黄风格配色
Set-PSReadLineOption -Colors @{
    Command             = '#E5C07B'  # 金黄
    Parameter           = '#56B6C2'  # 青蓝
    Operator            = '#808080'  # 灰
    Number              = '#D19A66'  # 橙
    String              = '#98C379'  # 绿
    Variable            = '#61AFEF'  # 蓝
    Type                = '#C678DD'  # 紫
    Comment             = '#5C6370'  # 暗灰
    InlinePrediction    = '#4B5263'  # 深灰
    ContinuationPrompt  = '#E5C07B'  # 金黄
    Default             = '#FFFFFF'  # 白
}

# =============== zoxide + PSReadLine 快捷键增强 ===============
# Ctrl+Z：返回上一个目录
Set-PSReadLineKeyHandler -Chord "Ctrl+z" -BriefDescription "Zoxide back" -ScriptBlock {
    z -
}
# Alt+Z：打开 zoxide 交互式目录选择器
Set-PSReadLineKeyHandler -Chord "Alt+z" -BriefDescription "Zoxide interactive jump" -ScriptBlock {
    $dest = zoxide query -i
    if ($dest) { Set-Location $dest }
}
# ===========================================================


# PSFzf 快捷搜索
if (Get-Command Set-PsFzfOption -ErrorAction SilentlyContinue) {
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
}

# 彩色日志函数
function Log-Info($msg)  { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Log-Warn($msg)  { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Log-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# 启动提示符动画
function Show-AnimatedPrompt {
    $colors = [ConsoleColor]::GetValues([ConsoleColor])
    $text = "PS> "
    foreach ($c in $colors) {
        Write-Host $text -NoNewline -ForegroundColor $c
        Start-Sleep -Milliseconds 50
        Write-Host "`r" -NoNewline
    }
}
Show-AnimatedPrompt



```
你想把上面脚本中涉及的所有工具都 **用 Scoop 来统一安装和管理** —— 这是开发者最推荐的方案 ✅
Scoop 比 Winget 更干净、无 UAC、可版本控制、易更新。

---
## 🧩 一、前提：安装 Scoop
如果还没装 Scoop，在 PowerShell（管理员或用户模式都行）执行：

```Plain Text
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex

```
安装完成后，验证：

```Plain Text
scoop -v

```
若输出版本号 → 表示成功。

---
## 🧱 二、添加必要的仓库（bucket）
Scoop 默认只含 “main” 源，但某些工具（如 oh-my-posh、bat）在其它源中。

执行以下命令添加常用仓库：

```Plain Text
scoop bucket add main
scoop bucket add extras
scoop bucket add versions
scoop bucket add nerd-fonts

```
> 💡解释：

> * **main** → 常规命令行工具（git、python、eza 等）
> * **extras** → GUI / 高级工具（oh-my-posh 等）
> * **versions** → 各版本管理器（PowerShell、NodeJS）
> * **nerd-fonts** → 含 Nerd Font 字体库（图标支持）

---
## 🧰 三、使用 Scoop 安装脚本所需全部工具
直接执行以下命令即可一键安装：

```Plain Text
# 🧠 环境管理器 vfox
scoop install vfox

# ⚙️ 系统信息显示 Fastfetch
scoop install fastfetch

# 🎨 美化提示符 Oh My Posh
scoop install oh-my-posh

# 🦋 彩色目录工具 eza
scoop install eza

# 🪶 高亮文件输出 bat
scoop install bat

# 🧩 Git 版本控制
scoop install git

# 🧰 PowerShell 7（最新版本）
scoop install pwsh

# 把这些也安装一下方便后续安装yazi
scoop install ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
scoop install curl
scoop install sudo
scoop install jq

```
---
## 🧩 四、安装 PowerShell 模块（非 Scoop 管理）
Scoop 管理的是 CLI 工具，PowerShell 模块则用 PowerShell 内置命令安装：

```Plain Text
Install-Module Terminal-Icons -Scope CurrentUser -Force
Install-Module PSFzf -Scope CurrentUser -Force
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
```
---
## 🎨 五、安装字体（让图标显示正常）
安装 Nerd Font 字体（推荐 JetBrainsMono）：

```Plain Text
scoop install JetBrainsMono-NF

```
安装后：

1. 打开 **Windows Terminal → 设置 → 外观 → 字体**；
2. 选择：

```Plain Text
JetBrainsMono Nerd Font Mono

```
这样 Oh My Posh 和 eza 图标才会显示完整。

---
## 🔁 六、统一更新与管理命令
更新所有工具：

```Plain Text
scoop update *

```
清理旧版本：

```Plain Text
scoop cleanup *

```
卸载工具：

```Plain Text
scoop uninstall <包名>

```
查看已安装的工具：

```Plain Text
scoop list

```
---
## 🧭 七、验证安装成功
执行以下命令：

```Plain Text
vfox --version
fastfetch --version
oh-my-posh --version
eza --version
bat --version
git --version
pwsh --version

```
全部能输出版本号 → ✅ 环境完全配置成功。

---
## 🧠 八、Scoop 管理结构概览
默认路径：

```Plain Text
C:\Users\<用户名>\scoop\
├─ apps\
│  ├─ git\
│  ├─ fastfetch\
│  ├─ oh-my-posh\
│  ├─ eza\
│  ├─ bat\
│  ├─ pwsh\
│  └─ vfox\
└─ shims\
    ├─ git.exe
    ├─ eza.exe
    ├─ fastfetch.exe
    └─ ...

```
Scoop 会自动将 `C:\Users\<用户名>\scoop\shims` 添加到 PATH，
所以这些命令可以在 PowerShell 任意目录直接用。

---
## ✅ 九、总结一览表（Scoop 版本）
|工具 / 模块|作用|安装命令|
| ----- | ----- | ----- |
|🧠 vfox|环境版本管理器|scoop install vfox|
|⚙️ Fastfetch|系统信息显示|scoop install fastfetch|
|🎨 Oh My Posh|终端提示符美化|scoop install oh-my-posh|
|🗂️ Terminal-Icons|文件夹图标|Install-Module Terminal-Icons -Scope CurrentUser|
|📚 PSReadLine|智能补全（自带）|无需安装|
|🔍 PSFzf|快速搜索|Install-Module PSFzf -Scope CurrentUser|
|🦋 eza|现代 ls 替代|scoop install eza|
|🪶 bat|高亮 cat 替代|scoop install bat|
|🧩 git|版本控制工具|scoop install git|
|🧰 PowerShell 7|最新 PowerShell|scoop install pwsh|
|🔤 JetBrainsMono Nerd Font|图标字体|scoop install JetBrainsMono-NF|

