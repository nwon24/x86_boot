# 16-bit boot block (MBR)
.=0
LADDR	= 0x7c00
LSEG	= 0x7c0
RADDR	= 0x6000
RSEG	= 0x600
PARTOFF = 0x1be
LBAOFF  = 8

.text
.code16
.globl _start
_start:
	ljmp	$0,$1f
1:	cli		# No interrupts
	mov	$0,%ax
	mov	%ax,%ss
	mov	$LADDR,%sp
	mov	%ax,%es
	mov	%ax,%ds
	mov	%ax,%fs
	mov	%ax,%gs

	# Copy to RADDR
	mov	$256,%cx	# Copy 256 words
	mov	$RADDR,%di	# destination
	mov	$LADDR,%si	# Source
	cld			# Go forward
	rep
	movsw			# Copy
	ljmp	$0,$RADDR+1f-LADDR	# Jump to relocation

	# From now on, addresses must be relative to RADDR
1:	sti
	cmp	$0x80,%dl		# Floppy disk?
	jl	err			# Don't care for them
	# Save disk
	movb	%dl,RADDR+drv-LADDR
	# Set es:di to part table
	mov	$RADDR+PARTOFF,%di

	# Print prompt :
	mov	$0x1,%ah		# Send output to serial port
	mov	$0,%dx			# Serial port 1
	mov	$':',%al		# Character
	int	$0x14
	test	$128,%ah		# Error?
	jnz	err			# Wouldn't help, but do it anyway

	# Get a number from the user 1-4
	mov	$0,%ah
	int	$0x16
	cmp	$'1',%al		# < '1'?
	jl	err			# Yes, error
	cmp	$'4',%al		# > '4'?'
	jg	err			# Yes, error
	movb	$0,%ah			# Clear upper byte
	push	%ax			# Save it
	sub	$'0',%al		# Get partition number
	mov	%al,RADDR+part-LADDR		# save it
	pop	%ax			# Echo it back
	mov	$0x1,%ah
	mov	$0,%dx			# First serial port
	int	$0x14			# Send it

	# Get partition table entry
	xor	%ax,%ax
	mov	RADDR+part-LADDR,%al
	dec	%al
	shl	$4,%al			# Each entry is 16 bytes
	add	%ax,%di
	mov	(%di),%al		# Get first byte
	test	$0x80,%al		# Bootable?
	jz	err			# No, error
	
	# Now read the VBR
	mov	LBAOFF(%di), %ax	# Lower 16-bits
	mov	LBAOFF+2(%di), %bx	# Upper 16-bits
	mov	$RADDR+pket-LADDR,%si
	mov	%ax,8(%si)		# Store in packet
	mov	%bx,10(%si)		# ""
	movw	$0,12(%si)
	
	mov	$0x42,%ah		# Extended read
	mov	RADDR+drv-LADDR,%dl			# Drive number
	int	$0x13
	jc	err			# Carry set on error
	test	%ah,%ah			# ah should also be 0
	jnz	err

	# Give partition table entry and disk to VBR
	mov	%di,%si
	mov	RADDR+drv-LADDR,%dl
	# Now jump to VBR
	ljmp	$0,$LADDR
1:	jmp	.

	# err: print '?' and loop forever
err:	mov	$0x1,%ah
	mov	$0,%dx
	mov	$'?',%al
	int	$0x14
	jmp	.
.align 2
pket:
	.byte	16
	.byte	0
	.word	1
	.word	0
	.word	LSEG
	.long	0
	.long	0
part:
	.byte	0
drv:
	.byte	0
.=510
.word 0xaa55
