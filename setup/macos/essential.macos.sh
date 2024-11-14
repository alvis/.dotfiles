#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Install essential utilites
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# set PATH for startup scripts loaded via launchctl
sudo launchctl config user path $PATH

# configuration files

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || mackup: configuration backup manager
#  || dotfiles: sync .dotfiles to ~/
# //

# install Mackup using Python 3.11 to avoid compatibility issues
# NOTE: Mackup's dependency, docopt, is incompatible with Python 3.12 and above, see: https://github.com/lra/mackup/issues/1986

pipx install --python python3.11 mackup

mackup restore --force && mackup uninstall --force

# restore dotfiles
pipx install dotfiles
ln -s $(grealpath --relative-to ~ ${BASH_SOURCE%/*}/../.dotfilesrc) ~/.dotfilesrc
dotfiles --sync

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
