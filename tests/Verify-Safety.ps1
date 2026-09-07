$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$testRoot=Join-Path $PSScriptRoot ('tmp-safety-'+[guid]::NewGuid().ToString('N'))
$environment=@{}
foreach ($name in @('USERPROFILE','LOCALAPPDATA','APPDATA','TERMINAL_SETUP_DOCUMENTS','PATH','POSH_THEMES_PATH','POWERSHELL_PROFILE_MINIMAL')) { $environment[$name]=[Environment]::GetEnvironmentVariable($name) }
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Fails([scriptblock]$Action,[string]$Pattern) {
    $failed=$false
    try { & $Action } catch { if ($_.Exception.Message -notlike $Pattern) { throw }; $failed=$true }
    Assert $failed "Expected failure: $Pattern"
}
try {
    $env:USERPROFILE=Join-Path $testRoot 'user'
    $env:LOCALAPPDATA=Join-Path $testRoot 'local'
    $env:APPDATA=Join-Path $testRoot 'roaming'
    $env:TERMINAL_SETUP_DOCUMENTS=Join-Path $testRoot 'redirected-documents'
    [IO.Directory]::CreateDirectory($testRoot) | Out-Null
    . (Join-Path $projectRoot 'scripts/TerminalSetupCommon.ps1')
    # No test writes to HKCU: these two boundaries emulate registry values and their types.
    $script:registry=@{}
    function Get-TerminalRegistryState($Spec) {
        $id="$($Spec.Key)|$($Spec.Name)"
        if ($script:registry.ContainsKey($id)) { return $script:registry[$id] }
        return [pscustomobject]@{Key=$Spec.Key;Name=$Spec.Name;Existed=$false;Value=$null;Kind='String'}
    }
    function Set-TerminalRegistryState($State) { $script:registry["$($State.Key)|$($State.Name)"]=$State }
    $msys=Join-Path $testRoot 'custom-msys'
    $targets=@(Get-TerminalTargets -Msys2InstallPath $msys)
    Assert ($targets.Count -eq 19) 'Incomplete backup target inventory.'
    Assert (@($targets | Where-Object Name -eq 'nushell_zoxide.nu').Count -eq 1) 'zoxide backup missing.'
    Assert (@($targets | Where-Object Target -like "$msys*").Count -eq 5) 'MSYS root/ini coverage missing.'
    $ps=@($targets | Where-Object Name -eq 'PowerShell7_profile.ps1')[0]
    $nu=@($targets | Where-Object Name -eq 'nushell_zoxide.nu')[0]
    Assert ($ps.Target.StartsWith($env:TERMINAL_SETUP_DOCUMENTS)) 'Redirected Documents not used.'
    Set-TerminalText $ps.Target 'original profile'
    $auto=[pscustomobject]@{Key='HKCU:\Software\Microsoft\Command Processor';Name='AutoRun';Existed=$true;Value='';Kind='ExpandString'}
    Set-TerminalRegistryState $auto
    $snapshot=Join-Path $testRoot 'snapshot'
    $null=New-TerminalSnapshot -Directory $snapshot -Targets $targets -RegistrySpecs @(Get-TerminalRegistrySpecs)
    Set-TerminalText $ps.Target 'later edit'
    Set-TerminalText $nu.Target 'later added file'
    Restore-TerminalSnapshot -Directory $snapshot -Msys2InstallPath $msys -WhatIf
    Assert ([IO.File]::ReadAllText($ps.Target) -eq 'later edit') 'WhatIf changed data.'
    Assert (@(Get-ChildItem $snapshot -Directory -Filter 'pre-rollback-*').Count -eq 0) 'WhatIf created a rescue.'
    Restore-TerminalSnapshot -Directory $snapshot -Msys2InstallPath $msys
    Assert ([IO.File]::ReadAllText($ps.Target) -eq 'original profile') 'Restore failed.'
    Assert (-not [IO.File]::Exists($nu.Target)) 'New file not removed.'
    $rescue=@(Get-ChildItem $snapshot -Directory -Filter 'pre-rollback-*')[0].FullName
    Assert ([IO.File]::ReadAllText((Join-Path $rescue $ps.Name)) -eq 'later edit') 'Later edit not rescued.'
    Assert ([IO.File]::ReadAllText((Join-Path $rescue $nu.Name)) -eq 'later added file') 'New file not rescued.'
    $restored=Get-TerminalRegistryState $auto
    Assert ($restored.Existed -and $restored.Value -ceq '' -and $restored.Kind -eq 'ExpandString') 'Empty expandable registry value not preserved.'
    Restore-TerminalSnapshot -Directory $rescue -Msys2InstallPath $msys
    Assert ([IO.File]::ReadAllText($nu.Target) -eq 'later added file') 'Rescue snapshot was not restorable.'

    $manifestPath=Join-Path $snapshot 'manifest.json'
    $originalManifest=[IO.File]::ReadAllText($manifestPath)
    $bad=$originalManifest | ConvertFrom-Json
    $bad.Files[0].Target=Join-Path $testRoot 'outside-allowlist.txt'
    Set-TerminalText $manifestPath ($bad | ConvertTo-Json -Depth 8)
    Assert-Fails { Restore-TerminalSnapshot -Directory $snapshot -Msys2InstallPath $msys } '*Invalid snapshot target*'
    Set-TerminalText $manifestPath $originalManifest
    Set-TerminalText (Join-Path $snapshot $ps.Name) 'corrupt backup'
    Assert-Fails { Restore-TerminalSnapshot -Directory $snapshot -Msys2InstallPath $msys } '*SHA256*'
    Assert ([IO.File]::ReadAllText($ps.Target) -eq 'later edit') 'Preflight failure changed live content.'
    Set-TerminalText (Join-Path $snapshot $ps.Name) 'original profile'
    $bad=$originalManifest | ConvertFrom-Json
    $bad.Registry[0].Key='HKCU:\Unrelated'
    Set-TerminalText $manifestPath ($bad | ConvertTo-Json -Depth 8)
    Assert-Fails { Restore-TerminalSnapshot -Directory $snapshot -Msys2InstallPath $msys } '*Invalid snapshot registry*'
    Set-TerminalText $manifestPath $originalManifest

    # Atomic replacement must leave original bytes intact while a reader denies write/delete sharing.
    $locked=Join-Path $testRoot 'locked.txt'
    Set-TerminalText $locked 'keep me'
    $handle=[IO.File]::Open($locked,'Open','Read','Read')
    try { Assert-Fails { Set-TerminalText $locked 'replacement' } '*' }
    finally { $handle.Dispose() }
    Assert ([IO.File]::ReadAllText($locked) -eq 'keep me') 'Atomic write truncated a locked file.'
    Set-TerminalText $locked ''
    Assert ((Get-Item $locked).Length -eq 0) 'Empty file replacement failed.'

    # Test real package failure propagation with all external installation boundaries replaced.
    & {
        function Initialize-SetupEnvironment {}
        function Ensure-ScoopBuckets {}
        function Ensure-ScoopInstalled {}
        function Ensure-WingetConfigured { return $false }
        function Refresh-SessionPath {}
        function Get-Command { return $null }
        function scoop { if ($args[0] -eq 'list') { $global:LASTEXITCODE=0 } else { $global:LASTEXITCODE=1 } }
        Assert-Fails { Install-AppWithChocoWingetFallback -Name test -ChocoId test -WingetId test -ScoopId test -CommandCheck test } '*All installation methods failed*'
    }
    $source=Join-Path $testRoot 'themes'
    [IO.Directory]::CreateDirectory($source) | Out-Null
    Set-TerminalText (Join-Path $source 'catppuccin_mocha.omp.json') '{}'
    $env:POSH_THEMES_PATH=$source
    $count=Ensure-OhMyPoshThemes
    Assert ($count -gt 0) 'Theme copying still fails.'

    # Minimal and noninteractive loads must not discover tools, import modules or spawn children.
    $env:POWERSHELL_PROFILE_MINIMAL='1'
    . (Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1')
    & {
        function Get-Command { throw 'Unexpected tool discovery in minimal mode' }
        function Import-Module { throw 'Unexpected module import in minimal mode' }
        . (Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1')
    }
    $engine=if ($PSVersionTable.PSEdition -eq 'Core') { Join-Path $PSHOME 'pwsh.exe' } else { Join-Path $PSHOME 'powershell.exe' }
    $watch=[Diagnostics.Stopwatch]::StartNew()
    Assert-Fails { Invoke-ProfileProcess $engine @('-NoProfile','-Command','Start-Sleep -Seconds 10') -TimeoutMs 100 } '*timed out*'
    Assert ($watch.Elapsed.TotalSeconds -lt 4) 'Timeout did not bound child process wait.'
    $argTest=Join-Path $testRoot 'argument test.ps1'
    Set-TerminalText $argTest 'param([string]$Value) Write-Output $Value'
    $value='a space "quote" and slash\'
    $echo=Invoke-ProfileProcess $engine @('-NoProfile','-File',$argTest,'-Value',$value) -TimeoutMs 3000
    Assert ($echo.Trim() -ceq $value) 'Native argument quoting failed.'
    Write-Host "PASS: modern rescue/restore, preflight security, registry types, atomic writes, failed installs, themes, minimal startup and process timeout ($($PSVersionTable.PSVersion))."
} finally {
    foreach ($name in $environment.Keys) { [Environment]::SetEnvironmentVariable($name,$environment[$name]) }
    $full=[IO.Path]::GetFullPath($testRoot)
    $parent=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
    if (-not $full.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test cleanup path.' }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop }
}
