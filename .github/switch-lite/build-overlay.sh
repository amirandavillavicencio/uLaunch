#!/usr/bin/env bash
set -euo pipefail
repo=https://github.com/ppkantorski/nx-ovlloader.git
git clone --depth 1 --branch v2.0.3 "$repo" loader
test "$(git -C loader rev-parse HEAD)" = 2b8adf9b974f01ca118d6179eb2b34754d0d630e
case "$1" in
  baseline) defines= ;;
  experimental)
    git -C loader apply "$PWD/.github/switch-lite/overlay.patch"
    defines=-DOVL_PROFILE_HEAP ;;
  *) exit 2 ;;
esac
docker run --rm -v "$PWD/loader:/src" -w /src -e DEVKITA64=/opt/devkitpro/devkitA64 "$DKP_IMG" make build "DEFINES=$defines"
mkdir -p out
cp loader/ovll.nsp out/exefs.nsp
