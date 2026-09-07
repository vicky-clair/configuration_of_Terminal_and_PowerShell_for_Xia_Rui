# Optional Windows integration check: writes only a unique temporary HKCU subkey and removes it.
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/TerminalState.ps1')
$subKey='Software\powershelldome-test-'+[guid]::NewGuid().ToString('N')
$state=[pscustomobject]@{Key=('HKCU:\'+$subKey);Name='Value';Existed=$true;Value='%USERPROFILE%';Kind='ExpandString'}
try {
    Set-TerminalRegistryState $state
    $read=Get-TerminalRegistryState $state
    if (-not $read.Existed -or $read.Value -cne $state.Value -or $read.Kind -ne $state.Kind) { throw 'Expandable value round trip failed.' }
    $state.Value=''; $state.Kind='String'
    Set-TerminalRegistryState $state
    $read=Get-TerminalRegistryState $state
    if (-not $read.Existed -or $read.Value -cne '' -or $read.Kind -ne 'String') { throw 'Empty string round trip failed.' }
    $state.Existed=$false
    Set-TerminalRegistryState $state
    if ((Get-TerminalRegistryState $state).Existed) { throw 'Value deletion failed.' }
    Set-TerminalRegistryState $state
    Write-Output "PASS: writable HKCU registry value creation, replacement, type preservation and deletion ($($PSVersionTable.PSVersion))."
} finally {
    if ($subKey -notmatch '^Software\\powershelldome-test-[a-f0-9]{32}$') { throw 'Unsafe registry cleanup path.' }
    [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($subKey,$false)
}
