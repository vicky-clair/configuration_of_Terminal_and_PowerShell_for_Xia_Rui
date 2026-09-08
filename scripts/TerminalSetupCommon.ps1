. (Join-Path $PSScriptRoot 'TerminalState.ps1')

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

    # Do not persistently change execution policy or repository trust.

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
            $bootstrap=Join-Path ([IO.Path]::GetTempPath()) ('scoop-bootstrap-' + [guid]::NewGuid().ToString('N') + '.ps1')
            try {
                Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/ScoopInstaller/Install/1e2f334083d609986d8c8bc9e31ae8e87c39fab4/install.ps1' -UseBasicParsing -OutFile $bootstrap -TimeoutSec 30 -ErrorAction Stop
                if ((Get-TerminalHash $bootstrap) -ne '94F983B190438311E006B957DB7C8422709E0BA62A6C2AC04E278164108F2512') { throw 'Scoop bootstrap SHA256 mismatch.' }
                & (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') -NoProfile -ExecutionPolicy Bypass -File $bootstrap
                if ($LASTEXITCODE -ne 0) { throw "Scoop bootstrap failed: $LASTEXITCODE" }
            } finally { if ([IO.File]::Exists($bootstrap)) { [IO.File]::Delete($bootstrap) } }
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
    if ($LASTEXITCODE -ne 0) { throw 'Scoop bucket list failed.' }
    $installedBuckets = @($bucketListOutput | ForEach-Object {
        if ($_.PSObject.Properties['Name'] -and $_.Name) {
            $_.Name.ToString().Trim()
        } elseif ($_ -is [string]) {
            $_.Trim()
        }
    })
    $knownMirrors = @{
        'nerd-fonts' = @(
            'https://gh-proxy.com/https://github.com/matthewjberger/scoop-nerd-fonts',
            'https://gitee.com/kkzzhizhou/scoop-nerd-fonts'
        )
        'extras'     = @(
            'https://gh-proxy.com/https://github.com/ScoopInstaller/Extras',
            'https://gitee.com/scoop-bucket/extras'
        )
        'versions'   = @(
            'https://gh-proxy.com/https://github.com/ScoopInstaller/Versions'
        )
    }
    foreach ($b in $Buckets) {
        if ($installedBuckets -notcontains $b) {
            if ($b -eq 'nerd-fonts') {
                $fontMatches = @(Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter "*JetBrains*" -ErrorAction SilentlyContinue)
                if ($fontMatches.Count -gt 0) {
                    Write-Host "[OK] 系统中已检测到 JetBrains Mono 图标字体，跳过 nerd-fonts 仓库添加" -ForegroundColor DarkGray
                    continue
                }
            }
            Write-Host "[*] 正在添加 Scoop 仓库: $b..." -ForegroundColor Yellow
            $bucketAdded = $false
            try {
                & scoop bucket add $b 2>$null | Out-Host
                if ($LASTEXITCODE -eq 0) { $bucketAdded = $true }
            } catch {}

            if (-not $bucketAdded -and $knownMirrors.ContainsKey($b)) {
                foreach ($mirrorUrl in $knownMirrors[$b]) {
                    Write-Host "[*] 官方源连接受阻，尝试加速镜像添加 $b ($mirrorUrl)..." -ForegroundColor Cyan
                    try {
                        & scoop bucket add $b $mirrorUrl 2>$null | Out-Host
                        if ($LASTEXITCODE -eq 0) {
                            $bucketAdded = $true
                            Write-Host "[OK] Scoop 仓库 $b 通过镜像添加成功！" -ForegroundColor Green
                            break
                        }
                    } catch {}
                }
            }

            if (-not $bucketAdded) {
                if ($b -eq 'nerd-fonts') {
                    $fontMatches = @(Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter "*JetBrains*" -ErrorAction SilentlyContinue)
                    if ($fontMatches.Count -gt 0) {
                        Write-Warning "[!] nerd-fonts 仓库添加失败，但检测到系统中已有 JetBrains 图标字体，跳过该仓库。"
                        continue
                    }
                    Write-Warning "[!] 添加 nerd-fonts 仓库失败（国内直连 GitHub 连接重置）。"
                    Write-Warning "[!] 若您有代理软件（如 Clash/v2ray），请在终端配置: scoop config proxy 127.0.0.1:7890"
                    Write-Warning "[!] 或手动通过镜像添加: scoop bucket add nerd-fonts https://gh-proxy.com/https://github.com/matthewjberger/scoop-nerd-fonts"
                }
                throw "Cannot add Scoop bucket $b. 网络连接受阻（GitHub 连接重置），请配置代理或镜像后重试。"
            }
        } else {
            Write-Host "[OK] Scoop 仓库已添加: $b" -ForegroundColor DarkGray
        }
    }
}

