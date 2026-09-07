# ============================================================================
# Terminal Setup Common Library (跨操作系统 Win11/10/8.1 兼容性与环境准备)
# ============================================================================

function Initialize-SetupEnvironment {
    # 1. 强制启用 TLS 1.2 (兼容 Windows 8.1 / Windows 10 旧版 .NET 4.5 联网下载)
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {
        Write-Verbose "TLS 1.2 setup failed: $_"
    }

    # 2. 检查操作系统版本
    $osVersion = [System.Environment]::OSVersion.Version
    $osName = "Windows $([System.Environment]::OSVersion.VersionString)"
    if ($osVersion.Major -eq 10 -and $osVersion.Build -ge 22000) {
        $osName = "Windows 11 (Build $($osVersion.Build))"
    } elseif ($osVersion.Major -eq 10) {
        $osName = "Windows 10 (Build $($osVersion.Build))"
    } elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 3) {
        $osName = "Windows 8.1"
    }
    Write-Host "[*] 检测到操作系统: $osName" -ForegroundColor Cyan

    # 3. 检查并设置 ExecutionPolicy (允许当前用户运行脚本)
    try {
        $policy = Get-ExecutionPolicy -Scope CurrentUser
        if ($policy -in @('Restricted', 'Undefined')) {
            Write-Host "[*] 正在配置 CurrentUser 执行策略为 RemoteSigned..." -ForegroundColor Yellow
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        }
    } catch {
        Write-Verbose "ExecutionPolicy configuration note: $_"
    }
}

