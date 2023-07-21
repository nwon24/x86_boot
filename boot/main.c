#include <stdint.h>

#define inb cinb

uint8_t cinb(uint16_t port);
void putc(int c);
void puts(char *s);

void
main(void)
{
	puts("Hello, world!\n");
	while (1) {
		while (!(inb(0x3f8+5) & 1));
		putc(inb(0x3f8));
		inb(0x3f8);
	}
	while (1);
}
