/* SPDX-License-Identifier: GPL-2.0 */
/*
 * Found only on kernels before 6.12, which declare the unaligned accessors in
 * <asm/unaligned.h>. Kbuild searches the kernel's own include/ before ccflags
 * paths, so where a kernel ships <linux/unaligned.h> its copy wins.
 */
#include <asm/unaligned.h>