function Ensure-ScoopInstalled {
    Initialize-SetupEnvironment
    $scoopShims = Join-Path $env:USERPROFILE 'scoop\shims'
    if (Test-Path $scoopShims) {
        $envPaths = @($env:PATH -split ';' | ForEach-Object { $_.Trim().TrimEnd('\', '/') })
        if ($envPaths -notcontains $scoopShims.TrimEnd('\', '/')) {
            if ($env:PATH) {
                $env:PATH = "$($env:PATH);$scoopShims"
            } else {
                $env:PATH = $scoopShims
            }
        }
    }

    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
        Write-Host "[*] 未检测到 Scoop，正在通过官方脚本一键安装..." -ForegroundColor Yellow
        try {
            Invoke-Expression (Invoke-RestMethod -Uri 'https://get.scoop.sh' -UseBasicParsing)
            $env:PATH = "$env:PATH;$env:USERPROFILE\scoop\shims"
        } catch {
            throw "Scoop 安装失败，请检查网络连接: $_"
        }
    } else {
        Write-Host "[OK] Scoop 已就绪 ($((Get-Command scoop).Source))" -ForegroundColor Green
    }
}

function Ensure-ScoopBuckets {
    param([string[]]$Buckets = @('main', 'extras', 'versions', 'nerd-fonts'))
    Ensure-ScoopInstalled
    $bucketListOutput = & scoop bucket list
    $installedBuckets = @($bucketListOutput | ForEach-Object {
        if ($_.PSObject.Properties['Name'] -and $_.Name) {
            $_.Name.ToString().Trim()
        } elseif ($_ -is [string]) {
            $_.Trim()
        }
    })
    foreach ($b in $Buckets) {
        if ($installedBuckets -notcontains $b) {
            Write-Host "[*] 正在添加 Scoop 仓库: $b..." -ForegroundColor Yellow
            try {
                & scoop bucket add $b 2>$null
            } catch {
                Write-Warning "添加仓库 $b 遇到提示: $_"
            }
        } else {
            Write-Host "[OK] Scoop 仓库已添加: $b" -ForegroundColor DarkGray
        }
    }
}

function Install-ScoopAppsIfMissing {
    param([string[]]$Apps)
    Ensure-ScoopInstalled
    $listOutput = & scoop list
    $installed = @($listOutput | ForEach-Object {
        if ($_.PSObject.Properties['Name'] -and $_.Name) {
            $_.Name.ToString().Trim()
        } elseif ($_ -match '^Name\s+:\s+(.+)$') {
            $matches[1].Trim()
        }
    })

    $wingetFallbackMap = @{
        'pwsh'        = 'Microsoft.PowerShell'
        'git'         = 'Git.Git'
        'oh-my-posh'  = 'JanDeDobbeleer.OhMyPosh'
        'fastfetch'   = 'Fastfetch-cli.Fastfetch'
        'eza'         = 'eza-community.eza'
        'bat'         = 'sharkdp.bat'
        'zoxide'      = 'ajeetdsouza.zoxide'
        'fzf'         = 'junegunn.fzf'
        'lazydocker'  = 'jesseduffield.lazydocker'
        'lazygit'     = 'JesseDuffield.lazygit'
        'vfox'        = 'version-fox.vfox'
        'starship'    = 'Starship.Starship'
        'ripgrep'     = 'BurntSushi.ripgrep.MSVC'
        'rg'          = 'BurntSushi.ripgrep.MSVC'
        'fd'          = 'sharkdp.fd'
        'neovim'      = 'Neovim.Neovim'
        'nvim'        = 'Neovim.Neovim'
        'yazi'        = 'sxyazi.yazi'
        'clink'       = 'chrisant996.Clink'
    }

    foreach ($app in $Apps) {
        $baseName = $app.Split('/')[-1]

        # 特殊处理：如果是字体应用，检测系统字体目录（当前用户与全局 Windows Fonts）
        if ($baseName -match '(?i)JetBrains' -or $app -match 'nerd-fonts') {
            $fontMatches = @(Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter "*JetBrains*" -ErrorAction SilentlyContinue)
            if ($fontMatches.Count -gt 0) {
                Write-Host "[OK] 图标字体已在系统中安装就绪: $baseName ($($fontMatches.Count) 个字体变体已加载)" -ForegroundColor DarkGray
                continue
            }
        }

        # 检查是否已通过外部途径（如 WinGet / MSI / 系统自带）安装
        if (Get-Command $baseName -ErrorAction SilentlyContinue) {
            Write-Host "[OK] 应用已就绪: $baseName ($((Get-Command $baseName).Source))" -ForegroundColor DarkGray
            continue
        }

        if ($installed -notcontains $baseName) {
            Write-Host "[*] 正在安装 Scoop 应用: $app..." -ForegroundColor Yellow
            $scoopSuccess = $false
            try {
                & scoop install $app
                if ($LASTEXITCODE -eq 0) {
                    $scoopSuccess = $true
                }
            } catch {
                Write-Warning "Scoop 安装 $app 遇到提示: $_"
            }

            # 若 Scoop 安装遇阻且该工具在 WinGet 中存在，自动尝试 WinGet 容错兜底
            if (-not $scoopSuccess -and -not (Get-Command $baseName -ErrorAction SilentlyContinue)) {
                if ($wingetFallbackMap.ContainsKey($baseName)) {
                    $wingetId = $wingetFallbackMap[$baseName]
                    Write-Host "[*] 启动 WinGet 智能容错兜底: 正在通过 WinGet 安装 $baseName ($wingetId)..." -ForegroundColor Cyan
                    if (Ensure-WingetConfigured) {
                        try {
                            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                            $wPath = if ($wingetCmd) { $wingetCmd.Source } else { "winget" }
                            $proc = Start-Process -FilePath $wPath -ArgumentList "install", "--id", $wingetId, "--exact", "--accept-source-agreements", "--accept-package-agreements", "--silent" -NoNewWindow -PassThru -Wait
                            if ($proc.ExitCode -in @(0, -1978335189)) {
                                Write-Host "[OK] [WinGet] $baseName 兜底安装成功！" -ForegroundColor Green
                                Refresh-SessionPath
                            } else {
                                Write-Warning "[!] [WinGet] 兜底安装 $baseName 返回退出码: $($proc.ExitCode)"
                            }
                        } catch {
                            Write-Warning "[!] WinGet 兜底执行异常: $_"
                        }
                    }
                }
            }
        } else {
            Write-Host "[OK] 应用已安装: $app" -ForegroundColor DarkGray
        }
    }
}

function Install-PSModulesIfMissing {
    param([string[]]$Modules)

    # 自动配置 NuGet Provider 与 PSGallery 信任，防止无人值守安装时挂起等待用户交互
    try {
        if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
            Write-Host "[*] 正在静默配置 NuGet 包管理器提供程序..." -ForegroundColor Yellow
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser -ErrorAction SilentlyContinue | Out-Null
        }
        $gallery = Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue
        if ($gallery -and $gallery.InstallationPolicy -ne 'Trusted') {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -Confirm:$false -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Verbose "NuGet/PSGallery setup note: $_"
    }

    foreach ($mod in $Modules) {
        if (-not (Get-Module -ListAvailable -Name $mod)) {
            Write-Host "[*] 正在安装 PowerShell 模块: $mod..." -ForegroundColor Yellow
            try {
                Install-Module -Name $mod -Scope CurrentUser -Force -Confirm:$false -SkipPublisherCheck -ErrorAction Stop
                Write-Host "[OK] 模块安装完成: $mod" -ForegroundColor Green
            } catch {
                Write-Warning "模块 $mod 安装遇到警告: $_"
            }
        } else {
            Write-Host "[OK] 模块已就绪: $mod" -ForegroundColor DarkGray
        }
    }
}

function Ensure-WindowsTerminalConfigured {
    param(
        [switch]$Force
    )
    $projectRoot = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $projectRoot 'settings.json'))) {
        $projectRoot = $PSScriptRoot
    }
    $sourceSettings = Join-Path $projectRoot 'settings.json'
    if (-not (Test-Path -LiteralPath $sourceSettings)) { return }

    $wtTargets = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
    )

    foreach ($target in $wtTargets) {
        $targetDir = Split-Path -Parent $target
        if (Test-Path $targetDir) {
            if ($Force -or (Test-Path $target)) {
                Copy-Item -LiteralPath $sourceSettings -Destination $target -Force
                Write-Host "[OK] Windows Terminal 深度美化配置 (亚克力磨砂/Catppuccin配色/JetBrainsMono字体) 已部署至: $target" -ForegroundColor Green
            }
        }
    }
}

