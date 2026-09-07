# Windows 全终端现代化与美化生产力套件

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2011%20|%2010%20|%208.1-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-PowerShell%207%20|%20WinPS%205.1%20|%20CMD%20|%20NuShell%20|%20MSYS2-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Shells" />
  <img src="https://img.shields.io/badge/Startup-~258ms%20(Sub--Second)-success?style=for-the-badge&logo=speedtest&logoColor=white" alt="Startup" />
  <img src="https://img.shields.io/badge/Theme-120+%20Themes%20(Random/Fixed)-F5E0DC?style=for-the-badge&logo=starship&logoColor=black" alt="Theme" />
  <img src="https://img.shields.io/badge/Safety-Rescue%20Snapshot%20&%20Atomic%20IO-brightgreen?style=for-the-badge" alt="Safety" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <b>开箱即用、安全无损、极速响应（~258ms）的 Windows 全终端现代化与美化生产力套件。</b><br>
  涵盖 Windows Terminal、PowerShell 7、Windows PowerShell 5.1、CMD、NuShell 以及 MSYS2。<br>
  配备<b>三级包管理容错自愈体系</b>、<b>PowerShell 7 每日随机主题</b>、<b>全终端救援快照与原子回退</b>以及<b>CMD 防工作目录劫持加固</b>。
</p>

---

## 📚 详细文档导航

- 💻 **[IDE 与开发工具集成指南 (IDE与开发工具集成指南.md)](IDE与开发工具集成指南.md)**：专为开发者量身打造，详解如何在 **VS Code** 与 **IntelliJ IDEA / PyCharm / WebStorm 等 JetBrains 全家桶** 中深度集成美化终端，配置终端独立字体与避免乱码。
- 📖 **[开发与部署全景指南 (开发与部署文档.md)](开发与部署文档.md)**：深入剖析系统架构、配置拓扑、三级容错底层实现、随机主题算法、编码避坑规范与测试框架。
- 📦 **[部署与回退操作手册 (部署与回退.md)](部署与回退.md)**：快照存档、版本追溯、沙箱测试与一键回退实操手册。
- 🎨 **[Windows 终端美化背景与参考 (windows终端美化相关.md)](windows终端美化相关.md)**：终端渲染引擎、Catppuccin 配色方案与设计演进背景。

---

## 🌟 核心特性

- ⚡ **毫秒级极速响应与按需加载（Profile 冷启动降至 ~258ms）**
  - **按需激活版本管理**：针对旧版本 `vfox activate` 造成的 9~11 秒严重启动阻塞，优化为按需加载（提供 `Enable-Vfox` 函数）；
  - **流式全文检索 (fif)**：`fif <词>` 采用管道流式传输直达 `fzf`，并杜绝全量空查询，彻底消除大仓库搜索卡死与内存暴涨；
  - **极速短路与进程超时控制**：支持 `POWERSHELL_PROFILE_MINIMAL=1` 顶层短路；外部工具调用通过 `Invoke-ProfileProcess` 施加带超时保护的进程托管。

- 🛡️ **不可信目录防劫持加固（CMD 安全防御）**
  - **杜绝 CWD 程序劫持**：彻底根除 CMD 在当前工作目录调用裸命令的潜在风险，所有系统指令硬编码绑定 `%SystemRoot%\System32`（如 `chcp.com`, `doskey.exe`）；
  - **安装期可信物理路径解析**：Fastfetch 与 Clink 注入点在安装期通过受信任目录清单固化为绝对路径，绝不执行当前目录中的同名可执行文件；
  - **非交互启动极速绕过**：CMD AutoRun 前置分析 `CMDCMDLINE`，批处理及 `/c` 静默调用立即退出，零开销无污染；
  - **Clink 提示符静态生成**：`starship.lua` 改为安装期预编译生成，消除运行时额外子进程调用。

