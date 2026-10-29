# Windows 终端美化与使用说明

本文件说明当前配置的外观、主题、快捷键和常见问题。项目截图见[中文 README](README.zh-CN.md#项目展示截图)，安装与恢复操作见[部署与回退](部署与回退.md)。

## 外观配置与展示截图

[settings.json](settings.json) 是 Windows Terminal 设置模板，当前 `profiles.defaults` 使用 Catppuccin Mocha、`opacity: 80`、`useAcrylic: true`，光标为竖线。字体大小为 11，行高为 `1.2`，字体候选为 `JetBrainsMono NFM, JetBrainsMono NF, JetBrainsMono Nerd Font Mono, Cascadia Code`。各 Profile 可覆盖默认值，实际效果也受 Terminal 版本、系统透明效果和字体安装影响。

模板当前仍含作者本机的背景路径：

```json
{
  "backgroundImage": "%USERPROFILE%\\Pictures\\壁纸文件\\dde5a5767u6579.jpg",
  "backgroundImageOpacity": 0.4,
  "backgroundImageStretchMode": "uniformToFill"
}
```

这是相关字段示例，不是完整 settings.json。部署到其他电脑前，将 `backgroundImage` 换成自己的图片路径，或删除该字段以使用纯色 / 亚克力背景。README 的 assets 图片是项目展示截图，不是脚本自动使用的壁纸。通过 Terminal 的设置 → 默认值或某个配置文件 → 外观选择背景图片，也可以进行同样调整；[官方外观配置说明](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/profile-appearance)解释了相关字段。

## 字体

```powershell
# 从项目目录安装 48 个本地 TTF，默认作用于当前用户。
powershell.exe -NoProfile -File .\Install-Fonts.ps1
```

等宽终端优先选择 `JetBrainsMono NFM`，也可选择已安装的 `JetBrainsMono NF`；`NFP` 为比例版本，不作为等宽对齐的首选。普通 JetBrains Mono 不包含同一套 Nerd Font 图标。安装器会尝试注册并发送字体变更通知；如果应用还看不到字体，关闭并重开应用，再检查 Windows 字体设置。多级候选字体不能保证所有字体缺失提示都不会出现。

独立字体脚本只读取本地 `fonts/`，目录缺失或没有 TTF 时会报错。工具安装中的字体分支另有包管理器 / 下载回退，不能将两者混为一谈。IDE 需要单独选择终端字体，见[IDE 指南](IDE与开发工具集成指南.md)。

## PowerShell 主题与环境开关

PS7 和 PS5.1 安装后共用同一份 Profile 源码，默认 `random`。随机主题从本地主题目录抽取，每次交互加载都可能变化，也可能重复；数量由实际安装的 Oh My Posh 主题库决定。`fixed` 默认尝试 Catppuccin Mocha，`starship` 使用 Starship。

| 环境变量 | 未设置时的行为 | 可用设置 |
| --- | --- | --- |
| `POWERSHELL_THEME_MODE` | 随机主题（安装器可写入其他默认值） | `random` / `fixed` / `starship` |
| `POWERSHELL_POSH_THEME` | 使用模式对应的候选主题 | 固定模式下可指定本地 `.omp.json` 绝对路径；`starship` 可切换引擎 |
| `POWERSHELL_PROFILE_MINIMAL` | 按交互环境判断是否完整初始化 | `1` 跳过提示符和 UI 集成 |
| `POWERSHELL_PROFILE_BANNER` | 开启 Fastfetch 横幅 | `0` 关闭 |
| `POWERSHELL_PROFILE_TIPS` | 开启工具提示卡与主题名称输出 | `0` 关闭 |
| `POWERSHELL_PROFILE_ICONS` | 导入 Terminal-Icons（可用时） | `0` 关闭 |
| `POWERSHELL_PROFILE_VFOX` | 不自动激活 vfox | `1` 自动激活；也可手动 `Enable-Vfox` |
| `POSH_THEMES_PATH` | 优先使用用户 `oh-my-posh-themes` 目录 | 提供额外本地主题路径 |

当前源码未读取 `POWERSHELL_PREDICTION_VIEW`。预测显示由 PSReadLine 可用参数决定，当前设置为 `InlineView`；不要依赖不存在的开关。

```powershell
# 当前会话中切换，再加载 Profile；变量只在本进程和子进程继承。
$env:POWERSHELL_THEME_MODE = 'fixed'
$env:POWERSHELL_POSH_THEME = Join-Path $env:USERPROFILE 'oh-my-posh-themes/catppuccin_mocha.omp.json'
$env:POWERSHELL_PROFILE_BANNER = '0'
$env:POWERSHELL_PROFILE_TIPS = '0'
. $PROFILE
```

若需要新开的终端持续使用某个设置，将对应赋值放在个人 Profile 的初始化之前，或设置用户环境变量后重启 Terminal / IDE。已打开的父进程可能仍持有旧环境；从当前 Shell 启动的子进程会继承当前值。重新运行安装或部署可能覆盖手工修改的 Profile。用最小模式重新加载也不会自动卸载当前会话已经加载的提示符、模块或按键处理器，验证最小环境应新开进程。

## Fastfetch 与中文提示卡

[fastfetch/config.jsonc](fastfetch/config.jsonc) 定义信息模块和配色，[fastfetch/ascii.txt](fastfetch/ascii.txt) 提供字符画。安装辅助函数复制到 `~/.config/fastfetch/` 并将字符画路径写为当前机器实际路径。

在交互 PowerShell 中运行 `Show-SystemInfo` 可重新查看系统信息，`Show-FeatureTips` 可重新显示工具提示卡。横幅和提示卡分别受 BANNER、TIPS 开关控制；只关闭横幅不会自动隐藏提示卡。提示卡用于快速查看命令，不应把某一行的文字当成完整环境验证；检查依赖使用 `Test-Environment`。

## 常用操作

| 场景 | PowerShell 命令 / 快捷键 |
| --- | --- |
| 列表、隐藏文件、两层树、三层树 | `ll`、`la`、`lt`、`lt3` |
| Git 状态目录列表 | `llg` |
| 高亮预览 | `catc <文件>`；PowerShell `cat` 仍是 Get-Content |
| 目录跳转 | `z <关键词>`、`zi`、`Alt+Z`（需要 zoxide / fzf） |
| 搜索历史 / 选择文件 | `Ctrl+R` / `Ctrl+F`（需要 PSReadLine、PSFzf、fzf） |
| 模糊文件编辑 / 全文检索 | `fv` / `fif <关键词>` |
| 文件管理 / Git 面板 | `y` / `lg`；可用时 `Ctrl+G` 调用 lazygit |
| 创建并进入目录 | `mkcd <目录>` |
| 大文件查找 | `Find-LargeFiles -TopN 10` |
| 编辑 / 重新加载配置 | `Edit-Profile` / `Update-Profile` |
| 检查依赖 | `Test-Environment` |

CMD 的 `cat` 等是 Doskey 宏，NuShell 和 MSYS2 使用自身配置生成的别名，作用域与依赖均可能不同。不要用 PowerShell 的快捷键表推断所有 Shell 的行为。

Terminal 宿主快捷键由 `settings.json` 决定：`Ctrl+Shift+T` 新建标签、`Ctrl+Shift+W` 关闭窗格、`Alt+Shift+D` 复制拆分、`Alt+Shift+Minus` 水平拆分、`Alt+Shift+Plus` 垂直拆分、`Ctrl+Shift+F` 查找、`Ctrl+Shift+P` 命令面板、`Alt+方向键` 切换窗格焦点。宿主快捷键和 Shell 内快捷键是两层配置。

## 常见问题

### 找不到 pwsh、nu 或 MSYS2

默认总装不包含 NuShell/MSYS2。需要时运行对应安装器或总装 `-All`。确认程序已安装、PATH 已刷新，并新开终端。MSYS2 非默认目录传 `-Msys2InstallPath`。PS7 安装器的完整模板应用会尝试隐藏不可用入口；原样配置部署不做同样检查，因此不能只凭菜单存在就断定 Shell 已安装。

### 为什么没有 Windows Terminal

本项目配置终端与 Shell，但不负责安装 Windows Terminal 宿主。可按 [Windows Terminal 官方安装说明](https://learn.microsoft.com/en-us/windows/terminal/install)安装适用于系统的版本；不要把 Windows PowerShell 5.1 语法兼容理解为 Windows Terminal 支持 Windows 8.1。

### 中文显示乱码或图标方块

先区分字体缺字、文件编码与进程输出编码。检查终端实际选中的 Nerd Font、源文件是否采用正确编码、`[Console]::OutputEncoding.CodePage` 与 `$OutputEncoding.CodePage` 是否为 65001。Profile 设置 UTF-8 不会自动修复已经保存为错误编码的文件或所有第三方程序的输出。PS5.1 读取含中文脚本时还需留意 UTF-8 BOM。

### 启动慢

先在真实交互新进程中测量，按需关闭 BANNER、TIPS、ICONS，保持 VFOX 默认关闭。`Enable-Vfox` 可在需要时手动执行；最小模式会跳过更多初始化。截图中的耗时和历史审计数据都不是当前环境的保证。测量命令与范围见[开发文档](开发与部署文档.md#性能测量)。

### 执行策略阻止运行

先核实脚本来源，再按[部署文档](部署与回退.md)的进程级命令执行。安装器可能另外调整当前用户策略；组织强制策略应按组织要求处理。不要为消除提示递归解除整个用户目录的下载标记。

### 更新工具后出现兼容问题

先确认工具由哪个包管理器安装，再单独更新需要的工具。模块安装器使用固定版本列表；若调整版本，同步检查 PS7 / PS5.1、生成配置与交互行为，避免把 `Update-Module` 后的新版本当作已经过项目验证。
