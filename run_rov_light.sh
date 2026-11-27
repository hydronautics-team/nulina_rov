#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ "${1:-}" == "--debug" ]]; then
    shift
    set -x
fi
export STINGRAY_CONFIG_DIR="${STINGRAY_CONFIG_DIR:-$(pwd)/src/nulina_config/control}"

set +u
source install/setup.bash
set -u

exec ros2 launch nulina_bringup run_rov.launch.py "$@"
