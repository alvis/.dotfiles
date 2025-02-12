#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup an amazing terminal experience on MacOS
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2019 - All Rights Reserved.
# -------------------------------------------------------------------------
#

BASE=$(cd "$(dirname "$0")"; pwd -P)
# temporarily disable the need for typing the sudo password multiple times in the current shell session after it is initially verified

ME=$(whoami)
UUID=$(head /dev/urandom | LC_ALL=C tr -dc 'a-z0-9' | head -c 8)
SUDO_FILE="/etc/sudoers.d/$UUID"
sudo -S -k -- bash -c "{
  echo '$ME ALL=(ALL) NOPASSWD: ALL';
} | sudo tee -a '$SUDO_FILE' >/dev/null"

# explanation:
# -S: allows sudo to read the password from standard input, enabling interactive password entry
# -k: forces sudo to invalidate the current timestamp, requiring a password for the next sudo command
# bash -c: runs a command string to append the temporary configuration to a sudoers file
# /etc/sudoers.d/$UUID: creates a unique temporary file in the sudoers.d directory to avoid modifying the main sudoers file

# set for automatic installation
export NONINTERACTIVE=1

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
source $BASE/../.zshenv

# need to accept the xcode license before things can continue
sudo xcodebuild -license accept || true

# install common essentials
$BASE/common/essential.common.sh
$BASE/common/utility.common.sh
$BASE/common/development.common.sh
$BASE/common/devops.common.sh

# install macos specific essentials
$BASE/macos/essential.macos.sh
$BASE/macos/development.macos.sh
$BASE/macos/editor.macos.sh
$BASE/macos/application.macos.sh

# setup .zshrc

ln -sf $BASE/../.aliases.d ~/.aliases.d
ln -sf $BASE/../.common.zshrc ~/.common.zshrc

# finish the sudo session
sudo rm $SUDO_FILE
sudo -k
