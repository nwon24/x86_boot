# Bootloader
# Loads /kernel from the filesystem
# Begins in 16-bit real mode
# Linked at 0x7e00
.code16
.text
.globl _start
_start:
	mov	$1,%ah
	mov	$0,%dx
	mov	$'a',%al
	int	$0x14
	jmp	.
