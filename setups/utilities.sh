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
#  || buku: bookmark manager
#  || csvtojson: convert csv to json
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
#  || rename: renames files according to modification rules
#  || > see: http://plasmasturm.org/code/rename
#  || tree: list files as a tree
# //

brew install\
  the_silver_searcher\
  buku\
  jhawthorn/fzy/fzy\
  grc\
  htop\
  ranger\
  rename\
  tree\
  || true

npm install -g\
  csvtojson\
  json2csv\
  prettyjson\
  || true

# network utilities

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\
#  || hey: http stress testing utilities
#  || httpie: HTTP client
#  || mycli: mysql client
#  || swaks: email sender
#  || telnet: text-oriented TCP/IP client
#  || wget: file downloader 
# //

go get -u github.com/rakyll/hey

brew install\
  httpie\
  mycli\
  swaks\
  telnet\
  wget\
  || true
