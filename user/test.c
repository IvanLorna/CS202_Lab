#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
	int n =0;
	if (argc >= 2) n = atoi(argv[1]);
	
	int size = 40;
	int stack = 40;


	int p = 0;//myproc()->pagetable;
	int c = clone(&p + stack, size);
	//clone(&p + stack, size);
	
	printf("mode: %d\n", n);
	//printf("my pid: ???");
	printf("clone pid: %d\n", c);
	exit(0);



}
