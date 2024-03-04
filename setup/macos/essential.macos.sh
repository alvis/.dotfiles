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

# restore dotfiles
# brew install mackup
pip3 install dotfiles
ln -s $(grealpath --relative-to ~ ${BASH_SOURCE%/*}/../.dotfilesrc) ~/.dotfilesrc
dotfiles --sync
# mackup restore

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
