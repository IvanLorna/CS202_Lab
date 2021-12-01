
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	1800                	addi	s0,sp,48
	int n =0;
	if (argc >= 2) n = atoi(argv[1]);
   c:	4785                	li	a5,1
	int n =0;
   e:	4901                	li	s2,0
	if (argc >= 2) n = atoi(argv[1]);
  10:	04a7c463          	blt	a5,a0,58 <main+0x58>
	
	int size = 40;
	int stack = 40;


	int p = 0;//myproc()->pagetable;
  14:	fc042e23          	sw	zero,-36(s0)
	int c = clone(&p + stack, size);
  18:	02800593          	li	a1,40
  1c:	07c40513          	addi	a0,s0,124
  20:	00000097          	auipc	ra,0x0
  24:	35c080e7          	jalr	860(ra) # 37c <clone>
  28:	84aa                	mv	s1,a0
	//clone(&p + stack, size);
	
	printf("mode: %d\n", n);
  2a:	85ca                	mv	a1,s2
  2c:	00000517          	auipc	a0,0x0
  30:	7d450513          	addi	a0,a0,2004 # 800 <malloc+0xe6>
  34:	00000097          	auipc	ra,0x0
  38:	628080e7          	jalr	1576(ra) # 65c <printf>
	//printf("my pid: ???");
	printf("clone pid: %d\n", c);
  3c:	85a6                	mv	a1,s1
  3e:	00000517          	auipc	a0,0x0
  42:	7d250513          	addi	a0,a0,2002 # 810 <malloc+0xf6>
  46:	00000097          	auipc	ra,0x0
  4a:	616080e7          	jalr	1558(ra) # 65c <printf>
	exit(0);
  4e:	4501                	li	a0,0
  50:	00000097          	auipc	ra,0x0
  54:	28c080e7          	jalr	652(ra) # 2dc <exit>
	if (argc >= 2) n = atoi(argv[1]);
  58:	6588                	ld	a0,8(a1)
  5a:	00000097          	auipc	ra,0x0
  5e:	182080e7          	jalr	386(ra) # 1dc <atoi>
  62:	892a                	mv	s2,a0
  64:	bf45                	j	14 <main+0x14>

0000000000000066 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  66:	1141                	addi	sp,sp,-16
  68:	e422                	sd	s0,8(sp)
  6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  6c:	87aa                	mv	a5,a0
  6e:	0585                	addi	a1,a1,1
  70:	0785                	addi	a5,a5,1
  72:	fff5c703          	lbu	a4,-1(a1)
  76:	fee78fa3          	sb	a4,-1(a5)
  7a:	fb75                	bnez	a4,6e <strcpy+0x8>
    ;
  return os;
}
  7c:	6422                	ld	s0,8(sp)
  7e:	0141                	addi	sp,sp,16
  80:	8082                	ret

0000000000000082 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  82:	1141                	addi	sp,sp,-16
  84:	e422                	sd	s0,8(sp)
  86:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  88:	00054783          	lbu	a5,0(a0)
  8c:	cb91                	beqz	a5,a0 <strcmp+0x1e>
  8e:	0005c703          	lbu	a4,0(a1)
  92:	00f71763          	bne	a4,a5,a0 <strcmp+0x1e>
    p++, q++;
  96:	0505                	addi	a0,a0,1
  98:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	fbe5                	bnez	a5,8e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  a0:	0005c503          	lbu	a0,0(a1)
}
  a4:	40a7853b          	subw	a0,a5,a0
  a8:	6422                	ld	s0,8(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret

00000000000000ae <strlen>:

uint
strlen(const char *s)
{
  ae:	1141                	addi	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  b4:	00054783          	lbu	a5,0(a0)
  b8:	cf91                	beqz	a5,d4 <strlen+0x26>
  ba:	0505                	addi	a0,a0,1
  bc:	87aa                	mv	a5,a0
  be:	4685                	li	a3,1
  c0:	9e89                	subw	a3,a3,a0
  c2:	00f6853b          	addw	a0,a3,a5
  c6:	0785                	addi	a5,a5,1
  c8:	fff7c703          	lbu	a4,-1(a5)
  cc:	fb7d                	bnez	a4,c2 <strlen+0x14>
    ;
  return n;
}
  ce:	6422                	ld	s0,8(sp)
  d0:	0141                	addi	sp,sp,16
  d2:	8082                	ret
  for(n = 0; s[n]; n++)
  d4:	4501                	li	a0,0
  d6:	bfe5                	j	ce <strlen+0x20>

00000000000000d8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  d8:	1141                	addi	sp,sp,-16
  da:	e422                	sd	s0,8(sp)
  dc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  de:	ce09                	beqz	a2,f8 <memset+0x20>
  e0:	87aa                	mv	a5,a0
  e2:	fff6071b          	addiw	a4,a2,-1
  e6:	1702                	slli	a4,a4,0x20
  e8:	9301                	srli	a4,a4,0x20
  ea:	0705                	addi	a4,a4,1
  ec:	972a                	add	a4,a4,a0
    cdst[i] = c;
  ee:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  f2:	0785                	addi	a5,a5,1
  f4:	fee79de3          	bne	a5,a4,ee <memset+0x16>
  }
  return dst;
}
  f8:	6422                	ld	s0,8(sp)
  fa:	0141                	addi	sp,sp,16
  fc:	8082                	ret

