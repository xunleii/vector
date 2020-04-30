#!/usr/bin/env bash

# build-docker.sh
#
# SUMMARY
#
#   Builds the Vector docker images and optionally
#   pushes it to the Docker registry

set -eux

CHANNEL=${CHANNEL:-$(scripts/util/release-channel.sh)}
VERSION=${VERSION:-$(scripts/version.sh)}
DATE=${DATE:-$(date -u +%Y-%m-%d)}
PUSH=${PUSH:-}
PLATFORM=${PLATFORM:-}
REPO="${REPO:-"timberio/vector"}"

#
# Functions
#

build() {
  base=$1
  version=$2

  local tag="$REPO:$version-$base"

  if [ -n "$PLATFORM" ]; then
    export DOCKER_CLI_EXPERIMENTAL=enabled
    docker run --rm --privileged docker/binfmt:66f9012c56a8316f9244ffd7622d7c21c1f6f28d
    docker buildx rm vector-builder || true
    docker buildx create --use --name vector-builder
    docker buildx install

    docker buildx build \
      --platform="$PLATFORM" \
      --tag "$tag" \
      target/artifacts \
      -f "distribution/docker/$base/Dockerfile" ${PUSH:+--push}
  else
    docker build \
      --tag "$tag" \
      target/artifacts \
      -f "distribution/docker/$base/Dockerfile"

    if [ -n "$PUSH" ]; then
      docker push "$tag"
    fi
  fi
}

#
# Build
#

echo "Building $REPO:* Docker images"

if [[ "$CHANNEL" == "latest" ]]; then
  version_exact=$VERSION
  version_minor_x=$(echo $VERSION | sed 's/\.[0-9]*$/.X/g')
  version_major_x=$(echo $VERSION | sed 's/\.[0-9]*\.[0-9]*$/.X/g')

  for i in $version_exact $version_minor_x $version_major_x latest; do
    build alpine $i
    build debian $i
  done
elif [[ "$CHANNEL" == "nightly" ]]; then
  for i in nightly-$DATE nightly; do
    build alpine $i
    build debian $i
  done
elif [[ "$CHANNEL" == "test" ]]; then
  build "${BASE:-"alpine"}" "${TAG:-"test"}"
fi
