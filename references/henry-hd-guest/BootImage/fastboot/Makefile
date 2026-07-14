CC = gcc
AS = gas
LD = ld
OBJCOPY = objcopy
OBJDUMP = objdump
# CFLAGS for fastboot
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -Os -Wall -MD -ggdb -m32 -Werror -fomit-frame-pointer -mno-accumulate-outgoing-args -fno-unwind-tables -fno-asynchronous-unwind-tables
#CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -fvar-tracking -fvar-tracking-assignments -O0 -g -Wall -MD -gdwarf-2 -m32 -Werror -fno-omit-frame-pointer
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
# FreeBSD ld wants ``elf_i386_fbsd''
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)

all: fastboot

clean:
	rm -f *.o
	rm -f *.d
	rm -f bzImage
	rm -f *.asm
	rm -f *.vdi
	rm -f *.img
	rm -f fastbootblock
	rm -f fastboot.vdi

fastboot: fastboot_asm.S fastboot_main.c
	rm -f fastboot.vdi
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -c fastboot_main.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c fastboot_asm.S
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c boot_bzImage.c
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o fastbootblock.o fastboot_asm.o fastboot_main.o boot_bzImage.o
	$(OBJDUMP) -S fastbootblock.o > fastbootblock.asm
	$(OBJCOPY) -S -O binary -j .text fastbootblock.o fastbootblock
	./sign.pl fastbootblock
	dd if=/dev/zero of=fastboot.img count=12000
	dd if=fastbootblock of=fastboot.img bs=512 conv=notrunc
	bash -x ./cp_bzImage_initrd.sh
ifeq ($(IMAGE),Nougat32)
	VBoxManage convertfromraw --uuid 4da0cf19-7a5d-474d-9748-2c31c11fbbd6 fastboot.img.padded fastboot.vdi
else ifeq ($(IMAGE),Nougat64)
	VBoxManage convertfromraw --uuid 40cb560f-0b78-4866-b757-e57cb88d185a fastboot.img.padded fastboot.vdi
else ifeq ($(IMAGE),Pie64)
	VBoxManage convertfromraw --uuid 20131fc8-e33c-43ec-bb32-24b184a349f7 fastboot.img.padded fastboot.vdi
else ifeq ($(IMAGE),Rvc64)
	VBoxManage convertfromraw --uuid 0a9e5e2c-8f14-4bcf-9192-cf8c8d1e7fb5 fastboot.img.padded fastboot.vdi
else ifeq ($(IMAGE),Tiramisu64)
	VBoxManage convertfromraw --uuid 91b80c95-aa7d-459d-93e4-c479f5babbb7 fastboot.img.padded fastboot.vdi
else ifeq ($(IMAGE),Baklava64)
	VBoxManage convertfromraw --uuid 7c4e9a21-3b6f-4d8e-a1c2-5f0e8d3b7a94 fastboot.img.padded fastboot.vdi
else
	VBoxManage convertfromraw --uuid 5a7e1b10-3459-48c5-a885-a577bc05e57c fastboot.img.padded fastboot.vdi
endif
