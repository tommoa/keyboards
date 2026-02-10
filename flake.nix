{
  description = "Tools to build and flash my custom keyboard";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus/master";
    qmk-nix-utils = {
      url = "github:tommoa/qmk-nix-utils";
      inputs.nixpkgsUnstable.follows = "nixpkgs";
    };
    qmk-firmware-source = {
      type = "git";
      url = "https://github.com/qmk/qmk_firmware";
      flake = false;
      submodules = true;
    };
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils-plus,
      qmk-nix-utils,
      qmk-firmware-source,
      zmk-nix,
    }:
    flake-utils-plus.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        qmk-utils-factory = builtins.getAttr system qmk-nix-utils.utils-factory;

        preonic-qmk = qmk-utils-factory {
          inherit qmk-firmware-source;
          src = ./qmk/preonic;
          keyboard-name = "preonic";
          keyboard-variant = "rev3_drop";
          keymap-name = "tommoa";
          type = "keymap";
          flash-script = ''
            ${pkgs.dfu-util}/bin/dfu-util -a 0 -s 0x08000000:leave -w -D $BIN_FILE
          '';
        };

        zmk-flasher = pkgs.writeShellScriptBin "zmk-flash" ''
          set -euo pipefail
          ${pkgs.dfu-util}/bin/dfu-util -a 0 -s 0x08000000:leave -w -D "${preonic-zmk}/zmk.bin"
        '';

        preonic-zmk = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "preonic-zmk";
          src = nixpkgs.lib.sourceFilesBySuffices ./zmk [
            ".conf"
            ".keymap"
            ".yml"
          ];
          board = "preonic";
          config = "preonic/config";
          zephyrDepsHash = "sha256-mUJpGWlU+rGbcWtKs/SuombCJ3RcIDMTiuMicwLX1D4=";
          # The Preonic rev3 Drop uses STM32 DFU, not UF2 bootloader,
          # so the build produces .bin/.hex instead of .uf2.
          installPhase = ''
            runHook preInstall
            mkdir $out
            cp zephyr/zmk.bin $out/
            runHook postInstall
          '';
          meta = {
            description = "ZMK firmware for Preonic rev3 Drop";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };
      in
      {
        devShells.default = preonic-qmk.dev-shell;
        devShells.zmk = zmk-nix.devShells.${system}.default;

        packages.default = preonic-qmk.hex;
        packages.preonic-qmk = preonic-qmk.hex;
        packages.preonic-zmk = preonic-zmk;

        apps.default = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.flash = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.zmk-flash = {
          type = "app";
          program = "${zmk-flasher}/bin/zmk-flash";
        };
        apps.zmk-update = {
          type = "app";
          program = "${pkgs.writeShellScript "zmk-update" ''
            export UPDATE_NIX_ATTR_PATH=preonic-zmk
            export UPDATE_WEST_ROOT=zmk/preonic
            exec ${zmk-nix.packages.${system}.update}/bin/zmk-firmware-update "$@"
          ''}";
        };
      }
    );
}
