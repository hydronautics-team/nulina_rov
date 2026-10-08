#!/usr/bin/env bash
set -eo pipefail

cd "$(dirname "$0")"

IMAGE_NAME="${IMAGE_NAME:-nulina_rov:humble}"
CONTAINER_NAME="${CONTAINER_NAME:-nulina_rov}"

# The upstream script hard-codes its container name and ROS domain.
if [ "$#" -eq 0 ]; then
    set -- bash
fi

exec docker run -it --rm \
    --name "$CONTAINER_NAME" \
    --privileged \
    --network host \
    --workdir /stingray_core \
    --volume "$(pwd):/stingray_core" \
    --volume /dev:/dev \
    --volume /tmp/.X11-unix:/tmp/.X11-unix \
    --env "DISPLAY=${DISPLAY:-}" \
    --env "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-1}" \
    --env "ROS_LOCALHOST_ONLY=${ROS_LOCALHOST_ONLY:-0}" \
    --env STINGRAY_CONFIG_DIR=/stingray_core/src/nulina_config/control \
    --entrypoint /stingray_core/docker/entrypoint.sh \
    "$IMAGE_NAME" "$@"
