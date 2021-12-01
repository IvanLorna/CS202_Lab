
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9c013103          	ld	sp,-1600(sp) # 800089c0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	fbc78793          	addi	a5,a5,-68 # 80006020 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	41c080e7          	jalr	1052(ra) # 80002548 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	81a080e7          	jalr	-2022(ra) # 800019de <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f7a080e7          	jalr	-134(ra) # 8000214e <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2e2080e7          	jalr	738(ra) # 800024f2 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2ac080e7          	jalr	684(ra) # 8000259e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e94080e7          	jalr	-364(ra) # 800022da <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	0a078793          	addi	a5,a5,160 # 80021518 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	e3450513          	addi	a0,a0,-460 # 800083a0 <states.1725+0x70>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a3a080e7          	jalr	-1478(ra) # 800022da <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	822080e7          	jalr	-2014(ra) # 8000214e <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e44080e7          	jalr	-444(ra) # 800019c2 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	e12080e7          	jalr	-494(ra) # 800019c2 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	e06080e7          	jalr	-506(ra) # 800019c2 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dee080e7          	jalr	-530(ra) # 800019c2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	dae080e7          	jalr	-594(ra) # 800019c2 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d82080e7          	jalr	-638(ra) # 800019c2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	b1c080e7          	jalr	-1252(ra) # 800019b2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	b00080e7          	jalr	-1280(ra) # 800019b2 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	9ca080e7          	jalr	-1590(ra) # 8000289e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	184080e7          	jalr	388(ra) # 80006060 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	052080e7          	jalr	82(ra) # 80001f36 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	4a450513          	addi	a0,a0,1188 # 800083a0 <states.1725+0x70>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	48450513          	addi	a0,a0,1156 # 800083a0 <states.1725+0x70>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	92a080e7          	jalr	-1750(ra) # 80002876 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	94a080e7          	jalr	-1718(ra) # 8000289e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	0ee080e7          	jalr	238(ra) # 8000604a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	0fc080e7          	jalr	252(ra) # 80006060 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	2da080e7          	jalr	730(ra) # 80003246 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	96a080e7          	jalr	-1686(ra) # 800038de <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	914080e7          	jalr	-1772(ra) # 80004890 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	1fe080e7          	jalr	510(ra) # 80006182 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d78080e7          	jalr	-648(ra) # 80001d04 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e7c48493          	addi	s1,s1,-388 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	a62a0a13          	addi	s4,s4,-1438 # 800172d0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	8591                	srai	a1,a1,0x4
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	17048493          	addi	s1,s1,368
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:
int i = 0;
// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	715d                	addi	sp,sp,-80
    800018d6:	e486                	sd	ra,72(sp)
    800018d8:	e0a2                	sd	s0,64(sp)
    800018da:	fc26                	sd	s1,56(sp)
    800018dc:	f84a                	sd	s2,48(sp)
    800018de:	f44e                	sd	s3,40(sp)
    800018e0:	f052                	sd	s4,32(sp)
    800018e2:	ec56                	sd	s5,24(sp)
    800018e4:	e85a                	sd	s6,16(sp)
    800018e6:	e45e                	sd	s7,8(sp)
    800018e8:	e062                	sd	s8,0(sp)
    800018ea:	0880                	addi	s0,sp,80
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018ec:	00007597          	auipc	a1,0x7
    800018f0:	8f458593          	addi	a1,a1,-1804 # 800081e0 <digits+0x1a0>
    800018f4:	00010517          	auipc	a0,0x10
    800018f8:	9ac50513          	addi	a0,a0,-1620 # 800112a0 <pid_lock>
    800018fc:	fffff097          	auipc	ra,0xfffff
    80001900:	258080e7          	jalr	600(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001904:	00007597          	auipc	a1,0x7
    80001908:	8e458593          	addi	a1,a1,-1820 # 800081e8 <digits+0x1a8>
    8000190c:	00010517          	auipc	a0,0x10
    80001910:	9ac50513          	addi	a0,a0,-1620 # 800112b8 <wait_lock>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	240080e7          	jalr	576(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191c:	00010497          	auipc	s1,0x10
    80001920:	db448493          	addi	s1,s1,-588 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001924:	00007c17          	auipc	s8,0x7
    80001928:	8d4c0c13          	addi	s8,s8,-1836 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000192c:	8ba6                	mv	s7,s1
    8000192e:	00006b17          	auipc	s6,0x6
    80001932:	6d2b0b13          	addi	s6,s6,1746 # 80008000 <etext>
    80001936:	040009b7          	lui	s3,0x4000
    8000193a:	19fd                	addi	s3,s3,-1
    8000193c:	09b2                	slli	s3,s3,0xc
      printf("procinit i = %d kstack = 0x%x\n", i++, p->kstack);
    8000193e:	00007917          	auipc	s2,0x7
    80001942:	6ea90913          	addi	s2,s2,1770 # 80009028 <i>
    80001946:	00007a97          	auipc	s5,0x7
    8000194a:	8baa8a93          	addi	s5,s5,-1862 # 80008200 <digits+0x1c0>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00016a17          	auipc	s4,0x16
    80001952:	982a0a13          	addi	s4,s4,-1662 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001956:	85e2                	mv	a1,s8
    80001958:	8526                	mv	a0,s1
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	1fa080e7          	jalr	506(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001962:	41748633          	sub	a2,s1,s7
    80001966:	8611                	srai	a2,a2,0x4
    80001968:	000b3783          	ld	a5,0(s6)
    8000196c:	02f60633          	mul	a2,a2,a5
    80001970:	2605                	addiw	a2,a2,1
    80001972:	00d6161b          	slliw	a2,a2,0xd
    80001976:	40c98633          	sub	a2,s3,a2
    8000197a:	e4b0                	sd	a2,72(s1)
      printf("procinit i = %d kstack = 0x%x\n", i++, p->kstack);
    8000197c:	00092583          	lw	a1,0(s2)
    80001980:	0015879b          	addiw	a5,a1,1
    80001984:	00f92023          	sw	a5,0(s2)
    80001988:	8556                	mv	a0,s5
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	bfe080e7          	jalr	-1026(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001992:	17048493          	addi	s1,s1,368
    80001996:	fd4490e3          	bne	s1,s4,80001956 <procinit+0x82>
  }
}
    8000199a:	60a6                	ld	ra,72(sp)
    8000199c:	6406                	ld	s0,64(sp)
    8000199e:	74e2                	ld	s1,56(sp)
    800019a0:	7942                	ld	s2,48(sp)
    800019a2:	79a2                	ld	s3,40(sp)
    800019a4:	7a02                	ld	s4,32(sp)
    800019a6:	6ae2                	ld	s5,24(sp)
    800019a8:	6b42                	ld	s6,16(sp)
    800019aa:	6ba2                	ld	s7,8(sp)
    800019ac:	6c02                	ld	s8,0(sp)
    800019ae:	6161                	addi	sp,sp,80
    800019b0:	8082                	ret

00000000800019b2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019b2:	1141                	addi	sp,sp,-16
    800019b4:	e422                	sd	s0,8(sp)
    800019b6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019b8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ba:	2501                	sext.w	a0,a0
    800019bc:	6422                	ld	s0,8(sp)
    800019be:	0141                	addi	sp,sp,16
    800019c0:	8082                	ret

00000000800019c2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019c2:	1141                	addi	sp,sp,-16
    800019c4:	e422                	sd	s0,8(sp)
    800019c6:	0800                	addi	s0,sp,16
    800019c8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ca:	2781                	sext.w	a5,a5
    800019cc:	079e                	slli	a5,a5,0x7
  return c;
}
    800019ce:	00010517          	auipc	a0,0x10
    800019d2:	90250513          	addi	a0,a0,-1790 # 800112d0 <cpus>
    800019d6:	953e                	add	a0,a0,a5
    800019d8:	6422                	ld	s0,8(sp)
    800019da:	0141                	addi	sp,sp,16
    800019dc:	8082                	ret

00000000800019de <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019de:	1101                	addi	sp,sp,-32
    800019e0:	ec06                	sd	ra,24(sp)
    800019e2:	e822                	sd	s0,16(sp)
    800019e4:	e426                	sd	s1,8(sp)
    800019e6:	1000                	addi	s0,sp,32
  push_off();
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	1b0080e7          	jalr	432(ra) # 80000b98 <push_off>
    800019f0:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019f2:	2781                	sext.w	a5,a5
    800019f4:	079e                	slli	a5,a5,0x7
    800019f6:	00010717          	auipc	a4,0x10
    800019fa:	8aa70713          	addi	a4,a4,-1878 # 800112a0 <pid_lock>
    800019fe:	97ba                	add	a5,a5,a4
    80001a00:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	236080e7          	jalr	566(ra) # 80000c38 <pop_off>
  return p;
}
    80001a0a:	8526                	mv	a0,s1
    80001a0c:	60e2                	ld	ra,24(sp)
    80001a0e:	6442                	ld	s0,16(sp)
    80001a10:	64a2                	ld	s1,8(sp)
    80001a12:	6105                	addi	sp,sp,32
    80001a14:	8082                	ret

0000000080001a16 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e406                	sd	ra,8(sp)
    80001a1a:	e022                	sd	s0,0(sp)
    80001a1c:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a1e:	00000097          	auipc	ra,0x0
    80001a22:	fc0080e7          	jalr	-64(ra) # 800019de <myproc>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	272080e7          	jalr	626(ra) # 80000c98 <release>

  if (first) {
    80001a2e:	00007797          	auipc	a5,0x7
    80001a32:	f467a783          	lw	a5,-186(a5) # 80008974 <first.1688>
    80001a36:	eb89                	bnez	a5,80001a48 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a38:	00001097          	auipc	ra,0x1
    80001a3c:	f70080e7          	jalr	-144(ra) # 800029a8 <usertrapret>
}
    80001a40:	60a2                	ld	ra,8(sp)
    80001a42:	6402                	ld	s0,0(sp)
    80001a44:	0141                	addi	sp,sp,16
    80001a46:	8082                	ret
    first = 0;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f207a623          	sw	zero,-212(a5) # 80008974 <first.1688>
    fsinit(ROOTDEV);
    80001a50:	4505                	li	a0,1
    80001a52:	00002097          	auipc	ra,0x2
    80001a56:	e0c080e7          	jalr	-500(ra) # 8000385e <fsinit>
    80001a5a:	bff9                	j	80001a38 <forkret+0x22>

0000000080001a5c <forkret_thread>:
//---------------------------------------------------------------------------------------------
//lab3

void
forkret_thread(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	f7a080e7          	jalr	-134(ra) # 800019de <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	22c080e7          	jalr	556(ra) # 80000c98 <release>

  if (first) {
    80001a74:	00007797          	auipc	a5,0x7
    80001a78:	efc7a783          	lw	a5,-260(a5) # 80008970 <first.1735>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret_thread+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret_thread();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	fc8080e7          	jalr	-56(ra) # 80002a46 <usertrapret_thread>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	ee07a123          	sw	zero,-286(a5) # 80008970 <first.1735>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	dc6080e7          	jalr	-570(ra) # 8000385e <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret_thread+0x22>

0000000080001aa2 <allocpid>:
allocpid() {
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	0000f917          	auipc	s2,0xf
    80001ab2:	7f290913          	addi	s2,s2,2034 # 800112a0 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	12c080e7          	jalr	300(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	ebc78793          	addi	a5,a5,-324 # 8000897c <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1c6080e7          	jalr	454(ra) # 80000c98 <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	844080e7          	jalr	-1980(ra) # 8000133a <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	59a080e7          	jalr	1434(ra) # 800010b0 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	06093683          	ld	a3,96(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	57c080e7          	jalr	1404(ra) # 800010b0 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	9e4080e7          	jalr	-1564(ra) # 80001536 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	70a080e7          	jalr	1802(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	9be080e7          	jalr	-1602(ra) # 80001536 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	6d6080e7          	jalr	1750(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	6c0080e7          	jalr	1728(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	974080e7          	jalr	-1676(ra) # 80001536 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be2:	7128                	ld	a0,96(a0)
    80001be4:	c509                	beqz	a0,80001bee <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	e12080e7          	jalr	-494(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bee:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001bf2:	6ca8                	ld	a0,88(s1)
    80001bf4:	c511                	beqz	a0,80001c00 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bf6:	68ac                	ld	a1,80(s1)
    80001bf8:	00000097          	auipc	ra,0x0
    80001bfc:	f8c080e7          	jalr	-116(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c00:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001c04:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001c08:	0204a823          	sw	zero,48(s1)
  p->tid = 0; //LAB3
    80001c0c:	0204aa23          	sw	zero,52(s1)
  p->tcnt = 0;//LAB3
    80001c10:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c14:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001c18:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001c1c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c20:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c24:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c28:	0004ac23          	sw	zero,24(s1)
}
    80001c2c:	60e2                	ld	ra,24(sp)
    80001c2e:	6442                	ld	s0,16(sp)
    80001c30:	64a2                	ld	s1,8(sp)
    80001c32:	6105                	addi	sp,sp,32
    80001c34:	8082                	ret

0000000080001c36 <allocproc>:
{
    80001c36:	1101                	addi	sp,sp,-32
    80001c38:	ec06                	sd	ra,24(sp)
    80001c3a:	e822                	sd	s0,16(sp)
    80001c3c:	e426                	sd	s1,8(sp)
    80001c3e:	e04a                	sd	s2,0(sp)
    80001c40:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c42:	00010497          	auipc	s1,0x10
    80001c46:	a8e48493          	addi	s1,s1,-1394 # 800116d0 <proc>
    80001c4a:	00015917          	auipc	s2,0x15
    80001c4e:	68690913          	addi	s2,s2,1670 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c52:	8526                	mv	a0,s1
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	f90080e7          	jalr	-112(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c5c:	4c9c                	lw	a5,24(s1)
    80001c5e:	cf81                	beqz	a5,80001c76 <allocproc+0x40>
      release(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6a:	17048493          	addi	s1,s1,368
    80001c6e:	ff2492e3          	bne	s1,s2,80001c52 <allocproc+0x1c>
  return 0;
    80001c72:	4481                	li	s1,0
    80001c74:	a889                	j	80001cc6 <allocproc+0x90>
  p->pid = allocpid();
    80001c76:	00000097          	auipc	ra,0x0
    80001c7a:	e2c080e7          	jalr	-468(ra) # 80001aa2 <allocpid>
    80001c7e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c80:	4785                	li	a5,1
    80001c82:	cc9c                	sw	a5,24(s1)
  if(((p->trapframe = (struct trapframe *)kalloc()) == 0)){
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	e70080e7          	jalr	-400(ra) # 80000af4 <kalloc>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	f0a8                	sd	a0,96(s1)
    80001c90:	c131                	beqz	a0,80001cd4 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c92:	8526                	mv	a0,s1
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	e54080e7          	jalr	-428(ra) # 80001ae8 <proc_pagetable>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001ca0:	c531                	beqz	a0,80001cec <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001ca2:	07000613          	li	a2,112
    80001ca6:	4581                	li	a1,0
    80001ca8:	06848513          	addi	a0,s1,104
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	034080e7          	jalr	52(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001cb4:	00000797          	auipc	a5,0x0
    80001cb8:	d6278793          	addi	a5,a5,-670 # 80001a16 <forkret>
    80001cbc:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cbe:	64bc                	ld	a5,72(s1)
    80001cc0:	6705                	lui	a4,0x1
    80001cc2:	97ba                	add	a5,a5,a4
    80001cc4:	f8bc                	sd	a5,112(s1)
}
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	60e2                	ld	ra,24(sp)
    80001cca:	6442                	ld	s0,16(sp)
    80001ccc:	64a2                	ld	s1,8(sp)
    80001cce:	6902                	ld	s2,0(sp)
    80001cd0:	6105                	addi	sp,sp,32
    80001cd2:	8082                	ret
    freeproc(p);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	f00080e7          	jalr	-256(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	fb8080e7          	jalr	-72(ra) # 80000c98 <release>
    return 0;
    80001ce8:	84ca                	mv	s1,s2
    80001cea:	bff1                	j	80001cc6 <allocproc+0x90>
    freeproc(p);
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	ee8080e7          	jalr	-280(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
    return 0;
    80001d00:	84ca                	mv	s1,s2
    80001d02:	b7d1                	j	80001cc6 <allocproc+0x90>

0000000080001d04 <userinit>:
{
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	f28080e7          	jalr	-216(ra) # 80001c36 <allocproc>
    80001d16:	84aa                	mv	s1,a0
  initproc = p;
    80001d18:	00007797          	auipc	a5,0x7
    80001d1c:	30a7bc23          	sd	a0,792(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d20:	03400613          	li	a2,52
    80001d24:	00007597          	auipc	a1,0x7
    80001d28:	c5c58593          	addi	a1,a1,-932 # 80008980 <initcode>
    80001d2c:	6d28                	ld	a0,88(a0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	63a080e7          	jalr	1594(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d36:	6785                	lui	a5,0x1
    80001d38:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d3a:	70b8                	ld	a4,96(s1)
    80001d3c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d40:	70b8                	ld	a4,96(s1)
    80001d42:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d44:	4641                	li	a2,16
    80001d46:	00006597          	auipc	a1,0x6
    80001d4a:	4da58593          	addi	a1,a1,1242 # 80008220 <digits+0x1e0>
    80001d4e:	16048513          	addi	a0,s1,352
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	0e0080e7          	jalr	224(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d5a:	00006517          	auipc	a0,0x6
    80001d5e:	4d650513          	addi	a0,a0,1238 # 80008230 <digits+0x1f0>
    80001d62:	00002097          	auipc	ra,0x2
    80001d66:	52a080e7          	jalr	1322(ra) # 8000428c <namei>
    80001d6a:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d6e:	478d                	li	a5,3
    80001d70:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	f24080e7          	jalr	-220(ra) # 80000c98 <release>
}
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret

0000000080001d86 <growproc>:
{
    80001d86:	1101                	addi	sp,sp,-32
    80001d88:	ec06                	sd	ra,24(sp)
    80001d8a:	e822                	sd	s0,16(sp)
    80001d8c:	e426                	sd	s1,8(sp)
    80001d8e:	e04a                	sd	s2,0(sp)
    80001d90:	1000                	addi	s0,sp,32
    80001d92:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	c4a080e7          	jalr	-950(ra) # 800019de <myproc>
    80001d9c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d9e:	692c                	ld	a1,80(a0)
    80001da0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001da4:	00904f63          	bgtz	s1,80001dc2 <growproc+0x3c>
  } else if(n < 0){
    80001da8:	0204cc63          	bltz	s1,80001de0 <growproc+0x5a>
  p->sz = sz;
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	04c93823          	sd	a2,80(s2)
  return 0;
    80001db4:	4501                	li	a0,0
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	6d28                	ld	a0,88(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	654080e7          	jalr	1620(ra) # 80001422 <uvmalloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	fa69                	bnez	a2,80001dac <growproc+0x26>
      return -1;
    80001ddc:	557d                	li	a0,-1
    80001dde:	bfe1                	j	80001db6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de0:	9e25                	addw	a2,a2,s1
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	1582                	slli	a1,a1,0x20
    80001de8:	9181                	srli	a1,a1,0x20
    80001dea:	6d28                	ld	a0,88(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	5ee080e7          	jalr	1518(ra) # 800013da <uvmdealloc>
    80001df4:	0005061b          	sext.w	a2,a0
    80001df8:	bf55                	j	80001dac <growproc+0x26>

0000000080001dfa <fork>:
{
    80001dfa:	7179                	addi	sp,sp,-48
    80001dfc:	f406                	sd	ra,40(sp)
    80001dfe:	f022                	sd	s0,32(sp)
    80001e00:	ec26                	sd	s1,24(sp)
    80001e02:	e84a                	sd	s2,16(sp)
    80001e04:	e44e                	sd	s3,8(sp)
    80001e06:	e052                	sd	s4,0(sp)
    80001e08:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	bd4080e7          	jalr	-1068(ra) # 800019de <myproc>
    80001e12:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	e22080e7          	jalr	-478(ra) # 80001c36 <allocproc>
    80001e1c:	10050b63          	beqz	a0,80001f32 <fork+0x138>
    80001e20:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e22:	05093603          	ld	a2,80(s2)
    80001e26:	6d2c                	ld	a1,88(a0)
    80001e28:	05893503          	ld	a0,88(s2)
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	742080e7          	jalr	1858(ra) # 8000156e <uvmcopy>
    80001e34:	04054663          	bltz	a0,80001e80 <fork+0x86>
  np->sz = p->sz;
    80001e38:	05093783          	ld	a5,80(s2)
    80001e3c:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  *(np->trapframe) = *(p->trapframe);
    80001e40:	06093683          	ld	a3,96(s2)
    80001e44:	87b6                	mv	a5,a3
    80001e46:	0609b703          	ld	a4,96(s3)
    80001e4a:	12068693          	addi	a3,a3,288
    80001e4e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e52:	6788                	ld	a0,8(a5)
    80001e54:	6b8c                	ld	a1,16(a5)
    80001e56:	6f90                	ld	a2,24(a5)
    80001e58:	01073023          	sd	a6,0(a4)
    80001e5c:	e708                	sd	a0,8(a4)
    80001e5e:	eb0c                	sd	a1,16(a4)
    80001e60:	ef10                	sd	a2,24(a4)
    80001e62:	02078793          	addi	a5,a5,32
    80001e66:	02070713          	addi	a4,a4,32
    80001e6a:	fed792e3          	bne	a5,a3,80001e4e <fork+0x54>
  np->trapframe->a0 = 0;
    80001e6e:	0609b783          	ld	a5,96(s3)
    80001e72:	0607b823          	sd	zero,112(a5)
    80001e76:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001e7a:	15800a13          	li	s4,344
    80001e7e:	a03d                	j	80001eac <fork+0xb2>
    freeproc(np);
    80001e80:	854e                	mv	a0,s3
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	d54080e7          	jalr	-684(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e8a:	854e                	mv	a0,s3
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e0c080e7          	jalr	-500(ra) # 80000c98 <release>
    return -1;
    80001e94:	5a7d                	li	s4,-1
    80001e96:	a069                	j	80001f20 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e98:	00003097          	auipc	ra,0x3
    80001e9c:	a8a080e7          	jalr	-1398(ra) # 80004922 <filedup>
    80001ea0:	009987b3          	add	a5,s3,s1
    80001ea4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea6:	04a1                	addi	s1,s1,8
    80001ea8:	01448763          	beq	s1,s4,80001eb6 <fork+0xbc>
    if(p->ofile[i])
    80001eac:	009907b3          	add	a5,s2,s1
    80001eb0:	6388                	ld	a0,0(a5)
    80001eb2:	f17d                	bnez	a0,80001e98 <fork+0x9e>
    80001eb4:	bfcd                	j	80001ea6 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001eb6:	15893503          	ld	a0,344(s2)
    80001eba:	00002097          	auipc	ra,0x2
    80001ebe:	bde080e7          	jalr	-1058(ra) # 80003a98 <idup>
    80001ec2:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec6:	4641                	li	a2,16
    80001ec8:	16090593          	addi	a1,s2,352
    80001ecc:	16098513          	addi	a0,s3,352
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	f62080e7          	jalr	-158(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ed8:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001edc:	854e                	mv	a0,s3
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	dba080e7          	jalr	-582(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001ee6:	0000f497          	auipc	s1,0xf
    80001eea:	3d248493          	addi	s1,s1,978 # 800112b8 <wait_lock>
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	cf4080e7          	jalr	-780(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ef8:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	d9a080e7          	jalr	-614(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	cdc080e7          	jalr	-804(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f10:	478d                	li	a5,3
    80001f12:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f16:	854e                	mv	a0,s3
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d80080e7          	jalr	-640(ra) # 80000c98 <release>
}
    80001f20:	8552                	mv	a0,s4
    80001f22:	70a2                	ld	ra,40(sp)
    80001f24:	7402                	ld	s0,32(sp)
    80001f26:	64e2                	ld	s1,24(sp)
    80001f28:	6942                	ld	s2,16(sp)
    80001f2a:	69a2                	ld	s3,8(sp)
    80001f2c:	6a02                	ld	s4,0(sp)
    80001f2e:	6145                	addi	sp,sp,48
    80001f30:	8082                	ret
    return -1;
    80001f32:	5a7d                	li	s4,-1
    80001f34:	b7f5                	j	80001f20 <fork+0x126>

0000000080001f36 <scheduler>:
{
    80001f36:	7139                	addi	sp,sp,-64
    80001f38:	fc06                	sd	ra,56(sp)
    80001f3a:	f822                	sd	s0,48(sp)
    80001f3c:	f426                	sd	s1,40(sp)
    80001f3e:	f04a                	sd	s2,32(sp)
    80001f40:	ec4e                	sd	s3,24(sp)
    80001f42:	e852                	sd	s4,16(sp)
    80001f44:	e456                	sd	s5,8(sp)
    80001f46:	e05a                	sd	s6,0(sp)
    80001f48:	0080                	addi	s0,sp,64
    80001f4a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f4c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f4e:	00779a93          	slli	s5,a5,0x7
    80001f52:	0000f717          	auipc	a4,0xf
    80001f56:	34e70713          	addi	a4,a4,846 # 800112a0 <pid_lock>
    80001f5a:	9756                	add	a4,a4,s5
    80001f5c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f60:	0000f717          	auipc	a4,0xf
    80001f64:	37870713          	addi	a4,a4,888 # 800112d8 <cpus+0x8>
    80001f68:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f6a:	498d                	li	s3,3
        p->state = RUNNING;
    80001f6c:	4b11                	li	s6,4
        c->proc = p;
    80001f6e:	079e                	slli	a5,a5,0x7
    80001f70:	0000fa17          	auipc	s4,0xf
    80001f74:	330a0a13          	addi	s4,s4,816 # 800112a0 <pid_lock>
    80001f78:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	00015917          	auipc	s2,0x15
    80001f7e:	35690913          	addi	s2,s2,854 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f82:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f86:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f8a:	10079073          	csrw	sstatus,a5
    80001f8e:	0000f497          	auipc	s1,0xf
    80001f92:	74248493          	addi	s1,s1,1858 # 800116d0 <proc>
    80001f96:	a03d                	j	80001fc4 <scheduler+0x8e>
        p->state = RUNNING;
    80001f98:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f9c:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fa0:	06848593          	addi	a1,s1,104
    80001fa4:	8556                	mv	a0,s5
    80001fa6:	00001097          	auipc	ra,0x1
    80001faa:	866080e7          	jalr	-1946(ra) # 8000280c <swtch>
        c->proc = 0;
    80001fae:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ce4080e7          	jalr	-796(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fbc:	17048493          	addi	s1,s1,368
    80001fc0:	fd2481e3          	beq	s1,s2,80001f82 <scheduler+0x4c>
      acquire(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	c1e080e7          	jalr	-994(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fce:	4c9c                	lw	a5,24(s1)
    80001fd0:	ff3791e3          	bne	a5,s3,80001fb2 <scheduler+0x7c>
    80001fd4:	b7d1                	j	80001f98 <scheduler+0x62>

0000000080001fd6 <sched>:
{
    80001fd6:	7179                	addi	sp,sp,-48
    80001fd8:	f406                	sd	ra,40(sp)
    80001fda:	f022                	sd	s0,32(sp)
    80001fdc:	ec26                	sd	s1,24(sp)
    80001fde:	e84a                	sd	s2,16(sp)
    80001fe0:	e44e                	sd	s3,8(sp)
    80001fe2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	9fa080e7          	jalr	-1542(ra) # 800019de <myproc>
    80001fec:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	b7c080e7          	jalr	-1156(ra) # 80000b6a <holding>
    80001ff6:	c93d                	beqz	a0,8000206c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	0000f717          	auipc	a4,0xf
    80002002:	2a270713          	addi	a4,a4,674 # 800112a0 <pid_lock>
    80002006:	97ba                	add	a5,a5,a4
    80002008:	0a87a703          	lw	a4,168(a5)
    8000200c:	4785                	li	a5,1
    8000200e:	06f71763          	bne	a4,a5,8000207c <sched+0xa6>
  if(p->state == RUNNING)
    80002012:	4c98                	lw	a4,24(s1)
    80002014:	4791                	li	a5,4
    80002016:	06f70b63          	beq	a4,a5,8000208c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000201e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002020:	efb5                	bnez	a5,8000209c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002022:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002024:	0000f917          	auipc	s2,0xf
    80002028:	27c90913          	addi	s2,s2,636 # 800112a0 <pid_lock>
    8000202c:	2781                	sext.w	a5,a5
    8000202e:	079e                	slli	a5,a5,0x7
    80002030:	97ca                	add	a5,a5,s2
    80002032:	0ac7a983          	lw	s3,172(a5)
    80002036:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002038:	2781                	sext.w	a5,a5
    8000203a:	079e                	slli	a5,a5,0x7
    8000203c:	0000f597          	auipc	a1,0xf
    80002040:	29c58593          	addi	a1,a1,668 # 800112d8 <cpus+0x8>
    80002044:	95be                	add	a1,a1,a5
    80002046:	06848513          	addi	a0,s1,104
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	7c2080e7          	jalr	1986(ra) # 8000280c <swtch>
    80002052:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	97ca                	add	a5,a5,s2
    8000205a:	0b37a623          	sw	s3,172(a5)
}
    8000205e:	70a2                	ld	ra,40(sp)
    80002060:	7402                	ld	s0,32(sp)
    80002062:	64e2                	ld	s1,24(sp)
    80002064:	6942                	ld	s2,16(sp)
    80002066:	69a2                	ld	s3,8(sp)
    80002068:	6145                	addi	sp,sp,48
    8000206a:	8082                	ret
    panic("sched p->lock");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1cc50513          	addi	a0,a0,460 # 80008238 <digits+0x1f8>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4ca080e7          	jalr	1226(ra) # 8000053e <panic>
    panic("sched locks");
    8000207c:	00006517          	auipc	a0,0x6
    80002080:	1cc50513          	addi	a0,a0,460 # 80008248 <digits+0x208>
    80002084:	ffffe097          	auipc	ra,0xffffe
    80002088:	4ba080e7          	jalr	1210(ra) # 8000053e <panic>
    panic("sched running");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	1cc50513          	addi	a0,a0,460 # 80008258 <digits+0x218>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4aa080e7          	jalr	1194(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	1cc50513          	addi	a0,a0,460 # 80008268 <digits+0x228>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	49a080e7          	jalr	1178(ra) # 8000053e <panic>

00000000800020ac <yield>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	928080e7          	jalr	-1752(ra) # 800019de <myproc>
    800020be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b24080e7          	jalr	-1244(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    800020c8:	478d                	li	a5,3
    800020ca:	cc9c                	sw	a5,24(s1)
  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	f0a080e7          	jalr	-246(ra) # 80001fd6 <sched>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bc2080e7          	jalr	-1086(ra) # 80000c98 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <forkret2>:
{
    800020e8:	1141                	addi	sp,sp,-16
    800020ea:	e406                	sd	ra,8(sp)
    800020ec:	e022                	sd	s0,0(sp)
    800020ee:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	8ee080e7          	jalr	-1810(ra) # 800019de <myproc>
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba0080e7          	jalr	-1120(ra) # 80000c98 <release>
  if (first) {
    80002100:	00007797          	auipc	a5,0x7
    80002104:	8787a783          	lw	a5,-1928(a5) # 80008978 <first.1684>
    80002108:	eb8d                	bnez	a5,8000213a <forkret2+0x52>
  printf("forkret2\n");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	17650513          	addi	a0,a0,374 # 80008280 <digits+0x240>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	476080e7          	jalr	1142(ra) # 80000588 <printf>
  usertrapret2();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	79c080e7          	jalr	1948(ra) # 800028b6 <usertrapret2>
  printf("forkret2 -1\n");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	16e50513          	addi	a0,a0,366 # 80008290 <digits+0x250>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	45e080e7          	jalr	1118(ra) # 80000588 <printf>
}
    80002132:	60a2                	ld	ra,8(sp)
    80002134:	6402                	ld	s0,0(sp)
    80002136:	0141                	addi	sp,sp,16
    80002138:	8082                	ret
    first = 0;
    8000213a:	00007797          	auipc	a5,0x7
    8000213e:	8207af23          	sw	zero,-1986(a5) # 80008978 <first.1684>
    fsinit(ROOTDEV);
    80002142:	4505                	li	a0,1
    80002144:	00001097          	auipc	ra,0x1
    80002148:	71a080e7          	jalr	1818(ra) # 8000385e <fsinit>
    8000214c:	bf7d                	j	8000210a <forkret2+0x22>

000000008000214e <sleep>:
{
    8000214e:	7179                	addi	sp,sp,-48
    80002150:	f406                	sd	ra,40(sp)
    80002152:	f022                	sd	s0,32(sp)
    80002154:	ec26                	sd	s1,24(sp)
    80002156:	e84a                	sd	s2,16(sp)
    80002158:	e44e                	sd	s3,8(sp)
    8000215a:	1800                	addi	s0,sp,48
    8000215c:	89aa                	mv	s3,a0
    8000215e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002160:	00000097          	auipc	ra,0x0
    80002164:	87e080e7          	jalr	-1922(ra) # 800019de <myproc>
    80002168:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	a7a080e7          	jalr	-1414(ra) # 80000be4 <acquire>
  release(lk);
    80002172:	854a                	mv	a0,s2
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b24080e7          	jalr	-1244(ra) # 80000c98 <release>
  p->chan = chan;
    8000217c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002180:	4789                	li	a5,2
    80002182:	cc9c                	sw	a5,24(s1)
  sched();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	e52080e7          	jalr	-430(ra) # 80001fd6 <sched>
  p->chan = 0;
    8000218c:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b06080e7          	jalr	-1274(ra) # 80000c98 <release>
  acquire(lk);
    8000219a:	854a                	mv	a0,s2
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a48080e7          	jalr	-1464(ra) # 80000be4 <acquire>
}
    800021a4:	70a2                	ld	ra,40(sp)
    800021a6:	7402                	ld	s0,32(sp)
    800021a8:	64e2                	ld	s1,24(sp)
    800021aa:	6942                	ld	s2,16(sp)
    800021ac:	69a2                	ld	s3,8(sp)
    800021ae:	6145                	addi	sp,sp,48
    800021b0:	8082                	ret

00000000800021b2 <wait>:
{
    800021b2:	715d                	addi	sp,sp,-80
    800021b4:	e486                	sd	ra,72(sp)
    800021b6:	e0a2                	sd	s0,64(sp)
    800021b8:	fc26                	sd	s1,56(sp)
    800021ba:	f84a                	sd	s2,48(sp)
    800021bc:	f44e                	sd	s3,40(sp)
    800021be:	f052                	sd	s4,32(sp)
    800021c0:	ec56                	sd	s5,24(sp)
    800021c2:	e85a                	sd	s6,16(sp)
    800021c4:	e45e                	sd	s7,8(sp)
    800021c6:	e062                	sd	s8,0(sp)
    800021c8:	0880                	addi	s0,sp,80
    800021ca:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	812080e7          	jalr	-2030(ra) # 800019de <myproc>
    800021d4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021d6:	0000f517          	auipc	a0,0xf
    800021da:	0e250513          	addi	a0,a0,226 # 800112b8 <wait_lock>
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	a06080e7          	jalr	-1530(ra) # 80000be4 <acquire>
    havekids = 0;
    800021e6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021e8:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021ea:	00015997          	auipc	s3,0x15
    800021ee:	0e698993          	addi	s3,s3,230 # 800172d0 <tickslock>
        havekids = 1;
    800021f2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021f4:	0000fc17          	auipc	s8,0xf
    800021f8:	0c4c0c13          	addi	s8,s8,196 # 800112b8 <wait_lock>
    havekids = 0;
    800021fc:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800021fe:	0000f497          	auipc	s1,0xf
    80002202:	4d248493          	addi	s1,s1,1234 # 800116d0 <proc>
    80002206:	a0bd                	j	80002274 <wait+0xc2>
          pid = np->pid;
    80002208:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000220c:	000b0e63          	beqz	s6,80002228 <wait+0x76>
    80002210:	4691                	li	a3,4
    80002212:	02c48613          	addi	a2,s1,44
    80002216:	85da                	mv	a1,s6
    80002218:	05893503          	ld	a0,88(s2)
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	456080e7          	jalr	1110(ra) # 80001672 <copyout>
    80002224:	02054563          	bltz	a0,8000224e <wait+0x9c>
          freeproc(np);
    80002228:	8526                	mv	a0,s1
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80001bd6 <freeproc>
          release(&np->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a64080e7          	jalr	-1436(ra) # 80000c98 <release>
          release(&wait_lock);
    8000223c:	0000f517          	auipc	a0,0xf
    80002240:	07c50513          	addi	a0,a0,124 # 800112b8 <wait_lock>
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a54080e7          	jalr	-1452(ra) # 80000c98 <release>
          return pid;
    8000224c:	a09d                	j	800022b2 <wait+0x100>
            release(&np->lock);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	a48080e7          	jalr	-1464(ra) # 80000c98 <release>
            release(&wait_lock);
    80002258:	0000f517          	auipc	a0,0xf
    8000225c:	06050513          	addi	a0,a0,96 # 800112b8 <wait_lock>
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	a38080e7          	jalr	-1480(ra) # 80000c98 <release>
            return -1;
    80002268:	59fd                	li	s3,-1
    8000226a:	a0a1                	j	800022b2 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000226c:	17048493          	addi	s1,s1,368
    80002270:	03348463          	beq	s1,s3,80002298 <wait+0xe6>
      if(np->parent == p){
    80002274:	60bc                	ld	a5,64(s1)
    80002276:	ff279be3          	bne	a5,s2,8000226c <wait+0xba>
        acquire(&np->lock);
    8000227a:	8526                	mv	a0,s1
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	968080e7          	jalr	-1688(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002284:	4c9c                	lw	a5,24(s1)
    80002286:	f94781e3          	beq	a5,s4,80002208 <wait+0x56>
        release(&np->lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a0c080e7          	jalr	-1524(ra) # 80000c98 <release>
        havekids = 1;
    80002294:	8756                	mv	a4,s5
    80002296:	bfd9                	j	8000226c <wait+0xba>
    if(!havekids || p->killed){
    80002298:	c701                	beqz	a4,800022a0 <wait+0xee>
    8000229a:	02892783          	lw	a5,40(s2)
    8000229e:	c79d                	beqz	a5,800022cc <wait+0x11a>
      release(&wait_lock);
    800022a0:	0000f517          	auipc	a0,0xf
    800022a4:	01850513          	addi	a0,a0,24 # 800112b8 <wait_lock>
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	9f0080e7          	jalr	-1552(ra) # 80000c98 <release>
      return -1;
    800022b0:	59fd                	li	s3,-1
}
    800022b2:	854e                	mv	a0,s3
    800022b4:	60a6                	ld	ra,72(sp)
    800022b6:	6406                	ld	s0,64(sp)
    800022b8:	74e2                	ld	s1,56(sp)
    800022ba:	7942                	ld	s2,48(sp)
    800022bc:	79a2                	ld	s3,40(sp)
    800022be:	7a02                	ld	s4,32(sp)
    800022c0:	6ae2                	ld	s5,24(sp)
    800022c2:	6b42                	ld	s6,16(sp)
    800022c4:	6ba2                	ld	s7,8(sp)
    800022c6:	6c02                	ld	s8,0(sp)
    800022c8:	6161                	addi	sp,sp,80
    800022ca:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022cc:	85e2                	mv	a1,s8
    800022ce:	854a                	mv	a0,s2
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	e7e080e7          	jalr	-386(ra) # 8000214e <sleep>
    havekids = 0;
    800022d8:	b715                	j	800021fc <wait+0x4a>

00000000800022da <wakeup>:
{
    800022da:	7139                	addi	sp,sp,-64
    800022dc:	fc06                	sd	ra,56(sp)
    800022de:	f822                	sd	s0,48(sp)
    800022e0:	f426                	sd	s1,40(sp)
    800022e2:	f04a                	sd	s2,32(sp)
    800022e4:	ec4e                	sd	s3,24(sp)
    800022e6:	e852                	sd	s4,16(sp)
    800022e8:	e456                	sd	s5,8(sp)
    800022ea:	0080                	addi	s0,sp,64
    800022ec:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ee:	0000f497          	auipc	s1,0xf
    800022f2:	3e248493          	addi	s1,s1,994 # 800116d0 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    800022f6:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022f8:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022fa:	00015917          	auipc	s2,0x15
    800022fe:	fd690913          	addi	s2,s2,-42 # 800172d0 <tickslock>
    80002302:	a821                	j	8000231a <wakeup+0x40>
        p->state = RUNNABLE;
    80002304:	0154ac23          	sw	s5,24(s1)
      release(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	98e080e7          	jalr	-1650(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002312:	17048493          	addi	s1,s1,368
    80002316:	03248463          	beq	s1,s2,8000233e <wakeup+0x64>
    if(p != myproc()){
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	6c4080e7          	jalr	1732(ra) # 800019de <myproc>
    80002322:	fea488e3          	beq	s1,a0,80002312 <wakeup+0x38>
      acquire(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8bc080e7          	jalr	-1860(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002330:	4c9c                	lw	a5,24(s1)
    80002332:	fd379be3          	bne	a5,s3,80002308 <wakeup+0x2e>
    80002336:	709c                	ld	a5,32(s1)
    80002338:	fd4798e3          	bne	a5,s4,80002308 <wakeup+0x2e>
    8000233c:	b7e1                	j	80002304 <wakeup+0x2a>
}
    8000233e:	70e2                	ld	ra,56(sp)
    80002340:	7442                	ld	s0,48(sp)
    80002342:	74a2                	ld	s1,40(sp)
    80002344:	7902                	ld	s2,32(sp)
    80002346:	69e2                	ld	s3,24(sp)
    80002348:	6a42                	ld	s4,16(sp)
    8000234a:	6aa2                	ld	s5,8(sp)
    8000234c:	6121                	addi	sp,sp,64
    8000234e:	8082                	ret

0000000080002350 <reparent>:
{
    80002350:	7179                	addi	sp,sp,-48
    80002352:	f406                	sd	ra,40(sp)
    80002354:	f022                	sd	s0,32(sp)
    80002356:	ec26                	sd	s1,24(sp)
    80002358:	e84a                	sd	s2,16(sp)
    8000235a:	e44e                	sd	s3,8(sp)
    8000235c:	e052                	sd	s4,0(sp)
    8000235e:	1800                	addi	s0,sp,48
    80002360:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002362:	0000f497          	auipc	s1,0xf
    80002366:	36e48493          	addi	s1,s1,878 # 800116d0 <proc>
      pp->parent = initproc;
    8000236a:	00007a17          	auipc	s4,0x7
    8000236e:	cc6a0a13          	addi	s4,s4,-826 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002372:	00015997          	auipc	s3,0x15
    80002376:	f5e98993          	addi	s3,s3,-162 # 800172d0 <tickslock>
    8000237a:	a029                	j	80002384 <reparent+0x34>
    8000237c:	17048493          	addi	s1,s1,368
    80002380:	01348d63          	beq	s1,s3,8000239a <reparent+0x4a>
    if(pp->parent == p){
    80002384:	60bc                	ld	a5,64(s1)
    80002386:	ff279be3          	bne	a5,s2,8000237c <reparent+0x2c>
      pp->parent = initproc;
    8000238a:	000a3503          	ld	a0,0(s4)
    8000238e:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002390:	00000097          	auipc	ra,0x0
    80002394:	f4a080e7          	jalr	-182(ra) # 800022da <wakeup>
    80002398:	b7d5                	j	8000237c <reparent+0x2c>
}
    8000239a:	70a2                	ld	ra,40(sp)
    8000239c:	7402                	ld	s0,32(sp)
    8000239e:	64e2                	ld	s1,24(sp)
    800023a0:	6942                	ld	s2,16(sp)
    800023a2:	69a2                	ld	s3,8(sp)
    800023a4:	6a02                	ld	s4,0(sp)
    800023a6:	6145                	addi	sp,sp,48
    800023a8:	8082                	ret

00000000800023aa <exit>:
{
    800023aa:	7179                	addi	sp,sp,-48
    800023ac:	f406                	sd	ra,40(sp)
    800023ae:	f022                	sd	s0,32(sp)
    800023b0:	ec26                	sd	s1,24(sp)
    800023b2:	e84a                	sd	s2,16(sp)
    800023b4:	e44e                	sd	s3,8(sp)
    800023b6:	e052                	sd	s4,0(sp)
    800023b8:	1800                	addi	s0,sp,48
    800023ba:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	622080e7          	jalr	1570(ra) # 800019de <myproc>
    800023c4:	89aa                	mv	s3,a0
  if(p == initproc)
    800023c6:	00007797          	auipc	a5,0x7
    800023ca:	c6a7b783          	ld	a5,-918(a5) # 80009030 <initproc>
    800023ce:	0d850493          	addi	s1,a0,216
    800023d2:	15850913          	addi	s2,a0,344
    800023d6:	02a79363          	bne	a5,a0,800023fc <exit+0x52>
    panic("init exiting");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	ec650513          	addi	a0,a0,-314 # 800082a0 <digits+0x260>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>
      fileclose(f);
    800023ea:	00002097          	auipc	ra,0x2
    800023ee:	58a080e7          	jalr	1418(ra) # 80004974 <fileclose>
      p->ofile[fd] = 0;
    800023f2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023f6:	04a1                	addi	s1,s1,8
    800023f8:	01248563          	beq	s1,s2,80002402 <exit+0x58>
    if(p->ofile[fd]){
    800023fc:	6088                	ld	a0,0(s1)
    800023fe:	f575                	bnez	a0,800023ea <exit+0x40>
    80002400:	bfdd                	j	800023f6 <exit+0x4c>
  begin_op();
    80002402:	00002097          	auipc	ra,0x2
    80002406:	0a6080e7          	jalr	166(ra) # 800044a8 <begin_op>
  iput(p->cwd);
    8000240a:	1589b503          	ld	a0,344(s3)
    8000240e:	00002097          	auipc	ra,0x2
    80002412:	882080e7          	jalr	-1918(ra) # 80003c90 <iput>
  end_op();
    80002416:	00002097          	auipc	ra,0x2
    8000241a:	112080e7          	jalr	274(ra) # 80004528 <end_op>
  p->cwd = 0;
    8000241e:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    80002422:	0000f497          	auipc	s1,0xf
    80002426:	e9648493          	addi	s1,s1,-362 # 800112b8 <wait_lock>
    8000242a:	8526                	mv	a0,s1
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	7b8080e7          	jalr	1976(ra) # 80000be4 <acquire>
  reparent(p);
    80002434:	854e                	mv	a0,s3
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	f1a080e7          	jalr	-230(ra) # 80002350 <reparent>
  wakeup(p->parent);
    8000243e:	0409b503          	ld	a0,64(s3)
    80002442:	00000097          	auipc	ra,0x0
    80002446:	e98080e7          	jalr	-360(ra) # 800022da <wakeup>
  acquire(&p->lock);
    8000244a:	854e                	mv	a0,s3
    8000244c:	ffffe097          	auipc	ra,0xffffe
    80002450:	798080e7          	jalr	1944(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002454:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002458:	4795                	li	a5,5
    8000245a:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	838080e7          	jalr	-1992(ra) # 80000c98 <release>
  sched();
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	b6e080e7          	jalr	-1170(ra) # 80001fd6 <sched>
  panic("zombie exit");
    80002470:	00006517          	auipc	a0,0x6
    80002474:	e4050513          	addi	a0,a0,-448 # 800082b0 <digits+0x270>
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	0c6080e7          	jalr	198(ra) # 8000053e <panic>

0000000080002480 <kill>:
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    80002490:	0000f497          	auipc	s1,0xf
    80002494:	24048493          	addi	s1,s1,576 # 800116d0 <proc>
    80002498:	00015997          	auipc	s3,0x15
    8000249c:	e3898993          	addi	s3,s3,-456 # 800172d0 <tickslock>
    acquire(&p->lock);
    800024a0:	8526                	mv	a0,s1
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	742080e7          	jalr	1858(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024aa:	589c                	lw	a5,48(s1)
    800024ac:	01278d63          	beq	a5,s2,800024c6 <kill+0x46>
    release(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7e6080e7          	jalr	2022(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ba:	17048493          	addi	s1,s1,368
    800024be:	ff3491e3          	bne	s1,s3,800024a0 <kill+0x20>
  return -1;
    800024c2:	557d                	li	a0,-1
    800024c4:	a829                	j	800024de <kill+0x5e>
      p->killed = 1;
    800024c6:	4785                	li	a5,1
    800024c8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024ca:	4c98                	lw	a4,24(s1)
    800024cc:	4789                	li	a5,2
    800024ce:	00f70f63          	beq	a4,a5,800024ec <kill+0x6c>
      release(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	7c4080e7          	jalr	1988(ra) # 80000c98 <release>
      return 0;
    800024dc:	4501                	li	a0,0
}
    800024de:	70a2                	ld	ra,40(sp)
    800024e0:	7402                	ld	s0,32(sp)
    800024e2:	64e2                	ld	s1,24(sp)
    800024e4:	6942                	ld	s2,16(sp)
    800024e6:	69a2                	ld	s3,8(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret
        p->state = RUNNABLE;
    800024ec:	478d                	li	a5,3
    800024ee:	cc9c                	sw	a5,24(s1)
    800024f0:	b7cd                	j	800024d2 <kill+0x52>

00000000800024f2 <either_copyout>:
{
    800024f2:	7179                	addi	sp,sp,-48
    800024f4:	f406                	sd	ra,40(sp)
    800024f6:	f022                	sd	s0,32(sp)
    800024f8:	ec26                	sd	s1,24(sp)
    800024fa:	e84a                	sd	s2,16(sp)
    800024fc:	e44e                	sd	s3,8(sp)
    800024fe:	e052                	sd	s4,0(sp)
    80002500:	1800                	addi	s0,sp,48
    80002502:	84aa                	mv	s1,a0
    80002504:	892e                	mv	s2,a1
    80002506:	89b2                	mv	s3,a2
    80002508:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	4d4080e7          	jalr	1236(ra) # 800019de <myproc>
  if(user_dst){
    80002512:	c08d                	beqz	s1,80002534 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002514:	86d2                	mv	a3,s4
    80002516:	864e                	mv	a2,s3
    80002518:	85ca                	mv	a1,s2
    8000251a:	6d28                	ld	a0,88(a0)
    8000251c:	fffff097          	auipc	ra,0xfffff
    80002520:	156080e7          	jalr	342(ra) # 80001672 <copyout>
}
    80002524:	70a2                	ld	ra,40(sp)
    80002526:	7402                	ld	s0,32(sp)
    80002528:	64e2                	ld	s1,24(sp)
    8000252a:	6942                	ld	s2,16(sp)
    8000252c:	69a2                	ld	s3,8(sp)
    8000252e:	6a02                	ld	s4,0(sp)
    80002530:	6145                	addi	sp,sp,48
    80002532:	8082                	ret
    memmove((char *)dst, src, len);
    80002534:	000a061b          	sext.w	a2,s4
    80002538:	85ce                	mv	a1,s3
    8000253a:	854a                	mv	a0,s2
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	804080e7          	jalr	-2044(ra) # 80000d40 <memmove>
    return 0;
    80002544:	8526                	mv	a0,s1
    80002546:	bff9                	j	80002524 <either_copyout+0x32>

0000000080002548 <either_copyin>:
{
    80002548:	7179                	addi	sp,sp,-48
    8000254a:	f406                	sd	ra,40(sp)
    8000254c:	f022                	sd	s0,32(sp)
    8000254e:	ec26                	sd	s1,24(sp)
    80002550:	e84a                	sd	s2,16(sp)
    80002552:	e44e                	sd	s3,8(sp)
    80002554:	e052                	sd	s4,0(sp)
    80002556:	1800                	addi	s0,sp,48
    80002558:	892a                	mv	s2,a0
    8000255a:	84ae                	mv	s1,a1
    8000255c:	89b2                	mv	s3,a2
    8000255e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	47e080e7          	jalr	1150(ra) # 800019de <myproc>
  if(user_src){
    80002568:	c08d                	beqz	s1,8000258a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256a:	86d2                	mv	a3,s4
    8000256c:	864e                	mv	a2,s3
    8000256e:	85ca                	mv	a1,s2
    80002570:	6d28                	ld	a0,88(a0)
    80002572:	fffff097          	auipc	ra,0xfffff
    80002576:	18c080e7          	jalr	396(ra) # 800016fe <copyin>
}
    8000257a:	70a2                	ld	ra,40(sp)
    8000257c:	7402                	ld	s0,32(sp)
    8000257e:	64e2                	ld	s1,24(sp)
    80002580:	6942                	ld	s2,16(sp)
    80002582:	69a2                	ld	s3,8(sp)
    80002584:	6a02                	ld	s4,0(sp)
    80002586:	6145                	addi	sp,sp,48
    80002588:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258a:	000a061b          	sext.w	a2,s4
    8000258e:	85ce                	mv	a1,s3
    80002590:	854a                	mv	a0,s2
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	7ae080e7          	jalr	1966(ra) # 80000d40 <memmove>
    return 0;
    8000259a:	8526                	mv	a0,s1
    8000259c:	bff9                	j	8000257a <either_copyin+0x32>

000000008000259e <procdump>:
{
    8000259e:	715d                	addi	sp,sp,-80
    800025a0:	e486                	sd	ra,72(sp)
    800025a2:	e0a2                	sd	s0,64(sp)
    800025a4:	fc26                	sd	s1,56(sp)
    800025a6:	f84a                	sd	s2,48(sp)
    800025a8:	f44e                	sd	s3,40(sp)
    800025aa:	f052                	sd	s4,32(sp)
    800025ac:	ec56                	sd	s5,24(sp)
    800025ae:	e85a                	sd	s6,16(sp)
    800025b0:	e45e                	sd	s7,8(sp)
    800025b2:	0880                	addi	s0,sp,80
  printf("\n");
    800025b4:	00006517          	auipc	a0,0x6
    800025b8:	dec50513          	addi	a0,a0,-532 # 800083a0 <states.1725+0x70>
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	fcc080e7          	jalr	-52(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c4:	0000f497          	auipc	s1,0xf
    800025c8:	26c48493          	addi	s1,s1,620 # 80011830 <proc+0x160>
    800025cc:	00015917          	auipc	s2,0x15
    800025d0:	e6490913          	addi	s2,s2,-412 # 80017430 <bcache+0x148>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d4:	4b15                	li	s6,5
      state = "???";
    800025d6:	00006997          	auipc	s3,0x6
    800025da:	cea98993          	addi	s3,s3,-790 # 800082c0 <digits+0x280>
    printf("%d %s %s", p->pid, state, p->name);
    800025de:	00006a97          	auipc	s5,0x6
    800025e2:	ceaa8a93          	addi	s5,s5,-790 # 800082c8 <digits+0x288>
    printf("\n");
    800025e6:	00006a17          	auipc	s4,0x6
    800025ea:	dbaa0a13          	addi	s4,s4,-582 # 800083a0 <states.1725+0x70>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	00006b97          	auipc	s7,0x6
    800025f2:	d42b8b93          	addi	s7,s7,-702 # 80008330 <states.1725>
    800025f6:	a00d                	j	80002618 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	ed06a583          	lw	a1,-304(a3)
    800025fc:	8556                	mv	a0,s5
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	f8a080e7          	jalr	-118(ra) # 80000588 <printf>
    printf("\n");
    80002606:	8552                	mv	a0,s4
    80002608:	ffffe097          	auipc	ra,0xffffe
    8000260c:	f80080e7          	jalr	-128(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002610:	17048493          	addi	s1,s1,368
    80002614:	03248163          	beq	s1,s2,80002636 <procdump+0x98>
    if(p->state == UNUSED)
    80002618:	86a6                	mv	a3,s1
    8000261a:	eb84a783          	lw	a5,-328(s1)
    8000261e:	dbed                	beqz	a5,80002610 <procdump+0x72>
      state = "???";
    80002620:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002622:	fcfb6be3          	bltu	s6,a5,800025f8 <procdump+0x5a>
    80002626:	1782                	slli	a5,a5,0x20
    80002628:	9381                	srli	a5,a5,0x20
    8000262a:	078e                	slli	a5,a5,0x3
    8000262c:	97de                	add	a5,a5,s7
    8000262e:	6390                	ld	a2,0(a5)
    80002630:	f661                	bnez	a2,800025f8 <procdump+0x5a>
      state = "???";
    80002632:	864e                	mv	a2,s3
    80002634:	b7d1                	j	800025f8 <procdump+0x5a>
}
    80002636:	60a6                	ld	ra,72(sp)
    80002638:	6406                	ld	s0,64(sp)
    8000263a:	74e2                	ld	s1,56(sp)
    8000263c:	7942                	ld	s2,48(sp)
    8000263e:	79a2                	ld	s3,40(sp)
    80002640:	7a02                	ld	s4,32(sp)
    80002642:	6ae2                	ld	s5,24(sp)
    80002644:	6b42                	ld	s6,16(sp)
    80002646:	6ba2                	ld	s7,8(sp)
    80002648:	6161                	addi	sp,sp,80
    8000264a:	8082                	ret

000000008000264c <clone>:

  return p;
}

int clone(void * stack, int size)
{
    8000264c:	7179                	addi	sp,sp,-48
    8000264e:	f406                	sd	ra,40(sp)
    80002650:	f022                	sd	s0,32(sp)
    80002652:	ec26                	sd	s1,24(sp)
    80002654:	e84a                	sd	s2,16(sp)
    80002656:	e44e                	sd	s3,8(sp)
    80002658:	e052                	sd	s4,0(sp)
    8000265a:	1800                	addi	s0,sp,48
 
  if (!stack) {
    8000265c:	c121                	beqz	a0,8000269c <clone+0x50>
    8000265e:	8a2a                	mv	s4,a0
    return -1;
  }
  
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	37e080e7          	jalr	894(ra) # 800019de <myproc>
    80002668:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000266a:	0000f497          	auipc	s1,0xf
    8000266e:	06648493          	addi	s1,s1,102 # 800116d0 <proc>
    80002672:	00015917          	auipc	s2,0x15
    80002676:	c5e90913          	addi	s2,s2,-930 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80002684:	4c9c                	lw	a5,24(s1)
    80002686:	c785                	beqz	a5,800026ae <clone+0x62>
      release(&p->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	60e080e7          	jalr	1550(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002692:	17048493          	addi	s1,s1,368
    80002696:	ff2492e3          	bne	s1,s2,8000267a <clone+0x2e>
    8000269a:	a285                	j	800027fa <clone+0x1ae>
    printf("clone: stack is null");
    8000269c:	00006517          	auipc	a0,0x6
    800026a0:	c3c50513          	addi	a0,a0,-964 # 800082d8 <digits+0x298>
    800026a4:	ffffe097          	auipc	ra,0xffffe
    800026a8:	ee4080e7          	jalr	-284(ra) # 80000588 <printf>
    return -1;
    800026ac:	a2b9                	j	800027fa <clone+0x1ae>
  p->pid = allocpid();
    800026ae:	fffff097          	auipc	ra,0xfffff
    800026b2:	3f4080e7          	jalr	1012(ra) # 80001aa2 <allocpid>
    800026b6:	d888                	sw	a0,48(s1)
  p->state = USED;
    800026b8:	4785                	li	a5,1
    800026ba:	cc9c                	sw	a5,24(s1)
  if(((p->trapframe = (struct trapframe *)kalloc()) == 0)){
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	438080e7          	jalr	1080(ra) # 80000af4 <kalloc>
    800026c4:	f0a8                	sd	a0,96(s1)
    800026c6:	c141                	beqz	a0,80002746 <clone+0xfa>
  memset(&p->context, 0, sizeof(p->context));
    800026c8:	07000613          	li	a2,112
    800026cc:	4581                	li	a1,0
    800026ce:	06848513          	addi	a0,s1,104
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	60e080e7          	jalr	1550(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret_thread;
    800026da:	fffff797          	auipc	a5,0xfffff
    800026de:	38278793          	addi	a5,a5,898 # 80001a5c <forkret_thread>
    800026e2:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    800026e4:	64bc                	ld	a5,72(s1)
    800026e6:	6705                	lui	a4,0x1
    800026e8:	97ba                	add	a5,a5,a4
    800026ea:	f8bc                	sd	a5,112(s1)
  //if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
  //  freeproc(np);
  // release(&np->lock);
  //  return -1;
  //}
  np->pagetable = p->pagetable;
    800026ec:	0589b783          	ld	a5,88(s3)
    800026f0:	ecbc                	sd	a5,88(s1)
  np->sz = p->sz;
    800026f2:	0509b783          	ld	a5,80(s3)
    800026f6:	e8bc                	sd	a5,80(s1)
  
  //update parent thread count and thread id
  p->tcnt +=1;
    800026f8:	0389a783          	lw	a5,56(s3)
    800026fc:	2785                	addiw	a5,a5,1
    800026fe:	02f9ac23          	sw	a5,56(s3)
  np->tid = p->tcnt;
    80002702:	d8dc                	sw	a5,52(s1)

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);
    80002704:	0609b683          	ld	a3,96(s3)
    80002708:	87b6                	mv	a5,a3
    8000270a:	70b8                	ld	a4,96(s1)
    8000270c:	12068693          	addi	a3,a3,288
    80002710:	0007b803          	ld	a6,0(a5)
    80002714:	6788                	ld	a0,8(a5)
    80002716:	6b8c                	ld	a1,16(a5)
    80002718:	6f90                	ld	a2,24(a5)
    8000271a:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    8000271e:	e708                	sd	a0,8(a4)
    80002720:	eb0c                	sd	a1,16(a4)
    80002722:	ef10                	sd	a2,24(a4)
    80002724:	02078793          	addi	a5,a5,32
    80002728:	02070713          	addi	a4,a4,32
    8000272c:	fed792e3          	bne	a5,a3,80002710 <clone+0xc4>
  np->trapframe->sp = (uint64) stack;// + size;
    80002730:	70bc                	ld	a5,96(s1)
    80002732:	0347b823          	sd	s4,48(a5)
  //np->trapframe->kernel_sp = (uint64) (stack+size);
	
  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;
    80002736:	70bc                	ld	a5,96(s1)
    80002738:	0607b823          	sd	zero,112(a5)
    8000273c:	0d800913          	li	s2,216

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    80002740:	15800a13          	li	s4,344
    80002744:	a035                	j	80002770 <clone+0x124>
    freeproc(p);
    80002746:	8526                	mv	a0,s1
    80002748:	fffff097          	auipc	ra,0xfffff
    8000274c:	48e080e7          	jalr	1166(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
    return 0;
    8000275a:	a045                	j	800027fa <clone+0x1ae>
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
    8000275c:	00002097          	auipc	ra,0x2
    80002760:	1c6080e7          	jalr	454(ra) # 80004922 <filedup>
    80002764:	012487b3          	add	a5,s1,s2
    80002768:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000276a:	0921                	addi	s2,s2,8
    8000276c:	01490763          	beq	s2,s4,8000277a <clone+0x12e>
    if(p->ofile[i])
    80002770:	012987b3          	add	a5,s3,s2
    80002774:	6388                	ld	a0,0(a5)
    80002776:	f17d                	bnez	a0,8000275c <clone+0x110>
    80002778:	bfcd                	j	8000276a <clone+0x11e>
  np->cwd = idup(p->cwd);
    8000277a:	1589b503          	ld	a0,344(s3)
    8000277e:	00001097          	auipc	ra,0x1
    80002782:	31a080e7          	jalr	794(ra) # 80003a98 <idup>
    80002786:	14a4bc23          	sd	a0,344(s1)

  safestrcpy(np->name, p->name, sizeof(p->name));
    8000278a:	4641                	li	a2,16
    8000278c:	16098593          	addi	a1,s3,352
    80002790:	16048513          	addi	a0,s1,352
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	69e080e7          	jalr	1694(ra) # 80000e32 <safestrcpy>

  np->pid = allocpid();
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	306080e7          	jalr	774(ra) # 80001aa2 <allocpid>
    800027a4:	85aa                	mv	a1,a0
    800027a6:	d888                	sw	a0,48(s1)
  printf("pid from clone: %d\n",np->pid);
    800027a8:	00006517          	auipc	a0,0x6
    800027ac:	b4850513          	addi	a0,a0,-1208 # 800082f0 <digits+0x2b0>
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	dd8080e7          	jalr	-552(ra) # 80000588 <printf>
  //np->tid = 1;

  release(&np->lock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	4de080e7          	jalr	1246(ra) # 80000c98 <release>

  acquire(&wait_lock);
    800027c2:	0000f917          	auipc	s2,0xf
    800027c6:	af690913          	addi	s2,s2,-1290 # 800112b8 <wait_lock>
    800027ca:	854a                	mv	a0,s2
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	418080e7          	jalr	1048(ra) # 80000be4 <acquire>
  np->parent = p;
    800027d4:	0534b023          	sd	s3,64(s1)
  release(&wait_lock);
    800027d8:	854a                	mv	a0,s2
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	4be080e7          	jalr	1214(ra) # 80000c98 <release>

  acquire(&np->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	400080e7          	jalr	1024(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    800027ec:	478d                	li	a5,3
    800027ee:	cc9c                	sw	a5,24(s1)
  release(&np->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	4a6080e7          	jalr	1190(ra) # 80000c98 <release>
  
  
  return pid;
}
    800027fa:	557d                	li	a0,-1
    800027fc:	70a2                	ld	ra,40(sp)
    800027fe:	7402                	ld	s0,32(sp)
    80002800:	64e2                	ld	s1,24(sp)
    80002802:	6942                	ld	s2,16(sp)
    80002804:	69a2                	ld	s3,8(sp)
    80002806:	6a02                	ld	s4,0(sp)
    80002808:	6145                	addi	sp,sp,48
    8000280a:	8082                	ret

000000008000280c <swtch>:
    8000280c:	00153023          	sd	ra,0(a0)
    80002810:	00253423          	sd	sp,8(a0)
    80002814:	e900                	sd	s0,16(a0)
    80002816:	ed04                	sd	s1,24(a0)
    80002818:	03253023          	sd	s2,32(a0)
    8000281c:	03353423          	sd	s3,40(a0)
    80002820:	03453823          	sd	s4,48(a0)
    80002824:	03553c23          	sd	s5,56(a0)
    80002828:	05653023          	sd	s6,64(a0)
    8000282c:	05753423          	sd	s7,72(a0)
    80002830:	05853823          	sd	s8,80(a0)
    80002834:	05953c23          	sd	s9,88(a0)
    80002838:	07a53023          	sd	s10,96(a0)
    8000283c:	07b53423          	sd	s11,104(a0)
    80002840:	0005b083          	ld	ra,0(a1)
    80002844:	0085b103          	ld	sp,8(a1)
    80002848:	6980                	ld	s0,16(a1)
    8000284a:	6d84                	ld	s1,24(a1)
    8000284c:	0205b903          	ld	s2,32(a1)
    80002850:	0285b983          	ld	s3,40(a1)
    80002854:	0305ba03          	ld	s4,48(a1)
    80002858:	0385ba83          	ld	s5,56(a1)
    8000285c:	0405bb03          	ld	s6,64(a1)
    80002860:	0485bb83          	ld	s7,72(a1)
    80002864:	0505bc03          	ld	s8,80(a1)
    80002868:	0585bc83          	ld	s9,88(a1)
    8000286c:	0605bd03          	ld	s10,96(a1)
    80002870:	0685bd83          	ld	s11,104(a1)
    80002874:	8082                	ret

0000000080002876 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002876:	1141                	addi	sp,sp,-16
    80002878:	e406                	sd	ra,8(sp)
    8000287a:	e022                	sd	s0,0(sp)
    8000287c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000287e:	00006597          	auipc	a1,0x6
    80002882:	ae258593          	addi	a1,a1,-1310 # 80008360 <states.1725+0x30>
    80002886:	00015517          	auipc	a0,0x15
    8000288a:	a4a50513          	addi	a0,a0,-1462 # 800172d0 <tickslock>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	2c6080e7          	jalr	710(ra) # 80000b54 <initlock>
}
    80002896:	60a2                	ld	ra,8(sp)
    80002898:	6402                	ld	s0,0(sp)
    8000289a:	0141                	addi	sp,sp,16
    8000289c:	8082                	ret

000000008000289e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000289e:	1141                	addi	sp,sp,-16
    800028a0:	e422                	sd	s0,8(sp)
    800028a2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a4:	00003797          	auipc	a5,0x3
    800028a8:	6ec78793          	addi	a5,a5,1772 # 80005f90 <kernelvec>
    800028ac:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028b0:	6422                	ld	s0,8(sp)
    800028b2:	0141                	addi	sp,sp,16
    800028b4:	8082                	ret

00000000800028b6 <usertrapret2>:
  usertrapret();
}

void
usertrapret2(void)
{
    800028b6:	7139                	addi	sp,sp,-64
    800028b8:	fc06                	sd	ra,56(sp)
    800028ba:	f822                	sd	s0,48(sp)
    800028bc:	f426                	sd	s1,40(sp)
    800028be:	f04a                	sd	s2,32(sp)
    800028c0:	ec4e                	sd	s3,24(sp)
    800028c2:	e852                	sd	s4,16(sp)
    800028c4:	e456                	sd	s5,8(sp)
    800028c6:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800028c8:	fffff097          	auipc	ra,0xfffff
    800028cc:	116080e7          	jalr	278(ra) # 800019de <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028da:	00004a97          	auipc	s5,0x4
    800028de:	726a8a93          	addi	s5,s5,1830 # 80007000 <_trampoline>
    800028e2:	00004797          	auipc	a5,0x4
    800028e6:	71e78793          	addi	a5,a5,1822 # 80007000 <_trampoline>
    800028ea:	415787b3          	sub	a5,a5,s5
    800028ee:	040009b7          	lui	s3,0x4000
    800028f2:	fff98493          	addi	s1,s3,-1 # 3ffffff <_entry-0x7c000001>
    800028f6:	00c49a13          	slli	s4,s1,0xc
    800028fa:	97d2                	add	a5,a5,s4
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028fc:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002900:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002902:	18002773          	csrr	a4,satp
    80002906:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002908:	7138                	ld	a4,96(a0)
    8000290a:	653c                	ld	a5,72(a0)
    8000290c:	6685                	lui	a3,0x1
    8000290e:	97b6                	add	a5,a5,a3
    80002910:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002912:	713c                	ld	a5,96(a0)
    80002914:	00000717          	auipc	a4,0x0
    80002918:	34270713          	addi	a4,a4,834 # 80002c56 <usertrap>
    8000291c:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000291e:	713c                	ld	a5,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002920:	8712                	mv	a4,tp
    80002922:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002924:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002928:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000292c:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002930:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002934:	713c                	ld	a5,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002936:	6f9c                	ld	a5,24(a5)
    80002938:	14179073          	csrw	sepc,a5

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000293c:	05853903          	ld	s2,88(a0)
    80002940:	00c95913          	srli	s2,s2,0xc
    80002944:	57fd                	li	a5,-1
    80002946:	17fe                	slli	a5,a5,0x3f
    80002948:	00f96933          	or	s2,s2,a5

  printf("usertrapret2\n");
    8000294c:	00006517          	auipc	a0,0x6
    80002950:	a1c50513          	addi	a0,a0,-1508 # 80008368 <states.1725+0x38>
    80002954:	ffffe097          	auipc	ra,0xffffe
    80002958:	c34080e7          	jalr	-972(ra) # 80000588 <printf>

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000295c:	00004497          	auipc	s1,0x4
    80002960:	73448493          	addi	s1,s1,1844 # 80007090 <userret>
    80002964:	415484b3          	sub	s1,s1,s5
    80002968:	94d2                	add	s1,s1,s4
  printf("usertrapret2 fn = 0x%x\n", fn);
    8000296a:	85a6                	mv	a1,s1
    8000296c:	00006517          	auipc	a0,0x6
    80002970:	a0c50513          	addi	a0,a0,-1524 # 80008378 <states.1725+0x48>
    80002974:	ffffe097          	auipc	ra,0xffffe
    80002978:	c14080e7          	jalr	-1004(ra) # 80000588 <printf>
  ((void (*)(uint64,uint64))fn)(TRAPFRAME - PGSIZE * 1, satp);
    8000297c:	85ca                	mv	a1,s2
    8000297e:	ffd98513          	addi	a0,s3,-3
    80002982:	0532                	slli	a0,a0,0xc
    80002984:	9482                	jalr	s1
  printf("usertrapret2 - 2\n");
    80002986:	00006517          	auipc	a0,0x6
    8000298a:	a0a50513          	addi	a0,a0,-1526 # 80008390 <states.1725+0x60>
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	bfa080e7          	jalr	-1030(ra) # 80000588 <printf>
}
    80002996:	70e2                	ld	ra,56(sp)
    80002998:	7442                	ld	s0,48(sp)
    8000299a:	74a2                	ld	s1,40(sp)
    8000299c:	7902                	ld	s2,32(sp)
    8000299e:	69e2                	ld	s3,24(sp)
    800029a0:	6a42                	ld	s4,16(sp)
    800029a2:	6aa2                	ld	s5,8(sp)
    800029a4:	6121                	addi	sp,sp,64
    800029a6:	8082                	ret

00000000800029a8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a8:	1141                	addi	sp,sp,-16
    800029aa:	e406                	sd	ra,8(sp)
    800029ac:	e022                	sd	s0,0(sp)
    800029ae:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b0:	fffff097          	auipc	ra,0xfffff
    800029b4:	02e080e7          	jalr	46(ra) # 800019de <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029bc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029be:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029c2:	00004617          	auipc	a2,0x4
    800029c6:	63e60613          	addi	a2,a2,1598 # 80007000 <_trampoline>
    800029ca:	00004697          	auipc	a3,0x4
    800029ce:	63668693          	addi	a3,a3,1590 # 80007000 <_trampoline>
    800029d2:	8e91                	sub	a3,a3,a2
    800029d4:	040007b7          	lui	a5,0x4000
    800029d8:	17fd                	addi	a5,a5,-1
    800029da:	07b2                	slli	a5,a5,0xc
    800029dc:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029de:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029e2:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e4:	180026f3          	csrr	a3,satp
    800029e8:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ea:	7138                	ld	a4,96(a0)
    800029ec:	6534                	ld	a3,72(a0)
    800029ee:	6585                	lui	a1,0x1
    800029f0:	96ae                	add	a3,a3,a1
    800029f2:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f4:	7138                	ld	a4,96(a0)
    800029f6:	00000697          	auipc	a3,0x0
    800029fa:	26068693          	addi	a3,a3,608 # 80002c56 <usertrap>
    800029fe:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a00:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a02:	8692                	mv	a3,tp
    80002a04:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a06:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a0a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a12:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a16:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a18:	6f18                	ld	a4,24(a4)
    80002a1a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1e:	6d2c                	ld	a1,88(a0)
    80002a20:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a22:	00004717          	auipc	a4,0x4
    80002a26:	66e70713          	addi	a4,a4,1646 # 80007090 <userret>
    80002a2a:	8f11                	sub	a4,a4,a2
    80002a2c:	97ba                	add	a5,a5,a4
  // printf("usertrapret2 fn = 0x%x\n", fn);
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a2e:	577d                	li	a4,-1
    80002a30:	177e                	slli	a4,a4,0x3f
    80002a32:	8dd9                	or	a1,a1,a4
    80002a34:	02000537          	lui	a0,0x2000
    80002a38:	157d                	addi	a0,a0,-1
    80002a3a:	0536                	slli	a0,a0,0xd
    80002a3c:	9782                	jalr	a5
}
    80002a3e:	60a2                	ld	ra,8(sp)
    80002a40:	6402                	ld	s0,0(sp)
    80002a42:	0141                	addi	sp,sp,16
    80002a44:	8082                	ret

0000000080002a46 <usertrapret_thread>:

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Lab3
void
usertrapret_thread(void)
{
    80002a46:	7179                	addi	sp,sp,-48
    80002a48:	f406                	sd	ra,40(sp)
    80002a4a:	f022                	sd	s0,32(sp)
    80002a4c:	ec26                	sd	s1,24(sp)
    80002a4e:	e84a                	sd	s2,16(sp)
    80002a50:	e44e                	sd	s3,8(sp)
    80002a52:	e052                	sd	s4,0(sp)
    80002a54:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f88080e7          	jalr	-120(ra) # 800019de <myproc>
    80002a5e:	84aa                	mv	s1,a0
  printf("\nusertrapret_thread: init\n");	
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	94850513          	addi	a0,a0,-1720 # 800083a8 <states.1725+0x78>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b20080e7          	jalr	-1248(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a76:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a7a:	00004a17          	auipc	s4,0x4
    80002a7e:	586a0a13          	addi	s4,s4,1414 # 80007000 <_trampoline>
    80002a82:	00004797          	auipc	a5,0x4
    80002a86:	57e78793          	addi	a5,a5,1406 # 80007000 <_trampoline>
    80002a8a:	414787b3          	sub	a5,a5,s4
    80002a8e:	04000937          	lui	s2,0x4000
    80002a92:	197d                	addi	s2,s2,-1
    80002a94:	0932                	slli	s2,s2,0xc
    80002a96:	97ca                	add	a5,a5,s2
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a98:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a9c:	70bc                	ld	a5,96(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a9e:	18002773          	csrr	a4,satp
    80002aa2:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002aa4:	70b8                	ld	a4,96(s1)
    80002aa6:	64bc                	ld	a5,72(s1)
    80002aa8:	6685                	lui	a3,0x1
    80002aaa:	97b6                	add	a5,a5,a3
    80002aac:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002aae:	70bc                	ld	a5,96(s1)
    80002ab0:	00000717          	auipc	a4,0x0
    80002ab4:	1a670713          	addi	a4,a4,422 # 80002c56 <usertrap>
    80002ab8:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002aba:	70bc                	ld	a5,96(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002abc:	8712                	mv	a4,tp
    80002abe:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ac4:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ac8:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002ad0:	70bc                	ld	a5,96(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ad2:	6f9c                	ld	a5,24(a5)
    80002ad4:	14179073          	csrw	sepc,a5

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002ad8:	0584b983          	ld	s3,88(s1)
    80002adc:	00c9d993          	srli	s3,s3,0xc
    80002ae0:	57fd                	li	a5,-1
    80002ae2:	17fe                	slli	a5,a5,0x3f
    80002ae4:	00f9e9b3          	or	s3,s3,a5

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  printf("\nusertrapret_thread: before change\n");
    80002ae8:	00006517          	auipc	a0,0x6
    80002aec:	8e050513          	addi	a0,a0,-1824 # 800083c8 <states.1725+0x98>
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	a98080e7          	jalr	-1384(ra) # 80000588 <printf>
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002af8:	00004797          	auipc	a5,0x4
    80002afc:	59878793          	addi	a5,a5,1432 # 80007090 <userret>
    80002b00:	414787b3          	sub	a5,a5,s4
    80002b04:	993e                	add	s2,s2,a5
  if (p->tid != 0){
    80002b06:	58dc                	lw	a5,52(s1)
    80002b08:	c7a1                	beqz	a5,80002b50 <usertrapret_thread+0x10a>
  	printf("\nusertrapret_thread: if 1\n");
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	8e650513          	addi	a0,a0,-1818 # 800083f0 <states.1725+0xc0>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a76080e7          	jalr	-1418(ra) # 80000588 <printf>
  	((void (*)(uint64,uint64))fn)(TRAPFRAME - (PGSIZE * p->tid), satp);
    80002b1a:	58c8                	lw	a0,52(s1)
    80002b1c:	00c5151b          	slliw	a0,a0,0xc
    80002b20:	020007b7          	lui	a5,0x2000
    80002b24:	85ce                	mv	a1,s3
    80002b26:	17fd                	addi	a5,a5,-1
    80002b28:	07b6                	slli	a5,a5,0xd
    80002b2a:	40a78533          	sub	a0,a5,a0
    80002b2e:	9902                	jalr	s2
  }
  else {
  	printf("\nusertrapret_thread: else 1\n");
  	((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
  }
  printf("\nusertrapret_thread: end\n");
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	90050513          	addi	a0,a0,-1792 # 80008430 <states.1725+0x100>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a50080e7          	jalr	-1456(ra) # 80000588 <printf>
}
    80002b40:	70a2                	ld	ra,40(sp)
    80002b42:	7402                	ld	s0,32(sp)
    80002b44:	64e2                	ld	s1,24(sp)
    80002b46:	6942                	ld	s2,16(sp)
    80002b48:	69a2                	ld	s3,8(sp)
    80002b4a:	6a02                	ld	s4,0(sp)
    80002b4c:	6145                	addi	sp,sp,48
    80002b4e:	8082                	ret
  	printf("\nusertrapret_thread: else 1\n");
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	8c050513          	addi	a0,a0,-1856 # 80008410 <states.1725+0xe0>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a30080e7          	jalr	-1488(ra) # 80000588 <printf>
  	((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002b60:	85ce                	mv	a1,s3
    80002b62:	02000537          	lui	a0,0x2000
    80002b66:	157d                	addi	a0,a0,-1
    80002b68:	0536                	slli	a0,a0,0xd
    80002b6a:	9902                	jalr	s2
    80002b6c:	b7d1                	j	80002b30 <usertrapret_thread+0xea>

0000000080002b6e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002b6e:	1101                	addi	sp,sp,-32
    80002b70:	ec06                	sd	ra,24(sp)
    80002b72:	e822                	sd	s0,16(sp)
    80002b74:	e426                	sd	s1,8(sp)
    80002b76:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002b78:	00014497          	auipc	s1,0x14
    80002b7c:	75848493          	addi	s1,s1,1880 # 800172d0 <tickslock>
    80002b80:	8526                	mv	a0,s1
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	062080e7          	jalr	98(ra) # 80000be4 <acquire>
  ticks++;
    80002b8a:	00006517          	auipc	a0,0x6
    80002b8e:	4ae50513          	addi	a0,a0,1198 # 80009038 <ticks>
    80002b92:	411c                	lw	a5,0(a0)
    80002b94:	2785                	addiw	a5,a5,1
    80002b96:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002b98:	fffff097          	auipc	ra,0xfffff
    80002b9c:	742080e7          	jalr	1858(ra) # 800022da <wakeup>
  release(&tickslock);
    80002ba0:	8526                	mv	a0,s1
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	0f6080e7          	jalr	246(ra) # 80000c98 <release>
}
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	64a2                	ld	s1,8(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bbe:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002bc2:	00074d63          	bltz	a4,80002bdc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002bc6:	57fd                	li	a5,-1
    80002bc8:	17fe                	slli	a5,a5,0x3f
    80002bca:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bcc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002bce:	06f70363          	beq	a4,a5,80002c34 <devintr+0x80>
  }
}
    80002bd2:	60e2                	ld	ra,24(sp)
    80002bd4:	6442                	ld	s0,16(sp)
    80002bd6:	64a2                	ld	s1,8(sp)
    80002bd8:	6105                	addi	sp,sp,32
    80002bda:	8082                	ret
     (scause & 0xff) == 9){
    80002bdc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002be0:	46a5                	li	a3,9
    80002be2:	fed792e3          	bne	a5,a3,80002bc6 <devintr+0x12>
    int irq = plic_claim();
    80002be6:	00003097          	auipc	ra,0x3
    80002bea:	4b2080e7          	jalr	1202(ra) # 80006098 <plic_claim>
    80002bee:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002bf0:	47a9                	li	a5,10
    80002bf2:	02f50763          	beq	a0,a5,80002c20 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002bf6:	4785                	li	a5,1
    80002bf8:	02f50963          	beq	a0,a5,80002c2a <devintr+0x76>
    return 1;
    80002bfc:	4505                	li	a0,1
    } else if(irq){
    80002bfe:	d8f1                	beqz	s1,80002bd2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c00:	85a6                	mv	a1,s1
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	84e50513          	addi	a0,a0,-1970 # 80008450 <states.1725+0x120>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	97e080e7          	jalr	-1666(ra) # 80000588 <printf>
      plic_complete(irq);
    80002c12:	8526                	mv	a0,s1
    80002c14:	00003097          	auipc	ra,0x3
    80002c18:	4a8080e7          	jalr	1192(ra) # 800060bc <plic_complete>
    return 1;
    80002c1c:	4505                	li	a0,1
    80002c1e:	bf55                	j	80002bd2 <devintr+0x1e>
      uartintr();
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	d88080e7          	jalr	-632(ra) # 800009a8 <uartintr>
    80002c28:	b7ed                	j	80002c12 <devintr+0x5e>
      virtio_disk_intr();
    80002c2a:	00004097          	auipc	ra,0x4
    80002c2e:	972080e7          	jalr	-1678(ra) # 8000659c <virtio_disk_intr>
    80002c32:	b7c5                	j	80002c12 <devintr+0x5e>
    if(cpuid() == 0){
    80002c34:	fffff097          	auipc	ra,0xfffff
    80002c38:	d7e080e7          	jalr	-642(ra) # 800019b2 <cpuid>
    80002c3c:	c901                	beqz	a0,80002c4c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c3e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c42:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c44:	14479073          	csrw	sip,a5
    return 2;
    80002c48:	4509                	li	a0,2
    80002c4a:	b761                	j	80002bd2 <devintr+0x1e>
      clockintr();
    80002c4c:	00000097          	auipc	ra,0x0
    80002c50:	f22080e7          	jalr	-222(ra) # 80002b6e <clockintr>
    80002c54:	b7ed                	j	80002c3e <devintr+0x8a>

0000000080002c56 <usertrap>:
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	e04a                	sd	s2,0(sp)
    80002c60:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c62:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002c66:	1007f793          	andi	a5,a5,256
    80002c6a:	e3ad                	bnez	a5,80002ccc <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c6c:	00003797          	auipc	a5,0x3
    80002c70:	32478793          	addi	a5,a5,804 # 80005f90 <kernelvec>
    80002c74:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002c78:	fffff097          	auipc	ra,0xfffff
    80002c7c:	d66080e7          	jalr	-666(ra) # 800019de <myproc>
    80002c80:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002c82:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c84:	14102773          	csrr	a4,sepc
    80002c88:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c8a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002c8e:	47a1                	li	a5,8
    80002c90:	04f71c63          	bne	a4,a5,80002ce8 <usertrap+0x92>
    if(p->killed)
    80002c94:	551c                	lw	a5,40(a0)
    80002c96:	e3b9                	bnez	a5,80002cdc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002c98:	70b8                	ld	a4,96(s1)
    80002c9a:	6f1c                	ld	a5,24(a4)
    80002c9c:	0791                	addi	a5,a5,4
    80002c9e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ca4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca8:	10079073          	csrw	sstatus,a5
    syscall();
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	2e0080e7          	jalr	736(ra) # 80002f8c <syscall>
  if(p->killed)
    80002cb4:	549c                	lw	a5,40(s1)
    80002cb6:	ebc1                	bnez	a5,80002d46 <usertrap+0xf0>
  usertrapret();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	cf0080e7          	jalr	-784(ra) # 800029a8 <usertrapret>
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6902                	ld	s2,0(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret
    panic("usertrap: not from user mode");
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	7a450513          	addi	a0,a0,1956 # 80008470 <states.1725+0x140>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	86a080e7          	jalr	-1942(ra) # 8000053e <panic>
      exit(-1);
    80002cdc:	557d                	li	a0,-1
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	6cc080e7          	jalr	1740(ra) # 800023aa <exit>
    80002ce6:	bf4d                	j	80002c98 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	ecc080e7          	jalr	-308(ra) # 80002bb4 <devintr>
    80002cf0:	892a                	mv	s2,a0
    80002cf2:	c501                	beqz	a0,80002cfa <usertrap+0xa4>
  if(p->killed)
    80002cf4:	549c                	lw	a5,40(s1)
    80002cf6:	c3a1                	beqz	a5,80002d36 <usertrap+0xe0>
    80002cf8:	a815                	j	80002d2c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cfa:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002cfe:	5890                	lw	a2,48(s1)
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	79050513          	addi	a0,a0,1936 # 80008490 <states.1725+0x160>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	880080e7          	jalr	-1920(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d14:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	7a850513          	addi	a0,a0,1960 # 800084c0 <states.1725+0x190>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	868080e7          	jalr	-1944(ra) # 80000588 <printf>
    p->killed = 1;
    80002d28:	4785                	li	a5,1
    80002d2a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002d2c:	557d                	li	a0,-1
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	67c080e7          	jalr	1660(ra) # 800023aa <exit>
  if(which_dev == 2)
    80002d36:	4789                	li	a5,2
    80002d38:	f8f910e3          	bne	s2,a5,80002cb8 <usertrap+0x62>
    yield();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	370080e7          	jalr	880(ra) # 800020ac <yield>
    80002d44:	bf95                	j	80002cb8 <usertrap+0x62>
  int which_dev = 0;
    80002d46:	4901                	li	s2,0
    80002d48:	b7d5                	j	80002d2c <usertrap+0xd6>

0000000080002d4a <kerneltrap>:
{
    80002d4a:	7179                	addi	sp,sp,-48
    80002d4c:	f406                	sd	ra,40(sp)
    80002d4e:	f022                	sd	s0,32(sp)
    80002d50:	ec26                	sd	s1,24(sp)
    80002d52:	e84a                	sd	s2,16(sp)
    80002d54:	e44e                	sd	s3,8(sp)
    80002d56:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d58:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d5c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d60:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d64:	1004f793          	andi	a5,s1,256
    80002d68:	cb85                	beqz	a5,80002d98 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d6e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d70:	ef85                	bnez	a5,80002da8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	e42080e7          	jalr	-446(ra) # 80002bb4 <devintr>
    80002d7a:	cd1d                	beqz	a0,80002db8 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d7c:	4789                	li	a5,2
    80002d7e:	06f50a63          	beq	a0,a5,80002df2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d82:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d86:	10049073          	csrw	sstatus,s1
}
    80002d8a:	70a2                	ld	ra,40(sp)
    80002d8c:	7402                	ld	s0,32(sp)
    80002d8e:	64e2                	ld	s1,24(sp)
    80002d90:	6942                	ld	s2,16(sp)
    80002d92:	69a2                	ld	s3,8(sp)
    80002d94:	6145                	addi	sp,sp,48
    80002d96:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d98:	00005517          	auipc	a0,0x5
    80002d9c:	74850513          	addi	a0,a0,1864 # 800084e0 <states.1725+0x1b0>
    80002da0:	ffffd097          	auipc	ra,0xffffd
    80002da4:	79e080e7          	jalr	1950(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002da8:	00005517          	auipc	a0,0x5
    80002dac:	76050513          	addi	a0,a0,1888 # 80008508 <states.1725+0x1d8>
    80002db0:	ffffd097          	auipc	ra,0xffffd
    80002db4:	78e080e7          	jalr	1934(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002db8:	85ce                	mv	a1,s3
    80002dba:	00005517          	auipc	a0,0x5
    80002dbe:	76e50513          	addi	a0,a0,1902 # 80008528 <states.1725+0x1f8>
    80002dc2:	ffffd097          	auipc	ra,0xffffd
    80002dc6:	7c6080e7          	jalr	1990(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dca:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dce:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd2:	00005517          	auipc	a0,0x5
    80002dd6:	76650513          	addi	a0,a0,1894 # 80008538 <states.1725+0x208>
    80002dda:	ffffd097          	auipc	ra,0xffffd
    80002dde:	7ae080e7          	jalr	1966(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002de2:	00005517          	auipc	a0,0x5
    80002de6:	76e50513          	addi	a0,a0,1902 # 80008550 <states.1725+0x220>
    80002dea:	ffffd097          	auipc	ra,0xffffd
    80002dee:	754080e7          	jalr	1876(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	bec080e7          	jalr	-1044(ra) # 800019de <myproc>
    80002dfa:	d541                	beqz	a0,80002d82 <kerneltrap+0x38>
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	be2080e7          	jalr	-1054(ra) # 800019de <myproc>
    80002e04:	4d18                	lw	a4,24(a0)
    80002e06:	4791                	li	a5,4
    80002e08:	f6f71de3          	bne	a4,a5,80002d82 <kerneltrap+0x38>
    yield();
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	2a0080e7          	jalr	672(ra) # 800020ac <yield>
    80002e14:	b7bd                	j	80002d82 <kerneltrap+0x38>

0000000080002e16 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	1000                	addi	s0,sp,32
    80002e20:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	bbc080e7          	jalr	-1092(ra) # 800019de <myproc>
  switch (n) {
    80002e2a:	4795                	li	a5,5
    80002e2c:	0497e163          	bltu	a5,s1,80002e6e <argraw+0x58>
    80002e30:	048a                	slli	s1,s1,0x2
    80002e32:	00005717          	auipc	a4,0x5
    80002e36:	75670713          	addi	a4,a4,1878 # 80008588 <states.1725+0x258>
    80002e3a:	94ba                	add	s1,s1,a4
    80002e3c:	409c                	lw	a5,0(s1)
    80002e3e:	97ba                	add	a5,a5,a4
    80002e40:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002e42:	713c                	ld	a5,96(a0)
    80002e44:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	64a2                	ld	s1,8(sp)
    80002e4c:	6105                	addi	sp,sp,32
    80002e4e:	8082                	ret
    return p->trapframe->a1;
    80002e50:	713c                	ld	a5,96(a0)
    80002e52:	7fa8                	ld	a0,120(a5)
    80002e54:	bfcd                	j	80002e46 <argraw+0x30>
    return p->trapframe->a2;
    80002e56:	713c                	ld	a5,96(a0)
    80002e58:	63c8                	ld	a0,128(a5)
    80002e5a:	b7f5                	j	80002e46 <argraw+0x30>
    return p->trapframe->a3;
    80002e5c:	713c                	ld	a5,96(a0)
    80002e5e:	67c8                	ld	a0,136(a5)
    80002e60:	b7dd                	j	80002e46 <argraw+0x30>
    return p->trapframe->a4;
    80002e62:	713c                	ld	a5,96(a0)
    80002e64:	6bc8                	ld	a0,144(a5)
    80002e66:	b7c5                	j	80002e46 <argraw+0x30>
    return p->trapframe->a5;
    80002e68:	713c                	ld	a5,96(a0)
    80002e6a:	6fc8                	ld	a0,152(a5)
    80002e6c:	bfe9                	j	80002e46 <argraw+0x30>
  panic("argraw");
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	6f250513          	addi	a0,a0,1778 # 80008560 <states.1725+0x230>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	6c8080e7          	jalr	1736(ra) # 8000053e <panic>

0000000080002e7e <fetchaddr>:
{
    80002e7e:	1101                	addi	sp,sp,-32
    80002e80:	ec06                	sd	ra,24(sp)
    80002e82:	e822                	sd	s0,16(sp)
    80002e84:	e426                	sd	s1,8(sp)
    80002e86:	e04a                	sd	s2,0(sp)
    80002e88:	1000                	addi	s0,sp,32
    80002e8a:	84aa                	mv	s1,a0
    80002e8c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	b50080e7          	jalr	-1200(ra) # 800019de <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002e96:	693c                	ld	a5,80(a0)
    80002e98:	02f4f863          	bgeu	s1,a5,80002ec8 <fetchaddr+0x4a>
    80002e9c:	00848713          	addi	a4,s1,8
    80002ea0:	02e7e663          	bltu	a5,a4,80002ecc <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ea4:	46a1                	li	a3,8
    80002ea6:	8626                	mv	a2,s1
    80002ea8:	85ca                	mv	a1,s2
    80002eaa:	6d28                	ld	a0,88(a0)
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	852080e7          	jalr	-1966(ra) # 800016fe <copyin>
    80002eb4:	00a03533          	snez	a0,a0
    80002eb8:	40a00533          	neg	a0,a0
}
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	64a2                	ld	s1,8(sp)
    80002ec2:	6902                	ld	s2,0(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret
    return -1;
    80002ec8:	557d                	li	a0,-1
    80002eca:	bfcd                	j	80002ebc <fetchaddr+0x3e>
    80002ecc:	557d                	li	a0,-1
    80002ece:	b7fd                	j	80002ebc <fetchaddr+0x3e>

0000000080002ed0 <fetchstr>:
{
    80002ed0:	7179                	addi	sp,sp,-48
    80002ed2:	f406                	sd	ra,40(sp)
    80002ed4:	f022                	sd	s0,32(sp)
    80002ed6:	ec26                	sd	s1,24(sp)
    80002ed8:	e84a                	sd	s2,16(sp)
    80002eda:	e44e                	sd	s3,8(sp)
    80002edc:	1800                	addi	s0,sp,48
    80002ede:	892a                	mv	s2,a0
    80002ee0:	84ae                	mv	s1,a1
    80002ee2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	afa080e7          	jalr	-1286(ra) # 800019de <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002eec:	86ce                	mv	a3,s3
    80002eee:	864a                	mv	a2,s2
    80002ef0:	85a6                	mv	a1,s1
    80002ef2:	6d28                	ld	a0,88(a0)
    80002ef4:	fffff097          	auipc	ra,0xfffff
    80002ef8:	896080e7          	jalr	-1898(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002efc:	00054763          	bltz	a0,80002f0a <fetchstr+0x3a>
  return strlen(buf);
    80002f00:	8526                	mv	a0,s1
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	f62080e7          	jalr	-158(ra) # 80000e64 <strlen>
}
    80002f0a:	70a2                	ld	ra,40(sp)
    80002f0c:	7402                	ld	s0,32(sp)
    80002f0e:	64e2                	ld	s1,24(sp)
    80002f10:	6942                	ld	s2,16(sp)
    80002f12:	69a2                	ld	s3,8(sp)
    80002f14:	6145                	addi	sp,sp,48
    80002f16:	8082                	ret

0000000080002f18 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002f18:	1101                	addi	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	e426                	sd	s1,8(sp)
    80002f20:	1000                	addi	s0,sp,32
    80002f22:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	ef2080e7          	jalr	-270(ra) # 80002e16 <argraw>
    80002f2c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002f2e:	4501                	li	a0,0
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	64a2                	ld	s1,8(sp)
    80002f36:	6105                	addi	sp,sp,32
    80002f38:	8082                	ret

0000000080002f3a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002f3a:	1101                	addi	sp,sp,-32
    80002f3c:	ec06                	sd	ra,24(sp)
    80002f3e:	e822                	sd	s0,16(sp)
    80002f40:	e426                	sd	s1,8(sp)
    80002f42:	1000                	addi	s0,sp,32
    80002f44:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	ed0080e7          	jalr	-304(ra) # 80002e16 <argraw>
    80002f4e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002f50:	4501                	li	a0,0
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	64a2                	ld	s1,8(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	e426                	sd	s1,8(sp)
    80002f64:	e04a                	sd	s2,0(sp)
    80002f66:	1000                	addi	s0,sp,32
    80002f68:	84ae                	mv	s1,a1
    80002f6a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002f6c:	00000097          	auipc	ra,0x0
    80002f70:	eaa080e7          	jalr	-342(ra) # 80002e16 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002f74:	864a                	mv	a2,s2
    80002f76:	85a6                	mv	a1,s1
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	f58080e7          	jalr	-168(ra) # 80002ed0 <fetchstr>
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	64a2                	ld	s1,8(sp)
    80002f86:	6902                	ld	s2,0(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret

0000000080002f8c <syscall>:
[SYS_clone]   sys_clone,
};

void
syscall(void)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	e426                	sd	s1,8(sp)
    80002f94:	e04a                	sd	s2,0(sp)
    80002f96:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002f98:	fffff097          	auipc	ra,0xfffff
    80002f9c:	a46080e7          	jalr	-1466(ra) # 800019de <myproc>
    80002fa0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002fa2:	06053903          	ld	s2,96(a0)
    80002fa6:	0a893783          	ld	a5,168(s2) # 40000a8 <_entry-0x7bffff58>
    80002faa:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002fae:	37fd                	addiw	a5,a5,-1
    80002fb0:	4755                	li	a4,21
    80002fb2:	00f76f63          	bltu	a4,a5,80002fd0 <syscall+0x44>
    80002fb6:	00369713          	slli	a4,a3,0x3
    80002fba:	00005797          	auipc	a5,0x5
    80002fbe:	5e678793          	addi	a5,a5,1510 # 800085a0 <syscalls>
    80002fc2:	97ba                	add	a5,a5,a4
    80002fc4:	639c                	ld	a5,0(a5)
    80002fc6:	c789                	beqz	a5,80002fd0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002fc8:	9782                	jalr	a5
    80002fca:	06a93823          	sd	a0,112(s2)
    80002fce:	a839                	j	80002fec <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002fd0:	16048613          	addi	a2,s1,352
    80002fd4:	588c                	lw	a1,48(s1)
    80002fd6:	00005517          	auipc	a0,0x5
    80002fda:	59250513          	addi	a0,a0,1426 # 80008568 <states.1725+0x238>
    80002fde:	ffffd097          	auipc	ra,0xffffd
    80002fe2:	5aa080e7          	jalr	1450(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002fe6:	70bc                	ld	a5,96(s1)
    80002fe8:	577d                	li	a4,-1
    80002fea:	fbb8                	sd	a4,112(a5)
  }
}
    80002fec:	60e2                	ld	ra,24(sp)
    80002fee:	6442                	ld	s0,16(sp)
    80002ff0:	64a2                	ld	s1,8(sp)
    80002ff2:	6902                	ld	s2,0(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret

0000000080002ff8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003000:	fec40593          	addi	a1,s0,-20
    80003004:	4501                	li	a0,0
    80003006:	00000097          	auipc	ra,0x0
    8000300a:	f12080e7          	jalr	-238(ra) # 80002f18 <argint>
    return -1;
    8000300e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003010:	00054963          	bltz	a0,80003022 <sys_exit+0x2a>
  exit(n);
    80003014:	fec42503          	lw	a0,-20(s0)
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	392080e7          	jalr	914(ra) # 800023aa <exit>
  return 0;  // not reached
    80003020:	4781                	li	a5,0
}
    80003022:	853e                	mv	a0,a5
    80003024:	60e2                	ld	ra,24(sp)
    80003026:	6442                	ld	s0,16(sp)
    80003028:	6105                	addi	sp,sp,32
    8000302a:	8082                	ret

000000008000302c <sys_getpid>:

uint64
sys_getpid(void)
{
    8000302c:	1141                	addi	sp,sp,-16
    8000302e:	e406                	sd	ra,8(sp)
    80003030:	e022                	sd	s0,0(sp)
    80003032:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	9aa080e7          	jalr	-1622(ra) # 800019de <myproc>
}
    8000303c:	5908                	lw	a0,48(a0)
    8000303e:	60a2                	ld	ra,8(sp)
    80003040:	6402                	ld	s0,0(sp)
    80003042:	0141                	addi	sp,sp,16
    80003044:	8082                	ret

0000000080003046 <sys_fork>:

uint64
sys_fork(void)
{
    80003046:	1141                	addi	sp,sp,-16
    80003048:	e406                	sd	ra,8(sp)
    8000304a:	e022                	sd	s0,0(sp)
    8000304c:	0800                	addi	s0,sp,16
  return fork();
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	dac080e7          	jalr	-596(ra) # 80001dfa <fork>
}
    80003056:	60a2                	ld	ra,8(sp)
    80003058:	6402                	ld	s0,0(sp)
    8000305a:	0141                	addi	sp,sp,16
    8000305c:	8082                	ret

000000008000305e <sys_wait>:

uint64
sys_wait(void)
{
    8000305e:	1101                	addi	sp,sp,-32
    80003060:	ec06                	sd	ra,24(sp)
    80003062:	e822                	sd	s0,16(sp)
    80003064:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003066:	fe840593          	addi	a1,s0,-24
    8000306a:	4501                	li	a0,0
    8000306c:	00000097          	auipc	ra,0x0
    80003070:	ece080e7          	jalr	-306(ra) # 80002f3a <argaddr>
    80003074:	87aa                	mv	a5,a0
    return -1;
    80003076:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003078:	0007c863          	bltz	a5,80003088 <sys_wait+0x2a>
  return wait(p);
    8000307c:	fe843503          	ld	a0,-24(s0)
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	132080e7          	jalr	306(ra) # 800021b2 <wait>
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003090:	7179                	addi	sp,sp,-48
    80003092:	f406                	sd	ra,40(sp)
    80003094:	f022                	sd	s0,32(sp)
    80003096:	ec26                	sd	s1,24(sp)
    80003098:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000309a:	fdc40593          	addi	a1,s0,-36
    8000309e:	4501                	li	a0,0
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	e78080e7          	jalr	-392(ra) # 80002f18 <argint>
    800030a8:	87aa                	mv	a5,a0
    return -1;
    800030aa:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800030ac:	0207c063          	bltz	a5,800030cc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800030b0:	fffff097          	auipc	ra,0xfffff
    800030b4:	92e080e7          	jalr	-1746(ra) # 800019de <myproc>
    800030b8:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    800030ba:	fdc42503          	lw	a0,-36(s0)
    800030be:	fffff097          	auipc	ra,0xfffff
    800030c2:	cc8080e7          	jalr	-824(ra) # 80001d86 <growproc>
    800030c6:	00054863          	bltz	a0,800030d6 <sys_sbrk+0x46>
    return -1;
  return addr;
    800030ca:	8526                	mv	a0,s1
}
    800030cc:	70a2                	ld	ra,40(sp)
    800030ce:	7402                	ld	s0,32(sp)
    800030d0:	64e2                	ld	s1,24(sp)
    800030d2:	6145                	addi	sp,sp,48
    800030d4:	8082                	ret
    return -1;
    800030d6:	557d                	li	a0,-1
    800030d8:	bfd5                	j	800030cc <sys_sbrk+0x3c>

00000000800030da <sys_sleep>:

uint64
sys_sleep(void)
{
    800030da:	7139                	addi	sp,sp,-64
    800030dc:	fc06                	sd	ra,56(sp)
    800030de:	f822                	sd	s0,48(sp)
    800030e0:	f426                	sd	s1,40(sp)
    800030e2:	f04a                	sd	s2,32(sp)
    800030e4:	ec4e                	sd	s3,24(sp)
    800030e6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800030e8:	fcc40593          	addi	a1,s0,-52
    800030ec:	4501                	li	a0,0
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	e2a080e7          	jalr	-470(ra) # 80002f18 <argint>
    return -1;
    800030f6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800030f8:	06054563          	bltz	a0,80003162 <sys_sleep+0x88>
  acquire(&tickslock);
    800030fc:	00014517          	auipc	a0,0x14
    80003100:	1d450513          	addi	a0,a0,468 # 800172d0 <tickslock>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	ae0080e7          	jalr	-1312(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    8000310c:	00006917          	auipc	s2,0x6
    80003110:	f2c92903          	lw	s2,-212(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80003114:	fcc42783          	lw	a5,-52(s0)
    80003118:	cf85                	beqz	a5,80003150 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000311a:	00014997          	auipc	s3,0x14
    8000311e:	1b698993          	addi	s3,s3,438 # 800172d0 <tickslock>
    80003122:	00006497          	auipc	s1,0x6
    80003126:	f1648493          	addi	s1,s1,-234 # 80009038 <ticks>
    if(myproc()->killed){
    8000312a:	fffff097          	auipc	ra,0xfffff
    8000312e:	8b4080e7          	jalr	-1868(ra) # 800019de <myproc>
    80003132:	551c                	lw	a5,40(a0)
    80003134:	ef9d                	bnez	a5,80003172 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003136:	85ce                	mv	a1,s3
    80003138:	8526                	mv	a0,s1
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	014080e7          	jalr	20(ra) # 8000214e <sleep>
  while(ticks - ticks0 < n){
    80003142:	409c                	lw	a5,0(s1)
    80003144:	412787bb          	subw	a5,a5,s2
    80003148:	fcc42703          	lw	a4,-52(s0)
    8000314c:	fce7efe3          	bltu	a5,a4,8000312a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003150:	00014517          	auipc	a0,0x14
    80003154:	18050513          	addi	a0,a0,384 # 800172d0 <tickslock>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b40080e7          	jalr	-1216(ra) # 80000c98 <release>
  return 0;
    80003160:	4781                	li	a5,0
}
    80003162:	853e                	mv	a0,a5
    80003164:	70e2                	ld	ra,56(sp)
    80003166:	7442                	ld	s0,48(sp)
    80003168:	74a2                	ld	s1,40(sp)
    8000316a:	7902                	ld	s2,32(sp)
    8000316c:	69e2                	ld	s3,24(sp)
    8000316e:	6121                	addi	sp,sp,64
    80003170:	8082                	ret
      release(&tickslock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	15e50513          	addi	a0,a0,350 # 800172d0 <tickslock>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	b1e080e7          	jalr	-1250(ra) # 80000c98 <release>
      return -1;
    80003182:	57fd                	li	a5,-1
    80003184:	bff9                	j	80003162 <sys_sleep+0x88>

0000000080003186 <sys_kill>:

uint64
sys_kill(void)
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000318e:	fec40593          	addi	a1,s0,-20
    80003192:	4501                	li	a0,0
    80003194:	00000097          	auipc	ra,0x0
    80003198:	d84080e7          	jalr	-636(ra) # 80002f18 <argint>
    8000319c:	87aa                	mv	a5,a0
    return -1;
    8000319e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800031a0:	0007c863          	bltz	a5,800031b0 <sys_kill+0x2a>
  return kill(pid);
    800031a4:	fec42503          	lw	a0,-20(s0)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	2d8080e7          	jalr	728(ra) # 80002480 <kill>
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <sys_clone>:

uint64
sys_clone(void)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	1000                	addi	s0,sp,32
	uint64 st;
	int sz;
	if (argaddr(0,&st) <0)
    800031c0:	fe840593          	addi	a1,s0,-24
    800031c4:	4501                	li	a0,0
    800031c6:	00000097          	auipc	ra,0x0
    800031ca:	d74080e7          	jalr	-652(ra) # 80002f3a <argaddr>
		return -1;
    800031ce:	57fd                	li	a5,-1
	if (argaddr(0,&st) <0)
    800031d0:	02054563          	bltz	a0,800031fa <sys_clone+0x42>
	if(argint(1,&sz)<0)
    800031d4:	fe440593          	addi	a1,s0,-28
    800031d8:	4505                	li	a0,1
    800031da:	00000097          	auipc	ra,0x0
    800031de:	d3e080e7          	jalr	-706(ra) # 80002f18 <argint>
		return -1;
    800031e2:	57fd                	li	a5,-1
	if(argint(1,&sz)<0)
    800031e4:	00054b63          	bltz	a0,800031fa <sys_clone+0x42>

	return clone((void *)st, sz);
    800031e8:	fe442583          	lw	a1,-28(s0)
    800031ec:	fe843503          	ld	a0,-24(s0)
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	45c080e7          	jalr	1116(ra) # 8000264c <clone>
    800031f8:	87aa                	mv	a5,a0
}
    800031fa:	853e                	mv	a0,a5
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret

0000000080003204 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003204:	1101                	addi	sp,sp,-32
    80003206:	ec06                	sd	ra,24(sp)
    80003208:	e822                	sd	s0,16(sp)
    8000320a:	e426                	sd	s1,8(sp)
    8000320c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000320e:	00014517          	auipc	a0,0x14
    80003212:	0c250513          	addi	a0,a0,194 # 800172d0 <tickslock>
    80003216:	ffffe097          	auipc	ra,0xffffe
    8000321a:	9ce080e7          	jalr	-1586(ra) # 80000be4 <acquire>
  xticks = ticks;
    8000321e:	00006497          	auipc	s1,0x6
    80003222:	e1a4a483          	lw	s1,-486(s1) # 80009038 <ticks>
  release(&tickslock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	0aa50513          	addi	a0,a0,170 # 800172d0 <tickslock>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	a6a080e7          	jalr	-1430(ra) # 80000c98 <release>
  return xticks;
}
    80003236:	02049513          	slli	a0,s1,0x20
    8000323a:	9101                	srli	a0,a0,0x20
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret

0000000080003246 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003246:	7179                	addi	sp,sp,-48
    80003248:	f406                	sd	ra,40(sp)
    8000324a:	f022                	sd	s0,32(sp)
    8000324c:	ec26                	sd	s1,24(sp)
    8000324e:	e84a                	sd	s2,16(sp)
    80003250:	e44e                	sd	s3,8(sp)
    80003252:	e052                	sd	s4,0(sp)
    80003254:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003256:	00005597          	auipc	a1,0x5
    8000325a:	40258593          	addi	a1,a1,1026 # 80008658 <syscalls+0xb8>
    8000325e:	00014517          	auipc	a0,0x14
    80003262:	08a50513          	addi	a0,a0,138 # 800172e8 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	8ee080e7          	jalr	-1810(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000326e:	0001c797          	auipc	a5,0x1c
    80003272:	07a78793          	addi	a5,a5,122 # 8001f2e8 <bcache+0x8000>
    80003276:	0001c717          	auipc	a4,0x1c
    8000327a:	2da70713          	addi	a4,a4,730 # 8001f550 <bcache+0x8268>
    8000327e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003282:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003286:	00014497          	auipc	s1,0x14
    8000328a:	07a48493          	addi	s1,s1,122 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    8000328e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003290:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003292:	00005a17          	auipc	s4,0x5
    80003296:	3cea0a13          	addi	s4,s4,974 # 80008660 <syscalls+0xc0>
    b->next = bcache.head.next;
    8000329a:	2b893783          	ld	a5,696(s2)
    8000329e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032a0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032a4:	85d2                	mv	a1,s4
    800032a6:	01048513          	addi	a0,s1,16
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	4bc080e7          	jalr	1212(ra) # 80004766 <initsleeplock>
    bcache.head.next->prev = b;
    800032b2:	2b893783          	ld	a5,696(s2)
    800032b6:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032b8:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032bc:	45848493          	addi	s1,s1,1112
    800032c0:	fd349de3          	bne	s1,s3,8000329a <binit+0x54>
  }
}
    800032c4:	70a2                	ld	ra,40(sp)
    800032c6:	7402                	ld	s0,32(sp)
    800032c8:	64e2                	ld	s1,24(sp)
    800032ca:	6942                	ld	s2,16(sp)
    800032cc:	69a2                	ld	s3,8(sp)
    800032ce:	6a02                	ld	s4,0(sp)
    800032d0:	6145                	addi	sp,sp,48
    800032d2:	8082                	ret

00000000800032d4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032d4:	7179                	addi	sp,sp,-48
    800032d6:	f406                	sd	ra,40(sp)
    800032d8:	f022                	sd	s0,32(sp)
    800032da:	ec26                	sd	s1,24(sp)
    800032dc:	e84a                	sd	s2,16(sp)
    800032de:	e44e                	sd	s3,8(sp)
    800032e0:	1800                	addi	s0,sp,48
    800032e2:	89aa                	mv	s3,a0
    800032e4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800032e6:	00014517          	auipc	a0,0x14
    800032ea:	00250513          	addi	a0,a0,2 # 800172e8 <bcache>
    800032ee:	ffffe097          	auipc	ra,0xffffe
    800032f2:	8f6080e7          	jalr	-1802(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032f6:	0001c497          	auipc	s1,0x1c
    800032fa:	2aa4b483          	ld	s1,682(s1) # 8001f5a0 <bcache+0x82b8>
    800032fe:	0001c797          	auipc	a5,0x1c
    80003302:	25278793          	addi	a5,a5,594 # 8001f550 <bcache+0x8268>
    80003306:	02f48f63          	beq	s1,a5,80003344 <bread+0x70>
    8000330a:	873e                	mv	a4,a5
    8000330c:	a021                	j	80003314 <bread+0x40>
    8000330e:	68a4                	ld	s1,80(s1)
    80003310:	02e48a63          	beq	s1,a4,80003344 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003314:	449c                	lw	a5,8(s1)
    80003316:	ff379ce3          	bne	a5,s3,8000330e <bread+0x3a>
    8000331a:	44dc                	lw	a5,12(s1)
    8000331c:	ff2799e3          	bne	a5,s2,8000330e <bread+0x3a>
      b->refcnt++;
    80003320:	40bc                	lw	a5,64(s1)
    80003322:	2785                	addiw	a5,a5,1
    80003324:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003326:	00014517          	auipc	a0,0x14
    8000332a:	fc250513          	addi	a0,a0,-62 # 800172e8 <bcache>
    8000332e:	ffffe097          	auipc	ra,0xffffe
    80003332:	96a080e7          	jalr	-1686(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003336:	01048513          	addi	a0,s1,16
    8000333a:	00001097          	auipc	ra,0x1
    8000333e:	466080e7          	jalr	1126(ra) # 800047a0 <acquiresleep>
      return b;
    80003342:	a8b9                	j	800033a0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003344:	0001c497          	auipc	s1,0x1c
    80003348:	2544b483          	ld	s1,596(s1) # 8001f598 <bcache+0x82b0>
    8000334c:	0001c797          	auipc	a5,0x1c
    80003350:	20478793          	addi	a5,a5,516 # 8001f550 <bcache+0x8268>
    80003354:	00f48863          	beq	s1,a5,80003364 <bread+0x90>
    80003358:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000335a:	40bc                	lw	a5,64(s1)
    8000335c:	cf81                	beqz	a5,80003374 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000335e:	64a4                	ld	s1,72(s1)
    80003360:	fee49de3          	bne	s1,a4,8000335a <bread+0x86>
  panic("bget: no buffers");
    80003364:	00005517          	auipc	a0,0x5
    80003368:	30450513          	addi	a0,a0,772 # 80008668 <syscalls+0xc8>
    8000336c:	ffffd097          	auipc	ra,0xffffd
    80003370:	1d2080e7          	jalr	466(ra) # 8000053e <panic>
      b->dev = dev;
    80003374:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003378:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000337c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003380:	4785                	li	a5,1
    80003382:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003384:	00014517          	auipc	a0,0x14
    80003388:	f6450513          	addi	a0,a0,-156 # 800172e8 <bcache>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	90c080e7          	jalr	-1780(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003394:	01048513          	addi	a0,s1,16
    80003398:	00001097          	auipc	ra,0x1
    8000339c:	408080e7          	jalr	1032(ra) # 800047a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033a0:	409c                	lw	a5,0(s1)
    800033a2:	cb89                	beqz	a5,800033b4 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033a4:	8526                	mv	a0,s1
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	64e2                	ld	s1,24(sp)
    800033ac:	6942                	ld	s2,16(sp)
    800033ae:	69a2                	ld	s3,8(sp)
    800033b0:	6145                	addi	sp,sp,48
    800033b2:	8082                	ret
    virtio_disk_rw(b, 0);
    800033b4:	4581                	li	a1,0
    800033b6:	8526                	mv	a0,s1
    800033b8:	00003097          	auipc	ra,0x3
    800033bc:	f0e080e7          	jalr	-242(ra) # 800062c6 <virtio_disk_rw>
    b->valid = 1;
    800033c0:	4785                	li	a5,1
    800033c2:	c09c                	sw	a5,0(s1)
  return b;
    800033c4:	b7c5                	j	800033a4 <bread+0xd0>

00000000800033c6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033c6:	1101                	addi	sp,sp,-32
    800033c8:	ec06                	sd	ra,24(sp)
    800033ca:	e822                	sd	s0,16(sp)
    800033cc:	e426                	sd	s1,8(sp)
    800033ce:	1000                	addi	s0,sp,32
    800033d0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033d2:	0541                	addi	a0,a0,16
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	466080e7          	jalr	1126(ra) # 8000483a <holdingsleep>
    800033dc:	cd01                	beqz	a0,800033f4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033de:	4585                	li	a1,1
    800033e0:	8526                	mv	a0,s1
    800033e2:	00003097          	auipc	ra,0x3
    800033e6:	ee4080e7          	jalr	-284(ra) # 800062c6 <virtio_disk_rw>
}
    800033ea:	60e2                	ld	ra,24(sp)
    800033ec:	6442                	ld	s0,16(sp)
    800033ee:	64a2                	ld	s1,8(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret
    panic("bwrite");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	28c50513          	addi	a0,a0,652 # 80008680 <syscalls+0xe0>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	142080e7          	jalr	322(ra) # 8000053e <panic>

0000000080003404 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003404:	1101                	addi	sp,sp,-32
    80003406:	ec06                	sd	ra,24(sp)
    80003408:	e822                	sd	s0,16(sp)
    8000340a:	e426                	sd	s1,8(sp)
    8000340c:	e04a                	sd	s2,0(sp)
    8000340e:	1000                	addi	s0,sp,32
    80003410:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003412:	01050913          	addi	s2,a0,16
    80003416:	854a                	mv	a0,s2
    80003418:	00001097          	auipc	ra,0x1
    8000341c:	422080e7          	jalr	1058(ra) # 8000483a <holdingsleep>
    80003420:	c92d                	beqz	a0,80003492 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003422:	854a                	mv	a0,s2
    80003424:	00001097          	auipc	ra,0x1
    80003428:	3d2080e7          	jalr	978(ra) # 800047f6 <releasesleep>

  acquire(&bcache.lock);
    8000342c:	00014517          	auipc	a0,0x14
    80003430:	ebc50513          	addi	a0,a0,-324 # 800172e8 <bcache>
    80003434:	ffffd097          	auipc	ra,0xffffd
    80003438:	7b0080e7          	jalr	1968(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000343c:	40bc                	lw	a5,64(s1)
    8000343e:	37fd                	addiw	a5,a5,-1
    80003440:	0007871b          	sext.w	a4,a5
    80003444:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003446:	eb05                	bnez	a4,80003476 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003448:	68bc                	ld	a5,80(s1)
    8000344a:	64b8                	ld	a4,72(s1)
    8000344c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000344e:	64bc                	ld	a5,72(s1)
    80003450:	68b8                	ld	a4,80(s1)
    80003452:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003454:	0001c797          	auipc	a5,0x1c
    80003458:	e9478793          	addi	a5,a5,-364 # 8001f2e8 <bcache+0x8000>
    8000345c:	2b87b703          	ld	a4,696(a5)
    80003460:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003462:	0001c717          	auipc	a4,0x1c
    80003466:	0ee70713          	addi	a4,a4,238 # 8001f550 <bcache+0x8268>
    8000346a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000346c:	2b87b703          	ld	a4,696(a5)
    80003470:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003472:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003476:	00014517          	auipc	a0,0x14
    8000347a:	e7250513          	addi	a0,a0,-398 # 800172e8 <bcache>
    8000347e:	ffffe097          	auipc	ra,0xffffe
    80003482:	81a080e7          	jalr	-2022(ra) # 80000c98 <release>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6902                	ld	s2,0(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret
    panic("brelse");
    80003492:	00005517          	auipc	a0,0x5
    80003496:	1f650513          	addi	a0,a0,502 # 80008688 <syscalls+0xe8>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	0a4080e7          	jalr	164(ra) # 8000053e <panic>

00000000800034a2 <bpin>:

void
bpin(struct buf *b) {
    800034a2:	1101                	addi	sp,sp,-32
    800034a4:	ec06                	sd	ra,24(sp)
    800034a6:	e822                	sd	s0,16(sp)
    800034a8:	e426                	sd	s1,8(sp)
    800034aa:	1000                	addi	s0,sp,32
    800034ac:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034ae:	00014517          	auipc	a0,0x14
    800034b2:	e3a50513          	addi	a0,a0,-454 # 800172e8 <bcache>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	72e080e7          	jalr	1838(ra) # 80000be4 <acquire>
  b->refcnt++;
    800034be:	40bc                	lw	a5,64(s1)
    800034c0:	2785                	addiw	a5,a5,1
    800034c2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034c4:	00014517          	auipc	a0,0x14
    800034c8:	e2450513          	addi	a0,a0,-476 # 800172e8 <bcache>
    800034cc:	ffffd097          	auipc	ra,0xffffd
    800034d0:	7cc080e7          	jalr	1996(ra) # 80000c98 <release>
}
    800034d4:	60e2                	ld	ra,24(sp)
    800034d6:	6442                	ld	s0,16(sp)
    800034d8:	64a2                	ld	s1,8(sp)
    800034da:	6105                	addi	sp,sp,32
    800034dc:	8082                	ret

00000000800034de <bunpin>:

void
bunpin(struct buf *b) {
    800034de:	1101                	addi	sp,sp,-32
    800034e0:	ec06                	sd	ra,24(sp)
    800034e2:	e822                	sd	s0,16(sp)
    800034e4:	e426                	sd	s1,8(sp)
    800034e6:	1000                	addi	s0,sp,32
    800034e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034ea:	00014517          	auipc	a0,0x14
    800034ee:	dfe50513          	addi	a0,a0,-514 # 800172e8 <bcache>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	6f2080e7          	jalr	1778(ra) # 80000be4 <acquire>
  b->refcnt--;
    800034fa:	40bc                	lw	a5,64(s1)
    800034fc:	37fd                	addiw	a5,a5,-1
    800034fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003500:	00014517          	auipc	a0,0x14
    80003504:	de850513          	addi	a0,a0,-536 # 800172e8 <bcache>
    80003508:	ffffd097          	auipc	ra,0xffffd
    8000350c:	790080e7          	jalr	1936(ra) # 80000c98 <release>
}
    80003510:	60e2                	ld	ra,24(sp)
    80003512:	6442                	ld	s0,16(sp)
    80003514:	64a2                	ld	s1,8(sp)
    80003516:	6105                	addi	sp,sp,32
    80003518:	8082                	ret

000000008000351a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000351a:	1101                	addi	sp,sp,-32
    8000351c:	ec06                	sd	ra,24(sp)
    8000351e:	e822                	sd	s0,16(sp)
    80003520:	e426                	sd	s1,8(sp)
    80003522:	e04a                	sd	s2,0(sp)
    80003524:	1000                	addi	s0,sp,32
    80003526:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003528:	00d5d59b          	srliw	a1,a1,0xd
    8000352c:	0001c797          	auipc	a5,0x1c
    80003530:	4987a783          	lw	a5,1176(a5) # 8001f9c4 <sb+0x1c>
    80003534:	9dbd                	addw	a1,a1,a5
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	d9e080e7          	jalr	-610(ra) # 800032d4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000353e:	0074f713          	andi	a4,s1,7
    80003542:	4785                	li	a5,1
    80003544:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003548:	14ce                	slli	s1,s1,0x33
    8000354a:	90d9                	srli	s1,s1,0x36
    8000354c:	00950733          	add	a4,a0,s1
    80003550:	05874703          	lbu	a4,88(a4)
    80003554:	00e7f6b3          	and	a3,a5,a4
    80003558:	c69d                	beqz	a3,80003586 <bfree+0x6c>
    8000355a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000355c:	94aa                	add	s1,s1,a0
    8000355e:	fff7c793          	not	a5,a5
    80003562:	8ff9                	and	a5,a5,a4
    80003564:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003568:	00001097          	auipc	ra,0x1
    8000356c:	118080e7          	jalr	280(ra) # 80004680 <log_write>
  brelse(bp);
    80003570:	854a                	mv	a0,s2
    80003572:	00000097          	auipc	ra,0x0
    80003576:	e92080e7          	jalr	-366(ra) # 80003404 <brelse>
}
    8000357a:	60e2                	ld	ra,24(sp)
    8000357c:	6442                	ld	s0,16(sp)
    8000357e:	64a2                	ld	s1,8(sp)
    80003580:	6902                	ld	s2,0(sp)
    80003582:	6105                	addi	sp,sp,32
    80003584:	8082                	ret
    panic("freeing free block");
    80003586:	00005517          	auipc	a0,0x5
    8000358a:	10a50513          	addi	a0,a0,266 # 80008690 <syscalls+0xf0>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	fb0080e7          	jalr	-80(ra) # 8000053e <panic>

0000000080003596 <balloc>:
{
    80003596:	711d                	addi	sp,sp,-96
    80003598:	ec86                	sd	ra,88(sp)
    8000359a:	e8a2                	sd	s0,80(sp)
    8000359c:	e4a6                	sd	s1,72(sp)
    8000359e:	e0ca                	sd	s2,64(sp)
    800035a0:	fc4e                	sd	s3,56(sp)
    800035a2:	f852                	sd	s4,48(sp)
    800035a4:	f456                	sd	s5,40(sp)
    800035a6:	f05a                	sd	s6,32(sp)
    800035a8:	ec5e                	sd	s7,24(sp)
    800035aa:	e862                	sd	s8,16(sp)
    800035ac:	e466                	sd	s9,8(sp)
    800035ae:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035b0:	0001c797          	auipc	a5,0x1c
    800035b4:	3fc7a783          	lw	a5,1020(a5) # 8001f9ac <sb+0x4>
    800035b8:	cbd1                	beqz	a5,8000364c <balloc+0xb6>
    800035ba:	8baa                	mv	s7,a0
    800035bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035be:	0001cb17          	auipc	s6,0x1c
    800035c2:	3eab0b13          	addi	s6,s6,1002 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035cc:	6c89                	lui	s9,0x2
    800035ce:	a831                	j	800035ea <balloc+0x54>
    brelse(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	e32080e7          	jalr	-462(ra) # 80003404 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800035da:	015c87bb          	addw	a5,s9,s5
    800035de:	00078a9b          	sext.w	s5,a5
    800035e2:	004b2703          	lw	a4,4(s6)
    800035e6:	06eaf363          	bgeu	s5,a4,8000364c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800035ea:	41fad79b          	sraiw	a5,s5,0x1f
    800035ee:	0137d79b          	srliw	a5,a5,0x13
    800035f2:	015787bb          	addw	a5,a5,s5
    800035f6:	40d7d79b          	sraiw	a5,a5,0xd
    800035fa:	01cb2583          	lw	a1,28(s6)
    800035fe:	9dbd                	addw	a1,a1,a5
    80003600:	855e                	mv	a0,s7
    80003602:	00000097          	auipc	ra,0x0
    80003606:	cd2080e7          	jalr	-814(ra) # 800032d4 <bread>
    8000360a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000360c:	004b2503          	lw	a0,4(s6)
    80003610:	000a849b          	sext.w	s1,s5
    80003614:	8662                	mv	a2,s8
    80003616:	faa4fde3          	bgeu	s1,a0,800035d0 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000361a:	41f6579b          	sraiw	a5,a2,0x1f
    8000361e:	01d7d69b          	srliw	a3,a5,0x1d
    80003622:	00c6873b          	addw	a4,a3,a2
    80003626:	00777793          	andi	a5,a4,7
    8000362a:	9f95                	subw	a5,a5,a3
    8000362c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003630:	4037571b          	sraiw	a4,a4,0x3
    80003634:	00e906b3          	add	a3,s2,a4
    80003638:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    8000363c:	00d7f5b3          	and	a1,a5,a3
    80003640:	cd91                	beqz	a1,8000365c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003642:	2605                	addiw	a2,a2,1
    80003644:	2485                	addiw	s1,s1,1
    80003646:	fd4618e3          	bne	a2,s4,80003616 <balloc+0x80>
    8000364a:	b759                	j	800035d0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000364c:	00005517          	auipc	a0,0x5
    80003650:	05c50513          	addi	a0,a0,92 # 800086a8 <syscalls+0x108>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	eea080e7          	jalr	-278(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000365c:	974a                	add	a4,a4,s2
    8000365e:	8fd5                	or	a5,a5,a3
    80003660:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003664:	854a                	mv	a0,s2
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	01a080e7          	jalr	26(ra) # 80004680 <log_write>
        brelse(bp);
    8000366e:	854a                	mv	a0,s2
    80003670:	00000097          	auipc	ra,0x0
    80003674:	d94080e7          	jalr	-620(ra) # 80003404 <brelse>
  bp = bread(dev, bno);
    80003678:	85a6                	mv	a1,s1
    8000367a:	855e                	mv	a0,s7
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	c58080e7          	jalr	-936(ra) # 800032d4 <bread>
    80003684:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003686:	40000613          	li	a2,1024
    8000368a:	4581                	li	a1,0
    8000368c:	05850513          	addi	a0,a0,88
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	650080e7          	jalr	1616(ra) # 80000ce0 <memset>
  log_write(bp);
    80003698:	854a                	mv	a0,s2
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	fe6080e7          	jalr	-26(ra) # 80004680 <log_write>
  brelse(bp);
    800036a2:	854a                	mv	a0,s2
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	d60080e7          	jalr	-672(ra) # 80003404 <brelse>
}
    800036ac:	8526                	mv	a0,s1
    800036ae:	60e6                	ld	ra,88(sp)
    800036b0:	6446                	ld	s0,80(sp)
    800036b2:	64a6                	ld	s1,72(sp)
    800036b4:	6906                	ld	s2,64(sp)
    800036b6:	79e2                	ld	s3,56(sp)
    800036b8:	7a42                	ld	s4,48(sp)
    800036ba:	7aa2                	ld	s5,40(sp)
    800036bc:	7b02                	ld	s6,32(sp)
    800036be:	6be2                	ld	s7,24(sp)
    800036c0:	6c42                	ld	s8,16(sp)
    800036c2:	6ca2                	ld	s9,8(sp)
    800036c4:	6125                	addi	sp,sp,96
    800036c6:	8082                	ret

00000000800036c8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036c8:	7179                	addi	sp,sp,-48
    800036ca:	f406                	sd	ra,40(sp)
    800036cc:	f022                	sd	s0,32(sp)
    800036ce:	ec26                	sd	s1,24(sp)
    800036d0:	e84a                	sd	s2,16(sp)
    800036d2:	e44e                	sd	s3,8(sp)
    800036d4:	e052                	sd	s4,0(sp)
    800036d6:	1800                	addi	s0,sp,48
    800036d8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036da:	47ad                	li	a5,11
    800036dc:	04b7fe63          	bgeu	a5,a1,80003738 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800036e0:	ff45849b          	addiw	s1,a1,-12
    800036e4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036e8:	0ff00793          	li	a5,255
    800036ec:	0ae7e363          	bltu	a5,a4,80003792 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800036f0:	08052583          	lw	a1,128(a0)
    800036f4:	c5ad                	beqz	a1,8000375e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800036f6:	00092503          	lw	a0,0(s2)
    800036fa:	00000097          	auipc	ra,0x0
    800036fe:	bda080e7          	jalr	-1062(ra) # 800032d4 <bread>
    80003702:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003704:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003708:	02049593          	slli	a1,s1,0x20
    8000370c:	9181                	srli	a1,a1,0x20
    8000370e:	058a                	slli	a1,a1,0x2
    80003710:	00b784b3          	add	s1,a5,a1
    80003714:	0004a983          	lw	s3,0(s1)
    80003718:	04098d63          	beqz	s3,80003772 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000371c:	8552                	mv	a0,s4
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	ce6080e7          	jalr	-794(ra) # 80003404 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003726:	854e                	mv	a0,s3
    80003728:	70a2                	ld	ra,40(sp)
    8000372a:	7402                	ld	s0,32(sp)
    8000372c:	64e2                	ld	s1,24(sp)
    8000372e:	6942                	ld	s2,16(sp)
    80003730:	69a2                	ld	s3,8(sp)
    80003732:	6a02                	ld	s4,0(sp)
    80003734:	6145                	addi	sp,sp,48
    80003736:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003738:	02059493          	slli	s1,a1,0x20
    8000373c:	9081                	srli	s1,s1,0x20
    8000373e:	048a                	slli	s1,s1,0x2
    80003740:	94aa                	add	s1,s1,a0
    80003742:	0504a983          	lw	s3,80(s1)
    80003746:	fe0990e3          	bnez	s3,80003726 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000374a:	4108                	lw	a0,0(a0)
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	e4a080e7          	jalr	-438(ra) # 80003596 <balloc>
    80003754:	0005099b          	sext.w	s3,a0
    80003758:	0534a823          	sw	s3,80(s1)
    8000375c:	b7e9                	j	80003726 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000375e:	4108                	lw	a0,0(a0)
    80003760:	00000097          	auipc	ra,0x0
    80003764:	e36080e7          	jalr	-458(ra) # 80003596 <balloc>
    80003768:	0005059b          	sext.w	a1,a0
    8000376c:	08b92023          	sw	a1,128(s2)
    80003770:	b759                	j	800036f6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003772:	00092503          	lw	a0,0(s2)
    80003776:	00000097          	auipc	ra,0x0
    8000377a:	e20080e7          	jalr	-480(ra) # 80003596 <balloc>
    8000377e:	0005099b          	sext.w	s3,a0
    80003782:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003786:	8552                	mv	a0,s4
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	ef8080e7          	jalr	-264(ra) # 80004680 <log_write>
    80003790:	b771                	j	8000371c <bmap+0x54>
  panic("bmap: out of range");
    80003792:	00005517          	auipc	a0,0x5
    80003796:	f2e50513          	addi	a0,a0,-210 # 800086c0 <syscalls+0x120>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	da4080e7          	jalr	-604(ra) # 8000053e <panic>

00000000800037a2 <iget>:
{
    800037a2:	7179                	addi	sp,sp,-48
    800037a4:	f406                	sd	ra,40(sp)
    800037a6:	f022                	sd	s0,32(sp)
    800037a8:	ec26                	sd	s1,24(sp)
    800037aa:	e84a                	sd	s2,16(sp)
    800037ac:	e44e                	sd	s3,8(sp)
    800037ae:	e052                	sd	s4,0(sp)
    800037b0:	1800                	addi	s0,sp,48
    800037b2:	89aa                	mv	s3,a0
    800037b4:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037b6:	0001c517          	auipc	a0,0x1c
    800037ba:	21250513          	addi	a0,a0,530 # 8001f9c8 <itable>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	426080e7          	jalr	1062(ra) # 80000be4 <acquire>
  empty = 0;
    800037c6:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c8:	0001c497          	auipc	s1,0x1c
    800037cc:	21848493          	addi	s1,s1,536 # 8001f9e0 <itable+0x18>
    800037d0:	0001e697          	auipc	a3,0x1e
    800037d4:	ca068693          	addi	a3,a3,-864 # 80021470 <log>
    800037d8:	a039                	j	800037e6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037da:	02090b63          	beqz	s2,80003810 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037de:	08848493          	addi	s1,s1,136
    800037e2:	02d48a63          	beq	s1,a3,80003816 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037e6:	449c                	lw	a5,8(s1)
    800037e8:	fef059e3          	blez	a5,800037da <iget+0x38>
    800037ec:	4098                	lw	a4,0(s1)
    800037ee:	ff3716e3          	bne	a4,s3,800037da <iget+0x38>
    800037f2:	40d8                	lw	a4,4(s1)
    800037f4:	ff4713e3          	bne	a4,s4,800037da <iget+0x38>
      ip->ref++;
    800037f8:	2785                	addiw	a5,a5,1
    800037fa:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037fc:	0001c517          	auipc	a0,0x1c
    80003800:	1cc50513          	addi	a0,a0,460 # 8001f9c8 <itable>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	494080e7          	jalr	1172(ra) # 80000c98 <release>
      return ip;
    8000380c:	8926                	mv	s2,s1
    8000380e:	a03d                	j	8000383c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003810:	f7f9                	bnez	a5,800037de <iget+0x3c>
    80003812:	8926                	mv	s2,s1
    80003814:	b7e9                	j	800037de <iget+0x3c>
  if(empty == 0)
    80003816:	02090c63          	beqz	s2,8000384e <iget+0xac>
  ip->dev = dev;
    8000381a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000381e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003822:	4785                	li	a5,1
    80003824:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003828:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000382c:	0001c517          	auipc	a0,0x1c
    80003830:	19c50513          	addi	a0,a0,412 # 8001f9c8 <itable>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	464080e7          	jalr	1124(ra) # 80000c98 <release>
}
    8000383c:	854a                	mv	a0,s2
    8000383e:	70a2                	ld	ra,40(sp)
    80003840:	7402                	ld	s0,32(sp)
    80003842:	64e2                	ld	s1,24(sp)
    80003844:	6942                	ld	s2,16(sp)
    80003846:	69a2                	ld	s3,8(sp)
    80003848:	6a02                	ld	s4,0(sp)
    8000384a:	6145                	addi	sp,sp,48
    8000384c:	8082                	ret
    panic("iget: no inodes");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	e8a50513          	addi	a0,a0,-374 # 800086d8 <syscalls+0x138>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>

000000008000385e <fsinit>:
fsinit(int dev) {
    8000385e:	7179                	addi	sp,sp,-48
    80003860:	f406                	sd	ra,40(sp)
    80003862:	f022                	sd	s0,32(sp)
    80003864:	ec26                	sd	s1,24(sp)
    80003866:	e84a                	sd	s2,16(sp)
    80003868:	e44e                	sd	s3,8(sp)
    8000386a:	1800                	addi	s0,sp,48
    8000386c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000386e:	4585                	li	a1,1
    80003870:	00000097          	auipc	ra,0x0
    80003874:	a64080e7          	jalr	-1436(ra) # 800032d4 <bread>
    80003878:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000387a:	0001c997          	auipc	s3,0x1c
    8000387e:	12e98993          	addi	s3,s3,302 # 8001f9a8 <sb>
    80003882:	02000613          	li	a2,32
    80003886:	05850593          	addi	a1,a0,88
    8000388a:	854e                	mv	a0,s3
    8000388c:	ffffd097          	auipc	ra,0xffffd
    80003890:	4b4080e7          	jalr	1204(ra) # 80000d40 <memmove>
  brelse(bp);
    80003894:	8526                	mv	a0,s1
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	b6e080e7          	jalr	-1170(ra) # 80003404 <brelse>
  if(sb.magic != FSMAGIC)
    8000389e:	0009a703          	lw	a4,0(s3)
    800038a2:	102037b7          	lui	a5,0x10203
    800038a6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038aa:	02f71263          	bne	a4,a5,800038ce <fsinit+0x70>
  initlog(dev, &sb);
    800038ae:	0001c597          	auipc	a1,0x1c
    800038b2:	0fa58593          	addi	a1,a1,250 # 8001f9a8 <sb>
    800038b6:	854a                	mv	a0,s2
    800038b8:	00001097          	auipc	ra,0x1
    800038bc:	b4c080e7          	jalr	-1204(ra) # 80004404 <initlog>
}
    800038c0:	70a2                	ld	ra,40(sp)
    800038c2:	7402                	ld	s0,32(sp)
    800038c4:	64e2                	ld	s1,24(sp)
    800038c6:	6942                	ld	s2,16(sp)
    800038c8:	69a2                	ld	s3,8(sp)
    800038ca:	6145                	addi	sp,sp,48
    800038cc:	8082                	ret
    panic("invalid file system");
    800038ce:	00005517          	auipc	a0,0x5
    800038d2:	e1a50513          	addi	a0,a0,-486 # 800086e8 <syscalls+0x148>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	c68080e7          	jalr	-920(ra) # 8000053e <panic>

00000000800038de <iinit>:
{
    800038de:	7179                	addi	sp,sp,-48
    800038e0:	f406                	sd	ra,40(sp)
    800038e2:	f022                	sd	s0,32(sp)
    800038e4:	ec26                	sd	s1,24(sp)
    800038e6:	e84a                	sd	s2,16(sp)
    800038e8:	e44e                	sd	s3,8(sp)
    800038ea:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038ec:	00005597          	auipc	a1,0x5
    800038f0:	e1458593          	addi	a1,a1,-492 # 80008700 <syscalls+0x160>
    800038f4:	0001c517          	auipc	a0,0x1c
    800038f8:	0d450513          	addi	a0,a0,212 # 8001f9c8 <itable>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	258080e7          	jalr	600(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003904:	0001c497          	auipc	s1,0x1c
    80003908:	0ec48493          	addi	s1,s1,236 # 8001f9f0 <itable+0x28>
    8000390c:	0001e997          	auipc	s3,0x1e
    80003910:	b7498993          	addi	s3,s3,-1164 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003914:	00005917          	auipc	s2,0x5
    80003918:	df490913          	addi	s2,s2,-524 # 80008708 <syscalls+0x168>
    8000391c:	85ca                	mv	a1,s2
    8000391e:	8526                	mv	a0,s1
    80003920:	00001097          	auipc	ra,0x1
    80003924:	e46080e7          	jalr	-442(ra) # 80004766 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003928:	08848493          	addi	s1,s1,136
    8000392c:	ff3498e3          	bne	s1,s3,8000391c <iinit+0x3e>
}
    80003930:	70a2                	ld	ra,40(sp)
    80003932:	7402                	ld	s0,32(sp)
    80003934:	64e2                	ld	s1,24(sp)
    80003936:	6942                	ld	s2,16(sp)
    80003938:	69a2                	ld	s3,8(sp)
    8000393a:	6145                	addi	sp,sp,48
    8000393c:	8082                	ret

000000008000393e <ialloc>:
{
    8000393e:	715d                	addi	sp,sp,-80
    80003940:	e486                	sd	ra,72(sp)
    80003942:	e0a2                	sd	s0,64(sp)
    80003944:	fc26                	sd	s1,56(sp)
    80003946:	f84a                	sd	s2,48(sp)
    80003948:	f44e                	sd	s3,40(sp)
    8000394a:	f052                	sd	s4,32(sp)
    8000394c:	ec56                	sd	s5,24(sp)
    8000394e:	e85a                	sd	s6,16(sp)
    80003950:	e45e                	sd	s7,8(sp)
    80003952:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003954:	0001c717          	auipc	a4,0x1c
    80003958:	06072703          	lw	a4,96(a4) # 8001f9b4 <sb+0xc>
    8000395c:	4785                	li	a5,1
    8000395e:	04e7fa63          	bgeu	a5,a4,800039b2 <ialloc+0x74>
    80003962:	8aaa                	mv	s5,a0
    80003964:	8bae                	mv	s7,a1
    80003966:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003968:	0001ca17          	auipc	s4,0x1c
    8000396c:	040a0a13          	addi	s4,s4,64 # 8001f9a8 <sb>
    80003970:	00048b1b          	sext.w	s6,s1
    80003974:	0044d593          	srli	a1,s1,0x4
    80003978:	018a2783          	lw	a5,24(s4)
    8000397c:	9dbd                	addw	a1,a1,a5
    8000397e:	8556                	mv	a0,s5
    80003980:	00000097          	auipc	ra,0x0
    80003984:	954080e7          	jalr	-1708(ra) # 800032d4 <bread>
    80003988:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000398a:	05850993          	addi	s3,a0,88
    8000398e:	00f4f793          	andi	a5,s1,15
    80003992:	079a                	slli	a5,a5,0x6
    80003994:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003996:	00099783          	lh	a5,0(s3)
    8000399a:	c785                	beqz	a5,800039c2 <ialloc+0x84>
    brelse(bp);
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	a68080e7          	jalr	-1432(ra) # 80003404 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039a4:	0485                	addi	s1,s1,1
    800039a6:	00ca2703          	lw	a4,12(s4)
    800039aa:	0004879b          	sext.w	a5,s1
    800039ae:	fce7e1e3          	bltu	a5,a4,80003970 <ialloc+0x32>
  panic("ialloc: no inodes");
    800039b2:	00005517          	auipc	a0,0x5
    800039b6:	d5e50513          	addi	a0,a0,-674 # 80008710 <syscalls+0x170>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	b84080e7          	jalr	-1148(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    800039c2:	04000613          	li	a2,64
    800039c6:	4581                	li	a1,0
    800039c8:	854e                	mv	a0,s3
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	316080e7          	jalr	790(ra) # 80000ce0 <memset>
      dip->type = type;
    800039d2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	ca8080e7          	jalr	-856(ra) # 80004680 <log_write>
      brelse(bp);
    800039e0:	854a                	mv	a0,s2
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	a22080e7          	jalr	-1502(ra) # 80003404 <brelse>
      return iget(dev, inum);
    800039ea:	85da                	mv	a1,s6
    800039ec:	8556                	mv	a0,s5
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	db4080e7          	jalr	-588(ra) # 800037a2 <iget>
}
    800039f6:	60a6                	ld	ra,72(sp)
    800039f8:	6406                	ld	s0,64(sp)
    800039fa:	74e2                	ld	s1,56(sp)
    800039fc:	7942                	ld	s2,48(sp)
    800039fe:	79a2                	ld	s3,40(sp)
    80003a00:	7a02                	ld	s4,32(sp)
    80003a02:	6ae2                	ld	s5,24(sp)
    80003a04:	6b42                	ld	s6,16(sp)
    80003a06:	6ba2                	ld	s7,8(sp)
    80003a08:	6161                	addi	sp,sp,80
    80003a0a:	8082                	ret

0000000080003a0c <iupdate>:
{
    80003a0c:	1101                	addi	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	e426                	sd	s1,8(sp)
    80003a14:	e04a                	sd	s2,0(sp)
    80003a16:	1000                	addi	s0,sp,32
    80003a18:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a1a:	415c                	lw	a5,4(a0)
    80003a1c:	0047d79b          	srliw	a5,a5,0x4
    80003a20:	0001c597          	auipc	a1,0x1c
    80003a24:	fa05a583          	lw	a1,-96(a1) # 8001f9c0 <sb+0x18>
    80003a28:	9dbd                	addw	a1,a1,a5
    80003a2a:	4108                	lw	a0,0(a0)
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	8a8080e7          	jalr	-1880(ra) # 800032d4 <bread>
    80003a34:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a36:	05850793          	addi	a5,a0,88
    80003a3a:	40c8                	lw	a0,4(s1)
    80003a3c:	893d                	andi	a0,a0,15
    80003a3e:	051a                	slli	a0,a0,0x6
    80003a40:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a42:	04449703          	lh	a4,68(s1)
    80003a46:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a4a:	04649703          	lh	a4,70(s1)
    80003a4e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a52:	04849703          	lh	a4,72(s1)
    80003a56:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a5a:	04a49703          	lh	a4,74(s1)
    80003a5e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a62:	44f8                	lw	a4,76(s1)
    80003a64:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a66:	03400613          	li	a2,52
    80003a6a:	05048593          	addi	a1,s1,80
    80003a6e:	0531                	addi	a0,a0,12
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	2d0080e7          	jalr	720(ra) # 80000d40 <memmove>
  log_write(bp);
    80003a78:	854a                	mv	a0,s2
    80003a7a:	00001097          	auipc	ra,0x1
    80003a7e:	c06080e7          	jalr	-1018(ra) # 80004680 <log_write>
  brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	980080e7          	jalr	-1664(ra) # 80003404 <brelse>
}
    80003a8c:	60e2                	ld	ra,24(sp)
    80003a8e:	6442                	ld	s0,16(sp)
    80003a90:	64a2                	ld	s1,8(sp)
    80003a92:	6902                	ld	s2,0(sp)
    80003a94:	6105                	addi	sp,sp,32
    80003a96:	8082                	ret

0000000080003a98 <idup>:
{
    80003a98:	1101                	addi	sp,sp,-32
    80003a9a:	ec06                	sd	ra,24(sp)
    80003a9c:	e822                	sd	s0,16(sp)
    80003a9e:	e426                	sd	s1,8(sp)
    80003aa0:	1000                	addi	s0,sp,32
    80003aa2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aa4:	0001c517          	auipc	a0,0x1c
    80003aa8:	f2450513          	addi	a0,a0,-220 # 8001f9c8 <itable>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	138080e7          	jalr	312(ra) # 80000be4 <acquire>
  ip->ref++;
    80003ab4:	449c                	lw	a5,8(s1)
    80003ab6:	2785                	addiw	a5,a5,1
    80003ab8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aba:	0001c517          	auipc	a0,0x1c
    80003abe:	f0e50513          	addi	a0,a0,-242 # 8001f9c8 <itable>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	1d6080e7          	jalr	470(ra) # 80000c98 <release>
}
    80003aca:	8526                	mv	a0,s1
    80003acc:	60e2                	ld	ra,24(sp)
    80003ace:	6442                	ld	s0,16(sp)
    80003ad0:	64a2                	ld	s1,8(sp)
    80003ad2:	6105                	addi	sp,sp,32
    80003ad4:	8082                	ret

0000000080003ad6 <ilock>:
{
    80003ad6:	1101                	addi	sp,sp,-32
    80003ad8:	ec06                	sd	ra,24(sp)
    80003ada:	e822                	sd	s0,16(sp)
    80003adc:	e426                	sd	s1,8(sp)
    80003ade:	e04a                	sd	s2,0(sp)
    80003ae0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ae2:	c115                	beqz	a0,80003b06 <ilock+0x30>
    80003ae4:	84aa                	mv	s1,a0
    80003ae6:	451c                	lw	a5,8(a0)
    80003ae8:	00f05f63          	blez	a5,80003b06 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003aec:	0541                	addi	a0,a0,16
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	cb2080e7          	jalr	-846(ra) # 800047a0 <acquiresleep>
  if(ip->valid == 0){
    80003af6:	40bc                	lw	a5,64(s1)
    80003af8:	cf99                	beqz	a5,80003b16 <ilock+0x40>
}
    80003afa:	60e2                	ld	ra,24(sp)
    80003afc:	6442                	ld	s0,16(sp)
    80003afe:	64a2                	ld	s1,8(sp)
    80003b00:	6902                	ld	s2,0(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret
    panic("ilock");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	c2250513          	addi	a0,a0,-990 # 80008728 <syscalls+0x188>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a30080e7          	jalr	-1488(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b16:	40dc                	lw	a5,4(s1)
    80003b18:	0047d79b          	srliw	a5,a5,0x4
    80003b1c:	0001c597          	auipc	a1,0x1c
    80003b20:	ea45a583          	lw	a1,-348(a1) # 8001f9c0 <sb+0x18>
    80003b24:	9dbd                	addw	a1,a1,a5
    80003b26:	4088                	lw	a0,0(s1)
    80003b28:	fffff097          	auipc	ra,0xfffff
    80003b2c:	7ac080e7          	jalr	1964(ra) # 800032d4 <bread>
    80003b30:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b32:	05850593          	addi	a1,a0,88
    80003b36:	40dc                	lw	a5,4(s1)
    80003b38:	8bbd                	andi	a5,a5,15
    80003b3a:	079a                	slli	a5,a5,0x6
    80003b3c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b3e:	00059783          	lh	a5,0(a1)
    80003b42:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b46:	00259783          	lh	a5,2(a1)
    80003b4a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b4e:	00459783          	lh	a5,4(a1)
    80003b52:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b56:	00659783          	lh	a5,6(a1)
    80003b5a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b5e:	459c                	lw	a5,8(a1)
    80003b60:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b62:	03400613          	li	a2,52
    80003b66:	05b1                	addi	a1,a1,12
    80003b68:	05048513          	addi	a0,s1,80
    80003b6c:	ffffd097          	auipc	ra,0xffffd
    80003b70:	1d4080e7          	jalr	468(ra) # 80000d40 <memmove>
    brelse(bp);
    80003b74:	854a                	mv	a0,s2
    80003b76:	00000097          	auipc	ra,0x0
    80003b7a:	88e080e7          	jalr	-1906(ra) # 80003404 <brelse>
    ip->valid = 1;
    80003b7e:	4785                	li	a5,1
    80003b80:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b82:	04449783          	lh	a5,68(s1)
    80003b86:	fbb5                	bnez	a5,80003afa <ilock+0x24>
      panic("ilock: no type");
    80003b88:	00005517          	auipc	a0,0x5
    80003b8c:	ba850513          	addi	a0,a0,-1112 # 80008730 <syscalls+0x190>
    80003b90:	ffffd097          	auipc	ra,0xffffd
    80003b94:	9ae080e7          	jalr	-1618(ra) # 8000053e <panic>

0000000080003b98 <iunlock>:
{
    80003b98:	1101                	addi	sp,sp,-32
    80003b9a:	ec06                	sd	ra,24(sp)
    80003b9c:	e822                	sd	s0,16(sp)
    80003b9e:	e426                	sd	s1,8(sp)
    80003ba0:	e04a                	sd	s2,0(sp)
    80003ba2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ba4:	c905                	beqz	a0,80003bd4 <iunlock+0x3c>
    80003ba6:	84aa                	mv	s1,a0
    80003ba8:	01050913          	addi	s2,a0,16
    80003bac:	854a                	mv	a0,s2
    80003bae:	00001097          	auipc	ra,0x1
    80003bb2:	c8c080e7          	jalr	-884(ra) # 8000483a <holdingsleep>
    80003bb6:	cd19                	beqz	a0,80003bd4 <iunlock+0x3c>
    80003bb8:	449c                	lw	a5,8(s1)
    80003bba:	00f05d63          	blez	a5,80003bd4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	c36080e7          	jalr	-970(ra) # 800047f6 <releasesleep>
}
    80003bc8:	60e2                	ld	ra,24(sp)
    80003bca:	6442                	ld	s0,16(sp)
    80003bcc:	64a2                	ld	s1,8(sp)
    80003bce:	6902                	ld	s2,0(sp)
    80003bd0:	6105                	addi	sp,sp,32
    80003bd2:	8082                	ret
    panic("iunlock");
    80003bd4:	00005517          	auipc	a0,0x5
    80003bd8:	b6c50513          	addi	a0,a0,-1172 # 80008740 <syscalls+0x1a0>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	962080e7          	jalr	-1694(ra) # 8000053e <panic>

0000000080003be4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003be4:	7179                	addi	sp,sp,-48
    80003be6:	f406                	sd	ra,40(sp)
    80003be8:	f022                	sd	s0,32(sp)
    80003bea:	ec26                	sd	s1,24(sp)
    80003bec:	e84a                	sd	s2,16(sp)
    80003bee:	e44e                	sd	s3,8(sp)
    80003bf0:	e052                	sd	s4,0(sp)
    80003bf2:	1800                	addi	s0,sp,48
    80003bf4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bf6:	05050493          	addi	s1,a0,80
    80003bfa:	08050913          	addi	s2,a0,128
    80003bfe:	a021                	j	80003c06 <itrunc+0x22>
    80003c00:	0491                	addi	s1,s1,4
    80003c02:	01248d63          	beq	s1,s2,80003c1c <itrunc+0x38>
    if(ip->addrs[i]){
    80003c06:	408c                	lw	a1,0(s1)
    80003c08:	dde5                	beqz	a1,80003c00 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c0a:	0009a503          	lw	a0,0(s3)
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	90c080e7          	jalr	-1780(ra) # 8000351a <bfree>
      ip->addrs[i] = 0;
    80003c16:	0004a023          	sw	zero,0(s1)
    80003c1a:	b7dd                	j	80003c00 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c1c:	0809a583          	lw	a1,128(s3)
    80003c20:	e185                	bnez	a1,80003c40 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c22:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c26:	854e                	mv	a0,s3
    80003c28:	00000097          	auipc	ra,0x0
    80003c2c:	de4080e7          	jalr	-540(ra) # 80003a0c <iupdate>
}
    80003c30:	70a2                	ld	ra,40(sp)
    80003c32:	7402                	ld	s0,32(sp)
    80003c34:	64e2                	ld	s1,24(sp)
    80003c36:	6942                	ld	s2,16(sp)
    80003c38:	69a2                	ld	s3,8(sp)
    80003c3a:	6a02                	ld	s4,0(sp)
    80003c3c:	6145                	addi	sp,sp,48
    80003c3e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c40:	0009a503          	lw	a0,0(s3)
    80003c44:	fffff097          	auipc	ra,0xfffff
    80003c48:	690080e7          	jalr	1680(ra) # 800032d4 <bread>
    80003c4c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c4e:	05850493          	addi	s1,a0,88
    80003c52:	45850913          	addi	s2,a0,1112
    80003c56:	a811                	j	80003c6a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003c58:	0009a503          	lw	a0,0(s3)
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	8be080e7          	jalr	-1858(ra) # 8000351a <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003c64:	0491                	addi	s1,s1,4
    80003c66:	01248563          	beq	s1,s2,80003c70 <itrunc+0x8c>
      if(a[j])
    80003c6a:	408c                	lw	a1,0(s1)
    80003c6c:	dde5                	beqz	a1,80003c64 <itrunc+0x80>
    80003c6e:	b7ed                	j	80003c58 <itrunc+0x74>
    brelse(bp);
    80003c70:	8552                	mv	a0,s4
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	792080e7          	jalr	1938(ra) # 80003404 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c7a:	0809a583          	lw	a1,128(s3)
    80003c7e:	0009a503          	lw	a0,0(s3)
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	898080e7          	jalr	-1896(ra) # 8000351a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c8a:	0809a023          	sw	zero,128(s3)
    80003c8e:	bf51                	j	80003c22 <itrunc+0x3e>

0000000080003c90 <iput>:
{
    80003c90:	1101                	addi	sp,sp,-32
    80003c92:	ec06                	sd	ra,24(sp)
    80003c94:	e822                	sd	s0,16(sp)
    80003c96:	e426                	sd	s1,8(sp)
    80003c98:	e04a                	sd	s2,0(sp)
    80003c9a:	1000                	addi	s0,sp,32
    80003c9c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c9e:	0001c517          	auipc	a0,0x1c
    80003ca2:	d2a50513          	addi	a0,a0,-726 # 8001f9c8 <itable>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	f3e080e7          	jalr	-194(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cae:	4498                	lw	a4,8(s1)
    80003cb0:	4785                	li	a5,1
    80003cb2:	02f70363          	beq	a4,a5,80003cd8 <iput+0x48>
  ip->ref--;
    80003cb6:	449c                	lw	a5,8(s1)
    80003cb8:	37fd                	addiw	a5,a5,-1
    80003cba:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cbc:	0001c517          	auipc	a0,0x1c
    80003cc0:	d0c50513          	addi	a0,a0,-756 # 8001f9c8 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	fd4080e7          	jalr	-44(ra) # 80000c98 <release>
}
    80003ccc:	60e2                	ld	ra,24(sp)
    80003cce:	6442                	ld	s0,16(sp)
    80003cd0:	64a2                	ld	s1,8(sp)
    80003cd2:	6902                	ld	s2,0(sp)
    80003cd4:	6105                	addi	sp,sp,32
    80003cd6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cd8:	40bc                	lw	a5,64(s1)
    80003cda:	dff1                	beqz	a5,80003cb6 <iput+0x26>
    80003cdc:	04a49783          	lh	a5,74(s1)
    80003ce0:	fbf9                	bnez	a5,80003cb6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ce2:	01048913          	addi	s2,s1,16
    80003ce6:	854a                	mv	a0,s2
    80003ce8:	00001097          	auipc	ra,0x1
    80003cec:	ab8080e7          	jalr	-1352(ra) # 800047a0 <acquiresleep>
    release(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	cd850513          	addi	a0,a0,-808 # 8001f9c8 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa0080e7          	jalr	-96(ra) # 80000c98 <release>
    itrunc(ip);
    80003d00:	8526                	mv	a0,s1
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	ee2080e7          	jalr	-286(ra) # 80003be4 <itrunc>
    ip->type = 0;
    80003d0a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d0e:	8526                	mv	a0,s1
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	cfc080e7          	jalr	-772(ra) # 80003a0c <iupdate>
    ip->valid = 0;
    80003d18:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	00001097          	auipc	ra,0x1
    80003d22:	ad8080e7          	jalr	-1320(ra) # 800047f6 <releasesleep>
    acquire(&itable.lock);
    80003d26:	0001c517          	auipc	a0,0x1c
    80003d2a:	ca250513          	addi	a0,a0,-862 # 8001f9c8 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	eb6080e7          	jalr	-330(ra) # 80000be4 <acquire>
    80003d36:	b741                	j	80003cb6 <iput+0x26>

0000000080003d38 <iunlockput>:
{
    80003d38:	1101                	addi	sp,sp,-32
    80003d3a:	ec06                	sd	ra,24(sp)
    80003d3c:	e822                	sd	s0,16(sp)
    80003d3e:	e426                	sd	s1,8(sp)
    80003d40:	1000                	addi	s0,sp,32
    80003d42:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	e54080e7          	jalr	-428(ra) # 80003b98 <iunlock>
  iput(ip);
    80003d4c:	8526                	mv	a0,s1
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	f42080e7          	jalr	-190(ra) # 80003c90 <iput>
}
    80003d56:	60e2                	ld	ra,24(sp)
    80003d58:	6442                	ld	s0,16(sp)
    80003d5a:	64a2                	ld	s1,8(sp)
    80003d5c:	6105                	addi	sp,sp,32
    80003d5e:	8082                	ret

0000000080003d60 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d60:	1141                	addi	sp,sp,-16
    80003d62:	e422                	sd	s0,8(sp)
    80003d64:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d66:	411c                	lw	a5,0(a0)
    80003d68:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d6a:	415c                	lw	a5,4(a0)
    80003d6c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d6e:	04451783          	lh	a5,68(a0)
    80003d72:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d76:	04a51783          	lh	a5,74(a0)
    80003d7a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d7e:	04c56783          	lwu	a5,76(a0)
    80003d82:	e99c                	sd	a5,16(a1)
}
    80003d84:	6422                	ld	s0,8(sp)
    80003d86:	0141                	addi	sp,sp,16
    80003d88:	8082                	ret

0000000080003d8a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d8a:	457c                	lw	a5,76(a0)
    80003d8c:	0ed7e963          	bltu	a5,a3,80003e7e <readi+0xf4>
{
    80003d90:	7159                	addi	sp,sp,-112
    80003d92:	f486                	sd	ra,104(sp)
    80003d94:	f0a2                	sd	s0,96(sp)
    80003d96:	eca6                	sd	s1,88(sp)
    80003d98:	e8ca                	sd	s2,80(sp)
    80003d9a:	e4ce                	sd	s3,72(sp)
    80003d9c:	e0d2                	sd	s4,64(sp)
    80003d9e:	fc56                	sd	s5,56(sp)
    80003da0:	f85a                	sd	s6,48(sp)
    80003da2:	f45e                	sd	s7,40(sp)
    80003da4:	f062                	sd	s8,32(sp)
    80003da6:	ec66                	sd	s9,24(sp)
    80003da8:	e86a                	sd	s10,16(sp)
    80003daa:	e46e                	sd	s11,8(sp)
    80003dac:	1880                	addi	s0,sp,112
    80003dae:	8baa                	mv	s7,a0
    80003db0:	8c2e                	mv	s8,a1
    80003db2:	8ab2                	mv	s5,a2
    80003db4:	84b6                	mv	s1,a3
    80003db6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003db8:	9f35                	addw	a4,a4,a3
    return 0;
    80003dba:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dbc:	0ad76063          	bltu	a4,a3,80003e5c <readi+0xd2>
  if(off + n > ip->size)
    80003dc0:	00e7f463          	bgeu	a5,a4,80003dc8 <readi+0x3e>
    n = ip->size - off;
    80003dc4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dc8:	0a0b0963          	beqz	s6,80003e7a <readi+0xf0>
    80003dcc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dce:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003dd2:	5cfd                	li	s9,-1
    80003dd4:	a82d                	j	80003e0e <readi+0x84>
    80003dd6:	020a1d93          	slli	s11,s4,0x20
    80003dda:	020ddd93          	srli	s11,s11,0x20
    80003dde:	05890613          	addi	a2,s2,88
    80003de2:	86ee                	mv	a3,s11
    80003de4:	963a                	add	a2,a2,a4
    80003de6:	85d6                	mv	a1,s5
    80003de8:	8562                	mv	a0,s8
    80003dea:	ffffe097          	auipc	ra,0xffffe
    80003dee:	708080e7          	jalr	1800(ra) # 800024f2 <either_copyout>
    80003df2:	05950d63          	beq	a0,s9,80003e4c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	60c080e7          	jalr	1548(ra) # 80003404 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e00:	013a09bb          	addw	s3,s4,s3
    80003e04:	009a04bb          	addw	s1,s4,s1
    80003e08:	9aee                	add	s5,s5,s11
    80003e0a:	0569f763          	bgeu	s3,s6,80003e58 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e0e:	000ba903          	lw	s2,0(s7)
    80003e12:	00a4d59b          	srliw	a1,s1,0xa
    80003e16:	855e                	mv	a0,s7
    80003e18:	00000097          	auipc	ra,0x0
    80003e1c:	8b0080e7          	jalr	-1872(ra) # 800036c8 <bmap>
    80003e20:	0005059b          	sext.w	a1,a0
    80003e24:	854a                	mv	a0,s2
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	4ae080e7          	jalr	1198(ra) # 800032d4 <bread>
    80003e2e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e30:	3ff4f713          	andi	a4,s1,1023
    80003e34:	40ed07bb          	subw	a5,s10,a4
    80003e38:	413b06bb          	subw	a3,s6,s3
    80003e3c:	8a3e                	mv	s4,a5
    80003e3e:	2781                	sext.w	a5,a5
    80003e40:	0006861b          	sext.w	a2,a3
    80003e44:	f8f679e3          	bgeu	a2,a5,80003dd6 <readi+0x4c>
    80003e48:	8a36                	mv	s4,a3
    80003e4a:	b771                	j	80003dd6 <readi+0x4c>
      brelse(bp);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	5b6080e7          	jalr	1462(ra) # 80003404 <brelse>
      tot = -1;
    80003e56:	59fd                	li	s3,-1
  }
  return tot;
    80003e58:	0009851b          	sext.w	a0,s3
}
    80003e5c:	70a6                	ld	ra,104(sp)
    80003e5e:	7406                	ld	s0,96(sp)
    80003e60:	64e6                	ld	s1,88(sp)
    80003e62:	6946                	ld	s2,80(sp)
    80003e64:	69a6                	ld	s3,72(sp)
    80003e66:	6a06                	ld	s4,64(sp)
    80003e68:	7ae2                	ld	s5,56(sp)
    80003e6a:	7b42                	ld	s6,48(sp)
    80003e6c:	7ba2                	ld	s7,40(sp)
    80003e6e:	7c02                	ld	s8,32(sp)
    80003e70:	6ce2                	ld	s9,24(sp)
    80003e72:	6d42                	ld	s10,16(sp)
    80003e74:	6da2                	ld	s11,8(sp)
    80003e76:	6165                	addi	sp,sp,112
    80003e78:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e7a:	89da                	mv	s3,s6
    80003e7c:	bff1                	j	80003e58 <readi+0xce>
    return 0;
    80003e7e:	4501                	li	a0,0
}
    80003e80:	8082                	ret

0000000080003e82 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e82:	457c                	lw	a5,76(a0)
    80003e84:	10d7e863          	bltu	a5,a3,80003f94 <writei+0x112>
{
    80003e88:	7159                	addi	sp,sp,-112
    80003e8a:	f486                	sd	ra,104(sp)
    80003e8c:	f0a2                	sd	s0,96(sp)
    80003e8e:	eca6                	sd	s1,88(sp)
    80003e90:	e8ca                	sd	s2,80(sp)
    80003e92:	e4ce                	sd	s3,72(sp)
    80003e94:	e0d2                	sd	s4,64(sp)
    80003e96:	fc56                	sd	s5,56(sp)
    80003e98:	f85a                	sd	s6,48(sp)
    80003e9a:	f45e                	sd	s7,40(sp)
    80003e9c:	f062                	sd	s8,32(sp)
    80003e9e:	ec66                	sd	s9,24(sp)
    80003ea0:	e86a                	sd	s10,16(sp)
    80003ea2:	e46e                	sd	s11,8(sp)
    80003ea4:	1880                	addi	s0,sp,112
    80003ea6:	8b2a                	mv	s6,a0
    80003ea8:	8c2e                	mv	s8,a1
    80003eaa:	8ab2                	mv	s5,a2
    80003eac:	8936                	mv	s2,a3
    80003eae:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003eb0:	00e687bb          	addw	a5,a3,a4
    80003eb4:	0ed7e263          	bltu	a5,a3,80003f98 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003eb8:	00043737          	lui	a4,0x43
    80003ebc:	0ef76063          	bltu	a4,a5,80003f9c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ec0:	0c0b8863          	beqz	s7,80003f90 <writei+0x10e>
    80003ec4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ec6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eca:	5cfd                	li	s9,-1
    80003ecc:	a091                	j	80003f10 <writei+0x8e>
    80003ece:	02099d93          	slli	s11,s3,0x20
    80003ed2:	020ddd93          	srli	s11,s11,0x20
    80003ed6:	05848513          	addi	a0,s1,88
    80003eda:	86ee                	mv	a3,s11
    80003edc:	8656                	mv	a2,s5
    80003ede:	85e2                	mv	a1,s8
    80003ee0:	953a                	add	a0,a0,a4
    80003ee2:	ffffe097          	auipc	ra,0xffffe
    80003ee6:	666080e7          	jalr	1638(ra) # 80002548 <either_copyin>
    80003eea:	07950263          	beq	a0,s9,80003f4e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003eee:	8526                	mv	a0,s1
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	790080e7          	jalr	1936(ra) # 80004680 <log_write>
    brelse(bp);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	50a080e7          	jalr	1290(ra) # 80003404 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f02:	01498a3b          	addw	s4,s3,s4
    80003f06:	0129893b          	addw	s2,s3,s2
    80003f0a:	9aee                	add	s5,s5,s11
    80003f0c:	057a7663          	bgeu	s4,s7,80003f58 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f10:	000b2483          	lw	s1,0(s6)
    80003f14:	00a9559b          	srliw	a1,s2,0xa
    80003f18:	855a                	mv	a0,s6
    80003f1a:	fffff097          	auipc	ra,0xfffff
    80003f1e:	7ae080e7          	jalr	1966(ra) # 800036c8 <bmap>
    80003f22:	0005059b          	sext.w	a1,a0
    80003f26:	8526                	mv	a0,s1
    80003f28:	fffff097          	auipc	ra,0xfffff
    80003f2c:	3ac080e7          	jalr	940(ra) # 800032d4 <bread>
    80003f30:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f32:	3ff97713          	andi	a4,s2,1023
    80003f36:	40ed07bb          	subw	a5,s10,a4
    80003f3a:	414b86bb          	subw	a3,s7,s4
    80003f3e:	89be                	mv	s3,a5
    80003f40:	2781                	sext.w	a5,a5
    80003f42:	0006861b          	sext.w	a2,a3
    80003f46:	f8f674e3          	bgeu	a2,a5,80003ece <writei+0x4c>
    80003f4a:	89b6                	mv	s3,a3
    80003f4c:	b749                	j	80003ece <writei+0x4c>
      brelse(bp);
    80003f4e:	8526                	mv	a0,s1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	4b4080e7          	jalr	1204(ra) # 80003404 <brelse>
  }

  if(off > ip->size)
    80003f58:	04cb2783          	lw	a5,76(s6)
    80003f5c:	0127f463          	bgeu	a5,s2,80003f64 <writei+0xe2>
    ip->size = off;
    80003f60:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f64:	855a                	mv	a0,s6
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	aa6080e7          	jalr	-1370(ra) # 80003a0c <iupdate>

  return tot;
    80003f6e:	000a051b          	sext.w	a0,s4
}
    80003f72:	70a6                	ld	ra,104(sp)
    80003f74:	7406                	ld	s0,96(sp)
    80003f76:	64e6                	ld	s1,88(sp)
    80003f78:	6946                	ld	s2,80(sp)
    80003f7a:	69a6                	ld	s3,72(sp)
    80003f7c:	6a06                	ld	s4,64(sp)
    80003f7e:	7ae2                	ld	s5,56(sp)
    80003f80:	7b42                	ld	s6,48(sp)
    80003f82:	7ba2                	ld	s7,40(sp)
    80003f84:	7c02                	ld	s8,32(sp)
    80003f86:	6ce2                	ld	s9,24(sp)
    80003f88:	6d42                	ld	s10,16(sp)
    80003f8a:	6da2                	ld	s11,8(sp)
    80003f8c:	6165                	addi	sp,sp,112
    80003f8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f90:	8a5e                	mv	s4,s7
    80003f92:	bfc9                	j	80003f64 <writei+0xe2>
    return -1;
    80003f94:	557d                	li	a0,-1
}
    80003f96:	8082                	ret
    return -1;
    80003f98:	557d                	li	a0,-1
    80003f9a:	bfe1                	j	80003f72 <writei+0xf0>
    return -1;
    80003f9c:	557d                	li	a0,-1
    80003f9e:	bfd1                	j	80003f72 <writei+0xf0>

0000000080003fa0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fa0:	1141                	addi	sp,sp,-16
    80003fa2:	e406                	sd	ra,8(sp)
    80003fa4:	e022                	sd	s0,0(sp)
    80003fa6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fa8:	4639                	li	a2,14
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	e0e080e7          	jalr	-498(ra) # 80000db8 <strncmp>
}
    80003fb2:	60a2                	ld	ra,8(sp)
    80003fb4:	6402                	ld	s0,0(sp)
    80003fb6:	0141                	addi	sp,sp,16
    80003fb8:	8082                	ret

0000000080003fba <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fba:	7139                	addi	sp,sp,-64
    80003fbc:	fc06                	sd	ra,56(sp)
    80003fbe:	f822                	sd	s0,48(sp)
    80003fc0:	f426                	sd	s1,40(sp)
    80003fc2:	f04a                	sd	s2,32(sp)
    80003fc4:	ec4e                	sd	s3,24(sp)
    80003fc6:	e852                	sd	s4,16(sp)
    80003fc8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fca:	04451703          	lh	a4,68(a0)
    80003fce:	4785                	li	a5,1
    80003fd0:	00f71a63          	bne	a4,a5,80003fe4 <dirlookup+0x2a>
    80003fd4:	892a                	mv	s2,a0
    80003fd6:	89ae                	mv	s3,a1
    80003fd8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fda:	457c                	lw	a5,76(a0)
    80003fdc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fde:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe0:	e79d                	bnez	a5,8000400e <dirlookup+0x54>
    80003fe2:	a8a5                	j	8000405a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fe4:	00004517          	auipc	a0,0x4
    80003fe8:	76450513          	addi	a0,a0,1892 # 80008748 <syscalls+0x1a8>
    80003fec:	ffffc097          	auipc	ra,0xffffc
    80003ff0:	552080e7          	jalr	1362(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ff4:	00004517          	auipc	a0,0x4
    80003ff8:	76c50513          	addi	a0,a0,1900 # 80008760 <syscalls+0x1c0>
    80003ffc:	ffffc097          	auipc	ra,0xffffc
    80004000:	542080e7          	jalr	1346(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004004:	24c1                	addiw	s1,s1,16
    80004006:	04c92783          	lw	a5,76(s2)
    8000400a:	04f4f763          	bgeu	s1,a5,80004058 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000400e:	4741                	li	a4,16
    80004010:	86a6                	mv	a3,s1
    80004012:	fc040613          	addi	a2,s0,-64
    80004016:	4581                	li	a1,0
    80004018:	854a                	mv	a0,s2
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	d70080e7          	jalr	-656(ra) # 80003d8a <readi>
    80004022:	47c1                	li	a5,16
    80004024:	fcf518e3          	bne	a0,a5,80003ff4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004028:	fc045783          	lhu	a5,-64(s0)
    8000402c:	dfe1                	beqz	a5,80004004 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000402e:	fc240593          	addi	a1,s0,-62
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	f6c080e7          	jalr	-148(ra) # 80003fa0 <namecmp>
    8000403c:	f561                	bnez	a0,80004004 <dirlookup+0x4a>
      if(poff)
    8000403e:	000a0463          	beqz	s4,80004046 <dirlookup+0x8c>
        *poff = off;
    80004042:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004046:	fc045583          	lhu	a1,-64(s0)
    8000404a:	00092503          	lw	a0,0(s2)
    8000404e:	fffff097          	auipc	ra,0xfffff
    80004052:	754080e7          	jalr	1876(ra) # 800037a2 <iget>
    80004056:	a011                	j	8000405a <dirlookup+0xa0>
  return 0;
    80004058:	4501                	li	a0,0
}
    8000405a:	70e2                	ld	ra,56(sp)
    8000405c:	7442                	ld	s0,48(sp)
    8000405e:	74a2                	ld	s1,40(sp)
    80004060:	7902                	ld	s2,32(sp)
    80004062:	69e2                	ld	s3,24(sp)
    80004064:	6a42                	ld	s4,16(sp)
    80004066:	6121                	addi	sp,sp,64
    80004068:	8082                	ret

000000008000406a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000406a:	711d                	addi	sp,sp,-96
    8000406c:	ec86                	sd	ra,88(sp)
    8000406e:	e8a2                	sd	s0,80(sp)
    80004070:	e4a6                	sd	s1,72(sp)
    80004072:	e0ca                	sd	s2,64(sp)
    80004074:	fc4e                	sd	s3,56(sp)
    80004076:	f852                	sd	s4,48(sp)
    80004078:	f456                	sd	s5,40(sp)
    8000407a:	f05a                	sd	s6,32(sp)
    8000407c:	ec5e                	sd	s7,24(sp)
    8000407e:	e862                	sd	s8,16(sp)
    80004080:	e466                	sd	s9,8(sp)
    80004082:	1080                	addi	s0,sp,96
    80004084:	84aa                	mv	s1,a0
    80004086:	8b2e                	mv	s6,a1
    80004088:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000408a:	00054703          	lbu	a4,0(a0)
    8000408e:	02f00793          	li	a5,47
    80004092:	02f70363          	beq	a4,a5,800040b8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004096:	ffffe097          	auipc	ra,0xffffe
    8000409a:	948080e7          	jalr	-1720(ra) # 800019de <myproc>
    8000409e:	15853503          	ld	a0,344(a0)
    800040a2:	00000097          	auipc	ra,0x0
    800040a6:	9f6080e7          	jalr	-1546(ra) # 80003a98 <idup>
    800040aa:	89aa                	mv	s3,a0
  while(*path == '/')
    800040ac:	02f00913          	li	s2,47
  len = path - s;
    800040b0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800040b2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040b4:	4c05                	li	s8,1
    800040b6:	a865                	j	8000416e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800040b8:	4585                	li	a1,1
    800040ba:	4505                	li	a0,1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	6e6080e7          	jalr	1766(ra) # 800037a2 <iget>
    800040c4:	89aa                	mv	s3,a0
    800040c6:	b7dd                	j	800040ac <namex+0x42>
      iunlockput(ip);
    800040c8:	854e                	mv	a0,s3
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	c6e080e7          	jalr	-914(ra) # 80003d38 <iunlockput>
      return 0;
    800040d2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040d4:	854e                	mv	a0,s3
    800040d6:	60e6                	ld	ra,88(sp)
    800040d8:	6446                	ld	s0,80(sp)
    800040da:	64a6                	ld	s1,72(sp)
    800040dc:	6906                	ld	s2,64(sp)
    800040de:	79e2                	ld	s3,56(sp)
    800040e0:	7a42                	ld	s4,48(sp)
    800040e2:	7aa2                	ld	s5,40(sp)
    800040e4:	7b02                	ld	s6,32(sp)
    800040e6:	6be2                	ld	s7,24(sp)
    800040e8:	6c42                	ld	s8,16(sp)
    800040ea:	6ca2                	ld	s9,8(sp)
    800040ec:	6125                	addi	sp,sp,96
    800040ee:	8082                	ret
      iunlock(ip);
    800040f0:	854e                	mv	a0,s3
    800040f2:	00000097          	auipc	ra,0x0
    800040f6:	aa6080e7          	jalr	-1370(ra) # 80003b98 <iunlock>
      return ip;
    800040fa:	bfe9                	j	800040d4 <namex+0x6a>
      iunlockput(ip);
    800040fc:	854e                	mv	a0,s3
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	c3a080e7          	jalr	-966(ra) # 80003d38 <iunlockput>
      return 0;
    80004106:	89d2                	mv	s3,s4
    80004108:	b7f1                	j	800040d4 <namex+0x6a>
  len = path - s;
    8000410a:	40b48633          	sub	a2,s1,a1
    8000410e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004112:	094cd463          	bge	s9,s4,8000419a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004116:	4639                	li	a2,14
    80004118:	8556                	mv	a0,s5
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	c26080e7          	jalr	-986(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004122:	0004c783          	lbu	a5,0(s1)
    80004126:	01279763          	bne	a5,s2,80004134 <namex+0xca>
    path++;
    8000412a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000412c:	0004c783          	lbu	a5,0(s1)
    80004130:	ff278de3          	beq	a5,s2,8000412a <namex+0xc0>
    ilock(ip);
    80004134:	854e                	mv	a0,s3
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	9a0080e7          	jalr	-1632(ra) # 80003ad6 <ilock>
    if(ip->type != T_DIR){
    8000413e:	04499783          	lh	a5,68(s3)
    80004142:	f98793e3          	bne	a5,s8,800040c8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004146:	000b0563          	beqz	s6,80004150 <namex+0xe6>
    8000414a:	0004c783          	lbu	a5,0(s1)
    8000414e:	d3cd                	beqz	a5,800040f0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004150:	865e                	mv	a2,s7
    80004152:	85d6                	mv	a1,s5
    80004154:	854e                	mv	a0,s3
    80004156:	00000097          	auipc	ra,0x0
    8000415a:	e64080e7          	jalr	-412(ra) # 80003fba <dirlookup>
    8000415e:	8a2a                	mv	s4,a0
    80004160:	dd51                	beqz	a0,800040fc <namex+0x92>
    iunlockput(ip);
    80004162:	854e                	mv	a0,s3
    80004164:	00000097          	auipc	ra,0x0
    80004168:	bd4080e7          	jalr	-1068(ra) # 80003d38 <iunlockput>
    ip = next;
    8000416c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000416e:	0004c783          	lbu	a5,0(s1)
    80004172:	05279763          	bne	a5,s2,800041c0 <namex+0x156>
    path++;
    80004176:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004178:	0004c783          	lbu	a5,0(s1)
    8000417c:	ff278de3          	beq	a5,s2,80004176 <namex+0x10c>
  if(*path == 0)
    80004180:	c79d                	beqz	a5,800041ae <namex+0x144>
    path++;
    80004182:	85a6                	mv	a1,s1
  len = path - s;
    80004184:	8a5e                	mv	s4,s7
    80004186:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004188:	01278963          	beq	a5,s2,8000419a <namex+0x130>
    8000418c:	dfbd                	beqz	a5,8000410a <namex+0xa0>
    path++;
    8000418e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004190:	0004c783          	lbu	a5,0(s1)
    80004194:	ff279ce3          	bne	a5,s2,8000418c <namex+0x122>
    80004198:	bf8d                	j	8000410a <namex+0xa0>
    memmove(name, s, len);
    8000419a:	2601                	sext.w	a2,a2
    8000419c:	8556                	mv	a0,s5
    8000419e:	ffffd097          	auipc	ra,0xffffd
    800041a2:	ba2080e7          	jalr	-1118(ra) # 80000d40 <memmove>
    name[len] = 0;
    800041a6:	9a56                	add	s4,s4,s5
    800041a8:	000a0023          	sb	zero,0(s4)
    800041ac:	bf9d                	j	80004122 <namex+0xb8>
  if(nameiparent){
    800041ae:	f20b03e3          	beqz	s6,800040d4 <namex+0x6a>
    iput(ip);
    800041b2:	854e                	mv	a0,s3
    800041b4:	00000097          	auipc	ra,0x0
    800041b8:	adc080e7          	jalr	-1316(ra) # 80003c90 <iput>
    return 0;
    800041bc:	4981                	li	s3,0
    800041be:	bf19                	j	800040d4 <namex+0x6a>
  if(*path == 0)
    800041c0:	d7fd                	beqz	a5,800041ae <namex+0x144>
  while(*path != '/' && *path != 0)
    800041c2:	0004c783          	lbu	a5,0(s1)
    800041c6:	85a6                	mv	a1,s1
    800041c8:	b7d1                	j	8000418c <namex+0x122>

00000000800041ca <dirlink>:
{
    800041ca:	7139                	addi	sp,sp,-64
    800041cc:	fc06                	sd	ra,56(sp)
    800041ce:	f822                	sd	s0,48(sp)
    800041d0:	f426                	sd	s1,40(sp)
    800041d2:	f04a                	sd	s2,32(sp)
    800041d4:	ec4e                	sd	s3,24(sp)
    800041d6:	e852                	sd	s4,16(sp)
    800041d8:	0080                	addi	s0,sp,64
    800041da:	892a                	mv	s2,a0
    800041dc:	8a2e                	mv	s4,a1
    800041de:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041e0:	4601                	li	a2,0
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	dd8080e7          	jalr	-552(ra) # 80003fba <dirlookup>
    800041ea:	e93d                	bnez	a0,80004260 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041ec:	04c92483          	lw	s1,76(s2)
    800041f0:	c49d                	beqz	s1,8000421e <dirlink+0x54>
    800041f2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041f4:	4741                	li	a4,16
    800041f6:	86a6                	mv	a3,s1
    800041f8:	fc040613          	addi	a2,s0,-64
    800041fc:	4581                	li	a1,0
    800041fe:	854a                	mv	a0,s2
    80004200:	00000097          	auipc	ra,0x0
    80004204:	b8a080e7          	jalr	-1142(ra) # 80003d8a <readi>
    80004208:	47c1                	li	a5,16
    8000420a:	06f51163          	bne	a0,a5,8000426c <dirlink+0xa2>
    if(de.inum == 0)
    8000420e:	fc045783          	lhu	a5,-64(s0)
    80004212:	c791                	beqz	a5,8000421e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004214:	24c1                	addiw	s1,s1,16
    80004216:	04c92783          	lw	a5,76(s2)
    8000421a:	fcf4ede3          	bltu	s1,a5,800041f4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000421e:	4639                	li	a2,14
    80004220:	85d2                	mv	a1,s4
    80004222:	fc240513          	addi	a0,s0,-62
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	bce080e7          	jalr	-1074(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000422e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004232:	4741                	li	a4,16
    80004234:	86a6                	mv	a3,s1
    80004236:	fc040613          	addi	a2,s0,-64
    8000423a:	4581                	li	a1,0
    8000423c:	854a                	mv	a0,s2
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	c44080e7          	jalr	-956(ra) # 80003e82 <writei>
    80004246:	872a                	mv	a4,a0
    80004248:	47c1                	li	a5,16
  return 0;
    8000424a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000424c:	02f71863          	bne	a4,a5,8000427c <dirlink+0xb2>
}
    80004250:	70e2                	ld	ra,56(sp)
    80004252:	7442                	ld	s0,48(sp)
    80004254:	74a2                	ld	s1,40(sp)
    80004256:	7902                	ld	s2,32(sp)
    80004258:	69e2                	ld	s3,24(sp)
    8000425a:	6a42                	ld	s4,16(sp)
    8000425c:	6121                	addi	sp,sp,64
    8000425e:	8082                	ret
    iput(ip);
    80004260:	00000097          	auipc	ra,0x0
    80004264:	a30080e7          	jalr	-1488(ra) # 80003c90 <iput>
    return -1;
    80004268:	557d                	li	a0,-1
    8000426a:	b7dd                	j	80004250 <dirlink+0x86>
      panic("dirlink read");
    8000426c:	00004517          	auipc	a0,0x4
    80004270:	50450513          	addi	a0,a0,1284 # 80008770 <syscalls+0x1d0>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	2ca080e7          	jalr	714(ra) # 8000053e <panic>
    panic("dirlink");
    8000427c:	00004517          	auipc	a0,0x4
    80004280:	60450513          	addi	a0,a0,1540 # 80008880 <syscalls+0x2e0>
    80004284:	ffffc097          	auipc	ra,0xffffc
    80004288:	2ba080e7          	jalr	698(ra) # 8000053e <panic>

000000008000428c <namei>:

struct inode*
namei(char *path)
{
    8000428c:	1101                	addi	sp,sp,-32
    8000428e:	ec06                	sd	ra,24(sp)
    80004290:	e822                	sd	s0,16(sp)
    80004292:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004294:	fe040613          	addi	a2,s0,-32
    80004298:	4581                	li	a1,0
    8000429a:	00000097          	auipc	ra,0x0
    8000429e:	dd0080e7          	jalr	-560(ra) # 8000406a <namex>
}
    800042a2:	60e2                	ld	ra,24(sp)
    800042a4:	6442                	ld	s0,16(sp)
    800042a6:	6105                	addi	sp,sp,32
    800042a8:	8082                	ret

00000000800042aa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042aa:	1141                	addi	sp,sp,-16
    800042ac:	e406                	sd	ra,8(sp)
    800042ae:	e022                	sd	s0,0(sp)
    800042b0:	0800                	addi	s0,sp,16
    800042b2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042b4:	4585                	li	a1,1
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	db4080e7          	jalr	-588(ra) # 8000406a <namex>
}
    800042be:	60a2                	ld	ra,8(sp)
    800042c0:	6402                	ld	s0,0(sp)
    800042c2:	0141                	addi	sp,sp,16
    800042c4:	8082                	ret

00000000800042c6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042c6:	1101                	addi	sp,sp,-32
    800042c8:	ec06                	sd	ra,24(sp)
    800042ca:	e822                	sd	s0,16(sp)
    800042cc:	e426                	sd	s1,8(sp)
    800042ce:	e04a                	sd	s2,0(sp)
    800042d0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042d2:	0001d917          	auipc	s2,0x1d
    800042d6:	19e90913          	addi	s2,s2,414 # 80021470 <log>
    800042da:	01892583          	lw	a1,24(s2)
    800042de:	02892503          	lw	a0,40(s2)
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	ff2080e7          	jalr	-14(ra) # 800032d4 <bread>
    800042ea:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042ec:	02c92683          	lw	a3,44(s2)
    800042f0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042f2:	02d05763          	blez	a3,80004320 <write_head+0x5a>
    800042f6:	0001d797          	auipc	a5,0x1d
    800042fa:	1aa78793          	addi	a5,a5,426 # 800214a0 <log+0x30>
    800042fe:	05c50713          	addi	a4,a0,92
    80004302:	36fd                	addiw	a3,a3,-1
    80004304:	1682                	slli	a3,a3,0x20
    80004306:	9281                	srli	a3,a3,0x20
    80004308:	068a                	slli	a3,a3,0x2
    8000430a:	0001d617          	auipc	a2,0x1d
    8000430e:	19a60613          	addi	a2,a2,410 # 800214a4 <log+0x34>
    80004312:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004314:	4390                	lw	a2,0(a5)
    80004316:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004318:	0791                	addi	a5,a5,4
    8000431a:	0711                	addi	a4,a4,4
    8000431c:	fed79ce3          	bne	a5,a3,80004314 <write_head+0x4e>
  }
  bwrite(buf);
    80004320:	8526                	mv	a0,s1
    80004322:	fffff097          	auipc	ra,0xfffff
    80004326:	0a4080e7          	jalr	164(ra) # 800033c6 <bwrite>
  brelse(buf);
    8000432a:	8526                	mv	a0,s1
    8000432c:	fffff097          	auipc	ra,0xfffff
    80004330:	0d8080e7          	jalr	216(ra) # 80003404 <brelse>
}
    80004334:	60e2                	ld	ra,24(sp)
    80004336:	6442                	ld	s0,16(sp)
    80004338:	64a2                	ld	s1,8(sp)
    8000433a:	6902                	ld	s2,0(sp)
    8000433c:	6105                	addi	sp,sp,32
    8000433e:	8082                	ret

0000000080004340 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004340:	0001d797          	auipc	a5,0x1d
    80004344:	15c7a783          	lw	a5,348(a5) # 8002149c <log+0x2c>
    80004348:	0af05d63          	blez	a5,80004402 <install_trans+0xc2>
{
    8000434c:	7139                	addi	sp,sp,-64
    8000434e:	fc06                	sd	ra,56(sp)
    80004350:	f822                	sd	s0,48(sp)
    80004352:	f426                	sd	s1,40(sp)
    80004354:	f04a                	sd	s2,32(sp)
    80004356:	ec4e                	sd	s3,24(sp)
    80004358:	e852                	sd	s4,16(sp)
    8000435a:	e456                	sd	s5,8(sp)
    8000435c:	e05a                	sd	s6,0(sp)
    8000435e:	0080                	addi	s0,sp,64
    80004360:	8b2a                	mv	s6,a0
    80004362:	0001da97          	auipc	s5,0x1d
    80004366:	13ea8a93          	addi	s5,s5,318 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000436a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000436c:	0001d997          	auipc	s3,0x1d
    80004370:	10498993          	addi	s3,s3,260 # 80021470 <log>
    80004374:	a035                	j	800043a0 <install_trans+0x60>
      bunpin(dbuf);
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	166080e7          	jalr	358(ra) # 800034de <bunpin>
    brelse(lbuf);
    80004380:	854a                	mv	a0,s2
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	082080e7          	jalr	130(ra) # 80003404 <brelse>
    brelse(dbuf);
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	078080e7          	jalr	120(ra) # 80003404 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004394:	2a05                	addiw	s4,s4,1
    80004396:	0a91                	addi	s5,s5,4
    80004398:	02c9a783          	lw	a5,44(s3)
    8000439c:	04fa5963          	bge	s4,a5,800043ee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043a0:	0189a583          	lw	a1,24(s3)
    800043a4:	014585bb          	addw	a1,a1,s4
    800043a8:	2585                	addiw	a1,a1,1
    800043aa:	0289a503          	lw	a0,40(s3)
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	f26080e7          	jalr	-218(ra) # 800032d4 <bread>
    800043b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043b8:	000aa583          	lw	a1,0(s5)
    800043bc:	0289a503          	lw	a0,40(s3)
    800043c0:	fffff097          	auipc	ra,0xfffff
    800043c4:	f14080e7          	jalr	-236(ra) # 800032d4 <bread>
    800043c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043ca:	40000613          	li	a2,1024
    800043ce:	05890593          	addi	a1,s2,88
    800043d2:	05850513          	addi	a0,a0,88
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	96a080e7          	jalr	-1686(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	fe6080e7          	jalr	-26(ra) # 800033c6 <bwrite>
    if(recovering == 0)
    800043e8:	f80b1ce3          	bnez	s6,80004380 <install_trans+0x40>
    800043ec:	b769                	j	80004376 <install_trans+0x36>
}
    800043ee:	70e2                	ld	ra,56(sp)
    800043f0:	7442                	ld	s0,48(sp)
    800043f2:	74a2                	ld	s1,40(sp)
    800043f4:	7902                	ld	s2,32(sp)
    800043f6:	69e2                	ld	s3,24(sp)
    800043f8:	6a42                	ld	s4,16(sp)
    800043fa:	6aa2                	ld	s5,8(sp)
    800043fc:	6b02                	ld	s6,0(sp)
    800043fe:	6121                	addi	sp,sp,64
    80004400:	8082                	ret
    80004402:	8082                	ret

0000000080004404 <initlog>:
{
    80004404:	7179                	addi	sp,sp,-48
    80004406:	f406                	sd	ra,40(sp)
    80004408:	f022                	sd	s0,32(sp)
    8000440a:	ec26                	sd	s1,24(sp)
    8000440c:	e84a                	sd	s2,16(sp)
    8000440e:	e44e                	sd	s3,8(sp)
    80004410:	1800                	addi	s0,sp,48
    80004412:	892a                	mv	s2,a0
    80004414:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004416:	0001d497          	auipc	s1,0x1d
    8000441a:	05a48493          	addi	s1,s1,90 # 80021470 <log>
    8000441e:	00004597          	auipc	a1,0x4
    80004422:	36258593          	addi	a1,a1,866 # 80008780 <syscalls+0x1e0>
    80004426:	8526                	mv	a0,s1
    80004428:	ffffc097          	auipc	ra,0xffffc
    8000442c:	72c080e7          	jalr	1836(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    80004430:	0149a583          	lw	a1,20(s3)
    80004434:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004436:	0109a783          	lw	a5,16(s3)
    8000443a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000443c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004440:	854a                	mv	a0,s2
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	e92080e7          	jalr	-366(ra) # 800032d4 <bread>
  log.lh.n = lh->n;
    8000444a:	4d3c                	lw	a5,88(a0)
    8000444c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000444e:	02f05563          	blez	a5,80004478 <initlog+0x74>
    80004452:	05c50713          	addi	a4,a0,92
    80004456:	0001d697          	auipc	a3,0x1d
    8000445a:	04a68693          	addi	a3,a3,74 # 800214a0 <log+0x30>
    8000445e:	37fd                	addiw	a5,a5,-1
    80004460:	1782                	slli	a5,a5,0x20
    80004462:	9381                	srli	a5,a5,0x20
    80004464:	078a                	slli	a5,a5,0x2
    80004466:	06050613          	addi	a2,a0,96
    8000446a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000446c:	4310                	lw	a2,0(a4)
    8000446e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004470:	0711                	addi	a4,a4,4
    80004472:	0691                	addi	a3,a3,4
    80004474:	fef71ce3          	bne	a4,a5,8000446c <initlog+0x68>
  brelse(buf);
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	f8c080e7          	jalr	-116(ra) # 80003404 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004480:	4505                	li	a0,1
    80004482:	00000097          	auipc	ra,0x0
    80004486:	ebe080e7          	jalr	-322(ra) # 80004340 <install_trans>
  log.lh.n = 0;
    8000448a:	0001d797          	auipc	a5,0x1d
    8000448e:	0007a923          	sw	zero,18(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    80004492:	00000097          	auipc	ra,0x0
    80004496:	e34080e7          	jalr	-460(ra) # 800042c6 <write_head>
}
    8000449a:	70a2                	ld	ra,40(sp)
    8000449c:	7402                	ld	s0,32(sp)
    8000449e:	64e2                	ld	s1,24(sp)
    800044a0:	6942                	ld	s2,16(sp)
    800044a2:	69a2                	ld	s3,8(sp)
    800044a4:	6145                	addi	sp,sp,48
    800044a6:	8082                	ret

00000000800044a8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	e426                	sd	s1,8(sp)
    800044b0:	e04a                	sd	s2,0(sp)
    800044b2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044b4:	0001d517          	auipc	a0,0x1d
    800044b8:	fbc50513          	addi	a0,a0,-68 # 80021470 <log>
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	728080e7          	jalr	1832(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    800044c4:	0001d497          	auipc	s1,0x1d
    800044c8:	fac48493          	addi	s1,s1,-84 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044cc:	4979                	li	s2,30
    800044ce:	a039                	j	800044dc <begin_op+0x34>
      sleep(&log, &log.lock);
    800044d0:	85a6                	mv	a1,s1
    800044d2:	8526                	mv	a0,s1
    800044d4:	ffffe097          	auipc	ra,0xffffe
    800044d8:	c7a080e7          	jalr	-902(ra) # 8000214e <sleep>
    if(log.committing){
    800044dc:	50dc                	lw	a5,36(s1)
    800044de:	fbed                	bnez	a5,800044d0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044e0:	509c                	lw	a5,32(s1)
    800044e2:	0017871b          	addiw	a4,a5,1
    800044e6:	0007069b          	sext.w	a3,a4
    800044ea:	0027179b          	slliw	a5,a4,0x2
    800044ee:	9fb9                	addw	a5,a5,a4
    800044f0:	0017979b          	slliw	a5,a5,0x1
    800044f4:	54d8                	lw	a4,44(s1)
    800044f6:	9fb9                	addw	a5,a5,a4
    800044f8:	00f95963          	bge	s2,a5,8000450a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044fc:	85a6                	mv	a1,s1
    800044fe:	8526                	mv	a0,s1
    80004500:	ffffe097          	auipc	ra,0xffffe
    80004504:	c4e080e7          	jalr	-946(ra) # 8000214e <sleep>
    80004508:	bfd1                	j	800044dc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000450a:	0001d517          	auipc	a0,0x1d
    8000450e:	f6650513          	addi	a0,a0,-154 # 80021470 <log>
    80004512:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	784080e7          	jalr	1924(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6902                	ld	s2,0(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret

0000000080004528 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004528:	7139                	addi	sp,sp,-64
    8000452a:	fc06                	sd	ra,56(sp)
    8000452c:	f822                	sd	s0,48(sp)
    8000452e:	f426                	sd	s1,40(sp)
    80004530:	f04a                	sd	s2,32(sp)
    80004532:	ec4e                	sd	s3,24(sp)
    80004534:	e852                	sd	s4,16(sp)
    80004536:	e456                	sd	s5,8(sp)
    80004538:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000453a:	0001d497          	auipc	s1,0x1d
    8000453e:	f3648493          	addi	s1,s1,-202 # 80021470 <log>
    80004542:	8526                	mv	a0,s1
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	6a0080e7          	jalr	1696(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000454c:	509c                	lw	a5,32(s1)
    8000454e:	37fd                	addiw	a5,a5,-1
    80004550:	0007891b          	sext.w	s2,a5
    80004554:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004556:	50dc                	lw	a5,36(s1)
    80004558:	efb9                	bnez	a5,800045b6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000455a:	06091663          	bnez	s2,800045c6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000455e:	0001d497          	auipc	s1,0x1d
    80004562:	f1248493          	addi	s1,s1,-238 # 80021470 <log>
    80004566:	4785                	li	a5,1
    80004568:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000456a:	8526                	mv	a0,s1
    8000456c:	ffffc097          	auipc	ra,0xffffc
    80004570:	72c080e7          	jalr	1836(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004574:	54dc                	lw	a5,44(s1)
    80004576:	06f04763          	bgtz	a5,800045e4 <end_op+0xbc>
    acquire(&log.lock);
    8000457a:	0001d497          	auipc	s1,0x1d
    8000457e:	ef648493          	addi	s1,s1,-266 # 80021470 <log>
    80004582:	8526                	mv	a0,s1
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	660080e7          	jalr	1632(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000458c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004590:	8526                	mv	a0,s1
    80004592:	ffffe097          	auipc	ra,0xffffe
    80004596:	d48080e7          	jalr	-696(ra) # 800022da <wakeup>
    release(&log.lock);
    8000459a:	8526                	mv	a0,s1
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	6fc080e7          	jalr	1788(ra) # 80000c98 <release>
}
    800045a4:	70e2                	ld	ra,56(sp)
    800045a6:	7442                	ld	s0,48(sp)
    800045a8:	74a2                	ld	s1,40(sp)
    800045aa:	7902                	ld	s2,32(sp)
    800045ac:	69e2                	ld	s3,24(sp)
    800045ae:	6a42                	ld	s4,16(sp)
    800045b0:	6aa2                	ld	s5,8(sp)
    800045b2:	6121                	addi	sp,sp,64
    800045b4:	8082                	ret
    panic("log.committing");
    800045b6:	00004517          	auipc	a0,0x4
    800045ba:	1d250513          	addi	a0,a0,466 # 80008788 <syscalls+0x1e8>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	f80080e7          	jalr	-128(ra) # 8000053e <panic>
    wakeup(&log);
    800045c6:	0001d497          	auipc	s1,0x1d
    800045ca:	eaa48493          	addi	s1,s1,-342 # 80021470 <log>
    800045ce:	8526                	mv	a0,s1
    800045d0:	ffffe097          	auipc	ra,0xffffe
    800045d4:	d0a080e7          	jalr	-758(ra) # 800022da <wakeup>
  release(&log.lock);
    800045d8:	8526                	mv	a0,s1
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	6be080e7          	jalr	1726(ra) # 80000c98 <release>
  if(do_commit){
    800045e2:	b7c9                	j	800045a4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045e4:	0001da97          	auipc	s5,0x1d
    800045e8:	ebca8a93          	addi	s5,s5,-324 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045ec:	0001da17          	auipc	s4,0x1d
    800045f0:	e84a0a13          	addi	s4,s4,-380 # 80021470 <log>
    800045f4:	018a2583          	lw	a1,24(s4)
    800045f8:	012585bb          	addw	a1,a1,s2
    800045fc:	2585                	addiw	a1,a1,1
    800045fe:	028a2503          	lw	a0,40(s4)
    80004602:	fffff097          	auipc	ra,0xfffff
    80004606:	cd2080e7          	jalr	-814(ra) # 800032d4 <bread>
    8000460a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000460c:	000aa583          	lw	a1,0(s5)
    80004610:	028a2503          	lw	a0,40(s4)
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	cc0080e7          	jalr	-832(ra) # 800032d4 <bread>
    8000461c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000461e:	40000613          	li	a2,1024
    80004622:	05850593          	addi	a1,a0,88
    80004626:	05848513          	addi	a0,s1,88
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	716080e7          	jalr	1814(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004632:	8526                	mv	a0,s1
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	d92080e7          	jalr	-622(ra) # 800033c6 <bwrite>
    brelse(from);
    8000463c:	854e                	mv	a0,s3
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	dc6080e7          	jalr	-570(ra) # 80003404 <brelse>
    brelse(to);
    80004646:	8526                	mv	a0,s1
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	dbc080e7          	jalr	-580(ra) # 80003404 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004650:	2905                	addiw	s2,s2,1
    80004652:	0a91                	addi	s5,s5,4
    80004654:	02ca2783          	lw	a5,44(s4)
    80004658:	f8f94ee3          	blt	s2,a5,800045f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000465c:	00000097          	auipc	ra,0x0
    80004660:	c6a080e7          	jalr	-918(ra) # 800042c6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004664:	4501                	li	a0,0
    80004666:	00000097          	auipc	ra,0x0
    8000466a:	cda080e7          	jalr	-806(ra) # 80004340 <install_trans>
    log.lh.n = 0;
    8000466e:	0001d797          	auipc	a5,0x1d
    80004672:	e207a723          	sw	zero,-466(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	c50080e7          	jalr	-944(ra) # 800042c6 <write_head>
    8000467e:	bdf5                	j	8000457a <end_op+0x52>

0000000080004680 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004680:	1101                	addi	sp,sp,-32
    80004682:	ec06                	sd	ra,24(sp)
    80004684:	e822                	sd	s0,16(sp)
    80004686:	e426                	sd	s1,8(sp)
    80004688:	e04a                	sd	s2,0(sp)
    8000468a:	1000                	addi	s0,sp,32
    8000468c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000468e:	0001d917          	auipc	s2,0x1d
    80004692:	de290913          	addi	s2,s2,-542 # 80021470 <log>
    80004696:	854a                	mv	a0,s2
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	54c080e7          	jalr	1356(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046a0:	02c92603          	lw	a2,44(s2)
    800046a4:	47f5                	li	a5,29
    800046a6:	06c7c563          	blt	a5,a2,80004710 <log_write+0x90>
    800046aa:	0001d797          	auipc	a5,0x1d
    800046ae:	de27a783          	lw	a5,-542(a5) # 8002148c <log+0x1c>
    800046b2:	37fd                	addiw	a5,a5,-1
    800046b4:	04f65e63          	bge	a2,a5,80004710 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046b8:	0001d797          	auipc	a5,0x1d
    800046bc:	dd87a783          	lw	a5,-552(a5) # 80021490 <log+0x20>
    800046c0:	06f05063          	blez	a5,80004720 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046c4:	4781                	li	a5,0
    800046c6:	06c05563          	blez	a2,80004730 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ca:	44cc                	lw	a1,12(s1)
    800046cc:	0001d717          	auipc	a4,0x1d
    800046d0:	dd470713          	addi	a4,a4,-556 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046d6:	4314                	lw	a3,0(a4)
    800046d8:	04b68c63          	beq	a3,a1,80004730 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046dc:	2785                	addiw	a5,a5,1
    800046de:	0711                	addi	a4,a4,4
    800046e0:	fef61be3          	bne	a2,a5,800046d6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046e4:	0621                	addi	a2,a2,8
    800046e6:	060a                	slli	a2,a2,0x2
    800046e8:	0001d797          	auipc	a5,0x1d
    800046ec:	d8878793          	addi	a5,a5,-632 # 80021470 <log>
    800046f0:	963e                	add	a2,a2,a5
    800046f2:	44dc                	lw	a5,12(s1)
    800046f4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046f6:	8526                	mv	a0,s1
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	daa080e7          	jalr	-598(ra) # 800034a2 <bpin>
    log.lh.n++;
    80004700:	0001d717          	auipc	a4,0x1d
    80004704:	d7070713          	addi	a4,a4,-656 # 80021470 <log>
    80004708:	575c                	lw	a5,44(a4)
    8000470a:	2785                	addiw	a5,a5,1
    8000470c:	d75c                	sw	a5,44(a4)
    8000470e:	a835                	j	8000474a <log_write+0xca>
    panic("too big a transaction");
    80004710:	00004517          	auipc	a0,0x4
    80004714:	08850513          	addi	a0,a0,136 # 80008798 <syscalls+0x1f8>
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	e26080e7          	jalr	-474(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004720:	00004517          	auipc	a0,0x4
    80004724:	09050513          	addi	a0,a0,144 # 800087b0 <syscalls+0x210>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	e16080e7          	jalr	-490(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004730:	00878713          	addi	a4,a5,8
    80004734:	00271693          	slli	a3,a4,0x2
    80004738:	0001d717          	auipc	a4,0x1d
    8000473c:	d3870713          	addi	a4,a4,-712 # 80021470 <log>
    80004740:	9736                	add	a4,a4,a3
    80004742:	44d4                	lw	a3,12(s1)
    80004744:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004746:	faf608e3          	beq	a2,a5,800046f6 <log_write+0x76>
  }
  release(&log.lock);
    8000474a:	0001d517          	auipc	a0,0x1d
    8000474e:	d2650513          	addi	a0,a0,-730 # 80021470 <log>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	546080e7          	jalr	1350(ra) # 80000c98 <release>
}
    8000475a:	60e2                	ld	ra,24(sp)
    8000475c:	6442                	ld	s0,16(sp)
    8000475e:	64a2                	ld	s1,8(sp)
    80004760:	6902                	ld	s2,0(sp)
    80004762:	6105                	addi	sp,sp,32
    80004764:	8082                	ret

0000000080004766 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004766:	1101                	addi	sp,sp,-32
    80004768:	ec06                	sd	ra,24(sp)
    8000476a:	e822                	sd	s0,16(sp)
    8000476c:	e426                	sd	s1,8(sp)
    8000476e:	e04a                	sd	s2,0(sp)
    80004770:	1000                	addi	s0,sp,32
    80004772:	84aa                	mv	s1,a0
    80004774:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004776:	00004597          	auipc	a1,0x4
    8000477a:	05a58593          	addi	a1,a1,90 # 800087d0 <syscalls+0x230>
    8000477e:	0521                	addi	a0,a0,8
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	3d4080e7          	jalr	980(ra) # 80000b54 <initlock>
  lk->name = name;
    80004788:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000478c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004790:	0204a423          	sw	zero,40(s1)
}
    80004794:	60e2                	ld	ra,24(sp)
    80004796:	6442                	ld	s0,16(sp)
    80004798:	64a2                	ld	s1,8(sp)
    8000479a:	6902                	ld	s2,0(sp)
    8000479c:	6105                	addi	sp,sp,32
    8000479e:	8082                	ret

00000000800047a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047a0:	1101                	addi	sp,sp,-32
    800047a2:	ec06                	sd	ra,24(sp)
    800047a4:	e822                	sd	s0,16(sp)
    800047a6:	e426                	sd	s1,8(sp)
    800047a8:	e04a                	sd	s2,0(sp)
    800047aa:	1000                	addi	s0,sp,32
    800047ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ae:	00850913          	addi	s2,a0,8
    800047b2:	854a                	mv	a0,s2
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	430080e7          	jalr	1072(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800047bc:	409c                	lw	a5,0(s1)
    800047be:	cb89                	beqz	a5,800047d0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047c0:	85ca                	mv	a1,s2
    800047c2:	8526                	mv	a0,s1
    800047c4:	ffffe097          	auipc	ra,0xffffe
    800047c8:	98a080e7          	jalr	-1654(ra) # 8000214e <sleep>
  while (lk->locked) {
    800047cc:	409c                	lw	a5,0(s1)
    800047ce:	fbed                	bnez	a5,800047c0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047d0:	4785                	li	a5,1
    800047d2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047d4:	ffffd097          	auipc	ra,0xffffd
    800047d8:	20a080e7          	jalr	522(ra) # 800019de <myproc>
    800047dc:	591c                	lw	a5,48(a0)
    800047de:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047e0:	854a                	mv	a0,s2
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	4b6080e7          	jalr	1206(ra) # 80000c98 <release>
}
    800047ea:	60e2                	ld	ra,24(sp)
    800047ec:	6442                	ld	s0,16(sp)
    800047ee:	64a2                	ld	s1,8(sp)
    800047f0:	6902                	ld	s2,0(sp)
    800047f2:	6105                	addi	sp,sp,32
    800047f4:	8082                	ret

00000000800047f6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047f6:	1101                	addi	sp,sp,-32
    800047f8:	ec06                	sd	ra,24(sp)
    800047fa:	e822                	sd	s0,16(sp)
    800047fc:	e426                	sd	s1,8(sp)
    800047fe:	e04a                	sd	s2,0(sp)
    80004800:	1000                	addi	s0,sp,32
    80004802:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004804:	00850913          	addi	s2,a0,8
    80004808:	854a                	mv	a0,s2
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	3da080e7          	jalr	986(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004812:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004816:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000481a:	8526                	mv	a0,s1
    8000481c:	ffffe097          	auipc	ra,0xffffe
    80004820:	abe080e7          	jalr	-1346(ra) # 800022da <wakeup>
  release(&lk->lk);
    80004824:	854a                	mv	a0,s2
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	472080e7          	jalr	1138(ra) # 80000c98 <release>
}
    8000482e:	60e2                	ld	ra,24(sp)
    80004830:	6442                	ld	s0,16(sp)
    80004832:	64a2                	ld	s1,8(sp)
    80004834:	6902                	ld	s2,0(sp)
    80004836:	6105                	addi	sp,sp,32
    80004838:	8082                	ret

000000008000483a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000483a:	7179                	addi	sp,sp,-48
    8000483c:	f406                	sd	ra,40(sp)
    8000483e:	f022                	sd	s0,32(sp)
    80004840:	ec26                	sd	s1,24(sp)
    80004842:	e84a                	sd	s2,16(sp)
    80004844:	e44e                	sd	s3,8(sp)
    80004846:	1800                	addi	s0,sp,48
    80004848:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000484a:	00850913          	addi	s2,a0,8
    8000484e:	854a                	mv	a0,s2
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	394080e7          	jalr	916(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004858:	409c                	lw	a5,0(s1)
    8000485a:	ef99                	bnez	a5,80004878 <holdingsleep+0x3e>
    8000485c:	4481                	li	s1,0
  release(&lk->lk);
    8000485e:	854a                	mv	a0,s2
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	438080e7          	jalr	1080(ra) # 80000c98 <release>
  return r;
}
    80004868:	8526                	mv	a0,s1
    8000486a:	70a2                	ld	ra,40(sp)
    8000486c:	7402                	ld	s0,32(sp)
    8000486e:	64e2                	ld	s1,24(sp)
    80004870:	6942                	ld	s2,16(sp)
    80004872:	69a2                	ld	s3,8(sp)
    80004874:	6145                	addi	sp,sp,48
    80004876:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004878:	0284a983          	lw	s3,40(s1)
    8000487c:	ffffd097          	auipc	ra,0xffffd
    80004880:	162080e7          	jalr	354(ra) # 800019de <myproc>
    80004884:	5904                	lw	s1,48(a0)
    80004886:	413484b3          	sub	s1,s1,s3
    8000488a:	0014b493          	seqz	s1,s1
    8000488e:	bfc1                	j	8000485e <holdingsleep+0x24>

0000000080004890 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004890:	1141                	addi	sp,sp,-16
    80004892:	e406                	sd	ra,8(sp)
    80004894:	e022                	sd	s0,0(sp)
    80004896:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004898:	00004597          	auipc	a1,0x4
    8000489c:	f4858593          	addi	a1,a1,-184 # 800087e0 <syscalls+0x240>
    800048a0:	0001d517          	auipc	a0,0x1d
    800048a4:	d1850513          	addi	a0,a0,-744 # 800215b8 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	2ac080e7          	jalr	684(ra) # 80000b54 <initlock>
}
    800048b0:	60a2                	ld	ra,8(sp)
    800048b2:	6402                	ld	s0,0(sp)
    800048b4:	0141                	addi	sp,sp,16
    800048b6:	8082                	ret

00000000800048b8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048c2:	0001d517          	auipc	a0,0x1d
    800048c6:	cf650513          	addi	a0,a0,-778 # 800215b8 <ftable>
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	31a080e7          	jalr	794(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048d2:	0001d497          	auipc	s1,0x1d
    800048d6:	cfe48493          	addi	s1,s1,-770 # 800215d0 <ftable+0x18>
    800048da:	0001e717          	auipc	a4,0x1e
    800048de:	c9670713          	addi	a4,a4,-874 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    800048e2:	40dc                	lw	a5,4(s1)
    800048e4:	cf99                	beqz	a5,80004902 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048e6:	02848493          	addi	s1,s1,40
    800048ea:	fee49ce3          	bne	s1,a4,800048e2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048ee:	0001d517          	auipc	a0,0x1d
    800048f2:	cca50513          	addi	a0,a0,-822 # 800215b8 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	3a2080e7          	jalr	930(ra) # 80000c98 <release>
  return 0;
    800048fe:	4481                	li	s1,0
    80004900:	a819                	j	80004916 <filealloc+0x5e>
      f->ref = 1;
    80004902:	4785                	li	a5,1
    80004904:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004906:	0001d517          	auipc	a0,0x1d
    8000490a:	cb250513          	addi	a0,a0,-846 # 800215b8 <ftable>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	38a080e7          	jalr	906(ra) # 80000c98 <release>
}
    80004916:	8526                	mv	a0,s1
    80004918:	60e2                	ld	ra,24(sp)
    8000491a:	6442                	ld	s0,16(sp)
    8000491c:	64a2                	ld	s1,8(sp)
    8000491e:	6105                	addi	sp,sp,32
    80004920:	8082                	ret

0000000080004922 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004922:	1101                	addi	sp,sp,-32
    80004924:	ec06                	sd	ra,24(sp)
    80004926:	e822                	sd	s0,16(sp)
    80004928:	e426                	sd	s1,8(sp)
    8000492a:	1000                	addi	s0,sp,32
    8000492c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000492e:	0001d517          	auipc	a0,0x1d
    80004932:	c8a50513          	addi	a0,a0,-886 # 800215b8 <ftable>
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	2ae080e7          	jalr	686(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    8000493e:	40dc                	lw	a5,4(s1)
    80004940:	02f05263          	blez	a5,80004964 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004944:	2785                	addiw	a5,a5,1
    80004946:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004948:	0001d517          	auipc	a0,0x1d
    8000494c:	c7050513          	addi	a0,a0,-912 # 800215b8 <ftable>
    80004950:	ffffc097          	auipc	ra,0xffffc
    80004954:	348080e7          	jalr	840(ra) # 80000c98 <release>
  return f;
}
    80004958:	8526                	mv	a0,s1
    8000495a:	60e2                	ld	ra,24(sp)
    8000495c:	6442                	ld	s0,16(sp)
    8000495e:	64a2                	ld	s1,8(sp)
    80004960:	6105                	addi	sp,sp,32
    80004962:	8082                	ret
    panic("filedup");
    80004964:	00004517          	auipc	a0,0x4
    80004968:	e8450513          	addi	a0,a0,-380 # 800087e8 <syscalls+0x248>
    8000496c:	ffffc097          	auipc	ra,0xffffc
    80004970:	bd2080e7          	jalr	-1070(ra) # 8000053e <panic>

0000000080004974 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004974:	7139                	addi	sp,sp,-64
    80004976:	fc06                	sd	ra,56(sp)
    80004978:	f822                	sd	s0,48(sp)
    8000497a:	f426                	sd	s1,40(sp)
    8000497c:	f04a                	sd	s2,32(sp)
    8000497e:	ec4e                	sd	s3,24(sp)
    80004980:	e852                	sd	s4,16(sp)
    80004982:	e456                	sd	s5,8(sp)
    80004984:	0080                	addi	s0,sp,64
    80004986:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004988:	0001d517          	auipc	a0,0x1d
    8000498c:	c3050513          	addi	a0,a0,-976 # 800215b8 <ftable>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	254080e7          	jalr	596(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004998:	40dc                	lw	a5,4(s1)
    8000499a:	06f05163          	blez	a5,800049fc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000499e:	37fd                	addiw	a5,a5,-1
    800049a0:	0007871b          	sext.w	a4,a5
    800049a4:	c0dc                	sw	a5,4(s1)
    800049a6:	06e04363          	bgtz	a4,80004a0c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049aa:	0004a903          	lw	s2,0(s1)
    800049ae:	0094ca83          	lbu	s5,9(s1)
    800049b2:	0104ba03          	ld	s4,16(s1)
    800049b6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049ba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049be:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049c2:	0001d517          	auipc	a0,0x1d
    800049c6:	bf650513          	addi	a0,a0,-1034 # 800215b8 <ftable>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	2ce080e7          	jalr	718(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    800049d2:	4785                	li	a5,1
    800049d4:	04f90d63          	beq	s2,a5,80004a2e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049d8:	3979                	addiw	s2,s2,-2
    800049da:	4785                	li	a5,1
    800049dc:	0527e063          	bltu	a5,s2,80004a1c <fileclose+0xa8>
    begin_op();
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	ac8080e7          	jalr	-1336(ra) # 800044a8 <begin_op>
    iput(ff.ip);
    800049e8:	854e                	mv	a0,s3
    800049ea:	fffff097          	auipc	ra,0xfffff
    800049ee:	2a6080e7          	jalr	678(ra) # 80003c90 <iput>
    end_op();
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	b36080e7          	jalr	-1226(ra) # 80004528 <end_op>
    800049fa:	a00d                	j	80004a1c <fileclose+0xa8>
    panic("fileclose");
    800049fc:	00004517          	auipc	a0,0x4
    80004a00:	df450513          	addi	a0,a0,-524 # 800087f0 <syscalls+0x250>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	b3a080e7          	jalr	-1222(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004a0c:	0001d517          	auipc	a0,0x1d
    80004a10:	bac50513          	addi	a0,a0,-1108 # 800215b8 <ftable>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	284080e7          	jalr	644(ra) # 80000c98 <release>
  }
}
    80004a1c:	70e2                	ld	ra,56(sp)
    80004a1e:	7442                	ld	s0,48(sp)
    80004a20:	74a2                	ld	s1,40(sp)
    80004a22:	7902                	ld	s2,32(sp)
    80004a24:	69e2                	ld	s3,24(sp)
    80004a26:	6a42                	ld	s4,16(sp)
    80004a28:	6aa2                	ld	s5,8(sp)
    80004a2a:	6121                	addi	sp,sp,64
    80004a2c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a2e:	85d6                	mv	a1,s5
    80004a30:	8552                	mv	a0,s4
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	34c080e7          	jalr	844(ra) # 80004d7e <pipeclose>
    80004a3a:	b7cd                	j	80004a1c <fileclose+0xa8>

0000000080004a3c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a3c:	715d                	addi	sp,sp,-80
    80004a3e:	e486                	sd	ra,72(sp)
    80004a40:	e0a2                	sd	s0,64(sp)
    80004a42:	fc26                	sd	s1,56(sp)
    80004a44:	f84a                	sd	s2,48(sp)
    80004a46:	f44e                	sd	s3,40(sp)
    80004a48:	0880                	addi	s0,sp,80
    80004a4a:	84aa                	mv	s1,a0
    80004a4c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a4e:	ffffd097          	auipc	ra,0xffffd
    80004a52:	f90080e7          	jalr	-112(ra) # 800019de <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a56:	409c                	lw	a5,0(s1)
    80004a58:	37f9                	addiw	a5,a5,-2
    80004a5a:	4705                	li	a4,1
    80004a5c:	04f76763          	bltu	a4,a5,80004aaa <filestat+0x6e>
    80004a60:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a62:	6c88                	ld	a0,24(s1)
    80004a64:	fffff097          	auipc	ra,0xfffff
    80004a68:	072080e7          	jalr	114(ra) # 80003ad6 <ilock>
    stati(f->ip, &st);
    80004a6c:	fb840593          	addi	a1,s0,-72
    80004a70:	6c88                	ld	a0,24(s1)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	2ee080e7          	jalr	750(ra) # 80003d60 <stati>
    iunlock(f->ip);
    80004a7a:	6c88                	ld	a0,24(s1)
    80004a7c:	fffff097          	auipc	ra,0xfffff
    80004a80:	11c080e7          	jalr	284(ra) # 80003b98 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a84:	46e1                	li	a3,24
    80004a86:	fb840613          	addi	a2,s0,-72
    80004a8a:	85ce                	mv	a1,s3
    80004a8c:	05893503          	ld	a0,88(s2)
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	be2080e7          	jalr	-1054(ra) # 80001672 <copyout>
    80004a98:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a9c:	60a6                	ld	ra,72(sp)
    80004a9e:	6406                	ld	s0,64(sp)
    80004aa0:	74e2                	ld	s1,56(sp)
    80004aa2:	7942                	ld	s2,48(sp)
    80004aa4:	79a2                	ld	s3,40(sp)
    80004aa6:	6161                	addi	sp,sp,80
    80004aa8:	8082                	ret
  return -1;
    80004aaa:	557d                	li	a0,-1
    80004aac:	bfc5                	j	80004a9c <filestat+0x60>

0000000080004aae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aae:	7179                	addi	sp,sp,-48
    80004ab0:	f406                	sd	ra,40(sp)
    80004ab2:	f022                	sd	s0,32(sp)
    80004ab4:	ec26                	sd	s1,24(sp)
    80004ab6:	e84a                	sd	s2,16(sp)
    80004ab8:	e44e                	sd	s3,8(sp)
    80004aba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004abc:	00854783          	lbu	a5,8(a0)
    80004ac0:	c3d5                	beqz	a5,80004b64 <fileread+0xb6>
    80004ac2:	84aa                	mv	s1,a0
    80004ac4:	89ae                	mv	s3,a1
    80004ac6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ac8:	411c                	lw	a5,0(a0)
    80004aca:	4705                	li	a4,1
    80004acc:	04e78963          	beq	a5,a4,80004b1e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ad0:	470d                	li	a4,3
    80004ad2:	04e78d63          	beq	a5,a4,80004b2c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ad6:	4709                	li	a4,2
    80004ad8:	06e79e63          	bne	a5,a4,80004b54 <fileread+0xa6>
    ilock(f->ip);
    80004adc:	6d08                	ld	a0,24(a0)
    80004ade:	fffff097          	auipc	ra,0xfffff
    80004ae2:	ff8080e7          	jalr	-8(ra) # 80003ad6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ae6:	874a                	mv	a4,s2
    80004ae8:	5094                	lw	a3,32(s1)
    80004aea:	864e                	mv	a2,s3
    80004aec:	4585                	li	a1,1
    80004aee:	6c88                	ld	a0,24(s1)
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	29a080e7          	jalr	666(ra) # 80003d8a <readi>
    80004af8:	892a                	mv	s2,a0
    80004afa:	00a05563          	blez	a0,80004b04 <fileread+0x56>
      f->off += r;
    80004afe:	509c                	lw	a5,32(s1)
    80004b00:	9fa9                	addw	a5,a5,a0
    80004b02:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b04:	6c88                	ld	a0,24(s1)
    80004b06:	fffff097          	auipc	ra,0xfffff
    80004b0a:	092080e7          	jalr	146(ra) # 80003b98 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b0e:	854a                	mv	a0,s2
    80004b10:	70a2                	ld	ra,40(sp)
    80004b12:	7402                	ld	s0,32(sp)
    80004b14:	64e2                	ld	s1,24(sp)
    80004b16:	6942                	ld	s2,16(sp)
    80004b18:	69a2                	ld	s3,8(sp)
    80004b1a:	6145                	addi	sp,sp,48
    80004b1c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b1e:	6908                	ld	a0,16(a0)
    80004b20:	00000097          	auipc	ra,0x0
    80004b24:	3c8080e7          	jalr	968(ra) # 80004ee8 <piperead>
    80004b28:	892a                	mv	s2,a0
    80004b2a:	b7d5                	j	80004b0e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b2c:	02451783          	lh	a5,36(a0)
    80004b30:	03079693          	slli	a3,a5,0x30
    80004b34:	92c1                	srli	a3,a3,0x30
    80004b36:	4725                	li	a4,9
    80004b38:	02d76863          	bltu	a4,a3,80004b68 <fileread+0xba>
    80004b3c:	0792                	slli	a5,a5,0x4
    80004b3e:	0001d717          	auipc	a4,0x1d
    80004b42:	9da70713          	addi	a4,a4,-1574 # 80021518 <devsw>
    80004b46:	97ba                	add	a5,a5,a4
    80004b48:	639c                	ld	a5,0(a5)
    80004b4a:	c38d                	beqz	a5,80004b6c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b4c:	4505                	li	a0,1
    80004b4e:	9782                	jalr	a5
    80004b50:	892a                	mv	s2,a0
    80004b52:	bf75                	j	80004b0e <fileread+0x60>
    panic("fileread");
    80004b54:	00004517          	auipc	a0,0x4
    80004b58:	cac50513          	addi	a0,a0,-852 # 80008800 <syscalls+0x260>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	9e2080e7          	jalr	-1566(ra) # 8000053e <panic>
    return -1;
    80004b64:	597d                	li	s2,-1
    80004b66:	b765                	j	80004b0e <fileread+0x60>
      return -1;
    80004b68:	597d                	li	s2,-1
    80004b6a:	b755                	j	80004b0e <fileread+0x60>
    80004b6c:	597d                	li	s2,-1
    80004b6e:	b745                	j	80004b0e <fileread+0x60>

0000000080004b70 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b70:	715d                	addi	sp,sp,-80
    80004b72:	e486                	sd	ra,72(sp)
    80004b74:	e0a2                	sd	s0,64(sp)
    80004b76:	fc26                	sd	s1,56(sp)
    80004b78:	f84a                	sd	s2,48(sp)
    80004b7a:	f44e                	sd	s3,40(sp)
    80004b7c:	f052                	sd	s4,32(sp)
    80004b7e:	ec56                	sd	s5,24(sp)
    80004b80:	e85a                	sd	s6,16(sp)
    80004b82:	e45e                	sd	s7,8(sp)
    80004b84:	e062                	sd	s8,0(sp)
    80004b86:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b88:	00954783          	lbu	a5,9(a0)
    80004b8c:	10078663          	beqz	a5,80004c98 <filewrite+0x128>
    80004b90:	892a                	mv	s2,a0
    80004b92:	8aae                	mv	s5,a1
    80004b94:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b96:	411c                	lw	a5,0(a0)
    80004b98:	4705                	li	a4,1
    80004b9a:	02e78263          	beq	a5,a4,80004bbe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b9e:	470d                	li	a4,3
    80004ba0:	02e78663          	beq	a5,a4,80004bcc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ba4:	4709                	li	a4,2
    80004ba6:	0ee79163          	bne	a5,a4,80004c88 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004baa:	0ac05d63          	blez	a2,80004c64 <filewrite+0xf4>
    int i = 0;
    80004bae:	4981                	li	s3,0
    80004bb0:	6b05                	lui	s6,0x1
    80004bb2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004bb6:	6b85                	lui	s7,0x1
    80004bb8:	c00b8b9b          	addiw	s7,s7,-1024
    80004bbc:	a861                	j	80004c54 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bbe:	6908                	ld	a0,16(a0)
    80004bc0:	00000097          	auipc	ra,0x0
    80004bc4:	22e080e7          	jalr	558(ra) # 80004dee <pipewrite>
    80004bc8:	8a2a                	mv	s4,a0
    80004bca:	a045                	j	80004c6a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004bcc:	02451783          	lh	a5,36(a0)
    80004bd0:	03079693          	slli	a3,a5,0x30
    80004bd4:	92c1                	srli	a3,a3,0x30
    80004bd6:	4725                	li	a4,9
    80004bd8:	0cd76263          	bltu	a4,a3,80004c9c <filewrite+0x12c>
    80004bdc:	0792                	slli	a5,a5,0x4
    80004bde:	0001d717          	auipc	a4,0x1d
    80004be2:	93a70713          	addi	a4,a4,-1734 # 80021518 <devsw>
    80004be6:	97ba                	add	a5,a5,a4
    80004be8:	679c                	ld	a5,8(a5)
    80004bea:	cbdd                	beqz	a5,80004ca0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bec:	4505                	li	a0,1
    80004bee:	9782                	jalr	a5
    80004bf0:	8a2a                	mv	s4,a0
    80004bf2:	a8a5                	j	80004c6a <filewrite+0xfa>
    80004bf4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bf8:	00000097          	auipc	ra,0x0
    80004bfc:	8b0080e7          	jalr	-1872(ra) # 800044a8 <begin_op>
      ilock(f->ip);
    80004c00:	01893503          	ld	a0,24(s2)
    80004c04:	fffff097          	auipc	ra,0xfffff
    80004c08:	ed2080e7          	jalr	-302(ra) # 80003ad6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c0c:	8762                	mv	a4,s8
    80004c0e:	02092683          	lw	a3,32(s2)
    80004c12:	01598633          	add	a2,s3,s5
    80004c16:	4585                	li	a1,1
    80004c18:	01893503          	ld	a0,24(s2)
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	266080e7          	jalr	614(ra) # 80003e82 <writei>
    80004c24:	84aa                	mv	s1,a0
    80004c26:	00a05763          	blez	a0,80004c34 <filewrite+0xc4>
        f->off += r;
    80004c2a:	02092783          	lw	a5,32(s2)
    80004c2e:	9fa9                	addw	a5,a5,a0
    80004c30:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c34:	01893503          	ld	a0,24(s2)
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	f60080e7          	jalr	-160(ra) # 80003b98 <iunlock>
      end_op();
    80004c40:	00000097          	auipc	ra,0x0
    80004c44:	8e8080e7          	jalr	-1816(ra) # 80004528 <end_op>

      if(r != n1){
    80004c48:	009c1f63          	bne	s8,s1,80004c66 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c4c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c50:	0149db63          	bge	s3,s4,80004c66 <filewrite+0xf6>
      int n1 = n - i;
    80004c54:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c58:	84be                	mv	s1,a5
    80004c5a:	2781                	sext.w	a5,a5
    80004c5c:	f8fb5ce3          	bge	s6,a5,80004bf4 <filewrite+0x84>
    80004c60:	84de                	mv	s1,s7
    80004c62:	bf49                	j	80004bf4 <filewrite+0x84>
    int i = 0;
    80004c64:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c66:	013a1f63          	bne	s4,s3,80004c84 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c6a:	8552                	mv	a0,s4
    80004c6c:	60a6                	ld	ra,72(sp)
    80004c6e:	6406                	ld	s0,64(sp)
    80004c70:	74e2                	ld	s1,56(sp)
    80004c72:	7942                	ld	s2,48(sp)
    80004c74:	79a2                	ld	s3,40(sp)
    80004c76:	7a02                	ld	s4,32(sp)
    80004c78:	6ae2                	ld	s5,24(sp)
    80004c7a:	6b42                	ld	s6,16(sp)
    80004c7c:	6ba2                	ld	s7,8(sp)
    80004c7e:	6c02                	ld	s8,0(sp)
    80004c80:	6161                	addi	sp,sp,80
    80004c82:	8082                	ret
    ret = (i == n ? n : -1);
    80004c84:	5a7d                	li	s4,-1
    80004c86:	b7d5                	j	80004c6a <filewrite+0xfa>
    panic("filewrite");
    80004c88:	00004517          	auipc	a0,0x4
    80004c8c:	b8850513          	addi	a0,a0,-1144 # 80008810 <syscalls+0x270>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>
    return -1;
    80004c98:	5a7d                	li	s4,-1
    80004c9a:	bfc1                	j	80004c6a <filewrite+0xfa>
      return -1;
    80004c9c:	5a7d                	li	s4,-1
    80004c9e:	b7f1                	j	80004c6a <filewrite+0xfa>
    80004ca0:	5a7d                	li	s4,-1
    80004ca2:	b7e1                	j	80004c6a <filewrite+0xfa>

0000000080004ca4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ca4:	7179                	addi	sp,sp,-48
    80004ca6:	f406                	sd	ra,40(sp)
    80004ca8:	f022                	sd	s0,32(sp)
    80004caa:	ec26                	sd	s1,24(sp)
    80004cac:	e84a                	sd	s2,16(sp)
    80004cae:	e44e                	sd	s3,8(sp)
    80004cb0:	e052                	sd	s4,0(sp)
    80004cb2:	1800                	addi	s0,sp,48
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004cb8:	0005b023          	sd	zero,0(a1)
    80004cbc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cc0:	00000097          	auipc	ra,0x0
    80004cc4:	bf8080e7          	jalr	-1032(ra) # 800048b8 <filealloc>
    80004cc8:	e088                	sd	a0,0(s1)
    80004cca:	c551                	beqz	a0,80004d56 <pipealloc+0xb2>
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	bec080e7          	jalr	-1044(ra) # 800048b8 <filealloc>
    80004cd4:	00aa3023          	sd	a0,0(s4)
    80004cd8:	c92d                	beqz	a0,80004d4a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	e1a080e7          	jalr	-486(ra) # 80000af4 <kalloc>
    80004ce2:	892a                	mv	s2,a0
    80004ce4:	c125                	beqz	a0,80004d44 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ce6:	4985                	li	s3,1
    80004ce8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cf0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cf4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cf8:	00004597          	auipc	a1,0x4
    80004cfc:	b2858593          	addi	a1,a1,-1240 # 80008820 <syscalls+0x280>
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	e54080e7          	jalr	-428(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004d08:	609c                	ld	a5,0(s1)
    80004d0a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d0e:	609c                	ld	a5,0(s1)
    80004d10:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d14:	609c                	ld	a5,0(s1)
    80004d16:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d1a:	609c                	ld	a5,0(s1)
    80004d1c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d20:	000a3783          	ld	a5,0(s4)
    80004d24:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d28:	000a3783          	ld	a5,0(s4)
    80004d2c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d30:	000a3783          	ld	a5,0(s4)
    80004d34:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d38:	000a3783          	ld	a5,0(s4)
    80004d3c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d40:	4501                	li	a0,0
    80004d42:	a025                	j	80004d6a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d44:	6088                	ld	a0,0(s1)
    80004d46:	e501                	bnez	a0,80004d4e <pipealloc+0xaa>
    80004d48:	a039                	j	80004d56 <pipealloc+0xb2>
    80004d4a:	6088                	ld	a0,0(s1)
    80004d4c:	c51d                	beqz	a0,80004d7a <pipealloc+0xd6>
    fileclose(*f0);
    80004d4e:	00000097          	auipc	ra,0x0
    80004d52:	c26080e7          	jalr	-986(ra) # 80004974 <fileclose>
  if(*f1)
    80004d56:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d5a:	557d                	li	a0,-1
  if(*f1)
    80004d5c:	c799                	beqz	a5,80004d6a <pipealloc+0xc6>
    fileclose(*f1);
    80004d5e:	853e                	mv	a0,a5
    80004d60:	00000097          	auipc	ra,0x0
    80004d64:	c14080e7          	jalr	-1004(ra) # 80004974 <fileclose>
  return -1;
    80004d68:	557d                	li	a0,-1
}
    80004d6a:	70a2                	ld	ra,40(sp)
    80004d6c:	7402                	ld	s0,32(sp)
    80004d6e:	64e2                	ld	s1,24(sp)
    80004d70:	6942                	ld	s2,16(sp)
    80004d72:	69a2                	ld	s3,8(sp)
    80004d74:	6a02                	ld	s4,0(sp)
    80004d76:	6145                	addi	sp,sp,48
    80004d78:	8082                	ret
  return -1;
    80004d7a:	557d                	li	a0,-1
    80004d7c:	b7fd                	j	80004d6a <pipealloc+0xc6>

0000000080004d7e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d7e:	1101                	addi	sp,sp,-32
    80004d80:	ec06                	sd	ra,24(sp)
    80004d82:	e822                	sd	s0,16(sp)
    80004d84:	e426                	sd	s1,8(sp)
    80004d86:	e04a                	sd	s2,0(sp)
    80004d88:	1000                	addi	s0,sp,32
    80004d8a:	84aa                	mv	s1,a0
    80004d8c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	e56080e7          	jalr	-426(ra) # 80000be4 <acquire>
  if(writable){
    80004d96:	02090d63          	beqz	s2,80004dd0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d9a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d9e:	21848513          	addi	a0,s1,536
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	538080e7          	jalr	1336(ra) # 800022da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004daa:	2204b783          	ld	a5,544(s1)
    80004dae:	eb95                	bnez	a5,80004de2 <pipeclose+0x64>
    release(&pi->lock);
    80004db0:	8526                	mv	a0,s1
    80004db2:	ffffc097          	auipc	ra,0xffffc
    80004db6:	ee6080e7          	jalr	-282(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004dba:	8526                	mv	a0,s1
    80004dbc:	ffffc097          	auipc	ra,0xffffc
    80004dc0:	c3c080e7          	jalr	-964(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004dc4:	60e2                	ld	ra,24(sp)
    80004dc6:	6442                	ld	s0,16(sp)
    80004dc8:	64a2                	ld	s1,8(sp)
    80004dca:	6902                	ld	s2,0(sp)
    80004dcc:	6105                	addi	sp,sp,32
    80004dce:	8082                	ret
    pi->readopen = 0;
    80004dd0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004dd4:	21c48513          	addi	a0,s1,540
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	502080e7          	jalr	1282(ra) # 800022da <wakeup>
    80004de0:	b7e9                	j	80004daa <pipeclose+0x2c>
    release(&pi->lock);
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	eb4080e7          	jalr	-332(ra) # 80000c98 <release>
}
    80004dec:	bfe1                	j	80004dc4 <pipeclose+0x46>

0000000080004dee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dee:	7159                	addi	sp,sp,-112
    80004df0:	f486                	sd	ra,104(sp)
    80004df2:	f0a2                	sd	s0,96(sp)
    80004df4:	eca6                	sd	s1,88(sp)
    80004df6:	e8ca                	sd	s2,80(sp)
    80004df8:	e4ce                	sd	s3,72(sp)
    80004dfa:	e0d2                	sd	s4,64(sp)
    80004dfc:	fc56                	sd	s5,56(sp)
    80004dfe:	f85a                	sd	s6,48(sp)
    80004e00:	f45e                	sd	s7,40(sp)
    80004e02:	f062                	sd	s8,32(sp)
    80004e04:	ec66                	sd	s9,24(sp)
    80004e06:	1880                	addi	s0,sp,112
    80004e08:	84aa                	mv	s1,a0
    80004e0a:	8aae                	mv	s5,a1
    80004e0c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	bd0080e7          	jalr	-1072(ra) # 800019de <myproc>
    80004e16:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	dca080e7          	jalr	-566(ra) # 80000be4 <acquire>
  while(i < n){
    80004e22:	0d405163          	blez	s4,80004ee4 <pipewrite+0xf6>
    80004e26:	8ba6                	mv	s7,s1
  int i = 0;
    80004e28:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e2a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e2c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e30:	21c48c13          	addi	s8,s1,540
    80004e34:	a08d                	j	80004e96 <pipewrite+0xa8>
      release(&pi->lock);
    80004e36:	8526                	mv	a0,s1
    80004e38:	ffffc097          	auipc	ra,0xffffc
    80004e3c:	e60080e7          	jalr	-416(ra) # 80000c98 <release>
      return -1;
    80004e40:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e42:	854a                	mv	a0,s2
    80004e44:	70a6                	ld	ra,104(sp)
    80004e46:	7406                	ld	s0,96(sp)
    80004e48:	64e6                	ld	s1,88(sp)
    80004e4a:	6946                	ld	s2,80(sp)
    80004e4c:	69a6                	ld	s3,72(sp)
    80004e4e:	6a06                	ld	s4,64(sp)
    80004e50:	7ae2                	ld	s5,56(sp)
    80004e52:	7b42                	ld	s6,48(sp)
    80004e54:	7ba2                	ld	s7,40(sp)
    80004e56:	7c02                	ld	s8,32(sp)
    80004e58:	6ce2                	ld	s9,24(sp)
    80004e5a:	6165                	addi	sp,sp,112
    80004e5c:	8082                	ret
      wakeup(&pi->nread);
    80004e5e:	8566                	mv	a0,s9
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	47a080e7          	jalr	1146(ra) # 800022da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e68:	85de                	mv	a1,s7
    80004e6a:	8562                	mv	a0,s8
    80004e6c:	ffffd097          	auipc	ra,0xffffd
    80004e70:	2e2080e7          	jalr	738(ra) # 8000214e <sleep>
    80004e74:	a839                	j	80004e92 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e76:	21c4a783          	lw	a5,540(s1)
    80004e7a:	0017871b          	addiw	a4,a5,1
    80004e7e:	20e4ae23          	sw	a4,540(s1)
    80004e82:	1ff7f793          	andi	a5,a5,511
    80004e86:	97a6                	add	a5,a5,s1
    80004e88:	f9f44703          	lbu	a4,-97(s0)
    80004e8c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e90:	2905                	addiw	s2,s2,1
  while(i < n){
    80004e92:	03495d63          	bge	s2,s4,80004ecc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004e96:	2204a783          	lw	a5,544(s1)
    80004e9a:	dfd1                	beqz	a5,80004e36 <pipewrite+0x48>
    80004e9c:	0289a783          	lw	a5,40(s3)
    80004ea0:	fbd9                	bnez	a5,80004e36 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ea2:	2184a783          	lw	a5,536(s1)
    80004ea6:	21c4a703          	lw	a4,540(s1)
    80004eaa:	2007879b          	addiw	a5,a5,512
    80004eae:	faf708e3          	beq	a4,a5,80004e5e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004eb2:	4685                	li	a3,1
    80004eb4:	01590633          	add	a2,s2,s5
    80004eb8:	f9f40593          	addi	a1,s0,-97
    80004ebc:	0589b503          	ld	a0,88(s3)
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	83e080e7          	jalr	-1986(ra) # 800016fe <copyin>
    80004ec8:	fb6517e3          	bne	a0,s6,80004e76 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ecc:	21848513          	addi	a0,s1,536
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	40a080e7          	jalr	1034(ra) # 800022da <wakeup>
  release(&pi->lock);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	ffffc097          	auipc	ra,0xffffc
    80004ede:	dbe080e7          	jalr	-578(ra) # 80000c98 <release>
  return i;
    80004ee2:	b785                	j	80004e42 <pipewrite+0x54>
  int i = 0;
    80004ee4:	4901                	li	s2,0
    80004ee6:	b7dd                	j	80004ecc <pipewrite+0xde>

0000000080004ee8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ee8:	715d                	addi	sp,sp,-80
    80004eea:	e486                	sd	ra,72(sp)
    80004eec:	e0a2                	sd	s0,64(sp)
    80004eee:	fc26                	sd	s1,56(sp)
    80004ef0:	f84a                	sd	s2,48(sp)
    80004ef2:	f44e                	sd	s3,40(sp)
    80004ef4:	f052                	sd	s4,32(sp)
    80004ef6:	ec56                	sd	s5,24(sp)
    80004ef8:	e85a                	sd	s6,16(sp)
    80004efa:	0880                	addi	s0,sp,80
    80004efc:	84aa                	mv	s1,a0
    80004efe:	892e                	mv	s2,a1
    80004f00:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	adc080e7          	jalr	-1316(ra) # 800019de <myproc>
    80004f0a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f0c:	8b26                	mv	s6,s1
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	cd4080e7          	jalr	-812(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f18:	2184a703          	lw	a4,536(s1)
    80004f1c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f20:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f24:	02f71463          	bne	a4,a5,80004f4c <piperead+0x64>
    80004f28:	2244a783          	lw	a5,548(s1)
    80004f2c:	c385                	beqz	a5,80004f4c <piperead+0x64>
    if(pr->killed){
    80004f2e:	028a2783          	lw	a5,40(s4)
    80004f32:	ebc1                	bnez	a5,80004fc2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f34:	85da                	mv	a1,s6
    80004f36:	854e                	mv	a0,s3
    80004f38:	ffffd097          	auipc	ra,0xffffd
    80004f3c:	216080e7          	jalr	534(ra) # 8000214e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f40:	2184a703          	lw	a4,536(s1)
    80004f44:	21c4a783          	lw	a5,540(s1)
    80004f48:	fef700e3          	beq	a4,a5,80004f28 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f4c:	09505263          	blez	s5,80004fd0 <piperead+0xe8>
    80004f50:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f52:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004f54:	2184a783          	lw	a5,536(s1)
    80004f58:	21c4a703          	lw	a4,540(s1)
    80004f5c:	02f70d63          	beq	a4,a5,80004f96 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f60:	0017871b          	addiw	a4,a5,1
    80004f64:	20e4ac23          	sw	a4,536(s1)
    80004f68:	1ff7f793          	andi	a5,a5,511
    80004f6c:	97a6                	add	a5,a5,s1
    80004f6e:	0187c783          	lbu	a5,24(a5)
    80004f72:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f76:	4685                	li	a3,1
    80004f78:	fbf40613          	addi	a2,s0,-65
    80004f7c:	85ca                	mv	a1,s2
    80004f7e:	058a3503          	ld	a0,88(s4)
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	6f0080e7          	jalr	1776(ra) # 80001672 <copyout>
    80004f8a:	01650663          	beq	a0,s6,80004f96 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f8e:	2985                	addiw	s3,s3,1
    80004f90:	0905                	addi	s2,s2,1
    80004f92:	fd3a91e3          	bne	s5,s3,80004f54 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f96:	21c48513          	addi	a0,s1,540
    80004f9a:	ffffd097          	auipc	ra,0xffffd
    80004f9e:	340080e7          	jalr	832(ra) # 800022da <wakeup>
  release(&pi->lock);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	cf4080e7          	jalr	-780(ra) # 80000c98 <release>
  return i;
}
    80004fac:	854e                	mv	a0,s3
    80004fae:	60a6                	ld	ra,72(sp)
    80004fb0:	6406                	ld	s0,64(sp)
    80004fb2:	74e2                	ld	s1,56(sp)
    80004fb4:	7942                	ld	s2,48(sp)
    80004fb6:	79a2                	ld	s3,40(sp)
    80004fb8:	7a02                	ld	s4,32(sp)
    80004fba:	6ae2                	ld	s5,24(sp)
    80004fbc:	6b42                	ld	s6,16(sp)
    80004fbe:	6161                	addi	sp,sp,80
    80004fc0:	8082                	ret
      release(&pi->lock);
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	cd4080e7          	jalr	-812(ra) # 80000c98 <release>
      return -1;
    80004fcc:	59fd                	li	s3,-1
    80004fce:	bff9                	j	80004fac <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fd0:	4981                	li	s3,0
    80004fd2:	b7d1                	j	80004f96 <piperead+0xae>

0000000080004fd4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004fd4:	df010113          	addi	sp,sp,-528
    80004fd8:	20113423          	sd	ra,520(sp)
    80004fdc:	20813023          	sd	s0,512(sp)
    80004fe0:	ffa6                	sd	s1,504(sp)
    80004fe2:	fbca                	sd	s2,496(sp)
    80004fe4:	f7ce                	sd	s3,488(sp)
    80004fe6:	f3d2                	sd	s4,480(sp)
    80004fe8:	efd6                	sd	s5,472(sp)
    80004fea:	ebda                	sd	s6,464(sp)
    80004fec:	e7de                	sd	s7,456(sp)
    80004fee:	e3e2                	sd	s8,448(sp)
    80004ff0:	ff66                	sd	s9,440(sp)
    80004ff2:	fb6a                	sd	s10,432(sp)
    80004ff4:	f76e                	sd	s11,424(sp)
    80004ff6:	0c00                	addi	s0,sp,528
    80004ff8:	84aa                	mv	s1,a0
    80004ffa:	dea43c23          	sd	a0,-520(s0)
    80004ffe:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	9dc080e7          	jalr	-1572(ra) # 800019de <myproc>
    8000500a:	892a                	mv	s2,a0

  begin_op();
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	49c080e7          	jalr	1180(ra) # 800044a8 <begin_op>

  if((ip = namei(path)) == 0){
    80005014:	8526                	mv	a0,s1
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	276080e7          	jalr	630(ra) # 8000428c <namei>
    8000501e:	c92d                	beqz	a0,80005090 <exec+0xbc>
    80005020:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	ab4080e7          	jalr	-1356(ra) # 80003ad6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000502a:	04000713          	li	a4,64
    8000502e:	4681                	li	a3,0
    80005030:	e5040613          	addi	a2,s0,-432
    80005034:	4581                	li	a1,0
    80005036:	8526                	mv	a0,s1
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	d52080e7          	jalr	-686(ra) # 80003d8a <readi>
    80005040:	04000793          	li	a5,64
    80005044:	00f51a63          	bne	a0,a5,80005058 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005048:	e5042703          	lw	a4,-432(s0)
    8000504c:	464c47b7          	lui	a5,0x464c4
    80005050:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005054:	04f70463          	beq	a4,a5,8000509c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005058:	8526                	mv	a0,s1
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	cde080e7          	jalr	-802(ra) # 80003d38 <iunlockput>
    end_op();
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	4c6080e7          	jalr	1222(ra) # 80004528 <end_op>
  }
  return -1;
    8000506a:	557d                	li	a0,-1
}
    8000506c:	20813083          	ld	ra,520(sp)
    80005070:	20013403          	ld	s0,512(sp)
    80005074:	74fe                	ld	s1,504(sp)
    80005076:	795e                	ld	s2,496(sp)
    80005078:	79be                	ld	s3,488(sp)
    8000507a:	7a1e                	ld	s4,480(sp)
    8000507c:	6afe                	ld	s5,472(sp)
    8000507e:	6b5e                	ld	s6,464(sp)
    80005080:	6bbe                	ld	s7,456(sp)
    80005082:	6c1e                	ld	s8,448(sp)
    80005084:	7cfa                	ld	s9,440(sp)
    80005086:	7d5a                	ld	s10,432(sp)
    80005088:	7dba                	ld	s11,424(sp)
    8000508a:	21010113          	addi	sp,sp,528
    8000508e:	8082                	ret
    end_op();
    80005090:	fffff097          	auipc	ra,0xfffff
    80005094:	498080e7          	jalr	1176(ra) # 80004528 <end_op>
    return -1;
    80005098:	557d                	li	a0,-1
    8000509a:	bfc9                	j	8000506c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000509c:	854a                	mv	a0,s2
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	a4a080e7          	jalr	-1462(ra) # 80001ae8 <proc_pagetable>
    800050a6:	8baa                	mv	s7,a0
    800050a8:	d945                	beqz	a0,80005058 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050aa:	e7042983          	lw	s3,-400(s0)
    800050ae:	e8845783          	lhu	a5,-376(s0)
    800050b2:	c7ad                	beqz	a5,8000511c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050b4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b6:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800050b8:	6c85                	lui	s9,0x1
    800050ba:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800050be:	def43823          	sd	a5,-528(s0)
    800050c2:	a42d                	j	800052ec <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050c4:	00003517          	auipc	a0,0x3
    800050c8:	76450513          	addi	a0,a0,1892 # 80008828 <syscalls+0x288>
    800050cc:	ffffb097          	auipc	ra,0xffffb
    800050d0:	472080e7          	jalr	1138(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050d4:	8756                	mv	a4,s5
    800050d6:	012d86bb          	addw	a3,s11,s2
    800050da:	4581                	li	a1,0
    800050dc:	8526                	mv	a0,s1
    800050de:	fffff097          	auipc	ra,0xfffff
    800050e2:	cac080e7          	jalr	-852(ra) # 80003d8a <readi>
    800050e6:	2501                	sext.w	a0,a0
    800050e8:	1aaa9963          	bne	s5,a0,8000529a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800050ec:	6785                	lui	a5,0x1
    800050ee:	0127893b          	addw	s2,a5,s2
    800050f2:	77fd                	lui	a5,0xfffff
    800050f4:	01478a3b          	addw	s4,a5,s4
    800050f8:	1f897163          	bgeu	s2,s8,800052da <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800050fc:	02091593          	slli	a1,s2,0x20
    80005100:	9181                	srli	a1,a1,0x20
    80005102:	95ea                	add	a1,a1,s10
    80005104:	855e                	mv	a0,s7
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	f68080e7          	jalr	-152(ra) # 8000106e <walkaddr>
    8000510e:	862a                	mv	a2,a0
    if(pa == 0)
    80005110:	d955                	beqz	a0,800050c4 <exec+0xf0>
      n = PGSIZE;
    80005112:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005114:	fd9a70e3          	bgeu	s4,s9,800050d4 <exec+0x100>
      n = sz - i;
    80005118:	8ad2                	mv	s5,s4
    8000511a:	bf6d                	j	800050d4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000511c:	4901                	li	s2,0
  iunlockput(ip);
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	c18080e7          	jalr	-1000(ra) # 80003d38 <iunlockput>
  end_op();
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	400080e7          	jalr	1024(ra) # 80004528 <end_op>
  p = myproc();
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	8ae080e7          	jalr	-1874(ra) # 800019de <myproc>
    80005138:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000513a:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000513e:	6785                	lui	a5,0x1
    80005140:	17fd                	addi	a5,a5,-1
    80005142:	993e                	add	s2,s2,a5
    80005144:	757d                	lui	a0,0xfffff
    80005146:	00a977b3          	and	a5,s2,a0
    8000514a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000514e:	6609                	lui	a2,0x2
    80005150:	963e                	add	a2,a2,a5
    80005152:	85be                	mv	a1,a5
    80005154:	855e                	mv	a0,s7
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	2cc080e7          	jalr	716(ra) # 80001422 <uvmalloc>
    8000515e:	8b2a                	mv	s6,a0
  ip = 0;
    80005160:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005162:	12050c63          	beqz	a0,8000529a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005166:	75f9                	lui	a1,0xffffe
    80005168:	95aa                	add	a1,a1,a0
    8000516a:	855e                	mv	a0,s7
    8000516c:	ffffc097          	auipc	ra,0xffffc
    80005170:	4d4080e7          	jalr	1236(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80005174:	7c7d                	lui	s8,0xfffff
    80005176:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005178:	e0043783          	ld	a5,-512(s0)
    8000517c:	6388                	ld	a0,0(a5)
    8000517e:	c535                	beqz	a0,800051ea <exec+0x216>
    80005180:	e9040993          	addi	s3,s0,-368
    80005184:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005188:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000518a:	ffffc097          	auipc	ra,0xffffc
    8000518e:	cda080e7          	jalr	-806(ra) # 80000e64 <strlen>
    80005192:	2505                	addiw	a0,a0,1
    80005194:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005198:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000519c:	13896363          	bltu	s2,s8,800052c2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a0:	e0043d83          	ld	s11,-512(s0)
    800051a4:	000dba03          	ld	s4,0(s11)
    800051a8:	8552                	mv	a0,s4
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	cba080e7          	jalr	-838(ra) # 80000e64 <strlen>
    800051b2:	0015069b          	addiw	a3,a0,1
    800051b6:	8652                	mv	a2,s4
    800051b8:	85ca                	mv	a1,s2
    800051ba:	855e                	mv	a0,s7
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	4b6080e7          	jalr	1206(ra) # 80001672 <copyout>
    800051c4:	10054363          	bltz	a0,800052ca <exec+0x2f6>
    ustack[argc] = sp;
    800051c8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051cc:	0485                	addi	s1,s1,1
    800051ce:	008d8793          	addi	a5,s11,8
    800051d2:	e0f43023          	sd	a5,-512(s0)
    800051d6:	008db503          	ld	a0,8(s11)
    800051da:	c911                	beqz	a0,800051ee <exec+0x21a>
    if(argc >= MAXARG)
    800051dc:	09a1                	addi	s3,s3,8
    800051de:	fb3c96e3          	bne	s9,s3,8000518a <exec+0x1b6>
  sz = sz1;
    800051e2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051e6:	4481                	li	s1,0
    800051e8:	a84d                	j	8000529a <exec+0x2c6>
  sp = sz;
    800051ea:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	4481                	li	s1,0
  ustack[argc] = 0;
    800051ee:	00349793          	slli	a5,s1,0x3
    800051f2:	f9040713          	addi	a4,s0,-112
    800051f6:	97ba                	add	a5,a5,a4
    800051f8:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800051fc:	00148693          	addi	a3,s1,1
    80005200:	068e                	slli	a3,a3,0x3
    80005202:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005206:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000520a:	01897663          	bgeu	s2,s8,80005216 <exec+0x242>
  sz = sz1;
    8000520e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005212:	4481                	li	s1,0
    80005214:	a059                	j	8000529a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005216:	e9040613          	addi	a2,s0,-368
    8000521a:	85ca                	mv	a1,s2
    8000521c:	855e                	mv	a0,s7
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	454080e7          	jalr	1108(ra) # 80001672 <copyout>
    80005226:	0a054663          	bltz	a0,800052d2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000522a:	060ab783          	ld	a5,96(s5)
    8000522e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005232:	df843783          	ld	a5,-520(s0)
    80005236:	0007c703          	lbu	a4,0(a5)
    8000523a:	cf11                	beqz	a4,80005256 <exec+0x282>
    8000523c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000523e:	02f00693          	li	a3,47
    80005242:	a039                	j	80005250 <exec+0x27c>
      last = s+1;
    80005244:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005248:	0785                	addi	a5,a5,1
    8000524a:	fff7c703          	lbu	a4,-1(a5)
    8000524e:	c701                	beqz	a4,80005256 <exec+0x282>
    if(*s == '/')
    80005250:	fed71ce3          	bne	a4,a3,80005248 <exec+0x274>
    80005254:	bfc5                	j	80005244 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005256:	4641                	li	a2,16
    80005258:	df843583          	ld	a1,-520(s0)
    8000525c:	160a8513          	addi	a0,s5,352
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	bd2080e7          	jalr	-1070(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80005268:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    8000526c:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005270:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005274:	060ab783          	ld	a5,96(s5)
    80005278:	e6843703          	ld	a4,-408(s0)
    8000527c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000527e:	060ab783          	ld	a5,96(s5)
    80005282:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005286:	85ea                	mv	a1,s10
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	8fc080e7          	jalr	-1796(ra) # 80001b84 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005290:	0004851b          	sext.w	a0,s1
    80005294:	bbe1                	j	8000506c <exec+0x98>
    80005296:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000529a:	e0843583          	ld	a1,-504(s0)
    8000529e:	855e                	mv	a0,s7
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	8e4080e7          	jalr	-1820(ra) # 80001b84 <proc_freepagetable>
  if(ip){
    800052a8:	da0498e3          	bnez	s1,80005058 <exec+0x84>
  return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	bb7d                	j	8000506c <exec+0x98>
    800052b0:	e1243423          	sd	s2,-504(s0)
    800052b4:	b7dd                	j	8000529a <exec+0x2c6>
    800052b6:	e1243423          	sd	s2,-504(s0)
    800052ba:	b7c5                	j	8000529a <exec+0x2c6>
    800052bc:	e1243423          	sd	s2,-504(s0)
    800052c0:	bfe9                	j	8000529a <exec+0x2c6>
  sz = sz1;
    800052c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052c6:	4481                	li	s1,0
    800052c8:	bfc9                	j	8000529a <exec+0x2c6>
  sz = sz1;
    800052ca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052ce:	4481                	li	s1,0
    800052d0:	b7e9                	j	8000529a <exec+0x2c6>
  sz = sz1;
    800052d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052d6:	4481                	li	s1,0
    800052d8:	b7c9                	j	8000529a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052da:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052de:	2b05                	addiw	s6,s6,1
    800052e0:	0389899b          	addiw	s3,s3,56
    800052e4:	e8845783          	lhu	a5,-376(s0)
    800052e8:	e2fb5be3          	bge	s6,a5,8000511e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052ec:	2981                	sext.w	s3,s3
    800052ee:	03800713          	li	a4,56
    800052f2:	86ce                	mv	a3,s3
    800052f4:	e1840613          	addi	a2,s0,-488
    800052f8:	4581                	li	a1,0
    800052fa:	8526                	mv	a0,s1
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	a8e080e7          	jalr	-1394(ra) # 80003d8a <readi>
    80005304:	03800793          	li	a5,56
    80005308:	f8f517e3          	bne	a0,a5,80005296 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000530c:	e1842783          	lw	a5,-488(s0)
    80005310:	4705                	li	a4,1
    80005312:	fce796e3          	bne	a5,a4,800052de <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005316:	e4043603          	ld	a2,-448(s0)
    8000531a:	e3843783          	ld	a5,-456(s0)
    8000531e:	f8f669e3          	bltu	a2,a5,800052b0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005322:	e2843783          	ld	a5,-472(s0)
    80005326:	963e                	add	a2,a2,a5
    80005328:	f8f667e3          	bltu	a2,a5,800052b6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000532c:	85ca                	mv	a1,s2
    8000532e:	855e                	mv	a0,s7
    80005330:	ffffc097          	auipc	ra,0xffffc
    80005334:	0f2080e7          	jalr	242(ra) # 80001422 <uvmalloc>
    80005338:	e0a43423          	sd	a0,-504(s0)
    8000533c:	d141                	beqz	a0,800052bc <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000533e:	e2843d03          	ld	s10,-472(s0)
    80005342:	df043783          	ld	a5,-528(s0)
    80005346:	00fd77b3          	and	a5,s10,a5
    8000534a:	fba1                	bnez	a5,8000529a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000534c:	e2042d83          	lw	s11,-480(s0)
    80005350:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005354:	f80c03e3          	beqz	s8,800052da <exec+0x306>
    80005358:	8a62                	mv	s4,s8
    8000535a:	4901                	li	s2,0
    8000535c:	b345                	j	800050fc <exec+0x128>

000000008000535e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000535e:	7179                	addi	sp,sp,-48
    80005360:	f406                	sd	ra,40(sp)
    80005362:	f022                	sd	s0,32(sp)
    80005364:	ec26                	sd	s1,24(sp)
    80005366:	e84a                	sd	s2,16(sp)
    80005368:	1800                	addi	s0,sp,48
    8000536a:	892e                	mv	s2,a1
    8000536c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000536e:	fdc40593          	addi	a1,s0,-36
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	ba6080e7          	jalr	-1114(ra) # 80002f18 <argint>
    8000537a:	04054063          	bltz	a0,800053ba <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000537e:	fdc42703          	lw	a4,-36(s0)
    80005382:	47bd                	li	a5,15
    80005384:	02e7ed63          	bltu	a5,a4,800053be <argfd+0x60>
    80005388:	ffffc097          	auipc	ra,0xffffc
    8000538c:	656080e7          	jalr	1622(ra) # 800019de <myproc>
    80005390:	fdc42703          	lw	a4,-36(s0)
    80005394:	01a70793          	addi	a5,a4,26
    80005398:	078e                	slli	a5,a5,0x3
    8000539a:	953e                	add	a0,a0,a5
    8000539c:	651c                	ld	a5,8(a0)
    8000539e:	c395                	beqz	a5,800053c2 <argfd+0x64>
    return -1;
  if(pfd)
    800053a0:	00090463          	beqz	s2,800053a8 <argfd+0x4a>
    *pfd = fd;
    800053a4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053a8:	4501                	li	a0,0
  if(pf)
    800053aa:	c091                	beqz	s1,800053ae <argfd+0x50>
    *pf = f;
    800053ac:	e09c                	sd	a5,0(s1)
}
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	64e2                	ld	s1,24(sp)
    800053b4:	6942                	ld	s2,16(sp)
    800053b6:	6145                	addi	sp,sp,48
    800053b8:	8082                	ret
    return -1;
    800053ba:	557d                	li	a0,-1
    800053bc:	bfcd                	j	800053ae <argfd+0x50>
    return -1;
    800053be:	557d                	li	a0,-1
    800053c0:	b7fd                	j	800053ae <argfd+0x50>
    800053c2:	557d                	li	a0,-1
    800053c4:	b7ed                	j	800053ae <argfd+0x50>

00000000800053c6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053c6:	1101                	addi	sp,sp,-32
    800053c8:	ec06                	sd	ra,24(sp)
    800053ca:	e822                	sd	s0,16(sp)
    800053cc:	e426                	sd	s1,8(sp)
    800053ce:	1000                	addi	s0,sp,32
    800053d0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	60c080e7          	jalr	1548(ra) # 800019de <myproc>
    800053da:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053dc:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    800053e0:	4501                	li	a0,0
    800053e2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053e4:	6398                	ld	a4,0(a5)
    800053e6:	cb19                	beqz	a4,800053fc <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053e8:	2505                	addiw	a0,a0,1
    800053ea:	07a1                	addi	a5,a5,8
    800053ec:	fed51ce3          	bne	a0,a3,800053e4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053f0:	557d                	li	a0,-1
}
    800053f2:	60e2                	ld	ra,24(sp)
    800053f4:	6442                	ld	s0,16(sp)
    800053f6:	64a2                	ld	s1,8(sp)
    800053f8:	6105                	addi	sp,sp,32
    800053fa:	8082                	ret
      p->ofile[fd] = f;
    800053fc:	01a50793          	addi	a5,a0,26
    80005400:	078e                	slli	a5,a5,0x3
    80005402:	963e                	add	a2,a2,a5
    80005404:	e604                	sd	s1,8(a2)
      return fd;
    80005406:	b7f5                	j	800053f2 <fdalloc+0x2c>

0000000080005408 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005408:	715d                	addi	sp,sp,-80
    8000540a:	e486                	sd	ra,72(sp)
    8000540c:	e0a2                	sd	s0,64(sp)
    8000540e:	fc26                	sd	s1,56(sp)
    80005410:	f84a                	sd	s2,48(sp)
    80005412:	f44e                	sd	s3,40(sp)
    80005414:	f052                	sd	s4,32(sp)
    80005416:	ec56                	sd	s5,24(sp)
    80005418:	0880                	addi	s0,sp,80
    8000541a:	89ae                	mv	s3,a1
    8000541c:	8ab2                	mv	s5,a2
    8000541e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005420:	fb040593          	addi	a1,s0,-80
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	e86080e7          	jalr	-378(ra) # 800042aa <nameiparent>
    8000542c:	892a                	mv	s2,a0
    8000542e:	12050f63          	beqz	a0,8000556c <create+0x164>
    return 0;

  ilock(dp);
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	6a4080e7          	jalr	1700(ra) # 80003ad6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000543a:	4601                	li	a2,0
    8000543c:	fb040593          	addi	a1,s0,-80
    80005440:	854a                	mv	a0,s2
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	b78080e7          	jalr	-1160(ra) # 80003fba <dirlookup>
    8000544a:	84aa                	mv	s1,a0
    8000544c:	c921                	beqz	a0,8000549c <create+0x94>
    iunlockput(dp);
    8000544e:	854a                	mv	a0,s2
    80005450:	fffff097          	auipc	ra,0xfffff
    80005454:	8e8080e7          	jalr	-1816(ra) # 80003d38 <iunlockput>
    ilock(ip);
    80005458:	8526                	mv	a0,s1
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	67c080e7          	jalr	1660(ra) # 80003ad6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005462:	2981                	sext.w	s3,s3
    80005464:	4789                	li	a5,2
    80005466:	02f99463          	bne	s3,a5,8000548e <create+0x86>
    8000546a:	0444d783          	lhu	a5,68(s1)
    8000546e:	37f9                	addiw	a5,a5,-2
    80005470:	17c2                	slli	a5,a5,0x30
    80005472:	93c1                	srli	a5,a5,0x30
    80005474:	4705                	li	a4,1
    80005476:	00f76c63          	bltu	a4,a5,8000548e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000547a:	8526                	mv	a0,s1
    8000547c:	60a6                	ld	ra,72(sp)
    8000547e:	6406                	ld	s0,64(sp)
    80005480:	74e2                	ld	s1,56(sp)
    80005482:	7942                	ld	s2,48(sp)
    80005484:	79a2                	ld	s3,40(sp)
    80005486:	7a02                	ld	s4,32(sp)
    80005488:	6ae2                	ld	s5,24(sp)
    8000548a:	6161                	addi	sp,sp,80
    8000548c:	8082                	ret
    iunlockput(ip);
    8000548e:	8526                	mv	a0,s1
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	8a8080e7          	jalr	-1880(ra) # 80003d38 <iunlockput>
    return 0;
    80005498:	4481                	li	s1,0
    8000549a:	b7c5                	j	8000547a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000549c:	85ce                	mv	a1,s3
    8000549e:	00092503          	lw	a0,0(s2)
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	49c080e7          	jalr	1180(ra) # 8000393e <ialloc>
    800054aa:	84aa                	mv	s1,a0
    800054ac:	c529                	beqz	a0,800054f6 <create+0xee>
  ilock(ip);
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	628080e7          	jalr	1576(ra) # 80003ad6 <ilock>
  ip->major = major;
    800054b6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054ba:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054be:	4785                	li	a5,1
    800054c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	546080e7          	jalr	1350(ra) # 80003a0c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054ce:	2981                	sext.w	s3,s3
    800054d0:	4785                	li	a5,1
    800054d2:	02f98a63          	beq	s3,a5,80005506 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054d6:	40d0                	lw	a2,4(s1)
    800054d8:	fb040593          	addi	a1,s0,-80
    800054dc:	854a                	mv	a0,s2
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	cec080e7          	jalr	-788(ra) # 800041ca <dirlink>
    800054e6:	06054b63          	bltz	a0,8000555c <create+0x154>
  iunlockput(dp);
    800054ea:	854a                	mv	a0,s2
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	84c080e7          	jalr	-1972(ra) # 80003d38 <iunlockput>
  return ip;
    800054f4:	b759                	j	8000547a <create+0x72>
    panic("create: ialloc");
    800054f6:	00003517          	auipc	a0,0x3
    800054fa:	35250513          	addi	a0,a0,850 # 80008848 <syscalls+0x2a8>
    800054fe:	ffffb097          	auipc	ra,0xffffb
    80005502:	040080e7          	jalr	64(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005506:	04a95783          	lhu	a5,74(s2)
    8000550a:	2785                	addiw	a5,a5,1
    8000550c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	4fa080e7          	jalr	1274(ra) # 80003a0c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000551a:	40d0                	lw	a2,4(s1)
    8000551c:	00003597          	auipc	a1,0x3
    80005520:	33c58593          	addi	a1,a1,828 # 80008858 <syscalls+0x2b8>
    80005524:	8526                	mv	a0,s1
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	ca4080e7          	jalr	-860(ra) # 800041ca <dirlink>
    8000552e:	00054f63          	bltz	a0,8000554c <create+0x144>
    80005532:	00492603          	lw	a2,4(s2)
    80005536:	00003597          	auipc	a1,0x3
    8000553a:	32a58593          	addi	a1,a1,810 # 80008860 <syscalls+0x2c0>
    8000553e:	8526                	mv	a0,s1
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	c8a080e7          	jalr	-886(ra) # 800041ca <dirlink>
    80005548:	f80557e3          	bgez	a0,800054d6 <create+0xce>
      panic("create dots");
    8000554c:	00003517          	auipc	a0,0x3
    80005550:	31c50513          	addi	a0,a0,796 # 80008868 <syscalls+0x2c8>
    80005554:	ffffb097          	auipc	ra,0xffffb
    80005558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000555c:	00003517          	auipc	a0,0x3
    80005560:	31c50513          	addi	a0,a0,796 # 80008878 <syscalls+0x2d8>
    80005564:	ffffb097          	auipc	ra,0xffffb
    80005568:	fda080e7          	jalr	-38(ra) # 8000053e <panic>
    return 0;
    8000556c:	84aa                	mv	s1,a0
    8000556e:	b731                	j	8000547a <create+0x72>

0000000080005570 <sys_dup>:
{
    80005570:	7179                	addi	sp,sp,-48
    80005572:	f406                	sd	ra,40(sp)
    80005574:	f022                	sd	s0,32(sp)
    80005576:	ec26                	sd	s1,24(sp)
    80005578:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000557a:	fd840613          	addi	a2,s0,-40
    8000557e:	4581                	li	a1,0
    80005580:	4501                	li	a0,0
    80005582:	00000097          	auipc	ra,0x0
    80005586:	ddc080e7          	jalr	-548(ra) # 8000535e <argfd>
    return -1;
    8000558a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000558c:	02054363          	bltz	a0,800055b2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005590:	fd843503          	ld	a0,-40(s0)
    80005594:	00000097          	auipc	ra,0x0
    80005598:	e32080e7          	jalr	-462(ra) # 800053c6 <fdalloc>
    8000559c:	84aa                	mv	s1,a0
    return -1;
    8000559e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055a0:	00054963          	bltz	a0,800055b2 <sys_dup+0x42>
  filedup(f);
    800055a4:	fd843503          	ld	a0,-40(s0)
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	37a080e7          	jalr	890(ra) # 80004922 <filedup>
  return fd;
    800055b0:	87a6                	mv	a5,s1
}
    800055b2:	853e                	mv	a0,a5
    800055b4:	70a2                	ld	ra,40(sp)
    800055b6:	7402                	ld	s0,32(sp)
    800055b8:	64e2                	ld	s1,24(sp)
    800055ba:	6145                	addi	sp,sp,48
    800055bc:	8082                	ret

00000000800055be <sys_read>:
{
    800055be:	7179                	addi	sp,sp,-48
    800055c0:	f406                	sd	ra,40(sp)
    800055c2:	f022                	sd	s0,32(sp)
    800055c4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c6:	fe840613          	addi	a2,s0,-24
    800055ca:	4581                	li	a1,0
    800055cc:	4501                	li	a0,0
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	d90080e7          	jalr	-624(ra) # 8000535e <argfd>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d8:	04054163          	bltz	a0,8000561a <sys_read+0x5c>
    800055dc:	fe440593          	addi	a1,s0,-28
    800055e0:	4509                	li	a0,2
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	936080e7          	jalr	-1738(ra) # 80002f18 <argint>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ec:	02054763          	bltz	a0,8000561a <sys_read+0x5c>
    800055f0:	fd840593          	addi	a1,s0,-40
    800055f4:	4505                	li	a0,1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	944080e7          	jalr	-1724(ra) # 80002f3a <argaddr>
    return -1;
    800055fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005600:	00054d63          	bltz	a0,8000561a <sys_read+0x5c>
  return fileread(f, p, n);
    80005604:	fe442603          	lw	a2,-28(s0)
    80005608:	fd843583          	ld	a1,-40(s0)
    8000560c:	fe843503          	ld	a0,-24(s0)
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	49e080e7          	jalr	1182(ra) # 80004aae <fileread>
    80005618:	87aa                	mv	a5,a0
}
    8000561a:	853e                	mv	a0,a5
    8000561c:	70a2                	ld	ra,40(sp)
    8000561e:	7402                	ld	s0,32(sp)
    80005620:	6145                	addi	sp,sp,48
    80005622:	8082                	ret

0000000080005624 <sys_write>:
{
    80005624:	7179                	addi	sp,sp,-48
    80005626:	f406                	sd	ra,40(sp)
    80005628:	f022                	sd	s0,32(sp)
    8000562a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000562c:	fe840613          	addi	a2,s0,-24
    80005630:	4581                	li	a1,0
    80005632:	4501                	li	a0,0
    80005634:	00000097          	auipc	ra,0x0
    80005638:	d2a080e7          	jalr	-726(ra) # 8000535e <argfd>
    return -1;
    8000563c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000563e:	04054163          	bltz	a0,80005680 <sys_write+0x5c>
    80005642:	fe440593          	addi	a1,s0,-28
    80005646:	4509                	li	a0,2
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	8d0080e7          	jalr	-1840(ra) # 80002f18 <argint>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005652:	02054763          	bltz	a0,80005680 <sys_write+0x5c>
    80005656:	fd840593          	addi	a1,s0,-40
    8000565a:	4505                	li	a0,1
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	8de080e7          	jalr	-1826(ra) # 80002f3a <argaddr>
    return -1;
    80005664:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005666:	00054d63          	bltz	a0,80005680 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000566a:	fe442603          	lw	a2,-28(s0)
    8000566e:	fd843583          	ld	a1,-40(s0)
    80005672:	fe843503          	ld	a0,-24(s0)
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	4fa080e7          	jalr	1274(ra) # 80004b70 <filewrite>
    8000567e:	87aa                	mv	a5,a0
}
    80005680:	853e                	mv	a0,a5
    80005682:	70a2                	ld	ra,40(sp)
    80005684:	7402                	ld	s0,32(sp)
    80005686:	6145                	addi	sp,sp,48
    80005688:	8082                	ret

000000008000568a <sys_close>:
{
    8000568a:	1101                	addi	sp,sp,-32
    8000568c:	ec06                	sd	ra,24(sp)
    8000568e:	e822                	sd	s0,16(sp)
    80005690:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005692:	fe040613          	addi	a2,s0,-32
    80005696:	fec40593          	addi	a1,s0,-20
    8000569a:	4501                	li	a0,0
    8000569c:	00000097          	auipc	ra,0x0
    800056a0:	cc2080e7          	jalr	-830(ra) # 8000535e <argfd>
    return -1;
    800056a4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056a6:	02054463          	bltz	a0,800056ce <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056aa:	ffffc097          	auipc	ra,0xffffc
    800056ae:	334080e7          	jalr	820(ra) # 800019de <myproc>
    800056b2:	fec42783          	lw	a5,-20(s0)
    800056b6:	07e9                	addi	a5,a5,26
    800056b8:	078e                	slli	a5,a5,0x3
    800056ba:	97aa                	add	a5,a5,a0
    800056bc:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800056c0:	fe043503          	ld	a0,-32(s0)
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	2b0080e7          	jalr	688(ra) # 80004974 <fileclose>
  return 0;
    800056cc:	4781                	li	a5,0
}
    800056ce:	853e                	mv	a0,a5
    800056d0:	60e2                	ld	ra,24(sp)
    800056d2:	6442                	ld	s0,16(sp)
    800056d4:	6105                	addi	sp,sp,32
    800056d6:	8082                	ret

00000000800056d8 <sys_fstat>:
{
    800056d8:	1101                	addi	sp,sp,-32
    800056da:	ec06                	sd	ra,24(sp)
    800056dc:	e822                	sd	s0,16(sp)
    800056de:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056e0:	fe840613          	addi	a2,s0,-24
    800056e4:	4581                	li	a1,0
    800056e6:	4501                	li	a0,0
    800056e8:	00000097          	auipc	ra,0x0
    800056ec:	c76080e7          	jalr	-906(ra) # 8000535e <argfd>
    return -1;
    800056f0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056f2:	02054563          	bltz	a0,8000571c <sys_fstat+0x44>
    800056f6:	fe040593          	addi	a1,s0,-32
    800056fa:	4505                	li	a0,1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	83e080e7          	jalr	-1986(ra) # 80002f3a <argaddr>
    return -1;
    80005704:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005706:	00054b63          	bltz	a0,8000571c <sys_fstat+0x44>
  return filestat(f, st);
    8000570a:	fe043583          	ld	a1,-32(s0)
    8000570e:	fe843503          	ld	a0,-24(s0)
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	32a080e7          	jalr	810(ra) # 80004a3c <filestat>
    8000571a:	87aa                	mv	a5,a0
}
    8000571c:	853e                	mv	a0,a5
    8000571e:	60e2                	ld	ra,24(sp)
    80005720:	6442                	ld	s0,16(sp)
    80005722:	6105                	addi	sp,sp,32
    80005724:	8082                	ret

0000000080005726 <sys_link>:
{
    80005726:	7169                	addi	sp,sp,-304
    80005728:	f606                	sd	ra,296(sp)
    8000572a:	f222                	sd	s0,288(sp)
    8000572c:	ee26                	sd	s1,280(sp)
    8000572e:	ea4a                	sd	s2,272(sp)
    80005730:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005732:	08000613          	li	a2,128
    80005736:	ed040593          	addi	a1,s0,-304
    8000573a:	4501                	li	a0,0
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	820080e7          	jalr	-2016(ra) # 80002f5c <argstr>
    return -1;
    80005744:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005746:	10054e63          	bltz	a0,80005862 <sys_link+0x13c>
    8000574a:	08000613          	li	a2,128
    8000574e:	f5040593          	addi	a1,s0,-176
    80005752:	4505                	li	a0,1
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	808080e7          	jalr	-2040(ra) # 80002f5c <argstr>
    return -1;
    8000575c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000575e:	10054263          	bltz	a0,80005862 <sys_link+0x13c>
  begin_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	d46080e7          	jalr	-698(ra) # 800044a8 <begin_op>
  if((ip = namei(old)) == 0){
    8000576a:	ed040513          	addi	a0,s0,-304
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	b1e080e7          	jalr	-1250(ra) # 8000428c <namei>
    80005776:	84aa                	mv	s1,a0
    80005778:	c551                	beqz	a0,80005804 <sys_link+0xde>
  ilock(ip);
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	35c080e7          	jalr	860(ra) # 80003ad6 <ilock>
  if(ip->type == T_DIR){
    80005782:	04449703          	lh	a4,68(s1)
    80005786:	4785                	li	a5,1
    80005788:	08f70463          	beq	a4,a5,80005810 <sys_link+0xea>
  ip->nlink++;
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	2785                	addiw	a5,a5,1
    80005792:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	274080e7          	jalr	628(ra) # 80003a0c <iupdate>
  iunlock(ip);
    800057a0:	8526                	mv	a0,s1
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	3f6080e7          	jalr	1014(ra) # 80003b98 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057aa:	fd040593          	addi	a1,s0,-48
    800057ae:	f5040513          	addi	a0,s0,-176
    800057b2:	fffff097          	auipc	ra,0xfffff
    800057b6:	af8080e7          	jalr	-1288(ra) # 800042aa <nameiparent>
    800057ba:	892a                	mv	s2,a0
    800057bc:	c935                	beqz	a0,80005830 <sys_link+0x10a>
  ilock(dp);
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	318080e7          	jalr	792(ra) # 80003ad6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057c6:	00092703          	lw	a4,0(s2)
    800057ca:	409c                	lw	a5,0(s1)
    800057cc:	04f71d63          	bne	a4,a5,80005826 <sys_link+0x100>
    800057d0:	40d0                	lw	a2,4(s1)
    800057d2:	fd040593          	addi	a1,s0,-48
    800057d6:	854a                	mv	a0,s2
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	9f2080e7          	jalr	-1550(ra) # 800041ca <dirlink>
    800057e0:	04054363          	bltz	a0,80005826 <sys_link+0x100>
  iunlockput(dp);
    800057e4:	854a                	mv	a0,s2
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	552080e7          	jalr	1362(ra) # 80003d38 <iunlockput>
  iput(ip);
    800057ee:	8526                	mv	a0,s1
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	4a0080e7          	jalr	1184(ra) # 80003c90 <iput>
  end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	d30080e7          	jalr	-720(ra) # 80004528 <end_op>
  return 0;
    80005800:	4781                	li	a5,0
    80005802:	a085                	j	80005862 <sys_link+0x13c>
    end_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	d24080e7          	jalr	-732(ra) # 80004528 <end_op>
    return -1;
    8000580c:	57fd                	li	a5,-1
    8000580e:	a891                	j	80005862 <sys_link+0x13c>
    iunlockput(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	526080e7          	jalr	1318(ra) # 80003d38 <iunlockput>
    end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	d0e080e7          	jalr	-754(ra) # 80004528 <end_op>
    return -1;
    80005822:	57fd                	li	a5,-1
    80005824:	a83d                	j	80005862 <sys_link+0x13c>
    iunlockput(dp);
    80005826:	854a                	mv	a0,s2
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	510080e7          	jalr	1296(ra) # 80003d38 <iunlockput>
  ilock(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	2a4080e7          	jalr	676(ra) # 80003ad6 <ilock>
  ip->nlink--;
    8000583a:	04a4d783          	lhu	a5,74(s1)
    8000583e:	37fd                	addiw	a5,a5,-1
    80005840:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	1c6080e7          	jalr	454(ra) # 80003a0c <iupdate>
  iunlockput(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	4e8080e7          	jalr	1256(ra) # 80003d38 <iunlockput>
  end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	cd0080e7          	jalr	-816(ra) # 80004528 <end_op>
  return -1;
    80005860:	57fd                	li	a5,-1
}
    80005862:	853e                	mv	a0,a5
    80005864:	70b2                	ld	ra,296(sp)
    80005866:	7412                	ld	s0,288(sp)
    80005868:	64f2                	ld	s1,280(sp)
    8000586a:	6952                	ld	s2,272(sp)
    8000586c:	6155                	addi	sp,sp,304
    8000586e:	8082                	ret

0000000080005870 <sys_unlink>:
{
    80005870:	7151                	addi	sp,sp,-240
    80005872:	f586                	sd	ra,232(sp)
    80005874:	f1a2                	sd	s0,224(sp)
    80005876:	eda6                	sd	s1,216(sp)
    80005878:	e9ca                	sd	s2,208(sp)
    8000587a:	e5ce                	sd	s3,200(sp)
    8000587c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000587e:	08000613          	li	a2,128
    80005882:	f3040593          	addi	a1,s0,-208
    80005886:	4501                	li	a0,0
    80005888:	ffffd097          	auipc	ra,0xffffd
    8000588c:	6d4080e7          	jalr	1748(ra) # 80002f5c <argstr>
    80005890:	18054163          	bltz	a0,80005a12 <sys_unlink+0x1a2>
  begin_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	c14080e7          	jalr	-1004(ra) # 800044a8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000589c:	fb040593          	addi	a1,s0,-80
    800058a0:	f3040513          	addi	a0,s0,-208
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	a06080e7          	jalr	-1530(ra) # 800042aa <nameiparent>
    800058ac:	84aa                	mv	s1,a0
    800058ae:	c979                	beqz	a0,80005984 <sys_unlink+0x114>
  ilock(dp);
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	226080e7          	jalr	550(ra) # 80003ad6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058b8:	00003597          	auipc	a1,0x3
    800058bc:	fa058593          	addi	a1,a1,-96 # 80008858 <syscalls+0x2b8>
    800058c0:	fb040513          	addi	a0,s0,-80
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	6dc080e7          	jalr	1756(ra) # 80003fa0 <namecmp>
    800058cc:	14050a63          	beqz	a0,80005a20 <sys_unlink+0x1b0>
    800058d0:	00003597          	auipc	a1,0x3
    800058d4:	f9058593          	addi	a1,a1,-112 # 80008860 <syscalls+0x2c0>
    800058d8:	fb040513          	addi	a0,s0,-80
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	6c4080e7          	jalr	1732(ra) # 80003fa0 <namecmp>
    800058e4:	12050e63          	beqz	a0,80005a20 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058e8:	f2c40613          	addi	a2,s0,-212
    800058ec:	fb040593          	addi	a1,s0,-80
    800058f0:	8526                	mv	a0,s1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	6c8080e7          	jalr	1736(ra) # 80003fba <dirlookup>
    800058fa:	892a                	mv	s2,a0
    800058fc:	12050263          	beqz	a0,80005a20 <sys_unlink+0x1b0>
  ilock(ip);
    80005900:	ffffe097          	auipc	ra,0xffffe
    80005904:	1d6080e7          	jalr	470(ra) # 80003ad6 <ilock>
  if(ip->nlink < 1)
    80005908:	04a91783          	lh	a5,74(s2)
    8000590c:	08f05263          	blez	a5,80005990 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005910:	04491703          	lh	a4,68(s2)
    80005914:	4785                	li	a5,1
    80005916:	08f70563          	beq	a4,a5,800059a0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000591a:	4641                	li	a2,16
    8000591c:	4581                	li	a1,0
    8000591e:	fc040513          	addi	a0,s0,-64
    80005922:	ffffb097          	auipc	ra,0xffffb
    80005926:	3be080e7          	jalr	958(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000592a:	4741                	li	a4,16
    8000592c:	f2c42683          	lw	a3,-212(s0)
    80005930:	fc040613          	addi	a2,s0,-64
    80005934:	4581                	li	a1,0
    80005936:	8526                	mv	a0,s1
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	54a080e7          	jalr	1354(ra) # 80003e82 <writei>
    80005940:	47c1                	li	a5,16
    80005942:	0af51563          	bne	a0,a5,800059ec <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005946:	04491703          	lh	a4,68(s2)
    8000594a:	4785                	li	a5,1
    8000594c:	0af70863          	beq	a4,a5,800059fc <sys_unlink+0x18c>
  iunlockput(dp);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	3e6080e7          	jalr	998(ra) # 80003d38 <iunlockput>
  ip->nlink--;
    8000595a:	04a95783          	lhu	a5,74(s2)
    8000595e:	37fd                	addiw	a5,a5,-1
    80005960:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005964:	854a                	mv	a0,s2
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	0a6080e7          	jalr	166(ra) # 80003a0c <iupdate>
  iunlockput(ip);
    8000596e:	854a                	mv	a0,s2
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	3c8080e7          	jalr	968(ra) # 80003d38 <iunlockput>
  end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	bb0080e7          	jalr	-1104(ra) # 80004528 <end_op>
  return 0;
    80005980:	4501                	li	a0,0
    80005982:	a84d                	j	80005a34 <sys_unlink+0x1c4>
    end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	ba4080e7          	jalr	-1116(ra) # 80004528 <end_op>
    return -1;
    8000598c:	557d                	li	a0,-1
    8000598e:	a05d                	j	80005a34 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005990:	00003517          	auipc	a0,0x3
    80005994:	ef850513          	addi	a0,a0,-264 # 80008888 <syscalls+0x2e8>
    80005998:	ffffb097          	auipc	ra,0xffffb
    8000599c:	ba6080e7          	jalr	-1114(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059a0:	04c92703          	lw	a4,76(s2)
    800059a4:	02000793          	li	a5,32
    800059a8:	f6e7f9e3          	bgeu	a5,a4,8000591a <sys_unlink+0xaa>
    800059ac:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059b0:	4741                	li	a4,16
    800059b2:	86ce                	mv	a3,s3
    800059b4:	f1840613          	addi	a2,s0,-232
    800059b8:	4581                	li	a1,0
    800059ba:	854a                	mv	a0,s2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	3ce080e7          	jalr	974(ra) # 80003d8a <readi>
    800059c4:	47c1                	li	a5,16
    800059c6:	00f51b63          	bne	a0,a5,800059dc <sys_unlink+0x16c>
    if(de.inum != 0)
    800059ca:	f1845783          	lhu	a5,-232(s0)
    800059ce:	e7a1                	bnez	a5,80005a16 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059d0:	29c1                	addiw	s3,s3,16
    800059d2:	04c92783          	lw	a5,76(s2)
    800059d6:	fcf9ede3          	bltu	s3,a5,800059b0 <sys_unlink+0x140>
    800059da:	b781                	j	8000591a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059dc:	00003517          	auipc	a0,0x3
    800059e0:	ec450513          	addi	a0,a0,-316 # 800088a0 <syscalls+0x300>
    800059e4:	ffffb097          	auipc	ra,0xffffb
    800059e8:	b5a080e7          	jalr	-1190(ra) # 8000053e <panic>
    panic("unlink: writei");
    800059ec:	00003517          	auipc	a0,0x3
    800059f0:	ecc50513          	addi	a0,a0,-308 # 800088b8 <syscalls+0x318>
    800059f4:	ffffb097          	auipc	ra,0xffffb
    800059f8:	b4a080e7          	jalr	-1206(ra) # 8000053e <panic>
    dp->nlink--;
    800059fc:	04a4d783          	lhu	a5,74(s1)
    80005a00:	37fd                	addiw	a5,a5,-1
    80005a02:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	004080e7          	jalr	4(ra) # 80003a0c <iupdate>
    80005a10:	b781                	j	80005950 <sys_unlink+0xe0>
    return -1;
    80005a12:	557d                	li	a0,-1
    80005a14:	a005                	j	80005a34 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a16:	854a                	mv	a0,s2
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	320080e7          	jalr	800(ra) # 80003d38 <iunlockput>
  iunlockput(dp);
    80005a20:	8526                	mv	a0,s1
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	316080e7          	jalr	790(ra) # 80003d38 <iunlockput>
  end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	afe080e7          	jalr	-1282(ra) # 80004528 <end_op>
  return -1;
    80005a32:	557d                	li	a0,-1
}
    80005a34:	70ae                	ld	ra,232(sp)
    80005a36:	740e                	ld	s0,224(sp)
    80005a38:	64ee                	ld	s1,216(sp)
    80005a3a:	694e                	ld	s2,208(sp)
    80005a3c:	69ae                	ld	s3,200(sp)
    80005a3e:	616d                	addi	sp,sp,240
    80005a40:	8082                	ret

0000000080005a42 <sys_open>:

uint64
sys_open(void)
{
    80005a42:	7131                	addi	sp,sp,-192
    80005a44:	fd06                	sd	ra,184(sp)
    80005a46:	f922                	sd	s0,176(sp)
    80005a48:	f526                	sd	s1,168(sp)
    80005a4a:	f14a                	sd	s2,160(sp)
    80005a4c:	ed4e                	sd	s3,152(sp)
    80005a4e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a50:	08000613          	li	a2,128
    80005a54:	f5040593          	addi	a1,s0,-176
    80005a58:	4501                	li	a0,0
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	502080e7          	jalr	1282(ra) # 80002f5c <argstr>
    return -1;
    80005a62:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a64:	0c054163          	bltz	a0,80005b26 <sys_open+0xe4>
    80005a68:	f4c40593          	addi	a1,s0,-180
    80005a6c:	4505                	li	a0,1
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	4aa080e7          	jalr	1194(ra) # 80002f18 <argint>
    80005a76:	0a054863          	bltz	a0,80005b26 <sys_open+0xe4>

  begin_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	a2e080e7          	jalr	-1490(ra) # 800044a8 <begin_op>

  if(omode & O_CREATE){
    80005a82:	f4c42783          	lw	a5,-180(s0)
    80005a86:	2007f793          	andi	a5,a5,512
    80005a8a:	cbdd                	beqz	a5,80005b40 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a8c:	4681                	li	a3,0
    80005a8e:	4601                	li	a2,0
    80005a90:	4589                	li	a1,2
    80005a92:	f5040513          	addi	a0,s0,-176
    80005a96:	00000097          	auipc	ra,0x0
    80005a9a:	972080e7          	jalr	-1678(ra) # 80005408 <create>
    80005a9e:	892a                	mv	s2,a0
    if(ip == 0){
    80005aa0:	c959                	beqz	a0,80005b36 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005aa2:	04491703          	lh	a4,68(s2)
    80005aa6:	478d                	li	a5,3
    80005aa8:	00f71763          	bne	a4,a5,80005ab6 <sys_open+0x74>
    80005aac:	04695703          	lhu	a4,70(s2)
    80005ab0:	47a5                	li	a5,9
    80005ab2:	0ce7ec63          	bltu	a5,a4,80005b8a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	e02080e7          	jalr	-510(ra) # 800048b8 <filealloc>
    80005abe:	89aa                	mv	s3,a0
    80005ac0:	10050263          	beqz	a0,80005bc4 <sys_open+0x182>
    80005ac4:	00000097          	auipc	ra,0x0
    80005ac8:	902080e7          	jalr	-1790(ra) # 800053c6 <fdalloc>
    80005acc:	84aa                	mv	s1,a0
    80005ace:	0e054663          	bltz	a0,80005bba <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ad2:	04491703          	lh	a4,68(s2)
    80005ad6:	478d                	li	a5,3
    80005ad8:	0cf70463          	beq	a4,a5,80005ba0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005adc:	4789                	li	a5,2
    80005ade:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005ae2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ae6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005aea:	f4c42783          	lw	a5,-180(s0)
    80005aee:	0017c713          	xori	a4,a5,1
    80005af2:	8b05                	andi	a4,a4,1
    80005af4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005af8:	0037f713          	andi	a4,a5,3
    80005afc:	00e03733          	snez	a4,a4
    80005b00:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b04:	4007f793          	andi	a5,a5,1024
    80005b08:	c791                	beqz	a5,80005b14 <sys_open+0xd2>
    80005b0a:	04491703          	lh	a4,68(s2)
    80005b0e:	4789                	li	a5,2
    80005b10:	08f70f63          	beq	a4,a5,80005bae <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b14:	854a                	mv	a0,s2
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	082080e7          	jalr	130(ra) # 80003b98 <iunlock>
  end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	a0a080e7          	jalr	-1526(ra) # 80004528 <end_op>

  return fd;
}
    80005b26:	8526                	mv	a0,s1
    80005b28:	70ea                	ld	ra,184(sp)
    80005b2a:	744a                	ld	s0,176(sp)
    80005b2c:	74aa                	ld	s1,168(sp)
    80005b2e:	790a                	ld	s2,160(sp)
    80005b30:	69ea                	ld	s3,152(sp)
    80005b32:	6129                	addi	sp,sp,192
    80005b34:	8082                	ret
      end_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	9f2080e7          	jalr	-1550(ra) # 80004528 <end_op>
      return -1;
    80005b3e:	b7e5                	j	80005b26 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b40:	f5040513          	addi	a0,s0,-176
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	748080e7          	jalr	1864(ra) # 8000428c <namei>
    80005b4c:	892a                	mv	s2,a0
    80005b4e:	c905                	beqz	a0,80005b7e <sys_open+0x13c>
    ilock(ip);
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	f86080e7          	jalr	-122(ra) # 80003ad6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b58:	04491703          	lh	a4,68(s2)
    80005b5c:	4785                	li	a5,1
    80005b5e:	f4f712e3          	bne	a4,a5,80005aa2 <sys_open+0x60>
    80005b62:	f4c42783          	lw	a5,-180(s0)
    80005b66:	dba1                	beqz	a5,80005ab6 <sys_open+0x74>
      iunlockput(ip);
    80005b68:	854a                	mv	a0,s2
    80005b6a:	ffffe097          	auipc	ra,0xffffe
    80005b6e:	1ce080e7          	jalr	462(ra) # 80003d38 <iunlockput>
      end_op();
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	9b6080e7          	jalr	-1610(ra) # 80004528 <end_op>
      return -1;
    80005b7a:	54fd                	li	s1,-1
    80005b7c:	b76d                	j	80005b26 <sys_open+0xe4>
      end_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	9aa080e7          	jalr	-1622(ra) # 80004528 <end_op>
      return -1;
    80005b86:	54fd                	li	s1,-1
    80005b88:	bf79                	j	80005b26 <sys_open+0xe4>
    iunlockput(ip);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	1ac080e7          	jalr	428(ra) # 80003d38 <iunlockput>
    end_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	994080e7          	jalr	-1644(ra) # 80004528 <end_op>
    return -1;
    80005b9c:	54fd                	li	s1,-1
    80005b9e:	b761                	j	80005b26 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ba0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ba4:	04691783          	lh	a5,70(s2)
    80005ba8:	02f99223          	sh	a5,36(s3)
    80005bac:	bf2d                	j	80005ae6 <sys_open+0xa4>
    itrunc(ip);
    80005bae:	854a                	mv	a0,s2
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	034080e7          	jalr	52(ra) # 80003be4 <itrunc>
    80005bb8:	bfb1                	j	80005b14 <sys_open+0xd2>
      fileclose(f);
    80005bba:	854e                	mv	a0,s3
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	db8080e7          	jalr	-584(ra) # 80004974 <fileclose>
    iunlockput(ip);
    80005bc4:	854a                	mv	a0,s2
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	172080e7          	jalr	370(ra) # 80003d38 <iunlockput>
    end_op();
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	95a080e7          	jalr	-1702(ra) # 80004528 <end_op>
    return -1;
    80005bd6:	54fd                	li	s1,-1
    80005bd8:	b7b9                	j	80005b26 <sys_open+0xe4>

0000000080005bda <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bda:	7175                	addi	sp,sp,-144
    80005bdc:	e506                	sd	ra,136(sp)
    80005bde:	e122                	sd	s0,128(sp)
    80005be0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005be2:	fffff097          	auipc	ra,0xfffff
    80005be6:	8c6080e7          	jalr	-1850(ra) # 800044a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bea:	08000613          	li	a2,128
    80005bee:	f7040593          	addi	a1,s0,-144
    80005bf2:	4501                	li	a0,0
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	368080e7          	jalr	872(ra) # 80002f5c <argstr>
    80005bfc:	02054963          	bltz	a0,80005c2e <sys_mkdir+0x54>
    80005c00:	4681                	li	a3,0
    80005c02:	4601                	li	a2,0
    80005c04:	4585                	li	a1,1
    80005c06:	f7040513          	addi	a0,s0,-144
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	7fe080e7          	jalr	2046(ra) # 80005408 <create>
    80005c12:	cd11                	beqz	a0,80005c2e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	124080e7          	jalr	292(ra) # 80003d38 <iunlockput>
  end_op();
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	90c080e7          	jalr	-1780(ra) # 80004528 <end_op>
  return 0;
    80005c24:	4501                	li	a0,0
}
    80005c26:	60aa                	ld	ra,136(sp)
    80005c28:	640a                	ld	s0,128(sp)
    80005c2a:	6149                	addi	sp,sp,144
    80005c2c:	8082                	ret
    end_op();
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	8fa080e7          	jalr	-1798(ra) # 80004528 <end_op>
    return -1;
    80005c36:	557d                	li	a0,-1
    80005c38:	b7fd                	j	80005c26 <sys_mkdir+0x4c>

0000000080005c3a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c3a:	7135                	addi	sp,sp,-160
    80005c3c:	ed06                	sd	ra,152(sp)
    80005c3e:	e922                	sd	s0,144(sp)
    80005c40:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	866080e7          	jalr	-1946(ra) # 800044a8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c4a:	08000613          	li	a2,128
    80005c4e:	f7040593          	addi	a1,s0,-144
    80005c52:	4501                	li	a0,0
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	308080e7          	jalr	776(ra) # 80002f5c <argstr>
    80005c5c:	04054a63          	bltz	a0,80005cb0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c60:	f6c40593          	addi	a1,s0,-148
    80005c64:	4505                	li	a0,1
    80005c66:	ffffd097          	auipc	ra,0xffffd
    80005c6a:	2b2080e7          	jalr	690(ra) # 80002f18 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c6e:	04054163          	bltz	a0,80005cb0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c72:	f6840593          	addi	a1,s0,-152
    80005c76:	4509                	li	a0,2
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	2a0080e7          	jalr	672(ra) # 80002f18 <argint>
     argint(1, &major) < 0 ||
    80005c80:	02054863          	bltz	a0,80005cb0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c84:	f6841683          	lh	a3,-152(s0)
    80005c88:	f6c41603          	lh	a2,-148(s0)
    80005c8c:	458d                	li	a1,3
    80005c8e:	f7040513          	addi	a0,s0,-144
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	776080e7          	jalr	1910(ra) # 80005408 <create>
     argint(2, &minor) < 0 ||
    80005c9a:	c919                	beqz	a0,80005cb0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c9c:	ffffe097          	auipc	ra,0xffffe
    80005ca0:	09c080e7          	jalr	156(ra) # 80003d38 <iunlockput>
  end_op();
    80005ca4:	fffff097          	auipc	ra,0xfffff
    80005ca8:	884080e7          	jalr	-1916(ra) # 80004528 <end_op>
  return 0;
    80005cac:	4501                	li	a0,0
    80005cae:	a031                	j	80005cba <sys_mknod+0x80>
    end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	878080e7          	jalr	-1928(ra) # 80004528 <end_op>
    return -1;
    80005cb8:	557d                	li	a0,-1
}
    80005cba:	60ea                	ld	ra,152(sp)
    80005cbc:	644a                	ld	s0,144(sp)
    80005cbe:	610d                	addi	sp,sp,160
    80005cc0:	8082                	ret

0000000080005cc2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cc2:	7135                	addi	sp,sp,-160
    80005cc4:	ed06                	sd	ra,152(sp)
    80005cc6:	e922                	sd	s0,144(sp)
    80005cc8:	e526                	sd	s1,136(sp)
    80005cca:	e14a                	sd	s2,128(sp)
    80005ccc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cce:	ffffc097          	auipc	ra,0xffffc
    80005cd2:	d10080e7          	jalr	-752(ra) # 800019de <myproc>
    80005cd6:	892a                	mv	s2,a0
  
  begin_op();
    80005cd8:	ffffe097          	auipc	ra,0xffffe
    80005cdc:	7d0080e7          	jalr	2000(ra) # 800044a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ce0:	08000613          	li	a2,128
    80005ce4:	f6040593          	addi	a1,s0,-160
    80005ce8:	4501                	li	a0,0
    80005cea:	ffffd097          	auipc	ra,0xffffd
    80005cee:	272080e7          	jalr	626(ra) # 80002f5c <argstr>
    80005cf2:	04054b63          	bltz	a0,80005d48 <sys_chdir+0x86>
    80005cf6:	f6040513          	addi	a0,s0,-160
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	592080e7          	jalr	1426(ra) # 8000428c <namei>
    80005d02:	84aa                	mv	s1,a0
    80005d04:	c131                	beqz	a0,80005d48 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	dd0080e7          	jalr	-560(ra) # 80003ad6 <ilock>
  if(ip->type != T_DIR){
    80005d0e:	04449703          	lh	a4,68(s1)
    80005d12:	4785                	li	a5,1
    80005d14:	04f71063          	bne	a4,a5,80005d54 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d18:	8526                	mv	a0,s1
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	e7e080e7          	jalr	-386(ra) # 80003b98 <iunlock>
  iput(p->cwd);
    80005d22:	15893503          	ld	a0,344(s2)
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	f6a080e7          	jalr	-150(ra) # 80003c90 <iput>
  end_op();
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	7fa080e7          	jalr	2042(ra) # 80004528 <end_op>
  p->cwd = ip;
    80005d36:	14993c23          	sd	s1,344(s2)
  return 0;
    80005d3a:	4501                	li	a0,0
}
    80005d3c:	60ea                	ld	ra,152(sp)
    80005d3e:	644a                	ld	s0,144(sp)
    80005d40:	64aa                	ld	s1,136(sp)
    80005d42:	690a                	ld	s2,128(sp)
    80005d44:	610d                	addi	sp,sp,160
    80005d46:	8082                	ret
    end_op();
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	7e0080e7          	jalr	2016(ra) # 80004528 <end_op>
    return -1;
    80005d50:	557d                	li	a0,-1
    80005d52:	b7ed                	j	80005d3c <sys_chdir+0x7a>
    iunlockput(ip);
    80005d54:	8526                	mv	a0,s1
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	fe2080e7          	jalr	-30(ra) # 80003d38 <iunlockput>
    end_op();
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	7ca080e7          	jalr	1994(ra) # 80004528 <end_op>
    return -1;
    80005d66:	557d                	li	a0,-1
    80005d68:	bfd1                	j	80005d3c <sys_chdir+0x7a>

0000000080005d6a <sys_exec>:

uint64
sys_exec(void)
{
    80005d6a:	7145                	addi	sp,sp,-464
    80005d6c:	e786                	sd	ra,456(sp)
    80005d6e:	e3a2                	sd	s0,448(sp)
    80005d70:	ff26                	sd	s1,440(sp)
    80005d72:	fb4a                	sd	s2,432(sp)
    80005d74:	f74e                	sd	s3,424(sp)
    80005d76:	f352                	sd	s4,416(sp)
    80005d78:	ef56                	sd	s5,408(sp)
    80005d7a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d7c:	08000613          	li	a2,128
    80005d80:	f4040593          	addi	a1,s0,-192
    80005d84:	4501                	li	a0,0
    80005d86:	ffffd097          	auipc	ra,0xffffd
    80005d8a:	1d6080e7          	jalr	470(ra) # 80002f5c <argstr>
    return -1;
    80005d8e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d90:	0c054a63          	bltz	a0,80005e64 <sys_exec+0xfa>
    80005d94:	e3840593          	addi	a1,s0,-456
    80005d98:	4505                	li	a0,1
    80005d9a:	ffffd097          	auipc	ra,0xffffd
    80005d9e:	1a0080e7          	jalr	416(ra) # 80002f3a <argaddr>
    80005da2:	0c054163          	bltz	a0,80005e64 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005da6:	10000613          	li	a2,256
    80005daa:	4581                	li	a1,0
    80005dac:	e4040513          	addi	a0,s0,-448
    80005db0:	ffffb097          	auipc	ra,0xffffb
    80005db4:	f30080e7          	jalr	-208(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005db8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dbc:	89a6                	mv	s3,s1
    80005dbe:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dc0:	02000a13          	li	s4,32
    80005dc4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dc8:	00391513          	slli	a0,s2,0x3
    80005dcc:	e3040593          	addi	a1,s0,-464
    80005dd0:	e3843783          	ld	a5,-456(s0)
    80005dd4:	953e                	add	a0,a0,a5
    80005dd6:	ffffd097          	auipc	ra,0xffffd
    80005dda:	0a8080e7          	jalr	168(ra) # 80002e7e <fetchaddr>
    80005dde:	02054a63          	bltz	a0,80005e12 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005de2:	e3043783          	ld	a5,-464(s0)
    80005de6:	c3b9                	beqz	a5,80005e2c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005de8:	ffffb097          	auipc	ra,0xffffb
    80005dec:	d0c080e7          	jalr	-756(ra) # 80000af4 <kalloc>
    80005df0:	85aa                	mv	a1,a0
    80005df2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005df6:	cd11                	beqz	a0,80005e12 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005df8:	6605                	lui	a2,0x1
    80005dfa:	e3043503          	ld	a0,-464(s0)
    80005dfe:	ffffd097          	auipc	ra,0xffffd
    80005e02:	0d2080e7          	jalr	210(ra) # 80002ed0 <fetchstr>
    80005e06:	00054663          	bltz	a0,80005e12 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e0a:	0905                	addi	s2,s2,1
    80005e0c:	09a1                	addi	s3,s3,8
    80005e0e:	fb491be3          	bne	s2,s4,80005dc4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e12:	10048913          	addi	s2,s1,256
    80005e16:	6088                	ld	a0,0(s1)
    80005e18:	c529                	beqz	a0,80005e62 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e1a:	ffffb097          	auipc	ra,0xffffb
    80005e1e:	bde080e7          	jalr	-1058(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e22:	04a1                	addi	s1,s1,8
    80005e24:	ff2499e3          	bne	s1,s2,80005e16 <sys_exec+0xac>
  return -1;
    80005e28:	597d                	li	s2,-1
    80005e2a:	a82d                	j	80005e64 <sys_exec+0xfa>
      argv[i] = 0;
    80005e2c:	0a8e                	slli	s5,s5,0x3
    80005e2e:	fc040793          	addi	a5,s0,-64
    80005e32:	9abe                	add	s5,s5,a5
    80005e34:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e38:	e4040593          	addi	a1,s0,-448
    80005e3c:	f4040513          	addi	a0,s0,-192
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	194080e7          	jalr	404(ra) # 80004fd4 <exec>
    80005e48:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e4a:	10048993          	addi	s3,s1,256
    80005e4e:	6088                	ld	a0,0(s1)
    80005e50:	c911                	beqz	a0,80005e64 <sys_exec+0xfa>
    kfree(argv[i]);
    80005e52:	ffffb097          	auipc	ra,0xffffb
    80005e56:	ba6080e7          	jalr	-1114(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e5a:	04a1                	addi	s1,s1,8
    80005e5c:	ff3499e3          	bne	s1,s3,80005e4e <sys_exec+0xe4>
    80005e60:	a011                	j	80005e64 <sys_exec+0xfa>
  return -1;
    80005e62:	597d                	li	s2,-1
}
    80005e64:	854a                	mv	a0,s2
    80005e66:	60be                	ld	ra,456(sp)
    80005e68:	641e                	ld	s0,448(sp)
    80005e6a:	74fa                	ld	s1,440(sp)
    80005e6c:	795a                	ld	s2,432(sp)
    80005e6e:	79ba                	ld	s3,424(sp)
    80005e70:	7a1a                	ld	s4,416(sp)
    80005e72:	6afa                	ld	s5,408(sp)
    80005e74:	6179                	addi	sp,sp,464
    80005e76:	8082                	ret

0000000080005e78 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e78:	7139                	addi	sp,sp,-64
    80005e7a:	fc06                	sd	ra,56(sp)
    80005e7c:	f822                	sd	s0,48(sp)
    80005e7e:	f426                	sd	s1,40(sp)
    80005e80:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	b5c080e7          	jalr	-1188(ra) # 800019de <myproc>
    80005e8a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e8c:	fd840593          	addi	a1,s0,-40
    80005e90:	4501                	li	a0,0
    80005e92:	ffffd097          	auipc	ra,0xffffd
    80005e96:	0a8080e7          	jalr	168(ra) # 80002f3a <argaddr>
    return -1;
    80005e9a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e9c:	0e054063          	bltz	a0,80005f7c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ea0:	fc840593          	addi	a1,s0,-56
    80005ea4:	fd040513          	addi	a0,s0,-48
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	dfc080e7          	jalr	-516(ra) # 80004ca4 <pipealloc>
    return -1;
    80005eb0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005eb2:	0c054563          	bltz	a0,80005f7c <sys_pipe+0x104>
  fd0 = -1;
    80005eb6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eba:	fd043503          	ld	a0,-48(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	508080e7          	jalr	1288(ra) # 800053c6 <fdalloc>
    80005ec6:	fca42223          	sw	a0,-60(s0)
    80005eca:	08054c63          	bltz	a0,80005f62 <sys_pipe+0xea>
    80005ece:	fc843503          	ld	a0,-56(s0)
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	4f4080e7          	jalr	1268(ra) # 800053c6 <fdalloc>
    80005eda:	fca42023          	sw	a0,-64(s0)
    80005ede:	06054863          	bltz	a0,80005f4e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ee2:	4691                	li	a3,4
    80005ee4:	fc440613          	addi	a2,s0,-60
    80005ee8:	fd843583          	ld	a1,-40(s0)
    80005eec:	6ca8                	ld	a0,88(s1)
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	784080e7          	jalr	1924(ra) # 80001672 <copyout>
    80005ef6:	02054063          	bltz	a0,80005f16 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005efa:	4691                	li	a3,4
    80005efc:	fc040613          	addi	a2,s0,-64
    80005f00:	fd843583          	ld	a1,-40(s0)
    80005f04:	0591                	addi	a1,a1,4
    80005f06:	6ca8                	ld	a0,88(s1)
    80005f08:	ffffb097          	auipc	ra,0xffffb
    80005f0c:	76a080e7          	jalr	1898(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f10:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f12:	06055563          	bgez	a0,80005f7c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f16:	fc442783          	lw	a5,-60(s0)
    80005f1a:	07e9                	addi	a5,a5,26
    80005f1c:	078e                	slli	a5,a5,0x3
    80005f1e:	97a6                	add	a5,a5,s1
    80005f20:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005f24:	fc042503          	lw	a0,-64(s0)
    80005f28:	0569                	addi	a0,a0,26
    80005f2a:	050e                	slli	a0,a0,0x3
    80005f2c:	9526                	add	a0,a0,s1
    80005f2e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f32:	fd043503          	ld	a0,-48(s0)
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	a3e080e7          	jalr	-1474(ra) # 80004974 <fileclose>
    fileclose(wf);
    80005f3e:	fc843503          	ld	a0,-56(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	a32080e7          	jalr	-1486(ra) # 80004974 <fileclose>
    return -1;
    80005f4a:	57fd                	li	a5,-1
    80005f4c:	a805                	j	80005f7c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f4e:	fc442783          	lw	a5,-60(s0)
    80005f52:	0007c863          	bltz	a5,80005f62 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f56:	01a78513          	addi	a0,a5,26
    80005f5a:	050e                	slli	a0,a0,0x3
    80005f5c:	9526                	add	a0,a0,s1
    80005f5e:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005f62:	fd043503          	ld	a0,-48(s0)
    80005f66:	fffff097          	auipc	ra,0xfffff
    80005f6a:	a0e080e7          	jalr	-1522(ra) # 80004974 <fileclose>
    fileclose(wf);
    80005f6e:	fc843503          	ld	a0,-56(s0)
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	a02080e7          	jalr	-1534(ra) # 80004974 <fileclose>
    return -1;
    80005f7a:	57fd                	li	a5,-1
}
    80005f7c:	853e                	mv	a0,a5
    80005f7e:	70e2                	ld	ra,56(sp)
    80005f80:	7442                	ld	s0,48(sp)
    80005f82:	74a2                	ld	s1,40(sp)
    80005f84:	6121                	addi	sp,sp,64
    80005f86:	8082                	ret
	...

0000000080005f90 <kernelvec>:
    80005f90:	7111                	addi	sp,sp,-256
    80005f92:	e006                	sd	ra,0(sp)
    80005f94:	e40a                	sd	sp,8(sp)
    80005f96:	e80e                	sd	gp,16(sp)
    80005f98:	ec12                	sd	tp,24(sp)
    80005f9a:	f016                	sd	t0,32(sp)
    80005f9c:	f41a                	sd	t1,40(sp)
    80005f9e:	f81e                	sd	t2,48(sp)
    80005fa0:	fc22                	sd	s0,56(sp)
    80005fa2:	e0a6                	sd	s1,64(sp)
    80005fa4:	e4aa                	sd	a0,72(sp)
    80005fa6:	e8ae                	sd	a1,80(sp)
    80005fa8:	ecb2                	sd	a2,88(sp)
    80005faa:	f0b6                	sd	a3,96(sp)
    80005fac:	f4ba                	sd	a4,104(sp)
    80005fae:	f8be                	sd	a5,112(sp)
    80005fb0:	fcc2                	sd	a6,120(sp)
    80005fb2:	e146                	sd	a7,128(sp)
    80005fb4:	e54a                	sd	s2,136(sp)
    80005fb6:	e94e                	sd	s3,144(sp)
    80005fb8:	ed52                	sd	s4,152(sp)
    80005fba:	f156                	sd	s5,160(sp)
    80005fbc:	f55a                	sd	s6,168(sp)
    80005fbe:	f95e                	sd	s7,176(sp)
    80005fc0:	fd62                	sd	s8,184(sp)
    80005fc2:	e1e6                	sd	s9,192(sp)
    80005fc4:	e5ea                	sd	s10,200(sp)
    80005fc6:	e9ee                	sd	s11,208(sp)
    80005fc8:	edf2                	sd	t3,216(sp)
    80005fca:	f1f6                	sd	t4,224(sp)
    80005fcc:	f5fa                	sd	t5,232(sp)
    80005fce:	f9fe                	sd	t6,240(sp)
    80005fd0:	d7bfc0ef          	jal	ra,80002d4a <kerneltrap>
    80005fd4:	6082                	ld	ra,0(sp)
    80005fd6:	6122                	ld	sp,8(sp)
    80005fd8:	61c2                	ld	gp,16(sp)
    80005fda:	7282                	ld	t0,32(sp)
    80005fdc:	7322                	ld	t1,40(sp)
    80005fde:	73c2                	ld	t2,48(sp)
    80005fe0:	7462                	ld	s0,56(sp)
    80005fe2:	6486                	ld	s1,64(sp)
    80005fe4:	6526                	ld	a0,72(sp)
    80005fe6:	65c6                	ld	a1,80(sp)
    80005fe8:	6666                	ld	a2,88(sp)
    80005fea:	7686                	ld	a3,96(sp)
    80005fec:	7726                	ld	a4,104(sp)
    80005fee:	77c6                	ld	a5,112(sp)
    80005ff0:	7866                	ld	a6,120(sp)
    80005ff2:	688a                	ld	a7,128(sp)
    80005ff4:	692a                	ld	s2,136(sp)
    80005ff6:	69ca                	ld	s3,144(sp)
    80005ff8:	6a6a                	ld	s4,152(sp)
    80005ffa:	7a8a                	ld	s5,160(sp)
    80005ffc:	7b2a                	ld	s6,168(sp)
    80005ffe:	7bca                	ld	s7,176(sp)
    80006000:	7c6a                	ld	s8,184(sp)
    80006002:	6c8e                	ld	s9,192(sp)
    80006004:	6d2e                	ld	s10,200(sp)
    80006006:	6dce                	ld	s11,208(sp)
    80006008:	6e6e                	ld	t3,216(sp)
    8000600a:	7e8e                	ld	t4,224(sp)
    8000600c:	7f2e                	ld	t5,232(sp)
    8000600e:	7fce                	ld	t6,240(sp)
    80006010:	6111                	addi	sp,sp,256
    80006012:	10200073          	sret
    80006016:	00000013          	nop
    8000601a:	00000013          	nop
    8000601e:	0001                	nop

0000000080006020 <timervec>:
    80006020:	34051573          	csrrw	a0,mscratch,a0
    80006024:	e10c                	sd	a1,0(a0)
    80006026:	e510                	sd	a2,8(a0)
    80006028:	e914                	sd	a3,16(a0)
    8000602a:	6d0c                	ld	a1,24(a0)
    8000602c:	7110                	ld	a2,32(a0)
    8000602e:	6194                	ld	a3,0(a1)
    80006030:	96b2                	add	a3,a3,a2
    80006032:	e194                	sd	a3,0(a1)
    80006034:	4589                	li	a1,2
    80006036:	14459073          	csrw	sip,a1
    8000603a:	6914                	ld	a3,16(a0)
    8000603c:	6510                	ld	a2,8(a0)
    8000603e:	610c                	ld	a1,0(a0)
    80006040:	34051573          	csrrw	a0,mscratch,a0
    80006044:	30200073          	mret
	...

000000008000604a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000604a:	1141                	addi	sp,sp,-16
    8000604c:	e422                	sd	s0,8(sp)
    8000604e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006050:	0c0007b7          	lui	a5,0xc000
    80006054:	4705                	li	a4,1
    80006056:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006058:	c3d8                	sw	a4,4(a5)
}
    8000605a:	6422                	ld	s0,8(sp)
    8000605c:	0141                	addi	sp,sp,16
    8000605e:	8082                	ret

0000000080006060 <plicinithart>:

void
plicinithart(void)
{
    80006060:	1141                	addi	sp,sp,-16
    80006062:	e406                	sd	ra,8(sp)
    80006064:	e022                	sd	s0,0(sp)
    80006066:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	94a080e7          	jalr	-1718(ra) # 800019b2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006070:	0085171b          	slliw	a4,a0,0x8
    80006074:	0c0027b7          	lui	a5,0xc002
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	40200713          	li	a4,1026
    8000607e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006082:	00d5151b          	slliw	a0,a0,0xd
    80006086:	0c2017b7          	lui	a5,0xc201
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	00052023          	sw	zero,0(a0)
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret

0000000080006098 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006098:	1141                	addi	sp,sp,-16
    8000609a:	e406                	sd	ra,8(sp)
    8000609c:	e022                	sd	s0,0(sp)
    8000609e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a0:	ffffc097          	auipc	ra,0xffffc
    800060a4:	912080e7          	jalr	-1774(ra) # 800019b2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060a8:	00d5179b          	slliw	a5,a0,0xd
    800060ac:	0c201537          	lui	a0,0xc201
    800060b0:	953e                	add	a0,a0,a5
  return irq;
}
    800060b2:	4148                	lw	a0,4(a0)
    800060b4:	60a2                	ld	ra,8(sp)
    800060b6:	6402                	ld	s0,0(sp)
    800060b8:	0141                	addi	sp,sp,16
    800060ba:	8082                	ret

00000000800060bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060bc:	1101                	addi	sp,sp,-32
    800060be:	ec06                	sd	ra,24(sp)
    800060c0:	e822                	sd	s0,16(sp)
    800060c2:	e426                	sd	s1,8(sp)
    800060c4:	1000                	addi	s0,sp,32
    800060c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	8ea080e7          	jalr	-1814(ra) # 800019b2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060d0:	00d5151b          	slliw	a0,a0,0xd
    800060d4:	0c2017b7          	lui	a5,0xc201
    800060d8:	97aa                	add	a5,a5,a0
    800060da:	c3c4                	sw	s1,4(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret

00000000800060e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060e6:	1141                	addi	sp,sp,-16
    800060e8:	e406                	sd	ra,8(sp)
    800060ea:	e022                	sd	s0,0(sp)
    800060ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ee:	479d                	li	a5,7
    800060f0:	06a7c963          	blt	a5,a0,80006162 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800060f4:	0001d797          	auipc	a5,0x1d
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80023000 <disk>
    800060fc:	00a78733          	add	a4,a5,a0
    80006100:	6789                	lui	a5,0x2
    80006102:	97ba                	add	a5,a5,a4
    80006104:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006108:	e7ad                	bnez	a5,80006172 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000610a:	00451793          	slli	a5,a0,0x4
    8000610e:	0001f717          	auipc	a4,0x1f
    80006112:	ef270713          	addi	a4,a4,-270 # 80025000 <disk+0x2000>
    80006116:	6314                	ld	a3,0(a4)
    80006118:	96be                	add	a3,a3,a5
    8000611a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000611e:	6314                	ld	a3,0(a4)
    80006120:	96be                	add	a3,a3,a5
    80006122:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006126:	6314                	ld	a3,0(a4)
    80006128:	96be                	add	a3,a3,a5
    8000612a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000612e:	6318                	ld	a4,0(a4)
    80006130:	97ba                	add	a5,a5,a4
    80006132:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006136:	0001d797          	auipc	a5,0x1d
    8000613a:	eca78793          	addi	a5,a5,-310 # 80023000 <disk>
    8000613e:	97aa                	add	a5,a5,a0
    80006140:	6509                	lui	a0,0x2
    80006142:	953e                	add	a0,a0,a5
    80006144:	4785                	li	a5,1
    80006146:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000614a:	0001f517          	auipc	a0,0x1f
    8000614e:	ece50513          	addi	a0,a0,-306 # 80025018 <disk+0x2018>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	188080e7          	jalr	392(ra) # 800022da <wakeup>
}
    8000615a:	60a2                	ld	ra,8(sp)
    8000615c:	6402                	ld	s0,0(sp)
    8000615e:	0141                	addi	sp,sp,16
    80006160:	8082                	ret
    panic("free_desc 1");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	76650513          	addi	a0,a0,1894 # 800088c8 <syscalls+0x328>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3d4080e7          	jalr	980(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006172:	00002517          	auipc	a0,0x2
    80006176:	76650513          	addi	a0,a0,1894 # 800088d8 <syscalls+0x338>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>

0000000080006182 <virtio_disk_init>:
{
    80006182:	1101                	addi	sp,sp,-32
    80006184:	ec06                	sd	ra,24(sp)
    80006186:	e822                	sd	s0,16(sp)
    80006188:	e426                	sd	s1,8(sp)
    8000618a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000618c:	00002597          	auipc	a1,0x2
    80006190:	75c58593          	addi	a1,a1,1884 # 800088e8 <syscalls+0x348>
    80006194:	0001f517          	auipc	a0,0x1f
    80006198:	f9450513          	addi	a0,a0,-108 # 80025128 <disk+0x2128>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	9b8080e7          	jalr	-1608(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061a4:	100017b7          	lui	a5,0x10001
    800061a8:	4398                	lw	a4,0(a5)
    800061aa:	2701                	sext.w	a4,a4
    800061ac:	747277b7          	lui	a5,0x74727
    800061b0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061b4:	0ef71163          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	43dc                	lw	a5,4(a5)
    800061be:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061c0:	4705                	li	a4,1
    800061c2:	0ce79a63          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061c6:	100017b7          	lui	a5,0x10001
    800061ca:	479c                	lw	a5,8(a5)
    800061cc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ce:	4709                	li	a4,2
    800061d0:	0ce79363          	bne	a5,a4,80006296 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061d4:	100017b7          	lui	a5,0x10001
    800061d8:	47d8                	lw	a4,12(a5)
    800061da:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061dc:	554d47b7          	lui	a5,0x554d4
    800061e0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061e4:	0af71963          	bne	a4,a5,80006296 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	4705                	li	a4,1
    800061ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f0:	470d                	li	a4,3
    800061f2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061f4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061f6:	c7ffe737          	lui	a4,0xc7ffe
    800061fa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800061fe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006200:	2701                	sext.w	a4,a4
    80006202:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006204:	472d                	li	a4,11
    80006206:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006208:	473d                	li	a4,15
    8000620a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000620c:	6705                	lui	a4,0x1
    8000620e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006210:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006214:	5bdc                	lw	a5,52(a5)
    80006216:	2781                	sext.w	a5,a5
  if(max == 0)
    80006218:	c7d9                	beqz	a5,800062a6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000621a:	471d                	li	a4,7
    8000621c:	08f77d63          	bgeu	a4,a5,800062b6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006220:	100014b7          	lui	s1,0x10001
    80006224:	47a1                	li	a5,8
    80006226:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006228:	6609                	lui	a2,0x2
    8000622a:	4581                	li	a1,0
    8000622c:	0001d517          	auipc	a0,0x1d
    80006230:	dd450513          	addi	a0,a0,-556 # 80023000 <disk>
    80006234:	ffffb097          	auipc	ra,0xffffb
    80006238:	aac080e7          	jalr	-1364(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000623c:	0001d717          	auipc	a4,0x1d
    80006240:	dc470713          	addi	a4,a4,-572 # 80023000 <disk>
    80006244:	00c75793          	srli	a5,a4,0xc
    80006248:	2781                	sext.w	a5,a5
    8000624a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000624c:	0001f797          	auipc	a5,0x1f
    80006250:	db478793          	addi	a5,a5,-588 # 80025000 <disk+0x2000>
    80006254:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006256:	0001d717          	auipc	a4,0x1d
    8000625a:	e2a70713          	addi	a4,a4,-470 # 80023080 <disk+0x80>
    8000625e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006260:	0001e717          	auipc	a4,0x1e
    80006264:	da070713          	addi	a4,a4,-608 # 80024000 <disk+0x1000>
    80006268:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000626a:	4705                	li	a4,1
    8000626c:	00e78c23          	sb	a4,24(a5)
    80006270:	00e78ca3          	sb	a4,25(a5)
    80006274:	00e78d23          	sb	a4,26(a5)
    80006278:	00e78da3          	sb	a4,27(a5)
    8000627c:	00e78e23          	sb	a4,28(a5)
    80006280:	00e78ea3          	sb	a4,29(a5)
    80006284:	00e78f23          	sb	a4,30(a5)
    80006288:	00e78fa3          	sb	a4,31(a5)
}
    8000628c:	60e2                	ld	ra,24(sp)
    8000628e:	6442                	ld	s0,16(sp)
    80006290:	64a2                	ld	s1,8(sp)
    80006292:	6105                	addi	sp,sp,32
    80006294:	8082                	ret
    panic("could not find virtio disk");
    80006296:	00002517          	auipc	a0,0x2
    8000629a:	66250513          	addi	a0,a0,1634 # 800088f8 <syscalls+0x358>
    8000629e:	ffffa097          	auipc	ra,0xffffa
    800062a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800062a6:	00002517          	auipc	a0,0x2
    800062aa:	67250513          	addi	a0,a0,1650 # 80008918 <syscalls+0x378>
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	290080e7          	jalr	656(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800062b6:	00002517          	auipc	a0,0x2
    800062ba:	68250513          	addi	a0,a0,1666 # 80008938 <syscalls+0x398>
    800062be:	ffffa097          	auipc	ra,0xffffa
    800062c2:	280080e7          	jalr	640(ra) # 8000053e <panic>

00000000800062c6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062c6:	7159                	addi	sp,sp,-112
    800062c8:	f486                	sd	ra,104(sp)
    800062ca:	f0a2                	sd	s0,96(sp)
    800062cc:	eca6                	sd	s1,88(sp)
    800062ce:	e8ca                	sd	s2,80(sp)
    800062d0:	e4ce                	sd	s3,72(sp)
    800062d2:	e0d2                	sd	s4,64(sp)
    800062d4:	fc56                	sd	s5,56(sp)
    800062d6:	f85a                	sd	s6,48(sp)
    800062d8:	f45e                	sd	s7,40(sp)
    800062da:	f062                	sd	s8,32(sp)
    800062dc:	ec66                	sd	s9,24(sp)
    800062de:	e86a                	sd	s10,16(sp)
    800062e0:	1880                	addi	s0,sp,112
    800062e2:	892a                	mv	s2,a0
    800062e4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062e6:	00c52c83          	lw	s9,12(a0)
    800062ea:	001c9c9b          	slliw	s9,s9,0x1
    800062ee:	1c82                	slli	s9,s9,0x20
    800062f0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062f4:	0001f517          	auipc	a0,0x1f
    800062f8:	e3450513          	addi	a0,a0,-460 # 80025128 <disk+0x2128>
    800062fc:	ffffb097          	auipc	ra,0xffffb
    80006300:	8e8080e7          	jalr	-1816(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006304:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006306:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006308:	0001db97          	auipc	s7,0x1d
    8000630c:	cf8b8b93          	addi	s7,s7,-776 # 80023000 <disk>
    80006310:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006312:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006314:	8a4e                	mv	s4,s3
    80006316:	a051                	j	8000639a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006318:	00fb86b3          	add	a3,s7,a5
    8000631c:	96da                	add	a3,a3,s6
    8000631e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006322:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006324:	0207c563          	bltz	a5,8000634e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006328:	2485                	addiw	s1,s1,1
    8000632a:	0711                	addi	a4,a4,4
    8000632c:	25548063          	beq	s1,s5,8000656c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006330:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006332:	0001f697          	auipc	a3,0x1f
    80006336:	ce668693          	addi	a3,a3,-794 # 80025018 <disk+0x2018>
    8000633a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000633c:	0006c583          	lbu	a1,0(a3)
    80006340:	fde1                	bnez	a1,80006318 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006342:	2785                	addiw	a5,a5,1
    80006344:	0685                	addi	a3,a3,1
    80006346:	ff879be3          	bne	a5,s8,8000633c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000634a:	57fd                	li	a5,-1
    8000634c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000634e:	02905a63          	blez	s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006352:	f9042503          	lw	a0,-112(s0)
    80006356:	00000097          	auipc	ra,0x0
    8000635a:	d90080e7          	jalr	-624(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000635e:	4785                	li	a5,1
    80006360:	0297d163          	bge	a5,s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006364:	f9442503          	lw	a0,-108(s0)
    80006368:	00000097          	auipc	ra,0x0
    8000636c:	d7e080e7          	jalr	-642(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006370:	4789                	li	a5,2
    80006372:	0097d863          	bge	a5,s1,80006382 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006376:	f9842503          	lw	a0,-104(s0)
    8000637a:	00000097          	auipc	ra,0x0
    8000637e:	d6c080e7          	jalr	-660(ra) # 800060e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006382:	0001f597          	auipc	a1,0x1f
    80006386:	da658593          	addi	a1,a1,-602 # 80025128 <disk+0x2128>
    8000638a:	0001f517          	auipc	a0,0x1f
    8000638e:	c8e50513          	addi	a0,a0,-882 # 80025018 <disk+0x2018>
    80006392:	ffffc097          	auipc	ra,0xffffc
    80006396:	dbc080e7          	jalr	-580(ra) # 8000214e <sleep>
  for(int i = 0; i < 3; i++){
    8000639a:	f9040713          	addi	a4,s0,-112
    8000639e:	84ce                	mv	s1,s3
    800063a0:	bf41                	j	80006330 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800063a2:	20058713          	addi	a4,a1,512
    800063a6:	00471693          	slli	a3,a4,0x4
    800063aa:	0001d717          	auipc	a4,0x1d
    800063ae:	c5670713          	addi	a4,a4,-938 # 80023000 <disk>
    800063b2:	9736                	add	a4,a4,a3
    800063b4:	4685                	li	a3,1
    800063b6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800063ba:	20058713          	addi	a4,a1,512
    800063be:	00471693          	slli	a3,a4,0x4
    800063c2:	0001d717          	auipc	a4,0x1d
    800063c6:	c3e70713          	addi	a4,a4,-962 # 80023000 <disk>
    800063ca:	9736                	add	a4,a4,a3
    800063cc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063d0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800063d4:	7679                	lui	a2,0xffffe
    800063d6:	963e                	add	a2,a2,a5
    800063d8:	0001f697          	auipc	a3,0x1f
    800063dc:	c2868693          	addi	a3,a3,-984 # 80025000 <disk+0x2000>
    800063e0:	6298                	ld	a4,0(a3)
    800063e2:	9732                	add	a4,a4,a2
    800063e4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063e6:	6298                	ld	a4,0(a3)
    800063e8:	9732                	add	a4,a4,a2
    800063ea:	4541                	li	a0,16
    800063ec:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063ee:	6298                	ld	a4,0(a3)
    800063f0:	9732                	add	a4,a4,a2
    800063f2:	4505                	li	a0,1
    800063f4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063f8:	f9442703          	lw	a4,-108(s0)
    800063fc:	6288                	ld	a0,0(a3)
    800063fe:	962a                	add	a2,a2,a0
    80006400:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006404:	0712                	slli	a4,a4,0x4
    80006406:	6290                	ld	a2,0(a3)
    80006408:	963a                	add	a2,a2,a4
    8000640a:	05890513          	addi	a0,s2,88
    8000640e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006410:	6294                	ld	a3,0(a3)
    80006412:	96ba                	add	a3,a3,a4
    80006414:	40000613          	li	a2,1024
    80006418:	c690                	sw	a2,8(a3)
  if(write)
    8000641a:	140d0063          	beqz	s10,8000655a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000641e:	0001f697          	auipc	a3,0x1f
    80006422:	be26b683          	ld	a3,-1054(a3) # 80025000 <disk+0x2000>
    80006426:	96ba                	add	a3,a3,a4
    80006428:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000642c:	0001d817          	auipc	a6,0x1d
    80006430:	bd480813          	addi	a6,a6,-1068 # 80023000 <disk>
    80006434:	0001f517          	auipc	a0,0x1f
    80006438:	bcc50513          	addi	a0,a0,-1076 # 80025000 <disk+0x2000>
    8000643c:	6114                	ld	a3,0(a0)
    8000643e:	96ba                	add	a3,a3,a4
    80006440:	00c6d603          	lhu	a2,12(a3)
    80006444:	00166613          	ori	a2,a2,1
    80006448:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000644c:	f9842683          	lw	a3,-104(s0)
    80006450:	6110                	ld	a2,0(a0)
    80006452:	9732                	add	a4,a4,a2
    80006454:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006458:	20058613          	addi	a2,a1,512
    8000645c:	0612                	slli	a2,a2,0x4
    8000645e:	9642                	add	a2,a2,a6
    80006460:	577d                	li	a4,-1
    80006462:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006466:	00469713          	slli	a4,a3,0x4
    8000646a:	6114                	ld	a3,0(a0)
    8000646c:	96ba                	add	a3,a3,a4
    8000646e:	03078793          	addi	a5,a5,48
    80006472:	97c2                	add	a5,a5,a6
    80006474:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006476:	611c                	ld	a5,0(a0)
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	4685                	li	a3,1
    8000647c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000647e:	611c                	ld	a5,0(a0)
    80006480:	97ba                	add	a5,a5,a4
    80006482:	4809                	li	a6,2
    80006484:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006488:	611c                	ld	a5,0(a0)
    8000648a:	973e                	add	a4,a4,a5
    8000648c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006490:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006494:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006498:	6518                	ld	a4,8(a0)
    8000649a:	00275783          	lhu	a5,2(a4)
    8000649e:	8b9d                	andi	a5,a5,7
    800064a0:	0786                	slli	a5,a5,0x1
    800064a2:	97ba                	add	a5,a5,a4
    800064a4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064a8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ac:	6518                	ld	a4,8(a0)
    800064ae:	00275783          	lhu	a5,2(a4)
    800064b2:	2785                	addiw	a5,a5,1
    800064b4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064b8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064c4:	00492703          	lw	a4,4(s2)
    800064c8:	4785                	li	a5,1
    800064ca:	02f71163          	bne	a4,a5,800064ec <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800064ce:	0001f997          	auipc	s3,0x1f
    800064d2:	c5a98993          	addi	s3,s3,-934 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800064d6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064d8:	85ce                	mv	a1,s3
    800064da:	854a                	mv	a0,s2
    800064dc:	ffffc097          	auipc	ra,0xffffc
    800064e0:	c72080e7          	jalr	-910(ra) # 8000214e <sleep>
  while(b->disk == 1) {
    800064e4:	00492783          	lw	a5,4(s2)
    800064e8:	fe9788e3          	beq	a5,s1,800064d8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800064ec:	f9042903          	lw	s2,-112(s0)
    800064f0:	20090793          	addi	a5,s2,512
    800064f4:	00479713          	slli	a4,a5,0x4
    800064f8:	0001d797          	auipc	a5,0x1d
    800064fc:	b0878793          	addi	a5,a5,-1272 # 80023000 <disk>
    80006500:	97ba                	add	a5,a5,a4
    80006502:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006506:	0001f997          	auipc	s3,0x1f
    8000650a:	afa98993          	addi	s3,s3,-1286 # 80025000 <disk+0x2000>
    8000650e:	00491713          	slli	a4,s2,0x4
    80006512:	0009b783          	ld	a5,0(s3)
    80006516:	97ba                	add	a5,a5,a4
    80006518:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000651c:	854a                	mv	a0,s2
    8000651e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006522:	00000097          	auipc	ra,0x0
    80006526:	bc4080e7          	jalr	-1084(ra) # 800060e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000652a:	8885                	andi	s1,s1,1
    8000652c:	f0ed                	bnez	s1,8000650e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000652e:	0001f517          	auipc	a0,0x1f
    80006532:	bfa50513          	addi	a0,a0,-1030 # 80025128 <disk+0x2128>
    80006536:	ffffa097          	auipc	ra,0xffffa
    8000653a:	762080e7          	jalr	1890(ra) # 80000c98 <release>
}
    8000653e:	70a6                	ld	ra,104(sp)
    80006540:	7406                	ld	s0,96(sp)
    80006542:	64e6                	ld	s1,88(sp)
    80006544:	6946                	ld	s2,80(sp)
    80006546:	69a6                	ld	s3,72(sp)
    80006548:	6a06                	ld	s4,64(sp)
    8000654a:	7ae2                	ld	s5,56(sp)
    8000654c:	7b42                	ld	s6,48(sp)
    8000654e:	7ba2                	ld	s7,40(sp)
    80006550:	7c02                	ld	s8,32(sp)
    80006552:	6ce2                	ld	s9,24(sp)
    80006554:	6d42                	ld	s10,16(sp)
    80006556:	6165                	addi	sp,sp,112
    80006558:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000655a:	0001f697          	auipc	a3,0x1f
    8000655e:	aa66b683          	ld	a3,-1370(a3) # 80025000 <disk+0x2000>
    80006562:	96ba                	add	a3,a3,a4
    80006564:	4609                	li	a2,2
    80006566:	00c69623          	sh	a2,12(a3)
    8000656a:	b5c9                	j	8000642c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000656c:	f9042583          	lw	a1,-112(s0)
    80006570:	20058793          	addi	a5,a1,512
    80006574:	0792                	slli	a5,a5,0x4
    80006576:	0001d517          	auipc	a0,0x1d
    8000657a:	b3250513          	addi	a0,a0,-1230 # 800230a8 <disk+0xa8>
    8000657e:	953e                	add	a0,a0,a5
  if(write)
    80006580:	e20d11e3          	bnez	s10,800063a2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006584:	20058713          	addi	a4,a1,512
    80006588:	00471693          	slli	a3,a4,0x4
    8000658c:	0001d717          	auipc	a4,0x1d
    80006590:	a7470713          	addi	a4,a4,-1420 # 80023000 <disk>
    80006594:	9736                	add	a4,a4,a3
    80006596:	0a072423          	sw	zero,168(a4)
    8000659a:	b505                	j	800063ba <virtio_disk_rw+0xf4>

000000008000659c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000659c:	1101                	addi	sp,sp,-32
    8000659e:	ec06                	sd	ra,24(sp)
    800065a0:	e822                	sd	s0,16(sp)
    800065a2:	e426                	sd	s1,8(sp)
    800065a4:	e04a                	sd	s2,0(sp)
    800065a6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065a8:	0001f517          	auipc	a0,0x1f
    800065ac:	b8050513          	addi	a0,a0,-1152 # 80025128 <disk+0x2128>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	634080e7          	jalr	1588(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065b8:	10001737          	lui	a4,0x10001
    800065bc:	533c                	lw	a5,96(a4)
    800065be:	8b8d                	andi	a5,a5,3
    800065c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065c6:	0001f797          	auipc	a5,0x1f
    800065ca:	a3a78793          	addi	a5,a5,-1478 # 80025000 <disk+0x2000>
    800065ce:	6b94                	ld	a3,16(a5)
    800065d0:	0207d703          	lhu	a4,32(a5)
    800065d4:	0026d783          	lhu	a5,2(a3)
    800065d8:	06f70163          	beq	a4,a5,8000663a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065dc:	0001d917          	auipc	s2,0x1d
    800065e0:	a2490913          	addi	s2,s2,-1500 # 80023000 <disk>
    800065e4:	0001f497          	auipc	s1,0x1f
    800065e8:	a1c48493          	addi	s1,s1,-1508 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800065ec:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065f0:	6898                	ld	a4,16(s1)
    800065f2:	0204d783          	lhu	a5,32(s1)
    800065f6:	8b9d                	andi	a5,a5,7
    800065f8:	078e                	slli	a5,a5,0x3
    800065fa:	97ba                	add	a5,a5,a4
    800065fc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065fe:	20078713          	addi	a4,a5,512
    80006602:	0712                	slli	a4,a4,0x4
    80006604:	974a                	add	a4,a4,s2
    80006606:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000660a:	e731                	bnez	a4,80006656 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000660c:	20078793          	addi	a5,a5,512
    80006610:	0792                	slli	a5,a5,0x4
    80006612:	97ca                	add	a5,a5,s2
    80006614:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006616:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000661a:	ffffc097          	auipc	ra,0xffffc
    8000661e:	cc0080e7          	jalr	-832(ra) # 800022da <wakeup>

    disk.used_idx += 1;
    80006622:	0204d783          	lhu	a5,32(s1)
    80006626:	2785                	addiw	a5,a5,1
    80006628:	17c2                	slli	a5,a5,0x30
    8000662a:	93c1                	srli	a5,a5,0x30
    8000662c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006630:	6898                	ld	a4,16(s1)
    80006632:	00275703          	lhu	a4,2(a4)
    80006636:	faf71be3          	bne	a4,a5,800065ec <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	aee50513          	addi	a0,a0,-1298 # 80025128 <disk+0x2128>
    80006642:	ffffa097          	auipc	ra,0xffffa
    80006646:	656080e7          	jalr	1622(ra) # 80000c98 <release>
}
    8000664a:	60e2                	ld	ra,24(sp)
    8000664c:	6442                	ld	s0,16(sp)
    8000664e:	64a2                	ld	s1,8(sp)
    80006650:	6902                	ld	s2,0(sp)
    80006652:	6105                	addi	sp,sp,32
    80006654:	8082                	ret
      panic("virtio_disk_intr status");
    80006656:	00002517          	auipc	a0,0x2
    8000665a:	30250513          	addi	a0,a0,770 # 80008958 <syscalls+0x3b8>
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	ee0080e7          	jalr	-288(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
