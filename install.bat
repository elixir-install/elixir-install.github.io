@echo off
setlocal EnableDelayedExpansion

set "otp_version=27.1.2"
set "elixir_version=1.17.3"
set "force=false"
goto :start

:usage
echo Usage: install.bat [arguments] [options]
echo.
echo Arguments:
echo.
echo   elixir@VERSION   Install specific version of Elixir
echo   otp@VERSION      Install specific version of Erlang/OTP
echo.
echo Options:
echo.
echo   -f, --force      Forces installation even if it was previously installed
echo   -h, --help       Prints this help
echo.
echo Examples:
echo.
echo   # install default versions (Elixir %elixir_version%, OTP %otp_version%)
echo   install.bat
echo.
echo   install.bat elixir@1.16.3 otp@26.2.5.4
echo   install.bat elixir@main
echo   install.bat elixir@latest
echo.
goto :eof

:start
for %%i in (%*) do (
  set arg=%%i

  if "!arg:~0,7!" == "elixir@" (
    set "elixir_version=!arg:~7!"
  ) else if "!arg:~0,4!" == "otp@" (
    set "otp_version=!arg:~4!"
  ) else if "!arg!" == "-f" (
    set "force=true"
  ) else if "!arg!" == "--force" (
    set "force=true"
  ) else if "!arg!" == "-h" (
    call :usage
    exit /b 0
  ) else if "!arg!" == "--help" (
    call :usage
    exit /b 0
  ) else (
    echo error: unknown argument !arg!
    exit /b 1
  )
)

set "root_dir=%USERPROFILE%\.elixir-install"
set "tmp_dir=%root_dir%\Cache"
mkdir %tmp_dir% 2>nul

for /f "delims=." %%a in ("%otp_version%") do set otp_release=%%a
set "otp_dir=%root_dir%\installs\otp\%otp_version%"
set "elixir_dir=%root_dir%\installs\elixir\%elixir_version%-otp-%otp_release%"

call :main
goto :eof

:main
call :install_otp
if %errorlevel% neq 0 exit /b 1

set /p="checking OTP... "<nul
set "PATH=%otp_dir%\bin;%PATH%"
%otp_dir%\bin\erl.exe -noshell -eval "io:put_chars(erlang:system_info(otp_release) ++ "" ok\n""), halt()."

call :install_elixir
if %errorlevel% neq 0 exit /b 1

set /p="checking Elixir... "<nul
cmd /c %elixir_dir%\bin\elixir.bat -e "IO.puts ""#{System.version()} ok"""

if "%elixir_version%" == "latest" (
  set /p elixir_version=<%elixir_dir%\VERSION

  rem parens and redirection < above confuses the parser so let's add a noop.
  echo. >nul
)

echo.
echo If you are using powershell, run this (or add to your $PROFILE):
echo.
echo    $env:PATH = "$env:USERPROFILE\.elixir-install\installs\otp\%otp_version%\bin;$env:PATH"
echo    $env:PATH = "$env:USERPROFILE\.elixir-install\installs\elixir\%elixir_version%-otp-%otp_release%\bin;$env:PATH"
echo.
echo If you are using cmd, run this:
echo.
echo    set PATH=%%USERPROFILE%%\.elixir-install\installs\otp\%otp_version%\bin;%%PATH%%
echo    set PATH=%%USERPROFILE%%\.elixir-install\installs\elixir\%elixir_version%-otp-%otp_release%\bin;%%PATH%%
echo.
goto :eof

:install_otp
set otp_zip=otp_win64_%otp_version%.zip

if "%force%" == "true" (
  if exist "%otp_dir%" (
    rmdir /s /q "%otp_dir%"
  )
)

if not exist "%otp_dir%\bin" (
  if exist "%otp_dir%" (
    rmdir /s /q "%otp_dir%"
  )

  set otp_url=https://github.com/erlang/otp/releases/download/OTP-%otp_version%/%otp_zip%
  echo downloading !otp_url!...
  curl.exe -fsSLo %tmp_dir%\%otp_zip% !otp_url!
  if %errorlevel% neq 0 exit /b 1

  powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%otp_zip% -DestinationPath %otp_dir%"
  del /f /q %tmp_dir%\%otp_zip%
  cd /d "%otp_dir%"

  if not exist "c:\windows\system32\vcruntime140.dll" (
    echo Installing VC++ Redistributable...
    .\vc_redist.exe /quiet /norestart
  )
)
exit /b 0
goto :eof

:install_elixir
set elixir_zip=elixir-%elixir_version%-otp-%otp_release%.zip

if "%force%" == "true" (
  if exist "%elixir_dir%" (
    rmdir /s /q "%elixir_dir%"
  )
)

if not exist "%elixir_dir%\bin" (
  if "%elixir_version%" == "latest" (
    set elixir_url=https://github.com/elixir-lang/elixir/releases/latest/download/elixir-otp-%otp_release%.zip
  ) else (
    set elixir_url=https://github.com/elixir-lang/elixir/releases/download/v%elixir_version%/elixir-otp-%otp_release%.zip
  )
  echo downloading !elixir_url!...
  curl.exe -fsSLo "%tmp_dir%\%elixir_zip%" !elixir_url!
  if %errorlevel% neq 0 exit /b 1

  powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%elixir_zip% -DestinationPath %elixir_dir%"
  del /f /q %tmp_dir%\%elixir_zip%
)
goto :eof
