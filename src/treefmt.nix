{ lib, pkgs, ... }:
{
  # Consumers can import this module into their existing treefmt-nix
  # configuration. Explicit local options win over these defaults.
  programs = {
    shfmt.enable = lib.mkDefault true;
    shellcheck.enable = lib.mkDefault true;
    ruff-check.enable = lib.mkDefault true;
    ruff-format.enable = lib.mkDefault true;
    stylua.enable = lib.mkDefault true;
    prettier.enable = lib.mkDefault true;
    yamllint.enable = lib.mkDefault true;
    taplo.enable = lib.mkDefault true;
    rustfmt.enable = lib.mkDefault true;
    gofumpt.enable = lib.mkDefault true;
    fish_indent.enable = lib.mkDefault true;
    rubocop.enable = lib.mkDefault true;
    sqlfluff.enable = lib.mkDefault true;
    sqlfluff-lint.enable = lib.mkDefault true;
    clang-format.enable = lib.mkDefault true;
    rumdl-check.enable = lib.mkDefault true;
    rumdl-format.enable = lib.mkDefault true;
    google-java-format.enable = lib.mkDefault true;
  };

  programs.sqlfluff.dialect = lib.mkDefault "ansi";
  settings.formatter.shellcheck.options = lib.mkAfter [ "--shell=bash" ];
  settings.formatter.shellcheck.priority = lib.mkDefault 3;

  settings.formatter = {
    biome-lint = {
      command = lib.getExe pkgs.biome;
      options = [ "lint" ];
      includes = [
        "*.js"
        "*.jsx"
        "*.ts"
        "*.tsx"
        "*.json"
        "*.jsonc"
        "*.css"
      ];
      priority = 3;
    };
    toml-lint = {
      command = lib.getExe pkgs.taplo;
      options = [ "lint" ];
      includes = [ "*.toml" ];
      priority = 3;
    };
    fish-syntax = {
      command = lib.getExe pkgs.fish;
      options = [ "--no-execute" ];
      includes = [ "*.fish" ];
      priority = 3;
    };
    go-syntax = {
      command = "${pkgs.go}/bin/gofmt";
      options = [
        "-e"
        "-d"
      ];
      includes = [ "*.go" ];
      priority = 3;
    };
    rust-syntax = {
      command = lib.getExe pkgs.rustfmt;
      options = [ "--check" ];
      includes = [ "*.rs" ];
      priority = 3;
    };
    c-syntax = {
      command = lib.getExe pkgs.clang;
      options = [
        "-fsyntax-only"
        "-x"
        "c"
      ];
      includes = [ "*.c" ];
      priority = 3;
    };
    cpp-syntax = {
      command = lib.getExe pkgs.clang;
      options = [
        "-fsyntax-only"
        "-x"
        "c++"
      ];
      includes = [
        "*.cpp"
        "*.cc"
        "*.cxx"
      ];
      priority = 3;
    };
    java-lint = {
      command = lib.getExe pkgs.checkstyle;
      options = [
        "-c"
        "/google_checks.xml"
        "-f"
        "plain"
      ];
      includes = [ "*.java" ];
      priority = 3;
    };
    rubyfmt = {
      command = lib.getExe pkgs.rubyfmt;
      options = [ "--in-place" ];
      includes = [ "*.rb" ];
      priority = 1;
    };
    lua-lint = {
      command = lib.getExe pkgs.lua54Packages.luacheck;
      options = [ "--no-config" ];
      includes = [ "*.lua" ];
      priority = 3;
    };
    htmlhint = {
      command = lib.getExe pkgs.htmlhint;
      includes = [
        "*.html"
        "*.htm"
      ];
      priority = 3;
    };
  };
}
