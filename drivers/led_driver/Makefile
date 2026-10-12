obj-m += led_dev.o

KERN_DIR ?= $(HOME)/embedded/F1C200S/kernel/linux-6.14.2

ARCH ?= arm
CROSS_COMPILE ?= arm-linux-gnueabi-

all:
	$(MAKE) -C $(KERN_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KERN_DIR) \
		ARCH=$(ARCH) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		M=$(CURDIR) clean