00000000000000fe <strchr>:

char*
strchr(const char *s, char c)
{
  fe:	1141                	addi	sp,sp,-16
 100:	e422                	sd	s0,8(sp)
 102:	0800                	addi	s0,sp,16
  for(; *s; s++)
 104:	00054783          	lbu	a5,0(a0)
 108:	cb99                	beqz	a5,11e <strchr+0x20>
    if(*s == c)
 10a:	00f58763          	beq	a1,a5,118 <strchr+0x1a>
  for(; *s; s++)
 10e:	0505                	addi	a0,a0,1
 110:	00054783          	lbu	a5,0(a0)
 114:	fbfd                	bnez	a5,10a <strchr+0xc>
      return (char*)s;
  return 0;
 116:	4501                	li	a0,0
}
 118:	6422                	ld	s0,8(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret
  return 0;
 11e:	4501                	li	a0,0
 120:	bfe5                	j	118 <strchr+0x1a>

0000000000000122 <gets>:

char*
gets(char *buf, int max)
{
 122:	711d                	addi	sp,sp,-96
 124:	ec86                	sd	ra,88(sp)
 126:	e8a2                	sd	s0,80(sp)
 128:	e4a6                	sd	s1,72(sp)
 12a:	e0ca                	sd	s2,64(sp)
 12c:	fc4e                	sd	s3,56(sp)
 12e:	f852                	sd	s4,48(sp)
 130:	f456                	sd	s5,40(sp)
 132:	f05a                	sd	s6,32(sp)
 134:	ec5e                	sd	s7,24(sp)
 136:	1080                	addi	s0,sp,96
 138:	8baa                	mv	s7,a0
 13a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 13c:	892a                	mv	s2,a0
 13e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 140:	4aa9                	li	s5,10
 142:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 144:	89a6                	mv	s3,s1
 146:	2485                	addiw	s1,s1,1
 148:	0344d863          	bge	s1,s4,178 <gets+0x56>
    cc = read(0, &c, 1);
 14c:	4605                	li	a2,1
 14e:	faf40593          	addi	a1,s0,-81
 152:	4501                	li	a0,0
 154:	00000097          	auipc	ra,0x0
 158:	1a0080e7          	jalr	416(ra) # 2f4 <read>
    if(cc < 1)
 15c:	00a05e63          	blez	a0,178 <gets+0x56>
    buf[i++] = c;
 160:	faf44783          	lbu	a5,-81(s0)
 164:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 168:	01578763          	beq	a5,s5,176 <gets+0x54>
 16c:	0905                	addi	s2,s2,1
 16e:	fd679be3          	bne	a5,s6,144 <gets+0x22>
  for(i=0; i+1 < max; ){
 172:	89a6                	mv	s3,s1
 174:	a011                	j	178 <gets+0x56>
 176:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 178:	99de                	add	s3,s3,s7
 17a:	00098023          	sb	zero,0(s3)
  return buf;
}
 17e:	855e                	mv	a0,s7
 180:	60e6                	ld	ra,88(sp)
 182:	6446                	ld	s0,80(sp)
 184:	64a6                	ld	s1,72(sp)
 186:	6906                	ld	s2,64(sp)
 188:	79e2                	ld	s3,56(sp)
 18a:	7a42                	ld	s4,48(sp)
 18c:	7aa2                	ld	s5,40(sp)
 18e:	7b02                	ld	s6,32(sp)
 190:	6be2                	ld	s7,24(sp)
 192:	6125                	addi	sp,sp,96
 194:	8082                	ret

0000000000000196 <stat>:

int
stat(const char *n, struct stat *st)
{
 196:	1101                	addi	sp,sp,-32
 198:	ec06                	sd	ra,24(sp)
 19a:	e822                	sd	s0,16(sp)
 19c:	e426                	sd	s1,8(sp)
 19e:	e04a                	sd	s2,0(sp)
 1a0:	1000                	addi	s0,sp,32
 1a2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1a4:	4581                	li	a1,0
 1a6:	00000097          	auipc	ra,0x0
 1aa:	176080e7          	jalr	374(ra) # 31c <open>
  if(fd < 0)
 1ae:	02054563          	bltz	a0,1d8 <stat+0x42>
 1b2:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1b4:	85ca                	mv	a1,s2
 1b6:	00000097          	auipc	ra,0x0
 1ba:	17e080e7          	jalr	382(ra) # 334 <fstat>
 1be:	892a                	mv	s2,a0
  close(fd);
 1c0:	8526                	mv	a0,s1
 1c2:	00000097          	auipc	ra,0x0
 1c6:	142080e7          	jalr	322(ra) # 304 <close>
  return r;
}
 1ca:	854a                	mv	a0,s2
 1cc:	60e2                	ld	ra,24(sp)
 1ce:	6442                	ld	s0,16(sp)
 1d0:	64a2                	ld	s1,8(sp)
 1d2:	6902                	ld	s2,0(sp)
 1d4:	6105                	addi	sp,sp,32
 1d6:	8082                	ret
    return -1;
 1d8:	597d                	li	s2,-1
 1da:	bfc5                	j	1ca <stat+0x34>

00000000000001dc <atoi>:

int
atoi(const char *s)
{
 1dc:	1141                	addi	sp,sp,-16
 1de:	e422                	sd	s0,8(sp)
 1e0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1e2:	00054603          	lbu	a2,0(a0)
 1e6:	fd06079b          	addiw	a5,a2,-48
 1ea:	0ff7f793          	andi	a5,a5,255
 1ee:	4725                	li	a4,9
 1f0:	02f76963          	bltu	a4,a5,222 <atoi+0x46>
 1f4:	86aa                	mv	a3,a0
  n = 0;
 1f6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1f8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1fa:	0685                	addi	a3,a3,1
 1fc:	0025179b          	slliw	a5,a0,0x2
 200:	9fa9                	addw	a5,a5,a0
 202:	0017979b          	slliw	a5,a5,0x1
 206:	9fb1                	addw	a5,a5,a2
 208:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 20c:	0006c603          	lbu	a2,0(a3)
 210:	fd06071b          	addiw	a4,a2,-48
 214:	0ff77713          	andi	a4,a4,255
 218:	fee5f1e3          	bgeu	a1,a4,1fa <atoi+0x1e>
  return n;
}
 21c:	6422                	ld	s0,8(sp)
 21e:	0141                	addi	sp,sp,16
 220:	8082                	ret
  n = 0;
 222:	4501                	li	a0,0
 224:	bfe5                	j	21c <atoi+0x40>

0000000000000226 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 226:	1141                	addi	sp,sp,-16
 228:	e422                	sd	s0,8(sp)
 22a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 22c:	02b57663          	bgeu	a0,a1,258 <memmove+0x32>
    while(n-- > 0)
 230:	02c05163          	blez	a2,252 <memmove+0x2c>
 234:	fff6079b          	addiw	a5,a2,-1
 238:	1782                	slli	a5,a5,0x20
 23a:	9381                	srli	a5,a5,0x20
 23c:	0785                	addi	a5,a5,1
 23e:	97aa                	add	a5,a5,a0
  dst = vdst;
 240:	872a                	mv	a4,a0
      *dst++ = *src++;
 242:	0585                	addi	a1,a1,1
 244:	0705                	addi	a4,a4,1
 246:	fff5c683          	lbu	a3,-1(a1)
 24a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 24e:	fee79ae3          	bne	a5,a4,242 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 252:	6422                	ld	s0,8(sp)
 254:	0141                	addi	sp,sp,16
 256:	8082                	ret
    dst += n;
 258:	00c50733          	add	a4,a0,a2
    src += n;
 25c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 25e:	fec05ae3          	blez	a2,252 <memmove+0x2c>
 262:	fff6079b          	addiw	a5,a2,-1
 266:	1782                	slli	a5,a5,0x20
 268:	9381                	srli	a5,a5,0x20
 26a:	fff7c793          	not	a5,a5
 26e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 270:	15fd                	addi	a1,a1,-1
 272:	177d                	addi	a4,a4,-1
 274:	0005c683          	lbu	a3,0(a1)
 278:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 27c:	fee79ae3          	bne	a5,a4,270 <memmove+0x4a>
 280:	bfc9                	j	252 <memmove+0x2c>

0000000000000282 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 282:	1141                	addi	sp,sp,-16
 284:	e422                	sd	s0,8(sp)
 286:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 288:	ca05                	beqz	a2,2b8 <memcmp+0x36>
 28a:	fff6069b          	addiw	a3,a2,-1
 28e:	1682                	slli	a3,a3,0x20
 290:	9281                	srli	a3,a3,0x20
 292:	0685                	addi	a3,a3,1
 294:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 296:	00054783          	lbu	a5,0(a0)
 29a:	0005c703          	lbu	a4,0(a1)
 29e:	00e79863          	bne	a5,a4,2ae <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2a2:	0505                	addi	a0,a0,1
    p2++;
 2a4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2a6:	fed518e3          	bne	a0,a3,296 <memcmp+0x14>
  }
  return 0;
 2aa:	4501                	li	a0,0
 2ac:	a019                	j	2b2 <memcmp+0x30>
      return *p1 - *p2;
 2ae:	40e7853b          	subw	a0,a5,a4
}
 2b2:	6422                	ld	s0,8(sp)
 2b4:	0141                	addi	sp,sp,16
 2b6:	8082                	ret
  return 0;
 2b8:	4501                	li	a0,0
 2ba:	bfe5                	j	2b2 <memcmp+0x30>

