# PowerShell 7 recommended; Windows PowerShell 5.1 supported with reduced features.
# Dot-source this file from $PROFILE. No downloads or package installs at startup.

# Scoop normally manages PATH itself. Repair a missing entry without duplicating it.
$profileScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { Join-Path $env:USERPROFILE 'scoop' }
$profileShims = Join-Path $profileScoopRoot 'shims'
$profilePathEntries = @($env:PATH -split ';' | ForEach-Object { $_.Trim().TrimEnd('\', '/') })
if ((Test-Path -LiteralPath $profileShims -PathType Container) -and
    $profilePathEntries -notcontains $profileShims.TrimEnd('\', '/')) {
    $env:PATH = if ($env:PATH) { "$env:PATH;$profileShims" } else { $profileShims }
}

# Match native command input/output without spawning chcp.exe.
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::InputEncoding = $OutputEncoding
    [Console]::OutputEncoding = $OutputEncoding
} catch {
    Write-Verbose "Console encoding unavailable in this host: $_"
}

# Keep dir/ls/cat as PowerShell object-producing commands. Use ll/la/lt/lg/catc for display.
function ll {
    if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
        eza --long --icons=auto --group-directories-first --color=auto @args
    } else { Get-ChildItem @args }
}
function la {
    if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
        eza --long --all --icons=auto --group-directories-first --color=auto @args
    } else { Get-ChildItem -Force @args }
}
function lt {
    if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
        eza --tree --level=2 --icons=auto --group-directories-first --color=auto @args
    } else { Get-ChildItem -Recurse -Depth 2 @args }
}
function lt3 {
    if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
        eza --tree --level=3 --icons=auto --group-directories-first --color=auto @args
    } else { Get-ChildItem -Recurse -Depth 3 @args }
}
function lg {
    if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
        eza --long --git --icons=auto --group-directories-first --color=auto @args
    } else { Get-ChildItem @args }
}
function catc {
    if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
        bat --paging=never @args
    } else { Get-Content @args }
}

# Quick directory upward navigation
function ..   { Set-Location .. }
function ...  { Set-Location ../.. }
function .... { Set-Location ../../.. }

if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    Set-Alias g git
    function gst { git status @args }
    function gco { git checkout @args }
    function gb  { git branch @args }
    # gl is the built-in Get-Location alias and would shadow a function named gl.
    function glog { git log --oneline --graph --all @args }
}
Set-Alias grep Select-String

# Yazi file manager integration with automatic directory changing upon exit
if (Get-Command yazi -CommandType Application -ErrorAction SilentlyContinue) {
    function y {
        $tmp = [System.IO.Path]::GetTempFileName()
        & yazi @args --cwd-file="$tmp"
        if (Test-Path $tmp) {
            $cwd = (Get-Content -Path $tmp -ErrorAction SilentlyContinue | Out-String).Trim()
            if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path -and (Test-Path $cwd)) {
                Set-Location -- $cwd
            }
            Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue
        }
    }
}

# Lazydocker alias
if (Get-Command lazydocker -CommandType Application -ErrorAction SilentlyContinue) {
    Set-Alias lzd lazydocker
}

# Neovim as default editor & quick aliases
if (Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'nvim'
    $env:VISUAL = 'nvim'
    function v { & nvim @args }
}

# Zoxide interactive query alias
function zi {
    if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
        $dest = & zoxide query -i @args
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($dest) -and (Test-Path -LiteralPath $dest)) {
            Set-Location -LiteralPath $dest
        }
    } else {
        Write-Warning "zoxide 未安装，请运行: scoop install zoxide"
    }
}

# Fuzzy Find & Edit file with Neovim and bat preview
function fv {
    if (-not (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf 未安装，无法执行模糊选文件。请运行: scoop install fzf"
        return
    }
    $previewCmd = if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
        'bat --style=numbers --color=always --line-range :500 {}'
    } else {
        'type {}'
    }
    $fzfArgs = @(
        '--height=80%',
        '--layout=reverse',
        '--border=rounded',
        "--preview=$previewCmd",
        '--preview-window=right:60%:wrap'
    )
    $file = & fzf @fzfArgs
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($file) -and (Test-Path -LiteralPath $file)) {
        if (Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) {
            & nvim $file
        } elseif (Get-Command code -CommandType Application -ErrorAction SilentlyContinue) {
            & code $file
        } else {
            notepad $file
        }
    }
}

