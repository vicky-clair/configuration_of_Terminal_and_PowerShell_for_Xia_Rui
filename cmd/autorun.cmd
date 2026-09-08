@echo off
if "%~1"=="--help" goto :show_help
if "%~1"=="--shortcuts" goto :show_help
if "%~1"=="help" goto :show_help
if "%~1"=="shortcuts" goto :show_help

setlocal EnableExtensions DisableDelayedExpansion
rem Strip quotes before comparing CMDCMDLINE, never echo untrusted command text into a pipe.
set "_terminal_line=%CMDCMDLINE:"=%"
if not "%_terminal_line: /c=%"=="%_terminal_line%" exit /b
if not "%_terminal_line: /C=%"=="%_terminal_line%" exit /b
if defined TERMINAL_CMD_ACTIVE exit /b
set "TERMINAL_CMD_ACTIVE=1"
rem 1. 设置控制台代码页为 UTF-8 (65001)，解决中文与特殊字符乱码
"%SystemRoot%\System32\chcp.com" 65001 >nul 2>&1

rem 2. 通过 Doskey 注入现代化 CLI 快捷别名
rem --- 目录导航与树形列表 ---
"%SystemRoot%\System32\doskey.exe" ..=cd ..
"%SystemRoot%\System32\doskey.exe" ...=cd ..\..
"%SystemRoot%\System32\doskey.exe" ....=cd ..\..\..
"%SystemRoot%\System32\doskey.exe" ls=eza --icons $*
"%SystemRoot%\System32\doskey.exe" ll=eza -l --icons --group-directories-first $*
"%SystemRoot%\System32\doskey.exe" la=eza -la --icons --group-directories-first $*
"%SystemRoot%\System32\doskey.exe" l=eza -l --icons $*
"%SystemRoot%\System32\doskey.exe" lt=eza --tree --level=2 --icons --group-directories-first $*
"%SystemRoot%\System32\doskey.exe" lt3=eza --tree --level=3 --icons --group-directories-first $*

rem --- 文件查看、搜索与基础工具 ---
"%SystemRoot%\System32\doskey.exe" cat=bat --paging=never $*
"%SystemRoot%\System32\doskey.exe" catp=bat $*
"%SystemRoot%\System32\doskey.exe" clear=cls
"%SystemRoot%\System32\doskey.exe" grep=rg $*
"%SystemRoot%\System32\doskey.exe" findstr=rg $*
"%SystemRoot%\System32\doskey.exe" which=where $*

rem --- Git 常用全家桶 ---
"%SystemRoot%\System32\doskey.exe" g=git $*
"%SystemRoot%\System32\doskey.exe" gst=git status $*
"%SystemRoot%\System32\doskey.exe" ga=git add $*
"%SystemRoot%\System32\doskey.exe" gaa=git add --all
"%SystemRoot%\System32\doskey.exe" gc=git commit -m $*
"%SystemRoot%\System32\doskey.exe" gcm=git commit -m $*
"%SystemRoot%\System32\doskey.exe" gca=git commit --amend $*
"%SystemRoot%\System32\doskey.exe" gco=git checkout $*
"%SystemRoot%\System32\doskey.exe" gcb=git checkout -b $*
"%SystemRoot%\System32\doskey.exe" gb=git branch $*
"%SystemRoot%\System32\doskey.exe" gsw=git switch $*
"%SystemRoot%\System32\doskey.exe" glog=git log --oneline --graph --all $*
"%SystemRoot%\System32\doskey.exe" gpull=git pull $*
"%SystemRoot%\System32\doskey.exe" gps=git push $*
"%SystemRoot%\System32\doskey.exe" gd=git diff $*
"%SystemRoot%\System32\doskey.exe" gdiff=git diff $*
"%SystemRoot%\System32\doskey.exe" gundo=git reset --soft HEAD~1
"%SystemRoot%\System32\doskey.exe" lg=lazygit $*
"%SystemRoot%\System32\doskey.exe" lzg=lazygit $*
"%SystemRoot%\System32\doskey.exe" lzd=lazydocker $*