function Test-SetupAppReady {
    param([string]$CommandName, [string[]]$PathCheck)
    if ($PathCheck) {
        foreach ($path in $PathCheck) {
            if (Test-Path -LiteralPath $path -PathType Leaf) { return $true }
        }
        return $false
    }
    return [bool](Get-Command $CommandName -ErrorAction SilentlyContinue)
}

function Install-ScoopAppsIfMissing {
    param([string[]]$Apps, [string[]]$PathCheck)
    if ($PathCheck -and $Apps.Count -ne 1) { throw 'Path verification requires exactly one application.' }
    Ensure-ScoopInstalled
    $listOutput = & scoop list 6>&1 2>$null
    $listText = ($listOutput -join "`n")
    # Scoop 在未安装任何软件时会执行 exit 1 并输出 There aren't any apps installed. 这是正常的空列表状态
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 1 -and $listText -notmatch "There aren't any apps installed") {
        throw 'Scoop list failed.'
    }
    $installed = @()
    if ($listText -notmatch "There aren't any apps installed") {
        $installed = @($listOutput | ForEach-Object {
            if ($_.PSObject.Properties['Name'] -and $_.Name) {
                $_.Name.ToString().Trim()
            } elseif ($_ -match '^Name\s+:\s+(.+)$') {
                $matches[1].Trim()
            }
        })
    }

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
        $commandName = switch ($baseName) { 'ripgrep' {'rg'} 'neovim' {'nvim'} 'nushell' {'nu'} default {$baseName} }

        # 特殊处理：如果是字体应用，检测系统字体目录（当前用户与全局 Windows Fonts）
        if ($baseName -match '(?i)JetBrains' -or $app -match 'nerd-fonts') {
            $fontMatches = @(Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts", "$env:WINDIR\Fonts" -Filter "*JetBrains*" -ErrorAction SilentlyContinue)
            if ($fontMatches.Count -gt 0) {
                Write-Host "[OK] 图标字体已在系统中安装就绪: $baseName ($($fontMatches.Count) 个字体变体已加载)" -ForegroundColor DarkGray
                continue
            }
        }

        # 检查是否已通过外部途径（如 WinGet / MSI / 系统自带）安装
        if (Test-SetupAppReady $commandName $PathCheck) {
            Write-Host "[OK] 应用已就绪: $baseName" -ForegroundColor DarkGray
            continue
        }

        if ($installed -notcontains $baseName) {
            Write-Host "[*] 正在安装 Scoop 应用: $app..." -ForegroundColor Yellow
            $scoopSuccess = $false
            try {
                & scoop install $app | Out-Host
                if ($LASTEXITCODE -eq 0) {
                    $scoopSuccess = $true
                }
            } catch {
                Write-Warning "Scoop 安装 $app 遇到提示: $_"
            }

            # 若 Scoop 安装遇阻且该工具在 WinGet 中存在，自动尝试 WinGet 容错兜底
            if (-not $scoopSuccess -and -not (Test-SetupAppReady $commandName $PathCheck)) {
                if ($wingetFallbackMap.ContainsKey($baseName)) {
                    $wingetId = $wingetFallbackMap[$baseName]
                    Write-Host "[*] 启动 WinGet 智能容错兜底: 正在通过 WinGet 安装 $baseName ($wingetId)..." -ForegroundColor Cyan
                    if (Ensure-WingetConfigured) {
                        try {
                            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                            $wPath = if ($wingetCmd) { $wingetCmd.Source } else { "winget" }
                            $proc = Start-Process -FilePath $wPath -ArgumentList "install", "--id", $wingetId, "--exact", "--accept-source-agreements", "--accept-package-agreements", "--silent" -NoNewWindow -PassThru -Wait
                            if ($proc.ExitCode -in @(0, -1978335189)) {
                                $scoopSuccess = $true
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
            if (-not $scoopSuccess) { throw "Unable to install required application: $app" }
            Refresh-SessionPath
            if ($app -notmatch 'nerd-fonts' -and -not (Test-SetupAppReady $commandName $PathCheck)) { throw "Installed app is not executable: $commandName" }
        } else {
            Refresh-SessionPath
            if ($app -notmatch 'nerd-fonts' -and -not (Test-SetupAppReady $commandName $PathCheck)) {
                throw "Scoop lists $app as installed, but $commandName is not executable after refreshing PATH. Repair the installation or its shims before retrying."
            }
            Write-Host "[OK] 应用已安装: $app" -ForegroundColor DarkGray
        }
    }
}

function Install-PSModulesIfMissing {
    param([string[]]$Modules, [ValidateSet('Current','Core','Desktop')][string]$Edition='Current')

    if ($Edition -ne 'Current' -and $Edition -ne $PSVersionTable.PSEdition) {
        $engine=if ($Edition -eq 'Core') { (Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
                else { Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe' }
        & $engine -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Install-RequiredModules.ps1') -ModuleNames ($Modules -join ',')
        if ($LASTEXITCODE -ne 0) { throw "Module installation in $Edition failed: $LASTEXITCODE" }
        return
    }
    $versions=@{PSReadLine='2.4.5';'Terminal-Icons'='0.11.0';PSFzf='2.7.3'}

    # Keep the user's PSGallery trust policy and publisher checks intact.
    $gallery=Get-PSRepository -Name PSGallery -ErrorAction Stop
    if ($gallery.SourceLocation.TrimEnd('/') -ne 'https://www.powershellgallery.com/api/v2') { throw 'PSGallery source URL is not the official endpoint.' }
    foreach ($mod in $Modules) {
        if (-not $versions.ContainsKey($mod)) { throw "Module is not in the tested version list: $mod" }
        $version=$versions[$mod]
        if (-not @(Get-Module -ListAvailable -Name $mod | Where-Object Version -eq ([version]$version)).Count) {
            Install-Module -Name $mod -RequiredVersion $version -Repository PSGallery -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
            if (-not @(Get-Module -ListAvailable -Name $mod | Where-Object Version -eq ([version]$version)).Count) { throw "Module installation failed: $mod" }
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
                Set-TerminalBytes $target ([IO.File]::ReadAllBytes($sourceSettings))
                Write-Host "[OK] Windows Terminal 深度美化配置 (亚克力磨砂/Catppuccin配色/JetBrainsMono字体) 已部署至: $target" -ForegroundColor Green
            }
        }
    }
}

function Register-TerminalShellProfile {
    param([ValidateSet('NuShell','MSYS2')][string]$Shell, [string]$Msys2InstallPath)
    $msysGuids=@(
        '{17da3cac-b318-431e-8a3e-7fcdefe6d114}', '{71160544-14d8-4194-af25-d05feeac7233}',
        '{2d51fdc4-a03b-4efe-81bc-722b7f6f3820}', '{16d4cd58-c9b9-4c8f-8e9e-9b7c4d8f3e2a}',
        '{5e3c2b8f-9d4e-4a7b-8c3d-1f2e3a4b5c6d}'
    )
    $nuGuid='{a3f9c1e2-7b4d-4f6a-9c2d-1e5b8f3a7d6c}'
    $msysCommand=if ($Shell -eq 'MSYS2') { Join-Path ([IO.Path]::GetFullPath($Msys2InstallPath)) 'msys2_shell.cmd' }
    foreach ($target in @(Get-TerminalTargets -Components Terminal)) {
        $path=$target.Target
        if (-not (Test-Path -LiteralPath $path)) { continue }
        try {
            $json=[IO.File]::ReadAllText($path) | ConvertFrom-Json -ErrorAction Stop
            if ($json -isnot [pscustomobject]) { throw 'Expected a settings object.' }
            if (-not $json.PSObject.Properties['profiles']) { $json | Add-Member NoteProperty profiles ([pscustomobject]@{}) }
            if ($json.profiles -isnot [pscustomobject]) { throw 'Expected a profiles object.' }
            if (-not $json.profiles.PSObject.Properties['list']) { $json.profiles | Add-Member NoteProperty list @() }
            if ($json.profiles.list -isnot [array]) { throw 'Expected profiles.list to be an array.' }
            $found=$false; $changed=$false
            foreach ($profile in $json.profiles.list) {
                $exe=''; $arguments=''
                if ([string]$profile.commandline -match '^\s*(?:"(?<exe>[^"]+)"|(?<exe>\S+))(?<arguments>.*)$') {
                    $exe=$Matches.exe; $arguments=$Matches.arguments
                }
                $base=[IO.Path]::GetFileName($exe.Replace('/','\'))
                if ($Shell -eq 'NuShell') {
                    if ($base -in @('nu','nu.exe') -or $profile.guid -eq $nuGuid) { $found=$true }
                } elseif ($base -eq 'msys2_shell.cmd') {
                    if ($profile.guid -in $msysGuids) {
                        # Only the executable changes; keep shell flags, names, icons and appearance.
                        $command='"'+$msysCommand+'"'+$arguments
                        if ($profile.commandline -cne $command) { $profile.commandline=$command; $changed=$true }
                        $found=$true
                    } elseif ([Environment]::ExpandEnvironmentVariables($exe).Replace('/','\') -eq $msysCommand) {
                        $found=$true
                    }
                }
            }
            if (-not $found) {
                $guid=if ($Shell -eq 'NuShell') { $nuGuid } else { $msysGuids[3] }
                if (@($json.profiles.list | Where-Object guid -eq $guid).Count) { throw "Shell profile GUID is occupied by a different command: $guid" }
                $profile=[pscustomobject]@{
                    guid=$guid
                    name=$(if ($Shell -eq 'NuShell') { 'NuShell' } else { 'MSYS2 UCRT64' })
                    commandline=$(if ($Shell -eq 'NuShell') { 'nu.exe' } else { '"'+$msysCommand+'" -defterm -here -no-start -ucrt64' })
                    startingDirectory='%USERPROFILE%'
                    hidden=$false
                }
                $json.profiles.list=@($json.profiles.list)+@($profile)
                $changed=$true
            }
            if ($changed) { Set-TerminalText $path ($json | ConvertTo-Json -Depth 100) }
            Write-Host "[OK] Windows Terminal $Shell 启动入口已就绪: $path" -ForegroundColor Green
        } catch { throw "Windows Terminal $Shell registration failed ($path): $($_.Exception.Message)" }
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
                $found = @(Get-ChildItem -LiteralPath $cand -File -Filter '*.omp.json' -ErrorAction SilentlyContinue)
                if ($found.Count -gt 0) {
                    Write-Host "[*] 正在从 $cand 同步内置主题至 $themesPath..." -ForegroundColor Yellow
                    foreach ($theme in $found) {
                        $destination=Join-Path $themesPath $theme.Name
                        if (-not (Test-Path -LiteralPath $destination)) { Set-TerminalBytes $destination ([IO.File]::ReadAllBytes($theme.FullName)) }
                    }
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
            Set-TerminalBytes (Join-Path $targetFastfetchDir 'ascii.txt') ([IO.File]::ReadAllBytes($asciiSrc))
        }
        if (Test-Path $configSrc) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            $configContent = [System.IO.File]::ReadAllText($configSrc, $utf8NoBom)
            $portablePath = "$($env:USERPROFILE.Replace('\', '/'))/.config/fastfetch/ascii.txt"
            $configContent = $configContent -replace '"source":\s*".*?"', "`"source`": `"$portablePath`""
            Set-TerminalText (Join-Path $targetFastfetchDir 'config.jsonc') $configContent
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
        Set-TerminalBytes $targetStarshipFile ([IO.File]::ReadAllBytes($starshipSource))
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
        if ($LASTEXITCODE -ne 0) { throw 'WinGet source update failed.' }
        Write-Host "[OK] WinGet 软件源仓库配置就绪" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "[!] 配置 WinGet 仓库源时遇到提示: $_"
        return $false
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
        [string[]]$PathCheck
    )

    Initialize-SetupEnvironment

    # 1. 检查应用是否已经就绪
    if ($CommandCheck -and (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) {
        Write-Host "[OK] $Name 已就绪 ($((Get-Command $CommandCheck).Source))" -ForegroundColor DarkGray
        return $true
    }
    if ($PathCheck -and (Test-SetupAppReady -PathCheck $PathCheck)) {
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
        if ($CommandCheck -and -not (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) { throw "Chocolatey reported success but $CommandCheck is missing." }
        if ($PathCheck -and -not (Test-SetupAppReady -PathCheck $PathCheck)) { throw "Chocolatey reported success but the expected executable is missing: $PathCheck" }
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
                if ($CommandCheck -and -not (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) { throw "WinGet reported success but $CommandCheck is missing." }
                if ($PathCheck -and -not (Test-SetupAppReady -PathCheck $PathCheck)) { throw "WinGet reported success but the expected executable is missing: $PathCheck" }
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
            Install-ScoopAppsIfMissing -Apps @($ScoopId) -PathCheck $PathCheck
            Refresh-SessionPath
            if ($CommandCheck -and -not (Get-Command $CommandCheck -ErrorAction SilentlyContinue)) { throw "Missing command: $CommandCheck" }
            if ($PathCheck -and -not (Test-SetupAppReady -PathCheck $PathCheck)) { throw "Missing installed executable: $PathCheck" }
            return $true
        } catch {
            Write-Warning "[!] [Scoop] 安装 $Name 失败: $_"
        }
    }

    Write-Warning "[!] 应用 $Name 所有安装途径均已尝试完毕，请检查网络或手动安装。"
    throw "All installation methods failed for $Name."
}

function Backup-AllTerminalConfigurations {
    [CmdletBinding()]
    param([switch]$Force, [string]$Msys2InstallPath, [string[]]$Components=@('All'),
          [string]$CmdTargetDir, [string]$PointerName='.last-install-backup')
    $projectRoot=Split-Path -Parent $PSScriptRoot
    $backupDir=Join-Path $projectRoot ('backups/install-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N'))
    $targets=@(Get-TerminalTargets -Msys2InstallPath $Msys2InstallPath -Components $Components -CmdTargetDir $CmdTargetDir)
    $null=New-TerminalSnapshot -Directory $backupDir -Targets $targets -RegistrySpecs @(Get-TerminalRegistrySpecs $Components)
    if ($PointerName -eq '.last-install-backup') {
        $msysRoot=if (@($targets | Where-Object Name -eq 'msys2_bashrc').Count) { Resolve-TerminalMsysRoot $Msys2InstallPath } else { $null }
        Save-TerminalInstallContext -Directory $backupDir -Msys2InstallPath $msysRoot
    }
    # Each top-level operation owns its snapshot; nested installers explicitly skip backup.
    Set-TerminalText (Join-Path $projectRoot $PointerName) $backupDir
    Write-Host "Snapshot: $backupDir"
    return $backupDir
}
