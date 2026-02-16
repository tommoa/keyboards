{ ... }:
{
  projectRootFile = "flake.nix";

  # Nix
  programs.nixfmt.enable = true;

  # JavaScript (Ergogen footprints) and YAML
  programs.prettier.enable = true;
  programs.prettier.includes = [
    "*.js"
    "*.yaml"
  ];
}
