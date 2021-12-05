#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "tlib.h"

// #define DEBUG

#define PGSIZE 4096

int thread_create(void *(*start_routine)(void*), void *arg) {
	#ifdef DEBUG
	printf("thread_create 1 arg = 0x%x &arg = 0x%x\n", arg, &arg); 
	#endif
	// if(start_routine == 0) {
	// 	return -1;
	// }
	// printf("thread_create arg = 0x%x\n", arg); 
	void* stack = malloc(PGSIZE);
	if(stack == 0)
		return -1;
	#ifdef DEBUG
	printf("thread_create stack = 0x%x\n", stack); 
	#endif
	int ret = clone(stack, PGSIZE);
	#ifdef DEBUG
	printf("thread_create ret = 0x%x\n", ret); 
	#endif
	if(ret == 0) {
		#ifdef DEBUG
		printf("thread_create success arg = 0x%x &arg = 0x%x\n", arg, &arg);
		#endif
		sleep(20);//Sleep enough time to let the parent finish the childs clone, just for debug.
		(*start_routine)(arg);
		free(stack);

		// struct lock_t lock;
		// lock_init(&lock);

		// lock_acquire(&lock);

		exit(0);
	}
	return ret;
}

void lock_init(struct lock_t *lock) {
	lock->held = 0;
}

void lock_acquire(struct lock_t *lock) {
	while (__sync_lock_test_and_set(&lock->held, 1) == 1);
	// while(1) {
	// 	int ret = __sync_lock_test_and_set(&lock->held, 1);
	// 	printf("lock_acquire ret = %d\n", ret);
	// 	if(ret == 0) {
	// 		break;
	// 	}
	// }

	// while(1) {
	// 	int ret = __sync_lock_test_and_set(&lock->held, 1);
	// 	sleep(5);
	// 	printf("lock_acquire 2 ret = %d\n", ret);
	// 	lock_release(lock);
	// }
}

void lock_release(struct lock_t *lock) {
	lock->held = 0;
}

