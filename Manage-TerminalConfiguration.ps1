# ============================================================================
# 终端配置原子管理器 (白名单校验、SHA-256 完整性核对与安全回退)
# 仅允许对白名单内的两项目标配置文件执行变更：PowerShell 7 Profile 与 Windows Terminal Settings
# ============================================================================
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Validate', 'Apply', 'Rollback')]
    [string]$Mode = 'Validate',
    [Parameter(Mandatory = $true)]
    [string]$BackupDirectory
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'scripts/TerminalState.ps1')
$backupRoot = (Resolve-Path -LiteralPath $BackupDirectory).ProviderPath
$manifest = Get-Content -LiteralPath (Join-Path $backupRoot 'deployment.json') -Raw -Encoding UTF8 | ConvertFrom-Json

# 白名单目标路径定义
$allowedTargets = @(
    (Join-Path (Get-TerminalDocumentsPath) 'PowerShell/Microsoft.PowerShell_profile.ps1'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json')
)
if ($manifest.Files.Count -ne 2) { throw '部署清单校验失败：预期必须恰好包含两个目标配置文件。' }
$seenTargets = @()
foreach ($entry in $manifest.Files) {
    if ($entry.Target -notin $allowedTargets -or $entry.Target -in $seenTargets) {
        throw "非法或重复的配置目标: $($entry.Target)"
    }
    $seenTargets += $entry.Target
    foreach ($name in @($entry.Before, $entry.After)) {
        if ([System.IO.Path]::GetFileName($name) -ne $name) { throw '快照文件必须直接存放于备份根目录下。' }
    }
    foreach ($version in @('Before', 'After')) {
        $snapshotPath = Join-Path $backupRoot $entry.$version
        $expectedHash = $entry.($version + 'SHA256')
        if ((Get-FileHash -LiteralPath $snapshotPath -Algorithm SHA256).Hash -ne $expectedHash) {
            throw "快照文件 SHA-256 完整性校验失败: $snapshotPath"
        }
    }
    if (-not (Test-Path -LiteralPath $entry.Target -PathType Leaf)) { throw "目标配置文件不存在: $($entry.Target)" }
}

# 静态语法与 JSON GUID 校验
$tokens = $null
$parseErrors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile(
    (Join-Path $backupRoot 'PowerShell7-profile.after.ps1'), [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
$settings = Get-Content -LiteralPath (Join-Path $backupRoot 'Terminal-stable.after.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$guids = @($settings.profiles.list.guid)
if ($guids -notcontains $settings.defaultProfile -or
    @($guids | Select-Object -Unique).Count -ne $guids.Count) { throw 'Windows Terminal 配置文件 GUID 校验失败或默认 Profile 不存在。' }

# 1. 验证模式 (Validate)
if ($Mode -eq 'Validate') {
    $manifest.Files | ForEach-Object {
        $currentHash = (Get-FileHash -LiteralPath $_.Target -Algorithm SHA256).Hash
        [pscustomobject]@{
            Target = $_.Target
            State = if ($currentHash -eq $_.BeforeSHA256) { 'Original (原始状态)' }
                elseif ($currentHash -eq $_.AfterSHA256) { 'Applied (已部署状态)' } else { 'Changed since snapshot (已发生外部变更)' }
            BackupVerified = $true
        }
    } | Format-List
    return
}

# 2. 部署前预检 (Preflight)：防止覆写外部意外更改
if ($Mode -eq 'Apply') {
    foreach ($entry in $manifest.Files) {
        if ((Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.BeforeSHA256) {
            throw "Configuration changed since backup (配置文件在备份后已被外部修改，为安全拒绝覆写): $($entry.Target)"
        }
    }
}
if (-not $PSCmdlet.ShouldProcess(($allowedTargets -join ', '), $Mode)) { return }

# 3. 内存与磁盘字节级安全原子写入（支持 IO 锁冲突重试）
function Set-TargetBytesSafely([string]$Path, [byte[]]$Bytes) { Set-TerminalBytes -Path $Path -Bytes $Bytes }

# 捕获写入前的实时字节，以备紧急回滚；若执行 Rollback，额外将最新修改归档至 pre-rollback 目录
$priorBytes = @{}
foreach ($entry in $manifest.Files) { $priorBytes[$entry.Target] = [System.IO.File]::ReadAllBytes($entry.Target) }
if ($Mode -eq 'Rollback') {
    $rescueDirectory = Join-Path $backupRoot ('pre-rollback-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $rescueDirectory | Out-Null
    foreach ($entry in $manifest.Files) {
        Set-TargetBytesSafely (Join-Path $rescueDirectory $entry.After) $priorBytes[$entry.Target]
    }
    Write-Output "已在回退前自动保存当前最新配置副本: $rescueDirectory"
}

# 4. 执行写入与全量校验
$modified = @()
try {
    foreach ($entry in $manifest.Files) {
        $version = if ($Mode -eq 'Apply') { 'After' } else { 'Before' }
        # 严格校验部署前置状态：写入前最后一刻再次核对哈希
        if ($Mode -eq 'Apply' -and
            (Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.BeforeSHA256) {
            throw "部署过程中检测到配置并发变更: $($entry.Target)"
        }
        $bytes = [System.IO.File]::ReadAllBytes((Join-Path $backupRoot $entry.$version))
        $modified += $entry.Target
        Set-TargetBytesSafely $entry.Target $bytes
        if ((Get-FileHash -LiteralPath $entry.Target -Algorithm SHA256).Hash -ne $entry.($version + 'SHA256')) {
            throw "写入后哈希校验失败: $($entry.Target)"
        }
    }
} catch {
    $operationError = $_
    # 异常自动恢复现场
    foreach ($target in $modified) {
        try { Set-TargetBytesSafely $target $priorBytes[$target] }
        catch { Write-Warning "自动恢复现场失败: $target。请从快照恢复: $backupRoot。$_" }
    }
    throw $operationError
}
[pscustomobject]@{Mode=$Mode;Time=(Get-Date -Format o);Targets=$allowedTargets} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backupRoot ('last-' + $Mode.ToLowerInvariant() + '.json')) -Encoding UTF8
Write-Output "$Mode 操作成功完成，目标文件 SHA-256 校验一致。新开 PowerShell 标签页即可生效。"
