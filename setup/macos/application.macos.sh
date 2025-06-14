#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup for DevOps related utilities
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || 1password-cli: password manager
#  || bartender: menu bar manager
#  || brave-browser: web browser
#  || discord: voice and text chat
#  || google-chrome: web browser
#  || little-snitch: network monitor
#  || notion: note taking
#  || slack: team communication
#  || readdle-spark: email client
#  || telegram: messaging
# //
 
brew install --cask \
  1password-cli \
  bartender \
  brave-browser \
  discord \
  google-chrome \
  little-snitch \
  notion \
  slack \
  readdle-spark \
  telegram \
  || true