00000000000002bc <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2bc:	1141                	addi	sp,sp,-16
 2be:	e406                	sd	ra,8(sp)
 2c0:	e022                	sd	s0,0(sp)
 2c2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2c4:	00000097          	auipc	ra,0x0
 2c8:	f62080e7          	jalr	-158(ra) # 226 <memmove>
}
 2cc:	60a2                	ld	ra,8(sp)
 2ce:	6402                	ld	s0,0(sp)
 2d0:	0141                	addi	sp,sp,16
 2d2:	8082                	ret

00000000000002d4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2d4:	4885                	li	a7,1
 ecall
 2d6:	00000073          	ecall
 ret
 2da:	8082                	ret

00000000000002dc <exit>:
.global exit
exit:
 li a7, SYS_exit
 2dc:	4889                	li	a7,2
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2e4:	488d                	li	a7,3
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2ec:	4891                	li	a7,4
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <read>:
.global read
read:
 li a7, SYS_read
 2f4:	4895                	li	a7,5
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <write>:
.global write
write:
 li a7, SYS_write
 2fc:	48c1                	li	a7,16
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <close>:
.global close
close:
 li a7, SYS_close
 304:	48d5                	li	a7,21
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <kill>:
.global kill
kill:
 li a7, SYS_kill
 30c:	4899                	li	a7,6
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <exec>:
.global exec
exec:
 li a7, SYS_exec
 314:	489d                	li	a7,7
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <open>:
.global open
open:
 li a7, SYS_open
 31c:	48bd                	li	a7,15
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 324:	48c5                	li	a7,17
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 32c:	48c9                	li	a7,18
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 334:	48a1                	li	a7,8
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <link>:
.global link
link:
 li a7, SYS_link
 33c:	48cd                	li	a7,19
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 344:	48d1                	li	a7,20
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 34c:	48a5                	li	a7,9
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <dup>:
.global dup
dup:
 li a7, SYS_dup
 354:	48a9                	li	a7,10
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 35c:	48ad                	li	a7,11
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 364:	48b1                	li	a7,12
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 36c:	48b5                	li	a7,13
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 374:	48b9                	li	a7,14
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <clone>:
.global clone
clone:
 li a7, SYS_clone
 37c:	48d9                	li	a7,22
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 384:	1101                	addi	sp,sp,-32
 386:	ec06                	sd	ra,24(sp)
 388:	e822                	sd	s0,16(sp)
 38a:	1000                	addi	s0,sp,32
 38c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 390:	4605                	li	a2,1
 392:	fef40593          	addi	a1,s0,-17
 396:	00000097          	auipc	ra,0x0
 39a:	f66080e7          	jalr	-154(ra) # 2fc <write>
}
 39e:	60e2                	ld	ra,24(sp)
 3a0:	6442                	ld	s0,16(sp)
 3a2:	6105                	addi	sp,sp,32
 3a4:	8082                	ret

