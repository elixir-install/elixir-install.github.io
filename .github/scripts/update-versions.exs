#!/usr/bin/env elixir

defmodule Main do
  def main([]) do
    IO.puts("Usage: update-versions.exs elixir@x.y.z otp@x.y.z")
    System.halt(1)
  end

  def main(argv) do
    Enum.each(argv, fn
      "elixir@" <> vsn ->
        # replace_file("elixir-install", [
        #   {~r/elixir_version="(\d.*?)"/, ~s|elixir_version="#{vsn}"|}
        # ])

        replace_file("install.sh", [
          {~r/elixir_version="(\d.*?)"/, ~s|elixir_version="#{vsn}"|}
        ])

        # replace_file("elixir-install.bat", [
        #   {~r/elixir_version=(\d.*?)\n/, ~s|elixir_version=#{vsn}\n|}
        # ])

        replace_file("install.bat", [
          {~r/elixir_version=(\d.*?)\n/, ~s|elixir_version=#{vsn}\n|}
        ])

        # replace_file("elixir-install.ps1", [
        #   {~r/\$elixirVersion = "(\d.*?)"/, ~s|$elixirVersion = "#{vsn}"|}
        # ])

        replace_file("install.ps1", [
          {~r/\$elixirVersion = "(\d.*?)"/, ~s|$elixirVersion = "#{vsn}"|}
        ])

        replace_file("index.html", [
          {~r/elixir@(.*?) /, "elixir@#{vsn} "},
          {~r/installs\/elixir\/(.*?)-otp/, "installs/elixir/#{vsn}-otp"},
          {~r/installs\\elixir\\(.*?)-otp/, fn _ -> "installs\\elixir\\#{vsn}-otp" end}
        ])

        replace_file(".github/workflows/test.yml", [
          {~r/elixir@(.*?) /, "elixir@#{vsn} "},
          {~r/installs\/elixir\/(.*?)-otp/, "installs/elixir/#{vsn}-otp"},
          {~r/installs\\elixir\\(.*?)-otp/, fn _ -> "installs\\elixir\\#{vsn}-otp" end}
        ])

      "otp@" <> vsn ->
        # replace_file("elixir-install", [
        #   {~r/otp_version="(\d.*?)"/, ~s|otp_version="#{vsn}"|}
        # ])

        replace_file("install.sh", [
          {~r/otp_version="(\d.*?)"/, ~s|otp_version="#{vsn}"|}
        ])

        # replace_file("elixir-install.bat", [
        #   {~r/otp_version=(\d.*?)\n/, ~s|otp_version=#{vsn}\n|}
        # ])

        replace_file("install.bat", [
          {~r/otp_version=(\d.*?)\n/, ~s|otp_version=#{vsn}\n|}
        ])

        # replace_file("elixir-install.ps1", [
        #   {~r/\$otpVersion = "(.*?)"/, ~s|$otpVersion = "#{vsn}"|}
        # ])

        replace_file("install.ps1", [
          {~r/\$otpVersion = "(.*?)"/, ~s|$otpVersion = "#{vsn}"|}
        ])

        [otp_release | _] = String.split(vsn, ".")

        replace_file("index.html", [
          {~r/otp@(.*?)\n/, "otp@#{vsn}\n"},
          {~r/-otp-(\d+)/, "-otp-#{otp_release}"},
          {~r/installs\/otp\/(.*?)\/bin/, "installs/otp/#{vsn}/bin"},
          {~r/installs\\otp\\(.*?)\\bin/, fn _ -> "installs\\otp\\#{vsn}\\bin" end}
        ])

        replace_file(".github/workflows/test.yml", [
          {~r/otp@(.*?)\n/, "otp@#{vsn}\n"},
          {~r/-otp-(\d+)/, "-otp-#{otp_release}"},
          {~r/installs\/otp\/(.*?)\/bin/, "installs/otp/#{vsn}/bin"},
          {~r/installs\\otp\\(.*?)\\bin/, fn _ -> "installs\\otp\\#{vsn}\\bin" end}
        ])
    end)
  end

  defp replace_file(path, pairs) when is_list(pairs) do
    data =
      Enum.reduce(pairs, File.read!(path), fn {pattern, replacement}, data ->
        String.replace(data, pattern, replacement)
      end)

    File.write!(path, data)
  end
end

Main.main(System.argv())
