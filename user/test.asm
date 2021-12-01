
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user/user.h"

#define PGSIZE 4096

int main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48

	// int n =0;
	// if (argc >= 2) n = atoi(argv[1]);

	void* freeptr = malloc(PGSIZE*5);
   e:	6515                	lui	a0,0x5
  10:	00000097          	auipc	ra,0x0
  14:	77a080e7          	jalr	1914(ra) # 78a <malloc>
	void* stack;
	if(freeptr == 0)
  18:	e909                	bnez	a0,2a <main+0x2a>
	}
	exit(0);



}
  1a:	557d                	li	a0,-1
  1c:	70a2                	ld	ra,40(sp)
  1e:	7402                	ld	s0,32(sp)
  20:	64e2                	ld	s1,24(sp)
  22:	6942                	ld	s2,16(sp)
  24:	69a2                	ld	s3,8(sp)
  26:	6145                	addi	sp,sp,48
  28:	8082                	ret
	stack = (void *)(PGSIZE * (((uint64)freeptr + 3*PGSIZE) / PGSIZE));
  2a:	648d                	lui	s1,0x3
  2c:	9526                	add	a0,a0,s1
  2e:	74fd                	lui	s1,0xfffff
  30:	8ce9                	and	s1,s1,a0
	printf("test stack = 0x%x\n", stack);
  32:	85a6                	mv	a1,s1
  34:	00001517          	auipc	a0,0x1
  38:	83c50513          	addi	a0,a0,-1988 # 870 <malloc+0xe6>
  3c:	00000097          	auipc	ra,0x0
  40:	690080e7          	jalr	1680(ra) # 6cc <printf>
	int ret = clone(stack, PGSIZE);
  44:	6585                	lui	a1,0x1
  46:	8526                	mv	a0,s1
  48:	00000097          	auipc	ra,0x0
  4c:	3a4080e7          	jalr	932(ra) # 3ec <clone>
  50:	892a                	mv	s2,a0
	printf("test ret = %d\n", ret);
  52:	85aa                	mv	a1,a0
  54:	00001517          	auipc	a0,0x1
  58:	83450513          	addi	a0,a0,-1996 # 888 <malloc+0xfe>
  5c:	00000097          	auipc	ra,0x0
  60:	670080e7          	jalr	1648(ra) # 6cc <printf>
		int i = 0;
  64:	4481                	li	s1,0
	if(ret == 0) {
  66:	02090b63          	beqz	s2,9c <main+0x9c>
			printf("test 2 sleep i2 = %d\n", i);
  6a:	00001997          	auipc	s3,0x1
  6e:	84e98993          	addi	s3,s3,-1970 # 8b8 <malloc+0x12e>
		while(i < 1000) {
  72:	3e800913          	li	s2,1000
			i++;
  76:	2485                	addiw	s1,s1,1
			sleep(7);
  78:	451d                	li	a0,7
  7a:	00000097          	auipc	ra,0x0
  7e:	362080e7          	jalr	866(ra) # 3dc <sleep>
			printf("test 2 sleep i2 = %d\n", i);
  82:	85a6                	mv	a1,s1
  84:	854e                	mv	a0,s3
  86:	00000097          	auipc	ra,0x0
  8a:	646080e7          	jalr	1606(ra) # 6cc <printf>
		while(i < 1000) {
  8e:	ff2494e3          	bne	s1,s2,76 <main+0x76>
	exit(0);
  92:	4501                	li	a0,0
  94:	00000097          	auipc	ra,0x0
  98:	2b8080e7          	jalr	696(ra) # 34c <exit>
		printf("test 1\n");
  9c:	00000517          	auipc	a0,0x0
  a0:	7fc50513          	addi	a0,a0,2044 # 898 <malloc+0x10e>
  a4:	00000097          	auipc	ra,0x0
  a8:	628080e7          	jalr	1576(ra) # 6cc <printf>
			printf("test 1 sleep i1 = %d\n", i);
  ac:	00000997          	auipc	s3,0x0
  b0:	7f498993          	addi	s3,s3,2036 # 8a0 <malloc+0x116>
		while(i < 1000) {
  b4:	3e800493          	li	s1,1000
			i++;
  b8:	2905                	addiw	s2,s2,1
			sleep(5);
  ba:	4515                	li	a0,5
  bc:	00000097          	auipc	ra,0x0
  c0:	320080e7          	jalr	800(ra) # 3dc <sleep>
			printf("test 1 sleep i1 = %d\n", i);
  c4:	85ca                	mv	a1,s2
  c6:	854e                	mv	a0,s3
  c8:	00000097          	auipc	ra,0x0
  cc:	604080e7          	jalr	1540(ra) # 6cc <printf>
		while(i < 1000) {
  d0:	fe9914e3          	bne	s2,s1,b8 <main+0xb8>
  d4:	bf7d                	j	92 <main+0x92>

00000000000000d6 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  d6:	1141                	addi	sp,sp,-16
  d8:	e422                	sd	s0,8(sp)
  da:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  dc:	87aa                	mv	a5,a0
  de:	0585                	addi	a1,a1,1
  e0:	0785                	addi	a5,a5,1
  e2:	fff5c703          	lbu	a4,-1(a1) # fff <__BSS_END__+0x6f7>
  e6:	fee78fa3          	sb	a4,-1(a5)
  ea:	fb75                	bnez	a4,de <strcpy+0x8>
    ;
  return os;
}
  ec:	6422                	ld	s0,8(sp)
  ee:	0141                	addi	sp,sp,16
  f0:	8082                	ret

00000000000000f2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  f2:	1141                	addi	sp,sp,-16
  f4:	e422                	sd	s0,8(sp)
  f6:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  f8:	00054783          	lbu	a5,0(a0)
  fc:	cb91                	beqz	a5,110 <strcmp+0x1e>
  fe:	0005c703          	lbu	a4,0(a1)
 102:	00f71763          	bne	a4,a5,110 <strcmp+0x1e>
    p++, q++;
 106:	0505                	addi	a0,a0,1
 108:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 10a:	00054783          	lbu	a5,0(a0)
 10e:	fbe5                	bnez	a5,fe <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 110:	0005c503          	lbu	a0,0(a1)
}
 114:	40a7853b          	subw	a0,a5,a0
 118:	6422                	ld	s0,8(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret

000000000000011e <strlen>:

uint
strlen(const char *s)
{
 11e:	1141                	addi	sp,sp,-16
 120:	e422                	sd	s0,8(sp)
 122:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 124:	00054783          	lbu	a5,0(a0)
 128:	cf91                	beqz	a5,144 <strlen+0x26>
 12a:	0505                	addi	a0,a0,1
 12c:	87aa                	mv	a5,a0
 12e:	4685                	li	a3,1
 130:	9e89                	subw	a3,a3,a0
 132:	00f6853b          	addw	a0,a3,a5
 136:	0785                	addi	a5,a5,1
 138:	fff7c703          	lbu	a4,-1(a5)
 13c:	fb7d                	bnez	a4,132 <strlen+0x14>
    ;
  return n;
}
 13e:	6422                	ld	s0,8(sp)
 140:	0141                	addi	sp,sp,16
 142:	8082                	ret
  for(n = 0; s[n]; n++)
 144:	4501                	li	a0,0
 146:	bfe5                	j	13e <strlen+0x20>

0000000000000148 <memset>:

void*
memset(void *dst, int c, uint n)
{
 148:	1141                	addi	sp,sp,-16
 14a:	e422                	sd	s0,8(sp)
 14c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 14e:	ce09                	beqz	a2,168 <memset+0x20>
 150:	87aa                	mv	a5,a0
 152:	fff6071b          	addiw	a4,a2,-1
 156:	1702                	slli	a4,a4,0x20
 158:	9301                	srli	a4,a4,0x20
 15a:	0705                	addi	a4,a4,1
 15c:	972a                	add	a4,a4,a0
    cdst[i] = c;
 15e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 162:	0785                	addi	a5,a5,1
 164:	fee79de3          	bne	a5,a4,15e <memset+0x16>
  }
  return dst;
}
 168:	6422                	ld	s0,8(sp)
 16a:	0141                	addi	sp,sp,16
 16c:	8082                	ret

000000000000016e <strchr>:

char*
strchr(const char *s, char c)
{
 16e:	1141                	addi	sp,sp,-16
 170:	e422                	sd	s0,8(sp)
 172:	0800                	addi	s0,sp,16
  for(; *s; s++)
 174:	00054783          	lbu	a5,0(a0)
 178:	cb99                	beqz	a5,18e <strchr+0x20>
    if(*s == c)
 17a:	00f58763          	beq	a1,a5,188 <strchr+0x1a>
  for(; *s; s++)
 17e:	0505                	addi	a0,a0,1
 180:	00054783          	lbu	a5,0(a0)
 184:	fbfd                	bnez	a5,17a <strchr+0xc>
      return (char*)s;
  return 0;
 186:	4501                	li	a0,0
}
 188:	6422                	ld	s0,8(sp)
 18a:	0141                	addi	sp,sp,16
 18c:	8082                	ret
  return 0;
 18e:	4501                	li	a0,0
 190:	bfe5                	j	188 <strchr+0x1a>

0000000000000192 <gets>:

char*
gets(char *buf, int max)
{
 192:	711d                	addi	sp,sp,-96
 194:	ec86                	sd	ra,88(sp)
 196:	e8a2                	sd	s0,80(sp)
 198:	e4a6                	sd	s1,72(sp)
 19a:	e0ca                	sd	s2,64(sp)
 19c:	fc4e                	sd	s3,56(sp)
 19e:	f852                	sd	s4,48(sp)
 1a0:	f456                	sd	s5,40(sp)
 1a2:	f05a                	sd	s6,32(sp)
 1a4:	ec5e                	sd	s7,24(sp)
 1a6:	1080                	addi	s0,sp,96
 1a8:	8baa                	mv	s7,a0
 1aa:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1ac:	892a                	mv	s2,a0
 1ae:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1b0:	4aa9                	li	s5,10
 1b2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1b4:	89a6                	mv	s3,s1
 1b6:	2485                	addiw	s1,s1,1
 1b8:	0344d863          	bge	s1,s4,1e8 <gets+0x56>
    cc = read(0, &c, 1);
 1bc:	4605                	li	a2,1
 1be:	faf40593          	addi	a1,s0,-81
 1c2:	4501                	li	a0,0
 1c4:	00000097          	auipc	ra,0x0
 1c8:	1a0080e7          	jalr	416(ra) # 364 <read>
    if(cc < 1)
 1cc:	00a05e63          	blez	a0,1e8 <gets+0x56>
    buf[i++] = c;
 1d0:	faf44783          	lbu	a5,-81(s0)
 1d4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1d8:	01578763          	beq	a5,s5,1e6 <gets+0x54>
 1dc:	0905                	addi	s2,s2,1
 1de:	fd679be3          	bne	a5,s6,1b4 <gets+0x22>
  for(i=0; i+1 < max; ){
 1e2:	89a6                	mv	s3,s1
 1e4:	a011                	j	1e8 <gets+0x56>
 1e6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1e8:	99de                	add	s3,s3,s7
 1ea:	00098023          	sb	zero,0(s3)
  return buf;
}
 1ee:	855e                	mv	a0,s7
 1f0:	60e6                	ld	ra,88(sp)
 1f2:	6446                	ld	s0,80(sp)
 1f4:	64a6                	ld	s1,72(sp)
 1f6:	6906                	ld	s2,64(sp)
 1f8:	79e2                	ld	s3,56(sp)
 1fa:	7a42                	ld	s4,48(sp)
 1fc:	7aa2                	ld	s5,40(sp)
 1fe:	7b02                	ld	s6,32(sp)
 200:	6be2                	ld	s7,24(sp)
 202:	6125                	addi	sp,sp,96
 204:	8082                	ret

0000000000000206 <stat>:

int
stat(const char *n, struct stat *st)
{
 206:	1101                	addi	sp,sp,-32
 208:	ec06                	sd	ra,24(sp)
 20a:	e822                	sd	s0,16(sp)
 20c:	e426                	sd	s1,8(sp)
 20e:	e04a                	sd	s2,0(sp)
 210:	1000                	addi	s0,sp,32
 212:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 214:	4581                	li	a1,0
 216:	00000097          	auipc	ra,0x0
 21a:	176080e7          	jalr	374(ra) # 38c <open>
  if(fd < 0)
 21e:	02054563          	bltz	a0,248 <stat+0x42>
 222:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 224:	85ca                	mv	a1,s2
 226:	00000097          	auipc	ra,0x0
 22a:	17e080e7          	jalr	382(ra) # 3a4 <fstat>
 22e:	892a                	mv	s2,a0
  close(fd);
 230:	8526                	mv	a0,s1
 232:	00000097          	auipc	ra,0x0
 236:	142080e7          	jalr	322(ra) # 374 <close>
  return r;
}
 23a:	854a                	mv	a0,s2
 23c:	60e2                	ld	ra,24(sp)
 23e:	6442                	ld	s0,16(sp)
 240:	64a2                	ld	s1,8(sp)
 242:	6902                	ld	s2,0(sp)
 244:	6105                	addi	sp,sp,32
 246:	8082                	ret
    return -1;
 248:	597d                	li	s2,-1
 24a:	bfc5                	j	23a <stat+0x34>

000000000000024c <atoi>:

int
atoi(const char *s)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 252:	00054603          	lbu	a2,0(a0)
 256:	fd06079b          	addiw	a5,a2,-48
 25a:	0ff7f793          	andi	a5,a5,255
 25e:	4725                	li	a4,9
 260:	02f76963          	bltu	a4,a5,292 <atoi+0x46>
 264:	86aa                	mv	a3,a0
  n = 0;
 266:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 268:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 26a:	0685                	addi	a3,a3,1
 26c:	0025179b          	slliw	a5,a0,0x2
 270:	9fa9                	addw	a5,a5,a0
 272:	0017979b          	slliw	a5,a5,0x1
 276:	9fb1                	addw	a5,a5,a2
 278:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 27c:	0006c603          	lbu	a2,0(a3)
 280:	fd06071b          	addiw	a4,a2,-48
 284:	0ff77713          	andi	a4,a4,255
 288:	fee5f1e3          	bgeu	a1,a4,26a <atoi+0x1e>
  return n;
}
 28c:	6422                	ld	s0,8(sp)
 28e:	0141                	addi	sp,sp,16
 290:	8082                	ret
  n = 0;
 292:	4501                	li	a0,0
 294:	bfe5                	j	28c <atoi+0x40>

0000000000000296 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 296:	1141                	addi	sp,sp,-16
 298:	e422                	sd	s0,8(sp)
 29a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 29c:	02b57663          	bgeu	a0,a1,2c8 <memmove+0x32>
    while(n-- > 0)
 2a0:	02c05163          	blez	a2,2c2 <memmove+0x2c>
 2a4:	fff6079b          	addiw	a5,a2,-1
 2a8:	1782                	slli	a5,a5,0x20
 2aa:	9381                	srli	a5,a5,0x20
 2ac:	0785                	addi	a5,a5,1
 2ae:	97aa                	add	a5,a5,a0
  dst = vdst;
 2b0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2b2:	0585                	addi	a1,a1,1
 2b4:	0705                	addi	a4,a4,1
 2b6:	fff5c683          	lbu	a3,-1(a1)
 2ba:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2be:	fee79ae3          	bne	a5,a4,2b2 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2c2:	6422                	ld	s0,8(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret
    dst += n;
 2c8:	00c50733          	add	a4,a0,a2
    src += n;
 2cc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ce:	fec05ae3          	blez	a2,2c2 <memmove+0x2c>
 2d2:	fff6079b          	addiw	a5,a2,-1
 2d6:	1782                	slli	a5,a5,0x20
 2d8:	9381                	srli	a5,a5,0x20
 2da:	fff7c793          	not	a5,a5
 2de:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2e0:	15fd                	addi	a1,a1,-1
 2e2:	177d                	addi	a4,a4,-1
 2e4:	0005c683          	lbu	a3,0(a1)
 2e8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ec:	fee79ae3          	bne	a5,a4,2e0 <memmove+0x4a>
 2f0:	bfc9                	j	2c2 <memmove+0x2c>

00000000000002f2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2f2:	1141                	addi	sp,sp,-16
 2f4:	e422                	sd	s0,8(sp)
 2f6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2f8:	ca05                	beqz	a2,328 <memcmp+0x36>
 2fa:	fff6069b          	addiw	a3,a2,-1
 2fe:	1682                	slli	a3,a3,0x20
 300:	9281                	srli	a3,a3,0x20
 302:	0685                	addi	a3,a3,1
 304:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 306:	00054783          	lbu	a5,0(a0)
 30a:	0005c703          	lbu	a4,0(a1)
 30e:	00e79863          	bne	a5,a4,31e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 312:	0505                	addi	a0,a0,1
    p2++;
 314:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 316:	fed518e3          	bne	a0,a3,306 <memcmp+0x14>
  }
  return 0;
 31a:	4501                	li	a0,0
 31c:	a019                	j	322 <memcmp+0x30>
      return *p1 - *p2;
 31e:	40e7853b          	subw	a0,a5,a4
}
 322:	6422                	ld	s0,8(sp)
 324:	0141                	addi	sp,sp,16
 326:	8082                	ret
  return 0;
 328:	4501                	li	a0,0
 32a:	bfe5                	j	322 <memcmp+0x30>

000000000000032c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 32c:	1141                	addi	sp,sp,-16
 32e:	e406                	sd	ra,8(sp)
 330:	e022                	sd	s0,0(sp)
 332:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 334:	00000097          	auipc	ra,0x0
 338:	f62080e7          	jalr	-158(ra) # 296 <memmove>
}
 33c:	60a2                	ld	ra,8(sp)
 33e:	6402                	ld	s0,0(sp)
 340:	0141                	addi	sp,sp,16
 342:	8082                	ret

0000000000000344 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 344:	4885                	li	a7,1
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <exit>:
.global exit
exit:
 li a7, SYS_exit
 34c:	4889                	li	a7,2
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <wait>:
.global wait
wait:
 li a7, SYS_wait
 354:	488d                	li	a7,3
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 35c:	4891                	li	a7,4
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <read>:
.global read
read:
 li a7, SYS_read
 364:	4895                	li	a7,5
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <write>:
.global write
write:
 li a7, SYS_write
 36c:	48c1                	li	a7,16
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <close>:
.global close
close:
 li a7, SYS_close
 374:	48d5                	li	a7,21
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <kill>:
.global kill
kill:
 li a7, SYS_kill
 37c:	4899                	li	a7,6
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <exec>:
.global exec
exec:
 li a7, SYS_exec
 384:	489d                	li	a7,7
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <open>:
.global open
open:
 li a7, SYS_open
 38c:	48bd                	li	a7,15
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 394:	48c5                	li	a7,17
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 39c:	48c9                	li	a7,18
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3a4:	48a1                	li	a7,8
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <link>:
.global link
link:
 li a7, SYS_link
 3ac:	48cd                	li	a7,19
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3b4:	48d1                	li	a7,20
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3bc:	48a5                	li	a7,9
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3c4:	48a9                	li	a7,10
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3cc:	48ad                	li	a7,11
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3d4:	48b1                	li	a7,12
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3dc:	48b5                	li	a7,13
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3e4:	48b9                	li	a7,14
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <clone>:
.global clone
clone:
 li a7, SYS_clone
 3ec:	48d9                	li	a7,22
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f4:	1101                	addi	sp,sp,-32
 3f6:	ec06                	sd	ra,24(sp)
 3f8:	e822                	sd	s0,16(sp)
 3fa:	1000                	addi	s0,sp,32
 3fc:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 400:	4605                	li	a2,1
 402:	fef40593          	addi	a1,s0,-17
 406:	00000097          	auipc	ra,0x0
 40a:	f66080e7          	jalr	-154(ra) # 36c <write>
}
 40e:	60e2                	ld	ra,24(sp)
 410:	6442                	ld	s0,16(sp)
 412:	6105                	addi	sp,sp,32
 414:	8082                	ret

