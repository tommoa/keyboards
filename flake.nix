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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
      treefmt-nix,
    }:
    flake-utils-plus.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

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
          board = "preonic//zmk";
          config = "preonic/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          # The Preonic rev3 Drop uses STM32 DFU, not UF2 bootloader,
          # so the build produces .bin/.hex instead of .uf2.
          installPhase = ''
            runHook preInstall
            mkdir $out
            cp zephyr/zmk.bin zephyr/zmk.hex $out/
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
        devShells.default = pkgs.mkShell {
          inputsFrom = [ preonic-qmk.dev-shell ];
          packages = [
            treefmtEval.config.build.wrapper
          ]
          ++ builtins.attrValues treefmtEval.config.build.programs;
        };
        devShells.zmk = pkgs.mkShell {
          inputsFrom = [ zmk-nix.devShells.${system}.default ];
          packages = [
            treefmtEval.config.build.wrapper
          ]
          ++ builtins.attrValues treefmtEval.config.build.programs;
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;

        packages.default = preonic-qmk.hex;
        packages.preonic-qmk = preonic-qmk.hex;
        packages.preonic-zmk = preonic-zmk;

        apps.default = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.preonic-qmk-flash = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.preonic-zmk-flash = {
          type = "app";
          program = "${zmk-flasher}/bin/zmk-flash";
        };
        apps.preonic-zmk-update = {
          type = "app";
          program = "${pkgs.writeShellScript "zmk-update" ''
            export UPDATE_NIX_ATTR_PATH=preonic-zmk
            export UPDATE_WEST_ROOT=zmk/preonic/config
            exec ${zmk-nix.packages.${system}.update}/bin/zmk-firmware-update "$@"
          ''}";
        };
      }
    );
}
