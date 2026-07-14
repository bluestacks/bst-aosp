// fastboot - fastbootloader for android/linux kernel.
// Fits within 1 Disk Sector (512 bytes) and boots
// Linux/Android Kernel ~500-600ms faster than grub2 bootloader.

//
// assembler macros to create x86 segments
//

#define SEG_NULLASM                                             \
        .word 0, 0;                                             \
        .byte 0, 0, 0, 0

// The 0xC0 means the limit is in 4096-byte units
// and (for executable segments) 32-bit mode.
#define SEG_ASM(type,base,lim)                                  \
        .word (((lim) >> 12) & 0xffff), ((base) & 0xffff);      \
        .byte (((base) >> 16) & 0xff), (0x90 | (type)),         \
                (0xC0 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)

#define SEG_ASM16(type,base,lim)                                \
        .word (((lim) >> 12) & 0xffff), ((base) & 0xffff);      \
        .byte (((base) >> 16) & 0xff), (0x90 | (type)),         \
                (0x00 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)

#define STA_X     0x8       // Executable segment
#define STA_E     0x4       // Expand down (non-executable segments)
#define STA_C     0x4       // Conforming code segment (executable only)
#define STA_W     0x2       // Writeable (non-executable segments)
#define STA_R     0x2       // Readable (executable segments)
#define STA_A     0x1       // Accessed

#define CR0_PE          0x00000001      // Protection Enable

# Start the first CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.

.code16                       # Assemble for 16-bit mode
.globl start
start:
  cli                         # BIOS enabled interrupts; disable

.ifdef RELOCATE_FASTBOOTBLOCK

#define BOOTSEG 0x9800

# MBR loaded at 0x07C0. Load entire booter to 0x9800
  movw  $BOOTSEG, %ax
  movw  %ax, %es
  xorw  %bx,%bx          # clear BX = 0
  #---------------------------------------------------
  #  read entire booter in sector#1-8KB to 0x9800
  #---------------------------------------------------
  movw $0x0080, %dx     # dh=head=0, dL=0x80=HD or USB's MBR
  xorw %cx,%cx
  incb %cl             # cyl 0, sector 1
  incb %cl             # cyl 0, sector 2 
  movw $0x0220, %ax    # READ 16 sectors (booter<8KB)
  int  $0x13

  ljmp $BOOTSEG, $next  # CS=BOOTSEG, IP=next

next:
.endif

  # Zero data segment registers DS, ES, and SS.
  xorw    %ax,%ax             # Set %ax to zero
  movw    %ax,%ds             # -> Data Segment
  movw    %ax,%es             # -> Extra Segment
  movw    %ax,%ss             # -> Stack Segment

  # Physical address line A20 is tied to zero so that the first PCs 
  # with 2 MB would run software that assumed 1 MB.  Undo that.
  # use "fast a20 gate" to enable a20 line, keep code lean.

  inb       $0x92,%al              # read configuration port A
  orb       $0x02,%al              # Enable A20
#  andb      $~0x01,%al             # Do not reset machine 
  outb      %al,$0x92

  # Switch from real to protected mode.  Use a bootstrap GDT that makes
  # virtual addresses map directly to physical addresses so that the
  # effective memory map doesn't change during the transition.
  lgdt    gdtdesc
  movl    %cr0, %eax
  orl     $CR0_PE, %eax
  movl    %eax, %cr0

//PAGEBREAK!
  # Complete the transition to 32-bit protected mode by using a long jmp
  # to reload %cs and %eip.  The segment descriptors are set up with no
  # translation, so that the mapping is still the identity mapping.
  ljmp    $(1<<3), $start32

.code32  # Tell assembler to generate 32-bit code now.
start32:
  # Set up the protected-mode data segment registers
  movw    $(2<<3), %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
#  movw    $0, %ax                 # Zero segments not ready for use
#  movw    %ax, %fs                # -> FS
#  movw    %ax, %gs                # -> GS

  # Set up the stack pointer and call into C.
  movl    $start, %esp
  call    boot_bzImage

# Bootstrap GDT
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULLASM                             # null seg
  SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)   # code seg
  SEG_ASM(STA_W, 0x0, 0xffffffff)         # data seg
  SEG_ASM16(STA_X|STA_R, 0x0, 0xffffffff)     # code16 seg
  SEG_ASM16(STA_W, 0x0, 0xffffffff)           # data16 seg

gdtdesc:
  .word   (gdtdesc - gdt - 1)             # sizeof(gdt) - 1
  .long   gdt                             # address gdt

.globl switch_back_to_rmode_and_jmp_setup
switch_back_to_rmode_and_jmp_setup:
  ljmp    $(3<<3), $back_to_rmode
.code16
back_to_rmode:
  movw    $(4<<3), %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS
  movl    %cr0, %eax
  andl    $~CR0_PE, %eax
  movl    %eax, %cr0
jmp_setup:
  movw $0x9000, %ax
  movw %ax, %ds                          # SETUP requres CS=DS+0x20
  ljmp $0x9020, $0                       # jmp to SETUP @0x9020; no ret
