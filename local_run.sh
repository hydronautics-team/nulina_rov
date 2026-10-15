#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if [[ "${1:-}" == "--debug" ]]; then
    shift
    set -x
    set -- --debug "$@"
fi

exec ./run_docker.sh ./run_rov.sh "$@"
