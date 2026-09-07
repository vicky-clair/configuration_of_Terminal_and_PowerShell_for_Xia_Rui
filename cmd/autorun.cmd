@echo off
rem ===========================================================================
rem Windows 命令提示符 (cmd.exe) 自动化启动挂载脚本
rem 实现 UTF-8 (65001) 编码修复、现代 CLI 别名 (Doskey) 与 Clink/Starship 注入
rem ===========================================================================

rem 1. 设置控制台代码页为 UTF-8 (65001)，解决中文与特殊字符乱码
chcp 65001 >nul 2>&1

rem 2. 通过 Doskey 注入现代化 CLI 快捷别名 (eza / bat / ripgrep / git)
doskey ls=eza --icons $*
doskey ll=eza -l --icons --group-directories-first $*
doskey la=eza -la --icons --group-directories-first $*
doskey l=eza -l --icons $*

doskey cat=bat --paging=never $*
doskey clear=cls
doskey grep=rg $*
doskey findstr=rg $*
doskey which=where $*

doskey g=git $*
doskey gst=git status $*
doskey gco=git checkout $*
doskey gb=git branch $*
doskey glog=git log --oneline --graph --all $*
doskey gpull=git pull $*
doskey gps=git push $*
doskey gd=git diff $*
doskey lg=lazygit $*
doskey lzg=lazygit $*
doskey lzd=lazydocker $*

rem 3. Inject Clink readline enhancement and Starship prompt if available
if exist "C:\Program Files (x86)\clink\clink.bat" (
    call "C:\Program Files (x86)\clink\clink.bat" inject --autorun --quiet
) else if exist "%LOCALAPPDATA%\clink\clink.bat" (
    call "%LOCALAPPDATA%\clink\clink.bat" inject --autorun --quiet
) else if exist "%USERPROFILE%\scoop\apps\clink\current\clink.bat" (
    call "%USERPROFILE%\scoop\apps\clink\current\clink.bat" inject --autorun --quiet
)

rem 4. Fastfetch ASCII 硬件横幅与现代化功能就绪提示
echo %CMDCMDLINE% | findstr /i /c:" /c" >nul
if not errorlevel 1 goto :skip_ui
if "%CMD_PROFILE_BANNER%"=="0" goto :skip_banner
if exist "%USERPROFILE%\.config\fastfetch\config.jsonc" (
    fastfetch -c "%USERPROFILE%\.config\fastfetch\config.jsonc" 2>nul
) else (
    fastfetch 2>nul
)
:skip_banner
if "%CMD_PROFILE_TIPS%"=="0" goto :skip_ui
where yazi >nul 2>&1
if not errorlevel 1 echo   ✓ yazi 文件管理器已集成 (命令: yazi)
where eza >nul 2>&1
if not errorlevel 1 echo   ✓ eza 现代化 ls 已启用 (别名: ls, ll, la)
where bat >nul 2>&1
if not errorlevel 1 echo   ✓ bat 代码高亮已启用 (别名: cat)
where rg >nul 2>&1
if not errorlevel 1 echo   ✓ ripgrep 极速搜索已启用 (别名: grep)
where git >nul 2>&1
if not errorlevel 1 echo   ✓ Git 快捷别名已加载 (g, gst, gco, gb, glog)
where lazygit >nul 2>&1
if not errorlevel 1 echo   ✓ lazygit 终端Git管家已启用 (命令: lg, lzg)
where lazydocker >nul 2>&1
if not errorlevel 1 echo   ✓ lazydocker 容器管家已启用 (命令: lzd)
where starship >nul 2>&1
if not errorlevel 1 echo   ✓ Starship 赛博朋克提示符与 Clink 已加载
where fastfetch >nul 2>&1
if not errorlevel 1 echo   ✓ fastfetch 系统信息工具已启动
echo.
:skip_ui
