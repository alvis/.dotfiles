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
#  || awscli: CLI for handling AWS resources
#  || google-cloud-sdk: CLI for handling GCS resources
#  || docker: docker for MacOS
#  || kubernetes-cli: CLI for handling K8S resources
# //

brew install\
  awscli\
  kubernetes-cli\
  && true

brew cask install\
  docker\
  google-cloud-sdk\
  && true
