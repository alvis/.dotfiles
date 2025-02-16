#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup an amazing terminal experience on dev container
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
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# install all essentials
$BASE/common/essential.common.sh

# install CLI utilities
$BASE/common/utility.common.sh

# install development environments
$BASE/common/development.common.sh

# setup dotfiles

ln -s $(grealpath --relative-to ~ ${BASE}/../.aliases.d) ~/.aliases.d
ln -s $(grealpath --relative-to ~ ${BASE}/../.common.zshrc) ~/.common.zshrc
ln -s $(grealpath --relative-to ~ ${BASE}/../.tmux.conf) ~/.tmux.conf
