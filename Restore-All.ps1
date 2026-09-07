[CmdletBinding(SupportsShouldProcess=$true)]
param([string]$BackupDirectory, [string]$Msys2InstallPath, [string]$CmdTargetDir,
      [ValidateSet('All','PowerShell7','WinPS51','Terminal','Cmd','Shared','NuShell','MSYS2')][string[]]$Components=@('All'))
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'scripts/TerminalState.ps1')
if (-not $BackupDirectory) {
    $pointer=Join-Path $PSScriptRoot '.last-install-backup'
    if (-not (Test-Path -LiteralPath $pointer)) { throw 'No installation snapshot. Specify -BackupDirectory.' }
    $BackupDirectory=[IO.File]::ReadAllText($pointer).Trim()
    $contextPath=Join-Path $PSScriptRoot '.last-install-context.json'
    if (-not $Msys2InstallPath -and [IO.File]::Exists($contextPath)) {
        Assert-TerminalRegularFile $contextPath
        $context=[IO.File]::ReadAllText($contextPath) | ConvertFrom-Json
        if ($context.Version -ne 1) { throw 'Unsupported local installation context version.' }
        if ($context.BackupDirectory -and [IO.Path]::GetFullPath($context.BackupDirectory) -eq [IO.Path]::GetFullPath($BackupDirectory)) {
            $Msys2InstallPath=$context.Msys2InstallPath
        }
    }
}
if (Test-Path -LiteralPath (Join-Path $BackupDirectory 'manifest.json')) {
    Restore-TerminalSnapshot -Directory $BackupDirectory -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir -Components $Components -WhatIf:$WhatIfPreference
} elseif (Test-Path -LiteralPath (Join-Path $BackupDirectory 'deployment.json')) {
    # Snapshots are data: never execute their scripts, even under WhatIf.
    & (Join-Path $PSScriptRoot 'Manage-TerminalConfiguration.ps1') -Mode Rollback -BackupDirectory $BackupDirectory -WhatIf:$WhatIfPreference
} else { throw "Unrecognized snapshot: $BackupDirectory" }
