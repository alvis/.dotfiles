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

# set for automatic installation
export NONINTERACTIVE=1

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"

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

ln -sf $BASE/../.common.zshrc ~/.common.zshrc
