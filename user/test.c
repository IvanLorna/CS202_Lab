#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "tlib.h"

#define PGSIZE 4096

static void *start_play(void* arg);

struct Friesbee {
	struct lock_t lock;
	int nextPlayerId;
	int passesNum;
	int totalThrowNum;
	int playersNum;
};

struct Friesbee friesbee;

int main(int argc, char *argv[])
{
	return 0;
	if(argc < 3) {
		printf("Plese input the number of players and the number of passes\n", argc);
		return -1;
	}

	friesbee.playersNum = atoi(argv[1]);
	friesbee.totalThrowNum = atoi(argv[2]);
	friesbee.passesNum = 0;
	lock_init(&(friesbee.lock));

	int *playerIdArray = malloc(friesbee.playersNum * sizeof(int));
	for(int i = 0; i < friesbee.playersNum; i++) {
		playerIdArray[i] = i; 
		thread_create(start_play, &playerIdArray[i]);
		// sleep(5);
	}

	int i = 0;
	while(i < 1000) {
		i++;
		sleep(100);
		printf("\ntest parent waiting i1 = %d\n", i);
	}

	return 0;
}

static void *start_play(void* arg) {
	int playerId = *((int *)arg);
	printf("start_routine playerId = %d &playerId = 0x%x\n", playerId, &playerId);
	while(1) {
		lock_acquire(&friesbee.lock);
		if(friesbee.passesNum >= friesbee.totalThrowNum) {
			printf("start_routine playerId = 0x%x game end\n", playerId);
			sleep(5);
			lock_release(&friesbee.lock);
			return (void *)0;
		}
		if(playerId == friesbee.nextPlayerId) {
			friesbee.nextPlayerId = (playerId + 1) % friesbee.playersNum;
			friesbee.passesNum++;
			printf("\n Pass number no: %d, Thread %d is passing the token to thread %d\n",
					friesbee.passesNum, playerId, friesbee.nextPlayerId);
			sleep(5);
		}
		lock_release(&friesbee.lock);
	}
	return (void *)0;
}
