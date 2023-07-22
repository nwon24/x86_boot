#include <stdint.h>

uint8_t cinb(uint16_t port);
void putc(int c);
void puts(char *s);
int getc(void);

void iderd(void *buf, int lba, int count);

void
main(void)
{
	puts("Hello, world!\n");
	while (1) {
		int c;

		c = getc();
		if (c == '\r')
			putc('\n');
		putc(c);
	}
	while (1);
}
