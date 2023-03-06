{ stdenv, fetchurl }:
let
  rev = "1.0";
  build = "1921";
  sha256 = "189scj79gnv8gdk3pa2c4qca0sp3n8zvdfaf3lsspkwbabk21048";
in stdenv.mkDerivation {
  src = fetchurl {
    url = "https://s3-eu-west-1.amazonaws.com/uswitch-tools/u/${build}/linux/u";
    sha256 = sha256;
  };

  name = "u-${rev}.${build}";
  buildInputs = [ ];

  doConfigure = false;
  doBuild = false;
  dontStrip = true;
  dontPatchELF = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir -p ./u/usr/bin
    cp $src ./u/usr/bin/u
    chmod 0755 ./u/usr/bin/u

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mv ./u/* $out/

    runHook postInstall
  '';

}
