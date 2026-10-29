{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    nixfmt.enable = true;
    ruff-format.enable = true;
    ruff-check.enable = true;
    prettier.enable = true;
    rumdl-format.enable = true;
    rumdl-check.enable = true;
  };
  settings.formatter = {
    ruff-format.priority = 1;
    ruff-check = {
      priority = 2;
      options = [
        "--select"
        "E4,E7,E9,F,I"
      ];
    };
    rumdl-format.priority = 1;
    rumdl-check.priority = 2;
  };
}
