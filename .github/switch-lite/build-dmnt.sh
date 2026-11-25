#!/usr/bin/env bash
set -euo pipefail

variant=${1:?Specify baseline or experimental}
case "$variant" in
    baseline|experimental) ;;
    *) echo "Expected baseline or experimental" >&2; exit 2 ;;
esac
: "${DKP_IMG:?Set DKP_IMG to the devkitPro image with a SHA256 digest}"
[[ "$DKP_IMG" =~ @sha256:[0-9a-f]{64}$ ]]
patch_dir=$(cd "$(dirname "$0")" && pwd)
output_dir=$(pwd)/out
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
revision=6b0c077b4c608a3a2ee712b8dc35fee87ceb62e8
git init -q "$work/src"
git -C "$work/src" fetch --depth 1 https://github.com/Atmosphere-NX/Atmosphere.git "$revision"
git -C "$work/src" checkout -q -b switch-lite-build FETCH_HEAD
[[ $(git -C "$work/src" rev-parse HEAD) == "$revision" ]]
if [[ "$variant" == experimental ]]; then
    git -C "$work/src" apply --check "$patch_dir/dmnt.patch"
    git -C "$work/src" apply "$patch_dir/dmnt.patch"
fi
mkdir -p "$output_dir"
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e TZ=UTC -e LC_ALL=C \
    -e SOURCE_DATE_EPOCH="$(git -C "$work/src" show -s --format=%ct HEAD)" \
    -v "$work/src:/src" -v "$output_dir:/out" -w /src "$DKP_IMG" bash -euc '
        make -C stratosphere/dmnt -j"$(nproc)" nx_release
        shopt -s nullglob
        files=(stratosphere/dmnt/out/*/release/dmnt.nsp)
        [[ ${#files[@]} == 1 && -s ${files[0]} ]]
        install -m 0644 "${files[0]}" /out/exefs.nsp
    '
