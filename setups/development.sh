#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup for development utilities
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# Source Control

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
#  || pinentry-mac: for entering gnupg credential 
# //

brew install\
  git\
  git-extras\
  git-lfs\
  potatolabs/git-redate/git-redate\
  gnupg\
  pinentry-mac\
  && true
git lfs install

# update git-redate to the latest version
rm -f $(greadlink -f /usr/local/bin/git-redate)
curl -Lo $(greadlink -f /usr/local/bin/git-redate)\
  https://raw.githubusercontent.com/PotatoLabs/git-redate/master/git-redate
chmod 555 $(greadlink -f /usr/local/bin/git-redate)

# Node

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || nvm: manage node environment
# //

git clone https://github.com/lukechilds/zsh-nvm ~/.oh-my-zsh/custom/plugins/zsh-nvm
nvm alias default system

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || miniconda: manage python environmemnt
# //

# Python

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || miniconda: manage python environmemnt
# //

brew cask install\
  miniconda\
  && true

# setup python environments
conda env create -f environments/python/datascience.yaml
python -m ipykernel install --user --name datascience --display-name "Data Science"

# iOS

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || cocoapods: manages library dependencies for xcode projects
# //

sudo gem install cocoapods
