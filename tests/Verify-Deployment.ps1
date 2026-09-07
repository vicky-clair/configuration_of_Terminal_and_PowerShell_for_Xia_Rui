$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$snapshotRoot = Join-Path $projectRoot 'backups\deployment-20260907-060507'
$testRoot = Join-Path $PSScriptRoot ('deployment-test-' + [guid]::NewGuid().ToString('N'))
$savedUserProfile = $env:USERPROFILE
$savedLocalAppData = $env:LOCALAPPDATA
$savedDocuments = $env:TERMINAL_SETUP_DOCUMENTS
try {
    # Exercise the real apply/rollback logic against isolated terminal fixtures.
    $env:USERPROFILE = Join-Path $testRoot 'user'
    $env:LOCALAPPDATA = Join-Path $testRoot 'local'
    $env:TERMINAL_SETUP_DOCUMENTS = Join-Path $env:USERPROFILE 'Documents'
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
    function Append-TestLineSafely([string]$Path, [string]$Value) {
        for ($retry = 0; $retry -lt 10; $retry++) {
            try {
                [System.IO.File]::AppendAllLines($Path, [string[]]@($Value))
                return
            } catch [System.IO.IOException] {
                Start-Sleep -Milliseconds 100
            }
        }
        [System.IO.File]::AppendAllLines($Path, [string[]]@($Value))
    }

    # 模拟外部用户在部署后所做的本地更改，必须安全留存在 pre-rollback 抢救快照中
    Append-TestLineSafely $manifest.Files[0].Target '# later user edit'
    $laterHash = (Get-FileHash -LiteralPath $manifest.Files[0].Target).Hash
    & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $fixtureSnapshots
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target).Hash -ne $entry.BeforeSHA256) { throw '回退后的字节与原始快照不一致。' }
    }
    $rescue = Get-ChildItem -LiteralPath $fixtureSnapshots -Directory -Filter 'pre-rollback-*'
    if ((Get-FileHash -LiteralPath (Join-Path $rescue.FullName $manifest.Files[0].After)).Hash -ne $laterHash) {
        throw '用户最新修改未能在 pre-rollback 快照中成功保存。'
    }
    # 模拟配置被意外篡改时的防覆写阻断
    Append-TestLineSafely $manifest.Files[1].Target ' '
    $blocked = $false
    try { & (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Mode Apply -BackupDirectory $fixtureSnapshots }
    catch { $blocked = ($_.Exception.Message -like '*Configuration changed since backup*' -or $_.Exception.Message -like '*配置文件在备份后已被修改*') }
    if (-not $blocked) { throw '部署预检未能阻止对已修改文件的意外覆写。' }
    if ((Get-FileHash -LiteralPath $manifest.Files[0].Target).Hash -ne $manifest.Files[0].BeforeSHA256) {
        throw '预检失败导致了意外的部分写入。'
    }
    Write-Output 'PASS: apply, WhatIf, exact rollback, rescue backup and changed-file protection.'
} finally {
    $env:USERPROFILE = $savedUserProfile
    $env:LOCALAPPDATA = $savedLocalAppData
    $env:TERMINAL_SETUP_DOCUMENTS = $savedDocuments
    $cleanupTarget = [System.IO.Path]::GetFullPath($testRoot)
    $allowedParent = [System.IO.Path]::GetFullPath($PSScriptRoot) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $cleanupTarget.StartsWith($allowedParent, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'Unexpected cleanup target.'
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
