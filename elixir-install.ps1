$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Main {
    param([string[]]$argv)

    $otpVersion = "27.0.1"
    $elixirVersion = "1.17.2"

    foreach ($arg in $argv) {
        if ($arg -like "elixir@*") {
            $elixirVersion = $arg -replace "elixir@", ""
        }
        elseif ($arg -like "otp@*") {
            $otpVersion = $arg -replace "otp@", ""
        }
        else {
            Write-Error "error: invalid argument $arg"
            exit 1
        }
    }

    $rootDir = "$env:USERPROFILE\.elixir-install"
    $tmpDir = "$rootDir\tmp"
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

    $otpRelease = $otpVersion.Split('.')[0]
    $otpDir = "$rootDir\installs\otp\$otpVersion"

    $elixirDir = "$rootDir\installs\elixir\$elixirVersion-otp-$otpRelease"

    InstallOTP
    Write-Host "checking OTP... " -NoNewline
    $env:PATH = "$otpDir\bin;$env:PATH"
    Write-Host (erl -noshell -eval "io:put_chars(erlang:system_info(otp_release)), halt()." | Out-String) -NoNewLine
    InstallElixir
    Write-Host "checking Elixir... " -NoNewline
    Write-Host (elixir -e "IO.puts System.version()" | Out-String) -NoNewLine
    Write-Host "`nAdd this to your PowerShell profile:`n"
    Write-Host "    `$env:PATH = `"`$env:USERPROFILE\.elixir-install\installs\otp\$otpVersion\bin;`$env:PATH`""
    Write-Host "    `$env:PATH = `"`$env:USERPROFILE\.elixir-install\installs\elixir\$elixirVersion-otp-$otpRelease\bin;`$env:PATH`"`n"
}

function InstallOTP {
    if (-not (Test-Path "$otpDir\bin")) {
        EnsureVCRedist
        $otpZip = "OTP-$otpVersion-windows-amd64.zip"

        if (-not (Test-Path "$tmpDir\$otpZip")) {
            $url = "https://github.com/elixir-install/otp_builds/releases/download/OTP-$otpVersion/$otpZip"
            Write-Host "downloading $url"
            Invoke-WebRequest -Uri $url -OutFile "$tmpDir\$otpZip" -ErrorAction Stop
        }

        Write-Host "unpacking $otpZip to $otpDir..."
        New-Item -ItemType Directory -Force -Path $otpDir | Out-Null
        Expand-Archive -Path "$tmpDir\$otpZip" -DestinationPath $otpDir
        Start-Process -FilePath "$otpDir\Install.exe" -ArgumentList "-sasl" -Wait
        Remove-Item "$tmpDir\$otpZip"
    }
}

function EnsureVCRedist {
    if (Test-Path "C:\Windows\System32\vcruntime140.dll") {
        return
    }

    $url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
    $file = "vc_redist.x64.exe"

    Write-Host "downloading VC++ Redistributable $url..."
    Invoke-WebRequest -Uri $url -OutFile $file
    Write-Host "installing VC++ Redistributable $url..."
    Start-Process -FilePath ".\$file" -ArgumentList "/quiet", "/norestart" -Wait
}

function InstallElixir {
    $elixirZip = "elixir-otp-$otpRelease.zip"

    if (-not (Test-Path "$elixirDir\bin")) {
        if (-not (Test-Path "$tmpDir\$elixirZip")) {
            $url = "https://github.com/elixir-lang/elixir/releases/download/v$elixirVersion/$elixirZip"
            Write-Host "downloading $url"
            Invoke-WebRequest -Uri $url -OutFile "$tmpDir\$elixirZip" -ErrorAction Stop
        }
        Write-Host "unpacking $elixirZip to $elixirDir..."
        New-Item -ItemType Directory -Force -Path $elixirDir | Out-Null
        Expand-Archive -Path "$tmpDir\$elixirZip" -DestinationPath $elixirDir
        Remove-Item "$tmpDir\$elixirZip"
    }
}

Main $args
