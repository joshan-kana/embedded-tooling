# Nix embedded-language tooling

Embedded-language LSP, formatting and linting integration for annotated Nix
strings, independent of the consuming editor and host configuration.

Kakehashi is the editor-facing LSP executable. A Nix-aware internal specialist
prepares embedded source, protects Nix interpolations and maps safe edits and
diagnostics back to Nix. Treefmt selects formatters and linters, using the
consumer's existing Treefmt configuration for both ordinary language files
and embedded source.

## Add the flake input

    embedded-tooling = {
      url = "github:joshan-kana/embedded-tooling";
      inputs.nixpkgs.follows = "nixpkgs";
    };

The integration is a library function and does not require flake-parts:

    embedded = inputs.embedded-tooling.lib.mkFor {
      inherit pkgs;
      languages = {
        bash.enable = true;
        python.enable = true;
        rust.enable = false;
      };
    };

All built-in languages are enabled unless explicitly disabled.
The language options are Nix module options. Invalid types fail evaluation.
The public lib.languageOptionsModule can be imported into a larger Nix module
to provide autocomplete, option introspection and merge semantics.

## Reuse the existing Treefmt configuration

Treefmt should remain the only configuration for native formatter commands,
linter commands, included files, priority and command-line options.

For a consumer already using treefmt-nix, evaluate its normal module once
without the embedded adapter and once with the adapter:

    baseModule = {
      imports = [ inputs.embedded-tooling.lib.treefmtModule ];
      projectRootFile = "flake.nix";

      programs.nixfmt.enable = true;
      # Other formatter and linter options belong here.
    };

    base = inputs.treefmt-nix.lib.evalModule pkgs baseModule;

    embedded = inputs.embedded-tooling.lib.mkFor {
      inherit pkgs;
      treefmtConfig = base.config.build.configFile;
    };

    full = inputs.treefmt-nix.lib.evalModule pkgs {
      imports = [ baseModule ];
      settings.formatter = {
        nix-embedded = embedded.formatter;
        nixfmt-final = embedded.finalNixfmtFormatter;
      };
    };

Use full.config.build.wrapper for nix fmt and full.config.build.check self
for the existing flake formatting check. The two evaluations use the same
baseModule, not two separately maintained configurations. The first excludes
the embedded adapter to avoid a circular derivation dependency.

When no treefmtConfig is passed, the package uses its shipped default
treefmt-nix module, which provides native formatting and applicable checking
tools for its built-in languages. The consumer can import
lib.treefmtModule to adopt those defaults or override them through the
usual treefmt-nix options.

The embedded formatter supplies virtual filenames such as
config.nix.embedded.py to Treefmt's --stdin mode, preserving the existing
formatter configuration's path selection and native tool settings.
Intervening Nix expressions remain protected and cannot be replaced by
unsafe native tool edits.

## Language options

The typed lib.mkFor languages option is an attribute set:

    languages.example = {
      enable = true;
      aliases = [ "example" ];
      extension = "sh";
      languageId = "shellscript";
      grammar = "bash";
      lsp = [
        {
          name = "bash-language-server";
          command = [ "bash-language-server" "start" ];
          features = [ "semantic" ];
        }
      ];
    };

Optional overrides include grammarPackages (Tree-sitter derivations),
lspPackages (language-server derivations), extraLspInputs and
kakehashiPackage. Tool selection and formatter/linter configuration belong
in treefmt-nix, not the LSP registry.

The existing annotations require no special editor plugin:

    /* bash */ ''
      echo "hello"
    ''

    /* python */ ''
      print(${builtins.toString 42})
    ''

VS Code, Helix and Neovim all connect to the provided kakehashi command
using their usual LSP configuration. Repository-specific nixd option
expressions may live in a root kakehashi.toml.

## Tests

    nix flake check --all-systems --no-build
    nix build .#checks.x86_64-linux.lint
    nix build .#checks.x86_64-linux.language-matrix
    nix build .#checks.x86_64-linux.lsp

The language matrix invokes formatting twice for each built-in language,
checks idempotence and Nix syntax, and checks protected interpolations.
The LSP smoke test exercises the running Kakehashi bridge and native servers.

## Limits

Formatting uses the same Treefmt configuration as standalone files. A
lint-only tool that rejects incomplete embedded source does not prevent
other native formatters from operating; Treefmt's standalone check still
reports that failure.

ShellCheck and Ruff CLI diagnostics retain specialised source-coordinate
mapping and reuse the configured Treefmt commands and options. For other
native checkers the generic Treefmt CLI fallback currently reports the
affected Nix block, which is less precise than language-server diagnostics.
New checkers with different output formats may require additional position
adapters before exact line mapping can be claimed.

Not every backend can safely edit across protected Nix interpolations.
The upstream Kakehashi virtual-document preparation series remains under
review; this package retains its existing internal Nix specialist until
upstream offers equivalent safe edit translation.
