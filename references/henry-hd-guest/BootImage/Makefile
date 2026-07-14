KERNEL=$(KDIR)/arch/x86/boot/bzImage

DONT_COPY_AUDIO_DRIVER_bgp_mac := 1
DONT_COPY_SENSOR_DRIVER_bgp_mac := 1

all: Boot.iso

hyperv: initrd-hyperv.img

initrd-hyperv.img: clean-initrd.img
	mkdir -p initrd/boot/bin initrd/boot/sbin initrd/boot/bstmods

	cp init.sh initrd/boot/init
	chmod +x initrd/boot/init

	cp bstsetconf.sh initrd/boot/bstsetconf.sh
	cp bstconf initrd/boot/bin/bstconf
	cp bstchkdata initrd/boot/bin/bstchkdata
	cp stage2.sh initrd/boot/stage2.sh
	cp bstsetup.env initrd/boot/bstsetup.env
	cp 4-dpi initrd/boot/4-dpi

    #TODO(@hsawhney-bst): Copy hyperv drivers from cp ../Drivers directory
	cp ../../Source/hst/guest/driver/bstpgaipc.ko initrd/boot/bstmods/
	cp ../../Source/vmsg/guest/driver/bstvmsg.ko initrd/boot/bstmods/
	cp ../../Source/inp/guest/driver/bstinput.ko initrd/boot/bstmods/
	cp ../../Source/aud/guest/driver/bstaudio.ko initrd/boot/bstmods/
	cp ../../Source/cam/guest/driver/bstcamera.ko initrd/boot/bstmods/
	cp ../../Source/hst/guest/driver/hvmem.ko initrd/boot/bstmods/

	cp $(KDIR)/drivers/media/v4l2-core/videobuf-core.ko \
	    initrd/boot/bstmods

	cp busybox-ndk initrd/boot/bin/busybox
	cp recovery initrd/boot/bin/recovery
	chmod +x initrd/boot/bin/busybox

	ln -s busybox initrd/boot/bin/sh
	ln -s busybox initrd/boot/bin/insmod
	ln -s busybox initrd/boot/bin/echo

	./initrd-implode.sh initrd initrd.img

clean-initrd.img:
	rm -rf initrd initrd.img

Boot.iso: Boot
	grub-mkrescue -o Boot.iso Boot

clean-Boot.iso:
	rm -f Boot.iso

.PHONY: Boot
Boot: clean-Boot initrd.img $(KERNEL)
	mkdir Boot
	mkdir Boot/boot
	mkdir Boot/boot/grub
	cp $(KERNEL) Boot/boot/bzImage
	cp initrd.img Boot/boot/initrd.img
	cp grub.cfg Boot/boot/grub/grub.cfg

clean-fastboot:
	$(MAKE) -C fastboot clean

build_fastboot: initrd.img $(KERNEL)
	cp $(KERNEL) fastboot
	cp initrd.img fastboot
	$(MAKE) -C fastboot

clean-Boot:
	rm -rf Boot

initrd.img: clean-initrd.img
	mkdir initrd
	mkdir initrd/boot
	mkdir initrd/boot/bin
	mkdir initrd/boot/sbin
	mkdir initrd/boot/bstmods

	cp init.sh initrd/boot/init
	chmod +x initrd/boot/init

	cp bstsetconf.sh initrd/boot/bstsetconf.sh
	cp bstconf initrd/boot/bin/bstconf
	cp bstchkdata initrd/boot/bin/bstchkdata
	cp stage2.sh initrd/boot/stage2.sh
	cp bstsetup.env initrd/boot/bstsetup.env
	cp 4-dpi initrd/boot/4-dpi

	cp ../Drivers/VirtualBox/vboxguest.ko initrd/boot/bstmods/
	cp ../Drivers/VirtualBox/vboxsf.ko initrd/boot/bstmods/
	cp ../../Source/vmsg/guest/driver/bstvmsg.ko initrd/boot/bstmods/
	cp ../../Source/inp/guest/driver/bstinput.ko initrd/boot/bstmods/
ifneq ($(DONT_COPY_AUDIO_DRIVER_$(OEM)),1)
	cp ../../Source/aud/guest/driver/bstaudio.ko initrd/boot/bstmods/
endif
	cp $(KDIR)/drivers/media/v4l2-core/videobuf-core.ko initrd/boot/bstmods
	cp ../../Source/cam/guest/driver/bstcamera.ko initrd/boot/bstmods/
	cp ../../Source/hst/guest/driver/bstpgaipc.ko initrd/boot/bstmods/
	cp ../../Source/hst/guest/driver/hvmem.ko initrd/boot/bstmods/

	cp busybox-ndk initrd/boot/bin/busybox
ifeq ($(IS_64_BUILD),1)
	cp bstreport_64 initrd/boot/bin/bstreport
else
	cp bstreport_32 initrd/boot/bin/bstreport
endif
	cp recovery initrd/boot/bin/recovery
	chmod +x initrd/boot/bin/busybox
	chmod +x initrd/boot/bin/bstreport
	chmod +x initrd/boot/bin/bstconf
	chmod +x initrd/boot/bin/bstchkdata

	ln -s busybox initrd/boot/bin/sh
	ln -s busybox initrd/boot/bin/insmod
	ln -s busybox initrd/boot/bin/echo

	./initrd-implode.sh initrd initrd.img

.FORCE: clean-initrd.img

clean: clean-fastboot clean-initrd.img