0000000000000416 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 416:	7139                	addi	sp,sp,-64
 418:	fc06                	sd	ra,56(sp)
 41a:	f822                	sd	s0,48(sp)
 41c:	f426                	sd	s1,40(sp)
 41e:	f04a                	sd	s2,32(sp)
 420:	ec4e                	sd	s3,24(sp)
 422:	0080                	addi	s0,sp,64
 424:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 426:	c299                	beqz	a3,42c <printint+0x16>
 428:	0805c863          	bltz	a1,4b8 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42c:	2581                	sext.w	a1,a1
  neg = 0;
 42e:	4881                	li	a7,0
 430:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 434:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 436:	2601                	sext.w	a2,a2
 438:	00000517          	auipc	a0,0x0
 43c:	4a050513          	addi	a0,a0,1184 # 8d8 <digits>
 440:	883a                	mv	a6,a4
 442:	2705                	addiw	a4,a4,1
 444:	02c5f7bb          	remuw	a5,a1,a2
 448:	1782                	slli	a5,a5,0x20
 44a:	9381                	srli	a5,a5,0x20
 44c:	97aa                	add	a5,a5,a0
 44e:	0007c783          	lbu	a5,0(a5)
 452:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 456:	0005879b          	sext.w	a5,a1
 45a:	02c5d5bb          	divuw	a1,a1,a2
 45e:	0685                	addi	a3,a3,1
 460:	fec7f0e3          	bgeu	a5,a2,440 <printint+0x2a>
  if(neg)
 464:	00088b63          	beqz	a7,47a <printint+0x64>
    buf[i++] = '-';
 468:	fd040793          	addi	a5,s0,-48
 46c:	973e                	add	a4,a4,a5
 46e:	02d00793          	li	a5,45
 472:	fef70823          	sb	a5,-16(a4)
 476:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 47a:	02e05863          	blez	a4,4aa <printint+0x94>
 47e:	fc040793          	addi	a5,s0,-64
 482:	00e78933          	add	s2,a5,a4
 486:	fff78993          	addi	s3,a5,-1
 48a:	99ba                	add	s3,s3,a4
 48c:	377d                	addiw	a4,a4,-1
 48e:	1702                	slli	a4,a4,0x20
 490:	9301                	srli	a4,a4,0x20
 492:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 496:	fff94583          	lbu	a1,-1(s2)
 49a:	8526                	mv	a0,s1
 49c:	00000097          	auipc	ra,0x0
 4a0:	f58080e7          	jalr	-168(ra) # 3f4 <putc>
  while(--i >= 0)
 4a4:	197d                	addi	s2,s2,-1
 4a6:	ff3918e3          	bne	s2,s3,496 <printint+0x80>
}
 4aa:	70e2                	ld	ra,56(sp)
 4ac:	7442                	ld	s0,48(sp)
 4ae:	74a2                	ld	s1,40(sp)
 4b0:	7902                	ld	s2,32(sp)
 4b2:	69e2                	ld	s3,24(sp)
 4b4:	6121                	addi	sp,sp,64
 4b6:	8082                	ret
    x = -xx;
 4b8:	40b005bb          	negw	a1,a1
    neg = 1;
 4bc:	4885                	li	a7,1
    x = -xx;
 4be:	bf8d                	j	430 <printint+0x1a>

