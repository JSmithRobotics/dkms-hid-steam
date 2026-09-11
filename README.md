# dkms-hid-steam

The upstream `hid-steam` driver, packaged with DKMS so kernels that predate the
2026 Steam Controller can drive one.

## Why this exists

Valve's controllers ship in **lizard mode**: the firmware emulates a mouse and a
keyboard until something claims the device over hidraw. The in-kernel
`hid-steam` driver is what claims it and presents a gamepad — but it only
learned the 2026 devices in **Linux 7.3**:

| id | device |
|----|--------|
| `28de:1302` | Steam Controller (2026), wired (Ibex) |
| `28de:1303` | Steam Controller (2026), BLE |
| `28de:1304` | Steam Controller (2026) Puck receiver (Proteus) |
| `28de:1305` | Steam Machine receiver (Nereid) |

On an earlier kernel these fall through to `hid-generic` and stay in lizard
mode, so no `/dev/input/jsX` is ever created. Anything reading the joystick API
— SDL, `joy_node`, `jstest` — has nothing to open, and the symptom is not an
error but a silence.

## Install

```
git clone https://github.com/JSmithRobotics/dkms-hid-steam && cd dkms-hid-steam && ./install.sh
```

Needs `dkms` and the kernel headers **for the running kernel**. Prompts for sudo
rather than wanting to be run as root. Undo with `./install.sh --uninstall`.

Run it on the machine the controller is plugged into. It refuses to run inside a
container, where there is no module tree to install into.

### "no kernel build tree for &lt;your kernel&gt;"

Usually this does not mean the headers are missing. It means they are installed
for a *different* kernel, because a rolling distro moved them forward and
nothing has rebooted since — so installing `linux-headers` again changes
nothing, since that fetches headers for the new kernel too. The script lists
which kernels it can build for, and there are three ways out:

- **Reboot** into the kernel the headers belong to, then run it again. Simplest
  where a reboot is cheap.
- **Build for that kernel now, load it later:** `KVER=<that kernel> ./install.sh`.
  It stops after installing rather than pretending a module built for a kernel
  you are not running can be loaded into the one you are.
- **Install headers matching the running kernel**, if a reboot is not welcome.
  On Arch they are in the [archive](https://archive.archlinux.org/):

  ```
  sudo pacman -U https://archive.archlinux.org/packages/l/linux-headers/linux-headers-$(uname -r | sed 's/-arch/.arch/')-x86_64.pkg.tar.zst
  ```

  Note this pins stale headers that the next `-Syu` will move forward again;
  that is fine, because DKMS rebuilds against whatever kernel is current.

## What makes it safe to leave installed

**It decides whether it is needed by asking, not by guessing.** The check is
whether the running kernel's own `hid_steam` lists a `28de:130x` modalias:

```sh
modinfo hid_steam | grep -iE 'alias:.*v0000?28DEp0000?130[2-5]'
```

A distro that backports the patch is detected however it chose to number the
release, which a version comparison would get wrong.

**It retires itself.** `dkms.conf` sets `BUILD_EXCLUSIVE_KERNEL_MAX="7.3"`, and
those bounds are inclusive — so it builds up to 7.2.999 and stops at 7.3-rc1,
exactly where the driver went in-tree. Past that DKMS skips it gracefully
instead of shadowing a newer driver with this older copy. The floor,
`BUILD_EXCLUSIVE_KERNEL_MIN="6.12"`, is `linux/unaligned.h`, which the driver
includes.

**It survives kernel updates.** `AUTOINSTALL="yes"`, so DKMS rebuilds it rather
than leaving you without a gamepad after the next upgrade.

## The vendored driver

`hid-steam.c` is upstream's, unmodified, from the ref in
[UPSTREAM_REF](UPSTREAM_REF). Re-vendor with:

```
tools/update-driver.sh v7.4
```

That refuses a ref that predates 2026-controller support, and one that uses
`kzalloc_obj()` — which is why the vendored copy is a tag and not `master`. The
driver moved onto that allocator in a treewide refactor after 7.3, and it does
not exist on any kernel this package targets, so `master` compiles on none of
them.

The one addition is [hid-ids.h](hid-ids.h). The real one is private to
`drivers/hid` and ships in no headers package; this stand-in carries the eight
Valve ids the driver references and nothing else. Because the driver's include
is quoted, this copy is what the compiler finds, so the driver source itself
needs no patch.

## Button and axis numbering

A 2026 controller does **not** enumerate like a 2015 one, which matters to
anything holding hardcoded indices.

`joydev` orders a device's capabilities by ascending evdev code, not by the
order the driver registered them. The Ibex path registers `BTN_BASE` (`0x126`),
which sorts below `BTN_A` (`0x130`) — so every button from index 2 up shifts by
one:

| | 2015 | 2026 |
|---|---|---|
| `BTN_A` | 2 | 3 |
| `BTN_TL` | 6 | 7 |
| `BTN_SELECT` | 10 | 11 |
| D-pad | 15–18 | 16–19 |
| grips | — | 20–23 |

It also registers a second trackpad (`ABS_HAT1X/Y`) at axes 6 and 7, pushing the
analog triggers to 8–9. Axes 0–5 are unchanged.

Derived from `steam_input_register()` and `input-event-codes.h`, not measured.
Confirm with `jstest /dev/input/js0` before trusting it.

## Licence

`hid-steam.c` is GPL-2.0+, copyright its upstream authors. Everything else here
is GPL-2.0+ to match, so the whole package can be redistributed as one thing.
