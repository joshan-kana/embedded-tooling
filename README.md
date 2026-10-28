# Nix embedded-language tooling

Reusable, editor-independent language tooling for explicitly annotated code
inside Nix strings. Supports an open registry of languages and native tools.

## Flake input

Add an input named nix-embedded from github:joshan-kana/nix-embedded-tooling.
Make its nixpkgs input follow the consumer repository's nixpkgs.

Build the integration with:

    embedded = nix-embedded.lib.mkFor {
      inherit pkgs;
      enabledLanguages = [ "bash" "python" "json" "yaml" ];
    };

The returned attributes include:
- lspPackage: Kakehashi-powered editor LSP command named kakehashi
- package: embedded-language formatter and linter
- formatter and finalNixfmtFormatter: treefmt formatter definitions
- lintCheck { src = self; }: reproducible native lint check
- lspCheck: LSP end-to-end protocol smoke test
- hostLspPackage and languageRegistry

Merge the formatter definitions with existing treefmt config; add the lint
check to the consuming flake's checks and the LSP package to its development
environment. Point each editor's LSP client at the provided kakehashi command.

The root kakehashi.toml of a consumer may hold repository-specific options.

## Language and tool configuration

- enabledLanguages: subset of known languages (default all)
- registryOverrides: replace or add language definitions
- formatterPackages and lspPackages: package lists by language
- extraFormatterInputs and extraLspInputs: extra dependencies

Formatters and language servers are selected by the registry's executable
commands; they are not editor-specific. The built-in CLI lint backends
currently cover Bash (ShellCheck) and Python (Ruff). Other languages can use
their configured LSP and native formatters without inventing a generic
lint-equivalent where none exists.

This is an extraction of a working Nix-string adapter. Kakehashi is the
editor-facing bridge. Its pending virtual-document preparation support can
replace adapter internals when equivalent behaviour is proven.

## Development

Run nix flake check --no-build, then build the platform-specific lint and
lsp checks. Test a consuming flake separately.
