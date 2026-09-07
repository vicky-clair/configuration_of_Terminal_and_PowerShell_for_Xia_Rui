# Exercises installer entry points with file fixtures; no real packages, registry or user profiles are changed.
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path $PSScriptRoot ('tmp-installer-integration-'+[guid]::NewGuid().ToString('N'))
$saved=@{}
foreach ($name in @('USERPROFILE','LOCALAPPDATA','APPDATA','TERMINAL_SETUP_DOCUMENTS','MSYS2_PATH_TYPE')) { $saved[$name]=[Environment]::GetEnvironmentVariable($name) }
function Assert($Condition,[string]$Message) { if (-not $Condition) { throw $Message } }
function Assert-Fails([scriptblock]$Action,[string]$Pattern) {
    try { & $Action } catch { if ($_.Exception.Message -like $Pattern) { return }; throw }
    throw "Expected failure: $Pattern"
}
try {
    $repo=Join-Path $fixture 'repo'
    [IO.Directory]::CreateDirectory($repo) | Out-Null
    Copy-Item -LiteralPath (Join-Path $projectRoot 'scripts') -Destination $repo -Recurse
    foreach ($file in @('Install-MSYS2.ps1','Install-NuShell.ps1','settings.json')) { Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $repo }
    $env:USERPROFILE=Join-Path $fixture 'user'
    $env:LOCALAPPDATA=Join-Path $fixture 'local'
    $env:APPDATA=Join-Path $fixture 'roaming'
    $env:TERMINAL_SETUP_DOCUMENTS=Join-Path $fixture 'Documents'
    . (Join-Path $projectRoot 'scripts/TerminalSetupCommon.ps1')

    # Run the real package fallback and Scoop verification. Only package-manager boundaries are mocked.
    & {
        function Initialize-SetupEnvironment {}
        function Ensure-ScoopInstalled {}
        function Ensure-ScoopBuckets {}
        function Ensure-WingetConfigured { return $false }
        function Refresh-SessionPath {}
        function Get-Command { return $null }
        $script:installed=$false; $script:broken=$false
        $scoopBash=Join-Path $fixture 'scoop/apps/msys2/current/usr/bin/bash.exe'
        $missingBash=Join-Path $fixture 'missing-msys/usr/bin/bash.exe'
        function scoop {
            $global:LASTEXITCODE=0
            if ($args[0] -eq 'list') {
                if ($script:installed) { [pscustomobject]@{Name='msys2'} }
            } elseif ($args[0] -eq 'install') {
                $script:installed=$true
                if (-not $script:broken) { Set-TerminalText $scoopBash 'fixture executable' }
            } else { throw 'Unexpected Scoop operation.' }
        }
        $result=Install-AppWithChocoWingetFallback -Name MSYS2 -ChocoId msys2 -WingetId MSYS2.MSYS2 -ScoopId msys2 -PathCheck @($missingBash,$scoopBash)
        Assert ($result -eq $true -and $script:installed) 'Scoop installation outside the default root was rejected.'
        Install-ScoopAppsIfMissing @('msys2') -PathCheck @($missingBash,$scoopBash)
        Assert-Fails { Install-ScoopAppsIfMissing @('msys2') -PathCheck @($missingBash) } '*not executable after refreshing PATH*'
        $script:installed=$false; $script:broken=$true
        Assert-Fails { Install-AppWithChocoWingetFallback -Name MSYS2 -ChocoId msys2 -WingetId MSYS2.MSYS2 -ScoopId msys2 -PathCheck @($missingBash) } '*All installation methods failed*'
        $emptyRoot=Join-Path $fixture 'empty-install'
        [IO.Directory]::CreateDirectory($emptyRoot) | Out-Null
        Assert (-not (Test-SetupAppReady -PathCheck @($emptyRoot))) 'An empty directory was accepted as an executable.'
    }

    $wt=@(Get-TerminalTargets -Components Terminal)[0].Target
    $settings=[IO.File]::ReadAllText((Join-Path $projectRoot 'settings.json')) | ConvertFrom-Json
    $visualBefore=$settings.profiles.defaults | ConvertTo-Json -Depth 30 -Compress
    $settings.profiles.list=@($settings.profiles.list | Where-Object name -ne 'NuShell')
    $settings.profiles.list+= [pscustomobject]@{guid='{00000000-0000-0000-0000-000000000001}';name='GNU Bash';commandline='bash.exe';colorScheme='Campbell'}
    $settings.profiles.list+= [pscustomobject]@{guid='{00000000-0000-0000-0000-000000000002}';name='Other MSYS2';commandline='"E:\Other\msys2_shell.cmd" -mingw64';hidden=$true}
    Set-TerminalText $wt ($settings | ConvertTo-Json -Depth 100)
    $originalProfiles=$settings.profiles.list | ConvertTo-Json -Depth 30 -Compress

    # The copied installer keeps real snapshot, text-generation and Terminal-registration logic.
    $mocks=@'
function Initialize-SetupEnvironment {}
function Ensure-ScoopBuckets {}
function Install-ScoopAppsIfMissing {}
function Install-AppWithChocoWingetFallback { return $true }
function Ensure-FastfetchConfigured {}
function Ensure-StarshipConfigured {}
function Get-TerminalRegistryState($Spec) { [pscustomobject]@{Key=$Spec.Key;Name=$Spec.Name;Existed=$false;Value=$null;Kind='String'} }
function Invoke-FixtureStarship { $global:LASTEXITCODE=0; '# fixture starship initialization' }
function Invoke-FixtureZoxide { $global:LASTEXITCODE=0; '# fixture zoxide initialization' }
function Get-Command {
    param($Name,$ErrorAction)
    if ($Name -eq 'starship') { return [pscustomobject]@{Source='Invoke-FixtureStarship'} }
    if ($Name -eq 'zoxide') { return [pscustomobject]@{Source='Invoke-FixtureZoxide'} }
    throw "Unexpected command discovery: $Name"
}
'@
    $common=Join-Path $repo 'scripts/TerminalSetupCommon.ps1'
    Set-TerminalText $common ([IO.File]::ReadAllText($common)+"`n"+$mocks) -Bom
    $msysInstaller=Join-Path $repo 'Install-MSYS2.ps1'
    $text=[IO.File]::ReadAllText($msysInstaller)
    $registryCall="[System.Environment]::SetEnvironmentVariable('MSYS2_PATH_TYPE', 'inherit', 'User')"
    $bashCall='& $bashExe -lc "exit" 2>$null'
    Assert ($text.Contains($registryCall) -and $text.Contains($bashCall)) 'Installer boundaries changed; update isolation before running.'
    $text=$text.Replace($registryCall,'$null = 0').Replace($bashCall,'$global:LASTEXITCODE=0')
    Set-TerminalText $msysInstaller $text -Bom
    $custom=Join-Path $fixture 'custom msys [literal]'
    Set-TerminalText (Join-Path $custom 'usr/bin/bash.exe') 'not executed'
    $bashrc=Join-Path $custom "home/$env:USERNAME/.bashrc"
    Set-TerminalText $bashrc '# existing user configuration'
    & $msysInstaller -Msys2InstallPath $custom -NonInteractive
    $after=Get-Content -LiteralPath $wt -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert (($after.profiles.defaults | ConvertTo-Json -Depth 30 -Compress) -ceq $visualBefore) 'Terminal appearance was changed.'
    $expectedCommand=Join-Path $custom 'msys2_shell.cmd'
    foreach ($profile in $after.profiles.list) {
        $before=@($settings.profiles.list | Where-Object guid -eq $profile.guid)[0]
        if ($before.commandline -like 'C:\msys64\msys2_shell.cmd*') {
            Assert ($profile.commandline.StartsWith('"'+$expectedCommand+'" ')) 'Managed MSYS2 entry retained its old executable.'
            $profile.commandline=$before.commandline
        }
    }
    Assert (($after.profiles.list | ConvertTo-Json -Depth 30 -Compress) -ceq $originalProfiles) 'Registration changed names, icons, shell flags or unrelated profiles.'
    $firstHash=Get-TerminalHash $wt
    & $msysInstaller -Msys2InstallPath $custom -NonInteractive
    Assert ((Get-TerminalHash $wt) -eq $firstHash) 'MSYS2 registration was not idempotent.'
    $generated=[IO.File]::ReadAllText($bashrc)
    Assert ($generated.StartsWith('# existing user configuration')) 'Existing bash configuration was lost.'
    Assert ([regex]::Matches($generated,'zoxide init bash').Count -eq 1) 'Zoxide initialization was missing or duplicated.'
    Assert ([regex]::Matches($generated,'# >>> Windows Terminal Beautification for MSYS2 >>>').Count -eq 1) 'Repeated installation duplicated the managed block.'
    $backup=[IO.File]::ReadAllText((Join-Path $repo '.last-install-backup'))
    $manifest=Get-Content -LiteralPath (Join-Path $backup 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert (@($manifest.Files | Where-Object Target -eq $bashrc).Count -eq 1) 'Custom MSYS2 file was not backed up.'

    & (Join-Path $repo 'Install-NuShell.ps1') -NonInteractive
    $after=Get-Content -LiteralPath $wt -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert (@($after.profiles.list | Where-Object commandline -eq 'nu.exe').Count -eq 1) 'GNU Bash prevented NuShell registration.'
    Assert (($after.profiles.defaults | ConvertTo-Json -Depth 30 -Compress) -ceq $visualBefore) 'NuShell registration changed default appearance.'
    foreach ($plugin in @('starship','zoxide')) {
        Assert ([IO.File]::ReadAllText((Join-Path $env:APPDATA "nushell/vendor/autoload/$plugin.nu")) -like '*fixture*initialization*') 'NuShell plugin-generation branch was skipped.'
    }
    $firstHash=Get-TerminalHash $wt
    Register-TerminalShellProfile -Shell NuShell
    Assert ((Get-TerminalHash $wt) -eq $firstHash) 'NuShell registration duplicated or rewrote an existing profile.'
    Set-TerminalText $wt '{"profiles":{"list":[{"name":"Custom Nu","commandline":"\"D:\\Nu Tools\\nu.exe\" --login"}]}}'
    $firstHash=Get-TerminalHash $wt
    Register-TerminalShellProfile -Shell NuShell
    Assert ((Get-TerminalHash $wt) -eq $firstHash) 'Quoted NuShell executable was not recognized.'
    Set-TerminalText $wt '{"profiles":{"defaults":{"opacity":73},"list":[]}}'
    & {
        function Set-TerminalText { throw 'fixture write denied' }
        Assert-Fails { Register-TerminalShellProfile -Shell NuShell } '*registration failed*fixture write denied*'
    }
    Set-TerminalText $wt '{broken'
    Assert-Fails { & (Join-Path $repo 'Install-NuShell.ps1') -NonInteractive } '*registration failed*'
    Assert-Fails { & $msysInstaller -Msys2InstallPath $custom -NonInteractive } '*registration failed*'
    Assert ([IO.File]::ReadAllText($wt) -ceq '{broken') 'Invalid Terminal settings were overwritten.'
    Set-TerminalText $wt '{}'
    Register-TerminalShellProfile -Shell NuShell
    $after=Get-Content -LiteralPath $wt -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert ($after.profiles.list.Count -eq 1) 'An empty settings object could not register a profile.'
    Write-Host "PASS: package path verification, real MSYS2/NuShell entries, custom roots, visual preservation, Zoxide hook, idempotence and failure propagation ($($PSVersionTable.PSVersion))."
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name,$saved[$name]) }
    $full=[IO.Path]::GetFullPath($fixture)
    $parent=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\'
    if (-not $full.StartsWith($parent,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe fixture cleanup.' }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
