#include <stdint.h>

#define LBSIZ 20

void putc(int c);
void puts(char *s);
int getc(void);

void iderd(void *buf, int lba, int count);

char linebuf[LBSIZ];

void
getcmd(void)
{
	char *p;
	int cr;

	cr = 0;
	p = linebuf;
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
		if (p >= linebuf+LBSIZ-1) {
			puts("?length\r\n");
			p = linebuf;
			cr = 0;
			continue;
		}
		*p++ = c;
	}
	*p = '\0';
}

void
main(void)
{
	while (1) {
		getcmd();
		puts(linebuf);
		putc('\n');
	}
}
