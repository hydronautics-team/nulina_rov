#!/usr/bin/env bash
set -e

# Platform wrapper: run Docker from nulina_rov root so whole platform is mounted
cd "$(dirname "$0")"

IMAGE_NAME=${IMAGE_NAME:-stingray_core}
CONTAINER_NAME=${CONTAINER_NAME:-nulina_rov}
ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-1}

export IMAGE_NAME
export CONTAINER_NAME
export ROS_DOMAIN_ID

./src/stingray_core/docker/run.sh bash -lc './run_rov.sh'
