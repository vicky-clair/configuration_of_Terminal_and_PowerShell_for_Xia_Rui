# Dot-source this file from $PROFILE. No downloads or package installs at startup.

# Scoop normally manages PATH itself. Repair a missing entry without duplicating it.
$profileScoopRoot = if ($env:SCOOP) { $env:SCOOP } else { [IO.Path]::Combine($env:USERPROFILE, 'scoop') }
$profileShims = [IO.Path]::Combine($profileScoopRoot, 'shims')
$profilePathEntries = @($env:PATH -split ';' | ForEach-Object { $_.Trim().TrimEnd('\', '/') })
if ([IO.Directory]::Exists($profileShims) -and
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
function llg {
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

Set-Alias g git
function gst { git status @args }
function gco { git checkout @args }
function gb { git branch @args }
function glog { git log --oneline --graph --all @args }
Set-Alias grep Select-String

# Yazi file manager integration with automatic directory changing upon exit
function y {
    if (-not (Get-Command yazi -CommandType Application -ErrorAction SilentlyContinue)) { Write-Warning 'yazi is not installed.'; return }
    $tmp=[IO.Path]::GetTempFileName()
    try {
        & yazi @args --cwd-file="$tmp"
        $destination=[IO.File]::ReadAllText($tmp).Trim()
        if ($destination -and [IO.Directory]::Exists($destination)) { Set-Location -LiteralPath $destination }
    } finally { [IO.File]::Delete($tmp) }
}
Set-Alias lzd lazydocker
Set-Alias lzg lazygit
function lg { if (Get-Command lazygit -CommandType Application -ErrorAction SilentlyContinue) { & lazygit @args } else { llg @args } }
function v { & nvim @args }

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
    $file = & fzf @fzfArgs --no-multi
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
    if ([string]::IsNullOrWhiteSpace($Query)) { Write-Warning 'Usage: fif <search text>'; return }
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
    $rgArgs = @('--column', '--line-number', '--no-heading', '--color=never', '--smart-case')
    $selected = & rg @rgArgs -- $Query | & fzf @fzfArgs --no-multi
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

function Log-Info($msg)  { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Log-Warn($msg)  { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Log-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Show-SystemInfo {
    if ($env:POWERSHELL_PROFILE_MINIMAL -eq '1') { return }
    if (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue) {
        $configFile = Join-Path $env:USERPROFILE '.config\fastfetch\config.jsonc'
        if (Test-Path -LiteralPath $configFile -PathType Leaf) {
            try { Write-Host (Invoke-ProfileProcess fastfetch (@('-c',$configFile)+$args) -TimeoutMs 2000) } catch { Write-Verbose $_ }
        } else { try { Write-Host (Invoke-ProfileProcess fastfetch $args -TimeoutMs 2000) } catch { Write-Verbose $_ } }
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

    $features = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[object]]::new()

    # 1. Yazi
    if (Get-Command yazi -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add(@{ Name = 'yazi'; Desc = '目录穿梭'; Shortcut = 'y [path]' })
    } else {
        $warnings.Add(@{ Name = 'yazi'; Message = '文件管理器未就绪'; Hint = 'scoop install yazi' })
    }

    # 2. fd
    if ((Get-Command fd -CommandType Application -ErrorAction SilentlyContinue) -and ($env:FZF_DEFAULT_COMMAND -like '*fd*')) {
        $features.Add(@{ Name = 'fd'; Desc = '极速索引引擎'; Shortcut = 'FZF加速' })
    } else {
        $warnings.Add(@{ Name = 'fd'; Message = '索引引擎未就绪'; Hint = 'scoop install fd' })
    }

    # 3. bat + eza preview
    $hasBat = [bool](Get-Command bat -CommandType Application -ErrorAction SilentlyContinue)
    $hasEza = [bool](Get-Command eza -CommandType Application -ErrorAction SilentlyContinue)
    if ($hasBat -and $hasEza -and ($env:FZF_DEFAULT_OPTS -like '*--preview*')) {
        $features.Add(@{ Name = 'bat+eza'; Desc = '画中画实时预览'; Shortcut = '智能高亮' })
    } else {
        $missing = @()
        if (-not $hasBat) { $missing += 'bat' }
        if (-not $hasEza) { $missing += 'eza' }
        $warnings.Add(@{ Name = ($missing -join '/'); Message = '画中画预览已降级'; Hint = "scoop install $($missing -join ' ')" })
    }

    # 4. fzf & PSFzf
    $hasFzf = [bool](Get-Command fzf -CommandType Application -ErrorAction SilentlyContinue)
    $hasPsFzf = [bool](Get-Module PSFzf) -or [bool](Get-Module -ListAvailable PSFzf)
    if ($hasFzf -and $hasPsFzf) {
        $features.Add(@{ Name = 'fzf'; Desc = '模糊搜索'; Shortcut = 'Ctrl+R/F/Alt+Z' })
    } elseif ($hasFzf) {
        $features.Add(@{ Name = 'fzf'; Desc = '基础模糊查找'; Shortcut = 'CLI模式' })
        $warnings.Add(@{ Name = 'PSFzf'; Message = '快捷键未加载'; Hint = 'Install-Module PSFzf' })
    } else {
        $warnings.Add(@{ Name = 'fzf'; Message = '模糊检索未就绪'; Hint = 'scoop install fzf' })
    }

    # 5. eza
    if ($hasEza) {
        $features.Add(@{ Name = 'eza'; Desc = '现代文件列表'; Shortcut = 'll/la/lt/llg' })
    } else {
        $warnings.Add(@{ Name = 'eza'; Message = '现代化 ls 未启用'; Hint = 'scoop install eza' })
    }

    # 6. lazydocker
    if (Get-Command lazydocker -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add(@{ Name = 'lazydocker'; Desc = '容器管家'; Shortcut = 'lzd' })
    } else {
        $warnings.Add(@{ Name = 'lazydocker'; Message = '容器管理未安装'; Hint = 'scoop install lazydocker' })
    }

    # 7. Neovim
    if ((Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) -and ($env:EDITOR -eq 'nvim')) {
        $features.Add(@{ Name = 'Neovim'; Desc = '默认编辑器'; Shortcut = 'v/fv' })
    } else {
        $warnings.Add(@{ Name = 'neovim'; Message = '编辑器未设默认'; Hint = 'scoop install neovim' })
    }

    # 8. zoxide
    $hasZoxide = [bool](Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue)
    $zoxideHooked = $profileZoxideReady -or $script:profileZoxideReady -or [bool](Get-Command __zoxide_z -ErrorAction SilentlyContinue)
    if ($hasZoxide -and $zoxideHooked) {
        $features.Add(@{ Name = 'zoxide'; Desc = '智能目录快跳'; Shortcut = 'z/zi' })
    } elseif ($hasZoxide) {
        $features.Add(@{ Name = 'zoxide'; Desc = '智能跳转就绪'; Shortcut = 'CLI模式' })
    } else {
        $warnings.Add(@{ Name = 'zoxide'; Message = '智能快跳未生效'; Hint = 'scoop install zoxide' })
    }

    # 9. fif (Find in files)
    $hasRg = [bool](Get-Command rg -CommandType Application -ErrorAction SilentlyContinue)
    if ($hasRg -and $hasFzf -and $hasBat) {
        $features.Add(@{ Name = 'fif'; Desc = '全文代码检索'; Shortcut = 'fif <词>' })
    } else {
        $missing = @()
        if (-not $hasRg) { $missing += 'ripgrep' }
        if (-not $hasFzf) { $missing += 'fzf' }
        if (-not $hasBat) { $missing += 'bat' }
        $warnings.Add(@{ Name = 'fif'; Message = '全文检索未就绪'; Hint = "scoop install $($missing -join ' ')" })
    }

    # 10. Fastfetch
    if (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add(@{ Name = 'fastfetch'; Desc = '动漫硬件看板'; Shortcut = '系统状态' })
    } else {
        $warnings.Add(@{ Name = 'fastfetch'; Message = '硬件面板未就绪'; Hint = 'scoop install fastfetch' })
    }

    # 11. lazygit
    if (Get-Command lazygit -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add(@{ Name = 'lazygit'; Desc = 'Git管家'; Shortcut = 'lg/Ctrl+G' })
    } else {
        $warnings.Add(@{ Name = 'lazygit'; Message = 'Git管理未安装'; Hint = 'scoop install lazygit' })
    }

    # 12. Starship
    if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
        $features.Add(@{ Name = 'starship'; Desc = '赛博提示符'; Shortcut = '已就绪' })
    }

    if ($global:VFOX_SKIPPED) {
        $warnings.Add(@{ Name = 'vfox'; Message = '版本管理初始化超时'; Hint = '已自动降级跳过' })
    }

    $winWidth = 100
    try { $winWidth = $Host.UI.RawUI.WindowSize.Width } catch {}

    # 针对极端窄屏（小于 72 字符）自适应流式输出
    if ($winWidth -lt 72) {
        Write-Host "`n🚀 终端现代化生产力就绪看板:" -ForegroundColor Cyan
        foreach ($f in $features) {
            Write-Host "  ✓ " -NoNewline -ForegroundColor Green
            Write-Host $f.Name -NoNewline -ForegroundColor Cyan
            Write-Host " $($f.Desc) " -NoNewline -ForegroundColor White
            Write-Host "($($f.Shortcut))" -ForegroundColor Yellow
        }
        foreach ($w in $warnings) {
            Write-Host "  ✗ " -NoNewline -ForegroundColor Yellow
            Write-Host "$($w.Name) $($w.Message) " -NoNewline -ForegroundColor White
            Write-Host "(运行: $($w.Hint))" -ForegroundColor Cyan
        }
        Write-Host "  ⚡ 快捷按键: " -NoNewline -ForegroundColor Magenta
        Write-Host "[Ctrl+R] 历史搜 · [Alt+Z/zi] 目录跳 · [Ctrl+F] 文件填" -ForegroundColor Yellow
        Write-Host "  ⚡ 效率指令: " -NoNewline -ForegroundColor Magenta
        Write-Host "[lg/Ctrl+G] Lazygit · [fv] 模糊编辑 · [fif] 全文搜" -ForegroundColor Yellow
        Write-Host ""
        return
    }

    # 宽屏双列流式卡片（左侧流式垂直线，右侧开放无碎边）
    Write-Host ""
    Write-Host "╭── 🚀 终端现代化生产力就绪看板 ──────────────────────────────────────" -ForegroundColor Cyan

    for ($i = 0; $i -lt $features.Count; $i += 2) {
        $it1 = $features[$i]
        $it2 = if ($i + 1 -lt $features.Count) { $features[$i + 1] } else { $null }

        # 左侧引导指示线
        Write-Host "│  " -NoNewline -ForegroundColor Cyan

        # 第 1 列
        Write-Host "✓ " -NoNewline -ForegroundColor Green
        Write-Host $it1.Name -NoNewline -ForegroundColor Cyan
        Write-Host " $($it1.Desc) " -NoNewline -ForegroundColor White
        Write-Host "($($it1.Shortcut))" -NoNewline -ForegroundColor Yellow

        $text1 = "$($it1.Name) $($it1.Desc) ($($it1.Shortcut))"
        $w1 = Get-DisplayWidth $text1
        $col1Width = 38
        $pad = if ($col1Width -gt $w1) { ' ' * ($col1Width - $w1) } else { '  ' }
        Write-Host $pad -NoNewline

        # 第 2 列
        if ($it2) {
            Write-Host "✓ " -NoNewline -ForegroundColor Green
            Write-Host $it2.Name -NoNewline -ForegroundColor Cyan
            Write-Host " $($it2.Desc) " -NoNewline -ForegroundColor White
            Write-Host "($($it2.Shortcut))" -NoNewline -ForegroundColor Yellow
        }
        Write-Host ""
    }

    # 警告项展示（鲜明彩色提示修复命令）
    if ($warnings.Count -gt 0) {
        Write-Host "│" -ForegroundColor Cyan
        foreach ($w in $warnings) {
            Write-Host "│  " -NoNewline -ForegroundColor Cyan
            Write-Host "✗ " -NoNewline -ForegroundColor Yellow
            Write-Host "$($w.Name) $($w.Message) " -NoNewline -ForegroundColor White
            Write-Host "(运行: $($w.Hint))" -ForegroundColor Cyan
        }
    }

    # 底部快捷提示条（分两行结构化输出：按键 + 指令，杜绝单行超长出框）
    Write-Host "│" -ForegroundColor Cyan

    # 第 1 行：常用快捷按键
    Write-Host "│  " -NoNewline -ForegroundColor Cyan
    Write-Host "⚡ 快捷按键: " -NoNewline -ForegroundColor Magenta
    $hotkeys = @(
        @{ Key = '[Ctrl+R]'; Action = '历史搜' },
        @{ Key = '[Alt+Z/zi]'; Action = '目录跳' },
        @{ Key = '[Ctrl+F]'; Action = '文件填' }
    )
    for ($k = 0; $k -lt $hotkeys.Count; $k++) {
        $s = $hotkeys[$k]
        Write-Host $s.Key -NoNewline -ForegroundColor Yellow
        Write-Host " $($s.Action)" -NoNewline -ForegroundColor Cyan
        if ($k -lt $hotkeys.Count - 1) {
            Write-Host " · " -NoNewline -ForegroundColor White
        }
    }
    Write-Host ""

    # 第 2 行：现代效率指令
    Write-Host "│  " -NoNewline -ForegroundColor Cyan
    Write-Host "⚡ 效率指令: " -NoNewline -ForegroundColor Magenta
    $cliShortcuts = @(
        @{ Key = '[lg/Ctrl+G]'; Action = 'Lazygit' },
        @{ Key = '[fv]'; Action = '模糊编辑' },
        @{ Key = '[fif]'; Action = '全文搜' }
    )
    for ($k = 0; $k -lt $cliShortcuts.Count; $k++) {
        $s = $cliShortcuts[$k]
        Write-Host $s.Key -NoNewline -ForegroundColor Yellow
        Write-Host " $($s.Action)" -NoNewline -ForegroundColor Cyan
        if ($k -lt $cliShortcuts.Count - 1) {
            Write-Host " · " -NoNewline -ForegroundColor White
        }
    }
    Write-Host ""
    Write-Host "╰─────────────────────────────────────────────────────────────────────" -ForegroundColor Cyan
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
    param([string]$Path='.', [ValidateRange(1,10000)][int]$TopN=10)
    # Only retain N objects. Traversal still visits all files; selection costs O(files * N).
    $largest=[System.Collections.Generic.List[System.IO.FileInfo]]::new()
    Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
        $index=0
        while ($index -lt $largest.Count -and $largest[$index].Length -ge $_.Length) { $index++ }
        if ($index -lt $TopN) { $largest.Insert($index, $_); if ($largest.Count -gt $TopN) { $largest.RemoveAt($TopN) } }
    }
    $largest | Format-Table Name, @{Label='Size(MB)';Expression={[math]::Round($_.Length/1MB,2)}} -AutoSize
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
        @{Name="Lazygit"; Command="lazygit"; Required=$false},
        @{Name="Lazydocker"; Command="lazydocker"; Required=$false},
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

# Capture generated initialization code without unbounded native waits or pipe deadlocks.
function Invoke-ProfileProcess {
    param([string]$Name, [string[]]$Arguments=@(), [ValidateRange(50,60000)][int]$TimeoutMs=1500)
    $command=Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) { return '' }
    $process=[Diagnostics.Process]::new()
    $process.StartInfo.FileName=$command.Source
    $quoted=@(foreach ($argument in $Arguments) {
        '"' + ([regex]::Replace([regex]::Replace($argument,'(\\*)"','$1$1\"'),'(\\+)$','$1$1')) + '"'
    })
    $process.StartInfo.Arguments=$quoted -join ' '
    $process.StartInfo.UseShellExecute=$false
    $process.StartInfo.CreateNoWindow=$true
    $process.StartInfo.RedirectStandardOutput=$true
    $process.StartInfo.RedirectStandardError=$true
    $process.StartInfo.StandardOutputEncoding=[Text.UTF8Encoding]::new($false)
    $process.StartInfo.StandardErrorEncoding=[Text.UTF8Encoding]::new($false)
    try {
        $null=$process.Start()
        $stdout=$process.StandardOutput.ReadToEndAsync()
        $stderr=$process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutMs)) {
            try { $process.Kill($true) } catch { $process.Kill() }
            throw "$Name initialization timed out after $TimeoutMs ms."
        }
        if (-not $stdout.Wait(250) -or -not $stderr.Wait(250)) { throw "$Name output did not close." }
        if ($process.ExitCode -ne 0) { throw "$Name failed ($($process.ExitCode)): $($stderr.Result.Trim())" }
        return $stdout.Result
    } finally { $process.Dispose() }
}

function ConvertTo-BoundedVfoxScript {
    param([string]$Text, [int]$TimeoutMs=1500)
    $tokens=$null; $errors=$null
    $ast=[Management.Automation.Language.Parser]::ParseInput($Text,[ref]$tokens,[ref]$errors)
    if ($errors) { throw 'vfox generated invalid PowerShell initialization.' }
    # vfox emits native calls inside its module, prompt hook and exit handler. Bound these too.
    $calls=@($ast.FindAll({ param($node)
        if ($node -isnot [Management.Automation.Language.CommandAst]) { return $false }
        $name=$node.GetCommandName()
        return $name -and [IO.Path]::GetFileName($name) -in @('vfox','vfox.exe')
    },$true) | Sort-Object { $_.Extent.StartOffset } -Descending)
    foreach ($call in $calls) {
        $values=@(foreach ($element in $call.CommandElements) {
            if ($element -is [Management.Automation.Language.CommandParameterAst] -and -not $element.Argument) {
                "'"+$element.Extent.Text.Replace("'","''")+"'"
                continue
            }
            if ($element -isnot [Management.Automation.Language.StringConstantExpressionAst]) {
                throw 'Unsupported dynamic vfox call in generated initialization.'
            }
            "'"+$element.Value.Replace("'","''")+"'"
        })
        $arguments=if ($values.Count -gt 1) { $values[1..($values.Count-1)] -join ',' } else { '' }
        $replacement="Invoke-ProfileProcess -Name $($values[0]) -Arguments @($arguments) -TimeoutMs $TimeoutMs"
        $Text=$Text.Remove($call.Extent.StartOffset,$call.Extent.EndOffset-$call.Extent.StartOffset).Insert($call.Extent.StartOffset,$replacement)
    }
    return $Text
}

function Enable-Vfox {
    [CmdletBinding()]
    param([ValidateRange(50,60000)][int]$TimeoutMs=15000)
    try {
        $activation=Invoke-ProfileProcess vfox @('activate','pwsh') -TimeoutMs $TimeoutMs
        if (-not $activation) { throw 'vfox is unavailable or returned empty initialization.' }
        $activation=ConvertTo-BoundedVfoxScript $activation
        $ErrorActionPreference='Stop'
        Invoke-Expression $activation
        $global:VFOX_SKIPPED=$false
    } catch { $global:VFOX_SKIPPED=$true; Write-Warning "vfox: $_" }
}
function Enable-TerminalIcons { Import-Module Terminal-Icons -ErrorAction Stop }

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


if (Get-Command nvim -CommandType Application -ErrorAction SilentlyContinue) { $env:EDITOR='nvim'; $env:VISUAL='nvim' }


# Deterministic daily theme selection: no cache writes, and the same sorted library gives the same theme that day.
$profileThemeCandidates=@()
$themesDir=[IO.Path]::Combine($env:USERPROFILE,'oh-my-posh-themes')
if (-not [IO.Directory]::Exists($themesDir) -and $env:POSH_THEMES_PATH) { $themesDir=$env:POSH_THEMES_PATH }
$profileMode=if ($env:POWERSHELL_THEME_MODE) { $env:POWERSHELL_THEME_MODE } else { 'random' }
if ($profileMode -eq 'starship' -or $env:POWERSHELL_POSH_THEME -eq 'starship') {
    try { $profileInit=Invoke-ProfileProcess starship @('init','powershell'); if ($profileInit) { Invoke-Expression $profileInit } }
    catch { Write-Verbose "Starship: $_" }
} else {
    if ($profileMode -eq 'random' -and [IO.Directory]::Exists($themesDir)) {
        $randomThemes=@([IO.Directory]::GetFiles($themesDir,'*.omp.json') | Sort-Object)
        if ($randomThemes.Count) {
            $day=[int](Get-Date -Format yyyyMMdd)
            $profileThemeCandidates += $randomThemes[$day % $randomThemes.Count]
        }
    } elseif ($env:POWERSHELL_POSH_THEME -and $env:POWERSHELL_POSH_THEME -notin @('random','starship')) {
        $profileThemeCandidates += $env:POWERSHELL_POSH_THEME
    }
    if ($themesDir) { $profileThemeCandidates += [IO.Path]::Combine($themesDir,'catppuccin_mocha.omp.json') }
    if ($env:POSH_THEMES_PATH) { $profileThemeCandidates += [IO.Path]::Combine($env:POSH_THEMES_PATH,'catppuccin_mocha.omp.json') }
    foreach ($candidate in @($profileThemeCandidates | Select-Object -Unique)) {
        if (-not [IO.File]::Exists($candidate)) { continue }
        try {
            # Reject malformed local JSON before invoking the prompt engine.
            $null=[IO.File]::ReadAllText($candidate) | ConvertFrom-Json -ErrorAction Stop
            $profileInit=Invoke-ProfileProcess oh-my-posh @('init','pwsh','--config',$candidate)
            if (-not $profileInit) { continue }
            Invoke-Expression $profileInit
            if ($env:POWERSHELL_PROFILE_TIPS -eq '1') { Write-Host ('Theme: '+[IO.Path]::GetFileNameWithoutExtension($candidate)) }
            break
        } catch { Write-Verbose "Oh My Posh: $_" }
    }
}

# Initialize after Oh My Posh so zoxide can hook the final prompt.
$profileZoxideReady = $false
if (Get-Command zoxide -CommandType Application -ErrorAction SilentlyContinue) {
    try {
        $profileInit = Invoke-ProfileProcess zoxide @('init','powershell')
        if (-not [string]::IsNullOrWhiteSpace($profileInit)) {
            Invoke-Expression $profileInit
            $profileZoxideReady = $true
        } else { Write-Warning 'zoxide initialization failed.' }
    } catch { Write-Warning "zoxide: $_" }
}

# Terminal-Icons adds rich icons to directory listings. Enabled by default for interactive sessions.
# Set $env:POWERSHELL_PROFILE_ICONS = '0' to disable if ultra-fast startup is preferred.
if ($env:POWERSHELL_PROFILE_ICONS -eq '1') {
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
        if (Get-Command lazygit -CommandType Application -ErrorAction SilentlyContinue) {
            Set-PSReadLineKeyHandler -Chord 'Ctrl+g' -BriefDescription 'Launch Lazygit' -ScriptBlock {
                & lazygit
                [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt()
            }
        }
    } catch { Write-Warning "PSReadLine/PSFzf: $_" }
}


# Activate after final prompt setup, with a shorter generation budget than manual Enable-Vfox.
if ($env:POWERSHELL_PROFILE_VFOX -eq '1') { Enable-Vfox -TimeoutMs 3000 }

# Interactive startup banner: displays Fastfetch ASCII art and hardware telemetry.
# Set $env:POWERSHELL_PROFILE_BANNER = '0' to disable if a silent prompt is preferred.
if ($env:POWERSHELL_PROFILE_BANNER -eq '1') {
    Show-SystemInfo
}
if ($env:POWERSHELL_PROFILE_TIPS -eq '1') { Show-FeatureTips }
