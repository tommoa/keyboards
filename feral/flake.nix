{
  description = "Ergogen keyboard design environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        openscad-cli = pkgs.writeShellScriptBin "openscad" ''
          if [ -x "${pkgs.openscad}/bin/openscad" ]; then
            exec "${pkgs.openscad}/bin/openscad" "$@"
          fi

          if [ -x "${pkgs.openscad}/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]; then
            exec "${pkgs.openscad}/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" "$@"
          fi

          echo "Could not find an OpenSCAD executable in ${pkgs.openscad}" >&2
          exit 1
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            (with pkgs; [
              ergogen
            ])
            ++ [ openscad-cli ]
            ++ [ treefmtEval.config.build.wrapper ]
            ++ builtins.attrValues treefmtEval.config.build.programs;

          shellHook = ''
            echo "Ergogen development environment ready!"
            echo "Run 'ergogen ergogen/config.yaml' to generate the keyboard files"
          '';
        };

        formatter = treefmtEval.config.build.wrapper;
        checks.formatting = treefmtEval.config.build.check self;

        packages.default = pkgs.stdenv.mkDerivation {
          name = "feral-keyboard";
          src = ./.;

          buildInputs = with pkgs; [
            ergogen
          ];

          buildPhase = ''
            ergogen ergogen
          '';

          installPhase = ''
            mkdir -p $out
            cp -r output/* $out/ 2>/dev/null || echo "No output directory found"
          '';
        };
      }
    );
}