function Ensure-OhMyPoshThemes {
    $themesPath = Join-Path $env:USERPROFILE 'oh-my-posh-themes'
    if (-not (Test-Path $themesPath)) {
        New-Item -ItemType Directory -Path $themesPath -Force | Out-Null
    }
    $existing = @(Get-ChildItem -LiteralPath $themesPath -Filter '*.omp.json' -ErrorAction SilentlyContinue)
    # 多源聚合扫描：Scoop、WinGet、Program Files、环境变量
    if ($existing.Count -lt 5) {
        $candidates = @(
            (Join-Path $env:USERPROFILE 'scoop\apps\oh-my-posh\current\themes'),
            (Join-Path $env:LOCALAPPDATA 'Programs\oh-my-posh\themes'),
            'C:\Program Files (x86)\oh-my-posh\themes',
            'C:\Program Files\oh-my-posh\themes',
            $env:POSH_THEMES_PATH
        )
        foreach ($cand in $candidates) {
            if ($cand -and (Test-Path -LiteralPath $cand)) {
                $found = @(Get-ChildItem -LiteralPath $cand -Filter '*.omp.*' -ErrorAction SilentlyContinue)
                if ($found.Count -gt 0) {
                    Write-Host "[*] 正在从 $cand 同步内置主题至 $themesPath..." -ForegroundColor Yellow
                    Copy-Item -LiteralPath "$cand\*.omp.*" -Destination $themesPath -Force -ErrorAction SilentlyContinue
                    $existing = @(Get-ChildItem -LiteralPath $themesPath -Filter '*.omp.json' -ErrorAction SilentlyContinue)
                    if ($existing.Count -gt 0) { break }
                }
            }
        }
    }
    return $existing.Count
}

function Ensure-FastfetchConfigured {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $projectRoot 'fastfetch\ascii.txt'))) {
        $projectRoot = $PSScriptRoot
    }

    $projectFastfetchDir = Join-Path $projectRoot 'fastfetch'
    $targetFastfetchDir = Join-Path $env:USERPROFILE '.config\fastfetch'

    if (-not (Test-Path $targetFastfetchDir)) {
        New-Item -ItemType Directory -Path $targetFastfetchDir -Force | Out-Null
    }

    if (Test-Path $projectFastfetchDir) {
        $asciiSrc = Join-Path $projectFastfetchDir 'ascii.txt'
        $configSrc = Join-Path $projectFastfetchDir 'config.jsonc'
        if (Test-Path $asciiSrc) {
            Copy-Item -LiteralPath $asciiSrc -Destination (Join-Path $targetFastfetchDir 'ascii.txt') -Force
        }
        if (Test-Path $configSrc) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $configContent = [System.IO.File]::ReadAllText($configSrc, $utf8NoBom)
            $portablePath = "$($env:USERPROFILE.Replace('\', '/'))/.config/fastfetch/ascii.txt"
            $configContent = $configContent -replace '"source":\s*".*?"', "`"source`": `"$portablePath`""
            [System.IO.File]::WriteAllText((Join-Path $targetFastfetchDir 'config.jsonc'), $configContent, $utf8NoBom)
        }
        Write-Host "[OK] Fastfetch 专属 ASCII 横幅与配置文件已部署就绪 ($targetFastfetchDir)" -ForegroundColor Green
    }
}

