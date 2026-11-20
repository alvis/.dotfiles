#!/bin/sh
#
# Include the shared .dotfiles Git aliases exactly once.
#
#   setup.sh [--file <config>]
#
# The include goes into the machine-local ~/.config/git/config by default, so
# a personal ~/.gitconfig (which may sync between machines) cannot remove it.
# Nothing is added when any global Git config already includes the file.

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
CONFIG_PATH="$SCRIPT_DIR/config.conf"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/git/config"

while [ $# -gt 0 ]; do
    case $1 in
    --file)
        TARGET=${2:?--file needs a path}
        shift
        ;;
    *)
        echo "usage: $0 [--file <git config file>]" >&2
        exit 2
        ;;
    esac
    shift
done

if git config --global --get-all include.path 2>/dev/null | grep -Fqx "$CONFIG_PATH" ||
    git config --file "$TARGET" --get-all include.path 2>/dev/null | grep -Fqx "$CONFIG_PATH"; then
    echo "Git aliases are already included: $CONFIG_PATH"
    exit 0
fi

mkdir -p "$(dirname -- "$TARGET")"
git config --file "$TARGET" --add include.path "$CONFIG_PATH"
echo "Included Git aliases: $CONFIG_PATH (in $TARGET)"
