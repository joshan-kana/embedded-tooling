{
  description = "Editor-independent embedded-language tooling for Nix strings";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    kakehashi = {
      url = "github:atusy/kakehashi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, kakehashi, ... }:
    let
      inherit (nixpkgs) lib;
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forSystems = f: lib.genAttrs systems f;
      mkFor = { pkgs, kakehashiPackage ? kakehashi.packages.${pkgs.stdenv.hostPlatform.system}.default, ... }@args:
        import ./src/nix-embedded.nix (args // { inherit (pkgs) lib; inherit pkgs kakehashiPackage; });
    in {
      lib.mkFor = mkFor;
      packages = forSystems (system:
        let tools = mkFor { pkgs = import nixpkgs { inherit system; }; };
        in {
          default = tools.lspPackage;
          kakehashi = tools.lspPackage;
          embedded-formatter = tools.package;
          embedded-host-lsp = tools.hostLspPackage;
        });
      apps = forSystems (system: {
        default = {
          type = "app";
          program = lib.getExe self.packages.${system}.kakehashi;
        };
      });
      checks = forSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          tools = mkFor { inherit pkgs; };
        in {
          lint = tools.lintCheck { src = self; };
          lsp = tools.lspCheck;
        });
      formatter = forSystems (system: (import nixpkgs { inherit system; }).nixfmt);
    };
}
