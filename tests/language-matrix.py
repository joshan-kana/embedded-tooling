#!/usr/bin/env python3
"""Exercise each built-in embedded-language formatter and Nix round trip."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

tool = sys.argv[1]
nix_instantiate = sys.argv[3]
registry = json.loads(Path(sys.argv[2]).read_text())
samples = {
    "bash": "echo hello",
    "python": "print(1)",
    "lua": 'print("hello")',
    "javascript": "const answer = 42;",
    "typescript": "const answer: number = 42;",
    "json": '{"answer":42}',
    "jsonc": '{"answer":42}',
    "yaml": "answer: 42",
    "toml": "answer = 42",
    "rust": "fn main() {}",
    "go": "package main\nfunc main() {}",
    "fish": "echo hello",
    "ruby": 'puts "hello"',
    "sql": "SELECT 1;",
    "c": "int main(void) { return 0; }",
    "cpp": "int main(){return 0;}",
    "css": "body { color: red; }",
    "html": "<!DOCTYPE html><html><head><title>Test</title></head><body>Hello</body></html>",
    "markdown": "# Hello",
    "java": "class A { int x = 1; }",
}
assert set(registry) == set(samples), set(registry) ^ set(samples)


def checked(*args):
    result = subprocess.run(args, capture_output=True, text=True, check=False)
    if result.returncode:
        raise AssertionError(f"{' '.join(args)}: {result.stderr[-1500:]}")
    return result


with tempfile.TemporaryDirectory(prefix="embedded-matrix-") as temp:
    root = Path(temp)
    os.environ["NIX_STATE_DIR"] = str(root / "nix-state")
    (root / "nix-state").mkdir()
    for language, sample in samples.items():
        file = root / f"{language}.nix"
        file.write_text(
            "{\n  value = /* "
            + language
            + " */ ''\n    "
            + sample.replace("\n", "\n    ")
            + "\n  '';\n}\n"
        )
        checked(tool, "format", str(file))
        once = file.read_bytes()
        checked(nix_instantiate, "--parse", str(file))
        checked(tool, "format", str(file))
        assert file.read_bytes() == once, f"{language} formatter is not idempotent"

    for lang, body in {
        "bash": "echo ''${HOME}\necho ${builtins.toString 11}",
        "python": "print(${builtins.toString 11})",
        "json": '{"answer": ${builtins.toString 11}, "name": "prefix${builtins.toString 12}suffix"}',
    }.items():
        file = root / f"interpolated-{lang}.nix"
        file.write_text(
            "{\n  value = /* "
            + lang
            + " */ ''\n    "
            + body.replace("\n", "\n    ")
            + "\n  '';\n}\n"
        )
        checked(tool, "format", str(file))
        result = file.read_text()
        assert "${builtins.toString 11}" in result, f"{lang}: interpolation lost"
        if lang == "bash":
            assert "''${HOME}" in result, "escaped shell expansion lost"
        checked(nix_instantiate, "--parse", str(file))

    invalid = {
        "bash": "if then",
        "python": "def :",
        "lua": "local x =",
        "javascript": "const = ;",
        "typescript": "const a: =",
        "json": '{"a": }',
        "jsonc": '{"a": }',
        "yaml": "x: [",
        "toml": "x = [",
        "rust": "fn main( {",
        "go": "package main\nfunc (",
        "fish": "if true\n  echo hi",
        "ruby": "def end",
        "sql": "SELECT FROM",
        "c": "int main( {",
        "cpp": "int main( {",
        "css": "body { color: ?? }",
        "html": "<img>",
        "markdown": "some unstructured text",
        "java": "class {",
    }
    for language, sample in invalid.items():
        file = root / f"invalid-{language}.nix"
        file.write_text(
            "{\n  value = /* "
            + language
            + " */ ''\n    "
            + sample.replace("\n", "\n    ")
            + "\n  '';\n}\n"
        )
        result = subprocess.run(
            [tool, "lint", str(file)], capture_output=True, text=True, check=False
        )
        assert result.returncode != 0, (
            f"{language}: malformed input was accepted by all configured checkers"
        )
        assert str(file) in result.stderr, (
            f"{language}: diagnostic does not identify Nix file: {result.stderr[-600:]}"
        )

print(
    f"{len(samples)} languages, 2 format passes each, 3 interpolation cases, 20 invalid-language checks: passed"
)