00000000000003a6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3a6:	7139                	addi	sp,sp,-64
 3a8:	fc06                	sd	ra,56(sp)
 3aa:	f822                	sd	s0,48(sp)
 3ac:	f426                	sd	s1,40(sp)
 3ae:	f04a                	sd	s2,32(sp)
 3b0:	ec4e                	sd	s3,24(sp)
 3b2:	0080                	addi	s0,sp,64
 3b4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3b6:	c299                	beqz	a3,3bc <printint+0x16>
 3b8:	0805c863          	bltz	a1,448 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3bc:	2581                	sext.w	a1,a1
  neg = 0;
 3be:	4881                	li	a7,0
 3c0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3c4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3c6:	2601                	sext.w	a2,a2
 3c8:	00000517          	auipc	a0,0x0
 3cc:	46050513          	addi	a0,a0,1120 # 828 <digits>
 3d0:	883a                	mv	a6,a4
 3d2:	2705                	addiw	a4,a4,1
 3d4:	02c5f7bb          	remuw	a5,a1,a2
 3d8:	1782                	slli	a5,a5,0x20
 3da:	9381                	srli	a5,a5,0x20
 3dc:	97aa                	add	a5,a5,a0
 3de:	0007c783          	lbu	a5,0(a5)
 3e2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3e6:	0005879b          	sext.w	a5,a1
 3ea:	02c5d5bb          	divuw	a1,a1,a2
 3ee:	0685                	addi	a3,a3,1
 3f0:	fec7f0e3          	bgeu	a5,a2,3d0 <printint+0x2a>
  if(neg)
 3f4:	00088b63          	beqz	a7,40a <printint+0x64>
    buf[i++] = '-';
 3f8:	fd040793          	addi	a5,s0,-48
 3fc:	973e                	add	a4,a4,a5
 3fe:	02d00793          	li	a5,45
 402:	fef70823          	sb	a5,-16(a4)
 406:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 40a:	02e05863          	blez	a4,43a <printint+0x94>
 40e:	fc040793          	addi	a5,s0,-64
 412:	00e78933          	add	s2,a5,a4
 416:	fff78993          	addi	s3,a5,-1
 41a:	99ba                	add	s3,s3,a4
 41c:	377d                	addiw	a4,a4,-1
 41e:	1702                	slli	a4,a4,0x20
 420:	9301                	srli	a4,a4,0x20
 422:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 426:	fff94583          	lbu	a1,-1(s2)
 42a:	8526                	mv	a0,s1
 42c:	00000097          	auipc	ra,0x0
 430:	f58080e7          	jalr	-168(ra) # 384 <putc>
  while(--i >= 0)
 434:	197d                	addi	s2,s2,-1
 436:	ff3918e3          	bne	s2,s3,426 <printint+0x80>
}
 43a:	70e2                	ld	ra,56(sp)
 43c:	7442                	ld	s0,48(sp)
 43e:	74a2                	ld	s1,40(sp)
 440:	7902                	ld	s2,32(sp)
 442:	69e2                	ld	s3,24(sp)
 444:	6121                	addi	sp,sp,64
 446:	8082                	ret
    x = -xx;
 448:	40b005bb          	negw	a1,a1
    neg = 1;
 44c:	4885                	li	a7,1
    x = -xx;
 44e:	bf8d                	j	3c0 <printint+0x1a>

