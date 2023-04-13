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
#  || aws-vault: AWS credential management
#  || > usage
#  ||   - aws-vault login <profile>: open AWS console
#  ||   - aws-vault exec <profile> -- <command>: run with AWS session token
#  || docker: spin up a virtual environment
#  || flux: GitOps for Kubernetes
#  || google-cloud-sdk: CLI for handling GCP resources
#  || helm: application manager for k8s
#  || kind: local K8S installer and manager
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
#  || kubectl: CLI for handling K8S resources
#  || kubespy: observe Kubernetes resources in real time [ EXPERMENTAL ]
#  || derailed/popeye/popeye: live k8s issues monitor  [ EXPERIMENTAL ]
# //

brew install --cask\
  docker\
  || true

brew install\
  awscli\
  aws-vault\
  google-cloud-sdk\
  helm\
  derailed/k9s/k9s\
  fluxcd/tap/flux\
  kind\
  blendle/blendle/kns\
  kubectl\
  kubespy\
  derailed/popeye/popeye\
  || true
