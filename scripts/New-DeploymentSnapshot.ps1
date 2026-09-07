# ============================================================================
# 创建部署快照脚本 (捕获当前系统实时配置与待部署暂存文件，生成 SHA-256 清单)
# ============================================================================
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TerminalState.ps1')
$projectRoot = Split-Path -Parent $PSScriptRoot
$timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N')
$deployDir = Join-Path $projectRoot "backups\deployment-$timestamp"
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null

$livePs = Join-Path (Get-TerminalDocumentsPath) 'PowerShell/Microsoft.PowerShell_profile.ps1'
$liveWt = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'

$stagedPs = Join-Path $projectRoot 'Microsoft.PowerShell_profile.ps1'
$stagedWt = Join-Path $projectRoot 'settings.json'

# 1. 将系统当前实时文件复制为 .before 原始快照
Copy-Item -LiteralPath $livePs -Destination (Join-Path $deployDir 'PowerShell7-profile.before.ps1') -Force
Copy-Item -LiteralPath $liveWt -Destination (Join-Path $deployDir 'Terminal-stable.before.json') -Force

# 2. 将项目待部署文件复制为 .after 目标快照
Copy-Item -LiteralPath $stagedPs -Destination (Join-Path $deployDir 'PowerShell7-profile.after.ps1') -Force
Copy-Item -LiteralPath $stagedWt -Destination (Join-Path $deployDir 'Terminal-stable.after.json') -Force

# 3. 将管理脚本拷贝入快照目录，确保该快照具备独立自包含回退能力

# 4. 计算哈希并生成原子清单 deployment.json
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

Write-Host "已创建部署快照目录: $deployDir" -ForegroundColor Green
Write-Host "已更新部署路径标记 (.deployment-path): $deployDir" -ForegroundColor Cyan
$deployDir
