{ lib, stdenv, autoPatchelfHook, fetchzip, makeWrapper, dpkg, requireFile }:

let
  pkgs = import <nixpkgs> { };
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  autoPatchelfHook = pkgs.autoPatchelfHook;
  fetchzip = pkgs.fetchzip;
  makeWrapper = pkgs.makeWrapper;
  dpkg = pkgs.dpkg;
  requireFile = pkgs.requireFile;
  version = "0.11.12";
  workDir = "/var/lib/kolide-k2";

  system = if stdenv.isLinux then
    "linux"
  else if stdenv.isDarwin then
    "darwin"
  else
    throw "kolide-launcher-k2 is not available for this platform";

  srcs = {
    deb = requireFile rec {
      name = "kolide-launcher.deb";
      url = "https://COMPANY-URL-TO-DEB-PACKAGE";
      message = ''
        This Nix expression requires that ${name} already be part of the store. To
        obtain it you need to

        - Download the deb file from ${url}
        - Add the file to the Nix store using:

          nix-store --add-fixed sha256 ${name}
      '';
      sha256 = "sha256-jc9bQd+sU4jW87V4lJalq8h6aIXT7fwH6MXfd4/Zw6c=";
    };
    bin = fetchzip {
      url =
        "https://github.com/kolide/launcher/releases/download/v${version}/launcher_v${version}.zip";
      sha256 = "1a1icllds1cariinkb5sbrfrm4nrykrkmb2rafrrc72sykrqkw6m";
      stripRoot = false;
    };
  };

in stdenv.mkDerivation {
  pname = "kolide-launcher-k2";
  inherit version;

  src = srcs.deb;

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = "dpkg-deb -x $src .";

  postPatch = ''
    substituteInPlace lib/systemd/system/launcher.kolide-k2.service \
      --replace "/usr/local/kolide-k2/bin" "$out/bin"
    substituteInPlace lib/systemd/system/launcher.kolide-k2.service \
      --replace "/etc" "$out/etc"

    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/usr/local/kolide-k2/bin" "${workDir}/bin"
    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/etc" "$out/etc"
    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/var/kolide-k2" "${workDir}"
  '';

  installPhase = ''
    mkdir -p $out $out/bin $out/wbin $out/etc $out/lib $out/share

    cp -r ${srcs.bin}/${system}/* $out/wbin/
    cp -r etc/* $out/etc/
    cp -r lib/* $out/lib/
    cp -r usr/share/* $out/share/

    cat > $out/bin/launcher <<EOF
    #! ${stdenv.shell} -e
    mkdir -p "${workDir}/bin"
    for i in $out/wbin/*; do
      [ -f "${workDir}/bin/\$(basename "\$i")" ] || cp "\$i" "${workDir}/bin/"
    done
    exec ${workDir}/bin/launcher "\$@"
    EOF
    chmod +x $out/bin/launcher
  '';

  meta = with lib; {
    homepage = "https://www.kolide.com/launcher";
    description = "Kolide Launcher for Osquery";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
