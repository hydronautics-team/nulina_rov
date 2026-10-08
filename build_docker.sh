#!/usr/bin/env bash
set -eo pipefail

cd "$(dirname "$0")"
exec docker build --tag "${IMAGE_NAME:-nulina_rov:humble}" "$@" docker
