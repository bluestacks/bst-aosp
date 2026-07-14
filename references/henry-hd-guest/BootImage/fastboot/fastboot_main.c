// Fastboot loader.
//
// Part of the boot block, along with bootasm.S.
// bootasm.S has put the processor into protected 32-bit mode.

#define SECTSIZE  512

typedef unsigned int u32;
typedef unsigned short u16;
typedef unsigned char u8;

/*
 * BAR4_ADDR is enumed from PCI device. More detailed info pls refer to
 * Programming Interface for Bus Master IDE Controller Revision 1.0 5/16/94
 */
#define BAR4_ADDR           0xd040
#define PRDT_REG_ADDR       0xd044
#define MARK_END            0x8000
/* Any unused address is okay for PRDT_ADDR */
#define PRDT_ADDR           (0x1000000)

/** Currently performing a DMA operation. */
#define BM_STATUS_DMAING 0x01
/** An error occurred during the DMA operation. */
#define BM_STATUS_ERROR  0x02
/** The DMA unit has raised the IDE interrupt line. */
#define BM_STATUS_INT    0x04
/** User-defined bit 0, commonly used to signal that drive 0 supports DMA. */
#define BM_STATUS_D0DMA  0x20
/** User-defined bit 1, commonly used to signal that drive 1 supports DMA. */
#define BM_STATUS_D1DMA  0x40

/** Start the DMA operation. */
#define BM_CMD_START     0x01
/** Data transfer direction: from device to memory if set. */
#define BM_CMD_WRITE     0x08

#define ATA_IS_BUSY      0x80
#define READ_DMA         0xC8


/* PRDT - Physical Region Descriptor Table */
typedef struct prdt {
	u32 buffer_phys;
	u16 transfer_size;
	u16 mark_end;
} __attribute__ ((packed)) prdt_t;

#define barrier() __asm__ __volatile__("" ::: "memory")

#define DMA_SECTORS		(32)
#define SECTOR2BYTE(x)	((x) << 9)
#define BYTE2SECTOR(x)	((x) >> 9)

/* below inb, outb, outl are ported from kernel */
static inline u8 inb(u16 port)
{
	u8 v;
	asm volatile ("inb %1,%0":"=a" (v):"dN"(port));
	return v;
}

static inline void outb(u16 port, u8 v)
{
	asm volatile ("outb %0,%1"::"a" (v), "dN"(port));
}

static inline void outl(u16 port, u32 v)
{
	asm volatile ("outl %0,%1"::"a" (v), "dN"(port));
}

void init_ide()
{
	((prdt_t *) PRDT_ADDR)->mark_end = MARK_END;
	outl(PRDT_REG_ADDR, PRDT_ADDR);
}

/* Read n sectors at offset. */
static inline void readsect(u8 n, u32 offset)
{
	u16 bar4 = BAR4_ADDR;

	outb(0x1F2, n);
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
	/*We do NOT use offset bit 24-28, we simplify the op to save space*/
	/* outb(0x1F6, (offset >> 24) | 0xE0); */
	outb(0x1F6, 0xE0);

	outb(bar4, BM_CMD_WRITE | BM_CMD_START);

	outb(0x1F7, READ_DMA);

	/* Wait for the DMA op complete */
	while (1) {
		u8 status;
		status = inb(bar4 + 2);
		if ((status & BM_STATUS_DMAING) || !(status & BM_STATUS_INT)) {
			continue;
		}
		status = inb(0x1F7);
		if (!(status & ATA_IS_BUSY)) {
			break;
		}
	}
}

void readseg(u8 * pa, u32 count, u32 offset)
{

	offset = BYTE2SECTOR(offset) + 1;
	count = BYTE2SECTOR(count + 511);
	u8 n;
	/* read data from offset at disk to pa (physical address) of the memory */
	for (; count > 0; offset += n, pa += SECTOR2BYTE(DMA_SECTORS), count -= n) {
		n = count >= DMA_SECTORS ? DMA_SECTORS : count;
		((prdt_t *) PRDT_ADDR)->buffer_phys = (u32) pa;
		((prdt_t *) PRDT_ADDR)->transfer_size = SECTOR2BYTE(n);
		barrier();
		readsect(n, offset);
	}
}
