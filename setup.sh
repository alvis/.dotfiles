#!/bin/bash
#
# Compatibility entry point: the setup now lives in install.sh.
#
#   ~/.dotfiles/setup.sh [install.sh options]

exec "$(cd "$(dirname "$0")" && pwd -P)/install.sh" "$@"
