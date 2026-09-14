/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Stand-in for the input event codes the vendored driver uses but a target
 * kernel's uapi headers may predate.
 *
 * BTN_GRIPL..BTN_GRIPR2 sit immediately after BTN_DPAD_RIGHT (0x223) and
 * reached include/uapi/linux/input-event-codes.h after 6.12, so building
 * hid-steam.c from a later ref against 6.12 headers fails on four undeclared
 * identifiers -- Armbian's 6.12.44-current-rockchip64 among them.
 *
 * Force-included from the Makefile rather than included by the driver, so the
 * vendored source stays byte-identical to upstream. Guarded individually: a
 * kernel whose headers already define these must keep its own values, since
 * these numbers are the wire format between the driver and every userspace
 * reader of the device's capability bitmap.
 *
 * Values from include/uapi/linux/input-event-codes.h at the ref in UPSTREAM_REF.
 */
#ifndef HID_STEAM_COMPAT_INPUT_CODES_H
#define HID_STEAM_COMPAT_INPUT_CODES_H

#include <linux/input-event-codes.h>

#ifndef BTN_GRIPL
#define BTN_GRIPL 0x224
#endif
#ifndef BTN_GRIPR
#define BTN_GRIPR 0x225
#endif
#ifndef BTN_GRIPL2
#define BTN_GRIPL2 0x226
#endif
#ifndef BTN_GRIPR2
#define BTN_GRIPR2 0x227
#endif

#endif /* HID_STEAM_COMPAT_INPUT_CODES_H */
