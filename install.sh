#!/usr/bin/env bash
#
# install.sh — install the vendored hid-steam driver as a DKMS module.
#
# Run on the machine the controller is plugged into. Prompts for sudo; do not
# run it inside a container, which has no module tree or kernel build tree.
#
#   ./install.sh              # install
#   ./install.sh --uninstall
#   KVER=7.2.1-arch1-1 ./install.sh   # build for a kernel that is not booted

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_NAME="$(sed -n 's/^PACKAGE_NAME="\(.*\)"$/\1/p' "${HERE}/dkms.conf")"
PKG_VERSION="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"$/\1/p' "${HERE}/dkms.conf")"
SRC_DIR="/usr/src/${PKG_NAME}-${PKG_VERSION}"
KVER="${KVER:-$(uname -r)}"

BOLD=$'\033[1m'; RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; OFF=$'\033[0m'
say()  { printf '%s==>%s %s\n' "$BOLD" "$OFF" "$*"; }
ok()   { printf '%s==> %s%s\n' "$GRN" "$*" "$OFF"; }
warn() { printf '%s==> %s%s\n' "$YEL" "$*" "$OFF" >&2; }
die()  { printf '%s==> %s%s\n' "$RED" "$*" "$OFF" >&2; exit 1; }

if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
	die "You are inside a container. Kernel modules are built and installed on the host."
fi

uninstall() {
	say "Removing ${PKG_NAME}/${PKG_VERSION}"
	if sudo dkms status -m "$PKG_NAME" 2>/dev/null | grep -q .; then
		sudo dkms remove -m "$PKG_NAME" -v "$PKG_VERSION" --all || true
	fi
	sudo rm -rf "$SRC_DIR"
	sudo depmod -a "$KVER"
	ok "Removed. The kernel's own hid_steam takes over again on reload or reboot."
	exit 0
}
[ "${1:-}" = "--uninstall" ] && uninstall

# Ask the running kernel's module which devices it claims, rather than comparing
# version numbers: a distro may carry the patch at any version, and the modalias
# table is what actually decides whether a device binds.
already_supported() {
	modinfo -k "$KVER" hid_steam 2>/dev/null |
		grep -qiE 'alias:.*v0000?28DEp0000?130[2-5]'
}

if already_supported && ! sudo dkms status -m "$PKG_NAME" 2>/dev/null | grep -q .; then
	ok "hid_steam on ${KVER} already claims the 2026 controllers. Nothing to install."
	exit 0
fi

command -v dkms >/dev/null || die "dkms is not installed (Arch: sudo pacman -S dkms; Debian: sudo apt install dkms)"
KBUILD="/usr/lib/modules/${KVER}/build"
[ -d "$KBUILD" ] || KBUILD="/lib/modules/${KVER}/build"
[ -d "$KBUILD" ] || die "no kernel build tree for ${KVER} (Arch: linux-headers; Debian: linux-headers-${KVER})"

LOCKDOWN="$(cat /sys/kernel/security/lockdown 2>/dev/null || echo '[none]')"
case "$LOCKDOWN" in
	*"[none]"*) ;;
	*) warn "Kernel lockdown is active (${LOCKDOWN}): an unsigned module will be refused. Sign it with your MOK or disable Secure Boot." ;;
esac

say "Installing sources to ${SRC_DIR}"
sudo rm -rf "$SRC_DIR"
sudo install -d "$SRC_DIR"
sudo install -m 644 "${HERE}/hid-steam.c" "${HERE}/hid-ids.h" "${HERE}/Makefile" "${HERE}/dkms.conf" "$SRC_DIR/"

say "Building for ${KVER} (driver from $(cat "${HERE}/UPSTREAM_REF"))"
sudo dkms add -m "$PKG_NAME" -v "$PKG_VERSION" 2>/dev/null || true
sudo dkms install -m "$PKG_NAME" -v "$PKG_VERSION" -k "$KVER" --force

say "Loading"
sudo modprobe -r hid_steam 2>/dev/null || true
sudo modprobe hid_steam
sudo modprobe joydev 2>/dev/null || true

# A device already bound to hid-generic stays there until something moves it;
# rebinding is what replugging the receiver would otherwise do for you.
shopt -s nullglob
rebound=0
for dev in /sys/bus/hid/drivers/hid-generic/*:28DE:*; do
	id="${dev##*/}"
	echo "$id" | sudo tee /sys/bus/hid/drivers/hid-generic/unbind >/dev/null 2>&1 || continue
	echo "$id" | sudo tee /sys/bus/hid/drivers_probe >/dev/null 2>&1 || true
	rebound=$((rebound + 1))
done
[ "$rebound" -gt 0 ] && say "Rebound ${rebound} Valve HID interface(s)"
sleep 1

if compgen -G "/dev/input/js*" >/dev/null; then
	ok "Joystick device present:"
	ls -l /dev/input/js* 2>/dev/null || true
else
	warn "No /dev/input/js* yet. Replug the receiver; if it still does not appear, read 'dmesg | tail -40' and 'cat /sys/bus/hid/devices/*28DE*/driver'."
fi
say "dkms rebuilds this on each kernel update, and skips it from 7.3 on. Undo: ./install.sh --uninstall"
