[CmdletBinding(SupportsShouldProcess=$true)]
param([switch]$Uninstall, [switch]$SkipBackup, [string]$TargetDir="$env:USERPROFILE\.config\cmd")
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $projectRoot 'scripts/TerminalSetupCommon.ps1')
if ($TargetDir -match '[%!^&|<>"\r\n]') { throw 'CMD configuration path contains unsupported shell characters.' }
$TargetDir=[IO.Path]::GetFullPath($TargetDir)
if ($Uninstall) {
    $pointer=Join-Path $projectRoot '.last-cmd-backup'
    if (-not (Test-Path -LiteralPath $pointer)) { throw 'No CMD uninstall snapshot. Restore an installation snapshot explicitly; AutoRun has been left intact.' }
    $backup=[IO.File]::ReadAllText($pointer).Trim()
    Restore-TerminalSnapshot -Directory $backup -CmdTargetDir $TargetDir -Components Cmd -WhatIf:$WhatIfPreference
    return
}
$template=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'autorun.cmd'))
$fastfetch=Resolve-TerminalTool 'fastfetch.exe'
$clink=Resolve-TerminalTool 'clink.exe'
if (-not $clink) {
    foreach ($root in @("$env:USERPROFILE\scoop\apps\clink\current", "${env:ProgramFiles(x86)}\clink", "$env:LOCALAPPDATA\clink")) {
        $name=if ([Environment]::Is64BitOperatingSystem) { 'clink_x64.exe' } else { 'clink_x86.exe' }
        $candidate=Join-Path $root $name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { $clink=$candidate; break }
    }
}
foreach ($path in @($clink,$fastfetch)) { if ($path -and $path -match '[%!^&|<>"\r\n]') { throw "Unsupported executable path: $path" } }
$clinkLine=if ($clink) { '"'+$clink+'" inject --autorun --quiet' } else { 'rem Clink was not found in a trusted installation directory.' }
$fetchLine=if ($fastfetch) { '"'+$fastfetch+'" 2>nul' } else { 'rem Fastfetch was not found in a trusted installation directory.' }
$template=$template.Replace('__CLINK_INIT__',$clinkLine).Replace('__FASTFETCH_INIT__',$fetchLine)
if (-not $PSCmdlet.ShouldProcess($TargetDir, 'Back up and install CMD configuration')) { return }
# Separate uninstall pointer also works when an enclosing installer owns a broader snapshot.
$null=Backup-AllTerminalConfigurations -Components Cmd -CmdTargetDir $TargetDir -PointerName '.last-cmd-backup'
Set-TerminalText (Join-Path $TargetDir 'autorun.cmd') ($template.Replace("`r`n","`n").Replace("`n","`r`n"))
$clinkDir=Join-Path $env:LOCALAPPDATA 'clink'
Set-TerminalBytes (Join-Path $clinkDir 'settings.lua') ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot 'clink/settings.lua')))
$starship=Resolve-TerminalTool 'starship.exe'
$lua='-- Starship is not installed; initialization skipped.'
if ($starship) {
    $lua=(& $starship init cmd | Out-String)
    if ($LASTEXITCODE -ne 0 -or -not $lua.Trim()) { throw 'Starship CMD initialization generation failed.' }
}
Set-TerminalText (Join-Path $clinkDir 'starship.lua') $lua
$registration='if exist "'+$TargetDir+'\autorun.cmd" call "'+$TargetDir+'\autorun.cmd"'
Set-TerminalRegistryState ([pscustomobject]@{Key='HKCU:\Software\Microsoft\Command Processor';Name='AutoRun';Existed=$true;Kind='String';Value=$registration})
Write-Host 'CMD configuration installed; previous AutoRun and scripts are recoverable with -Uninstall.'
