# 16-bit vbr
# Only supports ext2 (for now) (and probably forever)

LADDR	= 0x7c00
.code16
.=0
.globl _start
_start:
	cli
	# Make sure ds=es=fs=gs=ss=0
	mov	$0,%ax
	mov	%ax,%ds
	mov	%ax,%es
	mov	%ax,%fs
	mov	%ax,%gs
	mov	%ax,%ss
	# Set up stack
	mov	$LADDR,%sp

	# save disk booted from
	movb	%dl,drv
	cmp	$0x80,%dl	# Floppy?
	jl	err		# Yes, don't care for it

	# Make sure ds:si points to partition table entry
	mov	(%si),%al	# Get first byte
	test	$0x80,%al	# Active?
	jz	err		# No, error
	# Save partition offset
	mov	8(%si),%ax	# Lower 16bits
	mov	%ax,partoff	# Save it
	mov	10(%si),%ax	# Upper 16bits
	mov	%ax,partoff+2   # Save it

	sti
	# Read superblock - 1024 bytes from start of partition = 2 sectors
	# Read 2 sectors to 0x500 (scratch area)
	mov	$2,%cx
	mov	$0x500,%di
	mov	$2,%bx
	xor	%ax,%ax
	call	rsec
	jmp	.

	# Print '?' and die
err:
	mov	$0x1,%ah
	mov	$'?',%al
	mov	$0,%dx
	int	$0x14
	jmp	.

	# Read a number of sectors
	# starting from an offset from the partition
	# cx=sectors to read, ax:bx=starting offset, di=destination
	# Surely no sector > 32 bits??
rsec:
	clc			# Clear carry
	movb	drv,%dl		# Drive number
	mov	$pket,%si	# Disk package address
	mov	%cx,2(%si)	# Set count
	mov	%di,4(%si)	# Address offset 
	mov	partoff,%cx	# Lower 16-bits of offset
	add	%cx,%bx		# Add it 
	mov	%bx,8(%si)	# Put it into the packate
	mov	partoff+2,%cx	# Upper 16-bits of offset
	add	%cx,%ax		# Add it
	mov	%ax,10(%si)	# Save it
	mov	$0x42,%ah	# Extended read
	int	$0x13
	jc	diskerr		# Carry set if error
	ret
diskerr:
	mov	$diskmsg,%si
	call	errmsg
	jmp	.

	# Print a message and die
	# Message is in si
errmsg:
	mov	$0,%dx
1:	lodsb
	cmp	$0,%al
	je	1f
	mov	$0x1,%ah
	int	$0x14
	jmp	1b
1:	jmp	.


drv:
	.word	0
partoff:
	.long	0
ext2msg:
	.asciz	"?ext2\n"
diskmsg:
	.asciz	"?disk\n"
pket:
	.byte	16	# Always 16 (size)
	.byte	0	# Always 0
	.word	0	# Number of sectors to transfer
	.word	0	# Address offset
	.word	0	# Address segment
	.long	0	# lower 32-bits of LBA
	.long	0	# Upper 16-bits of LBA
.=510
.word 0xaa55
