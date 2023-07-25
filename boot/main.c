#include <stdint.h>

#define LBSIZ 20

void putc(int c);
void puts(char *s);
int getc(void);

void iderd(void *buf, int lba, int count);

char lnbuf[LBSIZ];

void
main(void)
{
	char *p;
	int cr;

	p = lnbuf;
	cr = 0;
	puts("Hello, world!\n");
	while (1) {
		int c;

		c = getc();
		if (c == '\r') {
			putc('\n');
			++cr;
		}
		putc(c);
		if (cr || p >= lnbuf+LBSIZ)
			break;
		*p++ = c;
	}
	puts("command\r\n");
	while (1);
}
