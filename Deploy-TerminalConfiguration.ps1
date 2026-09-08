<#
.SYNOPSIS
    生产环境终端配置原子同步与部署脚本
.DESCRIPTION
    1. 前置静默运行 tests/Verify-Configuration.ps1 静态回归校验，语法或约束不通过则阻断部署；
    2. 自动生成当前生产终端配置的前置救援快照 (.deployment-path)，保障一键无损回退；
    3. 校验目标文件哈希一致性，防止并发覆写污染；
    4. 原子部署 Windows Terminal settings.json、PowerShell 7 Profile 及 CMD 现代化配置。
.PARAMETER SkipCmd
    是否跳过 CMD Clink 与 Starship 相关配置的部署。
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$SkipCmd
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/TerminalSetupCommon.ps1')

# 1. 前置静态与语法回归测试校验
$engine = Join-Path $PSHOME 'pwsh.exe'
if (-not (Test-Path -LiteralPath $engine)) { $engine = Join-Path $PSHOME 'powershell.exe' }
& $engine -NoProfile -File (Join-Path $PSScriptRoot 'tests/Verify-Configuration.ps1')
if ($LASTEXITCODE -ne 0) { throw "部署前静态回归校验未通过 (退出码: $LASTEXITCODE)，已安全阻断部署。" }

# 2. 检查 ShouldProcess 交互确认
if (-not $PSCmdlet.ShouldProcess('PowerShell, Terminal and selected CMD configuration', 'Snapshot and deploy')) { return }

# 3. 执行前置统合备份并记录 .deployment-path 快照指针
$components = @('PowerShell7', 'Terminal')
if (-not $SkipCmd) { $components += 'Cmd' }
$snapshot = Backup-AllTerminalConfigurations -Components $components -PointerName '.deployment-path'
$targets = @(Get-TerminalTargets -Components $components)
$manifest = Read-TerminalSnapshot $snapshot

# 4. 执行文件哈希并发校验与安全原子部署
try {
    $ps = @($targets | Where-Object Name -eq 'PowerShell7_profile.ps1')[0]
    $wt = @($targets | Where-Object Name -eq 'Terminal_stable.json')[0]
    foreach ($item in @(@($ps, 'Microsoft.PowerShell_profile.ps1'), @($wt, 'settings.json'))) {
        $entry = @($manifest.Files | Where-Object Name -eq $item[0].Name)[0]
        # 并发篡改检测：校验目标文件是否存在及 SHA256 哈希是否与快照一致
        if ([IO.File]::Exists($entry.Target) -ne $entry.Existed -or ($entry.Existed -and (Get-TerminalHash $entry.Target) -ne $entry.SHA256)) {
            throw "检测到目标文件在快照后被外部并发修改: $($entry.Target)"
        }
        Set-TerminalBytes $entry.Target ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $item[1])))
    }
    if (-not $SkipCmd) {
        & (Join-Path $PSScriptRoot 'cmd/Install-CmdConfiguration.ps1') -SkipBackup
    }
    Ensure-FastfetchConfigured
} catch {
    throw "部署未完整完成，请通过以下快照执行回退: $snapshot。异常信息: $($_.Exception.Message)"
}

Write-Host "[OK] 终端配置部署完成！快照位置: $snapshot" -ForegroundColor Green
Write-Host "如需回退请运行: ./Restore-TerminalConfiguration.ps1 -IncludeCmd" -ForegroundColor Cyan