function Ensure-StarshipConfigured {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $projectRoot 'starship\starship.toml'))) {
        $projectRoot = $PSScriptRoot
    }

    $starshipSource = Join-Path $projectRoot 'starship\starship.toml'
    $targetStarshipDir = Join-Path $env:USERPROFILE '.config'
    $targetStarshipFile = Join-Path $targetStarshipDir 'starship.toml'

    if (-not (Test-Path $targetStarshipDir)) {
        New-Item -ItemType Directory -Path $targetStarshipDir -Force | Out-Null
    }

    if (Test-Path -LiteralPath $starshipSource) {
        Copy-Item -LiteralPath $starshipSource -Destination $targetStarshipFile -Force
        Write-Host "[OK] Starship 赛博朋克固定配置已部署就绪: $targetStarshipFile" -ForegroundColor Green
    }
}

function Refresh-SessionPath {
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $combined = "$machinePath;$userPath"
    $scoopShims = Join-Path $env:USERPROFILE 'scoop\shims'
    if (Test-Path $scoopShims) {
        $combined = "$combined;$scoopShims"
    }
    $windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if (Test-Path $windowsApps) {
        $combined = "$combined;$windowsApps"
    }
    $env:PATH = $combined
}

function Ensure-WingetConfigured {
    # 1. 检查 PATH 中是否有 winget.exe，若没有尝试定位 WindowsApps
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $wingetCmd) {
        $windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
        if (Test-Path (Join-Path $windowsApps 'winget.exe')) {
            $env:PATH = "$($env:PATH);$windowsApps"
            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        }
    }

    if (-not $wingetCmd) {
        Write-Warning "[!] 当前系统未检测到 WinGet (App Installer)。若在 Windows 8.1 或精简系统上，将自动跳至 Scoop 保底。"
        return $false
    }

    # 2. 检查与配置 WinGet 仓库源
    Write-Host "[*] 正在检查与配置 WinGet 软件源仓库..." -ForegroundColor Cyan
    try {
        $sourcesOutput = & $wingetCmd.Source source list 2>&1 | Out-String
        if ($sourcesOutput -notmatch '(?i)winget' -and $sourcesOutput -notmatch '(?i)msstore') {
            Write-Host "[*] WinGet 默认软件源异常或为空，正在重置官方仓库..." -ForegroundColor Yellow
            & $wingetCmd.Source source reset --force 2>&1 | Out-Null
        }
        Write-Host "[*] 正在更新 WinGet 仓库索引..." -ForegroundColor DarkGray
        & $wingetCmd.Source source update 2>&1 | Out-Null
        Write-Host "[OK] WinGet 软件源仓库配置就绪" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "[!] 配置 WinGet 仓库源时遇到提示: $_"
        return $true
    }
}

