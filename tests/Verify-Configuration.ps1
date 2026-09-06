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
    if (Test-Path -LiteralPath $cleanupTarget) { Remove-Item -LiteralPath $cleanupTarget -Recurse -Force }
}
