#!/usr/bin/env bash
# Build one Switch Frame Tap applet-mitm variant on an Ubuntu Actions host.
set -euo pipefail

variant=${1:?expected baseline or experimental}
case "$variant" in baseline|experimental) ;; *) exit 2 ;; esac
here=$(cd "$(dirname "$0")" && pwd)
output="$PWD/out/exefs.nsp"
[[ ! -e "$output" ]] || { echo "Output already exists: $output" >&2; exit 1; }
scratch=$(mktemp -d "${RUNNER_TEMP:-/tmp}/frame-build.XXXXXXXX")
frame="$scratch/frame"
atmosphere="$scratch/Atmosphere-1.12.2"
image=${DKP_IMG:-devkitpro/devkita64@sha256:82575ea78651b530b2e232bb3799cfd1fe331514e053d5f724bb4b28191fb79d}
[[ "$image" =~ (^|@)sha256:[0-9a-f]{64}$ ]] || { echo "Expected a pinned DKP_IMG" >&2; exit 2; }

git clone --quiet --depth 1 --branch v0.7.23 https://github.com/TomasUribe/switch-frame-tap.git "$frame"
[[ $(git -C "$frame" rev-parse HEAD) == a024ac0eca1e22044744ed85fb7c2eb9ad5d34b4 ]]
git clone --quiet --depth 1 --branch 1.12.2 https://github.com/Atmosphere-NX/Atmosphere.git "$atmosphere"
[[ $(git -C "$atmosphere" rev-parse HEAD) == 4e3f37038d9e82dde7054897213ab32b2ecf651f ]]
git -C "$atmosphere" submodule update --init --recursive --depth 1
if [[ "$variant" == experimental ]]; then
    git -C "$frame" apply --check "$here/frame.patch"
    git -C "$frame" apply "$here/frame.patch"
fi

# The release helper patches libstratosphere in the disposable Atmosphere tree.
AMS_TREE="$atmosphere" DKP_IMG="$image" bash "$frame/tier4/applet-mitm/build.sh"
binary="$frame/tier4/applet-mitm/applet-mitm-Atmosphere-1.12.2.nsp"
[[ -s "$binary" && $(head -c 4 "$binary") == PFS0 ]]
install -D -m 0644 "$binary" "$output"
