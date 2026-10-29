{
  description = "Reusable embedded-language LSP, formatting, and lint integration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kakehashi = {
      url = "github:atusy/kakehashi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      kakehashi,
      treefmt-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forSystems = f: lib.genAttrs systems f;
      repoQualityFor =
        system: treefmt-nix.lib.evalModule (import nixpkgs { inherit system; }) ./src/repo-quality.nix;
      mkFor =
        {
          pkgs,
          kakehashiPackage ? kakehashi.packages.${pkgs.stdenv.hostPlatform.system}.default,
          treefmtConfig ? null,
          ...
        }@args:
        let
          defaultConfig = (treefmt-nix.lib.evalModule pkgs ./src/treefmt.nix).config.build.configFile;
        in
        import ./src/nix-embedded.nix (
          args
          // {
            inherit (pkgs) lib;
            inherit pkgs kakehashiPackage;
            treefmtConfig = if treefmtConfig == null then defaultConfig else treefmtConfig;
          }
        );
    in
    {
      lib = {
        mkFor = mkFor;
        treefmtModule = ./src/treefmt.nix;
        languageOptionsModule = ./src/language-options.nix;
      };
      packages = forSystems (
        system:
        let
          tools = mkFor { pkgs = import nixpkgs { inherit system; }; };
        in
        {
          default = tools.lspPackage;
          kakehashi = tools.lspPackage;
          embedded-formatter = tools.package;
          embedded-host-lsp = tools.hostLspPackage;
        }
      );
      apps = forSystems (system: {
        default = {
          type = "app";
          program = lib.getExe self.packages.${system}.kakehashi;
        };
      });
      checks = forSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          tools = mkFor { inherit pkgs; };
        in
        {
          lint = tools.lintCheck { src = self; };
          lsp = tools.lspCheck;
          repo-quality = (repoQualityFor system).config.build.check self;
          lsp-backends = pkgs.runCommand "embedded-lsp-backends" { } ''
            ${lib.getExe tools.hostLspPackage} --check-backends
            touch "$out"
          '';
          consumer-integration =
            let
              consumerTreefmt = treefmt-nix.lib.evalModule pkgs {
                projectRootFile = "flake.nix";
                programs.shfmt = {
                  enable = true;
                  indent_size = 4;
                };
              };
              consumerTools = mkFor {
                inherit pkgs;
                treefmtConfig = consumerTreefmt.config.build.configFile;
                languages.python.enable = false;
              };
            in
            pkgs.runCommand "embedded-tooling-consumer-integration" { } ''
              cp ${./tests/consumer.nix} fixture.nix
              chmod u+w fixture.nix
              ${lib.getExe consumerTools.package} format fixture.nix
              grep -q '^        echo hi$' fixture.nix
              grep -q 'print( 42 )' fixture.nix
              cp fixture.nix once.nix
              ${lib.getExe consumerTools.package} format fixture.nix
              cmp fixture.nix once.nix
              ${lib.getExe consumerTools.package} lint fixture.nix
              touch "$out"
            '';
          language-matrix = pkgs.runCommand "embedded-language-matrix" { } ''
            ${pkgs.python3}/bin/python3 ${./tests/language-matrix.py}               ${lib.getExe tools.package} ${./src/nix-embedded-languages.json} ${pkgs.nix}/bin/nix-instantiate
            touch "$out"
          '';
        }
      );
      formatter = forSystems (system: (repoQualityFor system).config.build.wrapper);
    };
}
