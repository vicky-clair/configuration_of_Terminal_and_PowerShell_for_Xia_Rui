# Windows 全终端现代化与美化生产力套件

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2011%20|%2010%20|%208.1-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-PowerShell%207%20|%20WinPS%205.1%20|%20CMD%20|%20NuShell%20|%20MSYS2-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Shells" />
  <img src="https://img.shields.io/badge/Theme-120+%20Themes%20(Random/Fixed)-F5E0DC?style=for-the-badge&logo=starship&logoColor=black" alt="Theme" />
  <img src="https://img.shields.io/badge/Stability-Fault--Tolerant%20Tier%203-brightgreen?style=for-the-badge" alt="Stability" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

<p align="center">
  <b>开箱即用、安全无损、极速响应的 Windows 全终端美化与高效开发环境套件。</b><br>
  涵盖 Windows Terminal、PowerShell 7、Windows PowerShell 5.1、CMD、NuShell 以及 MSYS2。<br>
  配备独创的<b>三级包管理智能容错高成功率体系</b>、<b>PowerShell 7 每日随机主题</b>与<b>全自动前置快照一键原子回退</b>机制。
</p>

---

## 📚 详细文档导航

- 📖 **[开发与部署全景指南 (开发与部署文档.md)](开发与部署文档.md)**：深入剖析系统架构、配置拓扑、三级容错底层实现、随机主题算法、编码避坑规范与测试框架。
- 📦 **[部署与回退操作手册 (部署与回退.md)](部署与回退.md)**：快照存档、版本追溯、沙箱测试与一键回退实操手册。

---

## 🌟 核心特性

- 🎲 **PowerShell 7 默认“每日随机主题”（每日新鲜感，杜绝审美疲劳）**
  - **120+ 官方精美离线主题库**：安装时自动同步全量 Oh-My-Posh 官方主题至本地 `~/.posh-themes/`，**纯本地毫秒级随机抽取，启动零网络等待**；
  - **直观反馈与优雅提示**：每次启动终端顶部展示 `✨ 今日随机主题: <ThemeName> ✨`；
  - **双层防崩安全降级**：若抽取的第三方主题在特定环境下格式解析异常，自动无缝降级至经典内置 Catppuccin Mocha 主题，终端绝不报错；
  - **自由随时切换**：随时支持一键切换为【固定主题 (Catppuccin Mocha)】或【Starship 赛博朋克极速主题】。

- ⚡ **高稳定性与极高安装成功率（三级容错自愈体系）**
  - **前置解决无人值守挂起**：自动静默安装最新 NuGet PackageProvider 并信任官方 PSGallery 软件源，彻底根治传统安装时弹窗询问导致的进程挂起；
  - **就绪状态毫秒级跳过 (Fast-Path Check)**：已存在的工具链自动跳过，多次运行不产生任何网络浪费；
  - **第一梯队 (Chocolatey)**：优先使用 `choco` 安装，内置捕获并**自动重试最多 2 次**；
  - **第二梯队 (WinGet 自动修复与接管)**：Choco 异常或不可用时，自动执行 `winget source reset --force` 修复本地源缓存，并使用 WinGet 官方源接管安装；
  - **第三梯队 (Scoop 终极跨版本保底)**：在不支持 WinGet 的环境（如 Windows 8.1）自动启用 Scoop 仓库安装。

- 🖥️ **五大主流命令行终端全覆盖**
  - **Windows Terminal**：沉浸式亚克力磨砂透明、Catppuccin Mocha 配色、自定义壁纸融合、JetBrainsMono Nerd Font 编程图标字体；
  - **PowerShell 7 (pwsh)**：Fastfetch 专属 ASCII 硬件横幅、功能就绪卡片、Yazi 目录穿梭集成（`y`）、PSReadLine 行内预测与历史检索、Terminal-Icons 文件图标；
  - **Windows PowerShell 5.1 (系统内置)**：专为 Win 10/11 内置终端与 Win 8.1 调优，**强制 UTF-8 编码彻底根治 GBK 936 乱码与 Parser 报错**，加载极速 Starship 提示符，毫秒级冷启动；
  - **CMD (命令提示符)**：Clink 语法着色与自动补全、Starship 霓虹渐变提示符、全面映射 Unix/Git 常用命令别名（`ll`, `la`, `cat`, `grep` 等）；
  - **NuShell (nu)**：结构化 Shell 环境配置，自动挂载 Starship 提示符与 Zoxide 目录快跳，开箱即用现代 Unix 别名；
  - **MSYS2 (bash)**：配置 `MSYS2_PATH_TYPE=inherit` 继承 Windows 系统 PATH（在 MSYS2 中可直接调用宿主机原生安装的编译器和工具链），集成 Starship 与 UTF-8 环境。

