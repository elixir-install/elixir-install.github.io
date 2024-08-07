@echo off
setlocal EnableDelayedExpansion

set otp_version=27.0.1
set elixir_version=1.17.2

for %%i in (%*) do (
    set arg=%%i
    if "!arg:~0,7!"=="elixir@" (
      set "elixir_version=!arg:~7!"
    ) else if "!arg:~0,4!"=="otp@" (
      set "otp_version=!arg:~4!"
    ) else (
      echo error: unknown argument !arg!
      exit /b 1
    )
)

set root_dir=%LOCALAPPDATA%\elixir-install
set tmp_dir=%root_dir%\Cache
mkdir %tmp_dir% 2>nul

for /f "delims=." %%a in ("%otp_version%") do set otp_release=%%a
set otp_dir=%root_dir%\installs\otp\%otp_version%
set elixir_dir=%root_dir%\installs\elixir\%elixir_version%-otp-%otp_release%

call :main
goto :eof

:main
call :install_otp
set /p="checking OTP..."<nul
set PATH=%otp_dir%\bin;%PATH%
%otp_dir%\bin\erl.exe -noshell -eval "io:put_chars(erlang:system_info(otp_release)), halt()."
echo  ok
call :install_elixir
set /p="checking Elixir... "<nul
call %elixir_dir%\bin\elixir.bat -e "IO.write System.version()"
echo  ok
echo.
echo Add this to your shell:
echo.
echo    set PATH=%%LOCALAPPDATA%%\elixir-install\installs\otp\%otp_version%\bin;%%PATH%%
echo    set PATH=%%LOCALAPPDATA%%\elixir-install\installs\elixir\%elixir_version%-otp-%otp_release%\bin;%%PATH%%
goto :eof

:install_otp
set otp_zip=OTP-%otp_version%-windows-amd64.zip

if not exist "%otp_dir%\bin" (
    if not exist "%tmp_dir%\%otp_zip%" (
      set otp_url=https://github.com/elixir-install/otp_builds/releases/download/OTP-%otp_version%/%otp_zip%
      echo downloading !otp_url!...
      curl --fail -L -o %tmp_dir%\%otp_zip% !otp_url!
    )
    powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%otp_zip% -DestinationPath %otp_dir%"
    del /f /q %tmp_dir%\%otp_zip%
    cd %otp_dir%
    .\Install.exe -sasl
)
goto :eof

:install_elixir
set elixir_zip=elixir-%elixir_version%-otp-%otp_release%.zip

if not exist "%elixir_dir%\bin" (
    if not exist "%tmp_dir%\%elixir_zip%" (
      set elixir_url=https://github.com/elixir-lang/elixir/releases/download/v%elixir_version%/elixir-otp-%otp_release%.zip
      echo downloading !elixir_url!...
      curl --fail -L -o "%tmp_dir%\%elixir_zip%" !elixir_url!
    )
    powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%elixir_zip% -DestinationPath %elixir_dir%"
    del /f /q %tmp_dir%\%elixir_zip%
)
goto :eof
