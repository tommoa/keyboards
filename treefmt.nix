{ ... }:
{
  projectRootFile = "flake.nix";

  # Nix
  programs.nixfmt.enable = true;

  # YAML
  programs.yamlfmt.enable = true;

  # Exclude feral/ — it has its own flake and treefmt config
  settings.global.excludes = [
    "feral/*"
  ];
}
