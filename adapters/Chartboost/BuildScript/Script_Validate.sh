#!/bin/bash

# Fail the build if the adapter version has drifted across its sources of truth
# (Swift constant, Adapter.xcconfig, podspec). See validate_version_consistency.sh.
"$(dirname "$0")/validate_version_consistency.sh"
