#!/usr/bin/env python3
import re
import sys
from pathlib import Path
version = re.search(r'@version "([^"]+)"', Path('mix.exs').read_text()).group(1)
if sys.argv[1] != f'v{version}':
    sys.exit(f'Tag {sys.argv[1]} must match package version v{version}')
