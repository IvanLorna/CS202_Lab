#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define PGSIZE 4096

int main(int argc, char *argv[])
{
	void* freeptr = malloc(PGSIZE*5);
	void* stack;
	if(freeptr == 0)
		return -1;
	//Align the stack to PGSIZE
	stack = (void *)(PGSIZE * (((uint64)freeptr + 3*PGSIZE) / PGSIZE));

	printf("test stack = 0x%x\n", stack);
	//int ret = fork();
	int ret = clone(stack, PGSIZE);
	printf("test stack = 0x%x ret = %d\n", stack, ret);
	if(ret == 0) {
		int i = 0;
		while(i < 1000) {
			i++;
			sleep(14);
			printf("\ntest 1 sleep i1 = %d\n", i);
		}
	} else {
		int i = 0;
		while(i < 1000) {
			i++;
			sleep(19);
			printf("\ntest 2 sleep i2 = %d\n", i);
		}
	}
	exit(0);



}