0000000000000450 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 450:	7119                	addi	sp,sp,-128
 452:	fc86                	sd	ra,120(sp)
 454:	f8a2                	sd	s0,112(sp)
 456:	f4a6                	sd	s1,104(sp)
 458:	f0ca                	sd	s2,96(sp)
 45a:	ecce                	sd	s3,88(sp)
 45c:	e8d2                	sd	s4,80(sp)
 45e:	e4d6                	sd	s5,72(sp)
 460:	e0da                	sd	s6,64(sp)
 462:	fc5e                	sd	s7,56(sp)
 464:	f862                	sd	s8,48(sp)
 466:	f466                	sd	s9,40(sp)
 468:	f06a                	sd	s10,32(sp)
 46a:	ec6e                	sd	s11,24(sp)
 46c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 46e:	0005c903          	lbu	s2,0(a1)
 472:	18090f63          	beqz	s2,610 <vprintf+0x1c0>
 476:	8aaa                	mv	s5,a0
 478:	8b32                	mv	s6,a2
 47a:	00158493          	addi	s1,a1,1
  state = 0;
 47e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 480:	02500a13          	li	s4,37
      if(c == 'd'){
 484:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 488:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 48c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 490:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 494:	00000b97          	auipc	s7,0x0
 498:	394b8b93          	addi	s7,s7,916 # 828 <digits>
 49c:	a839                	j	4ba <vprintf+0x6a>
        putc(fd, c);
 49e:	85ca                	mv	a1,s2
 4a0:	8556                	mv	a0,s5
 4a2:	00000097          	auipc	ra,0x0
 4a6:	ee2080e7          	jalr	-286(ra) # 384 <putc>
 4aa:	a019                	j	4b0 <vprintf+0x60>
    } else if(state == '%'){
 4ac:	01498f63          	beq	s3,s4,4ca <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4b0:	0485                	addi	s1,s1,1
 4b2:	fff4c903          	lbu	s2,-1(s1)
 4b6:	14090d63          	beqz	s2,610 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4ba:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4be:	fe0997e3          	bnez	s3,4ac <vprintf+0x5c>
      if(c == '%'){
 4c2:	fd479ee3          	bne	a5,s4,49e <vprintf+0x4e>
        state = '%';
 4c6:	89be                	mv	s3,a5
 4c8:	b7e5                	j	4b0 <vprintf+0x60>
      if(c == 'd'){
 4ca:	05878063          	beq	a5,s8,50a <vprintf+0xba>
      } else if(c == 'l') {
 4ce:	05978c63          	beq	a5,s9,526 <vprintf+0xd6>
      } else if(c == 'x') {
 4d2:	07a78863          	beq	a5,s10,542 <vprintf+0xf2>
      } else if(c == 'p') {
 4d6:	09b78463          	beq	a5,s11,55e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4da:	07300713          	li	a4,115
 4de:	0ce78663          	beq	a5,a4,5aa <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4e2:	06300713          	li	a4,99
 4e6:	0ee78e63          	beq	a5,a4,5e2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4ea:	11478863          	beq	a5,s4,5fa <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4ee:	85d2                	mv	a1,s4
 4f0:	8556                	mv	a0,s5
 4f2:	00000097          	auipc	ra,0x0
 4f6:	e92080e7          	jalr	-366(ra) # 384 <putc>
        putc(fd, c);
 4fa:	85ca                	mv	a1,s2
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e86080e7          	jalr	-378(ra) # 384 <putc>
      }
      state = 0;
 506:	4981                	li	s3,0
 508:	b765                	j	4b0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 50a:	008b0913          	addi	s2,s6,8
 50e:	4685                	li	a3,1
 510:	4629                	li	a2,10
 512:	000b2583          	lw	a1,0(s6)
 516:	8556                	mv	a0,s5
 518:	00000097          	auipc	ra,0x0
 51c:	e8e080e7          	jalr	-370(ra) # 3a6 <printint>
 520:	8b4a                	mv	s6,s2
      state = 0;
 522:	4981                	li	s3,0
 524:	b771                	j	4b0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 526:	008b0913          	addi	s2,s6,8
 52a:	4681                	li	a3,0
 52c:	4629                	li	a2,10
 52e:	000b2583          	lw	a1,0(s6)
 532:	8556                	mv	a0,s5
 534:	00000097          	auipc	ra,0x0
 538:	e72080e7          	jalr	-398(ra) # 3a6 <printint>
 53c:	8b4a                	mv	s6,s2
      state = 0;
 53e:	4981                	li	s3,0
 540:	bf85                	j	4b0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 542:	008b0913          	addi	s2,s6,8
 546:	4681                	li	a3,0
 548:	4641                	li	a2,16
 54a:	000b2583          	lw	a1,0(s6)
 54e:	8556                	mv	a0,s5
 550:	00000097          	auipc	ra,0x0
 554:	e56080e7          	jalr	-426(ra) # 3a6 <printint>
 558:	8b4a                	mv	s6,s2
      state = 0;
 55a:	4981                	li	s3,0
 55c:	bf91                	j	4b0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 55e:	008b0793          	addi	a5,s6,8
 562:	f8f43423          	sd	a5,-120(s0)
 566:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 56a:	03000593          	li	a1,48
 56e:	8556                	mv	a0,s5
 570:	00000097          	auipc	ra,0x0
 574:	e14080e7          	jalr	-492(ra) # 384 <putc>
  putc(fd, 'x');
 578:	85ea                	mv	a1,s10
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e08080e7          	jalr	-504(ra) # 384 <putc>
 584:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 586:	03c9d793          	srli	a5,s3,0x3c
 58a:	97de                	add	a5,a5,s7
 58c:	0007c583          	lbu	a1,0(a5)
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	df2080e7          	jalr	-526(ra) # 384 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 59a:	0992                	slli	s3,s3,0x4
 59c:	397d                	addiw	s2,s2,-1
 59e:	fe0914e3          	bnez	s2,586 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5a2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5a6:	4981                	li	s3,0
 5a8:	b721                	j	4b0 <vprintf+0x60>
        s = va_arg(ap, char*);
 5aa:	008b0993          	addi	s3,s6,8
 5ae:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5b2:	02090163          	beqz	s2,5d4 <vprintf+0x184>
        while(*s != 0){
 5b6:	00094583          	lbu	a1,0(s2)
 5ba:	c9a1                	beqz	a1,60a <vprintf+0x1ba>
          putc(fd, *s);
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	dc6080e7          	jalr	-570(ra) # 384 <putc>
          s++;
 5c6:	0905                	addi	s2,s2,1
        while(*s != 0){
 5c8:	00094583          	lbu	a1,0(s2)
 5cc:	f9e5                	bnez	a1,5bc <vprintf+0x16c>
        s = va_arg(ap, char*);
 5ce:	8b4e                	mv	s6,s3
      state = 0;
 5d0:	4981                	li	s3,0
 5d2:	bdf9                	j	4b0 <vprintf+0x60>
          s = "(null)";
 5d4:	00000917          	auipc	s2,0x0
 5d8:	24c90913          	addi	s2,s2,588 # 820 <malloc+0x106>
        while(*s != 0){
 5dc:	02800593          	li	a1,40
 5e0:	bff1                	j	5bc <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5e2:	008b0913          	addi	s2,s6,8
 5e6:	000b4583          	lbu	a1,0(s6)
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	d98080e7          	jalr	-616(ra) # 384 <putc>
 5f4:	8b4a                	mv	s6,s2
      state = 0;
 5f6:	4981                	li	s3,0
 5f8:	bd65                	j	4b0 <vprintf+0x60>
        putc(fd, c);
 5fa:	85d2                	mv	a1,s4
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	d86080e7          	jalr	-634(ra) # 384 <putc>
      state = 0;
 606:	4981                	li	s3,0
 608:	b565                	j	4b0 <vprintf+0x60>
        s = va_arg(ap, char*);
 60a:	8b4e                	mv	s6,s3
      state = 0;
 60c:	4981                	li	s3,0
 60e:	b54d                	j	4b0 <vprintf+0x60>
    }
  }
}
 610:	70e6                	ld	ra,120(sp)
 612:	7446                	ld	s0,112(sp)
 614:	74a6                	ld	s1,104(sp)
 616:	7906                	ld	s2,96(sp)
 618:	69e6                	ld	s3,88(sp)
 61a:	6a46                	ld	s4,80(sp)
 61c:	6aa6                	ld	s5,72(sp)
 61e:	6b06                	ld	s6,64(sp)
 620:	7be2                	ld	s7,56(sp)
 622:	7c42                	ld	s8,48(sp)
 624:	7ca2                	ld	s9,40(sp)
 626:	7d02                	ld	s10,32(sp)
 628:	6de2                	ld	s11,24(sp)
 62a:	6109                	addi	sp,sp,128
 62c:	8082                	ret

000000000000062e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 62e:	715d                	addi	sp,sp,-80
 630:	ec06                	sd	ra,24(sp)
 632:	e822                	sd	s0,16(sp)
 634:	1000                	addi	s0,sp,32
 636:	e010                	sd	a2,0(s0)
 638:	e414                	sd	a3,8(s0)
 63a:	e818                	sd	a4,16(s0)
 63c:	ec1c                	sd	a5,24(s0)
 63e:	03043023          	sd	a6,32(s0)
 642:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 646:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 64a:	8622                	mv	a2,s0
 64c:	00000097          	auipc	ra,0x0
 650:	e04080e7          	jalr	-508(ra) # 450 <vprintf>
}
 654:	60e2                	ld	ra,24(sp)
 656:	6442                	ld	s0,16(sp)
 658:	6161                	addi	sp,sp,80
 65a:	8082                	ret

000000000000065c <printf>:

void
printf(const char *fmt, ...)
{
 65c:	711d                	addi	sp,sp,-96
 65e:	ec06                	sd	ra,24(sp)
 660:	e822                	sd	s0,16(sp)
 662:	1000                	addi	s0,sp,32
 664:	e40c                	sd	a1,8(s0)
 666:	e810                	sd	a2,16(s0)
 668:	ec14                	sd	a3,24(s0)
 66a:	f018                	sd	a4,32(s0)
 66c:	f41c                	sd	a5,40(s0)
 66e:	03043823          	sd	a6,48(s0)
 672:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 676:	00840613          	addi	a2,s0,8
 67a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 67e:	85aa                	mv	a1,a0
 680:	4505                	li	a0,1
 682:	00000097          	auipc	ra,0x0
 686:	dce080e7          	jalr	-562(ra) # 450 <vprintf>
}
 68a:	60e2                	ld	ra,24(sp)
 68c:	6442                	ld	s0,16(sp)
 68e:	6125                	addi	sp,sp,96
 690:	8082                	ret

0000000000000692 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 692:	1141                	addi	sp,sp,-16
 694:	e422                	sd	s0,8(sp)
 696:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 698:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 69c:	00000797          	auipc	a5,0x0
 6a0:	1a47b783          	ld	a5,420(a5) # 840 <freep>
 6a4:	a805                	j	6d4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6a6:	4618                	lw	a4,8(a2)
 6a8:	9db9                	addw	a1,a1,a4
 6aa:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ae:	6398                	ld	a4,0(a5)
 6b0:	6318                	ld	a4,0(a4)
 6b2:	fee53823          	sd	a4,-16(a0)
 6b6:	a091                	j	6fa <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6b8:	ff852703          	lw	a4,-8(a0)
 6bc:	9e39                	addw	a2,a2,a4
 6be:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6c0:	ff053703          	ld	a4,-16(a0)
 6c4:	e398                	sd	a4,0(a5)
 6c6:	a099                	j	70c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c8:	6398                	ld	a4,0(a5)
 6ca:	00e7e463          	bltu	a5,a4,6d2 <free+0x40>
 6ce:	00e6ea63          	bltu	a3,a4,6e2 <free+0x50>
{
 6d2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6d4:	fed7fae3          	bgeu	a5,a3,6c8 <free+0x36>
 6d8:	6398                	ld	a4,0(a5)
 6da:	00e6e463          	bltu	a3,a4,6e2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6de:	fee7eae3          	bltu	a5,a4,6d2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6e2:	ff852583          	lw	a1,-8(a0)
 6e6:	6390                	ld	a2,0(a5)
 6e8:	02059713          	slli	a4,a1,0x20
 6ec:	9301                	srli	a4,a4,0x20
 6ee:	0712                	slli	a4,a4,0x4
 6f0:	9736                	add	a4,a4,a3
 6f2:	fae60ae3          	beq	a2,a4,6a6 <free+0x14>
    bp->s.ptr = p->s.ptr;
 6f6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6fa:	4790                	lw	a2,8(a5)
 6fc:	02061713          	slli	a4,a2,0x20
 700:	9301                	srli	a4,a4,0x20
 702:	0712                	slli	a4,a4,0x4
 704:	973e                	add	a4,a4,a5
 706:	fae689e3          	beq	a3,a4,6b8 <free+0x26>
  } else
    p->s.ptr = bp;
 70a:	e394                	sd	a3,0(a5)
  freep = p;
 70c:	00000717          	auipc	a4,0x0
 710:	12f73a23          	sd	a5,308(a4) # 840 <freep>
}
 714:	6422                	ld	s0,8(sp)
 716:	0141                	addi	sp,sp,16
 718:	8082                	ret

