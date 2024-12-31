#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup for development utilities for all platforms
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# source control

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || git: for source control
#  || git-extra: for useful git utilities
#  || git-lfs: for large assets
#  || git-redate: change the dates of several git commits
#  || > usage:
#  ||   git redate --commits <number of commits>
#  ||   git redate --all
#  || gnupg: for key management
#  || sops: for secret storage in a repo
# //

brew install \
  git \
  git-extras \
  git-lfs \
  potatolabs/git-redate/git-redate \
  gnupg \
  sops \
  || true
git lfs install

# update git-redate to the latest version
sudo rm -f $(greadlink -f /usr/local/bin/git-redate)
sudo curl -Lo $(greadlink -f /usr/local/bin/git-redate) \
  https://raw.githubusercontent.com/PotatoLabs/git-redate/master/git-redate
sudo chmod 555 $(greadlink -f /usr/local/bin/git-redate)

# node

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || nvm: manage node environment
#  || github-copilot-cli: command line interface for github copilot
# //

git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm

npm install -g @githubnext/github-copilot-cli

# python

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || poetry: manage python environment
# //

pipx install \
  poetry \
  || true