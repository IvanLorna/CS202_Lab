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

    printf("info kernel with parameter %d\n", n);
    int infoCnt = 1;
    if(n == 2) {
        //Invoke the system call for 10 times to observe the output, each time, it should add one to the number of system calls;
        infoCnt = 10;
    } else if((n < 0) || (n > 3)) {
        printf("Wrong parameter %d\n", n);
        goto EXIT;
    }

    for(int i = 0; i < infoCnt; i++) {
        info(n);
    }

EXIT:
    exit(0);
}