# Find In Files (ripgrep + fzf + bat + nvim interactive full-text search)
function fif {
    param([string]$Query = '')
    if (-not (Get-Command rg -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Warning "ripgrep (rg) 未安装，无法执行全文代码检索。请运行: scoop install ripgrep"
        return
    }
    if (-not (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)) {
        Write-Warning "fzf 未安装，无法执行交互式检索。请运行: scoop install fzf"
        return
    }
    $hasBat = [bool](Get-Command bat -CommandType Application -ErrorAction SilentlyContinue)
    $previewCmd = if ($hasBat) {
        'bat --style=numbers --color=always --highlight-line {2} {1}'
    } else {
        'type {1}'
    }
    $fzfArgs = @(
        '--ansi',
        '--delimiter=:',
        '--prompt=fif> ',
        '--layout=reverse',
        '--border=rounded',
        "--preview=$previewCmd",
        '--preview-window=right:60%:+{2}-5'
    )
    $rgArgs = @('--column', '--line-number', '--no-heading', '--color=always', '--smart-case')
    $rgOutput = if ($Query) {
        & rg @rgArgs -- $Query
    } else {
        & rg @rgArgs .
    }
    $selected = $rgOutput | & fzf @fzfArgs
    if ($selected) {
        $parts = $selected -split ':'
        $file = $parts[0]
        $line = if ($parts.Count -gt 1) { $parts[1] } else { '1' }
        if (Test-Path -LiteralPath $file) {
            if (Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) {
                & nvim "+$line" $file
            } elseif (Get-Command code -CommandType Application -ErrorAction SilentlyContinue) {
                & code --goto "${file}:${line}"
            } else {
                notepad $file
            }
        }
    }
}

# Integrate fd and Catppuccin Mocha theme with live bat/eza preview into FZF
if (Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git --exclude node_modules --exclude .venv'
    $env:FZF_ALT_C_COMMAND = 'fd --type d --hidden --exclude .git --exclude node_modules --exclude .venv'
}

$fzfColors = '--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 ' +
             '--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc ' +
             '--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 ' +
             '--color=selected-bg:#45475a'

$fzfPreview = ''
if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
    $fzfPreview = '--preview "bat --style=numbers --color=always --line-range :500 {}" --preview-window "right:60%:wrap"'
}
$env:FZF_DEFAULT_OPTS = "$fzfColors --border=rounded --info=inline --height=80% --layout=reverse --multi $fzfPreview".Trim()

if (Get-Command eza -CommandType Application -ErrorAction SilentlyContinue) {
    $env:FZF_ALT_C_OPTS = "$fzfColors --border=rounded --info=inline --height=80% --layout=reverse --preview 'eza --tree --level=2 --color=always --icons=always {}' --preview-window 'right:60%:wrap'"
}

