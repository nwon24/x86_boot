# Bootloader
# Loads /kernel from the filesystem
# Begins in 16-bit real mode
# Linked at 0x7e00
.code16
.text
.globl _start
_start:
	# Try to enable A20
	mov	$0x2403,%ax	# A20 supported?
	int	$0x15
	jb	a20err		# No supported

	mov	$0x2402,%ax	# A20 enabled?
	int	$0x15
	jb	a20err		# Error
	cmp	$1,%al		# A20 enabled?
	je	1f		# Already enabled
	mov	$0x2401,%ax	# Enable A20
	int	$0x15
	jb	a20err		# Failed
1:
	# Print start message
	mov	$bootmsg,%si
	call	print16

	# Go to protected mode
	cli			# No interrupts
	lgdt	bootgdtr	# Load gdt
	mov	%cr0,%eax
	or	$1,%al		# PM bit on
	mov	%eax,%cr0
	ljmp	$0x8,$pmmode	# Jump to protected mode
	jmp	.

	# Print message while still in real mode
	# Null terminated string in si
print16:
	mov	$0,%dx		# First serial port
1:	lodsb			# Get byte
	test	%al,%al		# Done?
	jz	1f		# Yes, exit
	mov	$1,%ah		# No, print it
	int	$0x14
	jmp	1b		# loop
1:	ret

	# Print message and loop forever while in real mode
	# Message in si
err16:
	call	print16
	jmp	.
a20err:
	mov	$a20msg,%si
	call	err16
	jmp	.

a20msg:
	.asciz	"?a20"
bootmsg:
	.asciz	"boot\n"

	# GDT
	# Set up for protected mode
bootgdt:
	# NULL
	.long	0,0

	# Code: r/w, 0xffff, base 0, gran 1
	.word	0xffff	# limit 0..15
	.word	0	# base
	.byte	0	# base
	.byte	0x9a	# type r/x, code, present 
	.byte	0xcf	# limit, 32-bit segment, granularity 1
	.byte	0	# base

	.word	0xffff
	.word	0
	.byte	0
	.byte	0x92	# type r/w data, present
	.byte	0xcf
	.byte	0
bootgdtr:
	.word	bootgdtr-bootgdt
	.long	bootgdt

# START OF 32BIT
.code32
pmmode:
	mov	$0x10,%ax	# Set segment descriptors
	mov	%ax,%ds
	mov	%ax,%es
	mov	%ax,%fs
	mov	%ax,%gs
	mov	%ax,%ss
	mov	$pmstack,%esp
	jmp	.

.=.+512
pmstack:
