#!/usr/bin/env bash

set -x

# Initialization
REGISTRY_NAME=quay.io
#REGISTRY_NAME=cnfcert-local.redhat.com
REGISTRY=$REGISTRY_NAME/
DIRECTORY=testnetworkfunction/
OPERATOR_BUNDLE_BASE_IMAGE=nginx-operator
OPERATOR_IMAGE=$OPERATOR_BUNDLE_BASE_IMAGE:v0.0.1
OPERATOR_BUNDLE_IMAGE=$OPERATOR_BUNDLE_BASE_IMAGE-bundle:v0.0.1
OPERATOR_BUNDLE_IMAGE_FULL_NAME=$REGISTRY$DIRECTORY$OPERATOR_BUNDLE_IMAGE
OPERATOR_REGISTRY_POD_NAME_FULL=$(echo $OPERATOR_BUNDLE_IMAGE_FULL_NAME | sed 's/[\/|\.|:]/-/g')
export \
	COMMUNITY_OPERATOR_IMAGEREPO=docker.io/hazelcast \
	COMMUNITY_OPERATOR_BASE=hazelcast-platform-operator \
	COMMUNITY_OPERATOR_NAME=hazelcast-platform-operator.v5.10.0 \
	COMMUNITY_OPERATOR_IMAGEVERSION=5.10.0 \
	OPERATOR_IMAGE_FULL_NAME=$REGISTRY$DIRECTORY$OPERATOR_IMAGE \
	SECRET_NAME=foo-cert-sec

export COLLECTOR_URL=https://github.com/test-network-function/collector-deployment.git
# export COLLECTOR_TAG=v0.0.1 # Re-enable this when the version is released

# Truncate registry pod name if more than 63 characters
if [[ ${#OPERATOR_REGISTRY_POD_NAME_FULL} -gt 63 ]]; then
	export OPERATOR_REGISTRY_POD_NAME=${OPERATOR_REGISTRY_POD_NAME_FULL: -63}
else
	export OPERATOR_REGISTRY_POD_NAME=$OPERATOR_REGISTRY_POD_NAME_FULL
fi

# Container executable
CERTSUITE_CONTAINER_CLIENT="docker"
export CONTAINER_CLIENT="${CONTAINER_EXECUTABLE:-$CERTSUITE_CONTAINER_CLIENT}"

# Test Namespace
export CERTSUITE_EXAMPLE_NAMESPACE="${CERTSUITE_EXAMPLE_NAMESPACE:-tnf}"

# catalog source namespace
export CATALOG_NAMESPACE="${CATALOG_NAMESPACE:-$CERTSUITE_EXAMPLE_NAMESPACE}"

# Creates namespace if it does not exist.
oc create \
	namespace "$CERTSUITE_EXAMPLE_NAMESPACE" \
	--dry-run=client \
	--output yaml |
	oc apply --filename -

# Debug on-demand by default
export ON_DEMAND_DEBUG_PODS="${ON_DEMAND_DEBUG_PODS:-true}"

#Partner repo
export CERTSUITE_PARTNER_REPO="${CERTSUITE_PARTNER_REPO:-quay.io/testnetworkfunction}"
export CERTSUITE_DEPLOYMENT_TIMEOUT="${CERTSUITE_DEPLOYMENT_TIMEOUT:-240s}"

# Number of multus interfaces to create
MULTUS_IF_NUM="${MULTUS_IF_NUM:-2}"

CERTSUITE_NON_OCP_CLUSTER=false
MULTUS_ANNOTATION=""
NET_NAME="mynet"

# Checks for non-OCP cluster.
oc version | grep Server >/dev/null || {
	printf 'Non-OCP cluster.\n'
	CERTSUITE_NON_OCP_CLUSTER=true
}

# create Multus annotations
create_multus_annotation() {
	for ((NUM = 0; NUM < MULTUS_IF_NUM; NUM++)); do
		MULTUS_ANNOTATION="${MULTUS_ANNOTATION}${NET_NAME}-$1-${NUM},"
	done
}

# Only add annotation in non OCP clusters
if $CERTSUITE_NON_OCP_CLUSTER; then
	echo 'creating multus annotations'

	# IPv4
	create_multus_annotation ipv4

	# IPv6
	create_multus_annotation ipv6

	# Remove the last character (comma)
	#  https://unix.stackexchange.com/questions/144298/delete-the-last-character-of-a-string-using-string-manipulation-in-shell-script
	MULTUS_ANNOTATION="${MULTUS_ANNOTATION%?}"
fi

CPU_ARCH="$(uname -m)"
export CPU_ARCH
echo "CPU_ARCH=$CPU_ARCH"
