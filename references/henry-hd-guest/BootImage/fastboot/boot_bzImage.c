// Fast bootloader.

#define BLK 4096

typedef unsigned char  u8;
typedef unsigned short u16;
typedef unsigned long  u32;

void readseg(u8*, u32, u32);
void switch_back_to_rmode_and_jmp_setup(void);

void init_ide();

// This function does not return, save bytes by skipping
// any function prologue code.
__attribute__ ((noreturn)) void boot_bzImage(void)
{ 
  u32 kSectors_bytes, setup_sectors;
  u32 offset_to_initrd;
  u32 initrd_size;

  init_ide();

  // First load bzImage's boot-sector to 0x9000.
  readseg((u8 *)0x90000, 512, 0);

  // read setup_sectors at 497 (value NOT including bootsector)
  setup_sectors = (*(u16 *)0x901F0) >> 8;
  setup_sectors <<= 9;
  kSectors_bytes = (*(u32 *)0x901F4) << 4;
  offset_to_initrd = 512 + setup_sectors + kSectors_bytes;
  offset_to_initrd = (offset_to_initrd + 511)/512;
  initrd_size = *((u32 *)(0x7C00 + 0x1FA));

  // Now, load setup to 0x9020
  readseg((u8 *)0x90200, setup_sectors, 512);
  
  // Next, load Kernel to 1MB.
  readseg((u8 *)0x100000, kSectors_bytes, 512 + setup_sectors);

  // Next, load initrd.img to 128MB.
  readseg((u8 *)0x08000000, initrd_size, offset_to_initrd << 9);

  *((u32 *)0x90218) = 0x08000000;   // 128MB
  *((u32 *)0x9021c) = initrd_size;

  // To keep the fastboot loader lean & within 512 bytes, we
  // are hard-coding config options inside Kernel's Setup and
  // Boot block, for eg., video mode is hardcoded to SVGA,
  // Boot-time arguments are being hardcoded both in main Kernel
  // and Setup. Root device setup is not required as we are
  // booting via initrd (rdinit option) and initrd will detect
  // and setup the "root" device.
  // hard-coding loader-type in kernel's boot/header.S
  // *((u8 *)0x90210) = 0x20;

  // Switch back to real-mode and jump to SETUP
  switch_back_to_rmode_and_jmp_setup();
  
  //jmp_setup();
  //__asm__ __volatile__ ("jmp *%0" : : "r"(0x90200));

  // DOES NOT RETURN!!!
  __builtin_unreachable();
}
