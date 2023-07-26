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
		if (cr)
			break;
		if (p >= lnbuf+LBSIZ-1) {
			puts("?length\r\n");
			p = lnbuf;
			cr = 0;
			continue;
		}
		*p++ = c;
	}
	*p = '\0';
	puts("command\r\n");
	while (1);
}
