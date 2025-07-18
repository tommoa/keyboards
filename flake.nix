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

      utils-factory = builtins.getAttr system qmk-nix-utils.utils-factory;

      utils = utils-factory
        {
          inherit qmk-firmware-source;
          src = ./src;
          keyboard-name = "custom_preonic";
          keymap-name = "default";
          flash-script = ''
            echo -n "Press the RESET button..."
            while [ ! -e /dev/ttyACM0 ]
            do
              echo -n "."
              sleep 0.5
            done
            ${pkgs.avrdude}/bin/avrdude -p atmega32u4 -c avr109 -P /dev/ttyACM0 -U flash:w:$HEX_FILE
          '';
        };
    in
    {
      devShell = utils.dev-shell;
      defaultPackage = utils.hex;
      defaultApp = {
        type = "app";
        program = "${utils.flasher}/bin/flasher";
      };
      apps.flash = utils.flasher;
    }
    );
}
