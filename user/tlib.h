
struct lock_t {
	int held; 
};

void lock_init(struct lock_t *lock);

void lock_acquire(struct lock_t *lock);

void lock_release(struct lock_t *lock);

int thread_create(void *(*start_routine)(void*), void *arg);