- 🎨 **动漫 ASCII Art 横幅与配置完全内聚（零手动查找）**
  - 项目内置 `fastfetch/ascii.txt`（高精度二次元点阵字符画）与 `fastfetch/config.jsonc`（Catppuccin 硬件监控面板）；
  - 安装脚本全自动分发横幅并动态适配为本机的物理绝对路径，免去用户手动寻找和复制素材的繁琐。

- 🛡️ **安全第一：全自动前置 SHA-256 镜像与一键原子回退**
  - 执行任何安装或部署前，脚本自动为当前所有系统配置文件创建**精确字节镜像与 SHA-256 散列清单**；
  - 配套 `Restore-All.ps1`，随时支持 `-WhatIf` 预演或一键无损复原，并在回退前额外捕获 `pre-rollback` 救援快照，确保数据万无一失。

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
├── Restore-All.ps1                  # 全终端一键无损回退脚本 (支持 -WhatIf 预演)
├── Deploy-TerminalConfiguration.ps1 # 生产部署同步脚本 (Windows Terminal + PS7 + CMD)
├── Restore-TerminalConfiguration.ps1# 部署委托回退脚本
├── scripts/
│   └── TerminalSetupCommon.ps1      # 跨平台稳态底层库 (三级容错、NuGet自愈、SHA-256快照)
├── tests/
│   ├── Verify-Configuration.ps1     # 静态语法、JSON 验证、BOM 规范与别名回归自检
│   └── Verify-Deployment.ps1        # 隔离沙箱部署、回退完整性与防覆写自动化测试
├── cmd/                             # CMD 批处理与 Clink Lua 增强脚本
├── fastfetch/                       # 内聚的 Fastfetch 动漫字符画与 Catppuccin 硬件面板
├── starship/                        # Starship 霓虹赛博朋克全局配置文件
├── settings.json                    # Windows Terminal 深度美化配置文件
├── Microsoft.PowerShell_profile.ps1 # PowerShell 7 核心 Profile 源码
├── 开发与部署文档.md                 # 架构设计、实现原理与避坑指南
└── 部署与回退.md                     # 备份归档与回退操作指南
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
| **PowerShell 7** | `pwsh -File .\Install-PowerShell7.ps1` | **直接回车默认采用【每日随机主题】**，亦可输入 `1` 选择 Catppuccin 固定主题或 `3` Starship |
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
| **极速 TUI 文件管理器** | `y` (退出自动切目录) / `yazi` | 全终端 | 基于 Rust 的现代化双栏文件管理器 |
| **Docker 容器 TUI 管理** | `lzd` / `lazydocker` | PS7 / CMD | 纯终端交互式 Docker 镜像与容器监控管理 |
| **彩色文件列表** | `ll` / `la` / `lt` | 全终端 | 调用 `eza` 图标排版（目录树/包含隐藏项） |
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

# 2. 启动横幅（'1' 开启 Fastfetch 动漫硬件面板，'0' 关闭实现纯净冷启动）
$env:POWERSHELL_PROFILE_BANNER = '1'

# 3. 现代化功能就绪提示卡片（'1' 开启，'0' 关闭）
$env:POWERSHELL_PROFILE_TIPS = '1'

# 4. Terminal-Icons 文件图标（'1' 开启，'0' 关闭可进一步减少启动耗时）
$env:POWERSHELL_PROFILE_ICONS = '1'

# 5. vfox 版本环境管理器加载（'1' 开启，'0' 关闭）
$env:POWERSHELL_PROFILE_VFOX = '1'

# 6. PSReadLine 预测模式 ('InlineView' 行内灰色预测 / 'ListView' 下拉菜单列表)
$env:POWERSHELL_PREDICTION_VIEW = 'InlineView'
```

---

## 🧪 自动化测试与质量保障

本项目包含两套严谨的自动化验证套件，可直接在本地运行以确保系统与配置 100% 正常：

```powershell
# 1. 静态语法、JSON 合法性、BOM 编码与别名自检（同时支持 PS7 与 WinPS 5.1）
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Configuration.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Configuration.ps1

# 2. 隔离沙箱环境部署、回退完整性与防覆写回归测试
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Deployment.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Verify-Deployment.ps1
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
