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

        feral-pcb = pkgs.stdenv.mkDerivation {
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

        case-shell-stls = pkgs.stdenvNoCC.mkDerivation {
          name = "feral-case-shell-stls";
          src = ./.;
          nativeBuildInputs = [
            openscad-cli
            pkgs.python3
          ];

          buildPhase = ''
            runHook preBuild

            # OpenSCAD's macOS config-path lookup goes through Foundation's
            # user-domain Application Support API. Under Nix build users that
            # defaults to /var/empty and traps inside OpenSCAD unless we give
            # Foundation a writable synthetic home.
            export HOME="$TMPDIR/home"
            export CFFIXED_USER_HOME="$HOME"
            mkdir -p "$HOME/Library/Application Support"

            cp -R "$src" work
            chmod -R u+w work
            ln -s ${feral-pcb} work/result
            mkdir -p work/case/cad/generated

            python3 work/case/scripts/extract_component_positions.py \
              --input work/feral.kicad_pcb \
              --output work/case/cad/generated/component_positions.scad

            cat > work/case/cad/generated/xiao-nrf52840-parts.scad <<'EOF'
            module xiao_nrf52840_parts() {}
            EOF

            for hand in left right; do
              for part in bottom top; do
                openscad \
                  -o "feral-$hand-$part.stl" \
                  -D "hand=\"$hand\"" \
                  -D "part=\"$part\"" \
                  work/case/cad/feral_case.scad
              done
            done

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p $out
            cp feral-*.stl $out/

            runHook postInstall
          '';
        };
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
        checks.case-shell-stls = case-shell-stls;

        packages.default = feral-pcb;
        packages.case-shell-stls = case-shell-stls;
      }
    );
}
