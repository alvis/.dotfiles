#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
CONFIG_PATH="$SCRIPT_DIR/config.conf"

if git config --global --get-all include.path 2>/dev/null | grep -Fqx "$CONFIG_PATH"; then
    echo "Git aliases are already included: $CONFIG_PATH"
    exit 0
fi

git config --global --add include.path "$CONFIG_PATH"
echo "Included Git aliases: $CONFIG_PATH"
