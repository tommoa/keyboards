{
  description = "Tools to build and flash my custom keyboard";

  inputs = {
    annepro2Tools = {
      url = "github:OpenAnnePro/AnnePro2-Tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    vortex-qmk-source = {
      type = "git";
      url = "https://github.com/pok3r-custom/qmk_pok3r";
      flake = false;
      submodules = true;
    };
    pok3rtool-source = {
      type = "git";
      url = "https://github.com/pok3r-custom/pok3rtool";
      flake = false;
    };
    pok3r-re-firmware-source = {
      type = "git";
      url = "https://github.com/pok3r-custom/pok3r_re_firmware";
      flake = false;
    };
    openocd-ht32-source = {
      type = "git";
      url = "https://github.com/ChaoticEnigma/openocd-ht32";
      flake = false;
    };
    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    feral.url = "path:./feral";
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
      vortex-qmk-source,
      pok3rtool-source,
      pok3r-re-firmware-source,
      openocd-ht32-source,
      zmk-nix,
      feral,
      treefmt-nix,
    }:
    flake-utils-plus.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;

        qmk-utils-factory = builtins.getAttr system qmk-nix-utils.utils-factory;

        pok3rtool = pkgs.callPackage ./nix/pkgs/pok3rtool.nix {
          src = pok3rtool-source;
        };

        openocd-ht32 = pkgs.callPackage ./nix/pkgs/openocd-ht32.nix {
          src = openocd-ht32-source;
        };

        vortex-core-unlocked-fw = pkgs.callPackage ./nix/pkgs/vortex-core-unlocked-fw.nix {
          src = pok3r-re-firmware-source;
        };

        vortex-core-qmk = pkgs.callPackage ./nix/pkgs/vortex-core-qmk.nix {
          qmk-firmware-source = vortex-qmk-source;
          src = ./qmk/vortex-core;
        };

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
          zephyrDepsHash = "sha256-dKindQ2e71XCGL4bA/+18HG6ZPUYWHQdwkU9HkXei0E=";
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

        feral-zmk = zmk-nix.legacyPackages.${system}.buildSplitKeyboard {
          name = "feral-zmk";
          src = feral-zmk-src;
          board = "xiao_ble";
          shield = "feral_%PART%";
          config = "feral/config";
          zephyrDepsHash = "sha256-AckaKQrasDg4T3c+Wf/VURpQ8dYlIWVR5eAqmx9iaf4=";
          extraCmakeFlags = [
            "-DZMK_EXTRA_MODULES=${./feral/startup-led}"
          ];
          meta = {
            description = "ZMK split firmware for Feral";
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
          extraCmakeFlags = [
            "-DZMK_EXTRA_MODULES=${./feral/startup-led}"
          ];
          meta = {
            description = "ZMK bring-up firmware for Feral (col2row scan)";
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
        devShells.vortex-core = pkgs.mkShell {
          packages = [
            pkgs.clang-tools
            pkgs.gcc-arm-embedded
            pkgs.git
            pkgs.qmk
            openocd-ht32
            pok3rtool
            treefmtEval.config.build.wrapper
          ]
          ++ builtins.attrValues treefmtEval.config.build.programs;

          shellHook = ''
            export SKIP_GIT=true
            export SKIP_VERSION=true
            unset NIX_CFLAGS_COMPILE_FOR_TARGET
          '';
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;

        packages.default = preonic-qmk.hex;
        packages.annepro2-qmk = annepro2-qmk.hex;
        packages.preonic-qmk = preonic-qmk.hex;
        packages.preonic-zmk = preonic-zmk;
        packages.vortex-core-qmk = vortex-core-qmk;
        packages.feral-zmk = feral-zmk;
        packages.feral-zmk-diag-col2row = feral-zmk-diag-col2row;
        packages.feral-raw-scan = feral-raw-scan;
        packages.feral-pcb = feral.packages.${system}.default;
        packages.feral-case-shell-stls = feral.packages.${system}.case-shell-stls;

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
        apps.vortex-core-qmk-flash = {
          type = "app";
          program = "${pkgs.writeShellScript "vortex-core-qmk-flash" ''
            set -euo pipefail

            BIN_FILE=$(${pkgs.findutils}/bin/find ${vortex-core-qmk} -type f -name "*.bin" | ${pkgs.coreutils}/bin/head -n 1)

            if [ -z "$BIN_FILE" ]; then
              echo "No .bin firmware artifact found in ${vortex-core-qmk}" >&2
              exit 1
            fi

            ${pok3rtool}/bin/pok3rtool reboot --bootloader || true
            exec ${pok3rtool}/bin/pok3rtool flash TOMMOA_VCORE "$BIN_FILE"
          ''}";
        };
        apps.vortex-core-qmk-bootloader = {
          type = "app";
          program = "${pkgs.writeShellScript "vortex-core-qmk-bootloader" ''
            exec ${pok3rtool}/bin/pok3rtool reboot --bootloader
          ''}";
        };
        apps.vortex-core-qmk-unlock = {
          type = "app";
          program = "${pkgs.writeShellScript "vortex-core-qmk-unlock" ''
            set -euo pipefail

            exec ${openocd-ht32}/bin/openocd \
              -c 'set HT32_SRAM_SIZE 0x4000' \
              -c 'set HT32_FLASH_SIZE 0x10000' \
              -f ${openocd-ht32}/share/openocd/scripts/interface/stlink-v2-1.cfg \
              -f ${openocd-ht32}/share/openocd/scripts/target/ht32f165x.cfg \
              -c 'init' \
              -c 'reset halt' \
              -c 'ht32f165x mass_erase 0' \
              -c 'flash write_image ${vortex-core-unlocked-fw}/firmware_builtin_core.bin 0' \
              -c 'reset run' \
              -c 'shutdown'
          ''}";
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
