#!/bin/bash
#
# Fails if the Chartboost adapter version disagrees across its sources of truth.
#
# The adapter version is hand-maintained in three places that must stay in sync:
#   1. GADMAdapterChartboostConstants.swift  -> adapterVersion  (4-part "A.B.C.D",
#      the ONLY value reported at runtime to GMA and sent to Chartboost)
#   2. Configuration/Adapter.xcconfig        -> MARKETING_VERSION ("A.B.C") and
#      CURRENT_PROJECT_VERSION (packed int A*10000 + B*100 + C)
#   3. CocoaPods/...podspec.json             -> version ("A.B.C.D")
#
# These drifted once (the Swift migration shipped the previous release's value),
# which is what this guard exists to catch. Run from CI on every PR and from the
# Xcode build phase (Script_Validate.sh). Uses only grep/sed so it needs no
# interpreter beyond bash.

set -euo pipefail

# Adapter root, resolved from this script's own location so it works both from a
# CI checkout and from an Xcode build phase regardless of the working directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADAPTER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

SWIFT_FILE="${ADAPTER_DIR}/ChartboostAdapter/GADMAdapterChartboostConstants.swift"
XCCONFIG_FILE="${ADAPTER_DIR}/Configuration/Adapter.xcconfig"
PODSPEC_FILE="${ADAPTER_DIR}/CocoaPods/GoogleMobileAdsMediationChartboost.podspec.json"

for f in "${SWIFT_FILE}" "${XCCONFIG_FILE}" "${PODSPEC_FILE}"; do
  if [[ ! -f "${f}" ]]; then
    echo "error: expected file not found: ${f}" >&2
    exit 1
  fi
done

# Swift constant: the 4-part dotted number on the adapterVersion line.
SWIFT_VER="$(grep 'adapterVersion' "${SWIFT_FILE}" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)"

# Podspec: the first "version" field.
POD_VER="$(grep -m1 '"version"' "${PODSPEC_FILE}" | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)"

# xcconfig: value after '=' for each key.
MARKETING_VERSION="$(grep -E '^MARKETING_VERSION[[:space:]]*=' "${XCCONFIG_FILE}" | sed -E 's/^[^=]*=[[:space:]]*//' | tr -d '[:space:]')"
CURRENT_PROJECT_VERSION="$(grep -E '^CURRENT_PROJECT_VERSION[[:space:]]*=' "${XCCONFIG_FILE}" | sed -E 's/^[^=]*=[[:space:]]*//' | tr -d '[:space:]')"

if [[ -z "${SWIFT_VER}" || -z "${POD_VER}" || -z "${MARKETING_VERSION}" || -z "${CURRENT_PROJECT_VERSION}" ]]; then
  echo "error: failed to extract one or more version values" >&2
  echo "  swift adapterVersion    = '${SWIFT_VER}'" >&2
  echo "  podspec version         = '${POD_VER}'" >&2
  echo "  MARKETING_VERSION       = '${MARKETING_VERSION}'" >&2
  echo "  CURRENT_PROJECT_VERSION = '${CURRENT_PROJECT_VERSION}'" >&2
  exit 1
fi

fail() {
  echo "error: Chartboost adapter version mismatch." >&2
  echo "$1" >&2
  echo "  swift adapterVersion    = ${SWIFT_VER}   (${SWIFT_FILE})" >&2
  echo "  podspec version         = ${POD_VER}   (${PODSPEC_FILE})" >&2
  echo "  MARKETING_VERSION       = ${MARKETING_VERSION}   (${XCCONFIG_FILE})" >&2
  echo "  CURRENT_PROJECT_VERSION = ${CURRENT_PROJECT_VERSION}   (${XCCONFIG_FILE})" >&2
  exit 1
}

# Rule 1: podspec version must exactly match the runtime Swift constant.
if [[ "${POD_VER}" != "${SWIFT_VER}" ]]; then
  fail "rule 1: podspec version must equal the Swift adapterVersion (4-part)."
fi

# Split the canonical Swift version into components A.B.C.D.
IFS='.' read -r A B C D <<< "${SWIFT_VER}"
if [[ -z "${A}" || -z "${B}" || -z "${C}" || -z "${D}" ]]; then
  fail "adapterVersion '${SWIFT_VER}' is not the expected 4-part A.B.C.D form."
fi

# Rule 2: MARKETING_VERSION must equal the first three components.
EXPECTED_MARKETING="${A}.${B}.${C}"
if [[ "${MARKETING_VERSION}" != "${EXPECTED_MARKETING}" ]]; then
  fail "rule 2: MARKETING_VERSION must equal ${EXPECTED_MARKETING} (first 3 components of adapterVersion)."
fi

# Rule 3: CURRENT_PROJECT_VERSION must equal the packed integer A*10000 + B*100 + C.
EXPECTED_CPV="$(printf '%d%02d%02d' "${A}" "${B}" "${C}")"
if [[ "${CURRENT_PROJECT_VERSION}" != "${EXPECTED_CPV}" ]]; then
  fail "rule 3: CURRENT_PROJECT_VERSION must equal ${EXPECTED_CPV} (A*10000 + B*100 + C)."
fi

echo "Chartboost adapter version consistent: ${SWIFT_VER} (MARKETING_VERSION=${MARKETING_VERSION}, CURRENT_PROJECT_VERSION=${CURRENT_PROJECT_VERSION})"
