#!/usr/bin/env bash
#
# update-driver.sh — re-vendor hid-steam.c from an upstream kernel ref.
#
#   tools/update-driver.sh v7.4
#
# Refuses a ref whose driver would not build here, so a bump cannot silently
# vendor something the target kernels cannot compile.

set -euo pipefail

REF="${1:?usage: $0 <kernel tag, e.g. v7.3-rc1>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RAW="https://raw.githubusercontent.com/torvalds/linux/${REF}/drivers/hid/hid-steam.c"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL "$RAW" -o "$tmp" || { echo "no hid-steam.c at ${REF}" >&2; exit 1; }

grep -q USB_DEVICE_ID_STEAM_CONTROLLER_PROTEUS "$tmp" ||
	{ echo "${REF} has no PROTEUS entry: it predates 2026-controller support" >&2; exit 1; }

# kzalloc_obj() and friends postdate the kernels this package targets. A ref
# that uses them compiles on none of them, which is worth catching here rather
# than in somebody's dkms build log.
if grep -qE '\bk[zm]alloc_obj\(' "$tmp"; then
	echo "${REF} uses kzalloc_obj(), which kernels below 7.3 do not have." >&2
	echo "Vendor an earlier ref, or raise BUILD_EXCLUSIVE_KERNEL_MIN and drop this check." >&2
	exit 1
fi

cp "$tmp" "${HERE}/hid-steam.c"
echo "$REF" > "${HERE}/UPSTREAM_REF"
echo "Vendored $(wc -l < "${HERE}/hid-steam.c") lines from ${REF}."
echo "Check hid-ids.h still covers every USB_*_ID_* the driver references:"
grep -ohE 'USB_(VENDOR|DEVICE)_ID_[A-Z0-9_]+' "${HERE}/hid-steam.c" | sort -u
