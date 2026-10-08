#!/usr/bin/env bash

set -eo pipefail

cd "$(dirname "$0")"
export STINGRAY_CONFIG_DIR="${STINGRAY_CONFIG_DIR:-$(pwd)/src/nulina_config/control}"

./build.sh
source install/setup.bash

exec ros2 launch nulina_bringup run_rov.launch.py "$@"
