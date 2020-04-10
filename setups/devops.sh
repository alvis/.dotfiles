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
#  || k9s: for probing K8S resource statuses [ EXPERIMENTAL ]
#  || > usage:
#  ||   - k9s: show the console
#  || > keys:
#  ||   - ctrl + a: list all resource types
#  ||   - :<resource type>: list resources of the type
#  || kns: for switching K8S namespaces and context [ EXPERIMENTAL ]
#  || > usage
#  ||   - kns: switch namespace
#  ||   - ktx: switch context
#  || kubernetes-cli: CLI for handling K8S resources
#  || derailed/popeye/popeye: live k8s issues monitor  [ EXPERIMENTAL ]
# //

brew install\
  awscli\
  derailed/k9s/k9s\
  blendle/blendle/kns
  kubernetes-cli\
  derailed/popeye/popeye\
  && true

brew cask install\
  docker\
  google-cloud-sdk\
  && true
