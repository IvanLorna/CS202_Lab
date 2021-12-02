#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define PGSIZE 4096

int main(int argc, char *argv[])
{

	// int n =0;
	// if (argc >= 2) n = atoi(argv[1]);

	void* freeptr = malloc(PGSIZE*5);
	void* stack;
	if(freeptr == 0)
		return -1;
	// if((uint64)freeptr % PGSIZE == 0)
	// 	stack = freeptr;
	// else
	// 	stack = freeptr + (PGSIZE - ((uint64)freeptr % PGSIZE));

	stack = (void *)(PGSIZE * (((uint64)freeptr + 3*PGSIZE) / PGSIZE));

	// void *stack = (void *)malloc(1024);
	printf("test stack = 0x%x\n", stack);
	//int ret = fork();
	int ret = clone(stack, PGSIZE);
	printf("test ret = %d\n", ret);
	if(ret == 0) {
		printf("test 1\n");
		int i = 0;
		while(i < 1000) {
			i++;
			sleep(5);
			printf("test 1 sleep i1 = %d\n", i);
		}
	} else {
		int i = 0;
		while(i < 1000) {
			i++;
			sleep(7);
			printf("test 2 sleep i2 = %d\n", i);
		}
	}
	exit(0);



}
