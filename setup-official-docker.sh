#!/bin/bash

# Instructions from https://docs.docker.com/engine/install/ubuntu/

set -euo pipefail

if [ ! -f /etc/os-release ]; then
  echo "Missing /etc/os-release; cannot detect distro." >&2
  exit 1
fi

. /etc/os-release

DOCKER_DISTRO=""
# docker repo path differs between Ubuntu and Debian.
case "${ID:-}" in
  ubuntu) DOCKER_DISTRO="ubuntu" ;;
  debian) DOCKER_DISTRO="debian" ;;
  *)
    # Try to infer from ID_LIKE (e.g. Debian-based derivatives).
    if echo "${ID_LIKE:-}" | grep -qi debian; then
      DOCKER_DISTRO="debian"
    elif echo "${ID_LIKE:-}" | grep -qi ubuntu; then
      DOCKER_DISTRO="ubuntu"
    fi
    ;;
esac

if [ -z "${DOCKER_DISTRO}" ]; then
  echo "Unsupported distro for Docker repo (ID=${ID:-unknown}, ID_LIKE=${ID_LIKE:-unknown})." >&2
  exit 1
fi

CODENAME="${VERSION_CODENAME:-}"
if [ -z "${CODENAME}" ]; then
  # Fallback for some minimal images.
  CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
fi

if [ -z "${CODENAME}" ]; then
  echo "Could not determine VERSION_CODENAME from /etc/os-release." >&2
  exit 1
fi

## remove old unofficial versions
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

## Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

## Add the repository to Apt sources:
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DOCKER_DISTRO} \
  ${CODENAME} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
