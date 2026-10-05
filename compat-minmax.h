/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Before 6.12, max() rejected operands of mixed signedness even when the
 * signed one cannot be negative, and the vendored driver's
 * max(size + 1, len) (int against u32) is one. Compare in the type C's usual
 * arithmetic conversions pick, which is what the relaxed check permits.
 *
 * Force-included from the Makefile, like compat-input-codes.h, so the driver
 * source stays byte-identical to upstream. minmax.h is include-guarded, so the
 * driver's own includes cannot restore the strict definition.
 */
#ifndef HID_STEAM_COMPAT_MINMAX_H
#define HID_STEAM_COMPAT_MINMAX_H

#include <linux/version.h>

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 12, 0)
#include <linux/minmax.h>
#undef max
#define max(x, y) max_t(__typeof__((x) + (y)), x, y)
#endif

#endif /* HID_STEAM_COMPAT_MINMAX_H */
