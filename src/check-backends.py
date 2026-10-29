#!/usr/bin/env python3
"""Ensure every configured embedded-language server is executable."""

import json
import shutil
import sys
from pathlib import Path

languages = json.loads(Path(sys.argv[1]).read_text())
missing = []
configured = []
for language, spec in sorted(languages.items()):
    backends = spec.get("lsp") or []
    if not backends:
        missing.append(f"{language}: no configured LSP")
    for backend in backends:
        executable = backend["command"][0]
        resolved = shutil.which(executable)
        configured.append((language, executable, resolved))
        if resolved is None:
            missing.append(f"{language}: executable {executable} unavailable")
for lang, command, resolved in configured:
    print(f"{lang:14} {command:30} {resolved or 'MISSING'}")
if missing:
    raise SystemExit("\n".join(missing))
print(
    f"{len(languages)} languages, {len(configured)} server entries: executables verified"
)
