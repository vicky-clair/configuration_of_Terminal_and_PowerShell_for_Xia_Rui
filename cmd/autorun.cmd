@echo off
setlocal EnableExtensions DisableDelayedExpansion
rem Strip quotes before comparing CMDCMDLINE, never echo untrusted command text into a pipe.
set "_terminal_line=%CMDCMDLINE:"=%"
if not "%_terminal_line: /c=%"=="%_terminal_line%" exit /b
if not "%_terminal_line: /C=%"=="%_terminal_line%" exit /b
if defined TERMINAL_CMD_ACTIVE exit /b
set "TERMINAL_CMD_ACTIVE=1"
rem 1. 设置控制台代码页为 UTF-8 (65001)，解决中文与特殊字符乱码
"%SystemRoot%\System32\chcp.com" 65001 >nul 2>&1

rem 2. 通过 Doskey 注入现代化 CLI 快捷别名 (eza / bat / ripgrep / git)
"%SystemRoot%\System32\doskey.exe" ls=eza --icons $*
"%SystemRoot%\System32\doskey.exe" ll=eza -l --icons --group-directories-first $*
"%SystemRoot%\System32\doskey.exe" la=eza -la --icons --group-directories-first $*
"%SystemRoot%\System32\doskey.exe" l=eza -l --icons $*

"%SystemRoot%\System32\doskey.exe" cat=bat --paging=never $*
"%SystemRoot%\System32\doskey.exe" clear=cls
"%SystemRoot%\System32\doskey.exe" grep=rg $*
"%SystemRoot%\System32\doskey.exe" findstr=rg $*
"%SystemRoot%\System32\doskey.exe" which=where $*

"%SystemRoot%\System32\doskey.exe" g=git $*
"%SystemRoot%\System32\doskey.exe" gst=git status $*
"%SystemRoot%\System32\doskey.exe" gco=git checkout $*
"%SystemRoot%\System32\doskey.exe" gb=git branch $*
"%SystemRoot%\System32\doskey.exe" glog=git log --oneline --graph --all $*
"%SystemRoot%\System32\doskey.exe" gpull=git pull $*
"%SystemRoot%\System32\doskey.exe" gps=git push $*
"%SystemRoot%\System32\doskey.exe" gd=git diff $*
"%SystemRoot%\System32\doskey.exe" lg=lazygit $*
"%SystemRoot%\System32\doskey.exe" lzg=lazygit $*
"%SystemRoot%\System32\doskey.exe" lzd=lazydocker $*


rem Replaced at installation with a trusted absolute executable path; absent tools stay disabled.
__CLINK_INIT__
if not "%CMD_PROFILE_BANNER%"=="1" goto :skip_banner
__FASTFETCH_INIT__
:skip_banner
if "%CMD_PROFILE_TIPS%"=="1" echo Terminal shortcuts: ll, la, gst, lg, lzd
endlocal
