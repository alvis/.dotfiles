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

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || homebrew: software package manager
# //

# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
[ -e /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)" || eval "$(/usr/local/bin/brew shellenv)"
echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" > ~/.zprofile

# set PATH for startup scripts loaded via launchctl
sudo launchctl config user path $PATH

# make homebrew 3 compatible with old recipes
brew style --fix

# install essential utilities

brew install\
  coreutils\
  golang\
  python\
  node\
  || true

# configuration files

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || mackup: configuration backup manager
#  || dotfiles: sync .dotfiles to ~/
# //

# restore dotfiles
brew install mackup
pip3 install dotfiles
ln -s $(grealpath --relative-to ~ ${BASH_SOURCE%/*}/../.dotfilesrc) ~/.dotfilesrc
dotfiles --sync
mackup restore

# terminal

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || iterm: terminal client
#  || tmux: terminal multiplexer
#  || terminal-notifier: notification
#  || tpm: tmux plugin manager
#  || maglev: tmux theme
# //

brew install\
  iterm2\
  tmux\
  terminal-notifier\
  || true

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone https://github.com/caiogondim/maglev ~/.tmux/plugins/maglev

# z shell

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || zsh: z shell
#  || zsh-autosuggestions: autosuggest the rest of a command
#  || zsh-completions: additional completion definitions
#  || zsh-syntax-highlighting: highlight commands whilst they are typed
# //

brew install\
  zsh\
  zsh-autosuggestions\
  zsh-completions\
  zsh-syntax-highlighting\
  || true

# oh my zsh
# \\
#  || oh my zsh: zsh plugin manager
#  || bullet-train: bullet train theme
#  || enhanced: cd command with an interactive filter
#  || history-search-multi-word: history searching
#  || notify: desktop notifications for long-running commands
# //

git clone https://github.com/robbyrussell/oh-my-zsh ~/.oh-my-zsh
wget http://raw.github.com/caiogondim/bullet-train-oh-my-zsh-theme/master/bullet-train.zsh-theme -P ~/.oh-my-zsh/custom/themes/
git clone https://github.com/b4b4r07/enhancd ~/.oh-my-zsh/custom/plugins/enhancd
git clone https://github.com/zdharma-continuum/history-search-multi-word ~/.oh-my-zsh/custom/plugins/history-search-multi-word
git clone http://www.github.com/marzocchi/zsh-notify ~/.oh-my-zsh/custom/plugins/notify
