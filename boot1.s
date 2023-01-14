# 16-bit vbr
# Only supports ext2 (for now) (and probably forever)

LADDR	= 0x7c00
EXT2SIG = 0xef53
BGDSIZ  = 32

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
	mov	$2,%cx		# 2 sectors
	mov	$0x500,%di	# To 0x500 (first free area)
	mov	$2,%bx		# %ax:%bx = 2
	xor	%ax,%ax
	call	rsec
	mov	$0x500,%di
	mov	56(%di),%ax	# Get signature 
	cmp	$EXT2SIG,%ax	# Valid signature?
	jne	ext2err	

	# First things first: get block size and inode size
	mov	24(%di),%cx	# Field in superblock
	mov	$1024,%bx
	shl	%cl,%bx
	mov	%bx,bsize	# store it
	
	mov	76(%di),%ax	# Get major version
	cmp	$1,%ax		# version >=1 ?
	jge	1f		# Yes, branch
	movw	$128,isize	# No, inode size is 128	
	jmp	2f
1:	mov	88(%di),%ax	# Get inode size from super block
	mov	%ax,isize	# Store it
2:
	mov	40(%di),%ax	# Number of inodes per group
	mov	%ax,ipg

	# Now read block group descriptor table into memory
	mov	bsize,%cx	# Read a full block
	shr	$9,%cx		# SECSIZ = 512
	mov	$0x500,%di	# Overwrite superblock (that's ok)
	mov	$4,%bx		# Fourth sector 
	xor	%ax,%ax
	call	rsec

	# Get root inode (inode 2)
	mov	$2,%ax
	mov	$0x900,%di
	call	iget
	jmp	.

	# Given an inode number (ax), read its inode into memory
	# at the specified address (di)
iget:
	mov	%di,dest
	# Determine block group
	push	%ax		# Save inode
	dec	%ax		# block group = (inode - 1) / ipg
	xor	%dx,%dx
	mov	ipg,%bx
	div	%bx		# Quotient in ax
	shl	$5,%ax		# Block group size is 32
	mov	$0x500,%bx	# Start of block group descriptor table
	add	%ax,%bx		# Get offset
	mov	%bx,%si		# Save offset
	# Determine index in inode table
	pop	%ax		# Get inode again
	dec	%ax		# index = (inode - 1) % ipg
	xor	%dx,%dx
	mov	ipg,%bx
	div	%bx		# Remainder in %dx
	mov	%dx,index	# Save it
	# Get containing block offset		
	mov	%dx,%ax		# block = (index * isize) / bsize
	xor	%dx,%dx
	mov	isize,%bx
	mul	%bx
	xor	%dx,%dx
	mov	bsize,%bx
	div	%bx
	# Block offset now in ax
	# Get starting block
	mov	8(%si),%bx	# Block of inode table
	add	%ax,%bx		# Add offset
	mov	%bx,%ax
	# Read block in %bx to 0x900
	mov	$1,%cx		# Read one block
	# di already contains destination
	call	rblk
	# Now calculate offset of inode in block
	# and move it to the beginning of the section
	# Offset in block = index % inodes per block
	mov	isize,%cx
	mov	bsize,%ax
	xor	%dx,%dx
	div	%cx		# Quotient in %ax
	mov	%ax,%bx		# Div by bx
	mov	index,%ax
	xor	%dx,%dx
	div	%bx		# Remainder in %dx
	# Now we have the index in %dx
	# We have to multiply it by isize to get byte offset
	mov	%dx,%ax
	mov	isize,%bx
	mul	%bx		# Product in %ax
	mov	dest,%si
	add	%ax,%si		# Add byte offset
	# Now just copy from (%si) to 0x900 isize bytes
	mov	isize,%cx	# Bytes to copy
	mov	dest,%di	# Destination
	cld
	rep
	movsb
	ret

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

	# Read ext2 block
	# ax=starting offset, di=destination, cx=block count
rblk:
	mov	%ax,%bx		# Save offset
	mov	%cx,%ax		# get sector count
	mov	bsize,%si	# Get block size
	shr	$9,%si		# Get as multiple of sector size
	xor	%dx,%dx		# Do conversions 
	mul	%si		# Multiply
	mov	%ax,%cx		# Store sector count
	mov	%bx,%ax		# Get sector offset
	xor	%dx,%dx		# dx:ax
	mul	%si		# multiply to get sector offset
	mov	%ax,%bx		# Move upper and lower 16-bits to proper location
	mov	%dx,%ax
	call	rsec
	ret
	
ext2err:
	mov	$ext2msg,%si
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

# ext2 parameters we want to save from superblock
# block size
bsize:
	.word	0
# inode size
isize:
	.word	0
# inodes per group
ipg:
	.long	0
# blocks per group
bpg:
	.long	0
# fields for current inode
index:
	.word	0
dest:
	.word 	0
.=510
.word 0xaa55