000000000000071a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 71a:	7139                	addi	sp,sp,-64
 71c:	fc06                	sd	ra,56(sp)
 71e:	f822                	sd	s0,48(sp)
 720:	f426                	sd	s1,40(sp)
 722:	f04a                	sd	s2,32(sp)
 724:	ec4e                	sd	s3,24(sp)
 726:	e852                	sd	s4,16(sp)
 728:	e456                	sd	s5,8(sp)
 72a:	e05a                	sd	s6,0(sp)
 72c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 72e:	02051493          	slli	s1,a0,0x20
 732:	9081                	srli	s1,s1,0x20
 734:	04bd                	addi	s1,s1,15
 736:	8091                	srli	s1,s1,0x4
 738:	0014899b          	addiw	s3,s1,1
 73c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 73e:	00000517          	auipc	a0,0x0
 742:	10253503          	ld	a0,258(a0) # 840 <freep>
 746:	c515                	beqz	a0,772 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 748:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 74a:	4798                	lw	a4,8(a5)
 74c:	02977f63          	bgeu	a4,s1,78a <malloc+0x70>
 750:	8a4e                	mv	s4,s3
 752:	0009871b          	sext.w	a4,s3
 756:	6685                	lui	a3,0x1
 758:	00d77363          	bgeu	a4,a3,75e <malloc+0x44>
 75c:	6a05                	lui	s4,0x1
 75e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 762:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 766:	00000917          	auipc	s2,0x0
 76a:	0da90913          	addi	s2,s2,218 # 840 <freep>
  if(p == (char*)-1)
 76e:	5afd                	li	s5,-1
 770:	a88d                	j	7e2 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 772:	00000797          	auipc	a5,0x0
 776:	0d678793          	addi	a5,a5,214 # 848 <base>
 77a:	00000717          	auipc	a4,0x0
 77e:	0cf73323          	sd	a5,198(a4) # 840 <freep>
 782:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 784:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 788:	b7e1                	j	750 <malloc+0x36>
      if(p->s.size == nunits)
 78a:	02e48b63          	beq	s1,a4,7c0 <malloc+0xa6>
        p->s.size -= nunits;
 78e:	4137073b          	subw	a4,a4,s3
 792:	c798                	sw	a4,8(a5)
        p += p->s.size;
 794:	1702                	slli	a4,a4,0x20
 796:	9301                	srli	a4,a4,0x20
 798:	0712                	slli	a4,a4,0x4
 79a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 79c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a0:	00000717          	auipc	a4,0x0
 7a4:	0aa73023          	sd	a0,160(a4) # 840 <freep>
      return (void*)(p + 1);
 7a8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ac:	70e2                	ld	ra,56(sp)
 7ae:	7442                	ld	s0,48(sp)
 7b0:	74a2                	ld	s1,40(sp)
 7b2:	7902                	ld	s2,32(sp)
 7b4:	69e2                	ld	s3,24(sp)
 7b6:	6a42                	ld	s4,16(sp)
 7b8:	6aa2                	ld	s5,8(sp)
 7ba:	6b02                	ld	s6,0(sp)
 7bc:	6121                	addi	sp,sp,64
 7be:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c0:	6398                	ld	a4,0(a5)
 7c2:	e118                	sd	a4,0(a0)
 7c4:	bff1                	j	7a0 <malloc+0x86>
  hp->s.size = nu;
 7c6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ca:	0541                	addi	a0,a0,16
 7cc:	00000097          	auipc	ra,0x0
 7d0:	ec6080e7          	jalr	-314(ra) # 692 <free>
  return freep;
 7d4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7d8:	d971                	beqz	a0,7ac <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7da:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7dc:	4798                	lw	a4,8(a5)
 7de:	fa9776e3          	bgeu	a4,s1,78a <malloc+0x70>
    if(p == freep)
 7e2:	00093703          	ld	a4,0(s2)
 7e6:	853e                	mv	a0,a5
 7e8:	fef719e3          	bne	a4,a5,7da <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7ec:	8552                	mv	a0,s4
 7ee:	00000097          	auipc	ra,0x0
 7f2:	b76080e7          	jalr	-1162(ra) # 364 <sbrk>
  if(p == (char*)-1)
 7f6:	fd5518e3          	bne	a0,s5,7c6 <malloc+0xac>
        return 0;
 7fa:	4501                	li	a0,0
 7fc:	bf45                	j	7ac <malloc+0x92>
