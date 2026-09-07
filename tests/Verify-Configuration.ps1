# Run in a disposable child process: pwsh -NoProfile -File .\tests\Verify-Configuration.ps1
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$profileFile = Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

$settings = Get-Content -LiteralPath (Join-Path $projectRoot 'settings.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$guids = @($settings.profiles.list | ForEach-Object { [guid]$_.guid })
Assert-True ($guids.Count -eq @($guids | Select-Object -Unique).Count) 'Duplicate profile GUID.'
Assert-True ($guids -contains [guid]$settings.defaultProfile) 'Default profile is missing.'
$actionIds = @($settings.actions.id)
foreach ($binding in $settings.keybindings) {
    Assert-True ($actionIds -contains $binding.id) "Unresolved keybinding: $($binding.id)"
}
$parseTokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($profileFile, [ref]$parseTokens, [ref]$parseErrors)
Assert-True ($parseErrors.Count -eq 0) ($parseErrors | Out-String)

# Verify CMD configuration assets
$cmdAutorun = Join-Path $projectRoot 'cmd\autorun.cmd'
$cmdStarship = Join-Path $projectRoot 'cmd\clink\starship.lua'
$cmdSettings = Join-Path $projectRoot 'cmd\clink\settings.lua'
$cmdInstaller = Join-Path $projectRoot 'cmd\Install-CmdConfiguration.ps1'
Assert-True (Test-Path -LiteralPath $cmdAutorun -PathType Leaf) 'cmd\autorun.cmd is missing.'
Assert-True (Test-Path -LiteralPath $cmdStarship -PathType Leaf) 'cmd\clink\starship.lua is missing.'
Assert-True (Test-Path -LiteralPath $cmdSettings -PathType Leaf) 'cmd\clink\settings.lua is missing.'
Assert-True (Test-Path -LiteralPath $cmdInstaller -PathType Leaf) 'cmd\Install-CmdConfiguration.ps1 is missing.'
$cmdTokens = $null
$cmdErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($cmdInstaller, [ref]$cmdTokens, [ref]$cmdErrors)
Assert-True ($cmdErrors.Count -eq 0) ($cmdErrors | Out-String)
$cmdProfileEntry = $settings.profiles.list | Where-Object { $_.guid -eq '{0caa0dad-35be-5f56-a8ff-afceeeaa6101}' }
Assert-True ($cmdProfileEntry.startingDirectory -eq '%USERPROFILE%') 'Command Prompt startingDirectory is not %USERPROFILE%.'

# Verify Fastfetch custom assets
$ffAscii = Join-Path $projectRoot 'fastfetch\ascii.txt'
$ffConfig = Join-Path $projectRoot 'fastfetch\config.jsonc'
Assert-True (Test-Path -LiteralPath $ffAscii -PathType Leaf) 'fastfetch\ascii.txt is missing.'
Assert-True (Test-Path -LiteralPath $ffConfig -PathType Leaf) 'fastfetch\config.jsonc is missing.'

# Verify standalone installation and restore scripts
$installerScripts = @(
    'Install-PowerShell7.ps1',
    'Install-WinPowerShell51.ps1',
    'Install-Cmd.ps1',
    'Install-NuShell.ps1',
    'Install-MSYS2.ps1',
    'Install-All.ps1',
    'Restore-All.ps1',
    'Restore-TerminalConfiguration.ps1',
    'scripts\TerminalSetupCommon.ps1'
)
foreach ($scriptName in $installerScripts) {
    $scriptPath = Join-Path $projectRoot $scriptName
    Assert-True (Test-Path -LiteralPath $scriptPath -PathType Leaf) "Missing installer script: $scriptName"
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
    Assert-True ($errors.Count -eq 0) "Parse errors in $scriptName`: $($errors | Out-String)"
}

$savedPath = $env:PATH
$savedScoop = $env:SCOOP
$savedMinimal = $env:POWERSHELL_PROFILE_MINIMAL
$testRoot = Join-Path $projectRoot ('tests\tmp-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $testRoot 'scoop\shims') -Force | Out-Null
    $env:SCOOP = Join-Path $testRoot 'scoop'
    $env:POWERSHELL_PROFILE_MINIMAL = '1'
    $profileOutput = @(. $profileFile *>&1)
    Assert-True ($profileOutput.Count -eq 0) 'Minimal loading should be silent.'
    $pathAfterFirstLoad = $env:PATH
    . $profileFile
    Assert-True ($env:PATH -ceq $pathAfterFirstLoad) 'Reload duplicated or changed PATH.'
    Assert-True (($env:PATH -split ';') -contains (Join-Path $env:SCOOP 'shims')) 'Missing Scoop shims repair.'
    Assert-True ((Get-Alias dir).Definition -eq 'Get-ChildItem') 'dir alias changed.'
    Assert-True ((Get-Alias ls).Definition -eq 'Get-ChildItem') 'ls alias changed.'
    Assert-True ((Get-Alias cat).Definition -eq 'Get-Content') 'cat alias changed.'
    Assert-True ($OutputEncoding.CodePage -eq 65001) 'Output encoding is not UTF-8.'

    # Intercept git after loading: test forwarding without altering any repository.
    if (Get-Command gco -ErrorAction SilentlyContinue) {
        function git { $script:forwardedArgs = @($args) }
        # Quote --: an unquoted -- is consumed by PowerShell's function invocation.
        gco 'branch with spaces' '--' file.txt
        Assert-True (($script:forwardedArgs -join '|') -eq 'checkout|branch with spaces|--|file.txt') 'gco lost arguments.'
        gst -sb
        Assert-True (($script:forwardedArgs -join '|') -eq 'status|-sb') 'gst lost arguments.'
        gb -a
        Assert-True (($script:forwardedArgs -join '|') -eq 'branch|-a') 'gb lost arguments.'
        glog -10
        Assert-True (($script:forwardedArgs -join '|') -eq 'log|--oneline|--graph|--all|-10') 'glog lost arguments.'
        Assert-True ((Get-Alias gl).Definition -eq 'Get-Location') 'gl alias changed.'
    } else { Write-Host 'SKIP: Git forwarding (git is not installed).' }

    # Simulate no CLI tools and exercise paths containing wildcard characters.
    $env:PATH = ''
    $env:SCOOP = Join-Path $testRoot 'missing-scoop'
    $fixtureDir = Join-Path $testRoot '[literal]'
    New-Item -ItemType Directory -Path $fixtureDir | Out-Null
    $fixtureFile = Join-Path $fixtureDir 'sample.txt'
    Set-Content -LiteralPath $fixtureFile -Value 'fixture' -Encoding UTF8
    $profileOutput = @(. $profileFile *>&1)
    Assert-True ($profileOutput.Count -eq 0) 'Missing optional tools should be silent.'
    $items = @(ll -LiteralPath $fixtureDir)
    Assert-True ($items.Count -eq 1 -and $items[0] -is [System.IO.FileInfo]) 'll fallback lost objects or literal path.'
    $items = @(la -LiteralPath $fixtureDir)
    Assert-True ($items.Count -eq 1 -and $items[0] -is [System.IO.FileInfo]) 'la fallback failed.'
    Assert-True ((catc -LiteralPath $fixtureFile) -eq 'fixture') 'catc fallback failed.'
    Write-Host "PASS: configuration and profile regression checks (PowerShell $($PSVersionTable.PSVersion))."
} finally {
    $env:PATH = $savedPath
    $env:SCOOP = $savedScoop
    $env:POWERSHELL_PROFILE_MINIMAL = $savedMinimal
    $testParent = [System.IO.Path]::GetFullPath((Join-Path $projectRoot 'tests')) + [System.IO.Path]::DirectorySeparatorChar
    $cleanupTarget = [System.IO.Path]::GetFullPath($testRoot)
    if (-not $cleanupTarget.StartsWith($testParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean an unexpected path: $cleanupTarget"
    }
    if (Test-Path -LiteralPath $cleanupTarget) {
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        try {
            Remove-Item -LiteralPath $cleanupTarget -Recurse -Force -ErrorAction Stop
        } catch {
            Start-Sleep -Milliseconds 200
            Remove-Item -LiteralPath $cleanupTarget -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
