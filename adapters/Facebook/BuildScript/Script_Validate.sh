#!/bin/bash

# copybara:strip_begin
set -o errexit
set -o nounset
set -o xtrace

SCRIPT_PATH="$( cd "$( dirname "$0" )" && pwd )"
GOOGLE3_ROOT="${SCRIPT_PATH}/../../../../../../../google3"
NONAGON_ROOT="${GOOGLE3_ROOT}/googlemac/iPhone/GoogleAds/GoogleMobileAdsNonagon/Nonagon"
PROHIBIT_PATTERNS_SCRIPT="${NONAGON_ROOT}/scripts/prohibit_patterns.sh"

bash "${PROHIBIT_PATTERNS_SCRIPT}" "${SCRIPT_PATH}/../Public"
bash "${PROHIBIT_PATTERNS_SCRIPT}" "${SCRIPT_PATH}/../FacebookAdapter"
# copybara:strip_end
