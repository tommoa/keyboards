{
  description = "QMK/ZMK compatible keyboards development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        qmkHome = "${./.}/qmk_firmware";
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # QMK dependencies
            qmk
            python3
            python3Packages.pip
            python3Packages.setuptools
            avrdude
            dfu-programmer
            dfu-util
            
            # General development tools
            git
            gnumake
          ];

          shellHook = ''
            export QMK_HOME="${qmkHome}"
            echo "QMK/ZMK Keyboard Development Environment"
            echo "======================================="
            echo "QMK_HOME set to: $QMK_HOME"
            echo "Available tools:"
            echo "  - qmk: QMK CLI tool"
            echo "  - avrdude, dfu-util: Flashing tools"
            echo ""
            echo "To get started with QMK:"
            echo "  qmk setup"
            echo "  qmk compile -kb <keyboard> -km <keymap>"
          '';
        };

        packages = {
          # Example package for building a specific keyboard
          # Uncomment and modify as needed
          # my-keyboard = pkgs.stdenv.mkDerivation {
          #   pname = "my-keyboard";
          #   version = "1.0.0";
          #   src = ./.;
          #   
          #   buildInputs = with pkgs; [ qmk ];
          #   
          #   QMK_HOME = qmkHome;
          #   
          #   buildPhase = ''
          #     qmk compile -kb my_keyboard -km default
          #   '';
          #   
          #   installPhase = ''
          #     mkdir -p $out
          #     cp *.hex $out/ || true
          #     cp *.uf2 $out/ || true
          #   '';
          # };
        };
      });
}
