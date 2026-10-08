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
if [ ! -f "$core_dir/src/parser/src/main.cpp" ]; then
    echo "Initialize the pinned Nulina core: git submodule update --init --recursive" >&2
    exit 1
fi

# Backport platform config persistence without an unpublished core commit.
if git -C "$core_dir" apply --reverse --check "$patch_file" 2>/dev/null; then
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
)
package_paths=()
for package in "${packages[@]}"; do
    package_paths+=("$core_dir/src/$package")
done

colcon build \
    --paths "${package_paths[@]}" src/nulina_bringup \
    --packages-select "${packages[@]}" nulina_bringup \
    "$@"
