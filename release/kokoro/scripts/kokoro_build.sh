#!/bin/bash
set -euo pipefail
set -x

echo "${ADAPTER_DIR:-""}"

current_dir="$(pwd)"
script_dir="$( cd "$( dirname "$0" )" && pwd )"
google3_dir=$(echo "${script_dir}" | sed "s,^\(.*\)google3.*$,\1google3,")
adapters_dir="${google3_dir}/third_party/objective_c/gma_sdk_mediation/adapters"
temp_dir="${KOKORO_ARTIFACTS_DIR}/temp"
output_dir="${KOKORO_ARTIFACTS_DIR}/output"
