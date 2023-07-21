all: boot

BOOTOBJ = asm.o main.o

.c.o:
	$(CC) -W -O -ffreestanding -c $<
.s.o:
	$(AS) -o $@ $<

boot: $(BOOTOBJ)
	$(LD) -o boot --oformat binary -Ttext 0x8000 $(BOOTOBJ)
clean:
	rm -f $(BOOTOBJ) boot
