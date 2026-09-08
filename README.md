# Windows 全终端现代化与美化生产力套件

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2011%20|%2010%20|%208.1-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-PowerShell%207%20|%20WinPS%205.1%20|%20CMD%20|%20NuShell%20|%20MSYS2-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Shells" />
  <img src="https://img.shields.io/badge/Startup-On%20Demand-success?style=for-the-badge&logo=speedtest&logoColor=white" alt="Startup" />
  <img src="https://img.shields.io/badge/Theme-120+%20Themes%20(Random/Fixed)-F5E0DC?style=for-the-badge&logo=starship&logoColor=black" alt="Theme" />
  <img src="https://img.shields.io/badge/Safety-Rescue%20Snapshot%20&%20Atomic%20IO-brightgreen?style=for-the-badge" alt="Safety" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <b>支持按需加载与救援备份的 Windows 全终端现代化与美化生产力套件。</b><br>
  涵盖 Windows Terminal、PowerShell 7、Windows PowerShell 5.1、CMD、NuShell 以及 MSYS2。<br>
  配备<b>包管理失败检查与容错</b>、<b>PowerShell 7 每次启动随机主题</b>、<b>配置救援快照与单文件原子替换</b>以及<b>CMD 防工作目录劫持加固</b>。
</p>

---

## 📚 详细文档导航

- 💻 **[IDE 与开发工具集成指南 (IDE与开发工具集成指南.md)](IDE与开发工具集成指南.md)**：专为开发者量身打造，详解如何在 **VS Code** 与 **IntelliJ IDEA / PyCharm / WebStorm 等 JetBrains 全家桶** 中深度集成美化终端，配置终端独立字体与避免乱码。
- 📖 **[开发与部署全景指南 (开发与部署文档.md)](开发与部署文档.md)**：深入剖析系统架构、配置拓扑、三级容错底层实现、随机主题算法、编码避坑规范与测试框架。
- 📦 **[部署与回退操作手册 (部署与回退.md)](部署与回退.md)**：快照存档、版本追溯、沙箱测试与一键回退实操手册。
- 🎨 **[Windows 终端美化背景与参考 (windows终端美化相关.md)](windows终端美化相关.md)**：终端渲染引擎、Catppuccin 配色方案与设计演进背景。

---

## 🌟 核心特性

- ⚡ **按需加载与可复测的启动性能**
  - **按需激活版本管理**：针对旧版本 `vfox activate` 造成的 9~11 秒严重启动阻塞，优化为按需加载（提供 `Enable-Vfox` 函数）；
  - **流式全文检索 (fif)**：`fif <词>` 采用管道流式传输直达 `fzf`，并杜绝全量空查询，彻底消除大仓库搜索卡死与内存暴涨；
  - **极速短路与进程超时控制**：支持 `POWERSHELL_PROFILE_MINIMAL=1` 顶层短路；外部工具调用通过 `Invoke-ProfileProcess` 施加带超时保护的进程托管。

- 🛡️ **不可信目录防劫持加固（CMD 安全防御）**
  - **杜绝 CWD 程序劫持**：彻底根除 CMD 在当前工作目录调用裸命令的潜在风险，所有系统指令硬编码绑定 `%SystemRoot%\System32`（如 `chcp.com`, `doskey.exe`）；
  - **安装期可信物理路径解析**：Fastfetch 与 Clink 注入点在安装期通过受信任目录清单固化为绝对路径，绝不执行当前目录中的同名可执行文件；
  - **非交互启动极速绕过**：CMD AutoRun 前置分析 `CMDCMDLINE`，批处理及 `/c` 静默调用立即退出，零开销无污染；
  - **Clink 提示符静态生成**：`starship.lua` 改为安装期预编译生成，消除运行时额外子进程调用。

- 🛡️ **配置救援快照与受管目标恢复（19 个文件及相关注册表值）**
  - **19 项全量资产覆盖**：清册覆盖 PS7、WinPS 5.1、Windows Terminal、CMD、NuShell（含 `zoxide.nu`）、MSYS2（含 `.bashrc`、4 类 `ini` 及 `MSYS2_PATH_TYPE` 注册表项）；
  - **快照指针精准隔离**：严格隔离部署快照（`.deployment-path`）、安装快照（`.last-install-backup`）与 CMD 卸载快照（`.last-cmd-backup`），避免快照错选或跨终端污染；
  - **两阶段救援备份**：回退前对当前配置生成 `pre-rollback-<guid>` 副本，失败时报告状态与救援目录；
  - **单文件替换与并发检测**：同目录临时文件与 `[IO.File]::Replace` 避免直接截断已有文件；整个恢复不是多文件和注册表事务，失败时可能部分完成。支持重定向 `Documents` 目录。

