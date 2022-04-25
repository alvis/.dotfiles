#!/bin/bash
#
#                            *** MIT LICENSE ***
# -------------------------------------------------------------------------
# This code may be modified and distributed under the MIT license.
# See the LICENSE file for details.
# -------------------------------------------------------------------------
#
# @summary   Setup script for an amazing terminal experience
#
# @author    Alvis HT Tang <alvis@hilbert.space>
# @license   MIT
# @copyright Copyright (c) 2019 - All Rights Reserved.
# -------------------------------------------------------------------------
#

BASE=${BASH_SOURCE%/*}

# need to accept the xcode license before things can continue
sudo xcodebuild -license accept || true 

# install all essentials
$BASE/setups/essentials.sh

# install CLI utilities
$BASE/setups/utilities.sh

# install development environments
$BASE/setups/development.sh

# install editors
$BASE/setups/editors.sh

# install devops utilities
$BASE/setups/devops.sh