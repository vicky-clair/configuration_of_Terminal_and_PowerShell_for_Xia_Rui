# Shared state, backup and restore primitives. Compatible with Windows PowerShell 5.1.
function Get-TerminalDocumentsPath {
    # Explicit override supports portable profiles and isolated verification fixtures.
    if ($env:TERMINAL_SETUP_DOCUMENTS) { return [IO.Path]::GetFullPath($env:TERMINAL_SETUP_DOCUMENTS) }
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if (-not $documents) { $documents = Join-Path $env:USERPROFILE 'Documents' }
    return $documents
}

function Resolve-TerminalMsysRoot([string]$Path) {
    if ($Path) { return [IO.Path]::GetFullPath($Path) }
    foreach ($candidate in @('C:\msys64', "$env:SystemDrive\msys64", "$env:USERPROFILE\scoop\apps\msys2\current", 'C:\tools\msys64')) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'usr\bin\bash.exe')) { return $candidate }
    }
    return 'C:\msys64'
}

function Get-TerminalTargets {
    param([string]$Msys2InstallPath, [string[]]$Components = @('All'), [string]$CmdTargetDir)
    $documents = Get-TerminalDocumentsPath
    $msys = Resolve-TerminalMsysRoot $Msys2InstallPath
    if (-not $CmdTargetDir) { $CmdTargetDir = Join-Path $env:USERPROFILE '.config\cmd' }
    $spec = @(
        @('PowerShell7_profile.ps1', "$documents\PowerShell\Microsoft.PowerShell_profile.ps1", 'PowerShell7'),
        @('WinPS51_profile.ps1', "$documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1", 'WinPS51'),
        @('Terminal_stable.json', "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json", 'Terminal'),
        @('Terminal_preview.json', "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json", 'Terminal'),
        @('clink_starship.lua', "$env:LOCALAPPDATA\clink\starship.lua", 'Cmd'),
        @('clink_settings.lua', "$env:LOCALAPPDATA\clink\settings.lua", 'Cmd'),
        @('cmd_autorun.cmd', "$CmdTargetDir\autorun.cmd", 'Cmd'),
        @('starship.toml', "$env:USERPROFILE\.config\starship.toml", 'Shared'),
        @('fastfetch_config.jsonc', "$env:USERPROFILE\.config\fastfetch\config.jsonc", 'Shared'),
        @('fastfetch_ascii.txt', "$env:USERPROFILE\.config\fastfetch\ascii.txt", 'Shared'),
        @('nushell_config.nu', "$env:APPDATA\nushell\config.nu", 'NuShell'),
        @('nushell_env.nu', "$env:APPDATA\nushell\env.nu", 'NuShell'),
        @('nushell_starship.nu', "$env:APPDATA\nushell\vendor\autoload\starship.nu", 'NuShell'),
        @('nushell_zoxide.nu', "$env:APPDATA\nushell\vendor\autoload\zoxide.nu", 'NuShell'),
        @('msys2_bashrc', "$msys\home\$env:USERNAME\.bashrc", 'MSYS2')
    )
    foreach ($ini in @('msys2','ucrt64','mingw64','clang64')) { $spec += ,@("$ini.ini", "$msys\$ini.ini", 'MSYS2') }
    foreach ($item in $spec) {
        if ('All' -in $Components -or $item[2] -in $Components) {
            [pscustomobject]@{Name=$item[0];Target=[IO.Path]::GetFullPath($item[1]);Desc=$item[2];Component=$item[2]}
        }
    }
}

function Assert-TerminalRegularFile([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
        if ($item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Expected a regular file, not a directory or link: $Path"
        }
    }
}

function Get-TerminalHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
    finally { $sha.Dispose(); $stream.Dispose() }
}

function Set-TerminalBytes {
    param([string]$Path, [AllowEmptyCollection()][byte[]]$Bytes)
    $Path = [IO.Path]::GetFullPath($Path)
    Assert-TerminalRegularFile $Path
    $parent = [IO.Path]::GetDirectoryName($Path)
    [IO.Directory]::CreateDirectory($parent) | Out-Null
    $temporary = Join-Path $parent ('.terminal-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        $stream = [IO.File]::Open($temporary, 'CreateNew', 'Write', 'None')
        try { $stream.Write($Bytes, 0, $Bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        for ($attempt=0; ; $attempt++) {
            try {
                if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temporary, $Path, [NullString]::Value) }
                else { [IO.File]::Move($temporary, $Path) }
                break
            } catch [IO.IOException] {
                if ($attempt -ge 9) { throw }
                Start-Sleep -Milliseconds 100
            }
        }
    } finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}