- 🛡️ **安全第一：全终端救援快照与无损原子回退（19 项全量资产）**
  - **19 项全量资产覆盖**：清册覆盖 PS7、WinPS 5.1、Windows Terminal、CMD、NuShell（含 `zoxide.nu`）、MSYS2（含 `.bashrc`、4 类 `ini` 及 `MSYS2_PATH_TYPE` 注册表项）；
  - **快照指针精准隔离**：严格隔离部署快照（`.deployment-path`）、安装快照（`.last-install-backup`）与 CMD 卸载快照（`.last-cmd-backup`），避免快照错选或跨终端污染；
  - **两阶段救援备份 (Zero Data Loss)**：回退前强制先对当前运行中的最新配置生成 `pre-rollback-<guid>` 救援快照，即使回退后反悔也能无损恢复；
  - **原子写入与并发检测**：利用临时文件与 `[IO.File]::Replace` 保证写入原子性；支持重定向 `Documents` 目录（兼容 OneDrive/企业重定向）。

- 🎲 **PowerShell 7 默认“每日随机主题”（每日新鲜感，杜绝审美疲劳）**
  - **120+ 官方精美离线主题库**：安装时自动同步全量 Oh-My-Posh 官方主题至本地 `~/oh-my-posh-themes/`，**纯本地毫秒级随机抽取，启动零网络等待**；
  - **直观反馈与优雅提示**：每次启动终端顶部展示 `✨ 今日随机主题: <ThemeName> ✨`；
  - **双层防崩安全降级**：若抽取的第三方主题在特定环境下格式解析异常，自动无缝降级至经典内置 Catppuccin Mocha 主题，终端绝不报错；
  - **自由随时切换**：随时支持一键切换为【固定主题 (Catppuccin Mocha)】或【Starship 赛博朋克极速主题】。

- ⚡ **高稳定性与极高安装成功率（三级容错自愈体系）**
  - **前置解决无人值守挂起**：自动静默安装最新 NuGet PackageProvider 并信任官方 PSGallery 软件源，彻底根治传统安装时弹窗询问导致的进程挂起；
  - **就绪状态毫秒级跳过 (Fast-Path Check)**：已存在的工具链自动跳过，多次运行不产生任何网络浪费；
  - **失败真实阻断**：全链路校验包管理器与自检退出码，严禁“失败但误报成功”，失败显式抛出异常中止；
  - **容错降级链**：Chocolatey（重试 2 次）➜ WinGet（自动重置源缓存）➜ Scoop（终极跨版本保底）。

- 🖥️ **五大主流命令行终端全覆盖**
  - **Windows Terminal**：沉浸式亚克力磨砂透明、Catppuccin Mocha 配色、自定义壁纸融合、JetBrainsMono Nerd Font 编程图标字体；
  - **PowerShell 7 (pwsh)**：Fastfetch 专属 ASCII 硬件横幅、功能就绪卡片、Yazi 目录穿梭集成（`y`）、PSReadLine 行内预测与历史检索、Terminal-Icons 文件图标；
  - **Windows PowerShell 5.1 (系统内置)**：专为 Win 10/11 内置终端与 Win 8.1 调优，**强制 UTF-8 编码彻底根治 GBK 936 乱码与 Parser 报错**，加载极速 Starship 提示符，毫秒级冷启动；
  - **CMD (命令提示符)**：Clink 语法着色与自动补全、Starship 霓虹渐变提示符、全面映射 Unix/Git 常用命令别名（`ll`, `la`, `cat`, `grep` 等）；
  - **NuShell (nu)**：结构化 Shell 环境配置，自动挂载 Starship 提示符与 Zoxide 目录快跳，顶层声明现代 Unix 别名（兼容 NuShell 0.108+ 词法作用域）；
  - **MSYS2 (bash)**：配置 `MSYS2_PATH_TYPE=inherit` 继承 Windows 系统 PATH（在 MSYS2 中可直接调用宿主机原生安装的编译器和工具链），集成 Starship 与 UTF-8 环境。

- 🎨 **动漫 ASCII Art 横幅与配置完全内聚（零手动查找）**
  - 项目内置 `fastfetch/ascii.txt`（高精度二次元点阵字符画）与 `fastfetch/config.jsonc`（Catppuccin 硬件监控面板）；
  - 安装脚本全自动分发横幅并动态适配为本机的物理绝对路径，免去用户手动寻找和复制素材的繁琐。

---

## 📋 脚本清单与项目结构

