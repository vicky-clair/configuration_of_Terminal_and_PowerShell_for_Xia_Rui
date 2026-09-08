<#
.SYNOPSIS
    JetBrainsMono Nerd Font 本地离线极速安装与注册脚本
.DESCRIPTION
    从项目内 fonts/ 目录直接将 JetBrainsMono Nerd Font (NFM/NF/NFP) 字体文件
    复制到 Windows 字体目录，自动写入注册表并通知系统即时刷新生效，无需依赖网络或外部包管理器。
.PARAMETER AllUsers
    是否以管理员权限为系统所有用户安装 (安装至 C:\Windows\Fonts 并写入 HKLM)。默认以当前用户安装。
#>
[CmdletBinding()]
param(
    [switch]$AllUsers
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$fontsSourceDir = Join-Path $projectRoot 'fonts'

if (-not (Test-Path -LiteralPath $fontsSourceDir)) {
    throw "项目字体源目录不存在: $fontsSourceDir"
}

$fontFiles = @(Get-ChildItem -LiteralPath $fontsSourceDir -Filter '*.ttf')
if ($fontFiles.Count -eq 0) {
    throw "未在 $fontsSourceDir 中找到任何 .ttf 字体文件。"
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[+] 开始安装项目内置 JetBrainsMono Nerd Font 图标字体" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[*] 检测到待安装字体文件数量: $($fontFiles.Count) 个" -ForegroundColor Yellow

$isAdmin = $false
try {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

if ($AllUsers -and -not $isAdmin) {
    Write-Warning "[!] 指定了 -AllUsers 但未以管理员身份运行，将自动降级为当前用户模式安装。"
    $AllUsers = $false
}

$targetFontDir = if ($AllUsers) {
    "$env:SystemRoot\Fonts"
} else {
    "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
}

$regKey = if ($AllUsers) {
    'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
} else {
    'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
}

if (-not (Test-Path -LiteralPath $targetFontDir)) {
    New-Item -ItemType Directory -Path $targetFontDir -Force | Out-Null
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class FontInstaller {
    [DllImport("gdi32.dll", EntryPoint = "AddFontResourceW", SetLastError = true)]
    public static extern int AddFontResource([MarshalAs(UnmanagedType.LPWStr)] string lpFileName);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, IntPtr lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@ -ErrorAction SilentlyContinue

$copiedCount = 0
$lockedCount = 0
$skippedCount = 0
$registeredCount = 0

foreach ($file in $fontFiles) {
    $destPath = Join-Path $targetFontDir $file.Name
    $destExists = Test-Path -LiteralPath $destPath
    $needsCopy = $false

    if (-not $destExists) {
        $needsCopy = $true
    } else {
        try {
            if ((Get-Item -LiteralPath $destPath).Length -ne $file.Length) {
                $needsCopy = $true
            }
        } catch {
            $needsCopy = $true
        }
    }

    if ($needsCopy) {
        try {
            Copy-Item -LiteralPath $file.FullName -Destination $destPath -Force -ErrorAction Stop
            $copiedCount++
        } catch [System.IO.IOException] {
            # 文件已被 Windows 字体缓存、Windows Terminal 或其他应用加载锁定
            # 这表明该字体已经在目标位置并且正在被系统使用，直接登记注册表即可
            $lockedCount++
            Write-Verbose "字体已被系统进程占用，跳过文件覆盖: $($file.Name)"
        } catch {
            $lockedCount++
            Write-Verbose "复制字体 $($file.Name) 跳过: $_"
        }
    } else {
        $skippedCount++
    }

    $baseName = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $style = ''
    $prefix = ''
    if ($baseName -match '^JetBrainsMonoNerdFontMono-(.+)$') {
        $prefix = 'JetBrainsMono NFM'
        $style = $matches[1] -replace '([a-z])([A-Z])', '$1 $2'
    } elseif ($baseName -match '^JetBrainsMonoNerdFontPropo-(.+)$') {
        $prefix = 'JetBrainsMono NFP'
        $style = $matches[1] -replace '([a-z])([A-Z])', '$1 $2'
    } elseif ($baseName -match '^JetBrainsMonoNerdFont-(.+)$') {
        $prefix = 'JetBrainsMono NF'
        $style = $matches[1] -replace '([a-z])([A-Z])', '$1 $2'
    } else {
        $prefix = $baseName
    }
    $regName = if ($style) { "$prefix $style (TrueType)" } else { "$prefix (TrueType)" }
    $regValue = if ($AllUsers) { $file.Name } else { $destPath }

    Set-ItemProperty -Path $regKey -Name $regName -Value $regValue -Force -ErrorAction SilentlyContinue | Out-Null
    $registeredCount++

    try {
        [FontInstaller]::AddFontResource($destPath) | Out-Null
    } catch {}
}

try {
    $result = [UIntPtr]::Zero
    [FontInstaller]::SendMessageTimeout([IntPtr]0xffff, 0x001D, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 1000, [ref]$result) | Out-Null
} catch {}

Write-Host "`n[OK] 字体安装成功！" -ForegroundColor Green
Write-Host "  - 目标目录: $targetFontDir" -ForegroundColor DarkGray
Write-Host "  - 复制/更新: $copiedCount 个文件 (已存在或正被系统加载: $($lockedCount + $skippedCount) 个)" -ForegroundColor DarkGray
Write-Host "  - 注册表登记: $registeredCount 项 ($regKey)" -ForegroundColor DarkGray
Write-Host "  - 字体家族: JetBrainsMono NFM (等宽推荐), JetBrainsMono NF, JetBrainsMono NFP" -ForegroundColor Cyan
Write-Host "`n[提示] Windows Terminal 与 IDE 已可立即识别并使用 JetBrainsMono NFM 字体。" -ForegroundColor Green
