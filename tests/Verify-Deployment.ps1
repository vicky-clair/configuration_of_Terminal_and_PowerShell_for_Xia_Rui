$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$snapshotRoot = Join-Path $projectRoot 'backups\deployment-20260907-060507'
$testRoot = Join-Path $PSScriptRoot ('deployment-test-' + [guid]::NewGuid().ToString('N'))
$savedUserProfile = $env:USERPROFILE
$savedLocalAppData = $env:LOCALAPPDATA
try {
    # Exercise the real apply/rollback logic against isolated terminal fixtures.
    $env:USERPROFILE = Join-Path $testRoot 'user'
    $env:LOCALAPPDATA = Join-Path $testRoot 'local'
    $fixtureSnapshots = Join-Path $testRoot 'snapshots'
    New-Item -ItemType Directory -Path $fixtureSnapshots -Force | Out-Null
    $manifest = Get-Content -LiteralPath (Join-Path $snapshotRoot 'deployment.json') -Raw | ConvertFrom-Json
    $manifest.Files[0].Target = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $manifest.Files[1].Target = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
    foreach ($entry in $manifest.Files) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $entry.Target) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $snapshotRoot $entry.Before) -Destination $entry.Target
        foreach ($name in @($entry.Before,$entry.After)) {
            Copy-Item -LiteralPath (Join-Path $snapshotRoot $name) -Destination (Join-Path $fixtureSnapshots $name)
        }
    }
    $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $fixtureSnapshots 'deployment.json') -Encoding utf8
    & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Apply -BackupDirectory $fixtureSnapshots
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target).Hash -ne $entry.AfterSHA256) { throw 'Apply did not match staged bytes.' }
    }
    & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $fixtureSnapshots -WhatIf
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target).Hash -ne $entry.AfterSHA256) { throw 'WhatIf changed a file.' }
    }
    # A later user edit must survive in the pre-rollback rescue snapshot.
    Add-Content -LiteralPath $manifest.Files[0].Target -Value '# later user edit'
    $laterHash = (Get-FileHash -LiteralPath $manifest.Files[0].Target).Hash
    & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $fixtureSnapshots
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target).Hash -ne $entry.BeforeSHA256) { throw 'Rollback was not byte-exact.' }
    }
    $rescue = Get-ChildItem -LiteralPath $fixtureSnapshots -Directory -Filter 'pre-rollback-*'
    if ((Get-FileHash -LiteralPath (Join-Path $rescue.FullName $manifest.Files[0].After)).Hash -ne $laterHash) {
        throw 'Later user edits were not backed up.'
    }
    Add-Content -LiteralPath $manifest.Files[1].Target -Value ' '
    $blocked = $false
    try { & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Apply -BackupDirectory $fixtureSnapshots }
    catch { $blocked = $_.Exception.Message -like 'Configuration changed since backup*' }
    if (-not $blocked) { throw 'Apply must reject a changed live file.' }
    if ((Get-FileHash -LiteralPath $manifest.Files[0].Target).Hash -ne $manifest.Files[0].BeforeSHA256) {
        throw 'Preflight failure changed the first file.'
    }
    Write-Output 'PASS: apply, WhatIf, exact rollback, rescue backup and changed-file protection.'
} finally {
    $env:USERPROFILE = $savedUserProfile
    $env:LOCALAPPDATA = $savedLocalAppData
    $cleanupTarget = [System.IO.Path]::GetFullPath($testRoot)
    $allowedParent = [System.IO.Path]::GetFullPath($PSScriptRoot) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $cleanupTarget.StartsWith($allowedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Unexpected cleanup target.'
    }
    if (Test-Path -LiteralPath $cleanupTarget) { Remove-Item -LiteralPath $cleanupTarget -Recurse -Force }
}