- 🎲 **PowerShell 7 默认“每次启动随机主题”（启动时随机抽取本地主题）**
  - **120+ 官方精美离线主题库**：安装时自动同步全量 Oh-My-Posh 官方主题至本地 `~/oh-my-posh-themes/`，**纯本地毫秒级随机抽取，启动零网络等待**；
  - **直观反馈与优雅提示**：每次启动终端顶部展示 `✨ 当前随机主题: <ThemeName> ✨`；
  - **双层防崩安全降级**：若抽取的第三方主题在特定环境下格式解析异常，自动无缝降级至经典内置 Catppuccin Mocha 主题，终端绝不报错；
  - **自由随时切换**：随时支持一键切换为【固定主题 (Catppuccin Mocha)】或【Starship 赛博朋克极速主题】。

- ⚡ **高稳定性与极高安装成功率（三级容错自愈体系）**
  - **模块来源与版本约束**：指定官方 PSGallery 和测试版本，保留用户仓库信任策略与发布者检查；新环境需具备可用的 PowerShellGet/NuGet 提供程序；
  - **就绪状态毫秒级跳过 (Fast-Path Check)**：已存在的工具链自动跳过，多次运行不产生任何网络浪费；
  - **失败真实阻断**：全链路校验包管理器与自检退出码，严禁“失败但误报成功”，失败显式抛出异常中止；
  - **容错降级链**：Chocolatey（重试 2 次）➜ WinGet（自动重置源缓存）➜ Scoop（终极跨版本保底）。

