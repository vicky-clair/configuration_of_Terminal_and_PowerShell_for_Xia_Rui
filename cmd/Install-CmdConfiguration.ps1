<#
.SYNOPSIS
    CMD (命令提示符) 运行环境与 AutoRun 注册表深度配置脚本
.DESCRIPTION
    负责自动化部署 CMD 现代化环境核心资产：
    1. 注入 Clink 行编辑与自动补全引擎；
    2. 配置 Starship 提示符与 Clink settings.lua；
    3. 组装 autorun.cmd 挂载启动脚本；
    4. 写入当前用户注册表 (HKCU:\Software\Microsoft\Command Processor\AutoRun) 自动化载入；
    5. 支持 -Uninstall 模式依据 .last-cmd-backup 干净回退。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Uninstall,
    [switch]$SkipBackup,
    [string]$TargetDir = "$env:USERPROFILE\.config\cmd"
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $projectRoot 'scripts/TerminalSetupCommon.ps1')

# 校验目标路径安全性，防止包含命令注入特殊字符
if ($TargetDir -match '[%!^&|<>"\r\n]') { throw 'CMD configuration path contains unsupported shell characters.' }
$TargetDir = [IO.Path]::GetFullPath($TargetDir)

# 1. 卸载/回退模式
if ($Uninstall) {
    $pointer = Join-Path $projectRoot '.last-cmd-backup'
    if (-not (Test-Path -LiteralPath $pointer)) {
        throw '未找到 CMD 卸载快照。请显式指定安装快照还原；AutoRun 保持原样未动。'
    }
    $backup = [IO.File]::ReadAllText($pointer).Trim()
    Restore-TerminalSnapshot -Directory $backup -CmdTargetDir $TargetDir -Components Cmd -WhatIf:$WhatIfPreference
    Write-Host "[OK] CMD 现代化配置已恢复为原始状态。" -ForegroundColor Green
    return
}

# 2. 定位受信任可执行文件路径 (Clink, Fastfetch)
$template = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'autorun.cmd'))
$fastfetch = Resolve-TerminalTool 'fastfetch.exe'
$clink = Resolve-TerminalTool 'clink.exe'
if (-not $clink) {
    foreach ($root in @("$env:USERPROFILE\scoop\apps\clink\current", "${env:ProgramFiles(x86)}\clink", "$env:LOCALAPPDATA\clink")) {
        $name = if ([Environment]::Is64BitOperatingSystem) { 'clink_x64.exe' } else { 'clink_x86.exe' }
        $candidate = Join-Path $root $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $clink = $candidate; break }
    }
}
foreach ($path in @($clink, $fastfetch)) {
    if ($path -and $path -match '[%!^&|<>"\r\n]') { throw "Unsupported executable path: $path" }
}

# 3. 动态组装 autorun.cmd 模版中的初始化行
$clinkLine = if ($clink) { '"' + $clink + '" inject --autorun --quiet' } else { 'rem Clink was not found in a trusted installation directory.' }
$fetchLine = if ($fastfetch) { '"' + $fastfetch + '" 2>nul' } else { 'rem Fastfetch was not found in a trusted installation directory.' }
$template = $template.Replace('__CLINK_INIT__', $clinkLine).Replace('__FASTFETCH_INIT__', $fetchLine)

if (-not $PSCmdlet.ShouldProcess($TargetDir, 'Back up and install CMD configuration')) { return }

# 4. 执行前置备份 (记录独立卸载指针 .last-cmd-backup)
$null = Backup-AllTerminalConfigurations -Components Cmd -CmdTargetDir $TargetDir -PointerName '.last-cmd-backup'

# 5. 写入 autorun.cmd 文件
Set-TerminalText (Join-Path $TargetDir 'autorun.cmd') ($template.Replace("`r`n", "`n").Replace("`n", "`r`n"))

# 6. 配置 Clink Lua 脚本 (settings.lua 与 Starship 提示符集成)
$clinkDir = Join-Path $env:LOCALAPPDATA 'clink'
Set-TerminalBytes (Join-Path $clinkDir 'settings.lua') ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'clink/settings.lua')))

$starship = Resolve-TerminalTool 'starship.exe'
$lua = '-- Starship is not installed; initialization skipped.'
if ($starship) {
    $lua = (& $starship init cmd | Out-String)
    if ($LASTEXITCODE -ne 0 -or -not $lua.Trim()) { throw 'Starship CMD initialization generation failed.' }
}
Set-TerminalText (Join-Path $clinkDir 'starship.lua') $lua

# 7. 注册当前用户 AutoRun 启动项 (免管理员权限)
$registration = 'if exist "' + $TargetDir + '\autorun.cmd" call "' + $TargetDir + '\autorun.cmd"'
Set-TerminalRegistryState ([pscustomobject]@{
    Key     = 'HKCU:\Software\Microsoft\Command Processor'
    Name    = 'AutoRun'
    Existed = $true
    Kind    = 'String'
    Value   = $registration
})

Write-Host '[OK] CMD 现代化配置安装就绪；原始 AutoRun 与配置已完整备份，可随时通过 -Uninstall 干净回退。' -ForegroundColor Green
