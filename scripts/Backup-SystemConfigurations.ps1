# Backup all system terminal and shell configurations into project
$ErrorActionPreference = 'Stop'
$projectRoot = 'C:\XMWJJ\powershelldome'
$backupDir = Join-Path $projectRoot "backups\system-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$manifest = @{
    Timestamp = (Get-Date -Format o)
    Files = @()
    Registry = @()
}

function Backup-File {
    param([string]$SourcePath, [string]$RelativeDest)
    if (Test-Path -LiteralPath $SourcePath -PathType Leaf) {
        $dest = Join-Path $backupDir $RelativeDest
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item -LiteralPath $SourcePath -Destination $dest -Force
        $hash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256).Hash
        $size = (Get-Item -LiteralPath $SourcePath).Length
        $manifest.Files += @{
            Source = $SourcePath
            Backup = $RelativeDest
            SHA256 = $hash
            SizeBytes = $size
        }
        Write-Host "Backed up: $SourcePath -> $RelativeDest ($hash)" -ForegroundColor Green
    } else {
        Write-Host "File not found, skipped: $SourcePath" -ForegroundColor DarkGray
    }
}

# 1. CMD / Clink configs
Backup-File "$env:LOCALAPPDATA\clink\starship.lua" "cmd\clink\starship.lua"
Backup-File "$env:LOCALAPPDATA\clink\clink_history" "cmd\clink\clink_history"
Backup-File "$env:LOCALAPPDATA\clink\default_inputrc" "cmd\clink\default_inputrc"
Backup-File "$env:LOCALAPPDATA\clink\default_settings" "cmd\clink\default_settings"

# 2. PowerShell profiles
Backup-File "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" "powershell\PowerShell7_profile.ps1"
Backup-File "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" "powershell\WinPS51_profile.ps1"

# 3. Windows Terminal settings
Backup-File "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" "terminal\WindowsTerminal_stable_settings.json"
Backup-File "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json" "terminal\WindowsTerminal_preview_settings.json"

# 4. Fastfetch configs
Backup-File "$env:USERPROFILE\.config\fastfetch\config.jsonc" "fastfetch\config.jsonc"
Backup-File "$env:USERPROFILE\.config\fastfetch\ascii.txt" "fastfetch\ascii.txt"

# 5. Starship config
Backup-File "$env:USERPROFILE\.config\starship.toml" "starship\starship.toml"

# 6. NuShell configs
Backup-File "$env:APPDATA\nushell\config.nu" "nushell\config.nu"
Backup-File "$env:APPDATA\nushell\env.nu" "nushell\env.nu"

# 7. Registry Command Processor export
$regCu = Get-ItemProperty 'HKCU:\Software\Microsoft\Command Processor' -ErrorAction SilentlyContinue
$regLm = Get-ItemProperty 'HKLM:\Software\Microsoft\Command Processor' -ErrorAction SilentlyContinue
$manifest.Registry += @{
    Key = 'HKCU:\Software\Microsoft\Command Processor'
    Properties = if ($regCu) {
        @{
            AutoRun = $regCu.AutoRun
            CompletionChar = $regCu.CompletionChar
            DefaultColor = $regCu.DefaultColor
            EnableExtensions = $regCu.EnableExtensions
        }
    } else { $null }
}
$manifest.Registry += @{
    Key = 'HKLM:\Software\Microsoft\Command Processor'
    Properties = if ($regLm) {
        @{
            AutoRun = $regLm.AutoRun
            CompletionChar = $regLm.CompletionChar
            DefaultColor = $regLm.DefaultColor
            EnableExtensions = $regLm.EnableExtensions
        }
    } else { $null }
}

# Save manifest
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $backupDir "manifest.json") -Encoding UTF8
Write-Host "`nBackup completed successfully. Manifest saved to: $backupDir\manifest.json" -ForegroundColor Cyan
