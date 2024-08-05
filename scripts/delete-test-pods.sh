#!/usr/bin/env bash

# Initialization
SCRIPT_DIR=$(dirname "$0")

# shellcheck disable=SC1091 # Not following.
source "$SCRIPT_DIR"/init-env.sh

# Delete test deployment
oc delete deployment.apps/test -n "${CERTSUITE_EXAMPLE_NAMESPACE}" --ignore-not-found=true
