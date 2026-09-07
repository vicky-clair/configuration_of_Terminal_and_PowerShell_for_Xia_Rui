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

# Keep dir/ls/cat as PowerShell object-producing commands. Use ll/la/catc for display.
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
function catc {
    if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
        bat --paging=never @args
    } else { Get-Content @args }
}

if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    Set-Alias g git
    function gst { git status @args }
    function gco { git checkout @args }
    function gb  { git branch @args }
    # gl is the built-in Get-Location alias and would shadow a function named gl.
    function glog { git log --oneline --graph --all @args }
}
Set-Alias grep Select-String

function Log-Info($msg)  { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Log-Warn($msg)  { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Log-Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor Red }

function Show-SystemInfo {
    if (Get-Command fastfetch -CommandType Application -ErrorAction SilentlyContinue) {
        $configFile = Join-Path $env:USERPROFILE '.config\fastfetch\config.jsonc'
        if (Test-Path -LiteralPath $configFile -PathType Leaf) {
            fastfetch -c $configFile @args
        } else { fastfetch @args }
    } else { Write-Warning 'Fastfetch is not installed. Run: scoop install fastfetch' }
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

# Load a fixed local theme. Never download a theme while opening a terminal.
# Override with $env:POWERSHELL_POSH_THEME (a local path) before dot-sourcing.
if (Get-Command oh-my-posh -CommandType Application -ErrorAction SilentlyContinue) {
    $profileTheme = $null
    $profileThemeCandidates = @()
    if ($env:POWERSHELL_POSH_THEME) {
        $profileThemeCandidates += $env:POWERSHELL_POSH_THEME
    } else {
        if ($env:POSH_THEMES_PATH) {
            $profileThemeCandidates += Join-Path $env:POSH_THEMES_PATH 'jandedobbeleer.omp.json'
        }
        $profileThemeCandidates += Join-Path $env:USERPROFILE 'oh-my-posh-themes\jandedobbeleer.omp.json'
    }
    foreach ($candidate in $profileThemeCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $profileTheme = (Resolve-Path -LiteralPath $candidate).ProviderPath
            break
        }
    }
    if ($profileTheme) {
        try {
            $profileInit = (& oh-my-posh init pwsh --config $profileTheme | Out-String)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($profileInit)) {
                Invoke-Expression $profileInit
            } else { Write-Warning 'Oh My Posh initialization failed.' }
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

# Icons can cost startup time; opt in when you want icons on Get-ChildItem output.
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
    } catch { Write-Warning "PSReadLine/PSFzf: $_" }
}

# Optional banner; no Clear-Host, random greeting, or artificial startup delay.
if ($env:POWERSHELL_PROFILE_BANNER -eq '1') { Show-SystemInfo }
