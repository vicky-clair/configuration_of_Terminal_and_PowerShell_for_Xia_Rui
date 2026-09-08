# Windows Terminal & Multi-Shell Modernization & Beautification Suite
# Windows 全终端现代化与美化生产力套件 / Windows ターミナル & マルチシェル モダン化・美化スイート

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Windows%2011%20|%2010%20|%208.1-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Shell-PowerShell%207%20|%20WinPS%205.1%20|%20CMD%20|%20NuShell%20|%20MSYS2-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Shells" />
  <img src="https://img.shields.io/badge/Theme-120+%20Themes%20(Random/Fixed/Cyberpunk)-F5E0DC?style=for-the-badge&logo=starship&logoColor=black" alt="Theme" />
  <img src="https://img.shields.io/badge/Font-JetBrainsMono%20Nerd%20Font%20v3-orange?style=for-the-badge&logo=font-awesome&logoColor=white" alt="Font" />
  <img src="https://img.shields.io/badge/Safety-Rescue%20Snapshot%20&%20Atomic%20IO-brightgreen?style=for-the-badge" alt="Safety" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

---

<p align="center">
  <b>Language Navigation / 语言导航 / 言語ナビゲーション</b><br>
  <a href="#-english"><b>🇬🇧 English (Default)</b></a> &nbsp;|&nbsp;
  <a href="#-简体中文"><b>🇨🇳 简体中文</b></a> &nbsp;|&nbsp;
  <a href="#-日本語"><b>🇯🇵 日本語</b></a>
</p>

---

<a id="-english"></a>
## 🇬🇧 English

### Overview

**Windows Terminal & Multi-Shell Modernization & Beautification Suite** is an enterprise-grade, turn-key automation and configuration framework designed to transform developer terminals on **Windows 11, Windows 10, and Windows 8.1**. 

It provides seamless integration, visual excellence (Catppuccin Mocha palette, acrylic blur, vibrant Starship / Oh My Posh prompts), ultra-fast startup performance, and rock-solid reliability across **Windows Terminal, PowerShell 7, Windows PowerShell 5.1, CMD (Command Prompt), NuShell, and MSYS2**.

#### Core Architectural Highlights
- ⚡ **On-Demand Lazy Loading & Sub-second Startup**: Defers heavy version managers (`vfox activate`), leverages streaming pipelines for file search (`fif` + `fzf`), and provides instant short-circuit capabilities (`POWERSHELL_PROFILE_MINIMAL=1`).
- 🎲 **PowerShell 7 Dynamic Startup Themes**: Synchronizes 120+ official Oh-My-Posh themes to a local directory for millisecond-level, offline theme randomization upon every terminal launch, complete with automatic fallback to Catppuccin Mocha.
- 📦 **Project-Bundled Offline Nerd Fonts**: Includes 48 full official `JetBrainsMono Nerd Font` (`.ttf`) variants. Equipped with a dedicated installer (`Install-Fonts.ps1`) utilizing Windows GDI APIs (`AddFontResourceW`) and `WM_FONTCHANGE` broadcasting for instantaneous, network-free font registration.
- 🛡️ **Two-Phase Atomic Rescue Snapshots**: Backs up 19 configuration assets and registry settings across all shells prior to applying any changes, with SHA-256 verification and atomic single-file swaps (`[IO.File]::Replace`).
- 🔒 **CMD Working Directory Hijack Hardening**: Enforces `%SystemRoot%\System32` absolute executable binding and builds pre-compiled Clink Starship Lua scripts to neutralize unquoted CWD executable hijacking vulnerabilities.
- 🌐 **Three-Tier Fallback Package Management**: Orchestrates Chocolatey (with automated retry) ➜ WinGet (source reset) ➜ Scoop (multi-mirror backup) to guarantee smooth installation regardless of local proxy or firewall environments.

---

### Quick Start

#### Prerequisites
- Operating System: Windows 11, Windows 10, or Windows 8.1 (with WMF 5.1).
- PowerShell Execution Policy: `RemoteSigned` (automatically configured by our installers).

#### 1. One-Click All-in-One Installation
Clone the repository and launch the master orchestrator in PowerShell:

```powershell
# Open PowerShell (pwsh or powershell.exe)
git clone https://github.com/vicky-clair/configuration_of_Terminal_and_PowerShell_for_Xia_Rui.git
cd configuration_of_Terminal_and_PowerShell_for_Xia_Rui

# Install core shells (PowerShell 7, WinPS 5.1, CMD, Fonts, Fastfetch)
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1

# Optional: Include NuShell and MSYS2
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1 -All
```

#### 2. Standalone Modular Installers
If you only wish to configure specific shells:

| Target Shell / Component | Script | Description |
| :--- | :--- | :--- |
| **Fonts (Offline)** | [`Install-Fonts.ps1`](Install-Fonts.ps1) | Installs 48 bundled JetBrainsMono NF fonts via Win32 GDI & Registry |
| **PowerShell 7** | [`Install-PowerShell7.ps1`](Install-PowerShell7.ps1) | CLI tools, PSReadLine, Fastfetch banner, random/fixed themes |
| **WinPS 5.1** | [`Install-WinPowerShell51.ps1`](Install-WinPowerShell51.ps1) | UTF-8 code page repair, Starship/Catppuccin prompt, PSReadLine |
| **CMD Prompt** | [`Install-Cmd.ps1`](Install-Cmd.ps1) | Clink 1.8+, Starship cyberpunk prompt, Unix aliases (`ls`, `cat`, `grep`) |
| **NuShell** | [`Install-NuShell.ps1`](Install-NuShell.ps1) | Structured data shell, Starship prompt, Zoxide, Unix aliases |
| **MSYS2** | [`Install-MSYS2.ps1`](Install-MSYS2.ps1) | Inherits Windows host PATH, Bash Starship prompt, UTF-8 locale |

#### 3. Disaster Recovery & Zero-Loss Rollback
Every installation automatically registers a restore point in `.last-install-backup`. You can safely preview and restore all configurations at any time:

```powershell
# Dry-run preview of rollback
pwsh -File .\Restore-All.ps1 -WhatIf

# Execute zero-loss atomic rollback
pwsh -File .\Restore-All.ps1
```

---

### Key Shortcuts & Commands

| Shortcut / Command | Scope | Description |
| :--- | :--- | :--- |
| `z <directory>` | All Shells | Smart jump to frequent directory via **zoxide** |
| `zi` / <kbd>Alt</kbd> + <kbd>Z</kbd> | PowerShell 7 | Interactive fuzzy directory navigation with **fzf** |
| <kbd>Ctrl</kbd> + <kbd>F</kbd> | PowerShell 7 | Interactive fuzzy file path search & inline insertion |
| <kbd>Ctrl</kbd> + <kbd>R</kbd> | PowerShell 7 / CMD | Interactive reverse history search |
| `fif <keyword>` | PowerShell 7 | High-performance streaming ripgrep search into fzf |
| `y` / `yazi` | PowerShell 7 | Blazing-fast terminal file manager with directory sync |
| `lg` / `lazygit` | All Shells | Visual interactive Git management UI |
| `lzd` / `lazydocker`| All Shells | Visual interactive Docker container manager |
| `ll`, `la`, `lt` | All Shells | Modern directory listings with icons & git status (**eza**) |
| `cat <file>` | All Shells | Syntax-highlighted file preview (**bat**) |

---

<a id="-简体中文"></a>
## 🇨🇳 简体中文

### 项目概览

**Windows 全终端现代化与美化生产力套件**是一套面向 **Windows 11、Windows 10 及 Windows 8.1** 的现代化终端工程化解决方案。

全面覆盖 **Windows Terminal、PowerShell 7 (pwsh)、Windows PowerShell 5.1 (系统内置)、CMD (命令提示符)、NuShell 以及 MSYS2**。彻底告别编码乱码、字体方块、单调黑白与启动卡顿，赋予 Windows 终端丝滑的操作手感与卓越的工业级稳定性。

---

### 🌟 核心特性与技术亮点

1. **⚡ 按需加载与毫秒级极速冷启动**
   - **版本管理按需加载**：彻底解决 `vfox activate` 造成的启动阻塞，默认提供 `Enable-Vfox` 按需启用；
   - **流式全文检索 (`fif`)**：管道流式传输直通 `fzf`，杜绝大仓库内存暴涨与界面假死；
   - **顶层最小化短路**：支持设置环境变量 `$env:POWERSHELL_PROFILE_MINIMAL = '1'` 实现纯净秒开。

