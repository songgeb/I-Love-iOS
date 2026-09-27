#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

if ! command -v cloc >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq cloc
fi

if ! command -v shellcheck >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo apt-get install -y -qq shellcheck
fi
