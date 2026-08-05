#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup for development utilities on MacOS
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# source control

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || pinentry-mac: for entering gnupg credential
# //

brew install \
  pinentry-mac \
  || true

# setup pinentry
{
  echo "pinentry-program $(brew --prefix)/bin/pinentry-mac"
  # Keep ordinary GPG cache entries at one hour when they are idle.
  echo "default-cache-ttl 3600"
  # Bound all cached passphrases, including authorize-sign presets, at one year.
  echo "max-cache-ttl 31536000"
  # allow git authorize-sign to seed a cache entry before its timer clears it.
  echo "allow-preset-passphrase"
} > ~/.gnupg/gpg-agent.conf

# github extensions

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || copilot-cli: github copilot cli
#  || gh: github CLI
#  || gh-dash: dashboard for github
# //
brew install copilot-cli gh
gh extension install dlvhdr/gh-dash
