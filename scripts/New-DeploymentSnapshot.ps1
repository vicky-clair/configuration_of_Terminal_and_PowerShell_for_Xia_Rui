# Creates a new deployment snapshot from live system and staged files
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$deployDir = Join-Path $projectRoot "backups\deployment-$timestamp"
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null

$livePs = Join-Path $env:USERPROFILE 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
$liveWt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

$stagedPs = Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'
$stagedWt = Join-Path $projectRoot 'settings.json'

# Copy live files as .before
Copy-Item -LiteralPath $livePs -Destination (Join-Path $deployDir 'PowerShell7-profile.before.ps1') -Force
Copy-Item -LiteralPath $liveWt -Destination (Join-Path $deployDir 'Terminal-stable.before.json') -Force

# Copy staged files as .after
Copy-Item -LiteralPath $stagedPs -Destination (Join-Path $deployDir 'PowerShell7-profile.after.ps1') -Force
Copy-Item -LiteralPath $stagedWt -Destination (Join-Path $deployDir 'Terminal-stable.after.json') -Force

# Copy Manage-TerminalConfiguration.ps1 into the backup directory for independent rollback
Copy-Item -LiteralPath (Join-Path $projectRoot 'Manage-TerminalConfiguration.ps1') -Destination (Join-Path $deployDir 'Manage-TerminalConfiguration.ps1') -Force

$manifest = @{
    Created = (Get-Date -Format o)
    Files = @(
        @{
            Target = $livePs
            Before = 'PowerShell7-profile.before.ps1'
            After = 'PowerShell7-profile.after.ps1'
            BeforeSHA256 = (Get-FileHash -LiteralPath (Join-Path $deployDir 'PowerShell7-profile.before.ps1') -Algorithm SHA256).Hash
            AfterSHA256 = (Get-FileHash -LiteralPath (Join-Path $deployDir 'PowerShell7-profile.after.ps1') -Algorithm SHA256).Hash
        },
        @{
            Target = $liveWt
            Before = 'Terminal-stable.before.json'
            After = 'Terminal-stable.after.json'
            BeforeSHA256 = (Get-FileHash -LiteralPath (Join-Path $deployDir 'Terminal-stable.before.json') -Algorithm SHA256).Hash
            AfterSHA256 = (Get-FileHash -LiteralPath (Join-Path $deployDir 'Terminal-stable.after.json') -Algorithm SHA256).Hash
        }
    )
}

$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $deployDir 'deployment.json') -Encoding UTF8
Set-Content -LiteralPath (Join-Path $projectRoot '.deployment-path') -Value $deployDir -Encoding UTF8

Write-Host "Created deployment snapshot at: $deployDir" -ForegroundColor Green
Write-Host "Updated .deployment-path to: $deployDir" -ForegroundColor Cyan
$deployDir
