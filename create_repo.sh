#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if command -v python >/dev/null 2>&1; then
  python scripts/repo_factory.py "$@"
elif command -v python3 >/dev/null 2>&1; then
  python3 scripts/repo_factory.py "$@"
elif command -v py >/dev/null 2>&1; then
  py -3 scripts/repo_factory.py "$@"
else
  echo "Python is required. Install Python or add it to PATH." >&2
  exit 1
fi
