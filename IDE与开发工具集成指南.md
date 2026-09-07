# Windows 现代化终端与 IDE / 编辑器集成配置指南

本指南详细说明如何将本项目美化配置好的终端（**PowerShell 7 / Starship / NuShell / CMD**）深度集成到 **Visual Studio Code (VS Code)** 与 **JetBrains 全家桶 (IntelliJ IDEA, PyCharm, WebStorm, GoLand, CLion, Android Studio)** 中，实现无缝编码、无乱码中文、极速命令行与炫彩提示符。

---

## 目录
- [一、核心前置知识：为什么 IDE 终端图标会乱码？](#一核心前置知识为什么-ide-终端图标会乱码)
- [二、Visual Studio Code (VS Code / Cursor) 深度配置](#二visual-studio-code-vs-code--cursor-深度配置)
  - [1. 快捷一键配置 (settings.json)](#1-快捷一键配置-settingsjson)
  - [2. 图形界面配置步骤](#2-图形界面配置步骤)
  - [3. 配置多终端 Profile (PowerShell 7 / NuShell / CMD / MSYS2)](#3-配置多终端-profile-powershell-7--nushell--cmd--msys2)
- [三、JetBrains 全家桶 (IDEA / WebStorm / PyCharm 等) 配置](#三jetbrains-全家桶-idea--webstorm--pycharm-等-配置)
  - [1. 设置默认 Shell 路径](#1-设置默认-shell-路径)
  - [2. 必须配置：设置终端独立字体](#2-必须配置设置终端独立字体)
  - [3. 配置环境变量与字符集](#3-配置环境变量与字符集)
- [四、常见问题排查与避坑指南](#四常见问题排查与避坑指南)

---

## 一、核心前置知识：为什么 IDE 终端图标会乱码？

IDE（如 VS Code 或 IDEA）的内置终端默认使用的是**编辑器的代码字体**（或系统默认等宽字体），而 Starship 提示符、Git 分支标记、文件夹图标（`Terminal-Icons` / `eza`）依赖于 **Nerd Font 图标字符集**。

> [!IMPORTANT]
> **无论使用哪款 IDE，集成的首要核心条件都是：将 IDE 的【内置终端字体 (Terminal Font)】单独设置为已安装的 `JetBrainsMono NF` 或 `JetBrainsMono NFP`，否则图标必然显示为小方框或问号。**

本项目各安装脚本已为您自动安装了 `JetBrainsMono-NF` 字体，您只需在 IDE 中按以下指引启用即可。

---

## 二、Visual Studio Code (VS Code / Cursor) 深度配置

### 1. 快捷一键配置 (settings.json)

在 VS Code 中按下快捷键 <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd>，输入：
```text
Preferences: Open User Settings (JSON)
```
打开用户的 `settings.json`，在最外层大括号内补充或替换以下配置项：

```json
{
  // =========================================================================
  // 1. 终端字体配置 (关键：保证 Starship 赛博朋克提示符与文件图标正常渲染)
  // =========================================================================
  "terminal.integrated.fontFamily": "'JetBrainsMono NFP', 'JetBrainsMono Nerd Font', 'Cascadia Code', monospace",
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.fontWeight": "normal",

  // =========================================================================
  // 2. 默认使用 PowerShell 7 现代化终端
  // =========================================================================
  "terminal.integrated.defaultProfile.windows": "PowerShell 7",

  // =========================================================================
  // 3. 多终端配置方案 (支持在 VS Code 下拉菜单自由切换)
  // =========================================================================
  "terminal.integrated.profiles.windows": {
    "PowerShell 7": {
      "source": "PowerShell",
      "args": ["-NoLogo"],
      "icon": "terminal-powershell"
    },
    "Windows PowerShell 5.1": {
      "path": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
      "args": ["-NoLogo"],
      "icon": "terminal-powershell"
    },
    "CMD (Clink & Starship)": {
      "path": "C:\\Windows\\System32\\cmd.exe",
      "icon": "terminal-cmd"
    },
    "NuShell": {
      "path": "nu.exe",
      "icon": "terminal"
    },
    "MSYS2 UCRT64": {
      "path": "C:\\msys64\\msys2_shell.cmd",
      "args": ["-defterm", "-here", "-no-start", "-ucrt64"],
      "icon": "terminal-bash"
    }
  },

  // =========================================================================
  // 4. 控制台与平滑渲染优化
  // =========================================================================
  "terminal.integrated.gpuAcceleration": "on",
  "terminal.integrated.cursorBlinking": true,
  "terminal.integrated.cursorStyle": "line",
  "terminal.integrated.smoothScrolling": true,
  "terminal.integrated.env.windows": {
    "PYTHONIOENCODING": "utf-8",
    "POWERSHELL_PROFILE_BANNER": "1" // 若想在 IDE 中保持极简清爽，可改为 "0" 隐藏 Fastfetch
  }
}
```

### 2. 图形界面配置步骤

如果您习惯使用图形界面操作：
1. 打开 VS Code 设置：快捷键 <kbd>Ctrl</kbd> + <kbd>,</kbd>；
2. 在顶部搜索框输入：`terminal.integrated.fontFamily`；
3. 将字体名称修改填入：`'JetBrainsMono NFP', 'JetBrainsMono Nerd Font'`；
4. 搜索：`terminal.integrated.defaultProfile: Windows`；
5. 在下拉菜单中选择：`PowerShell 7`（或 `pwsh`）；
6. 按下 <kbd>Ctrl</kbd> + <kbd>`</kbd> 新建终端，即可查看炫彩效果！

---

## 三、JetBrains 全家桶 (IDEA / WebStorm / PyCharm 等) 配置

适用于 IntelliJ IDEA、PyCharm、WebStorm、GoLand、CLion、Rider、DataGrip、Android Studio 等全部 JetBrains 旗下 IDE。

### 1. 设置默认 Shell 路径

1. 打开设置面板：快捷键 <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>S</kbd>（或菜单栏 `File` -> `Settings`）；
2. 导航至：**Tools (工具)** -> **Terminal (终端)**；
3. 在右侧找到 **Shell path (Shell 路径)**：
   - **推荐设置为 PowerShell 7**：
     - 若通过 Scoop 安装，输入：`pwsh.exe` 或 `C:\Users\<您的用户名>\scoop\shims\pwsh.exe`；
     - 若通过 WinGet/MSI 安装，输入：`C:\Program Files\PowerShell\7\pwsh.exe`；
   - 若想使用 NuShell，可填入：`nu.exe`；
   - 若想使用 CMD 现代化环境，填入：`cmd.exe`。

### 2. 必须配置：设置终端独立字体

JetBrains IDE 允许终端拥有独立的字体配置（不影响代码编辑器的字体）：
1. 在设置面板左侧导航至：**Editor (编辑器)** -> **Color Scheme (配色方案)** -> **Console Font (控制台字体)**；
   *(在 2023+ 新版中亦可查看 `Tools` -> `Terminal` 下的字体选项)*；
2. 勾选 **Use console font instead of the default (使用控制台字体替代默认字体)**；
3. **Font (字体)** 下拉列表选择：`JetBrainsMono Nerd Font` 或 `JetBrainsMono NF`；
4. **Size (字号)** 推荐：`13` 或 `14`，Line spacing (行高) 保持 `1.1` 或 `1.2`；
5. 点击 **Apply (应用)**。

### 3. 配置环境变量与字符集

在 **Tools (工具)** -> **Terminal (终端)** 页面中：
- 勾选 **Override IDE encoding (覆盖 IDE 编码)** 并确保选择为 **UTF-8**；
- 在 **Environment variables (环境变量)** 中点击右侧图标添加：
  - 名称：`PYTHONIOENCODING`，值：`utf-8`
  - *(可选)* 若希望在 IDE 终端里隐藏庞大的 Fastfetch ASCII 硬件面板以获得最大可视空间，添加变量：
    - 名称：`POWERSHELL_PROFILE_BANNER`，值：`0`

---

## 四、常见问题排查与避坑指南

### 1. 图标仍然是方块或问号？
- **原因**：字体名称拼写不一致，或者 IDE 使用了非等宽图标字体。
- **解决**：在字体列表中务必寻找名称带有 `Nerd Font`、`NF` 或 `NFP` 的字体项。不要选择不带后缀的普通 `JetBrains Mono`。

### 2. IDE 打开终端时出现乱码或中文问号？
- **原因**：IDE 默认控制台编码为 GBK (CodePage 936)。
- **解决**：本项目在 `Microsoft.PowerShell_profile.ps1` 和 `Install-WinPowerShell51.ps1` 中均自动注入了强制 UTF-8 修复代码：
  ```powershell
  $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  ```
  在 IDE 终端中输入 `chcp`，确保输出为 `65001`。

### 3. 在 IDE 中启动终端觉得太宽，想关掉 Fastfetch 字符画？
- **快捷方法**：
  在您的项目环境或者终端中，只需执行：
  ```powershell
  $env:POWERSHELL_PROFILE_BANNER = '0'
  ```
  或在 IDE 的 Terminal 环境变量设置中配置 `POWERSHELL_PROFILE_BANNER=0`，下次打开终端即可享受零横幅极速秒开模式。

### 4. 快捷键与 IDE 查找快捷键冲突？
- 本终端套件提供了快捷文件搜索 `fv`（模糊查文件 + 预览 + Neovim 打开）和全局关键字秒搜 `fif`（Ripgrep + FZF + 实时高亮）：
  - 在内置终端中直接输入 `fv` 或 `fif` 即可直接激活，无需按 Ctrl+F / Ctrl+R，完美避免与 IDE 全局搜索热键冲突！
