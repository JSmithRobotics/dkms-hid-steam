obj-m += hid-steam.o

# Force-included rather than added to hid-steam.c's includes, so the vendored
# driver source stays byte-identical to upstream and tools/update-driver.sh can
# keep re-fetching it verbatim.
ccflags-y += -include $(src)/compat-input-codes.h

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

.PHONY: all clean install uninstall

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean

# Convenience wrappers. install.sh is the supported entry point; these exist so
# `make install` does something unsurprising.
install:
	./install.sh

uninstall:
	./install.sh --uninstall
