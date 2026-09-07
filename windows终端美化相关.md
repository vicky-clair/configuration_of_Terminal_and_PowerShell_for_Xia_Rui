# Windows 全终端美化与增强配置手册

本项目保存可维护的终端与 Shell 配置源文件，支持 **Windows Terminal**、**PowerShell 7**、**CMD (Command Prompt)** 与 **Windows PowerShell 5.1** 的统一美化与功能增强。

终端全局配色采用 **Catppuccin Mocha**，集成专属背景壁纸、高质感亚克力磨砂透明、`JetBrainsMono Nerd Font` 编程字体、`Fastfetch` 专属 ASCII 硬件横幅、`Oh My Posh` 极美主题、以及 `Clink + Starship` 的现代 CMD 终端环境。

---

## 📁 项目结构与配置清单

| 路径 / 文件 | 用途与定位 |
| --- | --- |
| [`settings.json`](file:///c:/XMWJJ/powershelldome/settings.json) | Windows Terminal 全局配置文件（配色、透明度、字体、Profile 入口） |
| [`Microsoft.PowerShell_profile.ps1`](file:///c:/XMWJJ/powershelldome/Microsoft.PowerShell_profile.ps1) | PowerShell 7 启动增强脚本（主题、Fastfetch、图标、快捷键、实用函数） |
| [`cmd/autorun.cmd`](file:///c:/XMWJJ/powershelldome/cmd/autorun.cmd) | CMD 自动初始化脚本（UTF-8 编码、Doskey 现代化别名、Clink 挂载） |
| [`cmd/clink/starship.lua`](file:///c:/XMWJJ/powershelldome/cmd/clink/starship.lua) | Clink 扩展脚本：在 CMD 中加载 Starship 赛博朋克渐变提示符 |
| [`cmd/clink/settings.lua`](file:///c:/XMWJJ/powershelldome/cmd/clink/settings.lua) | Clink 补全体验增强：历史预测、输入语法着色、模糊匹配 |
| [`cmd/Install-CmdConfiguration.ps1`](file:///c:/XMWJJ/powershelldome/cmd/Install-CmdConfiguration.ps1) | CMD 自动化部署/卸载脚本（写入当前用户 AutoRun 注册表） |
| [`Deploy-TerminalConfiguration.ps1`](file:///c:/XMWJJ/powershelldome/Deploy-TerminalConfiguration.ps1) | **一键部署脚本**：自动创建校验快照，并部署 Terminal、PowerShell、CMD |
| [`Restore-TerminalConfiguration.ps1`](file:///c:/XMWJJ/powershelldome/Restore-TerminalConfiguration.ps1) | **一键无损回退脚本**：按字节恢复部署前的系统环境，支持 `-IncludeCmd` |
| [`tests/Verify-Configuration.ps1`](file:///c:/XMWJJ/powershelldome/tests/Verify-Configuration.ps1) | 静态语法、JSON 合法性、GUID、别名与依赖回退自检 |
| [`tests/Verify-Deployment.ps1`](file:///c:/XMWJJ/powershelldome/tests/Verify-Deployment.ps1) | 独立沙箱部署与回退完整性测试 |
| [`IDE与开发工具集成指南.md`](file:///c:/XMWJJ/powershelldome/IDE与开发工具集成指南.md) | **IDE 集成专用指南**：VS Code 与 IntelliJ IDEA 内置终端字体、编码与环境配置 |
| [`backups/system-audit-20260907-082932/`](file:///c:/XMWJJ/powershelldome/backups/system-audit-20260907-082932/) | **系统原始配置快照**（包含原终端设置、Profiles、Clink、Fastfetch、NuShell 等） |

---

## 🎨 视觉与体验特性

### 1. Windows Terminal 外观
- **配色方案**：`Catppuccin Mocha`（底色 `#1E1E2E`，青蓝/粉紫/金黄点缀）。
- **字体**：`JetBrainsMono Nerd Font Mono`，字号 `11`，行高系数 `1.2`，完美支持所有图标与连字。
- **背景与亚克力**：支持亚克力毛玻璃模糊（`useAcrylic: true`，窗口不透明度 `80%`），并支持叠加自定义背景壁纸（推荐透明度 `0.4`，拉伸模式 `uniformToFill`；详见下方 [FAQ 与最佳实践](#-核心逻辑说明与配置最佳实践-faq)）。
- **光标风格**：竖线光标（`bar`），更加现代化。
- **快捷键**：保留原生 `Ctrl+C` / `Ctrl+V`，`Alt+Shift+D` 自动分屏，`Ctrl+Shift+F` 快速搜索。

### 2. PowerShell 7 体验
- **提示符**：默认加载与 Terminal 深度契合的 `catppuccin_mocha.omp.json` 主题，平滑显示当前目录、Git 分支与状态、执行耗时。
- **专属启动横幅**：交互模式下自动呈现 Fastfetch 专属 ASCII 图标与硬件指标（CPU、内存、硬盘占用）；非交互和重定向时自动静默。
- **文件夹图标**：集成 `Terminal-Icons`，`Get-ChildItem` 自动渲染精美文件/目录类型图标。
- **智能预测与高亮**：PSReadLine 金黄/青蓝配色，开启历史记录行内预测；输入前缀后可按 `↑` / `↓` 搜索历史命令；`Ctrl+Z` 撤销输入。
- **现代化导航与模糊检索**：
  - `z 目录名`：由 `zoxide` 瞬间跳转。
  - `Alt+Z`：调出 `zoxide` 交互式模糊检索跳转。
  - `Ctrl+F`：使用 `fzf` 交互式搜索并插入文件路径。
  - `Ctrl+R`：使用 `fzf` 搜索历史执行命令。

### 3. CMD (命令提示符) 体验
- **UTF-8 编码**：启动自动生效 `chcp 65001`，彻底解决中文乱码与 Nerd Font 图标方框问题。
- **现代化 CLI 别名 (Doskey)**：
  - `ls` / `ll` / `la`：自动映射至 `eza` 彩色图标排版。
  - `cat`：自动映射至 `bat` 语法高亮文件查看。
  - `grep`：映射至 `rg` (ripgrep) 高速正则检索。
  - `clear`：清屏。
  - `g`, `gst`, `gco`, `gb`, `glog`, `gpull`, `gps`：常用 Git 命令别名。
- **Clink 赋能**：集成 `Clink 1.8.8`，实现类 Bash 的 Tab 补全、历史上下翻阅、输入着色。
- **Starship 提示符**：挂载赛博朋克霓虹渐变提示符，与 PowerShell 体验相得益彰。

---

## 💡 核心逻辑说明与配置最佳实践 (FAQ)

### Q1: 运行安装脚本时，Windows Terminal 会自动同时安装吗？
**答：不会。**
- **脚本设计职责**：本项目的安装脚本（如 [`Install-All.ps1`](file:///c:/XMWJJ/powershelldome/Install-All.ps1)、[`Install-PowerShell7.ps1`](file:///c:/XMWJJ/powershelldome/Install-PowerShell7.ps1)）定位为**“环境配置与美化部署”**，而非宿主分发工具。
- **执行逻辑**：脚本在安装阶段会自动检测当前系统中是否已有 Windows Terminal 的安装目录：
  - 若检测到已安装，会提示并注入深度定制的 [`settings.json`](file:///c:/XMWJJ/powershelldome/settings.json)（配色、字体、快捷键、亚克力等）；
  - 若未检测到（如未安装 Terminal 的纯净环境），脚本会跳过 Terminal 配置，继续配置原生控制台（PowerShell / CMD / NuShell 等依然生效）。
- **如何提前安装 Windows Terminal**：
  - **Windows 11**：出厂自带，无需手动安装。
  - **Windows 10 / Server**：推荐提前安装以获取最佳体验：
    ```powershell
    winget install Microsoft.WindowsTerminal
    ```
    或直接前往 **Microsoft Store** 搜索 `Windows Terminal` 安装。

### Q2: 终端背景图片是否需要备份/打包到项目文件内？为什么推荐用户自行配置？
**答：强烈推荐由用户在 Terminal 图形界面中自行配置，不需要也不建议强行打包在项目中。**
原因如下：
1. **避免绝对路径跨机失效**：每个用户的计算机用户名和文件目录各异，在 `settings.json` 中写死特定路径（如 `%USERPROFILE%\Pictures\壁纸文件\...`）在其他电脑上会导致路径悬空或失效。
2. **审美与隐私高度个性化**：背景壁纸属于非常主观的个人视觉偏好（动漫、极简、赛博朋克、纯黑等），通用项目不宜强行绑定特定图片。
3. **Windows Terminal 原生图形界面极简易用**：自带直观可视化设置面板，支持实时无缝预览，操作仅需数秒。
4. **无图状态已有顶级质感**：项目已预置 Catppuccin Mocha 顶级暗色主题与 `useAcrylic: true`（80% 窗口不透明度），在没有背景壁纸时，会直接呈现通透深邃的亚克力磨砂毛玻璃黑曜石效果，极度耐看。
5. **保持 Git 仓库轻量**：避免将数兆至数十兆的二进制大图片放入 Git 历史。

#### 🖼️ 背景壁纸配置三步指引：
1. 打开 Windows Terminal，按快捷键 <kbd>Ctrl</kbd> + <kbd>,</kbd> 打开 **设置**；
2. 在左侧菜单点击 **「默认值」**（全局生效）或选择特定 Shell（如 **「PowerShell」**），切换到顶部 **「外观」** 选项卡；
3. 向下滚动到 **「背景图像」** 区域：
   - 点击 **「浏览」** 选择您的本地图片；
   - **背景图像拉伸模式**：推荐选择 **均匀填满 (uniformToFill)**；
   - **背景图像不透明度**：推荐调节为 **`0.35` ~ `0.45`**（既能清晰展现壁纸美感，又不会干扰命令行文字阅读）；
   - 点击右下角 **「保存」** 即可实时生效！

### Q3: 安装 MSYS2 后，Windows Terminal 下拉菜单没有 MSYS2，脚本会自动补全吗？
**答：脚本会自动为您补全！**
- **原生缺失原因**：Windows Terminal 官方默认只会动态探测 WSL、PowerShell Core、Azure 与 VS 开发者提示符；而 MSYS2 官方安装程序**并不会主动向 Windows Terminal 注入配置**，因此独立安装 MSYS2 后 Terminal 下拉列表默认找不到它。
- **本项目的双重自动注册机制**：
  1. **动态智能注入**：只要运行 [`Install-MSYS2.ps1`](file:///c:/XMWJJ/powershelldome/Install-MSYS2.ps1)（或总装 `Install-All.ps1 -All`），脚本会自动扫描本地 Terminal 的 `settings.json`；若未包含 MSYS2，会自动生成一条 `MSYS2 UCRT64` 配置项并追加到 `profiles.list` 中。
  2. **项目完整模板覆盖**：若应用了项目自带的 [`settings.json`](file:///c:/XMWJJ/powershelldome/settings.json)，该配置中已预先内置了 5 大 MSYS2 子环境（MSYS、UCRT64、CLANG64、MINGW64、MINGW32），带独立图标与启动参数。
- **自定义安装路径支持**：若您的 MSYS2 安装在非默认目录（非 `C:\msys64`），只需在执行安装脚本时传参：
  ```powershell
  pwsh -File .\Install-MSYS2.ps1 -Msys2InstallPath "D:\Tools\msys64"
  ```
  脚本会自动将实际存在的物理路径（如 `D:\Tools\msys64\msys2_shell.cmd`）写入 Terminal 配置中。

---

## ⚡ 常用命令与操作速查

| 操作场景 | 推荐命令 / 快捷键 | 依赖说明 |
| --- | --- | --- |
| **彩色目录 / 含权限隐藏项** | `ll` / `la` | 调用 `eza`，缺失时自动降级原生 |
| **高亮查看文件内容** | `catc README.md` (PS7) / `cat README.md` (CMD) | 调用 `bat`，缺失时自动降级 |
| **智能路径跳转** | `z <关键词>` | 需要 `zoxide` |
| **交互式目录选择** | `Alt+Z` | 需要 `zoxide` + `fzf` |
| **历史命令模糊检索** | `Ctrl+R` | 需要 `fzf` + `PSFzf` (PS7) / Clink (CMD) |
| **交互式文件选择** | `Ctrl+F` | 需要 `fzf` + `PSFzf` |
| **快速撤销输入** | `Ctrl+Z` | PSReadLine / Clink |
| **新建并进入目录** | `mkcd <新目录路径>` | 内置实用函数 |
| **查找当前目录下大文件** | `Find-LargeFiles -TopN 10` | 内置实用函数 |
| **重新加载 PowerShell 配置** | `Update-Profile` | 内置实用函数 |
| **编辑 Profile 脚本** | `Edit-Profile` | 自动调用 VSCode / Notepad |
| **系统环境自检** | `Test-Environment` | 自动检查工具链与模块完备度 |
| **Git 便捷操作** | `gst`、`gco <分支>`、`gb -a`、`glog`、`gpull`、`gps` | 内置别名与函数 |

---

## 🛠️ 个性化定制变量 (PowerShell 7)

在您的 `$PROFILE` 中（或在开窗前设置环境变量），可以通过以下开关随心定制：

```powershell
# 1. 启动横幅（默认 1 启用，设为 0 禁用）
$env:POWERSHELL_PROFILE_BANNER = '1'

# 2. Terminal-Icons 图标（默认 1 启用，设为 0 可实现极致毫秒级冷启动）
$env:POWERSHELL_PROFILE_ICONS = '1'

# 3. vfox 环境管理器（默认 1 启用，设为 0 禁用）
$env:POWERSHELL_PROFILE_VFOX = '1'

# 4. 指定 Oh My Posh 主题（指定存在的本地 .omp.json 文件绝对路径）
$env:POWERSHELL_POSH_THEME = "$env:USERPROFILE\oh-my-posh-themes\catppuccin_mocha.omp.json"

# 5. PSReadLine 预测显示模式（可选 InlineView 行内 / ListView 列表）
$env:POWERSHELL_PREDICTION_VIEW = 'InlineView'
```

---

## 🚀 部署、验证与回退

### 1. 运行回归验证
在部署或修改后，运行本地静态检查：
```powershell
pwsh -NoProfile -File .\tests\Verify-Configuration.ps1
```

### 2. 一键应用部署
将项目配置部署到本机系统：
```powershell
# 预演查看变更目标（不实际修改系统）：
pwsh -NoProfile -File .\Deploy-TerminalConfiguration.ps1 -WhatIf

# 真正执行部署：
pwsh -NoProfile -File .\Deploy-TerminalConfiguration.ps1
```
### 3. 五个独立一键安装脚本与包管理容错降级（支持 Win11 / Win10 / Win8.1）

针对不同 Shell 环境的个性化需求，项目提供了五个独立的安装配置脚本及一个总装脚本：

| 脚本名称 | 适用目标 | 核心特性与主题定制 |
| :--- | :--- | :--- |
| [`Install-PowerShell7.ps1`](file:///c:/XMWJJ/powershelldome/Install-PowerShell7.ps1) | **PowerShell 7 (pwsh)** | 自动配置 Scoop 仓库与工具链（含 yazi 目录穿梭）、JetBrainsMono NF 字体、PSReadLine/Terminal-Icons 插件；**交互提示选择【1】每次启动随机主题 (120+ 离线主题池，回车默认)、【2】固定主题 (Catppuccin Mocha，极速秒开)、【3】Starship 赛博朋克主题**。 |
| [`Install-WinPowerShell51.ps1`](file:///c:/XMWJJ/powershelldome/Install-WinPowerShell51.ps1) | **Windows PowerShell 5.1** (系统内置) | 专为 Win 10/11 内置 PowerShell 及 Win 8.1 优化；**强制启用 UTF-8 解决中文乱码**；**默认配置丰富随机主题（可选 -Theme Starship 赛博朋克主题）**；现代化别名与历史搜索。 |
| [`Install-Cmd.ps1`](file:///c:/XMWJJ/powershelldome/Install-Cmd.ps1) | **CMD (命令提示符)** | 自动安装 Clink、Starship、Eza、Bat；**固定 Starship 赛博朋克霓虹主题**；**65001 UTF-8 与完整 Unix/Git Doskey 别名**；通过当前用户注册表 AutoRun 挂载，无需管理员权限，支持 `-Uninstall` 干净卸载。 |
| [`Install-NuShell.ps1`](file:///c:/XMWJJ/powershelldome/Install-NuShell.ps1) | **NuShell (nu)** | 自动安装 NuShell 及配套工具；**配置 `env.nu` UTF-8 中文环境**；**自动挂载 Starship 赛博朋克提示符与 Zoxide 目录快跳**；配置 Fastfetch 启动横幅与 Unix/Git 常用别名；自动注册 Windows Terminal 配置项。 |
| [`Install-MSYS2.ps1`](file:///c:/XMWJJ/powershelldome/Install-MSYS2.ps1) | **MSYS2 (bash)** | 定位或自动安装 MSYS2；**配置 `MSYS2_PATH_TYPE=inherit` 继承 Windows 本机环境变量**，可在 MSYS2 中直接调用 Windows 原生安装的工具；配置 `~/.bashrc` 强制 UTF-8、Starship 提示符、Fastfetch 横幅与别名；**自动检查并向 Windows Terminal 注册配置项（支持 `-Msys2InstallPath`）**。 |
| [`Install-All.ps1`](file:///c:/XMWJJ/powershelldome/Install-All.ps1) | **全终端总装** | 一键按序安装配置上述终端环境，支持 `-IncludeNuShell`、`-IncludeMSYS2` 或 `-All` 安装全部 5 种终端。 |

#### 包管理器容错降级策略（Choco -> WinGet 仓库自动配置 -> Scoop）
脚本内置通用容错函数 `Install-AppWithChocoWingetFallback`：
1. **已就绪检测**：优先检查命令是否已经在 PATH 或对应路径中就绪，避免重复下载。
2. **第一梯队 (Chocolatey)**：若检测到系统已安装 `choco`，执行安装；若发生失败，**自动重试 2 次**。
3. **第二梯队 (WinGet 自动配置与安装)**：若未检测到 `choco` 或 2 次尝试均失败，自动进入 WinGet 流程：
   - 自动检测并补全 `winget.exe` 路径（含 `WindowsApps` 检索）；
   - **自动检查与配置 WinGet 软件源仓库**：若源异常或为空，自动执行 `winget source reset --force` 与 `winget source update` 修复并同步官方仓库源；
   - 执行静默安装 `winget install --id ... --exact --silent`。
4. **第三梯队 (Scoop 终极保底)**：若 WinGet 仍不可用（例如在 Windows 8.1 或精简系统上），自动调用 Scoop 仓库进行终极保底安装。

#### 运行方式：

```powershell
# 1. 独立安装 PowerShell 7（带主题选择提示，可选随机或固定）：
pwsh -File .\Install-PowerShell7.ps1

# 2. 独立安装 Windows PowerShell 5.1（固定 Starship 极速主题）：
powershell.exe -File .\Install-WinPowerShell51.ps1

# 3. 独立安装 CMD（固定 Starship 赛博朋克主题 + Clink + 别名）：
pwsh -File .\Install-Cmd.ps1

# 4. 独立安装 NuShell（Starship 提示符 + Fastfetch + 别名）：
pwsh -File .\Install-NuShell.ps1

# 5. 独立安装 MSYS2（继承 Windows PATH + Starship + UTF-8）：
pwsh -File .\Install-MSYS2.ps1

# 6. 一键安装全部终端环境（包含 NuShell 与 MSYS2）：
pwsh -File .\Install-All.ps1 -All
```

---

### 4. 自动全量备份与一键无损回退

#### 自动前置备份机制
当运行任何安装脚本（`Install-PowerShell7.ps1`、`Install-WinPowerShell51.ps1`、`Install-Cmd.ps1` 或 `Install-All.ps1`）时，**脚本会在修改任何系统文件前，自动抓取当前系统所有终端配置（PS7 Profile、WinPS5.1 Profile、Windows Terminal 设置、CMD AutoRun 注册表、Clink 脚本、Starship 配置）**，保存在 `backups/install-backup-时间戳/` 目录中，并记录 SHA-256 校验清单。

#### 一键无损回退 (`Restore-All.ps1`)
在任意终端（PowerShell 7 或系统内置 Windows PowerShell 5.1）中运行：
```powershell
# 1. 仅预览回退操作（Dry Run，不改动任何文件）：
pwsh -File .\Restore-All.ps1 -WhatIf
# 或在 Windows PowerShell 5.1 / Win 8.1 下运行：
powershell.exe -File .\Restore-All.ps1 -WhatIf

# 2. 真正执行一键回退（自动读取最新安装备份还原原状，并清理新生成的文件与注册表项）：
pwsh -File .\Restore-All.ps1
# 或：
powershell.exe -File .\Restore-All.ps1
```
> **提示**：原脚本 `.\Restore-TerminalConfiguration.ps1` 亦已同步升级为兼容委托模式。

---

## 📦 工具链维护建议

本机已由 Scoop 与 WinGet 安装了常用工具：
- **Scoop 管理**：`fastfetch`、`oh-my-posh`、`eza`、`bat`、`starship`、`vfox`、`nu`、`7zip`、`curl`、`jq`、`sudo`、`ripgrep`。
- **WinGet 管理**：`zoxide`、`fzf`、`yazi`、`clink`。
- **PowerShell 模块**：`PSReadLine`、`PSFzf`、`Terminal-Icons`。

更新所有工具：
```powershell
scoop update *
Update-Module PSReadLine, PSFzf, Terminal-Icons
```

