all: fastboot.vdi

hyperv:
	$(MAKE) -C Drivers hyperv 
	$(MAKE) -C BootImage hyperv

fastboot.vdi:
	$(MAKE) -C Drivers all
	$(MAKE) -C BootImage build_fastboot

Boot.iso:
	$(MAKE) -C Drivers all
	$(MAKE) -C BootImage Boot.iso

clean:
	$(MAKE) -C Drivers clean
	$(MAKE) -C BootImage clean
