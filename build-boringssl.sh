#!/usr/bin/env bash

DEPS_LOCATION=`pwd`
DESTINATION=boringssl

if [ -f "$DEPS_LOCATION/$DESTINATION/lib/libssl.a" ]; then
    echo "BoringSSL fork already exist. delete $DEPS_LOCATION/$DESTINATION for a fresh checkout."
    exit 0
fi

DEBIAN_VERSION=$(cat /etc/debian_version)
if [[ $DEBIAN_VERSION =~ 9\.* ]]; then
    OS=stretch
elif [[ $DEBIAN_VERSION =~ 8\.* ]]; then
    OS=jessie
else
    OS=linux
fi

REPO=https://boringssl.googlesource.com/boringssl
BRANCH=master
REV=441efad4d7e97f313c7bbfc66252da6fea5c3c7a
HASH=$(echo "${REV}" | cut -c1-7)
PKG=${DESTINATION}-${HASH}-${OS}.tar

function fail_check
{
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "error with $1" >&2
        exit 1
    fi
}

function DownloadBoringSsl()
{
	echo "repo=$REPO rev=$REV branch=$BRANCH"

	mkdir -p $DEPS_LOCATION
	pushd $DEPS_LOCATION

	if [ ! -d "$DESTINATION" ]; then
	    fail_check git clone -b $BRANCH $REPO $DESTINATION
    fi

	pushd $DESTINATION
	fail_check git checkout $REV
	popd
	popd
}

function BuildBoringSsl()
{
	pushd $DEPS_LOCATION
	pushd $DESTINATION

	mkdir build
	pushd build

	fail_check cmake .. -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS="-fPIC" -DCMAKE_CXX_FLAGS="-fPIC"
	fail_check ninja
	mkdir ../lib
	fail_check cp crypto/libcrypto.a ../lib/libcrypto.a
	fail_check cp ssl/libssl.a ../lib/libssl.a
	fail_check cp decrepit/libdecrepit.a ../lib/libdecrepit.a

    popd
	popd
	popd
}

function PackageBoringSsl() {
	pushd $DEPS_LOCATION
	pushd $DESTINATION

	tar -cvf $PKG ./include ./lib
	gzip $PKG

	popd
	popd
}


DownloadBoringSsl
BuildBoringSsl
PackageBoringSsl
