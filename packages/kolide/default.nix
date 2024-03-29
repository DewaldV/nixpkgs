{ lib, stdenv, autoPatchelfHook, fetchzip, makeWrapper, dpkg, requireFile }:

let
  version = "1.0.3";
  osqueryVersion = "5.7.0";
  workDir = "/var/lib/kolide-k2";

  system = if stdenv.isLinux then
    "linux"
  else if stdenv.isDarwin then
    "darwin"
  else
    throw "kolide-launcher-k2 is not available for this platform";

  src = requireFile rec {
    name = "kolide-launcher.deb";
    url = "https://COMPANY-URL-TO-DEB-PACKAGE";
    message = ''
      This Nix expression requires that ${name} already be part of the store. To
      obtain it you need to

      - Download the deb file from ${url}
      - Add the file to the Nix store using:

        nix-store --add-fixed sha256 ${name}
    '';
    sha256 = "sha256-ZYPGp3g7BdppF1HhUUxKDkr7gJg5Tb4cktUT/eiOwpE=";
  };

in stdenv.mkDerivation {
  pname = "kolide-launcher-k2";
  inherit version;
  inherit src;

  nativeBuildInputs = [ autoPatchelfHook dpkg makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  unpackPhase = "dpkg-deb -x $src .";

  postPatch = ''
    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/usr/local/kolide-k2/bin" "${workDir}/bin"
    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/etc" "$out/etc"
    substituteInPlace etc/kolide-k2/launcher.flags \
      --replace "/var/kolide-k2" "${workDir}"
  '';

  installPhase = ''
    mkdir -p $out $out/bin $out/wbin $out/etc $out/lib $out/share

    cp -r etc/* $out/etc/
    cp -r lib/* $out/lib/
    cp -r usr/local/kolide-k2/bin/* $out/wbin/
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