- 🖥️ **五大主流命令行终端全覆盖**
  - **Windows Terminal**：沉浸式亚克力磨砂透明、Catppuccin Mocha 配色、自定义壁纸融合、JetBrainsMono Nerd Font 编程图标字体；
  - **PowerShell 7 (pwsh)**：Fastfetch 专属 ASCII 硬件横幅、功能就绪卡片、Yazi 目录穿梭集成（`y`）、PSReadLine 行内预测与历史检索、Terminal-Icons 文件图标；
  - **Windows PowerShell 5.1 (系统内置)**：配置 UTF-8 编码，默认每次启动随机主题，复用最小及非交互模式检查；
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
├── Install-WinPowerShell51.ps1      # Windows PowerShell 5.1 独立安装与美化配置 (默认随机主题 / 支持 Starship)
├── Install-Cmd.ps1                  # CMD Clink + Starship 现代化独立安装配置
├── Install-NuShell.ps1              # NuShell 现代化独立安装与美化配置
├── Install-MSYS2.ps1                # MSYS2 独立安装与 PATH 继承美化配置
├── Restore-All.ps1                  # 配置恢复脚本 (带救援快照，支持 -WhatIf 预演)
├── Deploy-TerminalConfiguration.ps1 # 生产部署同步脚本 (Windows Terminal + PS7 + CMD)
├── Restore-TerminalConfiguration.ps1# 部署专用委托回退脚本 (绑定 .deployment-path)
├── scripts/
│   ├── TerminalState.ps1            # 快照、救援备份、单文件替换与路径解析
│   ├── TerminalSetupCommon.ps1      # 跨平台稳态底层库 (三级容错、失败校验、主题分发)
│   ├── Install-RequiredModules.ps1  # 模块跨版本安全安装委托工具
│   └── New-DeploymentSnapshot.ps1  # 纯数据化部署快照生成器
├── tests/
│   ├── Verify-Configuration.ps1     # 静态语法、JSON 验证、AST 树与 Profile 重载安全性自检
│   ├── Verify-Deployment.ps1        # 隔离沙箱部署、回退完整性、WhatIf 与防覆写测试
│   ├── Verify-Safety.ps1            # 救援快照、白名单过滤、原子写入与防提权劫持专项测试
│   ├── Verify-GeneratedConfiguration.ps1 # 真实安装模板渲染、NuShell 作用域与 CMD 劫持防护测试
│   ├── Verify-InstallerIntegration.ps1   # 安装器真实路径、MSYS2/NuShell 终端注册与异常测试
│   └── Measure-ProfileStartup.ps1   # 交互式 Profile 加载基准性能测试工具
├── cmd/                             # CMD 批处理与 Clink Lua 增强脚本 (防 CWD 注入)
├── fastfetch/                       # 内聚的 Fastfetch 动漫字符画与 Catppuccin 硬件面板
├── starship/                        # Starship 霓虹赛博朋克全局配置文件 (收紧超时控制)
├── settings.json                    # Windows Terminal 深度美化配置文件
├── Microsoft.PowerShell_profile.ps1 # 共享 Profile 源码 (按需加载与进程超时)
├── IDE与开发工具集成指南.md         # VS Code 与 IntelliJ IDEA 内置终端集成配置指南
├── 开发与部署文档.md                 # 架构设计、实现原理与避坑指南
├── 部署与回退.md                     # 备份归档与回退操作指南
├── 安全稳定性性能审计-2026-09-07.md  # 详细安全稳定性性能审计报告
└── windows终端美化相关.md           # 终端美化背景与配置参考
```

---

## ⚠️ 重要安装须知与备份提示 (Please Read First)

> [!WARNING]
> **环境适用性与免责声明**：
> 1. **脚本并非 100% 适合所有电脑环境**：虽然本项目针对 Windows 11、Windows 10 及 Windows 8.1 进行了多轮兼容测试与三级容错设计，但不同设备的系统版本分支（如精简版、Ghost 系统、LTSC、部分 Windows Server、企业组策略严格限制的办公机）、已有的第三方工具链、PowerShell 执行策略以及既有环境变量各不相同，安装过程中仍可能遇到不可预期的依赖冲突或环境差异。
> 2. **务必提前手动备份原有数据与配置**：在执行任何安装脚本前，**请务必自行手动备份好电脑中原有的终端配置与重要数据**（包括原有的 PowerShell Profile `$PROFILE`、已有 Windows Terminal 的自定义 `settings.json`、注册表 AutoRun 启动项及个人重要配置）。虽然本套件内置了自动快照与回退机制（[`Restore-All.ps1`](file:///c:/XMWJJ/powershelldome/Restore-All.ps1)），但手动异地留档依然是保障系统环境安全的最优习惯。
> 3. **Windows Terminal 宿主安装说明**：本项目的安装脚本**定位为“环境美化与配置”，不会自动下载并安装 Windows Terminal 软件本体**。
>    - Windows 11 已默认内置 Windows Terminal；
>    - 若使用 Windows 10 或尚未安装 Terminal 的系统，脚本仍会正常配置 pwsh/cmd 原生终端，但会自动跳过 Terminal 美化。建议提前通过 Microsoft Store 或在命令行执行 `winget install Microsoft.WindowsTerminal` 安装。
> 4. **关于终端背景壁纸**：本项目注重多机分发的通用性与便携性，**未在仓库中强行捆绑个人大体积壁纸文件**。Windows Terminal 原生内置了便捷的图形化外观设置。如需设置心仪的壁纸，只需打开 Terminal 按 <kbd>Ctrl</kbd> + <kbd>,</kbd> 进入设置 $\rightarrow$ `默认值` $\rightarrow$ `外观` $\rightarrow$ `背景图像` 即可一键选取并实时预览（详情参阅 [windows终端美化相关.md](file:///c:/XMWJJ/powershelldome/windows终端美化相关.md)）。

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
# 默认配置 PowerShell 7 每次启动随机主题
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
| **PowerShell 7** | `pwsh -File .\Install-PowerShell7.ps1` | **直接回车默认采用 [1] 每次启动随机主题**，亦可输入 `2` 选择 Catppuccin 固定主题或 `3` Starship |
| **Windows PowerShell 5.1** | `powershell.exe -ExecutionPolicy Bypass -File .\Install-WinPowerShell51.ps1` | 配置 UTF-8 编码，默认每次启动随机主题，可用 -Theme Starship 选择 Starship |
| **CMD (命令提示符)** | `pwsh -File .\Install-Cmd.ps1` | 自动挂载 Clink 补全与 Starship 提示符（支持 `-Uninstall` 卸载） |
| **NuShell** | `pwsh -File .\Install-NuShell.ps1` | 自动挂载 `starship.nu` 提示符与 `zoxide.nu` 目录快跳，配置 Fastfetch 横幅，**自动在 Windows Terminal 下拉菜单注册入口** |
| **MSYS2** | `pwsh -File .\Install-MSYS2.ps1` | 注入 `MSYS2_PATH_TYPE=inherit` 继承系统 PATH，配置 UTF-8 与 Starship，**自动在 Windows Terminal 下拉菜单注册入口**（支持 `-Msys2InstallPath` 自定义目录） |

> 💡 **关于 Terminal 下拉菜单注册**：单独安装 MSYS2 或 NuShell 软件后，Terminal 官方默认不会自动将其添加到下拉菜单。本项目的 `Install-MSYS2.ps1` 与 `Install-NuShell.ps1` 均内置了**智能扫描与注入逻辑**，若检测到 Terminal 中缺失，会自动将对应终端入口安全追加到 `settings.json` 中。若 MSYS2 安装在非默认目录（如 `D:\Tools\msys64`），只需在命令后加上 `-Msys2InstallPath "D:\Tools\msys64"` 即可。

---

## 🎨 PowerShell 7 主题模式自由切换

PowerShell 7 默认启用**每次启动随机主题**，如果您希望切换模式，可以随时在终端中运行：

```powershell
# 1. 切换为每次启动随机主题（默认，启动输出 ✨ 当前随机主题: <ThemeName> ✨）
$env:POWERSHELL_THEME_MODE = 'random'