2. **🎲 PowerShell 7 每次启动随机主题**
   - **120+ 官方离线主题库**：全量 Oh-My-Posh 官方主题离线同步至本地 `~/oh-my-posh-themes/`，**零网络耗时，本地毫秒级随机呈现**；
   - **双层防崩安全降级**：若抽取的第三方主题解析异常，自动无缝回滚至经典 Catppuccin Mocha 主题；
   - **多模式支持**：亦可选择固定 Catppuccin Mocha 或 Starship 赛博朋克霓虹渐变。

3. **📦 项目内置 JetBrainsMono Nerd Font 离线字体包**
   - 内置完整 48 个官方 `.ttf` 字体（包含 Regular、Bold、Italic、Mono、Propo 等全套变体）；
   - 配套独立安装器 [`Install-Fonts.ps1`](Install-Fonts.ps1)，利用 Win32 GDI `AddFontResourceW` 与注册表并发加固，遇到终端正在使用字体时自动平滑跳过占用文件，**无需连网、无需代理、一键安装生效**。

4. **🛡️ 19 项全资产原子快照与两阶段救援回退**
   - 统合管理涵盖 PS7、WinPS 5.1、Windows Terminal、CMD、NuShell、MSYS2 及注册表项等 19 项关键配置；
   - 回退前自动创建 `pre-rollback-<guid>` 副本，使用 `[IO.File]::Replace` 保证物理单文件原子替换，拒绝半写入损坏。

5. **🔒 CMD 不可信目录防劫持加固**
   - 彻底解决命令提示符在当前工作目录调用裸命令的劫持风险，关键系统指令强制绑定 `%SystemRoot%\System32`（如 `chcp.com`, `doskey.exe`）；
   - Fastfetch 与 Clink 在安装期解析固化为绝对物理路径；
   - CMD AutoRun 智能识别批处理及 `/c` 静默调用，非交互调用零开销秒过。

6. **🎨 动漫点阵 ASCII 横幅与硬件监控**
   - 内置专属二次元高精度点阵字符画 (`fastfetch/ascii.txt`) 与 Catppuccin 硬件监控面板 (`fastfetch/config.jsonc`)；
   - 自动适配物理路径，跨 PowerShell、NuShell、CMD 与 MSYS2 统一展示。

---

### 🚀 快速上手

#### 1. 全终端一键集成总装
在 PowerShell（以当前普通用户运行即可）中执行：

```powershell
# 克隆本仓库
git clone https://github.com/vicky-clair/configuration_of_Terminal_and_PowerShell_for_Xia_Rui.git
cd configuration_of_Terminal_and_PowerShell_for_Xia_Rui

# 部署核心终端 (PowerShell 7, Windows PowerShell 5.1, CMD, 字体与 Fastfetch)
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1

# 若需要同时配置 NuShell 与 MSYS2
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1 -All
```

#### 2. 独立组件安装器

```powershell
# 仅安装并注册离线 JetBrainsMono Nerd Font 字体
pwsh -File .\Install-Fonts.ps1

# 仅配置 PowerShell 7 现代化环境 (交互选择：随机主题 / 固定主题 / Starship)
pwsh -File .\Install-PowerShell7.ps1

# 仅配置 Windows PowerShell 5.1 (修复 UTF-8 编码与秒开提示符)
powershell.exe -File .\Install-WinPowerShell51.ps1

# 仅配置 CMD 命令提示符 (注入 Clink 与 Starship 提示符)
pwsh -File .\Install-Cmd.ps1

# 仅配置 NuShell (跨版本兼容、Starship、Zoxide 与结构化别名)
pwsh -File .\Install-NuShell.ps1

# 仅配置 MSYS2 (继承 Windows PATH，挂载 Starship 与 UTF-8)
pwsh -File .\Install-MSYS2.ps1
```

#### 3. 配置检查与灾难恢复

```powershell
# 运行自动化回归测试套件 (AST语法、JSON规范、GUID与别名自检)
pwsh -NoProfile -File .\tests\Verify-Configuration.ps1

# 预演回退 (不改动任何实际文件)
pwsh -File .\Restore-All.ps1 -WhatIf

# 恢复至安装前状态
pwsh -File .\Restore-All.ps1
```

---

