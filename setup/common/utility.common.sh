#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup for terminal utilities
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2020 - All Rights Reserved.
# -------------------------------------------------------------------------
#

# terminal utilities

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || the_silver_searcher: text searcher
#  || > usage:
#  ||   ag <text>
#  || bat: cat clone with syntax highlighting
#  || csvtojson: convert csv to json
#  || direnv: environment variable manager
#  || eza: modernized version of the classic `ls` command
#  || > eza -l -T -L 2
#  || fswatch: monitor file system changes
#  || fzy: fast fuzzy finder for the terminal
#  || > usage:
#  ||   <command to print content> | fzy
#  || grc: colourise log output
#  || > usage:
#  ||   grc <command to print log>
#  || htop: process monitor
#  || ranger: file manager for the terminal
#  || json2csv: convert json to csv
#  || prettyjson: format json content for better readability
#  || tree: list files as a tree
#  || util-linux: collection of basic system utilities
# //

brew install \
  the_silver_searcher \
  bat \
  direnv \
  eza \
  fswatch \
  jhawthorn/fzy/fzy \
  grc \
  htop \
  ranger \
  tree \
  util-linux ||
  true

npm install -g \
  csvtojson \
  json2csv \
  prettyjson ||
  true

# network utilities

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || autocannon: http stress testing utilities with pipeline and better statistics
#  || hey: http stress testing utilities with http/2 support
#  || httpie: HTTP client
#  || swaks: email sender
#  || usql: universal sql client
#  || telnet: text-oriented TCP/IP client
#  || wget: file downloader
# //

go get -u github.com/rakyll/hey

npm install -g \
  autocannon \
  || true

brew install \
  httpie \
  mycli \
  swaks \
  xo/xo/usql \
  telnet \
  wget ||
  true

# file utilities

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || rar: archive manager
# //

brew install --cask \
  rar \
  || true