# 2. 切换为固定经典 Catppuccin Mocha 主题
$env:POWERSHELL_THEME_MODE = 'fixed'

# 3. 切换为 Starship 赛博朋克极速主题
$env:POWERSHELL_THEME_MODE = 'starship'
```
*提示：若需永久固定为某种模式，只需重新运行 `Install-PowerShell7.ps1` 选择对应编号，或将上述变量写入 `$PROFILE` 顶部即可。*

---

## ⏪ 配置回退与救援备份

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

新安装会将自定义 MSYS2 根目录保存到仓库本机记录 `.last-install-context.json`，供默认回退使用。显式指定历史或救援快照时，补上原来的 `-Msys2InstallPath 'D:\Tools\msys64'`。恢复中途失败可能已完成部分目标；保留原快照和输出的救援目录，参阅[部署与回退手册](部署与回退.md)。

---

## 🛠️ 安装故障排查与自愈自适应机制 (Troubleshooting & Self-Healing)

针对跨网络环境（如国内直连/代理）、不同 Windows 系统版本（Windows 10 19045 / Windows 11 / Windows 8.1）以及初始系统环境的各种常见报错，本项目各安装脚本已全面升级为**全自动自愈与安全容错体系**：

### 1. 常见错误场景、根因与全自动自愈方案

| 故障现象 / 报错信息 | 故障根因分析 | 脚本自愈与自动化修复措施 | 手动应急命令 / 备用操作 |
| :--- | :--- | :--- | :--- |
| **`fatal: unable to access ... Recv failure: Connection was reset`** | 国内网络连接 GitHub 异常重置，导致 Scoop bucket 添加失败。 | `Ensure-ScoopBuckets` 内置高速镜像自愈链（自动重试 `gh-proxy.com` 与 Gitee 镜像仓库）。 | 若有本地科学上网代理（如端口 7890/10809）：<br>`scoop config proxy 127.0.0.1:7890`<br>`git config --global http.proxy http://127.0.0.1:7890` |
| **`git pull ... Failed to connect to github.com:443 over proxy 127.0.0.1`** | 本地曾配置代理但代理软件已关闭或端口变更。 | 属于 Git 客户端全局网络配置残留。 | 执行清理全局代理：<br>`git config --global --unset http.proxy`<br>`git config --global --unset https.proxy`<br>`scoop config rm proxy` |
| **`There aren't any apps installed. Scoop list failed.`** | Scoop 在未安装任何应用时以状态码 1 退出并在信息流 6 输出提示，触发 Stop 策略。 | `TerminalSetupCommon.ps1` 现已重定向流 `6>&1` 并接纳退出码 1，优雅视为空状态平滑继续。 | 已自动化处理，无需人工干预。 |
| **`Couldn't find manifest for 'JetBrainsMono-NF' from 'nerd-fonts' bucket`** | 网络中断导致 bucket 目录损坏，或仓库清单未拉取全。 | 脚本自动检测并清理空 bucket 重新拉取；若仍无法通过 Scoop 获取，**自动启动高速 CDN 直链下载并注入当前用户字体注册表**。 | 手动下载字体解压缩后右键“为所有用户安装”：<br>[JetBrainsMono NF 官方下载](https://github.com/ryanoasis/nerd-fonts/releases) |
| **Windows Terminal 启动弹窗：`找不到所选字体 'JetBrainsMono Nerd Font Mono'`** | 字体包因网络问题未就绪前启动了 Windows Terminal。 | 字体安装完成后，重启 Windows Terminal 即可自动识别。 | 安装脚本已集成 CDN 字体自愈下载；安装后新开 Terminal 即可。 |
| **`因为在此系统上禁止运行脚本。有关详细信息，请参阅...`** | Windows 默认 PowerShell 脚本执行策略为 `Restricted`。 | `Install-All.ps1` 与各独立脚本在启动时**全自动检测并将当前用户 (`CurrentUser`) 策略提升为 `RemoteSigned`**，并持久化写入注册表。 | 手动放行命令：<br>`Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force` |
| **`是否要运行来自此不可信发布者的软件? 文件 ... PSReadLine.format.ps1xml`** | 模块下载文件携带 Windows Mark of the Web (Zone.Identifier) 锁定标志。 | 脚本在安装模块与生成 Profile 后，**全自动递归调用 `Unblock-File` 解除锁定**。 | 手动解除命令：<br>`Get-ChildItem -Path "$HOME\Documents\WindowsPowerShell\Modules" -Recurse \| Unblock-File` |
| **`[出现错误 2147942402 (0x80070002) (启动“nu.exe”时)] 系统找不到指定的文件`** | 仅运行了默认 `Install-All.ps1`（未加 `-All`），未安装 NuShell，但 Terminal 配置中包含该标签。 | `Ensure-WindowsTerminalConfigured` 现已实现**动态 Profile 探测**，对系统中未安装的 Shell 自动标记 `"hidden": true`，避免误点报错。 | 若需一键安装 NuShell 与 MSYS2：<br>`pwsh -File .\Install-All.ps1 -All`<br>脚本会自动安装并解除隐藏。 |

### 2. 跨网络环境代理最佳实践建议

若您在中国大陆网络环境下部署本套件，推荐配合本地代理软件获得数倍下载提速：

```powershell
# 1. 开启代理（端口请根据代理软件实际端口修改，常见为 7890 或 10809）
scoop config proxy 127.0.0.1:7890
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 2. 部署完毕后，若关闭了代理软件，请务必还原清理，避免后续 git pull 失败：
scoop config rm proxy
git config --global --unset http.proxy
git config --global --unset https.proxy
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
# 1. 终端美化主题模式 ('random' 每次启动随机 / 'fixed' 固定经典 / 'starship' 极速)
$env:POWERSHELL_THEME_MODE = 'random'

# 2. 极简模式（'1' 跳过外部工具探测和 UI 初始化，保留基础配置与便利函数）
$env:POWERSHELL_PROFILE_MINIMAL = '0'

# 3. 启动横幅（'1' 开启 Fastfetch 动漫硬件面板，'0' 关闭实现纯净启动）
$env:POWERSHELL_PROFILE_BANNER = '1'

# 4. 现代化功能就绪提示卡片（'1' 开启，'0' 关闭）
$env:POWERSHELL_PROFILE_TIPS = '1'

# 5. Terminal-Icons 文件图标（'1' 开启，'0' 关闭可进一步优化交互响应）
$env:POWERSHELL_PROFILE_ICONS = '1'

# 6. vfox 默认按需启用；设为 '1' 自动启动时生成预算为 3 秒。
# 手动 Enable-Vfox 的生成预算为 15 秒，可通过 -TimeoutMs 调整（最多 60000）。
# 生成脚本中的 vfox 清理、环境更新调用各自有 1.5 秒预算。
$env:POWERSHELL_PROFILE_VFOX = '0'

# 7. PSReadLine 预测模式 ('InlineView' 行内灰色预测 / 'ListView' 下拉菜单列表)
$env:POWERSHELL_PREDICTION_VIEW = 'InlineView'
```

---

## 🧪 自动化测试与质量保障

本项目包含 5 套回归测试及 1 套性能测量工具，可在 `PowerShell 7` 与 `Windows PowerShell 5.1` 下运行。安装和注册表操作使用隔离替身，测试通过不代表真实联网安装、所有系统版本和断电场景均已验证。

2026-09-07 对 `c484a83` 的复核中，Windows 11 / PowerShell 7.6.5、PTY、固定主题、每模式 3 次：defaults 的 Profile 主体加载中位数为 **3.142 秒**，minimal 为 **0.417 秒**。这不是完整冷启动；不含进程创建、首次提示符渲染和终端绘制，且会受负载与插件缓存影响。详细配置和 full 模式数据见[开发与部署文档](开发与部署文档.md)。当前默认已开启图标、横幅和卡片，以上历史数据不代表当前默认启动性能；当前版本尚需单独测速。

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

# 5. 安装器集成与真实终端注册测试（MSYS2/NuShell 路径联动、Zoxide 初始化、异常穿透）
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-InstallerIntegration.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-InstallerIntegration.ps1

# 6. 交互式 Profile 启动耗时基准测量 (支持 -Mode defaults/minimal/full)
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
