@echo off
setlocal EnableDelayedExpansion

set otp_version=27.1
set elixir_version=1.17.3

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

set root_dir=%USERPROFILE%\.elixir-install
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
echo Add this to your powershell:
echo.
echo    $env:PATH = "$env:USERPROFILE\.elixir-install\installs\otp\%otp_version%\bin;$env:PATH"
echo    $env:PATH = "$env:USERPROFILE\.elixir-install\installs\elixir\%elixir_version%-otp-%otp_release%\bin;$env:PATH"
echo.
echo Or cmd.exe:
echo.
echo    set PATH=%%USERPROFILE%%\.elixir-install\installs\otp\%otp_version%\bin;%%PATH%%
echo    set PATH=%%USERPROFILE%%\.elixir-install\installs\elixir\%elixir_version%-otp-%otp_release%\bin;%%PATH%%
echo.
goto :eof

:install_otp
set otp_zip=otp_win64_%otp_version%.zip

if not exist "%otp_dir%\bin" (
    if not exist "%tmp_dir%\%otp_zip%" (
      set otp_url=https://github.com/erlang/otp/releases/download/OTP-%otp_version%/%otp_zip%
      echo downloading !otp_url!...
      curl -fsSLo %tmp_dir%\%otp_zip% !otp_url!
    )
    powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%otp_zip% -DestinationPath %otp_dir%"
    del /f /q %tmp_dir%\%otp_zip%
    cd /d "%otp_dir%"

    REG QUERY "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
    IF %ERRORLEVEL% NEQ 0 (
        echo Installing VC++ Redistributable...
        .\vc_redist.exe /quiet /norestart

        REG QUERY "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" >nul 2>&1
        IF %ERRORLEVEL% EQU 0 (
            echo Installation successful.
            del %file%
            exit /b 0
        ) ELSE (
            echo Installation failed.
            exit /b 1
        )
    )

)
goto :eof

:install_elixir
set elixir_zip=elixir-%elixir_version%-otp-%otp_release%.zip

if not exist "%elixir_dir%\bin" (
    if not exist "%tmp_dir%\%elixir_zip%" (
      set elixir_url=https://github.com/elixir-lang/elixir/releases/download/v%elixir_version%/elixir-otp-%otp_release%.zip
      echo downloading !elixir_url!...
      curl -fsSLo "%tmp_dir%\%elixir_zip%" !elixir_url!
    )
    powershell -Command "Expand-Archive -LiteralPath %tmp_dir%\%elixir_zip% -DestinationPath %elixir_dir%"
    del /f /q %tmp_dir%\%elixir_zip%
)
goto :eof