function Log-Info($msg)  { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Log-Warn($msg)  { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Log-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Show-SystemInfo {
    if ($env:POWERSHELL_PROFILE_MINIMAL -eq '1' -or $env:POWERSHELL_PROFILE_BANNER -eq '0') { return }
    if (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue) {
        $configFile = Join-Path $env:USERPROFILE '.config\fastfetch\config.jsonc'
        if (Test-Path -LiteralPath $configFile -PathType Leaf) {
            fastfetch -c $configFile @args
        } else { fastfetch @args }
    } else { Write-Warning 'Fastfetch is not installed. Run: scoop install fastfetch' }
}

# Helper functions for CJK-aware width formatting
function Get-DisplayWidth([string]$text) {
    $width = 0
    foreach ($ch in $text.ToCharArray()) {
        $code = [int]$ch
        if (($code -ge 0x2E80 -and $code -le 0x9FFF) -or
            ($code -ge 0xF900 -and $code -le 0xFAFF) -or
            ($code -ge 0xFF01 -and $code -le 0xFF60)) {
            $width += 2
        } else {
            $width += 1
        }
    }
    return $width
}

function Pad-DisplayRight([string]$text, [int]$totalWidth) {
    $currentWidth = Get-DisplayWidth $text
    if ($currentWidth -ge $totalWidth) { return $text }
    return $text + (' ' * ($totalWidth - $currentWidth))
}

# Feature status card: displays active CLI tool integrations with real checks and warnings
# Set $env:POWERSHELL_PROFILE_TIPS = '0' to disable.
function Show-FeatureTips {
    if ($env:POWERSHELL_PROFILE_MINIMAL -eq '1' -or $env:POWERSHELL_PROFILE_BANNER -eq '0' -or $env:POWERSHELL_PROFILE_TIPS -eq '0') { return }

    $features = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    # 1. Yazi
    if (Get-Command yazi -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add('yazi 目录穿梭 (y [path])')
    } else {
        $warnings.Add('yazi 文件管理器未就绪 (缺少 yazi: 请运行 scoop install yazi)')
    }

    # 2. fd
    if ((Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) -and ($env:FZF_DEFAULT_COMMAND -like '*fd*')) {
        $features.Add('fd 极速索引引擎 (FZF加速)')
    } else {
        $warnings.Add('fd 索引引擎未就绪 (缺少 fd: 请运行 scoop install fd)')
    }

    # 3. bat + eza preview
    $hasBat = [bool](Get-Command bat -CommandType Application -ErrorAction SilentlyContinue)
    $hasEza = [bool](Get-Command eza -CommandType Application -ErrorAction SilentlyContinue)
    if ($hasBat -and $hasEza -and ($env:FZF_DEFAULT_OPTS -like '*--preview*')) {
        $features.Add('bat+eza 画中画实时预览')
    } else {
        $missing = @()
        if (-not $hasBat) { $missing += 'bat' }
        if (-not $hasEza) { $missing += 'eza' }
        $warnings.Add("FZF 画中画预览已降级 (缺少 $($missing -join ', '): 建议运行 scoop install $($missing -join ' '))")
    }

    # 4. fzf & PSFzf
    $hasFzf = [bool](Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)
    $hasPsFzf = [bool](Get-Module PSFzf) -or [bool](Get-Module -ListAvailable PSFzf)
    if ($hasFzf -and $hasPsFzf) {
        $features.Add('fzf 模糊搜索 (Ctrl+R/F/Alt+Z)')
    } elseif ($hasFzf) {
        $features.Add('fzf 基础模糊查找 (CLI模式)')
        $warnings.Add('PSFzf 快捷键未加载 (缺少模块: 请运行 Install-Module PSFzf)')
    } else {
        $warnings.Add('fzf 模糊检索未就绪 (缺少 fzf: 请运行 scoop install fzf)')
    }

    # 5. eza
    if ($hasEza) {
        $features.Add('eza 现代文件列表 (ll/la/lt/lg)')
    } else {
        $warnings.Add('eza 现代化 ls 未启用 (缺少 eza: 请运行 scoop install eza)')
    }

    # 6. lazydocker
    if (Get-Command lazydocker -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add('lazydocker 容器管家 (lzd)')
    } else {
        $warnings.Add('lazydocker 未安装 (缺少 lazydocker: 请运行 scoop install lazydocker)')
    }

    # 7. Neovim
    if ((Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) -and ($env:EDITOR -eq 'nvim')) {
        $features.Add('Neovim 默认编辑器 (v/fv)')
    } else {
        $warnings.Add('Neovim 未就绪 (建议运行: scoop install neovim)')
    }

    # 8. zoxide
    $hasZoxide = [bool](Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue)
    $zoxideHooked = $profileZoxideReady -or $script:profileZoxideReady -or [bool](Get-Command __zoxide_z -ErrorAction SilentlyContinue)
    if ($hasZoxide -and $zoxideHooked) {
        $features.Add('zoxide 智能目录快跳 (z/zi)')
    } elseif ($hasZoxide) {
        $features.Add('zoxide 智能跳转 (CLI模式就绪)')
    } else {
        $warnings.Add('zoxide 智能跳转未生效 (缺少 zoxide: 请运行 scoop install zoxide)')
    }

    # 9. fif (Find in files)
    $hasRg = [bool](Get-Command rg -CommandType Application -ErrorAction SilentlyContinue)
    if ($hasRg -and $hasFzf -and $hasBat) {
        $features.Add('fif 全文代码检索 (fif <词>)')
    } else {
        $missing = @()
        if (-not $hasRg) { $missing += 'ripgrep' }
        if (-not $hasFzf) { $missing += 'fzf' }
        if (-not $hasBat) { $missing += 'bat' }
        $warnings.Add("fif 全文检索未就绪 (缺少 $($missing -join ', '): 建议运行 scoop install $($missing -join ' '))")
    }

    # 10. Fastfetch
    if (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add('fastfetch 动漫硬件看板')
    } else {
        $warnings.Add('fastfetch 硬件面板未就绪 (缺少 fastfetch: 请运行 scoop install fastfetch)')
    }

    if ($global:VFOX_SKIPPED) {
        $warnings.Add('vfox 版本管理初始化失败或超时，本次已跳过')
    }

    $winWidth = 100
    try { $winWidth = $Host.UI.RawUI.WindowSize.Width } catch {}

    if ($winWidth -lt 82) {
        foreach ($f in $features) {
            Write-Host "  ✓ $f" -ForegroundColor Green
        }
        foreach ($w in $warnings) {
            Write-Host "  ✗ $w" -ForegroundColor Yellow
        }
        Write-Host ""
        return
    }

    Write-Host "┌─ 🚀 终端现代化生产力就绪看板 ────────────────────────────────────────────────────────┐" -ForegroundColor DarkCyan
    for ($i = 0; $i -lt $features.Count; $i += 2) {
        $item1 = $features[$i]
        $item2 = if ($i + 1 -lt $features.Count) { $features[$i + 1] } else { '' }

        Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
        Write-Host "✓ " -NoNewline -ForegroundColor Green
        Write-Host (Pad-DisplayRight $item1 36) -NoNewline -ForegroundColor White
        Write-Host " " -NoNewline

        if ($item2) {
            Write-Host "✓ " -NoNewline -ForegroundColor Green
            Write-Host (Pad-DisplayRight $item2 36) -NoNewline -ForegroundColor White
        } else {
            Write-Host (' ' * 38) -NoNewline
        }
        Write-Host " │" -ForegroundColor DarkCyan
    }

    if ($warnings.Count -gt 0) {
        Write-Host "├───────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkYellow
        foreach ($w in $warnings) {
            Write-Host "│ " -NoNewline -ForegroundColor DarkYellow
            Write-Host "✗ " -NoNewline -ForegroundColor Yellow
            Write-Host (Pad-DisplayRight $w 74) -NoNewline -ForegroundColor Yellow
            Write-Host " │" -ForegroundColor DarkYellow
        }
    }

    Write-Host "├───────────────────────────────────────────────────────────────────────────────────────┤" -ForegroundColor DarkCyan
    $footer = "⚡ 快捷操作: [Ctrl+R] 历史搜 | [Alt+Z/zi] 目录跳 | [Ctrl+F] 文件填 | [fv] 模糊编辑 | [fif] 全文搜"
    Write-Host "│ " -NoNewline -ForegroundColor DarkCyan
    Write-Host (Pad-DisplayRight $footer 76) -NoNewline -ForegroundColor DarkGray
    Write-Host " │" -ForegroundColor DarkCyan
    Write-Host "└───────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

# Preserved from the active profile during deployment.
function Test-Tool { param([string]$CommandName) [bool](Get-Command $CommandName -ErrorAction SilentlyContinue) }
function gpull { git pull @args }

function gps { git push @args }

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

function mkcd {
    param([string]$Path)
    if ($Path) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Set-Location $Path
        Write-Host "✅ 已创建并进入目录: $Path" -ForegroundColor Green
    }
}

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

function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code $PROFILE
    } elseif (Get-Command notepad++ -ErrorAction SilentlyContinue) {
        notepad++ $PROFILE
    } else {
        notepad $PROFILE
    }
}

