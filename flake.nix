{
  description = "Tools to build and flash my custom keyboard";

  inputs = {
    annepro2Tools.url = "github:OpenAnnePro/AnnePro2-Tools";
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
      annepro2Tools,
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

        annepro2-qmk = qmk-utils-factory {
          inherit qmk-firmware-source;
          src = ./qmk/annepro2;
          keyboard-name = "annepro2";
          keyboard-variant = "c18";
          keymap-name = "tommoa";
          type = "keymap";
          flash-script = ''
            ${annepro2Tools.packages.${system}."annepro2-tools"}/bin/annepro2_tools --boot $BIN_FILE
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
          zephyrDepsHash = "sha256-pgLfsYIPKZSWiflf1wZ7yiyohdw2V0X35R9xX624MGs=";
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

        feral-zmk-src = ./zmk;

        feral-zmk = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "feral-zmk";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          meta = {
            description = "ZMK firmware for Feral";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        feral-zmk-left = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "feral-zmk-left";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral_left";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          meta = {
            description = "ZMK split central firmware for Feral left half";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        feral-zmk-right = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "feral-zmk-right";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral_right";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          meta = {
            description = "ZMK split peripheral firmware for Feral right half";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        feral-zmk-diag-col2row = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "feral-zmk-diag-col2row";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral_diag";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          meta = {
            description = "ZMK bring-up firmware for Feral (col2row scan)";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        feral-zmk-diag-row2col = zmk-nix.legacyPackages.${system}.buildKeyboard {
          name = "feral-zmk-diag-row2col";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral_diag_rev";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          meta = {
            description = "ZMK bring-up firmware for Feral (row2col scan)";
            license = nixpkgs.lib.licenses.mit;
            platforms = nixpkgs.lib.platforms.all;
          };
        };

        feral-raw-scan = zmk-nix.legacyPackages.${system}.buildZephyrPackage {
          name = "feral-raw-scan";
          src = ./feral/raw-scan;
          zephyrDepsHash = "sha256-+SgSs8+fI3Li+B5eFXBNBa+c/OVbyKqjbogiC8d5vrg=";
          configurePhase = ''
            runHook preConfigure

            mkdir workspace
            cd workspace

            cp --no-preserve=mode -rt . "$westDeps"/*
            cp -R "$src" app

            mkdir -p zephyr/.git
            : > zephyr/.git/index

            mkdir -p .west
            cat >.west/config <<EOF
            [manifest]
            path = zephyr
            file = west.yml
            EOF

            west build -d "''${cmakeBuildDir:=build}" \
              -s app \
              -b xiao_ble

            cd "$cmakeBuildDir"

            runHook postConfigure
          '';
          installPhase = ''
            runHook preInstall

            mkdir $out
            cp zephyr/zephyr.uf2 zephyr/zephyr.bin zephyr/zephyr.elf $out/

            runHook postInstall
          '';
          meta = {
            description = "Standalone raw GPIO scan app for Feral";
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
        packages.annepro2-qmk = annepro2-qmk.hex;
        packages.preonic-qmk = preonic-qmk.hex;
        packages.preonic-zmk = preonic-zmk;
        packages.feral-zmk = feral-zmk;
        packages.feral-zmk-left = feral-zmk-left;
        packages.feral-zmk-right = feral-zmk-right;
        packages.feral-zmk-diag-col2row = feral-zmk-diag-col2row;
        packages.feral-zmk-diag-row2col = feral-zmk-diag-row2col;
        packages.feral-raw-scan = feral-raw-scan;

        apps.default = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.preonic-qmk-flash = {
          type = "app";
          program = "${preonic-qmk.flasher}/bin/flasher";
        };
        apps.annepro2-qmk-flash = {
          type = "app";
          program = "${annepro2-qmk.flasher}/bin/flasher";
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
