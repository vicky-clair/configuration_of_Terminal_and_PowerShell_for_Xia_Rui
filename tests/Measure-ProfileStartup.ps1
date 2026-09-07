param([ValidateSet('defaults','minimal','full')][string]$Mode='defaults', [int]$Iteration=1)
$env:TERM='xterm-256color'
$env:POWERSHELL_THEME_MODE='fixed'
$env:POWERSHELL_PROFILE_MINIMAL=if ($Mode -eq 'minimal') { '1' } else { '0' }
foreach ($name in @('POWERSHELL_PROFILE_VFOX','POWERSHELL_PROFILE_ICONS','POWERSHELL_PROFILE_BANNER','POWERSHELL_PROFILE_TIPS')) {
    [Environment]::SetEnvironmentVariable($name, $(if ($Mode -eq 'full') { '1' } else { '0' }))
}
$Error.Clear()
$watch=[Diagnostics.Stopwatch]::StartNew()
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'Microsoft.PowerShell_profile.ps1')
$watch.Stop()
$record=[pscustomobject]@{Mode=$Mode;Iteration=$Iteration;ProfileMs=[math]::Round($watch.Elapsed.TotalMilliseconds,2);InputRedirected=[Console]::IsInputRedirected;OutputRedirected=[Console]::IsOutputRedirected;ErrorCount=$Error.Count}
$directory=Join-Path $PSScriptRoot 'tmp-startup-metrics'
[IO.Directory]::CreateDirectory($directory) | Out-Null
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $directory "$Mode-$Iteration.json")
$record | ConvertTo-Json -Compress
