@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PARENT_DIR=%SCRIPT_DIR%.."

set "BASH_EXE="
if defined GIT_BASH if exist "%GIT_BASH%" set "BASH_EXE=%GIT_BASH%"
if not defined BASH_EXE if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_EXE if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LocalAppData%\Programs\Git\bin\bash.exe"
if not defined BASH_EXE for /f "delims=" %%i in ('where bash.exe 2^>nul') do if not defined BASH_EXE set "BASH_EXE=%%i"

if not defined BASH_EXE (
  echo ERROR: Could not find bash.exe. Install Git for Windows or set GIT_BASH to bash.exe path. 1>&2
  exit /b 1
)

set "BASH_SCRIPT=%PARENT_DIR%\run-feature-flow.sh"
set "BASH_SCRIPT=%BASH_SCRIPT:\=/%"

"%BASH_EXE%" "%BASH_SCRIPT%" %*
set "EXIT_CODE=%ERRORLEVEL%"
exit /b %EXIT_CODE%