<a id="-日本語"></a>
## 🇯🇵 日本語

### プロジェクト概要

**Windows ターミナル & マルチシェル モダン化・美化スイート** は、**Windows 11、Windows 10、および Windows 8.1** 環境における開発者向けターミナルを総合的に強化・美化するオープンソース自動化フレームワークです。

**Windows Terminal、PowerShell 7、Windows PowerShell 5.1、CMD（コマンドプロンプト）、NuShell、および MSYS2** に対応し、文字化けの解消、最新のフォールバック・パッケージ管理、Nerd Font オフライン導入、Catppuccin Mocha の統一デザイン、そして起動ごとのテーマランダム化を提供します。

---

### 🌟 主な機能と特徴

1. **⚡ オンデマンド読み込みと超高速起動**
   - 重いバージョンマネージャー（`vfox activate`）を遅延ロード化し、起動時間を 10 秒から 0.5 秒以下へ短縮；
   - ストリーミング検索パイプライン（`fif` + `fzf`）により、大規模リポジトリでのメモリ消費とフリーズを防止；
   - `$env:POWERSHELL_PROFILE_MINIMAL = '1'` による純粋な最小構成起動もサポート。

2. **🎲 PowerShell 7 起動時テーマランダム機能**
   - 120種類以上の Oh-My-Posh 公式テーマをローカル（`~/oh-my-posh-themes/`）にオフライン同期；
   - **ネットワーク待機なし・完全ローカル** でターミナル起動ごとに新しいテーマをランダム表示；
   - テーマの書式異常が発生した場合は、安定した Catppuccin Mocha テーマへ自動フォールバック。

3. **📦 JetBrainsMono Nerd Font 完全オフライン同根**
   - プロジェクト内に 48 種類の公式 `.ttf` フォントを標準同根；
   - 独立スクリプト [`Install-Fonts.ps1`](Install-Fonts.ps1) により、Win32 GDI `AddFontResourceW` とレジストリを用いて、プロキシや海外接続環境に依存せず高速インストールが可能。

4. **🛡️ 19 アセットの完全バックアップとゼロロス・ロールバック**
   - すべてのシェル設定、レジストリ、Windows Terminal の設定（計 19 ファイル）を変更前に自動バックアップ；
   - `[IO.File]::Replace` によるアトミックな単一ファイル置換で、安全かつ不可逆な破壊を防止；
   - `Restore-All.ps1` を実行するだけで、いつでもワンタッチで以前の環境にロールバック可能。

5. **🔒 CMD のカレントディレクトリ乗っ取り防止（セキュリティ強化）**
   - カレントディレクトリ内の同名バイナリによるコマンド乗っ取りを防ぐため、システム標準コマンド（`chcp.com`, `doskey.exe`）を `%SystemRoot%\System32` のフルパスに固定；
   - Clink と Starship の初期化スクリプトを事前生成し、安全かつ高速な実行を実現。

6. **🎨 アスキーアート（Fastfetch）とシステムダッシュボード**
   - 精緻なドット絵風アスキーアート (`fastfetch/ascii.txt`) と Catppuccin ハードウェアモニターを内蔵；
   - どのシェルからでも美しい起動バナーを表示可能。

---

### 🚀 クイックスタート

#### 1. 一括インストール
PowerShell（管理者権限不要、通常ユーザー権限で実行可能）を開き、以下を実行します：

```powershell
# リポジトリをクローン
git clone https://github.com/vicky-clair/configuration_of_Terminal_and_PowerShell_for_Xia_Rui.git
cd configuration_of_Terminal_and_PowerShell_for_Xia_Rui

# 主要環境の一括インストール (PowerShell 7, WinPS 5.1, CMD, フォント, Fastfetch)
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1

# NuShell と MSYS2 も含めてすべてセットアップする場合
pwsh -ExecutionPolicy Bypass -File .\Install-All.ps1 -All
```

#### 2. 個別シェルインストーラー

