{
  lib,
  stdenvNoCC,
  src,
}:

stdenvNoCC.mkDerivation {
  pname = "vortex-core-unlocked-fw";
  version = "unstable";
  inherit src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp "$src/disassemble/core/builtin_core/firmware_builtin_core.bin" "$out/"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Unlocked stock firmware image for the Vortex Core";
    homepage = "https://github.com/pok3r-custom/pok3r_re_firmware";
    license = licenses.gpl2Plus;
    platforms = platforms.all;
  };
}
