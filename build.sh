#!/usr/bin/env bash
set -eo pipefail

cd "$(dirname "$0")"

if ! command -v colcon >/dev/null 2>&1; then
    echo "colcon is missing. Run ./run_docker.sh first." >&2
    exit 1
fi
if [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
fi

core_dir="$(pwd)/src/stingray_core"
patch_file="$(pwd)/patches/stingray_core-platform-config.patch"
if [ ! -f "$core_dir/src/stingray_core_sensors/parser/src/main.cpp" ]; then
    echo "Initialize the pinned Nulina core: git submodule update --init --recursive" >&2
    exit 1
fi

# Older Nulina core revisions need the backport. Newer revisions already
# understand STINGRAY_CONFIG_DIR (the helper moved to utils/save_params.py).
if grep -Rqs 'STINGRAY_CONFIG_DIR' \
    "$core_dir/src/stingray_core_control/stingray_core_control"; then
    : # Native support is present.
elif git -C "$core_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
    : # Already applied; preserve all other local changes.
elif git -C "$core_dir" apply --check "$patch_file"; then
    git -C "$core_dir" apply "$patch_file"
else
    echo "Cannot apply the platform config patch. Check the stingray_core revision and local changes." >&2
    exit 1
fi

# Explicit paths avoid obsolete packages left by switching from the Welt core.
# AH127C uses system LibSerial, not the unrelated serial submodule.
packages=(
    asio_cmake_module
    io_context
    serial_driver
    stingray_core_communication
    stingray_core_control
    ms5837_pressure_sensor
    power_control
    parser
    dvl_msgs
    vectornav_msgs
    stingray_core_localization
)
package_paths=(
    "$core_dir/src/stingray_core_communication/asio_cmake_module"
    "$core_dir/src/stingray_core_communication/io_context"
    "$core_dir/src/stingray_core_communication/serial_driver"
    "$core_dir/src/stingray_core_communication/stingray_core_communication"
    "$core_dir/src/stingray_core_control"
    "$core_dir/src/stingray_core_sensors/ms5837_pressure_sensor"
    "$core_dir/src/stingray_core_devices/power_control"
    "$core_dir/src/stingray_core_sensors/parser"
    "$core_dir/src/stingray_core_sensors/dvl_msgs"
    "$core_dir/src/stingray_core_sensors/vectornav/vectornav_msgs"
    "$core_dir/src/stingray_core_localization"
)

for package_path in "${package_paths[@]}"; do
    if [ ! -f "$package_path/package.xml" ]; then
        echo "ROS package is missing: $package_path" >&2
        echo "Check the pinned stingray_core revision and initialize its submodules." >&2
        exit 1
    fi
done

colcon build \
    --paths "${package_paths[@]}" src/nulina_bringup \
    --packages-select "${packages[@]}" nulina_bringup \
    "$@"
