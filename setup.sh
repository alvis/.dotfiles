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

BASE=$(cd "$(dirname "$0")"; pwd -P)

# function to check if running inside a Docker container
is_container() {
    grep -qE '/docker/|/lxc/' /proc/1/cgroup || [ "$CODESPACES" = "true" ] || [ "$CI" = "true" ]
}

# function to check if running on macOS
is_macos() {
    [[ "$(uname)" == "Darwin" ]]
}

# detect the environment and run the appropriate setup script
if is_container; then
    echo "Detected Docker container environment."
    $BASE/setup/devcontainer.sh
elif is_macos; then
    echo "Detected macOS environment."
    $BASE/setup/macos.sh
else
    echo "Environment not recognized. Exiting..."
    exit 1
fi
