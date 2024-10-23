#!/bin/sh
set -eu

otp_version="27.1.2"
elixir_version="1.17.3"
force=false

usage() {
  cat<<EOF
Usage: install.sh [arguments] [options]

Arguments:

  elixir@VERSION   Install specific Elixir version
  otp@VERSION      Install specific Erlang/OTP version

Options:

  -f, --force      Forces installation even if it was previously installed
  -h, --help       Prints this help

Examples:

  # install default versions (Elixir $elixir_version, OTP $otp_version)
  sh install.sh

  sh install.sh elixir@1.16.3 otp@26.2.5.4
  sh install.sh elixir@main
  sh install.sh elixir@latest
EOF
  exit 0
}

main() {
  for arg in "$@"; do
    case "$arg" in
      elixir@*)
        elixir_version="${arg#elixir@}"
        ;;
      otp@*)
        otp_version="${arg#otp@}"
        ;;
      -h|--help)
        usage
        ;;
      -f|--force)
        force=true
        ;;
      *)
        echo "error: invalid argument $arg" >&2
        exit 1
        ;;
    esac
  done

  root_dir="$HOME/.elixir-install"
  tmp_dir="$root_dir/tmp"
  mkdir -p "$tmp_dir"

  otp_release="${otp_version%%.*}"

  case "${otp_version}" in
    master|maint*|latest)
      elixir_otp_release=27
      ;;

    *)
      elixir_otp_release=$otp_release
      ;;
  esac

  otp_dir="$root_dir/installs/otp/$otp_version"
  elixir_dir="$root_dir/installs/elixir/$elixir_version-otp-$elixir_otp_release"

  install_otp &
  install_elixir &
  wait

  if [ "${elixir_version}" = latest ]; then
    elixir_version=$(cat "${elixir_dir}/VERSION" | tr -d '\n')
    old_elixir_dir="${elixir_dir}"
    elixir_dir="${root_dir}/installs/elixir/${elixir_version}-otp-${elixir_otp_release}"
    rm -rf "${elixir_dir}"
    mv "${old_elixir_dir}" "${elixir_dir}"
  fi

  if [ "${otp_version}" = latest ]; then
    otp_version=$(cat "${otp_dir}"/releases/*/OTP_VERSION | tr -d '\n')
    old_otp_dir="${otp_dir}"
    otp_dir="$root_dir/installs/otp/${otp_version}"
    rm -rf "${otp_dir}"
    mv "${old_otp_dir}" "${otp_dir}"
  fi

  printf "checking OTP... "
  export PATH="$otp_dir/bin:$PATH"
  erl -noshell -eval 'io:put_chars(erlang:system_info(otp_release) ++ " ok\n"), halt().'

  printf "checking Elixir... "
  "$elixir_dir/bin/elixir" -e 'IO.puts(System.version() <> " ok")'

  export PATH="$elixir_dir/bin:$PATH"
cat<<EOF

Add this to your shell:

    export PATH=\$HOME/.elixir-install/installs/otp/$otp_version/bin:\$PATH
    export PATH=\$HOME/.elixir-install/installs/elixir/$elixir_version-otp-$elixir_otp_release/bin:\$PATH

EOF
}

install_otp() {
  os=$(uname -sm)
  case "$os" in
    "Darwin x86_64") target=x86_64-apple-darwin ;;
    "Darwin arm64")  target=aarch64-apple-darwin ;;
    "Linux x86_64")  target=x86_64-pc-linux ;;
    "Linux aarch64") target=aarch64-pc-linux ;;
    MINGW64*)        target=x86_64-pc-windows ;;
    *) echo "error: unsupported system $os." && exit 1 ;;
  esac

  if [ ! -d "${otp_dir}/bin" ] || [ "$force" = true ]; then
    rm -rf "${otp_dir}"

    case "$target" in
      *windows) install_otp_windows ;;
      *darwin) install_otp_darwin ;;
      *linux) install_otp_linux ;;
    esac
  fi
}

install_otp_darwin() {
  case "${otp_version}" in
    master|maint*)
      ref="${otp_version}-latest"
      ;;
    *)
      ref="OTP-${otp_version}"
      ;;
  esac

  otp_tgz="otp-${target}.tar.gz"

  if [ "${otp_version}" = "latest" ]; then
    url="https://github.com/erlef/otp_builds/releases/latest/download/$otp_tgz"
  else
    url="https://github.com/erlef/otp_builds/releases/download/$ref/$otp_tgz"
  fi

  download "$url" "$tmp_dir/$otp_tgz"

  echo "unpacking $otp_tgz to $otp_dir..."
  mkdir -p "$otp_dir"
  tar xzf "$tmp_dir/$otp_tgz" -C "$otp_dir"
  rm "$tmp_dir/$otp_tgz"
}

install_otp_linux() {
  case "${otp_version}" in
    master|maint*)
      otp_tgz="${otp_version}.tar.gz"
      ;;
    latest)
      otp_version=$(latest_otp_version)
      otp_tgz="OTP-${otp_version}.tar.gz"
      ;;
    *)
      otp_tgz="OTP-${otp_version}.tar.gz"
      ;;
  esac

  case "$target" in
    x86_64*)  arch=amd64 ;;
    aarch64*) arch=arm64 ;;
  esac

  id=$(grep '^ID=' /etc/os-release | cut -d '=' -f 2)
  if [ "${id}" != ubuntu ]; then
    echo $id is not supported
    exit 1
  fi
  case $(grep '^VERSION_ID=' /etc/os-release | cut -d '"' -f 2) in
    20*|21*)
      lts=20.04
      ;;
    22*|23*)
      lts=22.04
      ;;
    *)
      lts=24.04
      ;;
  esac

  url="https://builds.hex.pm/builds/otp/${arch}/ubuntu-${lts}/$otp_tgz"
  download "$url" "$tmp_dir/$otp_tgz"

  echo "unpacking $otp_tgz to $otp_dir..."
  mkdir -p "$otp_dir"
  tar xzf "$tmp_dir/$otp_tgz" --strip-components 1 -C "$otp_dir"
  (cd "$otp_dir" && ./Install -sasl "$PWD")
  rm "$tmp_dir/$otp_tgz"
}

install_otp_windows() {
  if [ "${otp_version}" = latest ]; then
    otp_version=$(latest_otp_version)
  fi

  otp_zip="otp_win64_$otp_version.zip"
  url="https://github.com/erlang/otp/releases/download/OTP-$otp_version/$otp_zip"
  download "$url" "$tmp_dir/$otp_zip"

  echo "unpacking $otp_zip to $otp_dir..."
  mkdir -p "$otp_dir"
  unzip -q "$tmp_dir/$otp_zip" -d "$otp_dir"
  rm "$tmp_dir/$otp_zip"
  install_vc_redist
}

install_vc_redist() {
  if [ ! -f /c/windows/system32/vcruntime140.dll ]; then
    echo "installing VC++ Redistributable..."
    (cd $otp_dir && ./vc_redist.exe /quiet /norestart)
  fi
}

latest_otp_version() {
  curl --retry 3 -fsS https://api.github.com/repos/erlef/otp_builds/releases/latest | grep '"tag_name":' | sed -n 's/.*"tag_name": "OTP-\(.*\)".*/\1/p'
}

install_elixir() {
  elixir_zip="elixir-otp-$elixir_otp_release.zip"

  if [ ! -d "${elixir_dir}/bin" ] || [ "$force" = true ]; then
    case "${elixir_version}" in
      main)
        ref="${elixir_version}-latest"
        ;;
      v[0-9]*.[0-9])
        ref="v${elixir_version}-latest"
        ;;
      *)
        ref="v${elixir_version}"
        ;;
    esac

    if [ "${elixir_version}" = latest ]; then
      url="https://github.com/elixir-lang/elixir/releases/latest/download/$elixir_zip"
    else
      url="https://github.com/elixir-lang/elixir/releases/download/$ref/$elixir_zip"
    fi

    download "$url" "$tmp_dir/$elixir_zip"

    echo "unpacking $elixir_zip to $elixir_dir..."
    rm -rf "${elixir_dir}"
    mkdir -p "${elixir_dir}"
    unzip -q "${tmp_dir}/${elixir_zip}" -d "${elixir_dir}"
    rm "${tmp_dir}/${elixir_zip}"
  fi
}

download() {
  url="$1"
  output="$2"
  echo "downloading $url"
  curl --retry 3 -fsSLo "$output" "$url"
}

main "$@"
