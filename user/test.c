#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
    int n = 0;
    if(argc >= 2)
    {
        n = atoi(argv[1]);
    }

    printf("\nTesting new system call 'info' with entered parameter, '%d'...\n", n);
    switch(n) {
    	case 1:
    		printf("Case 1: count the processes in the system\n");
    		printf("Executing info(1)... \n\n");
    		info(1);
    		printf("\ninfo(1) returned\n");
    		break;
    	case 2:
    		printf("Case 2: count the total number of system calls that the current procces has made so far\n");
    		printf("Executing info(2) 10 times to show effect... \n\n");
    		for (unsigned char i = 0; i < 10; i++){info(2);}
    		printf("\ninfo(2) returned\n");
    		break;
    	case 3:
    		printf("Case 3: return the number of memory pages allocated to the current process\n");
    		printf("Executing info(3)... \n\n");
    		info(3);
    		printf("\ninfo(3) returned\n");
    		
    		printf("Executing test implementation to verify correctness...\n\n");
    		info(4);
    		printf("\ntest returned\n");
    		break;
    	default:
    		printf("Parameter entered is unnacceptable. Enter '1', '2', or '3'.\n");
    }
    exit(0);
    	
    

//EXIT:
//    exit(0);

}