function Set-TerminalText {
    param([string]$Path, [AllowEmptyString()][string]$Text, [switch]$Bom)
    $encoding = New-Object Text.UTF8Encoding ([bool]$Bom)
    $bytes = $encoding.GetPreamble() + $encoding.GetBytes($Text)
    Set-TerminalBytes -Path $Path -Bytes $bytes
}

function Get-TerminalRegistrySpecs([string[]]$Components = @('All')) {
    if ('All' -in $Components -or 'Cmd' -in $Components) { [pscustomobject]@{Key='HKCU:\Software\Microsoft\Command Processor';Name='AutoRun'} }
    if ('All' -in $Components -or 'MSYS2' -in $Components) { [pscustomobject]@{Key='HKCU:\Environment';Name='MSYS2_PATH_TYPE'} }
}

function Get-TerminalRegistryState($Spec) {
    $result = [ordered]@{Key=$Spec.Key;Name=$Spec.Name;Existed=$false;Value=$null;Kind='String'}
    if (Test-Path -LiteralPath $Spec.Key) {
        $key = Get-Item -LiteralPath $Spec.Key -ErrorAction Stop
        try {
            if ($Spec.Name -in $key.GetValueNames()) {
                $result.Existed=$true
                $result.Kind=$key.GetValueKind($Spec.Name).ToString()
                $result.Value=$key.GetValue($Spec.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
            }
        } finally { $key.Close() }
    }
    [pscustomobject]$result
}

function Set-TerminalRegistryState($State) {
    if ($State.Key -notlike 'HKCU:\*') { throw "Unsupported registry hive: $($State.Key)" }
    $subKey=$State.Key.Substring(6)
    if ($State.Existed) {
        # Registry provider Get-Item handles may be read-only. Explicitly open a writable handle.
        $key=[Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($subKey)
        try { $key.SetValue($State.Name, $State.Value, ([Enum]::Parse([Microsoft.Win32.RegistryValueKind], $State.Kind))) }
        finally { $key.Close() }
    } else {
        $key=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($subKey,$true)
        if ($null -eq $key) { return }
        try { $key.DeleteValue($State.Name, $false) } finally { $key.Close() }
    }
}

function New-TerminalSnapshot {
    param([string]$Directory, [object[]]$Targets, [object[]]$RegistrySpecs = @())
    if (Test-Path -LiteralPath $Directory) { throw "Snapshot already exists: $Directory" }
    [IO.Directory]::CreateDirectory($Directory) | Out-Null
    $files = @(foreach ($target in $Targets) {
        Assert-TerminalRegularFile $target.Target
        $exists=[IO.File]::Exists($target.Target)
        $hash=''
        if ($exists) {
            $copy=Join-Path $Directory $target.Name
            Set-TerminalBytes $copy ([IO.File]::ReadAllBytes($target.Target))
            $hash=Get-TerminalHash $copy
        }
        [pscustomobject]@{Name=$target.Name;Target=$target.Target;Desc=$target.Desc;Existed=$exists;SHA256=$hash}
    })
    $registry=@(foreach ($spec in $RegistrySpecs) { Get-TerminalRegistryState $spec })
    $manifest=[pscustomobject]@{Version=2;Timestamp=(Get-Date -Format o);Files=$files;Registry=$registry}
    Set-TerminalText (Join-Path $Directory 'manifest.json') ($manifest | ConvertTo-Json -Depth 8)
    return $Directory
}

function Read-TerminalSnapshot {
    param([string]$Directory, [string]$Msys2InstallPath, [string]$CmdTargetDir)
    $Directory=(Resolve-Path -LiteralPath $Directory -ErrorAction Stop).ProviderPath
    $manifestPath=Join-Path $Directory 'manifest.json'
    Assert-TerminalRegularFile $manifestPath
    $manifest=[IO.File]::ReadAllText($manifestPath) | ConvertFrom-Json
    if ($manifest.Version -and $manifest.Version -ne 2) { throw 'Unsupported snapshot version.' }
    if (@($manifest.Files).Count -eq 0 -or @($manifest.Files).Count -gt 30) { throw 'Invalid snapshot file count.' }
    $allowed=@{}
    foreach ($target in (Get-TerminalTargets -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir)) { $allowed[$target.Name]=$target.Target }
    $seen=@{}
    foreach ($entry in $manifest.Files) {
        if (-not $entry.Name -or -not $allowed.ContainsKey($entry.Name) -or $seen.ContainsKey($entry.Name) -or
            -not [IO.Path]::IsPathRooted($entry.Target) -or [IO.Path]::GetFullPath($entry.Target) -ne $allowed[$entry.Name] -or
            $entry.Existed -isnot [bool]) { throw "Invalid snapshot target: $($entry.Name) / $($entry.Target)" }
        $seen[$entry.Name]=$true
        Assert-TerminalRegularFile $entry.Target
        if ($entry.Existed) {
            $source=Join-Path $Directory $entry.Name
            Assert-TerminalRegularFile $source
            if ($entry.SHA256 -notmatch '^[a-fA-F0-9]{64}$' -or (Get-TerminalHash $source) -ne $entry.SHA256) {
                throw "Snapshot SHA256 verification failed: $source"
            }
        }
    }
    $allowedRegistry=@(Get-TerminalRegistrySpecs)
    $seenRegistry=@{}
    foreach ($entry in @($manifest.Registry)) {
        if ($null -eq $entry) { continue }
        $identity="$($entry.Key)|$($entry.Name)"
        if (-not @($allowedRegistry | Where-Object { $_.Key -eq $entry.Key -and $_.Name -eq $entry.Name }).Count -or
            $seenRegistry.ContainsKey($identity) -or $entry.Existed -isnot [bool]) { throw "Invalid snapshot registry target: $identity" }
        $seenRegistry[$identity]=$true
        if (-not $entry.PSObject.Properties['Kind']) { $entry | Add-Member NoteProperty Kind 'String' }
        if ($entry.Kind -notin @('String','ExpandString') -or ($entry.Existed -and $entry.Value -isnot [string])) { throw 'Invalid registry value type.' }
    }
    return $manifest
}

function Save-TerminalInstallContext {
    param([string]$Directory, [string]$Msys2InstallPath)
    # Local installation state lives outside snapshots. Never learn allowed roots from an imported manifest.
    $projectRoot=Split-Path -Parent $PSScriptRoot
    $context=@{Version=1;BackupDirectory=[IO.Path]::GetFullPath($Directory);Msys2InstallPath=$Msys2InstallPath}
    Set-TerminalText (Join-Path $projectRoot '.last-install-context.json') ($context | ConvertTo-Json)
}

function Add-TerminalMsysSnapshot {
    param([string]$Directory, [string]$Msys2InstallPath)
    $manifest=Read-TerminalSnapshot -Directory $Directory -Msys2InstallPath $Msys2InstallPath
    if (@($manifest.Files | Where-Object Name -eq 'msys2_bashrc').Count) { throw 'MSYS2 was already captured.' }
    $staging=Join-Path $Directory ('msys-before-' + [guid]::NewGuid().ToString('N'))
    $null=New-TerminalSnapshot -Directory $staging -Targets @(Get-TerminalTargets -Msys2InstallPath $Msys2InstallPath -Components MSYS2) -RegistrySpecs @(Get-TerminalRegistrySpecs MSYS2)
    $extra=Read-TerminalSnapshot -Directory $staging -Msys2InstallPath $Msys2InstallPath
    foreach ($entry in $extra.Files) {
        if ($entry.Existed) { Set-TerminalBytes (Join-Path $Directory $entry.Name) ([IO.File]::ReadAllBytes((Join-Path $staging $entry.Name))) }
    }
    $manifest.Files=@($manifest.Files)+@($extra.Files)
    $manifest.Registry=@($manifest.Registry)+@($extra.Registry)
    Set-TerminalText (Join-Path $Directory 'manifest.json') ($manifest | ConvertTo-Json -Depth 8)
    $pointer=Join-Path (Split-Path -Parent $PSScriptRoot) '.last-install-backup'
    if ([IO.File]::Exists($pointer) -and [IO.Path]::GetFullPath([IO.File]::ReadAllText($pointer).Trim()) -eq [IO.Path]::GetFullPath($Directory)) {
        Save-TerminalInstallContext -Directory $Directory -Msys2InstallPath ([IO.Path]::GetFullPath($Msys2InstallPath))
    }
}

function Resolve-TerminalTool {
    param([string]$Name)
    # Resolve only absolute PATH entries under established installation roots; never the working directory.
    $roots=@($env:ProgramFiles, ${env:ProgramFiles(x86)}, $env:SystemRoot, "$env:USERPROFILE\scoop", $env:SCOOP,
             "$env:LOCALAPPDATA\Programs", "$env:LOCALAPPDATA\Microsoft\WinGet", "$env:LOCALAPPDATA\clink", $env:ChocolateyInstall)
    foreach ($directory in ($env:PATH -split ';')) {
        $directory=$directory.Trim(' ', '"')
        if (-not $directory -or -not [IO.Path]::IsPathRooted($directory)) { continue }
        $full=[IO.Path]::GetFullPath($directory).TrimEnd('\')
        if ($full -eq [IO.Path]::GetFullPath($PWD.Path).TrimEnd('\')) { continue }
        $trusted=$false
        foreach ($root in $roots) {
            if ($root -and ($full -eq $root.TrimEnd('\') -or $full.StartsWith($root.TrimEnd('\')+'\', [StringComparison]::OrdinalIgnoreCase))) { $trusted=$true; break }
        }
        if (-not $trusted) { continue }
        $candidate=Join-Path $full $Name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            if ($candidate -match '[%!^&|<>"\r\n]') { throw "Unsupported characters in executable path: $candidate" }
            return $candidate
        }
    }
    return $null
}

function Restore-TerminalSnapshot {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param([string]$Directory, [string]$Msys2InstallPath, [string]$CmdTargetDir, [string[]]$Components=@('All'))
    $manifest=Read-TerminalSnapshot -Directory $Directory -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir
    $selected=@(Get-TerminalTargets -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir -Components $Components)
    $files=@($manifest.Files | Where-Object { $_.Name -in $selected.Name })
    $registrySpecs=@(Get-TerminalRegistrySpecs $Components)
    $registry=@($manifest.Registry | Where-Object { $r=$_; $r -and @($registrySpecs | Where-Object { $_.Key -eq $r.Key -and $_.Name -eq $r.Name }).Count })
    if (-not $PSCmdlet.ShouldProcess($Directory, 'Restore verified snapshot; save all current content first')) { return }
    $rescue=Join-Path $Directory ('pre-rollback-' + [guid]::NewGuid().ToString('N'))
    $null=New-TerminalSnapshot -Directory $rescue -Targets $files -RegistrySpecs $registry
    $prior=Read-TerminalSnapshot -Directory $rescue -Msys2InstallPath $Msys2InstallPath -CmdTargetDir $CmdTargetDir
    $journal=Join-Path $rescue 'restore-status.json'
    Set-TerminalText $journal (@{Status='Applying';Source=$Directory;Rescue=$rescue} | ConvertTo-Json)
    try {
        foreach ($entry in $files) {
            $saved=@($prior.Files | Where-Object Name -eq $entry.Name)[0]
            if ([IO.File]::Exists($entry.Target) -ne $saved.Existed -or
                ($saved.Existed -and (Get-TerminalHash $entry.Target) -ne $saved.SHA256)) { throw "Concurrent edit: $($entry.Target)" }
            if ($entry.Existed) {
                $source=Join-Path $Directory $entry.Name
                if ((Get-TerminalHash $source) -ne $entry.SHA256) { throw 'Snapshot changed during restore.' }
                Set-TerminalBytes $entry.Target ([IO.File]::ReadAllBytes($source))
                if ((Get-TerminalHash $entry.Target) -ne $entry.SHA256) { throw 'Restored bytes did not match snapshot.' }
            } elseif ([IO.File]::Exists($entry.Target)) { [IO.File]::Delete($entry.Target) }
        }
        foreach ($entry in $registry) { Set-TerminalRegistryState $entry }
        Set-TerminalText $journal (@{Status='Completed';Source=$Directory;Rescue=$rescue} | ConvertTo-Json)
    } catch {
        # Durable rescue remains usable even after interruption; do not overwrite concurrent edits automatically.
        Set-TerminalText $journal (@{Status='Failed';Source=$Directory;Rescue=$rescue;Error="$($_.Exception.Message)"} | ConvertTo-Json)
        throw "Restore incomplete. Current content was saved to $rescue. $($_.Exception.Message)"
    }
    Write-Host "Restore completed. Rescue snapshot: $rescue"
}
