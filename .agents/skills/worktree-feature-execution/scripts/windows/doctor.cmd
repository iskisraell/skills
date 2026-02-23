@echo off
setlocal

echo [doctor] shell=%ComSpec%

where git.exe >nul 2>nul
if errorlevel 1 (
  echo [doctor] git: not found in PATH
) else (
  for /f "delims=" %%i in ('where git.exe') do (
    echo [doctor] git: %%i
    goto :git_done
  )
)
:git_done

where gh.exe >nul 2>nul
if errorlevel 1 (
  echo [doctor] gh: not found in PATH
) else (
  for /f "delims=" %%i in ('where gh.exe') do (
    echo [doctor] gh: %%i
    goto :gh_done
  )
)
:gh_done

set "BASH_HINT="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_HINT=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH_HINT if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH_HINT=%LocalAppData%\Programs\Git\bin\bash.exe"

if defined BASH_HINT (
  echo [doctor] bash: %BASH_HINT%
) else (
  where bash.exe >nul 2>nul
  if errorlevel 1 (
    echo [doctor] bash: not found in PATH
  ) else (
    for /f "delims=" %%i in ('where bash.exe') do (
      echo [doctor] bash: %%i
      goto :bash_done
    )
  )
)
:bash_done

echo [doctor] recommendations:
echo - Use Git Bash for skill scripts.
echo - Ensure both git.exe and gh.exe are available in PATH.
echo - Set GIT_BASH to explicit bash.exe path for wrappers.

exit /b 0