```powershell
# オフラインフォントのみをインストール
pwsh -File .\Install-Fonts.ps1

# PowerShell 7 のみをセットアップ（ランダム / 固定 / Starship 選択可能）
pwsh -File .\Install-PowerShell7.ps1

# Windows PowerShell 5.1 のみをセットアップ（UTF-8 修正・高速起動）
powershell.exe -File .\Install-WinPowerShell51.ps1

# CMD のみをセットアップ（Clink + Starship + エイリアス）
pwsh -File .\Install-Cmd.ps1

# NuShell のみをセットアップ（Starship + Zoxide）
pwsh -File .\Install-NuShell.ps1

# MSYS2 のみをセットアップ（Windows PATH 継承 + Starship）
pwsh -File .\Install-MSYS2.ps1
```

#### 3. 設定検証とロールバック

```powershell
# 構文・GUID・設定整合性の自動検証
pwsh -NoProfile -File .\tests\Verify-Configuration.ps1

# ロールバックのドライラン（事前確認）
pwsh -File .\Restore-All.ps1 -WhatIf

# インストール前の状態へ完全復元
pwsh -File .\Restore-All.ps1
```

---

## 📂 Repository Layout / 项目架构 / ディレクトリ構成

```text
powershelldome/
├── Install-All.ps1                  # Master installer for all shells (-All, -IncludeNuShell, -IncludeMSYS2)
├── Install-PowerShell7.ps1          # PowerShell 7 installer (Random themes / Catppuccin / Starship)
├── Install-WinPowerShell51.ps1      # Windows PowerShell 5.1 installer (UTF-8 fix & lightweight prompt)
├── Install-Cmd.ps1                  # CMD Clink + Starship modern environment installer
├── Install-NuShell.ps1              # NuShell cross-version configuration installer
├── Install-MSYS2.ps1                # MSYS2 developer shell installer (PATH inheritance)
├── Install-Fonts.ps1                # Offline font installer (JetBrainsMono Nerd Font into system)
├── Restore-All.ps1                  # One-click zero-loss configuration restore & rollback
├── Deploy-TerminalConfiguration.ps1 # Production deployment script (Windows Terminal + PS7 + CMD)
├── Restore-TerminalConfiguration.ps1# Production rollback delegate script
├── settings.json                    # Windows Terminal settings (Acrylic, Catppuccin Mocha, Fallback fonts)
├── Microsoft.PowerShell_profile.ps1 # PowerShell 7 profile (Fastfetch banner, fzf, PSReadLine, aliases)
├── fonts/                           # 48 official JetBrainsMono Nerd Font TTF files (NFM/NF/NFP)
├── fastfetch/                       # Anime ASCII art (ascii.txt) & Catppuccin config (config.jsonc)
├── starship/                        # Cyberpunk neon Starship prompt configuration (starship.toml)
├── cmd/                             # CMD autorun.cmd, Clink Lua scripts (starship.lua, settings.lua)
├── scripts/
│   ├── TerminalState.ps1            # Snapshots, rescue backups, atomic IO & path resolutions
│   └── TerminalSetupCommon.ps1      # Resilient installation backend (3-tier fallback, theme sync)
└── tests/
    ├── Verify-Configuration.ps1     # AST syntax, JSON validity, GUID uniqueness & profile reload tests
    └── Verify-Deployment.ps1        # Sandbox deployment & rollback integrity verification
```

---

## 📑 Documentation Index / 详细文档索引 / ドキュメント一覧

- 💻 **[IDE & Editor Integration Guide (IDE与开发工具集成指南.md)](IDE与开发工具集成指南.md)**: Comprehensive setup for **VS Code**, **Cursor**, and **JetBrains IDEs (IntelliJ IDEA, PyCharm, WebStorm, CLion)** to prevent missing icon glyphs and configure integrated fonts.
- 📖 **[Developer & Architecture Manual (开发与部署文档.md)](开发与部署文档.md)**: Deep dive into the three-tier package manager fallback, random theme algorithm, atomic snapshot mechanisms, and UTF-8 encoding patterns.
- 📦 **[Deployment & Rollback Operations Manual (部署与回退.md)](部署与回退.md)**: Step-by-step instructions for snapshot archiving, verification sandboxes, and safe rollbacks.
- 🎨 **[Windows Terminal Beautification Reference (windows终端美化相关.md)](windows终端美化相关.md)**: Detailed documentation of the Catppuccin Mocha color palette, acrylic backdrop filters, and design evolution.

---

## 📄 License / 开源协议 / ライセンス

This project is licensed under the [MIT License](LICENSE).
Feel free to use, modify, and distribute it for personal and commercial development environments.
