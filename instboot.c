/*
 * instboot.c
 * Install mbr and vbr.
 */
#include <stdio.h>
#include <stdlib.h>

#define SECSIZ 512	/* Sector size */
#define MBRSIZ 446	/* Size of MBR */

#define LBAOFF	8	/* LBA start offset in partition table entry */

#define ACTIVE 0x80	/* Partition active */

#define PENTSIZ 16	/* Partition entry size */

int
main(int argc, char *argv[])
{
	FILE *dsk, *mbr, *vbr;
	char buf[SECSIZ];
	char *pent;
	int ent, lba, i;

	if (argc != 5) {
		fprintf(stderr, "instdboot [disk] [mbr] [vbr] [part num]\n");
		return 1;
	}
	ent = atoi(argv[4]);
	if (ent <= 0 || ent > 4) {
		fprintf(stderr, "Invalid partition table entry\n");
		return 1;
	}
	if ((dsk = fopen(argv[1], "r+")) == NULL) {
		perror(argv[1]);
		return 1;
	}
	if ((mbr = fopen(argv[2], "r")) == NULL) {
		perror(argv[2]);
		return 1;
	}
	if ((vbr = fopen(argv[3], "r")) == NULL) {
		perror(argv[3]);
		return 1;
	}
	if (fread(buf, 1, MBRSIZ, mbr) != MBRSIZ) {
		fprintf(stderr, "invalid mbr\n");
		return 1;
	}
	buf[510] = 0x55;
	buf[511] = 0xaa;
	fseek(dsk, MBRSIZ, SEEK_SET);
	fread(&buf[MBRSIZ], 1, PENTSIZ*4, dsk);
	if (fseek(dsk, 0L, SEEK_SET) != 0) {
		fprintf(stderr, "fseek dsk\n");
		return 1;
	}
	if (fwrite(buf, 1, SECSIZ, dsk) != SECSIZ) {
		fprintf(stderr, "fwrite disk\n");
	}
	fflush(dsk);
	pent = &buf[MBRSIZ + (ent-1)*PENTSIZ];
	if (!(*pent & ACTIVE)) {
		printf("%d\n", *pent);
		fprintf(stderr, "Not bootable\n");
		return 1;
	}
	lba = *(int *)&pent[LBAOFF];
	if (lba == 0) {
		fprintf(stderr, "unrachable\n");	
		return 1;
	}
	fseek(dsk, SECSIZ*lba, SEEK_SET);
	while ((i = fread(buf, 1, SECSIZ, vbr)) > 0)
		fwrite(buf, 1, i, dsk);
	fclose(dsk);
	fclose(vbr);
	fclose(mbr);
	return 0;
}
