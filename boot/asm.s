/ Bootloader
/ Loads /kernel from the filesystem
/ Begins in 16-bit real mode
/ Linked at 0x7e00

/ MEMORY MAP
/ 0x1000 - 0x5000 - page tables
/ 0x5000 - memory map

COM1 = 0x3f8
MMAP = 0x5000

.code16
.text
.globl _start
_start:
	/ Try to enable A20
	mov	$0x2403,%ax	/ A20 supported?
	int	$0x15
	jb	a20err		/ No supported

	mov	$0x2402,%ax	/ A20 enabled?
	int	$0x15
	jb	a20err		/ Error
	cmp	$1,%al		/ A20 enabled?
	je	1f		/ Already enabled
	mov	$0x2401,%ax	/ Enable A20
	int	$0x15
	jb	a20err		/ Failed
1:
	/ Print start message
	mov	$bootmsg,%si
	call	print16

	/ Get memory map from BIOS
	mov	$0,%bx		/ 0 for the first call
	mov	$MMAP,%di	/ Address
1:	mov	$24,%cx		/ 24 byte entry 
	mov	$0x534d4150,%edx	/ magic
	mov	$0xe820,%ax
	int	$0x15
	test	%bx,%bx		/ Done?
	jz	1f		/ Yes
	add	$24,%di		/ No, increment pointer and repeat
	jmp	1b

	/ Go to protected mode
1:	cli			/ No interrupts
	lgdt	bootgdtr	/ Load gdt
	mov	%cr0,%eax
	or	$1,%al		/ PM bit on
	mov	%eax,%cr0
	ljmp	$0x8,$pmmode	/ Jump to protected mode
	jmp	.

	/ Print message while still in real mode
	/ Null terminated string in si
print16:
	mov	$0,%dx		/ First serial port
1:	lodsb			/ Get byte
	test	%al,%al		/ Done?
	jz	1f		/ Yes, exit
	mov	$1,%ah		/ No, print it
	int	$0x14
	jmp	1b		/ loop
1:	ret

	/ Print message and loop forever while in real mode
	/ Message in si
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
	.asciz	"boot\r\n"

	/ GDT
	/ Set up for protected mode
bootgdt:
	/ NULL
	.long	0,0

	/ Code: r/w, 0xffff, base 0, gran 1
	.word	0xffff	/ limit 0..15
	.word	0	/ base
	.byte	0	/ base
	.byte	0x9a	/ type r/x, code, present 
	.byte	0xcf	/ limit, 32-bit segment, granularity 1
	.byte	0	/ base

	.word	0xffff
	.word	0
	.byte	0
	.byte	0x92	/ type r/w data, present
	.byte	0xcf
	.byte	0
bootgdtr:
	.word	bootgdtr-bootgdt
	.long	bootgdt

/ START OF 32BIT
.code32
pmmode:
	cli			/ No interrupts
	mov	$0x10,%ax	/ Set segment descriptors
	mov	%ax,%ds
	mov	%ax,%es
	mov	%ax,%fs
	mov	%ax,%gs
	mov	%ax,%ss
	mov	$pmstack,%esp

	/ Set up serial port for output
	/ Disable all interrupts
	/ Write 0 to port +1
	mov	$0,%al
	mov	$COM1+1,%dx
	out	%al,%dx
	/ Set baud rate
	/ Begin by setting DLAB in port +3
	mov	$0x80,%al
	mov	$COM1+3,%dx
	out	%al,%dx
	/ Baud rate 115200 (divisor 1)
	mov	$1,%al
	mov	$COM1,%dx
	out	%al,%dx
	mov	$0,%al
	inc	%dx
	out	%al,%dx
	/ Clear msb of port +3
	/ and set 8 bit, no parity, one stop bit
	mov	$0x3,%al
	mov	$COM1+3,%dx
	out	%al,%dx
	/ magic
	mov	$0xc7,%al
	mov	$COM1+2,%dx
	out	%al,%dx

	/ Done. Now call main to load the kernel.
	call	main
	/ Unreachable
die:	jmp	.

.globl putc
	/ Send a character to the serial port
putc:
	mov	$COM1+5,%dx	/ Line status register
	inb	%dx,%al		/ Get status
	and	$0x20,%al	/ Can data be send?
	jz	putc		/ No, loop
	mov	4(%esp),%eax	/ Get char
	mov	$COM1,%dx
	out	%al,%dx		/ Send it
	ret
.globl puts
	/ Write a string to the serial port
puts:
	push	%ebp
	mov	%esp,%ebp
	push	%esi
	mov	8(%ebp),%esi	/ Get string
1:	xor	%eax,%eax	/ Clear %eax
	lodsb			/ Get a byte
	test	%al,%al		/ End of string?
	jz	1f		/ Yes, exit loop
	push	%eax		/ Call 'putc' to print it
	call	putc
	add	$4,%esp	
	jmp	1b		/ Loop
1:	pop	%esi
	mov	%ebp,%esp
	pop	%ebp
	ret

.globl cinb, coutb
/ read an IO port
cinb:
	mov	4(%esp),%edx
	xor	%eax,%eax
	inb	%dx
	ret
/ write to an IO port
coutb:
	mov	4(%esp),%edx
	mov	8(%esp),%eax
	outb	%al,%dx
	ret
	
.=.+512
pmstack:
