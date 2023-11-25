TGT = i686-elf
CC = $(TGT)-gcc
AS = $(TGT)-as
LD = $(TGT)-ld
OBJCOPY = $(TGT)-objcopy

export TGT CC AS LD OBJCOPY

BOOT = boot/boot

.PHONY: all $(BOOT)

all: boot0 boot1 $(BOOT)

.s.o:
	$(AS) $< -o $@

boot0: boot0.s
	$(AS)   -o boot0.o boot0.s
	$(LD)  -o boot0 --oformat binary -Ttext 0x7c00 boot0.o
boot1: boot1.s
	$(AS)  -o boot1.o boot1.s
	$(LD)  -o boot1 --oformat binary -Ttext 0x7c00 boot1.o
$(BOOT):
	(cd boot; $(MAKE))

disk.img: mkext2.sh
	dd if=/dev/zero of=disk.img bs=1024 count=10240
	printf ",,L,*" | sfdisk disk.img
	./mkext2.sh disk.img

instboot: instboot.c
	cc -O -w -o instboot instboot.c 
wboot: disk.img boot0 boot1 instboot $(BOOT)
	./instboot disk.img boot0 boot1 1
cpboot: disk.img $(BOOT) 
	./instboot.sh disk.img $(BOOT)
run: wboot cpboot disk.img 
	qemu-system-i386 -hda disk.img -nographic -serial mon:stdio 
clean:
	rm -f boot0 boot0.o boot1 boot.o
	(cd boot; $(MAKE) clean)
