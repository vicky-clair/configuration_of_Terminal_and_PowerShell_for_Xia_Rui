# Windows Terminal 与 PowerShell 配置

本项目保存可维护的配置源文件，建议使用 PowerShell 7。终端配色继续使用 Catppuccin Mocha，保留壁纸、透明度、字体及原有终端入口。

## 文件

| 文件 | 用途 |
| --- | --- |
| `settings.json` | Windows Terminal 配置，以此文件为准 |
| `Microsoft.PowerShell_profile.ps1` | 独立 PowerShell 启动脚本，以此文件为准 |
| `tests/Verify-Configuration.ps1` | 无需额外模块的回归检查 |
| `backups/original/` | 优化前配置和完整说明，包含原始启动脚本 |

此次只修改项目文件，系统正在使用的 `$PROFILE` 和 Terminal 设置没有自动被覆盖。当前目录不是 Git 仓库。

## 优化内容

- 删除动画中的 16 次 50 ms 等待，消除固定约 800 ms 延迟；删除强制清屏和随机欢迎语。
- 不再启动时联网下载主题或扫描目录随机选主题。优先使用 `$env:POSH_THEMES_PATH/jandedobbeleer.omp.json`，其次使用个人 `oh-my-posh-themes` 目录中的同名文件；都不存在则保留默认提示符。
- 使用官方的 `oh-my-posh init pwsh --config ...` 语法。
- Scoop shims 只在目录存在且 PATH 缺失时追加，支持自定义 `$env:SCOOP`，重复加载不再重复追加。
- 配置控制台编码与 `$OutputEncoding`，不额外启动 `chcp.exe`。这不改变 Windows PowerShell 5.1 的 `Out-File` 默认编码，写文件仍应明确指定编码。
- 为可选 CLI 和模块检查依赖；PSReadLine 预测按参数支持情况及终端能力启用。
- 修复 Git 函数丢失参数，例如 `gco feature/login` 现在会转发分支名。
- 原 `gl` 函数被内置 `Get-Location` 别名遮住；Git 日志改为 `glog`，保留原生 `gl`。函数调用中需传递字面量 `--` 时请加引号，例如 `gco '--' 文件名`。
- 保留 `dir`、`ls`、`cat` 原生对象管道语义，用 `ll`、`la`、`catc` 展示彩色内容。
- Ctrl+Z 恢复撤销；Alt+Z 在 zoxide 和 fzf 都可用时启用，目录跳转支持包含方括号的路径。
- 预测默认行内显示，减少占屏；Fastfetch 和 Terminal-Icons 按需开启。
- 重定向、非交互及精简模式跳过提示符和 UI 集成，仍配置 PATH、编码及便捷函数。
- Terminal 壁纸路径改用 `%USERPROFILE%`；NuShell 通过 PATH 中的 `nu.exe` 启动，不绑定用户名和 Scoop 路径。

保留 Ctrl+C 复制、Ctrl+V 粘贴习惯。Terminal 无选区时会将 Ctrl+C 传递给终端程序，原配置这一点不需要修复。

## 本机检查

执行环境找到 Oh My Posh 27.5.2、vfox 0.9.2、Fastfetch、eza、bat，以及 PSReadLine 2.4.5、PSFzf 2.7.3、Terminal-Icons 0.11.0。PATH 中未找到 zoxide 和 fzf；只有 PSFzf 模块不足以启用搜索。实际 Terminal 的 PATH 可能不同，可在其中运行 `Get-Command zoxide,fzf` 复核。

原壁纸文件存在。项目未包含 Fastfetch 的 `config.jsonc`、自定义主题、NuShell 配置和壁纸素材，仍不是这些工具的完整备份。缺少 Fastfetch 配置时，新脚本使用工具默认配置。

## 试用和应用

先在新的 PowerShell 窗口临时试用，退出该窗口即可结束本次会话的变更：

```powershell
pwsh -NoLogo -NoProfile -NoExit -Command ". 'C:\XMWJJ\powershelldome\Microsoft.PowerShell_profile.ps1'"
```

请用全新的 `-NoProfile` 会话；旧脚本已经定义的 `dir` 函数、`cat` 别名不会因加载新脚本而消失。

确认效果后，在希望配置的 PowerShell 版本中执行以下命令：先备份当前用户 Profile，再写入项目加载入口。原 Profile 中其他定制应先核对并迁移。

```powershell
$profileSource = 'C:\XMWJJ\powershelldome\Microsoft.PowerShell_profile.ps1'
if (-not (Test-Path -LiteralPath $profileSource -PathType Leaf)) { throw '找不到项目启动脚本' }
$profileTarget = $PROFILE.CurrentUserCurrentHost
$profileBackup = "$profileTarget.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss-fff')"
if (Test-Path -LiteralPath $profileTarget) {
    Copy-Item -LiteralPath $profileTarget -Destination $profileBackup -ErrorAction Stop
    Write-Host "旧 Profile 已备份：$profileBackup"
}
New-Item -ItemType Directory -Path (Split-Path -Parent $profileTarget) -Force | Out-Null
$profileLoader = ". '" + $profileSource.Replace("'", "''") + "'"
Set-Content -LiteralPath $profileTarget -Value $profileLoader -Encoding UTF8
```

入口依赖项目路径，移动项目后需要修改入口。也可直接复制脚本到 `$PROFILE`，后续手动同步。PowerShell 7 与 Windows PowerShell 5.1 的 `$PROFILE` 不同，分别配置；不要让多个 Profile 文件重复初始化第三方工具。

Terminal：打开“设置 → 打开 JSON 文件”，先另存实时配置备份，再替换为本项目 `settings.json`。动态 Profile GUID 沿用原配置；迁移电脑后应以新电脑自动生成的 GUID 为准。MSYS2 仍假定安装在 `C:\msys64`；NuShell 需要 `nu.exe` 位于 PATH。不使用壁纸时可删除 `backgroundImage`。

回退：把上述 `.bak-时间戳` 文件复制回对应 `$PROFILE`，恢复自己另存的 Terminal 设置，再重新开窗。`backups/original/settings.json` 是项目优化前版本，未必等同于应用前的实时配置。

## 个性化

在 `$PROFILE` 的点加载语句之前设置需要的开关：

```powershell
$env:POWERSHELL_PROFILE_BANNER = '1'  # 启动时显示 Fastfetch，默认关闭
$env:POWERSHELL_PROFILE_ICONS = '1'   # 加载 Terminal-Icons，默认关闭
$env:POWERSHELL_PROFILE_VFOX = '0'    # 禁用 vfox，默认启用
$env:POWERSHELL_POSH_THEME = "$env:USERPROFILE\oh-my-posh-themes\agnoster.omp.json"
. 'C:\XMWJJ\powershelldome\Microsoft.PowerShell_profile.ps1'
```

主题只接受已有本地文件；不存在时保留默认提示符。恢复默认行为可删除相应赋值再开窗。加载前设置 `$env:POWERSHELL_PROFILE_MINIMAL = '1'` 可跳过所有交互集成。

| 操作 | 命令或按键 |
| --- | --- |
| 彩色目录 / 含隐藏项 | `ll` / `la` |
| 彩色文件，不分页 | `catc README.md` |
| 原生文件对象 | `dir -File`、`cat 文件路径` |
| 系统信息 | `Show-SystemInfo` |
| Git | `gst -sb`、`gco 分支名`、`gb -a`、`glog -10` |
| 历史前缀搜索 | 输入前缀后 ↑ / ↓ |
| 撤销输入 | Ctrl+Z |
| 选择历史 / 文件 | Ctrl+R / Ctrl+F，需要 fzf 和 PSFzf |
| 智能目录 / 选择目录 | `z 关键词` / Alt+Z，需要 zoxide，后者还需 fzf |

喜欢列表预测时，交互加载后运行 `Set-PSReadLineOption -PredictionViewStyle ListView`（需要支持该参数的 PSReadLine）。

## 安装和维护

只安装缺少的依赖。在普通用户 PowerShell 中按照 [Scoop 官方说明](https://scoop.sh/) 安装 Scoop。CLI 由 Scoop 管理，PowerShell 模块由 PowerShell Gallery 管理。

```powershell
scoop install git pwsh oh-my-posh vfox fastfetch eza bat zoxide fzf
scoop bucket add nerd-fonts
scoop install nerd-fonts/JetBrainsMono-NF
Install-Module PSReadLine -Scope CurrentUser
Install-Module PSFzf -Scope CurrentUser
# 仅启用图标开关时需要
Install-Module Terminal-Icons -Scope CurrentUser
```

使用稳定版模块，不默认开启 `-AllowPrerelease` 或 `-SkipPublisherCheck`。遇到发布者或版本冲突，先核对报错。Scoop 的 Oh My Posh 包已经包含主题，无需在启动时另行下载。

原文的 ffmpeg、poppler、imagemagick、resvg 等属于额外文件预览需求，本配置不依赖它们。`versions` bucket 也不是所有版本管理器的必备源，按包需求添加。

```powershell
scoop update
scoop update *
Get-Module -ListAvailable PSReadLine,PSFzf,Terminal-Icons
Get-Command oh-my-posh,vfox,fastfetch,eza,bat,zoxide,fzf -ErrorAction SilentlyContinue
```

确认升级后正常再按需执行 `scoop cleanup *`，它会删除旧版本，影响降级。

## 验证

```powershell
pwsh -NoProfile -File .\tests\Verify-Configuration.ps1
powershell.exe -NoProfile -File .\tests\Verify-Configuration.ps1
```

检查 JSON、GUID、默认 Profile、按键引用、脚本语法、静默加载、PATH 幂等、原生别名、Git 参数和无工具降级。测试不安装依赖，不修改用户 Profile；不代替 Terminal 渲染、交互快捷键和第三方提示符初始化验收。

本机 Windows PowerShell 5.1 执行策略禁止运行脚本，因此仅进行语法解析，不声称已完成该版本的运行测试，也不自动修改执行策略。

实际启动耗时应在相同 PowerShell、目录、主题和依赖条件下比较多次新窗口。非交互测试跳过美化，不能用其耗时声称完整交互启动的加速比例。

## 官方参考

- [Oh My Posh 初始化](https://ohmyposh.dev/docs/installation/prompt)与[本地主题](https://ohmyposh.dev/docs/installation/customize)
- [PSReadLine 参数及版本支持](https://learn.microsoft.com/en-us/powershell/module/psreadline/set-psreadlineoption)
- [PSFzf 依赖和快捷键](https://github.com/kelleyma49/PSFzf)
- [Windows Terminal 操作](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/actions)
