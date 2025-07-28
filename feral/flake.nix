{
  description = "Ergogen keyboard design environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            ergogen
          ];

          shellHook = ''
            echo "Ergogen development environment ready!"
            echo "Run 'ergogen ergogen/config.yaml' to generate the keyboard files"
          '';
        };

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
      });
}