function Update-Profile {
    try {
        . $PROFILE
        Write-Host "✅ PowerShell 配置已重新加载" -ForegroundColor Green
    } catch {
        Write-Host "❌ 配置文件加载失败: $_" -ForegroundColor Red
    }
}

function Get-SystemInfo {
    Write-Host "`n=== 系统信息 ===" -ForegroundColor Cyan
    Write-Host "计算机名: $env:COMPUTERNAME" -ForegroundColor Yellow
    Write-Host "用户名: $env:USERNAME" -ForegroundColor Yellow
    Write-Host "PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "操作系统: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Yellow
    Write-Host "当前目录: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "===============`n" -ForegroundColor Cyan
}

function Test-Internet {
    param([string]$Target = "8.8.8.8")
    if (Test-Connection -ComputerName $Target -Count 2 -Quiet) {
        Write-Host "✅ 网络连接正常" -ForegroundColor Green
    } else {
        Write-Host "❌ 网络连接失败" -ForegroundColor Red
    }
}

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

# Redirected jobs and -NonInteractive sessions should not load prompt/UI integrations.
$profileInteractive = $Host.Name -eq 'ConsoleHost' -and $env:TERM -ne 'dumb'
try {
    $profileInteractive = $profileInteractive -and
        -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected
} catch { $profileInteractive = $false }
if ([Environment]::GetCommandLineArgs() | Where-Object {
    $_ -like '-noni*' -and '-NonInteractive'.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase)
}) {
    $profileInteractive = $false
}
if ($env:POWERSHELL_PROFILE_MINIMAL -eq '1' -or -not $profileInteractive) { return }

# Local init output is evaluated in the profile scope so generated functions survive.
if ($env:POWERSHELL_PROFILE_VFOX -ne '0' -and
    (Get-Command vfox -CommandType Application -ErrorAction SilentlyContinue)) {
    try {
        $profileInit = (& vfox activate pwsh | Out-String)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($profileInit)) {
            Invoke-Expression $profileInit
        } else { Write-Warning 'vfox initialization failed.' }
    } catch { Write-Warning "vfox: $_" }
}

# Prompt Theme Initialization: supports Fixed (Catppuccin Mocha), Random, or Starship.
if ($env:POWERSHELL_THEME_MODE -eq 'starship' -or $env:POWERSHELL_POSH_THEME -eq 'starship') {
    if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
        Invoke-Expression (&starship init powershell)
    }
} elseif (Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) {
    $profileTheme = $null
    $profileThemeCandidates = @()
    $isRandom = ($env:POWERSHELL_THEME_MODE -eq 'random' -or $env:POWERSHELL_POSH_THEME -eq 'random' -or (-not $env:POWERSHELL_THEME_MODE -and -not $env:POWERSHELL_POSH_THEME))
    if ($isRandom) {
        $themesDir = Join-Path $env:USERPROFILE 'oh-my-posh-themes'
        if (-not (Test-Path $themesDir) -and $env:POSH_THEMES_PATH) { $themesDir = $env:POSH_THEMES_PATH }
        if (Test-Path $themesDir) {
            $randomThemes = @(Get-ChildItem -LiteralPath $themesDir -Filter '*.omp.json' -ErrorAction SilentlyContinue)
            if ($randomThemes.Count -gt 0) {
                $chosen = $randomThemes | Get-Random
                $profileTheme = $chosen.FullName
                $displayTheme = $chosen.BaseName -replace '\.omp$', ''
                Write-Host "✨ 今日随机主题: $displayTheme ✨" -ForegroundColor Cyan
            }
        }
    } elseif ($env:POWERSHELL_POSH_THEME -and $env:POWERSHELL_POSH_THEME -ne 'random') {
        $profileThemeCandidates += $env:POWERSHELL_POSH_THEME
    } else {
        # Prefer Catppuccin Mocha to match Windows Terminal color scheme
        $profileThemeCandidates += Join-Path $env:USERPROFILE 'oh-my-posh-themes\catppuccin_mocha.omp.json'
        if ($env:POSH_THEMES_PATH) {
            $profileThemeCandidates += Join-Path $env:POSH_THEMES_PATH 'catppuccin_mocha.omp.json'
            $profileThemeCandidates += Join-Path $env:POSH_THEMES_PATH 'jandedobbeleer.omp.json'
        }
        $profileThemeCandidates += Join-Path $env:USERPROFILE 'oh-my-posh-themes\jandedobbeleer.omp.json'
    }
    if (-not $profileTheme) {
        foreach ($candidate in $profileThemeCandidates) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $profileTheme = (Resolve-Path -LiteralPath $candidate).ProviderPath
                break
            }
        }
    }
    if ($profileTheme) {
        try {
            $profileInit = (& oh-my-posh init pwsh --config $profileTheme | Out-String)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($profileInit)) {
                Invoke-Expression $profileInit
            } else {
                $fallbackTheme = Join-Path $env:USERPROFILE 'oh-my-posh-themes\catppuccin_mocha.omp.json'
                if (Test-Path $fallbackTheme) {
                    Invoke-Expression (& oh-my-posh init pwsh --config $fallbackTheme | Out-String)
                }
            }
        } catch { Write-Warning "Oh My Posh: $_" }
    } else {
        Write-Verbose 'No local Oh My Posh theme. Set POWERSHELL_POSH_THEME to a local .omp.json file.'
    }
}

# Initialize after Oh My Posh so zoxide can hook the final prompt.
$profileZoxideReady = $false
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    try {
        $profileInit = (& zoxide init powershell | Out-String)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($profileInit)) {
            Invoke-Expression $profileInit
            $profileZoxideReady = $true
        } else { Write-Warning 'zoxide initialization failed.' }
    } catch { Write-Warning "zoxide: $_" }
}

# Terminal-Icons adds rich icons to directory listings. Enabled by default for interactive sessions.
# Set $env:POWERSHELL_PROFILE_ICONS = '0' to disable if ultra-fast startup is preferred.
if ($env:POWERSHELL_PROFILE_ICONS -ne '0') {
    Import-Module Terminal-Icons -ErrorAction SilentlyContinue
}

if (Get-Module -ListAvailable PSReadLine) {
    try {
        Import-Module PSReadLine -ErrorAction Stop
        Set-PSReadLineOption -EditMode Windows -HistoryNoDuplicates:$true -BellStyle None
        $profileReadLineCommand = Get-Command Set-PSReadLineOption
        $profileColors = @{
            Command = '#E5C07B'; Parameter = '#56B6C2'; Operator = '#808080'
            Number = '#D19A66'; String = '#98C379'; Variable = '#61AFEF'
            Type = '#C678DD'; Comment = '#5C6370'; ContinuationPrompt = '#E5C07B'
            Default = '#FFFFFF'
        }
        if ($profileReadLineCommand.Parameters.ContainsKey('PredictionSource') -and
            $Host.UI.SupportsVirtualTerminal) {
            Set-PSReadLineOption -PredictionSource History
            $profileColors.InlinePrediction = '#6C7086'
            if ($profileReadLineCommand.Parameters.ContainsKey('PredictionViewStyle')) {
                Set-PSReadLineOption -PredictionViewStyle InlineView
            }
        }
        Set-PSReadLineOption -Colors $profileColors
        Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo

        if ($profileZoxideReady -and (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)) {
            Set-PSReadLineKeyHandler -Chord 'Alt+z' -BriefDescription 'Choose directory' -ScriptBlock {
                $destination = zoxide query -i
                if ($LASTEXITCODE -eq 0 -and $destination) {
                    Set-Location -LiteralPath $destination
                    [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
                }
            }
        }
        if (Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue) {
            if (Get-Module -ListAvailable PSFzf) {
                Import-Module PSFzf -ErrorAction Stop
                Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
            }
        }
    } catch { Write-Warning "PSReadLine/PSFzf: $_" }
}


# Interactive startup banner: displays Fastfetch ASCII art and hardware telemetry.
# Set $env:POWERSHELL_PROFILE_BANNER = '0' to disable if a silent prompt is preferred.
if ($env:POWERSHELL_PROFILE_BANNER -ne '0' -and $env:POWERSHELL_PROFILE_MINIMAL -ne '1') {
    Show-SystemInfo
    Show-FeatureTips
}
