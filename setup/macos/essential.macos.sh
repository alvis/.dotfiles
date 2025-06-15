#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Install essential utilities
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

BASE=$(cd "$(dirname "$0")"; pwd -P)

# set PATH for startup scripts loaded via launchctl
sudo launchctl config user path $PATH

# configuration files

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || dotfiles: sync .dotfiles to ~/
#  || mackup: configuration backup manager
# //

# restore dotfiles
pipx install dotfiles
ln -sf $(grealpath --relative-to ~ ${BASE}/../../.dotfilesrc) ~/.dotfilesrc
dotfiles --sync

# install Mackup using Python 3.11 to avoid compatibility issues
# NOTE: Mackup's dependency, docopt, is incompatible with Python 3.12 and above, see: https://github.com/lra/mackup/issues/1986

pipx install --python python3.11 mackup

mackup restore --force && mackup uninstall --force

# terminal

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || iterm: terminal client
#  || terminal-notifier: notification
# //

brew install \
  iterm2 \
  terminal-notifier ||
  true

# reset the shell environment

rm -f ~/.zcompdump
compinit
chmod go-w "$(brew --prefix)/share"
chmod -R go-w "$(brew --prefix)/share/zsh"

