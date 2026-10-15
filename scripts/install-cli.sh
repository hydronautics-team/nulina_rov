#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
INSTALL_DIR="${XDG_BIN_HOME:-${HOME}/.local/bin}"
TARGET="$INSTALL_DIR/run"

mkdir -p "$INSTALL_DIR"
ln -sfn "$SCRIPT_DIR/run" "$TARGET"

echo "Installed: $TARGET"
if [[ ":${PATH}:" != *":${INSTALL_DIR}:"* ]]; then
    echo "Add this directory to PATH: $INSTALL_DIR"
fi
