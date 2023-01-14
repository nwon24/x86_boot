all: boot

BOOTOBJ = asm.o main.o

.c.o:
	$(CC) -m32 -W -O -mno-red-zone -mno-sse -c $<
.s.o:
	$(AS) --32 -o $@ $<

boot: $(BOOTOBJ)
	$(LD) -o boot -melf_i386 --oformat binary -Ttext 0x8000 $(BOOTOBJ)
clean:
	rm -f $(BOOTOBJ) boot
