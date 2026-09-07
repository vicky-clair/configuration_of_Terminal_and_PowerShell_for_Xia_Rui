<#
.SYNOPSIS
    配置或卸载 CMD 现代化增强（UTF-8、Doskey 别名、Clink/Starship）
.DESCRIPTION
    将项目内的 cmd 配置安装至当前用户目录，并注册至当前用户 Command Processor AutoRun。
    不污染系统全局注册表，无需管理员权限，支持无损卸载。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Uninstall,
    [string]$TargetDir = "$env:USERPROFILE\.config\cmd"
)

$ErrorActionPreference = 'Stop'
$regPath = 'HKCU:\Software\Microsoft\Command Processor'
$scriptSource = Join-Path $PSScriptRoot 'autorun.cmd'
$clinkSource = Join-Path $PSScriptRoot 'clink'

if ($Uninstall) {
    if ($PSCmdlet.ShouldProcess($regPath, "Remove AutoRun registration")) {
        $current = (Get-ItemProperty -Path $regPath -Name 'AutoRun' -ErrorAction SilentlyContinue).AutoRun
        if ($current -and $current -like "*$TargetDir*") {
            Remove-ItemProperty -Path $regPath -Name 'AutoRun' -Force -ErrorAction SilentlyContinue
            Write-Host "✅ 已从当前用户注册表移除 CMD AutoRun 配置" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ 当前用户注册表未配置此 AutoRun，无需清理" -ForegroundColor DarkGray
        }
    }
    return
}

# 1. 复制配置文件至用户配置目录
if ($PSCmdlet.ShouldProcess($TargetDir, "Deploy CMD autorun script")) {
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $scriptSource -Destination (Join-Path $TargetDir 'autorun.cmd') -Force
    Write-Host "✅ 已部署: $(Join-Path $TargetDir 'autorun.cmd')" -ForegroundColor Green
}

# 2. 同步 Clink 脚本至 %LOCALAPPDATA%\clink
$clinkDestDir = "$env:LOCALAPPDATA\clink"
if (-not (Test-Path $clinkDestDir)) {
    New-Item -ItemType Directory -Path $clinkDestDir -Force | Out-Null
}
if ($PSCmdlet.ShouldProcess($clinkDestDir, "Deploy Clink Lua scripts")) {
    Get-ChildItem $clinkSource -Filter '*.lua' | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $clinkDestDir $_.Name) -Force
        Write-Host "✅ 已同步 Clink 脚本: $($_.Name) -> $clinkDestDir" -ForegroundColor Green
    }
}

# 3. 注册当前用户 AutoRun
$autoRunCommand = "if exist `"$TargetDir\autorun.cmd`" call `"$TargetDir\autorun.cmd`""
if ($PSCmdlet.ShouldProcess($regPath, "Set AutoRun to '$autoRunCommand'")) {
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name 'AutoRun' -Value $autoRunCommand -Type String -Force
    Write-Host "✅ 已注册当前用户 AutoRun: $autoRunCommand" -ForegroundColor Green
}

Write-Host "`n🎉 CMD 现代化配置安装完成！新开 cmd.exe 即可自动加载 UTF-8、别名与 Clink/Starship。" -ForegroundColor Cyan
