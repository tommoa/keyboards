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
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs =
            (with pkgs; [
              ergogen
            ])
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