```
powershelldome/
├── Install-All.ps1                  # 全终端一键集成总装脚本 (-IncludeNuShell, -IncludeMSYS2, -All)
├── Install-PowerShell7.ps1          # PowerShell 7 独立安装脚本 (默认随机主题 / 固定 / Starship)
├── Install-WinPowerShell51.ps1      # Windows PowerShell 5.1 独立安装与极速 Starship 配置
├── Install-Cmd.ps1                  # CMD Clink + Starship 现代化独立安装配置
├── Install-NuShell.ps1              # NuShell 现代化独立安装与美化配置
├── Install-MSYS2.ps1                # MSYS2 独立安装与 PATH 继承美化配置
├── Restore-All.ps1                  # 全终端一键无损回退脚本 (带救援快照，支持 -WhatIf 预演)
├── Deploy-TerminalConfiguration.ps1 # 生产部署同步脚本 (Windows Terminal + PS7 + CMD)
├── Restore-TerminalConfiguration.ps1# 部署专用委托回退脚本 (绑定 .deployment-path)
├── scripts/
│   ├── TerminalState.ps1            # 核心原子快照、救援备份、安全写入与路径解析引擎
│   ├── TerminalSetupCommon.ps1      # 跨平台稳态底层库 (三级容错、失败校验、主题分发)
│   ├── Install-RequiredModules.ps1  # 模块跨版本安全安装委托工具
│   └── New-DeploymentSnapshot.ps1  # 纯数据化部署快照生成器
├── tests/
│   ├── Verify-Configuration.ps1     # 静态语法、JSON 验证、AST 树与 Profile 重载安全性自检
│   ├── Verify-Deployment.ps1        # 隔离沙箱部署、回退完整性、WhatIf 与防覆写测试
│   ├── Verify-Safety.ps1            # 救援快照、白名单过滤、原子写入与防提权劫持专项测试
│   ├── Verify-GeneratedConfiguration.ps1 # 真实安装模板渲染、NuShell 作用域与 CMD 劫持防护测试
│   └── Measure-ProfileStartup.ps1   # 交互式 Profile 加载基准性能测试工具
├── cmd/                             # CMD 批处理与 Clink Lua 增强脚本 (防 CWD 注入)
├── fastfetch/                       # 内聚的 Fastfetch 动漫字符画与 Catppuccin 硬件面板
├── starship/                        # Starship 霓虹赛博朋克全局配置文件 (收紧超时控制)
├── settings.json                    # Windows Terminal 深度美化配置文件
├── Microsoft.PowerShell_profile.ps1 # PowerShell 7 核心 Profile 源码 (~258ms 极速冷启动)
├── IDE与开发工具集成指南.md         # VS Code 与 IntelliJ IDEA 内置终端集成配置指南
├── 开发与部署文档.md                 # 架构设计、实现原理与避坑指南
├── 部署与回退.md                     # 备份归档与回退操作指南
├── 安全稳定性性能审计-2026-09-07.md  # 详细安全稳定性性能审计报告
└── windows终端美化相关.md           # 终端美化背景与配置参考
```

---

## 🚀 快速开始

### 方式一：全终端一键总装（推荐）

在 PowerShell 中克隆本项目并进入目录：
```powershell
git clone https://github.com/vicky-clair/configuration_of_Terminal_and_PowerShell_for_Xia_Rui.git
cd configuration_of_Terminal_and_PowerShell_for_Xia_Rui
```

根据您的需求选择总装方式：
```powershell
# 1. 安装核心三终端（PowerShell 7 + Windows PowerShell 5.1 + CMD）：
# 默认配置 PowerShell 7 每日随机主题
pwsh -File .\Install-All.ps1

# 2. 一步到位安装全部 5 种终端（包含 NuShell 与 MSYS2）：
pwsh -File .\Install-All.ps1 -All

# 注：若当前系统尚未安装 PowerShell 7，直接使用 Windows 自带的 PowerShell 执行：
powershell.exe -ExecutionPolicy Bypass -File .\Install-All.ps1 -All
```

---

### 方式二：独立单终端安装与定制

您可以根据日常使用偏好，仅针对特定终端执行安装：