00000000000004c0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4c0:	7119                	addi	sp,sp,-128
 4c2:	fc86                	sd	ra,120(sp)
 4c4:	f8a2                	sd	s0,112(sp)
 4c6:	f4a6                	sd	s1,104(sp)
 4c8:	f0ca                	sd	s2,96(sp)
 4ca:	ecce                	sd	s3,88(sp)
 4cc:	e8d2                	sd	s4,80(sp)
 4ce:	e4d6                	sd	s5,72(sp)
 4d0:	e0da                	sd	s6,64(sp)
 4d2:	fc5e                	sd	s7,56(sp)
 4d4:	f862                	sd	s8,48(sp)
 4d6:	f466                	sd	s9,40(sp)
 4d8:	f06a                	sd	s10,32(sp)
 4da:	ec6e                	sd	s11,24(sp)
 4dc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4de:	0005c903          	lbu	s2,0(a1)
 4e2:	18090f63          	beqz	s2,680 <vprintf+0x1c0>
 4e6:	8aaa                	mv	s5,a0
 4e8:	8b32                	mv	s6,a2
 4ea:	00158493          	addi	s1,a1,1
  state = 0;
 4ee:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4f0:	02500a13          	li	s4,37
      if(c == 'd'){
 4f4:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4f8:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4fc:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 500:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 504:	00000b97          	auipc	s7,0x0
 508:	3d4b8b93          	addi	s7,s7,980 # 8d8 <digits>
 50c:	a839                	j	52a <vprintf+0x6a>
        putc(fd, c);
 50e:	85ca                	mv	a1,s2
 510:	8556                	mv	a0,s5
 512:	00000097          	auipc	ra,0x0
 516:	ee2080e7          	jalr	-286(ra) # 3f4 <putc>
 51a:	a019                	j	520 <vprintf+0x60>
    } else if(state == '%'){
 51c:	01498f63          	beq	s3,s4,53a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 520:	0485                	addi	s1,s1,1
 522:	fff4c903          	lbu	s2,-1(s1) # ffffffffffffefff <__global_pointer$+0xffffffffffffdf16>
 526:	14090d63          	beqz	s2,680 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 52a:	0009079b          	sext.w	a5,s2
    if(state == 0){
 52e:	fe0997e3          	bnez	s3,51c <vprintf+0x5c>
      if(c == '%'){
 532:	fd479ee3          	bne	a5,s4,50e <vprintf+0x4e>
        state = '%';
 536:	89be                	mv	s3,a5
 538:	b7e5                	j	520 <vprintf+0x60>
      if(c == 'd'){
 53a:	05878063          	beq	a5,s8,57a <vprintf+0xba>
      } else if(c == 'l') {
 53e:	05978c63          	beq	a5,s9,596 <vprintf+0xd6>
      } else if(c == 'x') {
 542:	07a78863          	beq	a5,s10,5b2 <vprintf+0xf2>
      } else if(c == 'p') {
 546:	09b78463          	beq	a5,s11,5ce <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 54a:	07300713          	li	a4,115
 54e:	0ce78663          	beq	a5,a4,61a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 552:	06300713          	li	a4,99
 556:	0ee78e63          	beq	a5,a4,652 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 55a:	11478863          	beq	a5,s4,66a <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 55e:	85d2                	mv	a1,s4
 560:	8556                	mv	a0,s5
 562:	00000097          	auipc	ra,0x0
 566:	e92080e7          	jalr	-366(ra) # 3f4 <putc>
        putc(fd, c);
 56a:	85ca                	mv	a1,s2
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e86080e7          	jalr	-378(ra) # 3f4 <putc>
      }
      state = 0;
 576:	4981                	li	s3,0
 578:	b765                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 57a:	008b0913          	addi	s2,s6,8
 57e:	4685                	li	a3,1
 580:	4629                	li	a2,10
 582:	000b2583          	lw	a1,0(s6)
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e8e080e7          	jalr	-370(ra) # 416 <printint>
 590:	8b4a                	mv	s6,s2
      state = 0;
 592:	4981                	li	s3,0
 594:	b771                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 596:	008b0913          	addi	s2,s6,8
 59a:	4681                	li	a3,0
 59c:	4629                	li	a2,10
 59e:	000b2583          	lw	a1,0(s6)
 5a2:	8556                	mv	a0,s5
 5a4:	00000097          	auipc	ra,0x0
 5a8:	e72080e7          	jalr	-398(ra) # 416 <printint>
 5ac:	8b4a                	mv	s6,s2
      state = 0;
 5ae:	4981                	li	s3,0
 5b0:	bf85                	j	520 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b2:	008b0913          	addi	s2,s6,8
 5b6:	4681                	li	a3,0
 5b8:	4641                	li	a2,16
 5ba:	000b2583          	lw	a1,0(s6)
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	e56080e7          	jalr	-426(ra) # 416 <printint>
 5c8:	8b4a                	mv	s6,s2
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	bf91                	j	520 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5ce:	008b0793          	addi	a5,s6,8
 5d2:	f8f43423          	sd	a5,-120(s0)
 5d6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5da:	03000593          	li	a1,48
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	e14080e7          	jalr	-492(ra) # 3f4 <putc>
  putc(fd, 'x');
 5e8:	85ea                	mv	a1,s10
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e08080e7          	jalr	-504(ra) # 3f4 <putc>
 5f4:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f6:	03c9d793          	srli	a5,s3,0x3c
 5fa:	97de                	add	a5,a5,s7
 5fc:	0007c583          	lbu	a1,0(a5)
 600:	8556                	mv	a0,s5
 602:	00000097          	auipc	ra,0x0
 606:	df2080e7          	jalr	-526(ra) # 3f4 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 60a:	0992                	slli	s3,s3,0x4
 60c:	397d                	addiw	s2,s2,-1
 60e:	fe0914e3          	bnez	s2,5f6 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 612:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 616:	4981                	li	s3,0
 618:	b721                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 61a:	008b0993          	addi	s3,s6,8
 61e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 622:	02090163          	beqz	s2,644 <vprintf+0x184>
        while(*s != 0){
 626:	00094583          	lbu	a1,0(s2)
 62a:	c9a1                	beqz	a1,67a <vprintf+0x1ba>
          putc(fd, *s);
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	dc6080e7          	jalr	-570(ra) # 3f4 <putc>
          s++;
 636:	0905                	addi	s2,s2,1
        while(*s != 0){
 638:	00094583          	lbu	a1,0(s2)
 63c:	f9e5                	bnez	a1,62c <vprintf+0x16c>
        s = va_arg(ap, char*);
 63e:	8b4e                	mv	s6,s3
      state = 0;
 640:	4981                	li	s3,0
 642:	bdf9                	j	520 <vprintf+0x60>
          s = "(null)";
 644:	00000917          	auipc	s2,0x0
 648:	28c90913          	addi	s2,s2,652 # 8d0 <malloc+0x146>
        while(*s != 0){
 64c:	02800593          	li	a1,40
 650:	bff1                	j	62c <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 652:	008b0913          	addi	s2,s6,8
 656:	000b4583          	lbu	a1,0(s6)
 65a:	8556                	mv	a0,s5
 65c:	00000097          	auipc	ra,0x0
 660:	d98080e7          	jalr	-616(ra) # 3f4 <putc>
 664:	8b4a                	mv	s6,s2
      state = 0;
 666:	4981                	li	s3,0
 668:	bd65                	j	520 <vprintf+0x60>
        putc(fd, c);
 66a:	85d2                	mv	a1,s4
 66c:	8556                	mv	a0,s5
 66e:	00000097          	auipc	ra,0x0
 672:	d86080e7          	jalr	-634(ra) # 3f4 <putc>
      state = 0;
 676:	4981                	li	s3,0
 678:	b565                	j	520 <vprintf+0x60>
        s = va_arg(ap, char*);
 67a:	8b4e                	mv	s6,s3
      state = 0;
 67c:	4981                	li	s3,0
 67e:	b54d                	j	520 <vprintf+0x60>
    }
  }
}
 680:	70e6                	ld	ra,120(sp)
 682:	7446                	ld	s0,112(sp)
 684:	74a6                	ld	s1,104(sp)
 686:	7906                	ld	s2,96(sp)
 688:	69e6                	ld	s3,88(sp)
 68a:	6a46                	ld	s4,80(sp)
 68c:	6aa6                	ld	s5,72(sp)
 68e:	6b06                	ld	s6,64(sp)
 690:	7be2                	ld	s7,56(sp)
 692:	7c42                	ld	s8,48(sp)
 694:	7ca2                	ld	s9,40(sp)
 696:	7d02                	ld	s10,32(sp)
 698:	6de2                	ld	s11,24(sp)
 69a:	6109                	addi	sp,sp,128
 69c:	8082                	ret

000000000000069e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69e:	715d                	addi	sp,sp,-80
 6a0:	ec06                	sd	ra,24(sp)
 6a2:	e822                	sd	s0,16(sp)
 6a4:	1000                	addi	s0,sp,32
 6a6:	e010                	sd	a2,0(s0)
 6a8:	e414                	sd	a3,8(s0)
 6aa:	e818                	sd	a4,16(s0)
 6ac:	ec1c                	sd	a5,24(s0)
 6ae:	03043023          	sd	a6,32(s0)
 6b2:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b6:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6ba:	8622                	mv	a2,s0
 6bc:	00000097          	auipc	ra,0x0
 6c0:	e04080e7          	jalr	-508(ra) # 4c0 <vprintf>
}
 6c4:	60e2                	ld	ra,24(sp)
 6c6:	6442                	ld	s0,16(sp)
 6c8:	6161                	addi	sp,sp,80
 6ca:	8082                	ret

00000000000006cc <printf>:

void
printf(const char *fmt, ...)
{
 6cc:	711d                	addi	sp,sp,-96
 6ce:	ec06                	sd	ra,24(sp)
 6d0:	e822                	sd	s0,16(sp)
 6d2:	1000                	addi	s0,sp,32
 6d4:	e40c                	sd	a1,8(s0)
 6d6:	e810                	sd	a2,16(s0)
 6d8:	ec14                	sd	a3,24(s0)
 6da:	f018                	sd	a4,32(s0)
 6dc:	f41c                	sd	a5,40(s0)
 6de:	03043823          	sd	a6,48(s0)
 6e2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e6:	00840613          	addi	a2,s0,8
 6ea:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ee:	85aa                	mv	a1,a0
 6f0:	4505                	li	a0,1
 6f2:	00000097          	auipc	ra,0x0
 6f6:	dce080e7          	jalr	-562(ra) # 4c0 <vprintf>
}
 6fa:	60e2                	ld	ra,24(sp)
 6fc:	6442                	ld	s0,16(sp)
 6fe:	6125                	addi	sp,sp,96
 700:	8082                	ret

0000000000000702 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 702:	1141                	addi	sp,sp,-16
 704:	e422                	sd	s0,8(sp)
 706:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 708:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70c:	00000797          	auipc	a5,0x0
 710:	1e47b783          	ld	a5,484(a5) # 8f0 <freep>
 714:	a805                	j	744 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 716:	4618                	lw	a4,8(a2)
 718:	9db9                	addw	a1,a1,a4
 71a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71e:	6398                	ld	a4,0(a5)
 720:	6318                	ld	a4,0(a4)
 722:	fee53823          	sd	a4,-16(a0)
 726:	a091                	j	76a <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 728:	ff852703          	lw	a4,-8(a0)
 72c:	9e39                	addw	a2,a2,a4
 72e:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 730:	ff053703          	ld	a4,-16(a0)
 734:	e398                	sd	a4,0(a5)
 736:	a099                	j	77c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 738:	6398                	ld	a4,0(a5)
 73a:	00e7e463          	bltu	a5,a4,742 <free+0x40>
 73e:	00e6ea63          	bltu	a3,a4,752 <free+0x50>
{
 742:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 744:	fed7fae3          	bgeu	a5,a3,738 <free+0x36>
 748:	6398                	ld	a4,0(a5)
 74a:	00e6e463          	bltu	a3,a4,752 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74e:	fee7eae3          	bltu	a5,a4,742 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 752:	ff852583          	lw	a1,-8(a0)
 756:	6390                	ld	a2,0(a5)
 758:	02059713          	slli	a4,a1,0x20
 75c:	9301                	srli	a4,a4,0x20
 75e:	0712                	slli	a4,a4,0x4
 760:	9736                	add	a4,a4,a3
 762:	fae60ae3          	beq	a2,a4,716 <free+0x14>
    bp->s.ptr = p->s.ptr;
 766:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 76a:	4790                	lw	a2,8(a5)
 76c:	02061713          	slli	a4,a2,0x20
 770:	9301                	srli	a4,a4,0x20
 772:	0712                	slli	a4,a4,0x4
 774:	973e                	add	a4,a4,a5
 776:	fae689e3          	beq	a3,a4,728 <free+0x26>
  } else
    p->s.ptr = bp;
 77a:	e394                	sd	a3,0(a5)
  freep = p;
 77c:	00000717          	auipc	a4,0x0
 780:	16f73a23          	sd	a5,372(a4) # 8f0 <freep>
}
 784:	6422                	ld	s0,8(sp)
 786:	0141                	addi	sp,sp,16
 788:	8082                	ret

000000000000078a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 78a:	7139                	addi	sp,sp,-64
 78c:	fc06                	sd	ra,56(sp)
 78e:	f822                	sd	s0,48(sp)
 790:	f426                	sd	s1,40(sp)
 792:	f04a                	sd	s2,32(sp)
 794:	ec4e                	sd	s3,24(sp)
 796:	e852                	sd	s4,16(sp)
 798:	e456                	sd	s5,8(sp)
 79a:	e05a                	sd	s6,0(sp)
 79c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 79e:	02051493          	slli	s1,a0,0x20
 7a2:	9081                	srli	s1,s1,0x20
 7a4:	04bd                	addi	s1,s1,15
 7a6:	8091                	srli	s1,s1,0x4
 7a8:	0014899b          	addiw	s3,s1,1
 7ac:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ae:	00000517          	auipc	a0,0x0
 7b2:	14253503          	ld	a0,322(a0) # 8f0 <freep>
 7b6:	c515                	beqz	a0,7e2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7ba:	4798                	lw	a4,8(a5)
 7bc:	02977f63          	bgeu	a4,s1,7fa <malloc+0x70>
 7c0:	8a4e                	mv	s4,s3
 7c2:	0009871b          	sext.w	a4,s3
 7c6:	6685                	lui	a3,0x1
 7c8:	00d77363          	bgeu	a4,a3,7ce <malloc+0x44>
 7cc:	6a05                	lui	s4,0x1
 7ce:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d6:	00000917          	auipc	s2,0x0
 7da:	11a90913          	addi	s2,s2,282 # 8f0 <freep>
  if(p == (char*)-1)
 7de:	5afd                	li	s5,-1
 7e0:	a88d                	j	852 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7e2:	00000797          	auipc	a5,0x0
 7e6:	11678793          	addi	a5,a5,278 # 8f8 <base>
 7ea:	00000717          	auipc	a4,0x0
 7ee:	10f73323          	sd	a5,262(a4) # 8f0 <freep>
 7f2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f8:	b7e1                	j	7c0 <malloc+0x36>
      if(p->s.size == nunits)
 7fa:	02e48b63          	beq	s1,a4,830 <malloc+0xa6>
        p->s.size -= nunits;
 7fe:	4137073b          	subw	a4,a4,s3
 802:	c798                	sw	a4,8(a5)
        p += p->s.size;
 804:	1702                	slli	a4,a4,0x20
 806:	9301                	srli	a4,a4,0x20
 808:	0712                	slli	a4,a4,0x4
 80a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 810:	00000717          	auipc	a4,0x0
 814:	0ea73023          	sd	a0,224(a4) # 8f0 <freep>
      return (void*)(p + 1);
 818:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81c:	70e2                	ld	ra,56(sp)
 81e:	7442                	ld	s0,48(sp)
 820:	74a2                	ld	s1,40(sp)
 822:	7902                	ld	s2,32(sp)
 824:	69e2                	ld	s3,24(sp)
 826:	6a42                	ld	s4,16(sp)
 828:	6aa2                	ld	s5,8(sp)
 82a:	6b02                	ld	s6,0(sp)
 82c:	6121                	addi	sp,sp,64
 82e:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 830:	6398                	ld	a4,0(a5)
 832:	e118                	sd	a4,0(a0)
 834:	bff1                	j	810 <malloc+0x86>
  hp->s.size = nu;
 836:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 83a:	0541                	addi	a0,a0,16
 83c:	00000097          	auipc	ra,0x0
 840:	ec6080e7          	jalr	-314(ra) # 702 <free>
  return freep;
 844:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 848:	d971                	beqz	a0,81c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 84a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84c:	4798                	lw	a4,8(a5)
 84e:	fa9776e3          	bgeu	a4,s1,7fa <malloc+0x70>
    if(p == freep)
 852:	00093703          	ld	a4,0(s2)
 856:	853e                	mv	a0,a5
 858:	fef719e3          	bne	a4,a5,84a <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 85c:	8552                	mv	a0,s4
 85e:	00000097          	auipc	ra,0x0
 862:	b76080e7          	jalr	-1162(ra) # 3d4 <sbrk>
  if(p == (char*)-1)
 866:	fd5518e3          	bne	a0,s5,836 <malloc+0xac>
        return 0;
 86a:	4501                	li	a0,0
 86c:	bf45                	j	81c <malloc+0x92>
