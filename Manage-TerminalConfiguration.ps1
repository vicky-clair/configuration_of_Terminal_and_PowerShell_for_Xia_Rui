# Only the two allowlisted terminal configuration files can be changed.
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Validate', 'Apply', 'Rollback')]
    [string]$Mode = 'Validate',
    [Parameter(Mandatory = $true)]
    [string]$BackupDirectory
)
$ErrorActionPreference = 'Stop'
$backupRoot = (Resolve-Path -LiteralPath $BackupDirectory).ProviderPath
$manifest = Get-Content -LiteralPath (Join-Path $backupRoot 'deployment.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$allowedTargets = @(
    (Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
)
if ($manifest.Files.Count -ne 2) { throw 'Expected exactly two configuration targets.' }
$seenTargets = @()
foreach ($entry in $manifest.Files) {
    if ($entry.Target -notin $allowedTargets -or $entry.Target -in $seenTargets) {
        throw "Unexpected or duplicate target: $($entry.Target)"
    }
    $seenTargets += $entry.Target
    foreach ($name in @($entry.Before, $entry.After)) {
        if ([System.IO.Path]::GetFileName($name) -ne $name) { throw 'Snapshot must be a direct child of the backup directory.' }
    }
    foreach ($version in @('Before', 'After')) {
        $snapshotPath = Join-Path $backupRoot $entry.$version
        $expectedHash = $entry.($version + 'SHA256')
        if ((Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash -ne $expectedHash) {
            throw "Snapshot integrity check failed: $snapshotPath"
        }
    }
    if (-not (Test-Path -LiteralPath $entry.Target -PathType Leaf)) { throw "Target is missing: $($entry.Target)" }
}

$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $backupRoot 'PowerShell7-profile.after.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$settings = Get-Content -LiteralPath (Join-Path $backupRoot 'Terminal-stable.after.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$guids = @($settings.profiles.list.guid)
if ($guids -notcontains $settings.defaultProfile -or
    @($guids | Select-Object -Unique).Count -ne $guids.Count) { throw 'Invalid Terminal profile references.' }

if ($Mode -eq 'Validate') {
    $manifest.Files | ForEach-Object {
        $currentHash = (Get-FileHash -LiteralPath $_.Target -Algorithm SHA256).Hash
        [pscustomobject]@{
            Target = $_.Target
            State = if ($currentHash -eq $_.BeforeSHA256) { 'Original' }
                elseif ($currentHash -eq $_.AfterSHA256) { 'Applied' } else { 'Changed since snapshot' }
            BackupVerified = $true
        }
    } | Format-List
    return
}

# Preflight all files before making the first write.
if ($Mode -eq 'Apply') {
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.BeforeSHA256) {
            throw "Configuration changed since backup; refusing to overwrite: $($entry.Target)"
        }
    }
}
if (-not $PSCmdlet.ShouldProcess(($allowedTargets -join ', '), $Mode)) { return }

# Capture the current bytes for recovery. Rollback also saves later user edits to disk.
$priorBytes = @{}
foreach ($entry in $manifest.Files) { $priorBytes[$entry.Target] = [System.IO.File]::ReadAllBytes($entry.Target) }
if ($Mode -eq 'Rollback') {
    $rescueDirectory = Join-Path $backupRoot ('pre-rollback-' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $rescueDirectory | Out-Null
    foreach ($entry in $manifest.Files) {
        [System.IO.File]::WriteAllBytes((Join-Path $rescueDirectory $entry.After), $priorBytes[$entry.Target])
    }
    Write-Output "Saved current configuration before rollback: $rescueDirectory"
}

$modified = @()
try {
    foreach ($entry in $manifest.Files) {
        $version = if ($Mode -eq 'Apply') { 'After' } else { 'Before' }
        # Recheck the apply precondition immediately before each write.
        if ($Mode -eq 'Apply' -and
            (Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.BeforeSHA256) {
            throw "Configuration changed during deployment: $($entry.Target)"
        }
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $backupRoot $entry.$version))
        $modified += $entry.Target
        [System.IO.File]::WriteAllBytes($entry.Target, $bytes)
        if ((Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.($version + 'SHA256')) {
            throw "Written configuration failed verification: $($entry.Target)"
        }
    }
} catch {
    $operationError = $_
    foreach ($target in $modified) {
        try { [System.IO.File]::WriteAllBytes($target, $priorBytes[$target]) }
        catch { Write-Warning "Automatic recovery failed for $target. Use the snapshots in $backupRoot. $_" }
    }
    throw $operationError
}
[pscustomobject]@{Mode=$Mode;Time=(Get-Date -Format o);Targets=$allowedTargets} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backupRoot ('last-' + $Mode.ToLowerInvariant() + '.json')) -Encoding UTF8
Write-Output "$Mode completed and both file hashes verified. Open a new PowerShell tab."