| 想要配置的终端 | 执行命令 | 交互与特性 |
| :--- | :--- | :--- |
| **PowerShell 7** | `pwsh -File .\Install-PowerShell7.ps1` | **直接回车默认采用 [1] 每日随机主题**，亦可输入 `2` 选择 Catppuccin 固定主题或 `3` Starship |
| **Windows PowerShell 5.1** | `powershell.exe -ExecutionPolicy Bypass -File .\Install-WinPowerShell51.ps1` | 自动修复中文编码，固定加载极速毫秒级 Starship 主题 |
| **CMD (命令提示符)** | `pwsh -File .\Install-Cmd.ps1` | 自动挂载 Clink 补全与 Starship 提示符（支持 `-Uninstall` 卸载） |
| **NuShell** | `pwsh -File .\Install-NuShell.ps1` | 自动挂载 `starship.nu` 提示符与 `zoxide.nu` 目录快跳，配置 Fastfetch 横幅 |
| **MSYS2** | `pwsh -File .\Install-MSYS2.ps1` | 注入 `MSYS2_PATH_TYPE=inherit` 继承系统 PATH，配置 UTF-8 与 Starship |

---

## 🎨 PowerShell 7 主题模式自由切换

PowerShell 7 默认启用**每日随机主题**，如果您希望切换模式，可以随时在终端中运行：

```powershell
# 1. 切换为每日随机主题（默认，启动输出 ✨ 今日随机主题: <ThemeName> ✨）
$env:POWERSHELL_THEME_MODE = 'random'

# 2. 切换为固定经典 Catppuccin Mocha 主题
$env:POWERSHELL_THEME_MODE = 'fixed'

# 3. 切换为 Starship 赛博朋克极速主题
$env:POWERSHELL_THEME_MODE = 'starship'
```
*提示：若需永久固定为某种模式，只需重新运行 `Install-PowerShell7.ps1` 选择对应编号，或将上述变量写入 `$PROFILE` 顶部即可。*

---

## ⏪ 一键无损回退

如果不满意当前配置，或需要复原到修改前的状态，可随时执行回退。回退程序会自动核对原始文件的 SHA-256 散列并清理新生成的文件与注册表项：

```powershell
# 1. 预览回退变更（Dry Run 预演，不改变任何文件）：
pwsh -File .\Restore-All.ps1 -WhatIf
# 或在系统内置 Windows PowerShell 5.1 下执行：
powershell.exe -File .\Restore-All.ps1 -WhatIf

# 2. 真正执行一键回退：
pwsh -File .\Restore-All.ps1
# 或：
powershell.exe -File .\Restore-All.ps1
```

---

## 🧩 常用快捷键与命令速查

| 操作场景 | 推荐命令 / 快捷键 | 适用终端 | 说明 |
| :--- | :--- | :--- | :--- |
| **模糊定位并编辑文件** | `fv` | PS7 | 呼出 FZF 模糊检索文件（带 `bat` 实时高亮预览），回车用 Neovim 打开 |
| **全文代码模糊检索** | `fif <关键词>` | PS7 | 联动 `ripgrep` + `fzf` + `bat` 毫秒级全文秒搜，回车 Neovim 直跳目标行 |
| **极速打开编辑器** | `v <文件或目录>` / `v .` | PS7 | 极速呼出 Neovim 编辑器 |
| **极速 TUI 文件管理器** | `y` (退出自动切目录) / `y <路径>` | 全终端 | 基于 Rust 的现代化双栏文件管理器（支持带路径定位） |
| **Git 终端 TUI 管理** | `lg` / `lzg` / `Ctrl+G` | 全终端 / PS7 | 纯终端全屏交互式 Lazygit（支持键盘 `Ctrl+G` 一键呼出） |
| **Docker 容器 TUI 管理** | `lzd` / `lazydocker` | 全终端 | 纯终端交互式 Docker 镜像与容器监控管理 |
| **彩色文件与树状图** | `ll` / `la` / `lt` / `lt3` | 全终端 | 调用 `eza` 图标排版（`lt` 2层树 / `lt3` 3层树 / 隐藏项） |
| **显示文件 Git 变更状态** | `llg` | PS7 | 调用 `eza --long --git`，文件列表右侧直观展示暂存/修改/未跟踪状态 |
| **快速上溯父级目录** | `..` / `...` / `....` | PS7 | 分别快速返回上一层、上两层、上三层目录 |
| **高亮预览文件** | `cat README.md` (CMD/Nu/MSYS2) / `catc` (PS7) | 全终端 | 调用 `bat` 进行代码高亮与自动折叠 |
| **智能目录瞬间跳转** | `z <目录名片段>` | 全终端 | 调用 `zoxide` 历史权重算法直接跳转 |
| **交互式目录模糊跳转** | `Alt+Z` 或 `zi` | PS7 / NuShell | 调用 `fzf` 交互式模糊检索并跳转 |
| **历史命令模糊搜索** | `Ctrl+R` | PS7 / CMD / MSYS2 | 调用 `fzf` / Clink 历史检索，回车即刻执行 |
| **交互式插入文件路径** | `Ctrl+F` | PS7 | 调用 `fzf` 模糊选择文件并填入当前命令行 |
| **创建并直接进入目录** | `mkcd <新目录名>` | PS7 | 自动创建深层路径并 `Set-Location` |
| **查找当前目录下大文件** | `Find-LargeFiles -TopN 10` | PS7 | 极速扫描并按体积降序排列 |
| **Git 快捷流** | `gst`、`gco`、`gb`、`glog`、`gpull`、`gps` | 全终端 | 常用 Git 状态、切换、分支、日志别名 |
| **终端分屏 (横向/纵向)** | `Alt+Shift+D` | Windows Terminal | 自动对当前活动窗格进行平铺拆分 |
| **终端命令面板** | `Ctrl+Shift+P` | Windows Terminal | 调出 Windows Terminal 所有操作指令集 |

