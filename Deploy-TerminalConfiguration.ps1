[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$SkipCmd)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'scripts/TerminalSetupCommon.ps1')
$engine=Join-Path $PSHOME 'pwsh.exe'
if (-not (Test-Path -LiteralPath $engine)) { $engine=Join-Path $PSHOME 'powershell.exe' }
& $engine -NoProfile -File (Join-Path $PSScriptRoot 'tests/Verify-Configuration.ps1')
if ($LASTEXITCODE -ne 0) { throw "Configuration verification failed: $LASTEXITCODE" }
if (-not $PSCmdlet.ShouldProcess('PowerShell, Terminal and selected CMD configuration', 'Snapshot and deploy')) { return }
$components=@('PowerShell7','Terminal')
if (-not $SkipCmd) { $components += 'Cmd' }
$snapshot=Backup-AllTerminalConfigurations -Components $components -PointerName '.deployment-path'
$targets=@(Get-TerminalTargets -Components $components)
$manifest=Read-TerminalSnapshot $snapshot
try {
    $ps=@($targets | Where-Object Name -eq 'PowerShell7_profile.ps1')[0]
    $wt=@($targets | Where-Object Name -eq 'Terminal_stable.json')[0]
    foreach ($item in @(@($ps,'Microsoft.PowerShell_profile.ps1'),@($wt,'settings.json'))) {
        $entry=@($manifest.Files | Where-Object Name -eq $item[0].Name)[0]
        if ([IO.File]::Exists($entry.Target) -ne $entry.Existed -or ($entry.Existed -and (Get-TerminalHash $entry.Target) -ne $entry.SHA256)) { throw "Concurrent edit: $($entry.Target)" }
        Set-TerminalBytes $entry.Target ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $item[1])))
    }
    if (-not $SkipCmd) { & (Join-Path $PSScriptRoot 'cmd/Install-CmdConfiguration.ps1') -SkipBackup }
} catch { throw "Deployment incomplete. Restore the verified snapshot at $snapshot. $($_.Exception.Message)" }
Write-Host "Deployment completed. Snapshot: $snapshot"
Write-Host 'Rollback: ./Restore-TerminalConfiguration.ps1 -IncludeCmd (omit -IncludeCmd to preserve CMD).'
