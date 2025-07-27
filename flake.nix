{
  description = "Tools to build and flash my custom keyboard";

  inputs =
    {
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
    };

  outputs =
    { self
    , nixpkgs
    , flake-utils-plus
    , qmk-nix-utils
    , qmk-firmware-source
    }: flake-utils-plus.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };

      qmk-utils-factory = builtins.getAttr system qmk-nix-utils.utils-factory;

      preonic = qmk-utils-factory
        {
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
    in
    {
      devShell = preonic.dev-shell;
      defaultPackage = preonic.hex;
      defaultApp = {
        type = "app";
        program = "${preonic.flasher}/bin/flasher";
      };
      apps.flash = preonic.flasher;
    }
    );
}