---

## ⚙️ 环境变量与进阶配置 (PowerShell 7)

您可以在 `$PROFILE` 中随时设置以下环境变量以控制功能启闭：

```powershell
# 1. 终端美化主题模式 ('random' 每日随机 / 'fixed' 固定经典 / 'starship' 极速)
$env:POWERSHELL_THEME_MODE = 'random'

# 2. 极简极速模式（'1' 开启顶层短路跳过所有外部工具探测，启动耗时降至 ~241ms）
$env:POWERSHELL_PROFILE_MINIMAL = '0'

# 3. 启动横幅（'1' 开启 Fastfetch 动漫硬件面板，'0' 关闭实现纯净启动）
$env:POWERSHELL_PROFILE_BANNER = '1'

# 4. 现代化功能就绪提示卡片（'1' 开启，'0' 关闭）
$env:POWERSHELL_PROFILE_TIPS = '1'

# 5. Terminal-Icons 文件图标（'1' 开启，'0' 关闭可进一步优化交互响应）
$env:POWERSHELL_PROFILE_ICONS = '1'

# 6. vfox 版本环境管理器（默认建议关闭以保持秒开；终端输入 `Enable-Vfox` 或设为 '1' 开启）
$env:POWERSHELL_PROFILE_VFOX = '0'

# 7. PSReadLine 预测模式 ('InlineView' 行内灰色预测 / 'ListView' 下拉菜单列表)
$env:POWERSHELL_PREDICTION_VIEW = 'InlineView'
```

---

## 🧪 自动化测试与质量保障

本项目包含 4 套严密的设计与安全回归测试套件及 1 套性能基准测试工具，在 `PowerShell 7` 与 `Windows PowerShell 5.1` 双环境下均保持 100% PASS：

```powershell
# 1. 静态语法、JSON 合法性、AST 抽象语法树与 Profile 重载安全性自检
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Configuration.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Configuration.ps1

# 2. 隔离沙箱环境部署、回退完整性、WhatIf 预演与防并发覆写回归测试
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Deployment.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Deployment.ps1

# 3. 救援快照、白名单过滤、安装失败异常中断、原子写入与防工作目录劫持专项安全测试
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Safety.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Safety.ps1

# 4. 真实安装模板渲染、NuShell 0.108+ 作用域与 CMD CWD 注入防御测试
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-GeneratedConfiguration.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-GeneratedConfiguration.ps1

# 5. 交互式 Profile 启动耗时基准测量 (支持 -Mode defaults/minimal/full)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Measure-ProfileStartup.ps1 -Mode defaults
```

---

## 🤝 参与贡献

欢迎提交 Issue 与 Pull Request！如果您有更好的主题预设、实用别名或跨版本优化思路，请随时分享。

1. Fork 本代码仓库
2. 创建新特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到远端分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

---

## 📄 开源许可

本项目基于 [MIT 许可证](LICENSE) 开源。欢迎自由使用、定制与分发。