rem --- 开发工具、交互式工具与系统网络 ---
"%SystemRoot%\System32\doskey.exe" v=nvim $*
"%SystemRoot%\System32\doskey.exe" c=code $*
"%SystemRoot%\System32\doskey.exe" y=yazi $*
"%SystemRoot%\System32\doskey.exe" f=fzf $*
"%SystemRoot%\System32\doskey.exe" zi=zoxide query -i $*
"%SystemRoot%\System32\doskey.exe" ports=netstat -ano $*
"%SystemRoot%\System32\doskey.exe" myip=fastfetch -s localip
"%SystemRoot%\System32\doskey.exe" shortcuts=call "%~f0" --shortcuts
"%SystemRoot%\System32\doskey.exe" help-cmd=call "%~f0" --help

rem Replaced at installation with a trusted absolute executable path; absent tools stay disabled.
__CLINK_INIT__
if "%CMD_PROFILE_BANNER%"=="0" goto :skip_banner
__FASTFETCH_INIT__
:skip_banner
if "%CMD_PROFILE_TIPS%"=="0" goto :skip_tips
echo.
echo   💡 常用快捷指令指引 (输入 shortcuts 可查看完整手册):
echo   ├─ 目录跳转: .. (返回上级)   lt (树形目录)    y (可视化文件管理)
echo   ├─ Git 协作: gst (查看状态)  ga (添加暂存)    gc (提交)    lg (Git图形面板)
echo   └─ 实用工具: cat (代码高亮)  ports (查端口)   c (VSCode)   f (模糊搜文件)
echo.
:skip_tips
endlocal
exit /b

:show_help
echo.
echo ========================================================================
echo              Windows 现代化 CMD 常用快捷指令速查手册
echo ========================================================================
echo [1] 目录与文件浏览
echo     ..            返回上一级目录 (cd ..)
echo     ...           返回上两级目录 (cd ../..)
echo     ....          返回上三级目录 (cd ../../..)
echo     ls            显示当前目录文件 (带色彩与图标)
echo     ll            详细文件列表 (文件夹优先排在最前)
echo     la            显示全部文件 (包含隐藏文件)
echo     lt            树形目录结构 (深度2)
echo     lt3           树形目录结构 (深度3)
echo     y             启动 Yazi 终端可视化文件管理器
echo.
echo [2] 查看与检索
echo     cat ^<文件^>    使用 bat 进行语法高亮查看
echo     catp ^<文件^>   带分页的语法高亮查看
echo     grep / findstr 极速正则文本检索 (底层调用 ripgrep)
echo     f             使用 fzf 进行交互式文件模糊搜索
echo     which ^<程序^>  查找命令所在的物理路径 (where)
echo     clear         清屏 (cls)
echo.
echo [3] Git 极速工作流
echo     gst           查看仓库状态 (git status)
echo     ga ^<文件^>     添加文件到暂存区 (git add)
echo     gaa           添加所有变动到暂存区 (git add --all)
echo     gc "信息"     提交暂存区代码 (git commit -m "信息")
echo     gca           追加修改到上次提交 (git commit --amend)
echo     gco ^<分支^>    检出分支或文件 (git checkout)
echo     gcb ^<分支^>    新建分支并直接切换 (git checkout -b)
echo     gsw ^<分支^>    切换分支 (git switch)
echo     gb            查看本地分支列表 (git branch)
echo     glog          图形化分支提交历史 (git log --oneline --graph)
echo     gpull / gps   拉取 / 推送远程分支 (git pull / git push)
echo     gd / gdiff    对比差异 (git diff)
echo     gundo         撤销上一次提交但保留代码 (git reset --soft HEAD~1)
echo     lg / lzg      启动 lazygit 终端全键盘图形化 Git 面板
echo.
echo [4] 开发工具与系统网络
echo     c [路径]      使用 VS Code 打开当前目录或指定文件
echo     v [文件]      使用 Neovim 极速代码编辑器
echo     lzd           启动 lazydocker 容器图形化管理面板
echo     zi            zoxide 历史常用目录智能交互跳转
echo     ports         查看当前系统端口监听与占用 PID (netstat -ano)
echo     myip          查看本机所有物理网卡与虚拟网卡 IP (fastfetch)
echo ========================================================================
echo 提示：若不需要启动时显示欢迎指引，可设置环境变量 set CMD_PROFILE_TIPS=0
echo.
exit /b
