TGT = x86_64-elf
CC = $(TGT)-gcc
AS = $(TGT)-as
LD = $(TGT)-ld
OBJCOPY = $(TGT)-objcopy

all: boot0 boot1

boot0: boot0.s
	$(AS) --32  -o boot0.o boot0.s
	$(LD) -melf_i386 -o boot0 --oformat binary -Ttext 0x7c00 boot0.o
boot1: boot1.s
	$(AS) --32 -o boot1.o boot1.s
	$(LD) -melf_i386 -o boot1 --oformat binary -Ttext 0x7c00 boot1.o

disk.img:
	dd if=/dev/zero of=disk.img bs=1024 count=10240
	printf ",,L,*" | sfdisk disk.img

instboot: instboot.c
	cc -O -w -o instboot instboot.c 
wboot: disk.img boot0 boot1 instboot
	./instboot disk.img boot0 boot1 1
run: wboot disk.img
	qemu-system-x86_64 -hda disk.img -nographic -monitor telnet::45454,server,nowait -serial mon:stdio
clean:
	rm -f boot0 boot0.o boot1 boot.o
