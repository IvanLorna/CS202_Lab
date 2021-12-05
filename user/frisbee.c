#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "tlib.h"

#define PGSIZE 4096

static void *start_play(void* arg);

struct Frisbee {
	struct lock_t lock;
	int nextPlayerId;
	int passesNum;
	int totalThrowNum;
	int playersNum;
};

struct Frisbee frisbee;

int main(int argc, char *argv[])
{
	if(argc < 3) {
		printf("Plese input the number of players and the number of passes\n", argc);
		return -1;
	}

	frisbee.playersNum = atoi(argv[1]);
	frisbee.totalThrowNum = atoi(argv[2]);
	frisbee.passesNum = 0;
	lock_init(&(frisbee.lock));

	int *playerIdArray = malloc(frisbee.playersNum * sizeof(int));
	for(int i = 0; i < frisbee.playersNum; i++) {
		playerIdArray[i] = i; 
		thread_create(start_play, &playerIdArray[i]);
		// sleep(5);
	}
	sleep(50);
	// printf("\ntest parent waiting...\n");
	wait(0);
	// printf("\ntest parent waiting pid = %d\n", pid);

	free(playerIdArray);
	
	printf("Simulation of Frisbee game has finished, %d rounds were played in total!\n", frisbee.totalThrowNum);

	exit(0);
}

static void *start_play(void* arg) {
	int playerId = *((int *)arg);
	// printf("start_routine playerId = %d &playerId = 0x%x\n", playerId, &playerId);
	while(1) {
		lock_acquire(&frisbee.lock);
		if(frisbee.passesNum >= frisbee.totalThrowNum) {
			// printf("start_routine playerId = 0x%x game end\n", playerId);
			sleep(5);
			lock_release(&frisbee.lock);
			return (void *)0;
		}
		if(playerId == frisbee.nextPlayerId) {
			frisbee.nextPlayerId = (playerId + 1) % frisbee.playersNum;
			frisbee.passesNum++;
			printf("\n Pass number no: %d, Thread %d is passing the token to thread %d\n",
					frisbee.passesNum, playerId, frisbee.nextPlayerId);
			sleep(5);
		}
		lock_release(&frisbee.lock);
	}
	return (void *)0;
}
