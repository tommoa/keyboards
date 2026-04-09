{
  lib,
  stdenv,
  gcc-arm-embedded,
  git,
  qmk,
  qmk-firmware-source,
  src,
}:

let
  qmk-with-keymap-src = stdenv.mkDerivation {
    pname = "vortex-core-qmk-src";
    version = "unstable";
    inherit src;
    phases = [ "installPhase" ];

    installPhase = ''
            mkdir "$out"
            cp -r ${qmk-firmware-source}/. "$out"
            chmod -R u+w "$out"
            cat > "$out/version.h" <<'EOF'
      #pragma once

      #define QMK_VERSION "nix"
      #define QMK_BUILDDATE "unknown"
      EOF
            mkdir -p "$out/keyboards/vortex/keymaps/tommoa"
            cp -r "$src"/. "$out/keyboards/vortex/keymaps/tommoa"
            chmod -R a-w "$out"
    '';
  };
in
stdenv.mkDerivation {
  pname = "vortex-core-qmk";
  version = "unstable";
  src = qmk-with-keymap-src;

  nativeBuildInputs = [
    gcc-arm-embedded
    git
    qmk
  ];

  buildPhase = ''
    runHook preBuild
    unset NIX_CFLAGS_COMPILE_FOR_TARGET
    export SKIP_GIT=true
    export SKIP_VERSION=true
    make EXTRAFLAGS="-Wno-error -Wno-array-bounds -Wno-stringop-overread -Wno-header-guard -Wno-deprecated" vortex/core:tommoa
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r .build/. "$out"
    find . -maxdepth 1 -type f \( -name "*.bin" -o -name "*.hex" \) -exec cp {} "$out" \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "QMK firmware build for the Vortex Core";
    homepage = "https://github.com/pok3r-custom/qmk_pok3r";
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
  };
}
