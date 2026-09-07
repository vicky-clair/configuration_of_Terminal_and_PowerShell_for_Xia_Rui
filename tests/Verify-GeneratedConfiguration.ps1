$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $PSScriptRoot ('tmp-generated-'+[guid]::NewGuid().ToString('N'))
$saved=@{}
foreach ($name in @('USERPROFILE','LOCALAPPDATA','APPDATA','TERMINAL_SETUP_DOCUMENTS','POWERSHELL_PROFILE_MINIMAL','CMDCMDLINE')) { $saved[$name]=[Environment]::GetEnvironmentVariable($name) }
$nuCommand=Get-Command nu -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
try {
    $repo=Join-Path $fixture 'repo'
    [IO.Directory]::CreateDirectory($repo) | Out-Null
    foreach ($directory in @('scripts','cmd','fastfetch','starship')) { Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination (Join-Path $repo $directory) -Recurse -Force }
    [IO.Directory]::CreateDirectory((Join-Path $repo 'tests')) | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Verify-Configuration.ps1') -Destination (Join-Path $repo 'tests/Verify-Configuration.ps1')
    foreach ($file in @(Get-ChildItem $projectRoot -File -Filter '*.ps1') + @(Get-Item (Join-Path $projectRoot 'settings.json'))) { Copy-Item -LiteralPath $file.FullName -Destination $repo }
    $env:USERPROFILE=Join-Path $fixture 'user'
    $env:LOCALAPPDATA=Join-Path $fixture 'local'
    $env:APPDATA=Join-Path $fixture 'roaming'
    $env:TERMINAL_SETUP_DOCUMENTS=Join-Path $fixture 'Documents'
    $env:POWERSHELL_PROFILE_MINIMAL='1'
    . (Join-Path $projectRoot 'scripts/TerminalState.ps1')
    # Fixture copy uses real file transactions but mocks every installation and registry boundary.
    $mocks=@'
function Initialize-SetupEnvironment {}
function Ensure-ScoopInstalled {}
function Ensure-ScoopBuckets {}
function Install-ScoopAppsIfMissing {}
function Install-PSModulesIfMissing {}
function Install-AppWithChocoWingetFallback { return $true }
function Get-TerminalRegistryState($Spec) { [pscustomobject]@{Key=$Spec.Key;Name=$Spec.Name;Existed=$false;Value=$null;Kind='String'} }
function Set-TerminalRegistryState($State) {}
function Resolve-TerminalTool { return $null }
function Get-Command {
    param([string]$Name, $ErrorAction, $CommandType)
    if ($Name -in @('starship','zoxide')) { return $null }
    Microsoft.PowerShell.Core\Get-Command @PSBoundParameters
}
'@
    $common=Join-Path $repo 'scripts/TerminalSetupCommon.ps1'
    Set-TerminalText $common ([IO.File]::ReadAllText($common)+"`n"+$mocks) -Bom
    # The CMD fallback is disabled in fixtures to avoid injecting a real Clink process.
    $cmdInstaller=Join-Path $repo 'cmd/Install-CmdConfiguration.ps1'
    $cmdText=[IO.File]::ReadAllText($cmdInstaller).Replace('if (-not $clink) {','if ($false) {')
    Set-TerminalText $cmdInstaller $cmdText -Bom
    & (Join-Path $repo 'Install-PowerShell7.ps1') -ThemeMode Fixed -NonInteractive
    & (Join-Path $repo 'Install-WinPowerShell51.ps1')
    & (Join-Path $repo 'Install-NuShell.ps1') -NonInteractive
    foreach ($edition in @('PowerShell','WindowsPowerShell')) {
        $profile=Join-Path $env:TERMINAL_SETUP_DOCUMENTS "$edition/Microsoft.PowerShell_profile.ps1"
        $t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile($profile,[ref]$t,[ref]$e)
        Assert (-not $e) "Generated $edition profile has parse errors."
        $engine=if ($edition -eq 'PowerShell') { (Microsoft.PowerShell.Core\Get-Command pwsh -CommandType Application | Select-Object -First 1).Source } else { Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe' }
        $output=@(& $engine -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $profile)
        Assert ($LASTEXITCODE -eq 0 -and $output.Count -eq 0) 'Generated noninteractive profile was not silent.'
    }
    if ($nuCommand) {
        $config=Join-Path $env:APPDATA 'nushell/config.nu'
        $query=[IO.File]::ReadAllText($config)+"`nscope aliases | where name in [ll la lt cat] | length"
        $queryPath=Join-Path $fixture 'nu-alias-check.nu'
        Set-TerminalText $queryPath $query
        $count=& $nuCommand.Source --no-config-file $queryPath
        Assert ($LASTEXITCODE -eq 0 -and $count -eq '4') 'Generated NuShell aliases are not visible.'
    } else { Write-Host 'SKIP: NuShell executable is not installed.' }

    # Actual deployment entry and rollback routing: older installation pointer must not win.
    $live=Join-Path $env:TERMINAL_SETUP_DOCUMENTS 'PowerShell/Microsoft.PowerShell_profile.ps1'
    Set-TerminalText $live 'before deployment'
    & (Join-Path $repo 'Deploy-TerminalConfiguration.ps1') -SkipCmd
    Assert ([IO.File]::ReadAllText($live) -ne 'before deployment') 'Deployment did not apply.'
    & (Join-Path $repo 'Restore-TerminalConfiguration.ps1')
    Assert ([IO.File]::ReadAllText($live) -eq 'before deployment') 'Deployment rollback chose the installation snapshot.'

    $cmdDir=Join-Path $env:USERPROFILE '.config/cmd'
    Set-TerminalText (Join-Path $cmdDir 'autorun.cmd') 'original autorun bytes'
    & $cmdInstaller
    $cmdProfile=Join-Path $cmdDir 'autorun.cmd'
    $deployed=[IO.File]::ReadAllText($cmdProfile)
    Assert ($deployed -notmatch '__CLINK_INIT__|__FASTFETCH_INIT__') 'Unexpanded CMD placeholder.'
    # Files named like startup tools cannot be invoked from the launch directory.
    $attack=Join-Path $fixture 'untrusted-directory'
    [IO.Directory]::CreateDirectory($attack) | Out-Null
    foreach ($name in @('fastfetch','starship','chcp','doskey','findstr','where')) { Set-TerminalText (Join-Path $attack "$name.cmd") '@echo ATTACK_EXECUTED' }
    Push-Location $attack
    try {
        $env:CMDCMDLINE='cmd.exe /k'
        $output=@(& $env:ComSpec /d /c "call `"$cmdProfile`"")
        Assert (-not ($output -match 'ATTACK_EXECUTED')) 'CMD ran a program from the current directory.'
        $env:CMDCMDLINE='cmd.exe /c echo expected'
        $output=@(& $env:ComSpec /d /c "call `"$cmdProfile`"")
        Assert ($output.Count -eq 0) 'Noninteractive CMD startup produced output.'
    } finally { Pop-Location }
    # Restore-All reimports the fixture state helper: replace registry boundaries there as well.
    $state=Join-Path $repo 'scripts/TerminalState.ps1'
    $regMocks=@'
function Get-TerminalRegistryState($Spec) { [pscustomobject]@{Key=$Spec.Key;Name=$Spec.Name;Existed=$false;Value=$null;Kind='String'} }
function Set-TerminalRegistryState($State) {}
'@
    Set-TerminalText $state ([IO.File]::ReadAllText($state)+"`n"+$regMocks) -Bom
    & $cmdInstaller -Uninstall
    Assert ([IO.File]::ReadAllText($cmdProfile) -eq 'original autorun bytes') 'CMD uninstall did not restore prior content.'
    Write-Host 'PASS: real installer templates, both generated PowerShell profiles, NuShell aliases, deployment rollback routing, CMD lookup and uninstall (all external writes mocked).'
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name]) }
    $full=[IO.Path]::GetFullPath($fixture)
    $parent=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
    if (-not $full.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
