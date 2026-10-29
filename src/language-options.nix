{ lib, ... }:
let
  inherit (lib) mkDefault mkOption types;
  defaults = builtins.fromJSON (builtins.readFile ./nix-embedded-languages.json);
  backend = types.submodule {
    options = {
      name = mkOption { type = types.str; };
      command = mkOption { type = types.listOf types.str; };
      features = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };
  language = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable this embedded-language integration.";
      };
      aliases = mkOption { type = types.listOf types.str; };
      extension = mkOption { type = types.str; };
      languageId = mkOption { type = types.str; };
      grammar = mkOption { type = types.str; };
      lsp = mkOption {
        type = types.listOf backend;
        default = [ ];
      };
    };
  };
in
{
  options.languages = mkOption {
    type = types.attrsOf language;
    default = { };
    description = "Per-language embedded syntax, Tree-sitter and LSP options.";
  };
  config.languages = lib.mapAttrs (_: value: lib.mapAttrs (_: entry: mkDefault entry) value) defaults;
}
