#!/usr/bin/env python3
"""Check the upstream declarations and exports used by the EXGBoost NIF."""
import re
import subprocess
import sys
from pathlib import Path


def declarations(include):
    header = Path(include) / 'xgboost/c_api.h'
    source = header.read_text()
    source = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.S)
    result = {}
    for decl in re.findall(r'XGB_DLL\s+[^;]+;', source):
        match = re.search(r'\b(XG\w+)\s*\(', decl)
        if match:
            normalized = re.sub(r'\s+', ' ', decl).strip()
            result[match[1]] = re.sub(r'\s*([*,();])\s*', r'\1', normalized)
    return result


if sys.argv[1:2] == ['--compare']:
    if len(sys.argv) != 4:
        sys.exit('Usage: check_xgboost_c_api.sh --compare <old-include> <new-include>')
    old, new = map(declarations, sys.argv[2:])
    removed = old.keys() - new.keys()
    changed = {name for name in old.keys() & new.keys() if old[name] != new[name]}
    added = new.keys() - old.keys()
    for label, names in [('Removed', removed), ('Changed', changed), ('Added', added)]:
        print(f'{label}: {", ".join(sorted(names)) or "none"}')
    sys.exit(1 if removed or changed else 0)

if len(sys.argv) not in (2, 3):
    sys.exit('Usage: check_xgboost_c_api.sh <installed-include> [shared-library]')
api = declarations(sys.argv[1])
used = set()
for source in Path('c/exgboost/src').glob('*.c'):
    used.update(re.findall(r'\b(XG\w+)\s*\(', source.read_text()))
missing = used - api.keys()
if missing:
    sys.exit(f'Missing C API declarations: {", ".join(sorted(missing))}')
if len(sys.argv) == 3:
    library = Path(sys.argv[2])
    if not library.is_file():
        sys.exit(f'Shared library does not exist: {library}')
    command = ['nm', '-gU'] if sys.platform == 'darwin' else ['nm', '-D', '--defined-only']
    output = subprocess.check_output(command + [str(library)], text=True)
    exported = {line.split()[-1].removeprefix('_') for line in output.splitlines() if line.split()}
    missing = used - exported
    if missing:
        sys.exit(f'Missing shared-library exports: {", ".join(sorted(missing))}')
print(f'XGBoost C API compatibility check passed ({len(used)} symbols).')