function Install-AppWithChocoWingetFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ChocoId,

        [Parameter(Mandatory = $true)]
        [string]$WingetId,

        [Parameter(Mandatory = $false)]
        [string]$ScoopId,

        [Parameter(Mandatory = $false)]
        [string]$CommandCheck,

        [Parameter(Mandatory = $false)]
        [string]$PathCheck
    )

    Initialize-SetupEnvironment

    # 1. 检查应用是否已经就绪
    if ($CommandCheck -and (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) {
        Write-Host "[OK] $Name 已就绪 ($((Get-Command $CommandCheck).Source))" -ForegroundColor DarkGray
        return $true
    }
    if ($PathCheck -and (Test-Path -LiteralPath $PathCheck)) {
        Write-Host "[OK] $Name 已安装在指定路径: $PathCheck" -ForegroundColor DarkGray
        return $true
    }

    Write-Host "`n[*] 准备安装应用: $Name ..." -ForegroundColor Yellow

    $chocoInstalled = $false
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue

    # 第一梯队：优先使用 Chocolatey 安装 (若 choco 可用，最多尝试 2 次)
    if ($chocoCmd) {
        Write-Host "[*] 检测到 Chocolatey，尝试使用 choco 安装 $Name (Choco ID: $ChocoId)..." -ForegroundColor Cyan
        for ($attempt = 1; $attempt -le 2; $attempt++) {
            Write-Host "[*] [Choco] 正在执行第 $attempt 次安装尝试..." -ForegroundColor DarkGray
            try {
                $process = Start-Process -FilePath $chocoCmd.Source -ArgumentList "install", $ChocoId, "-y", "--no-progress" -NoNewWindow -PassThru -Wait
                if ($process.ExitCode -eq 0) {
                    Write-Host "[OK] [Choco] $Name 安装成功 (第 $attempt 次尝试)" -ForegroundColor Green
                    $chocoInstalled = $true
                    break
                } else {
                    Write-Warning "[!] [Choco] 第 $attempt 次安装失败 (退出码: $($process.ExitCode))"
                }
            } catch {
                Write-Warning "[!] [Choco] 第 $attempt 次安装异常: $_"
            }
            if ($attempt -lt 2) {
                Start-Sleep -Seconds 2
            }
        }
    } else {
        Write-Host "[*] 未检测到 Chocolatey，或 choco 不可用。" -ForegroundColor DarkGray
    }

    if ($chocoInstalled) {
        Refresh-SessionPath
        return $true
    }

    # 第二梯队：Choco 不可用或 2 次安装均未成功，自动配置 WinGet 仓库并使用 WinGet 安装
    Write-Host "[*] 启动容错降级流程: 检查并配置 WinGet 软件源仓库..." -ForegroundColor Yellow
    $wingetReady = Ensure-WingetConfigured

    if ($wingetReady) {
        Write-Host "[*] [WinGet] 正在使用 winget 安装 $Name (Winget ID: $WingetId)..." -ForegroundColor Cyan
        try {
            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
            $wingetPath = if ($wingetCmd) { $wingetCmd.Source } else { "winget" }
            $wingetArgs = @(
                "install",
                "--id", $WingetId,
                "--exact",
                "--accept-source-agreements",
                "--accept-package-agreements",
                "--silent"
            )
            $process = Start-Process -FilePath $wingetPath -ArgumentList $wingetArgs -NoNewWindow -PassThru -Wait
            if ($process.ExitCode -in @(0, -1978335189)) {
                Write-Host "[OK] [WinGet] $Name 安装成功！" -ForegroundColor Green
                Refresh-SessionPath
                return $true
            } else {
                Write-Warning "[!] [WinGet] 安装返回退出码: $($process.ExitCode)，准备尝试 Scoop 终极保底..."
            }
        } catch {
            Write-Warning "[!] [WinGet] 安装执行异常: $_"
        }
    }

    # 第三梯队：Scoop 终极保底（兼容 Windows 8.1 或无 WinGet 场景）
    if ($ScoopId) {
        Write-Host "[*] [Scoop] 启用 Scoop 兜底安装 $Name (Scoop ID: $ScoopId)..." -ForegroundColor Cyan
        try {
            Ensure-ScoopBuckets -Buckets @('main', 'extras', 'versions')
            Install-ScoopAppsIfMissing -Apps @($ScoopId)
            Refresh-SessionPath
            return $true
        } catch {
            Write-Warning "[!] [Scoop] 安装 $Name 失败: $_"
        }
    }

    Write-Warning "[!] 应用 $Name 所有安装途径均已尝试完毕，请检查网络或手动安装。"
    return $false
}

