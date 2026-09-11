/* SPDX-License-Identifier: GPL-2.0+ */
/*
 * Stand-in for drivers/hid/hid-ids.h.
 *
 * That header is private to drivers/hid and ships in no headers package, so an
 * out-of-tree build of hid-steam.c cannot reach it. The driver refers to
 * Valve's own ids and nothing else, so carrying exactly those is enough -- and
 * because the driver's include is quoted, this copy is what the compiler finds
 * and the vendored driver source needs no patch.
 *
 * Values from include/uapi/../drivers/hid/hid-ids.h at the ref in UPSTREAM_REF.
 */
#ifndef HID_IDS_H_FILE
#define HID_IDS_H_FILE

#define USB_VENDOR_ID_VALVE			0x28de
#define USB_DEVICE_ID_STEAM_CONTROLLER		0x1102
#define USB_DEVICE_ID_STEAM_CONTROLLER_WIRELESS	0x1142
#define USB_DEVICE_ID_STEAM_DECK		0x1205
#define USB_DEVICE_ID_STEAM_CONTROLLER_IBEX	0x1302
#define USB_DEVICE_ID_STEAM_CONTROLLER_IBEX_BLE	0x1303
#define USB_DEVICE_ID_STEAM_CONTROLLER_PROTEUS	0x1304
#define USB_DEVICE_ID_STEAM_CONTROLLER_NEREID	0x1305

#endif
