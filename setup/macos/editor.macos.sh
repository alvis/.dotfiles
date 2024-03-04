#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup editors
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# common code analytic tools

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || ispell: spell checking
# //

brew install \
  ispell ||
  true

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || micro: modern terminal-based text editor
#  || nano: simple terminal-based text editor
#  || visual-studio-code: modern GUI-based text editor
# //

brew install \
  micro \
  nano \
  visual-studio-code ||
  true

# setup nano
git clone https://github.com/scopatz/nanorc ~/.nano
~/.nano/install.sh
echo "set autoindent" >> ~/.nanorc
echo "set mouse" >> ~/.nanorc
echo "set smooth" >> ~/.nanorc

# emacs

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || spacemacs: a community-driven emacs distribution
#  || tern: code-analysis engine for emacs
# //

# install spacemacs dependencies
brew install emacs

# install spacemacs as emacs's config
git clone -b develop https://github.com/syl20bnr/spacemacs ~/.emacs.d

# make emacs run as a service
brew services start emacs