function Backup-AllTerminalConfigurations {
    [CmdletBinding()]
    param(
        [switch]$Force
    )

    # 避免短时间内（同一安装流程中）重复备份
    if (-not $Force -and $global:LAST_TERMINAL_BACKUP_DIR -and (Test-Path $global:LAST_TERMINAL_BACKUP_DIR)) {
        return $global:LAST_TERMINAL_BACKUP_DIR
    }

    $projectRoot = Split-Path -Parent $PSScriptRoot
    if (-not (Test-Path (Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'))) {
        $projectRoot = $PSScriptRoot
    }
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path $projectRoot "backups\install-backup-$timestamp"
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }

    # 智能解析 MSYS2 .bashrc 路径
    $msys2Bashrc = Join-Path 'C:\msys64' "home\$env:USERNAME\.bashrc"
    foreach ($cand in @('C:\msys64', "$env:SystemDrive\msys64", (Join-Path $env:USERPROFILE 'scoop\apps\msys2\current'), 'C:\tools\msys64')) {
        $cPath = Join-Path $cand "home\$env:USERNAME\.bashrc"
        if (Test-Path -LiteralPath $cPath) {
            $msys2Bashrc = $cPath
            break
        }
    }

    $targets = @(
        @{
            Name = 'PowerShell7_profile.ps1'
            Path = (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1')
            Desc = 'PowerShell 7 Profile'
        },
        @{
            Name = 'WinPS51_profile.ps1'
            Path = (Join-Path $env:USERPROFILE 'Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1')
            Desc = 'Windows PowerShell 5.1 Profile'
        },
        @{
            Name = 'Terminal_stable.json'
            Path = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
            Desc = 'Windows Terminal (Stable) Settings'
        },
        @{
            Name = 'Terminal_preview.json'
            Path = (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
            Desc = 'Windows Terminal (Preview) Settings'
        },
        @{
            Name = 'clink_starship.lua'
            Path = (Join-Path $env:LOCALAPPDATA 'clink\starship.lua')
            Desc = 'Clink Starship Lua Script'
        },
        @{
            Name = 'clink_settings.lua'
            Path = (Join-Path $env:LOCALAPPDATA 'clink\settings.lua')
            Desc = 'Clink Settings Lua Script'
        },
        @{
            Name = 'starship.toml'
            Path = (Join-Path $env:USERPROFILE '.config\starship.toml')
            Desc = 'Starship Config'
        },
        @{
            Name = 'cmd_autorun.cmd'
            Path = (Join-Path $env:USERPROFILE '.config\cmd\autorun.cmd')
            Desc = 'CMD AutoRun Batch'
        },
        @{
            Name = 'fastfetch_config.jsonc'
            Path = (Join-Path $env:USERPROFILE '.config\fastfetch\config.jsonc')
            Desc = 'Fastfetch Config'
        },
        @{
            Name = 'fastfetch_ascii.txt'
            Path = (Join-Path $env:USERPROFILE '.config\fastfetch\ascii.txt')
            Desc = 'Fastfetch ASCII Banner'
        },
        @{
            Name = 'nushell_config.nu'
            Path = (Join-Path $env:APPDATA 'nushell\config.nu')
            Desc = 'NuShell Configuration (config.nu)'
        },
        @{
            Name = 'nushell_env.nu'
            Path = (Join-Path $env:APPDATA 'nushell\env.nu')
            Desc = 'NuShell Environment (env.nu)'
        },
        @{
            Name = 'nushell_starship.nu'
            Path = (Join-Path $env:APPDATA 'nushell\vendor\autoload\starship.nu')
            Desc = 'NuShell Starship Prompt Autoload'
        },
        @{
            Name = 'msys2_bashrc'
            Path = $msys2Bashrc
            Desc = 'MSYS2 Bash Configuration (.bashrc)'
        }
    )

    $manifestFiles = @()
    foreach ($item in $targets) {
        $existed = Test-Path -LiteralPath $item.Path -PathType Leaf
        $fileEntry = @{
            Name = $item.Name
            Target = $item.Path
            Desc = $item.Desc
            Existed = $existed
            SHA256 = ''
        }
        if ($existed) {
            $dest = Join-Path $backupDir $item.Name
            Copy-Item -LiteralPath $item.Path -Destination $dest -Force
            $fileEntry.SHA256 = (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash
        }
        $manifestFiles += $fileEntry
    }

    # 捕获 CMD AutoRun 注册表键
    $regKey = 'HKCU:\Software\Microsoft\Command Processor'
    $autorunVal = $null
    $autorunExisted = $false
    try {
        if (Test-Path $regKey) {
            $prop = Get-ItemProperty -Path $regKey -Name 'AutoRun' -ErrorAction SilentlyContinue
            if ($prop -and $prop.AutoRun -ne $null) {
                $autorunExisted = $true
                $autorunVal = $prop.AutoRun.ToString()
            }
        }
    } catch {}

    $manifest = @{
        Timestamp = (Get-Date -Format o)
        Files = $manifestFiles
        Registry = @{
            Key = $regKey
            Name = 'AutoRun'
            Existed = $autorunExisted
            Value = $autorunVal
        }
    }

    $manifestJson = $manifest | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath (Join-Path $backupDir 'manifest.json') -Value $manifestJson -Encoding UTF8

    # 记录最新安装备份路径
    $lastBackupFile = Join-Path $projectRoot '.last-install-backup'
    Set-Content -LiteralPath $lastBackupFile -Value $backupDir -Encoding UTF8
    $global:LAST_TERMINAL_BACKUP_DIR = $backupDir

    Write-Host "[备份] 已完成当前系统终端全量配置快照: $backupDir" -ForegroundColor Green
    Write-Host "[提示] 如需恢复，可随时运行 .\Restore-All.ps1 进行一键无损回退。" -ForegroundColor Cyan

    return $backupDir
}

