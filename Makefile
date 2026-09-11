obj-m += hid-steam.o

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
