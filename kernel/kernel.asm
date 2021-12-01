
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	e3c78793          	addi	a5,a5,-452 # 80005ea0 <timervec>
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
    80000130:	388080e7          	jalr	904(ra) # 800024b4 <either_copyin>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	ee6080e7          	jalr	-282(ra) # 800020ba <sleep>
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
    80000214:	24e080e7          	jalr	590(ra) # 8000245e <either_copyout>
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
    800002f6:	218080e7          	jalr	536(ra) # 8000250a <procdump>
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
    8000044a:	e00080e7          	jalr	-512(ra) # 80002246 <wakeup>
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
    80000570:	e5c50513          	addi	a0,a0,-420 # 800083c8 <states.1716+0xd8>
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
    800008a4:	9a6080e7          	jalr	-1626(ra) # 80002246 <wakeup>
    
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
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	78e080e7          	jalr	1934(ra) # 800020ba <sleep>
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
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
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
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
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
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
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
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
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
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
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
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
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
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
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
    80000ed8:	936080e7          	jalr	-1738(ra) # 8000280a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	004080e7          	jalr	4(ra) # 80005ee0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	024080e7          	jalr	36(ra) # 80001f08 <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	4cc50513          	addi	a0,a0,1228 # 800083c8 <states.1716+0xd8>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	4ac50513          	addi	a0,a0,1196 # 800083c8 <states.1716+0xd8>
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
    80000f50:	896080e7          	jalr	-1898(ra) # 800027e2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	8b6080e7          	jalr	-1866(ra) # 8000280a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	f6e080e7          	jalr	-146(ra) # 80005eca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	f7c080e7          	jalr	-132(ra) # 80005ee0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	154080e7          	jalr	340(ra) # 800030c0 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	7e4080e7          	jalr	2020(ra) # 80003758 <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	78e080e7          	jalr	1934(ra) # 8000470a <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	07e080e7          	jalr	126(ra) # 80006002 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d4a080e7          	jalr	-694(ra) # 80001cd6 <userinit>
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

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9b050513          	addi	a0,a0,-1616 # 800112a0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9b050513          	addi	a0,a0,-1616 # 800112b8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	db848493          	addi	s1,s1,-584 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	99698993          	addi	s3,s3,-1642 # 800172d0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	8791                	srai	a5,a5,0x4
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	17048493          	addi	s1,s1,368
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	93050513          	addi	a0,a0,-1744 # 800112d0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8d870713          	addi	a4,a4,-1832 # 800112a0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	ef47a783          	lw	a5,-268(a5) # 800088f4 <first.1679>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	e18080e7          	jalr	-488(ra) # 80002822 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	ec07ad23          	sw	zero,-294(a5) # 800088f4 <first.1679>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	cb4080e7          	jalr	-844(ra) # 800036d8 <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <forkret_thread>:
//---------------------------------------------------------------------------------------------
//lab3

void
forkret_thread(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e406                	sd	ra,8(sp)
    80001a32:	e022                	sd	s0,0(sp)
    80001a34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a36:	00000097          	auipc	ra,0x0
    80001a3a:	f7a080e7          	jalr	-134(ra) # 800019b0 <myproc>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	25a080e7          	jalr	602(ra) # 80000c98 <release>

  if (first) {
    80001a46:	00007797          	auipc	a5,0x7
    80001a4a:	eaa7a783          	lw	a5,-342(a5) # 800088f0 <first.1726>
    80001a4e:	eb89                	bnez	a5,80001a60 <forkret_thread+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret_thread();
    80001a50:	00001097          	auipc	ra,0x1
    80001a54:	e70080e7          	jalr	-400(ra) # 800028c0 <usertrapret_thread>
}
    80001a58:	60a2                	ld	ra,8(sp)
    80001a5a:	6402                	ld	s0,0(sp)
    80001a5c:	0141                	addi	sp,sp,16
    80001a5e:	8082                	ret
    first = 0;
    80001a60:	00007797          	auipc	a5,0x7
    80001a64:	e807a823          	sw	zero,-368(a5) # 800088f0 <first.1726>
    fsinit(ROOTDEV);
    80001a68:	4505                	li	a0,1
    80001a6a:	00002097          	auipc	ra,0x2
    80001a6e:	c6e080e7          	jalr	-914(ra) # 800036d8 <fsinit>
    80001a72:	bff9                	j	80001a50 <forkret_thread+0x22>

0000000080001a74 <allocpid>:
allocpid() {
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a80:	00010917          	auipc	s2,0x10
    80001a84:	82090913          	addi	s2,s2,-2016 # 800112a0 <pid_lock>
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	15a080e7          	jalr	346(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	e6678793          	addi	a5,a5,-410 # 800088f8 <nextpid>
    80001a9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9c:	0014871b          	addiw	a4,s1,1
    80001aa0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa2:	854a                	mv	a0,s2
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	1f4080e7          	jalr	500(ra) # 80000c98 <release>
}
    80001aac:	8526                	mv	a0,s1
    80001aae:	60e2                	ld	ra,24(sp)
    80001ab0:	6442                	ld	s0,16(sp)
    80001ab2:	64a2                	ld	s1,8(sp)
    80001ab4:	6902                	ld	s2,0(sp)
    80001ab6:	6105                	addi	sp,sp,32
    80001ab8:	8082                	ret

0000000080001aba <proc_pagetable>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
    80001ac6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac8:	00000097          	auipc	ra,0x0
    80001acc:	872080e7          	jalr	-1934(ra) # 8000133a <uvmcreate>
    80001ad0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad2:	c121                	beqz	a0,80001b12 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad4:	4729                	li	a4,10
    80001ad6:	00005697          	auipc	a3,0x5
    80001ada:	52a68693          	addi	a3,a3,1322 # 80007000 <_trampoline>
    80001ade:	6605                	lui	a2,0x1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	5c8080e7          	jalr	1480(ra) # 800010b0 <mappages>
    80001af0:	02054863          	bltz	a0,80001b20 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af4:	4719                	li	a4,6
    80001af6:	06093683          	ld	a3,96(s2)
    80001afa:	6605                	lui	a2,0x1
    80001afc:	020005b7          	lui	a1,0x2000
    80001b00:	15fd                	addi	a1,a1,-1
    80001b02:	05b6                	slli	a1,a1,0xd
    80001b04:	8526                	mv	a0,s1
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	5aa080e7          	jalr	1450(ra) # 800010b0 <mappages>
    80001b0e:	02054163          	bltz	a0,80001b30 <proc_pagetable+0x76>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a12080e7          	jalr	-1518(ra) # 80001536 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	b7d5                	j	80001b12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	738080e7          	jalr	1848(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b46:	4581                	li	a1,0
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9ec080e7          	jalr	-1556(ra) # 80001536 <uvmfree>
    return 0;
    80001b52:	4481                	li	s1,0
    80001b54:	bf7d                	j	80001b12 <proc_pagetable+0x58>

0000000080001b56 <proc_freepagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
    80001b64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	704080e7          	jalr	1796(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	020005b7          	lui	a1,0x2000
    80001b82:	15fd                	addi	a1,a1,-1
    80001b84:	05b6                	slli	a1,a1,0xd
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	6ee080e7          	jalr	1774(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b90:	85ca                	mv	a1,s2
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	9a2080e7          	jalr	-1630(ra) # 80001536 <uvmfree>
}
    80001b9c:	60e2                	ld	ra,24(sp)
    80001b9e:	6442                	ld	s0,16(sp)
    80001ba0:	64a2                	ld	s1,8(sp)
    80001ba2:	6902                	ld	s2,0(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <freeproc>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb4:	7128                	ld	a0,96(a0)
    80001bb6:	c509                	beqz	a0,80001bc0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	e40080e7          	jalr	-448(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001bc0:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001bc4:	6ca8                	ld	a0,88(s1)
    80001bc6:	c511                	beqz	a0,80001bd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc8:	68ac                	ld	a1,80(s1)
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	f8c080e7          	jalr	-116(ra) # 80001b56 <proc_freepagetable>
  p->pagetable = 0;
    80001bd2:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001bd6:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001bda:	0204a823          	sw	zero,48(s1)
  p->tid = 0; //LAB3
    80001bde:	0204aa23          	sw	zero,52(s1)
  p->tcnt = 0;//LAB3
    80001be2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001be6:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001bea:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001bee:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bf2:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bf6:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bfa:	0004ac23          	sw	zero,24(s1)
}
    80001bfe:	60e2                	ld	ra,24(sp)
    80001c00:	6442                	ld	s0,16(sp)
    80001c02:	64a2                	ld	s1,8(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret

0000000080001c08 <allocproc>:
{
    80001c08:	1101                	addi	sp,sp,-32
    80001c0a:	ec06                	sd	ra,24(sp)
    80001c0c:	e822                	sd	s0,16(sp)
    80001c0e:	e426                	sd	s1,8(sp)
    80001c10:	e04a                	sd	s2,0(sp)
    80001c12:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c14:	00010497          	auipc	s1,0x10
    80001c18:	abc48493          	addi	s1,s1,-1348 # 800116d0 <proc>
    80001c1c:	00015917          	auipc	s2,0x15
    80001c20:	6b490913          	addi	s2,s2,1716 # 800172d0 <tickslock>
    acquire(&p->lock);
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	fbe080e7          	jalr	-66(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001c2e:	4c9c                	lw	a5,24(s1)
    80001c30:	cf81                	beqz	a5,80001c48 <allocproc+0x40>
      release(&p->lock);
    80001c32:	8526                	mv	a0,s1
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	064080e7          	jalr	100(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3c:	17048493          	addi	s1,s1,368
    80001c40:	ff2492e3          	bne	s1,s2,80001c24 <allocproc+0x1c>
  return 0;
    80001c44:	4481                	li	s1,0
    80001c46:	a889                	j	80001c98 <allocproc+0x90>
  p->pid = allocpid();
    80001c48:	00000097          	auipc	ra,0x0
    80001c4c:	e2c080e7          	jalr	-468(ra) # 80001a74 <allocpid>
    80001c50:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c52:	4785                	li	a5,1
    80001c54:	cc9c                	sw	a5,24(s1)
  if(((p->trapframe = (struct trapframe *)kalloc()) == 0)){
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	e9e080e7          	jalr	-354(ra) # 80000af4 <kalloc>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	f0a8                	sd	a0,96(s1)
    80001c62:	c131                	beqz	a0,80001ca6 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e54080e7          	jalr	-428(ra) # 80001aba <proc_pagetable>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c72:	c531                	beqz	a0,80001cbe <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c74:	07000613          	li	a2,112
    80001c78:	4581                	li	a1,0
    80001c7a:	06848513          	addi	a0,s1,104
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	062080e7          	jalr	98(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c86:	00000797          	auipc	a5,0x0
    80001c8a:	d6278793          	addi	a5,a5,-670 # 800019e8 <forkret>
    80001c8e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c90:	64bc                	ld	a5,72(s1)
    80001c92:	6705                	lui	a4,0x1
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	f8bc                	sd	a5,112(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f00080e7          	jalr	-256(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	bff1                	j	80001c98 <allocproc+0x90>
    freeproc(p);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	00000097          	auipc	ra,0x0
    80001cc4:	ee8080e7          	jalr	-280(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fce080e7          	jalr	-50(ra) # 80000c98 <release>
    return 0;
    80001cd2:	84ca                	mv	s1,s2
    80001cd4:	b7d1                	j	80001c98 <allocproc+0x90>

0000000080001cd6 <userinit>:
{
    80001cd6:	1101                	addi	sp,sp,-32
    80001cd8:	ec06                	sd	ra,24(sp)
    80001cda:	e822                	sd	s0,16(sp)
    80001cdc:	e426                	sd	s1,8(sp)
    80001cde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	f28080e7          	jalr	-216(ra) # 80001c08 <allocproc>
    80001ce8:	84aa                	mv	s1,a0
  initproc = p;
    80001cea:	00007797          	auipc	a5,0x7
    80001cee:	32a7bf23          	sd	a0,830(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf2:	03400613          	li	a2,52
    80001cf6:	00007597          	auipc	a1,0x7
    80001cfa:	c0a58593          	addi	a1,a1,-1014 # 80008900 <initcode>
    80001cfe:	6d28                	ld	a0,88(a0)
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	668080e7          	jalr	1640(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0c:	70b8                	ld	a4,96(s1)
    80001d0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d12:	70b8                	ld	a4,96(s1)
    80001d14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d16:	4641                	li	a2,16
    80001d18:	00006597          	auipc	a1,0x6
    80001d1c:	4e858593          	addi	a1,a1,1256 # 80008200 <digits+0x1c0>
    80001d20:	16048513          	addi	a0,s1,352
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	10e080e7          	jalr	270(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d2c:	00006517          	auipc	a0,0x6
    80001d30:	4e450513          	addi	a0,a0,1252 # 80008210 <digits+0x1d0>
    80001d34:	00002097          	auipc	ra,0x2
    80001d38:	3d2080e7          	jalr	978(ra) # 80004106 <namei>
    80001d3c:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d40:	478d                	li	a5,3
    80001d42:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	f52080e7          	jalr	-174(ra) # 80000c98 <release>
}
    80001d4e:	60e2                	ld	ra,24(sp)
    80001d50:	6442                	ld	s0,16(sp)
    80001d52:	64a2                	ld	s1,8(sp)
    80001d54:	6105                	addi	sp,sp,32
    80001d56:	8082                	ret

0000000080001d58 <growproc>:
{
    80001d58:	1101                	addi	sp,sp,-32
    80001d5a:	ec06                	sd	ra,24(sp)
    80001d5c:	e822                	sd	s0,16(sp)
    80001d5e:	e426                	sd	s1,8(sp)
    80001d60:	e04a                	sd	s2,0(sp)
    80001d62:	1000                	addi	s0,sp,32
    80001d64:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	c4a080e7          	jalr	-950(ra) # 800019b0 <myproc>
    80001d6e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d70:	692c                	ld	a1,80(a0)
    80001d72:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d76:	00904f63          	bgtz	s1,80001d94 <growproc+0x3c>
  } else if(n < 0){
    80001d7a:	0204cc63          	bltz	s1,80001db2 <growproc+0x5a>
  p->sz = sz;
    80001d7e:	1602                	slli	a2,a2,0x20
    80001d80:	9201                	srli	a2,a2,0x20
    80001d82:	04c93823          	sd	a2,80(s2)
  return 0;
    80001d86:	4501                	li	a0,0
}
    80001d88:	60e2                	ld	ra,24(sp)
    80001d8a:	6442                	ld	s0,16(sp)
    80001d8c:	64a2                	ld	s1,8(sp)
    80001d8e:	6902                	ld	s2,0(sp)
    80001d90:	6105                	addi	sp,sp,32
    80001d92:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d94:	9e25                	addw	a2,a2,s1
    80001d96:	1602                	slli	a2,a2,0x20
    80001d98:	9201                	srli	a2,a2,0x20
    80001d9a:	1582                	slli	a1,a1,0x20
    80001d9c:	9181                	srli	a1,a1,0x20
    80001d9e:	6d28                	ld	a0,88(a0)
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	682080e7          	jalr	1666(ra) # 80001422 <uvmalloc>
    80001da8:	0005061b          	sext.w	a2,a0
    80001dac:	fa69                	bnez	a2,80001d7e <growproc+0x26>
      return -1;
    80001dae:	557d                	li	a0,-1
    80001db0:	bfe1                	j	80001d88 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db2:	9e25                	addw	a2,a2,s1
    80001db4:	1602                	slli	a2,a2,0x20
    80001db6:	9201                	srli	a2,a2,0x20
    80001db8:	1582                	slli	a1,a1,0x20
    80001dba:	9181                	srli	a1,a1,0x20
    80001dbc:	6d28                	ld	a0,88(a0)
    80001dbe:	fffff097          	auipc	ra,0xfffff
    80001dc2:	61c080e7          	jalr	1564(ra) # 800013da <uvmdealloc>
    80001dc6:	0005061b          	sext.w	a2,a0
    80001dca:	bf55                	j	80001d7e <growproc+0x26>

0000000080001dcc <fork>:
{
    80001dcc:	7179                	addi	sp,sp,-48
    80001dce:	f406                	sd	ra,40(sp)
    80001dd0:	f022                	sd	s0,32(sp)
    80001dd2:	ec26                	sd	s1,24(sp)
    80001dd4:	e84a                	sd	s2,16(sp)
    80001dd6:	e44e                	sd	s3,8(sp)
    80001dd8:	e052                	sd	s4,0(sp)
    80001dda:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	bd4080e7          	jalr	-1068(ra) # 800019b0 <myproc>
    80001de4:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	e22080e7          	jalr	-478(ra) # 80001c08 <allocproc>
    80001dee:	10050b63          	beqz	a0,80001f04 <fork+0x138>
    80001df2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df4:	05093603          	ld	a2,80(s2)
    80001df8:	6d2c                	ld	a1,88(a0)
    80001dfa:	05893503          	ld	a0,88(s2)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	770080e7          	jalr	1904(ra) # 8000156e <uvmcopy>
    80001e06:	04054663          	bltz	a0,80001e52 <fork+0x86>
  np->sz = p->sz;
    80001e0a:	05093783          	ld	a5,80(s2)
    80001e0e:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	06093683          	ld	a3,96(s2)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	0609b703          	ld	a4,96(s3)
    80001e1c:	12068693          	addi	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	addi	a5,a5,32
    80001e38:	02070713          	addi	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e40:	0609b783          	ld	a5,96(s3)
    80001e44:	0607b823          	sd	zero,112(a5)
    80001e48:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    80001e4c:	15800a13          	li	s4,344
    80001e50:	a03d                	j	80001e7e <fork+0xb2>
    freeproc(np);
    80001e52:	854e                	mv	a0,s3
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	d54080e7          	jalr	-684(ra) # 80001ba8 <freeproc>
    release(&np->lock);
    80001e5c:	854e                	mv	a0,s3
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e3a080e7          	jalr	-454(ra) # 80000c98 <release>
    return -1;
    80001e66:	5a7d                	li	s4,-1
    80001e68:	a069                	j	80001ef2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e6a:	00003097          	auipc	ra,0x3
    80001e6e:	932080e7          	jalr	-1742(ra) # 8000479c <filedup>
    80001e72:	009987b3          	add	a5,s3,s1
    80001e76:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e78:	04a1                	addi	s1,s1,8
    80001e7a:	01448763          	beq	s1,s4,80001e88 <fork+0xbc>
    if(p->ofile[i])
    80001e7e:	009907b3          	add	a5,s2,s1
    80001e82:	6388                	ld	a0,0(a5)
    80001e84:	f17d                	bnez	a0,80001e6a <fork+0x9e>
    80001e86:	bfcd                	j	80001e78 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e88:	15893503          	ld	a0,344(s2)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	a86080e7          	jalr	-1402(ra) # 80003912 <idup>
    80001e94:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	16090593          	addi	a1,s2,352
    80001e9e:	16098513          	addi	a0,s3,352
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	f90080e7          	jalr	-112(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001eaa:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eae:	854e                	mv	a0,s3
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	de8080e7          	jalr	-536(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eb8:	0000f497          	auipc	s1,0xf
    80001ebc:	40048493          	addi	s1,s1,1024 # 800112b8 <wait_lock>
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d22080e7          	jalr	-734(ra) # 80000be4 <acquire>
  np->parent = p;
    80001eca:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001ece:	8526                	mv	a0,s1
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	dc8080e7          	jalr	-568(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ed8:	854e                	mv	a0,s3
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	d0a080e7          	jalr	-758(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ee2:	478d                	li	a5,3
    80001ee4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	dae080e7          	jalr	-594(ra) # 80000c98 <release>
}
    80001ef2:	8552                	mv	a0,s4
    80001ef4:	70a2                	ld	ra,40(sp)
    80001ef6:	7402                	ld	s0,32(sp)
    80001ef8:	64e2                	ld	s1,24(sp)
    80001efa:	6942                	ld	s2,16(sp)
    80001efc:	69a2                	ld	s3,8(sp)
    80001efe:	6a02                	ld	s4,0(sp)
    80001f00:	6145                	addi	sp,sp,48
    80001f02:	8082                	ret
    return -1;
    80001f04:	5a7d                	li	s4,-1
    80001f06:	b7f5                	j	80001ef2 <fork+0x126>

0000000080001f08 <scheduler>:
{
    80001f08:	7139                	addi	sp,sp,-64
    80001f0a:	fc06                	sd	ra,56(sp)
    80001f0c:	f822                	sd	s0,48(sp)
    80001f0e:	f426                	sd	s1,40(sp)
    80001f10:	f04a                	sd	s2,32(sp)
    80001f12:	ec4e                	sd	s3,24(sp)
    80001f14:	e852                	sd	s4,16(sp)
    80001f16:	e456                	sd	s5,8(sp)
    80001f18:	e05a                	sd	s6,0(sp)
    80001f1a:	0080                	addi	s0,sp,64
    80001f1c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f1e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f20:	00779a93          	slli	s5,a5,0x7
    80001f24:	0000f717          	auipc	a4,0xf
    80001f28:	37c70713          	addi	a4,a4,892 # 800112a0 <pid_lock>
    80001f2c:	9756                	add	a4,a4,s5
    80001f2e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f32:	0000f717          	auipc	a4,0xf
    80001f36:	3a670713          	addi	a4,a4,934 # 800112d8 <cpus+0x8>
    80001f3a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f3c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f3e:	4b11                	li	s6,4
        c->proc = p;
    80001f40:	079e                	slli	a5,a5,0x7
    80001f42:	0000fa17          	auipc	s4,0xf
    80001f46:	35ea0a13          	addi	s4,s4,862 # 800112a0 <pid_lock>
    80001f4a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4c:	00015917          	auipc	s2,0x15
    80001f50:	38490913          	addi	s2,s2,900 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f54:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f58:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f5c:	10079073          	csrw	sstatus,a5
    80001f60:	0000f497          	auipc	s1,0xf
    80001f64:	77048493          	addi	s1,s1,1904 # 800116d0 <proc>
    80001f68:	a03d                	j	80001f96 <scheduler+0x8e>
        p->state = RUNNING;
    80001f6a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f6e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f72:	06848593          	addi	a1,s1,104
    80001f76:	8556                	mv	a0,s5
    80001f78:	00001097          	auipc	ra,0x1
    80001f7c:	800080e7          	jalr	-2048(ra) # 80002778 <swtch>
        c->proc = 0;
    80001f80:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d12080e7          	jalr	-750(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8e:	17048493          	addi	s1,s1,368
    80001f92:	fd2481e3          	beq	s1,s2,80001f54 <scheduler+0x4c>
      acquire(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	c4c080e7          	jalr	-948(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80001fa0:	4c9c                	lw	a5,24(s1)
    80001fa2:	ff3791e3          	bne	a5,s3,80001f84 <scheduler+0x7c>
    80001fa6:	b7d1                	j	80001f6a <scheduler+0x62>

0000000080001fa8 <sched>:
{
    80001fa8:	7179                	addi	sp,sp,-48
    80001faa:	f406                	sd	ra,40(sp)
    80001fac:	f022                	sd	s0,32(sp)
    80001fae:	ec26                	sd	s1,24(sp)
    80001fb0:	e84a                	sd	s2,16(sp)
    80001fb2:	e44e                	sd	s3,8(sp)
    80001fb4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	9fa080e7          	jalr	-1542(ra) # 800019b0 <myproc>
    80001fbe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	baa080e7          	jalr	-1110(ra) # 80000b6a <holding>
    80001fc8:	c93d                	beqz	a0,8000203e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fca:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fcc:	2781                	sext.w	a5,a5
    80001fce:	079e                	slli	a5,a5,0x7
    80001fd0:	0000f717          	auipc	a4,0xf
    80001fd4:	2d070713          	addi	a4,a4,720 # 800112a0 <pid_lock>
    80001fd8:	97ba                	add	a5,a5,a4
    80001fda:	0a87a703          	lw	a4,168(a5)
    80001fde:	4785                	li	a5,1
    80001fe0:	06f71763          	bne	a4,a5,8000204e <sched+0xa6>
  if(p->state == RUNNING)
    80001fe4:	4c98                	lw	a4,24(s1)
    80001fe6:	4791                	li	a5,4
    80001fe8:	06f70b63          	beq	a4,a5,8000205e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fec:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ff2:	efb5                	bnez	a5,8000206e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff6:	0000f917          	auipc	s2,0xf
    80001ffa:	2aa90913          	addi	s2,s2,682 # 800112a0 <pid_lock>
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	97ca                	add	a5,a5,s2
    80002004:	0ac7a983          	lw	s3,172(a5)
    80002008:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000200a:	2781                	sext.w	a5,a5
    8000200c:	079e                	slli	a5,a5,0x7
    8000200e:	0000f597          	auipc	a1,0xf
    80002012:	2ca58593          	addi	a1,a1,714 # 800112d8 <cpus+0x8>
    80002016:	95be                	add	a1,a1,a5
    80002018:	06848513          	addi	a0,s1,104
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	75c080e7          	jalr	1884(ra) # 80002778 <swtch>
    80002024:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002026:	2781                	sext.w	a5,a5
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	97ca                	add	a5,a5,s2
    8000202c:	0b37a623          	sw	s3,172(a5)
}
    80002030:	70a2                	ld	ra,40(sp)
    80002032:	7402                	ld	s0,32(sp)
    80002034:	64e2                	ld	s1,24(sp)
    80002036:	6942                	ld	s2,16(sp)
    80002038:	69a2                	ld	s3,8(sp)
    8000203a:	6145                	addi	sp,sp,48
    8000203c:	8082                	ret
    panic("sched p->lock");
    8000203e:	00006517          	auipc	a0,0x6
    80002042:	1da50513          	addi	a0,a0,474 # 80008218 <digits+0x1d8>
    80002046:	ffffe097          	auipc	ra,0xffffe
    8000204a:	4f8080e7          	jalr	1272(ra) # 8000053e <panic>
    panic("sched locks");
    8000204e:	00006517          	auipc	a0,0x6
    80002052:	1da50513          	addi	a0,a0,474 # 80008228 <digits+0x1e8>
    80002056:	ffffe097          	auipc	ra,0xffffe
    8000205a:	4e8080e7          	jalr	1256(ra) # 8000053e <panic>
    panic("sched running");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	1da50513          	addi	a0,a0,474 # 80008238 <digits+0x1f8>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4d8080e7          	jalr	1240(ra) # 8000053e <panic>
    panic("sched interruptible");
    8000206e:	00006517          	auipc	a0,0x6
    80002072:	1da50513          	addi	a0,a0,474 # 80008248 <digits+0x208>
    80002076:	ffffe097          	auipc	ra,0xffffe
    8000207a:	4c8080e7          	jalr	1224(ra) # 8000053e <panic>

000000008000207e <yield>:
{
    8000207e:	1101                	addi	sp,sp,-32
    80002080:	ec06                	sd	ra,24(sp)
    80002082:	e822                	sd	s0,16(sp)
    80002084:	e426                	sd	s1,8(sp)
    80002086:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002088:	00000097          	auipc	ra,0x0
    8000208c:	928080e7          	jalr	-1752(ra) # 800019b0 <myproc>
    80002090:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	b52080e7          	jalr	-1198(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    8000209a:	478d                	li	a5,3
    8000209c:	cc9c                	sw	a5,24(s1)
  sched();
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	f0a080e7          	jalr	-246(ra) # 80001fa8 <sched>
  release(&p->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	bf0080e7          	jalr	-1040(ra) # 80000c98 <release>
}
    800020b0:	60e2                	ld	ra,24(sp)
    800020b2:	6442                	ld	s0,16(sp)
    800020b4:	64a2                	ld	s1,8(sp)
    800020b6:	6105                	addi	sp,sp,32
    800020b8:	8082                	ret

00000000800020ba <sleep>:
{
    800020ba:	7179                	addi	sp,sp,-48
    800020bc:	f406                	sd	ra,40(sp)
    800020be:	f022                	sd	s0,32(sp)
    800020c0:	ec26                	sd	s1,24(sp)
    800020c2:	e84a                	sd	s2,16(sp)
    800020c4:	e44e                	sd	s3,8(sp)
    800020c6:	1800                	addi	s0,sp,48
    800020c8:	89aa                	mv	s3,a0
    800020ca:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	8e4080e7          	jalr	-1820(ra) # 800019b0 <myproc>
    800020d4:	84aa                	mv	s1,a0
  acquire(&p->lock);  //DOC: sleeplock1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	b0e080e7          	jalr	-1266(ra) # 80000be4 <acquire>
  release(lk);
    800020de:	854a                	mv	a0,s2
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	bb8080e7          	jalr	-1096(ra) # 80000c98 <release>
  p->chan = chan;
    800020e8:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ec:	4789                	li	a5,2
    800020ee:	cc9c                	sw	a5,24(s1)
  sched();
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	eb8080e7          	jalr	-328(ra) # 80001fa8 <sched>
  p->chan = 0;
    800020f8:	0204b023          	sd	zero,32(s1)
  release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	b9a080e7          	jalr	-1126(ra) # 80000c98 <release>
  acquire(lk);
    80002106:	854a                	mv	a0,s2
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	adc080e7          	jalr	-1316(ra) # 80000be4 <acquire>
}
    80002110:	70a2                	ld	ra,40(sp)
    80002112:	7402                	ld	s0,32(sp)
    80002114:	64e2                	ld	s1,24(sp)
    80002116:	6942                	ld	s2,16(sp)
    80002118:	69a2                	ld	s3,8(sp)
    8000211a:	6145                	addi	sp,sp,48
    8000211c:	8082                	ret

000000008000211e <wait>:
{
    8000211e:	715d                	addi	sp,sp,-80
    80002120:	e486                	sd	ra,72(sp)
    80002122:	e0a2                	sd	s0,64(sp)
    80002124:	fc26                	sd	s1,56(sp)
    80002126:	f84a                	sd	s2,48(sp)
    80002128:	f44e                	sd	s3,40(sp)
    8000212a:	f052                	sd	s4,32(sp)
    8000212c:	ec56                	sd	s5,24(sp)
    8000212e:	e85a                	sd	s6,16(sp)
    80002130:	e45e                	sd	s7,8(sp)
    80002132:	e062                	sd	s8,0(sp)
    80002134:	0880                	addi	s0,sp,80
    80002136:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002138:	00000097          	auipc	ra,0x0
    8000213c:	878080e7          	jalr	-1928(ra) # 800019b0 <myproc>
    80002140:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002142:	0000f517          	auipc	a0,0xf
    80002146:	17650513          	addi	a0,a0,374 # 800112b8 <wait_lock>
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	a9a080e7          	jalr	-1382(ra) # 80000be4 <acquire>
    havekids = 0;
    80002152:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002154:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002156:	00015997          	auipc	s3,0x15
    8000215a:	17a98993          	addi	s3,s3,378 # 800172d0 <tickslock>
        havekids = 1;
    8000215e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002160:	0000fc17          	auipc	s8,0xf
    80002164:	158c0c13          	addi	s8,s8,344 # 800112b8 <wait_lock>
    havekids = 0;
    80002168:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000216a:	0000f497          	auipc	s1,0xf
    8000216e:	56648493          	addi	s1,s1,1382 # 800116d0 <proc>
    80002172:	a0bd                	j	800021e0 <wait+0xc2>
          pid = np->pid;
    80002174:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002178:	000b0e63          	beqz	s6,80002194 <wait+0x76>
    8000217c:	4691                	li	a3,4
    8000217e:	02c48613          	addi	a2,s1,44
    80002182:	85da                	mv	a1,s6
    80002184:	05893503          	ld	a0,88(s2)
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	4ea080e7          	jalr	1258(ra) # 80001672 <copyout>
    80002190:	02054563          	bltz	a0,800021ba <wait+0x9c>
          freeproc(np);
    80002194:	8526                	mv	a0,s1
    80002196:	00000097          	auipc	ra,0x0
    8000219a:	a12080e7          	jalr	-1518(ra) # 80001ba8 <freeproc>
          release(&np->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	af8080e7          	jalr	-1288(ra) # 80000c98 <release>
          release(&wait_lock);
    800021a8:	0000f517          	auipc	a0,0xf
    800021ac:	11050513          	addi	a0,a0,272 # 800112b8 <wait_lock>
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ae8080e7          	jalr	-1304(ra) # 80000c98 <release>
          return pid;
    800021b8:	a09d                	j	8000221e <wait+0x100>
            release(&np->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	adc080e7          	jalr	-1316(ra) # 80000c98 <release>
            release(&wait_lock);
    800021c4:	0000f517          	auipc	a0,0xf
    800021c8:	0f450513          	addi	a0,a0,244 # 800112b8 <wait_lock>
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	acc080e7          	jalr	-1332(ra) # 80000c98 <release>
            return -1;
    800021d4:	59fd                	li	s3,-1
    800021d6:	a0a1                	j	8000221e <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    800021d8:	17048493          	addi	s1,s1,368
    800021dc:	03348463          	beq	s1,s3,80002204 <wait+0xe6>
      if(np->parent == p){
    800021e0:	60bc                	ld	a5,64(s1)
    800021e2:	ff279be3          	bne	a5,s2,800021d8 <wait+0xba>
        acquire(&np->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	9fc080e7          	jalr	-1540(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    800021f0:	4c9c                	lw	a5,24(s1)
    800021f2:	f94781e3          	beq	a5,s4,80002174 <wait+0x56>
        release(&np->lock);
    800021f6:	8526                	mv	a0,s1
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	aa0080e7          	jalr	-1376(ra) # 80000c98 <release>
        havekids = 1;
    80002200:	8756                	mv	a4,s5
    80002202:	bfd9                	j	800021d8 <wait+0xba>
    if(!havekids || p->killed){
    80002204:	c701                	beqz	a4,8000220c <wait+0xee>
    80002206:	02892783          	lw	a5,40(s2)
    8000220a:	c79d                	beqz	a5,80002238 <wait+0x11a>
      release(&wait_lock);
    8000220c:	0000f517          	auipc	a0,0xf
    80002210:	0ac50513          	addi	a0,a0,172 # 800112b8 <wait_lock>
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	a84080e7          	jalr	-1404(ra) # 80000c98 <release>
      return -1;
    8000221c:	59fd                	li	s3,-1
}
    8000221e:	854e                	mv	a0,s3
    80002220:	60a6                	ld	ra,72(sp)
    80002222:	6406                	ld	s0,64(sp)
    80002224:	74e2                	ld	s1,56(sp)
    80002226:	7942                	ld	s2,48(sp)
    80002228:	79a2                	ld	s3,40(sp)
    8000222a:	7a02                	ld	s4,32(sp)
    8000222c:	6ae2                	ld	s5,24(sp)
    8000222e:	6b42                	ld	s6,16(sp)
    80002230:	6ba2                	ld	s7,8(sp)
    80002232:	6c02                	ld	s8,0(sp)
    80002234:	6161                	addi	sp,sp,80
    80002236:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002238:	85e2                	mv	a1,s8
    8000223a:	854a                	mv	a0,s2
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	e7e080e7          	jalr	-386(ra) # 800020ba <sleep>
    havekids = 0;
    80002244:	b715                	j	80002168 <wait+0x4a>

0000000080002246 <wakeup>:
{
    80002246:	7139                	addi	sp,sp,-64
    80002248:	fc06                	sd	ra,56(sp)
    8000224a:	f822                	sd	s0,48(sp)
    8000224c:	f426                	sd	s1,40(sp)
    8000224e:	f04a                	sd	s2,32(sp)
    80002250:	ec4e                	sd	s3,24(sp)
    80002252:	e852                	sd	s4,16(sp)
    80002254:	e456                	sd	s5,8(sp)
    80002256:	0080                	addi	s0,sp,64
    80002258:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000225a:	0000f497          	auipc	s1,0xf
    8000225e:	47648493          	addi	s1,s1,1142 # 800116d0 <proc>
      if(p->state == SLEEPING && p->chan == chan) {
    80002262:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002264:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002266:	00015917          	auipc	s2,0x15
    8000226a:	06a90913          	addi	s2,s2,106 # 800172d0 <tickslock>
    8000226e:	a821                	j	80002286 <wakeup+0x40>
        p->state = RUNNABLE;
    80002270:	0154ac23          	sw	s5,24(s1)
      release(&p->lock);
    80002274:	8526                	mv	a0,s1
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	a22080e7          	jalr	-1502(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000227e:	17048493          	addi	s1,s1,368
    80002282:	03248463          	beq	s1,s2,800022aa <wakeup+0x64>
    if(p != myproc()){
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	72a080e7          	jalr	1834(ra) # 800019b0 <myproc>
    8000228e:	fea488e3          	beq	s1,a0,8000227e <wakeup+0x38>
      acquire(&p->lock);
    80002292:	8526                	mv	a0,s1
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	950080e7          	jalr	-1712(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000229c:	4c9c                	lw	a5,24(s1)
    8000229e:	fd379be3          	bne	a5,s3,80002274 <wakeup+0x2e>
    800022a2:	709c                	ld	a5,32(s1)
    800022a4:	fd4798e3          	bne	a5,s4,80002274 <wakeup+0x2e>
    800022a8:	b7e1                	j	80002270 <wakeup+0x2a>
}
    800022aa:	70e2                	ld	ra,56(sp)
    800022ac:	7442                	ld	s0,48(sp)
    800022ae:	74a2                	ld	s1,40(sp)
    800022b0:	7902                	ld	s2,32(sp)
    800022b2:	69e2                	ld	s3,24(sp)
    800022b4:	6a42                	ld	s4,16(sp)
    800022b6:	6aa2                	ld	s5,8(sp)
    800022b8:	6121                	addi	sp,sp,64
    800022ba:	8082                	ret

00000000800022bc <reparent>:
{
    800022bc:	7179                	addi	sp,sp,-48
    800022be:	f406                	sd	ra,40(sp)
    800022c0:	f022                	sd	s0,32(sp)
    800022c2:	ec26                	sd	s1,24(sp)
    800022c4:	e84a                	sd	s2,16(sp)
    800022c6:	e44e                	sd	s3,8(sp)
    800022c8:	e052                	sd	s4,0(sp)
    800022ca:	1800                	addi	s0,sp,48
    800022cc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022ce:	0000f497          	auipc	s1,0xf
    800022d2:	40248493          	addi	s1,s1,1026 # 800116d0 <proc>
      pp->parent = initproc;
    800022d6:	00007a17          	auipc	s4,0x7
    800022da:	d52a0a13          	addi	s4,s4,-686 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800022de:	00015997          	auipc	s3,0x15
    800022e2:	ff298993          	addi	s3,s3,-14 # 800172d0 <tickslock>
    800022e6:	a029                	j	800022f0 <reparent+0x34>
    800022e8:	17048493          	addi	s1,s1,368
    800022ec:	01348d63          	beq	s1,s3,80002306 <reparent+0x4a>
    if(pp->parent == p){
    800022f0:	60bc                	ld	a5,64(s1)
    800022f2:	ff279be3          	bne	a5,s2,800022e8 <reparent+0x2c>
      pp->parent = initproc;
    800022f6:	000a3503          	ld	a0,0(s4)
    800022fa:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	f4a080e7          	jalr	-182(ra) # 80002246 <wakeup>
    80002304:	b7d5                	j	800022e8 <reparent+0x2c>
}
    80002306:	70a2                	ld	ra,40(sp)
    80002308:	7402                	ld	s0,32(sp)
    8000230a:	64e2                	ld	s1,24(sp)
    8000230c:	6942                	ld	s2,16(sp)
    8000230e:	69a2                	ld	s3,8(sp)
    80002310:	6a02                	ld	s4,0(sp)
    80002312:	6145                	addi	sp,sp,48
    80002314:	8082                	ret

0000000080002316 <exit>:
{
    80002316:	7179                	addi	sp,sp,-48
    80002318:	f406                	sd	ra,40(sp)
    8000231a:	f022                	sd	s0,32(sp)
    8000231c:	ec26                	sd	s1,24(sp)
    8000231e:	e84a                	sd	s2,16(sp)
    80002320:	e44e                	sd	s3,8(sp)
    80002322:	e052                	sd	s4,0(sp)
    80002324:	1800                	addi	s0,sp,48
    80002326:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	688080e7          	jalr	1672(ra) # 800019b0 <myproc>
    80002330:	89aa                	mv	s3,a0
  if(p == initproc)
    80002332:	00007797          	auipc	a5,0x7
    80002336:	cf67b783          	ld	a5,-778(a5) # 80009028 <initproc>
    8000233a:	0d850493          	addi	s1,a0,216
    8000233e:	15850913          	addi	s2,a0,344
    80002342:	02a79363          	bne	a5,a0,80002368 <exit+0x52>
    panic("init exiting");
    80002346:	00006517          	auipc	a0,0x6
    8000234a:	f1a50513          	addi	a0,a0,-230 # 80008260 <digits+0x220>
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	1f0080e7          	jalr	496(ra) # 8000053e <panic>
      fileclose(f);
    80002356:	00002097          	auipc	ra,0x2
    8000235a:	498080e7          	jalr	1176(ra) # 800047ee <fileclose>
      p->ofile[fd] = 0;
    8000235e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002362:	04a1                	addi	s1,s1,8
    80002364:	01248563          	beq	s1,s2,8000236e <exit+0x58>
    if(p->ofile[fd]){
    80002368:	6088                	ld	a0,0(s1)
    8000236a:	f575                	bnez	a0,80002356 <exit+0x40>
    8000236c:	bfdd                	j	80002362 <exit+0x4c>
  begin_op();
    8000236e:	00002097          	auipc	ra,0x2
    80002372:	fb4080e7          	jalr	-76(ra) # 80004322 <begin_op>
  iput(p->cwd);
    80002376:	1589b503          	ld	a0,344(s3)
    8000237a:	00001097          	auipc	ra,0x1
    8000237e:	790080e7          	jalr	1936(ra) # 80003b0a <iput>
  end_op();
    80002382:	00002097          	auipc	ra,0x2
    80002386:	020080e7          	jalr	32(ra) # 800043a2 <end_op>
  p->cwd = 0;
    8000238a:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000238e:	0000f497          	auipc	s1,0xf
    80002392:	f2a48493          	addi	s1,s1,-214 # 800112b8 <wait_lock>
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	84c080e7          	jalr	-1972(ra) # 80000be4 <acquire>
  reparent(p);
    800023a0:	854e                	mv	a0,s3
    800023a2:	00000097          	auipc	ra,0x0
    800023a6:	f1a080e7          	jalr	-230(ra) # 800022bc <reparent>
  wakeup(p->parent);
    800023aa:	0409b503          	ld	a0,64(s3)
    800023ae:	00000097          	auipc	ra,0x0
    800023b2:	e98080e7          	jalr	-360(ra) # 80002246 <wakeup>
  acquire(&p->lock);
    800023b6:	854e                	mv	a0,s3
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	82c080e7          	jalr	-2004(ra) # 80000be4 <acquire>
  p->xstate = status;
    800023c0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023c4:	4795                	li	a5,5
    800023c6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8cc080e7          	jalr	-1844(ra) # 80000c98 <release>
  sched();
    800023d4:	00000097          	auipc	ra,0x0
    800023d8:	bd4080e7          	jalr	-1068(ra) # 80001fa8 <sched>
  panic("zombie exit");
    800023dc:	00006517          	auipc	a0,0x6
    800023e0:	e9450513          	addi	a0,a0,-364 # 80008270 <digits+0x230>
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>

00000000800023ec <kill>:
{
    800023ec:	7179                	addi	sp,sp,-48
    800023ee:	f406                	sd	ra,40(sp)
    800023f0:	f022                	sd	s0,32(sp)
    800023f2:	ec26                	sd	s1,24(sp)
    800023f4:	e84a                	sd	s2,16(sp)
    800023f6:	e44e                	sd	s3,8(sp)
    800023f8:	1800                	addi	s0,sp,48
    800023fa:	892a                	mv	s2,a0
  for(p = proc; p < &proc[NPROC]; p++){
    800023fc:	0000f497          	auipc	s1,0xf
    80002400:	2d448493          	addi	s1,s1,724 # 800116d0 <proc>
    80002404:	00015997          	auipc	s3,0x15
    80002408:	ecc98993          	addi	s3,s3,-308 # 800172d0 <tickslock>
    acquire(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7d6080e7          	jalr	2006(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    80002416:	589c                	lw	a5,48(s1)
    80002418:	01278d63          	beq	a5,s2,80002432 <kill+0x46>
    release(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	87a080e7          	jalr	-1926(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002426:	17048493          	addi	s1,s1,368
    8000242a:	ff3491e3          	bne	s1,s3,8000240c <kill+0x20>
  return -1;
    8000242e:	557d                	li	a0,-1
    80002430:	a829                	j	8000244a <kill+0x5e>
      p->killed = 1;
    80002432:	4785                	li	a5,1
    80002434:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002436:	4c98                	lw	a4,24(s1)
    80002438:	4789                	li	a5,2
    8000243a:	00f70f63          	beq	a4,a5,80002458 <kill+0x6c>
      release(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	858080e7          	jalr	-1960(ra) # 80000c98 <release>
      return 0;
    80002448:	4501                	li	a0,0
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret
        p->state = RUNNABLE;
    80002458:	478d                	li	a5,3
    8000245a:	cc9c                	sw	a5,24(s1)
    8000245c:	b7cd                	j	8000243e <kill+0x52>

000000008000245e <either_copyout>:
{
    8000245e:	7179                	addi	sp,sp,-48
    80002460:	f406                	sd	ra,40(sp)
    80002462:	f022                	sd	s0,32(sp)
    80002464:	ec26                	sd	s1,24(sp)
    80002466:	e84a                	sd	s2,16(sp)
    80002468:	e44e                	sd	s3,8(sp)
    8000246a:	e052                	sd	s4,0(sp)
    8000246c:	1800                	addi	s0,sp,48
    8000246e:	84aa                	mv	s1,a0
    80002470:	892e                	mv	s2,a1
    80002472:	89b2                	mv	s3,a2
    80002474:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	53a080e7          	jalr	1338(ra) # 800019b0 <myproc>
  if(user_dst){
    8000247e:	c08d                	beqz	s1,800024a0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002480:	86d2                	mv	a3,s4
    80002482:	864e                	mv	a2,s3
    80002484:	85ca                	mv	a1,s2
    80002486:	6d28                	ld	a0,88(a0)
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	1ea080e7          	jalr	490(ra) # 80001672 <copyout>
}
    80002490:	70a2                	ld	ra,40(sp)
    80002492:	7402                	ld	s0,32(sp)
    80002494:	64e2                	ld	s1,24(sp)
    80002496:	6942                	ld	s2,16(sp)
    80002498:	69a2                	ld	s3,8(sp)
    8000249a:	6a02                	ld	s4,0(sp)
    8000249c:	6145                	addi	sp,sp,48
    8000249e:	8082                	ret
    memmove((char *)dst, src, len);
    800024a0:	000a061b          	sext.w	a2,s4
    800024a4:	85ce                	mv	a1,s3
    800024a6:	854a                	mv	a0,s2
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	898080e7          	jalr	-1896(ra) # 80000d40 <memmove>
    return 0;
    800024b0:	8526                	mv	a0,s1
    800024b2:	bff9                	j	80002490 <either_copyout+0x32>

00000000800024b4 <either_copyin>:
{
    800024b4:	7179                	addi	sp,sp,-48
    800024b6:	f406                	sd	ra,40(sp)
    800024b8:	f022                	sd	s0,32(sp)
    800024ba:	ec26                	sd	s1,24(sp)
    800024bc:	e84a                	sd	s2,16(sp)
    800024be:	e44e                	sd	s3,8(sp)
    800024c0:	e052                	sd	s4,0(sp)
    800024c2:	1800                	addi	s0,sp,48
    800024c4:	892a                	mv	s2,a0
    800024c6:	84ae                	mv	s1,a1
    800024c8:	89b2                	mv	s3,a2
    800024ca:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	4e4080e7          	jalr	1252(ra) # 800019b0 <myproc>
  if(user_src){
    800024d4:	c08d                	beqz	s1,800024f6 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024d6:	86d2                	mv	a3,s4
    800024d8:	864e                	mv	a2,s3
    800024da:	85ca                	mv	a1,s2
    800024dc:	6d28                	ld	a0,88(a0)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	220080e7          	jalr	544(ra) # 800016fe <copyin>
}
    800024e6:	70a2                	ld	ra,40(sp)
    800024e8:	7402                	ld	s0,32(sp)
    800024ea:	64e2                	ld	s1,24(sp)
    800024ec:	6942                	ld	s2,16(sp)
    800024ee:	69a2                	ld	s3,8(sp)
    800024f0:	6a02                	ld	s4,0(sp)
    800024f2:	6145                	addi	sp,sp,48
    800024f4:	8082                	ret
    memmove(dst, (char*)src, len);
    800024f6:	000a061b          	sext.w	a2,s4
    800024fa:	85ce                	mv	a1,s3
    800024fc:	854a                	mv	a0,s2
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	842080e7          	jalr	-1982(ra) # 80000d40 <memmove>
    return 0;
    80002506:	8526                	mv	a0,s1
    80002508:	bff9                	j	800024e6 <either_copyin+0x32>

000000008000250a <procdump>:
{
    8000250a:	715d                	addi	sp,sp,-80
    8000250c:	e486                	sd	ra,72(sp)
    8000250e:	e0a2                	sd	s0,64(sp)
    80002510:	fc26                	sd	s1,56(sp)
    80002512:	f84a                	sd	s2,48(sp)
    80002514:	f44e                	sd	s3,40(sp)
    80002516:	f052                	sd	s4,32(sp)
    80002518:	ec56                	sd	s5,24(sp)
    8000251a:	e85a                	sd	s6,16(sp)
    8000251c:	e45e                	sd	s7,8(sp)
    8000251e:	0880                	addi	s0,sp,80
  printf("\n");
    80002520:	00006517          	auipc	a0,0x6
    80002524:	ea850513          	addi	a0,a0,-344 # 800083c8 <states.1716+0xd8>
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	060080e7          	jalr	96(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002530:	0000f497          	auipc	s1,0xf
    80002534:	30048493          	addi	s1,s1,768 # 80011830 <proc+0x160>
    80002538:	00015917          	auipc	s2,0x15
    8000253c:	ef890913          	addi	s2,s2,-264 # 80017430 <bcache+0x148>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002540:	4b15                	li	s6,5
      state = "???";
    80002542:	00006997          	auipc	s3,0x6
    80002546:	d3e98993          	addi	s3,s3,-706 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000254a:	00006a97          	auipc	s5,0x6
    8000254e:	d3ea8a93          	addi	s5,s5,-706 # 80008288 <digits+0x248>
    printf("\n");
    80002552:	00006a17          	auipc	s4,0x6
    80002556:	e76a0a13          	addi	s4,s4,-394 # 800083c8 <states.1716+0xd8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255a:	00006b97          	auipc	s7,0x6
    8000255e:	d96b8b93          	addi	s7,s7,-618 # 800082f0 <states.1716>
    80002562:	a00d                	j	80002584 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002564:	ed06a583          	lw	a1,-304(a3)
    80002568:	8556                	mv	a0,s5
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	01e080e7          	jalr	30(ra) # 80000588 <printf>
    printf("\n");
    80002572:	8552                	mv	a0,s4
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257c:	17048493          	addi	s1,s1,368
    80002580:	03248163          	beq	s1,s2,800025a2 <procdump+0x98>
    if(p->state == UNUSED)
    80002584:	86a6                	mv	a3,s1
    80002586:	eb84a783          	lw	a5,-328(s1)
    8000258a:	dbed                	beqz	a5,8000257c <procdump+0x72>
      state = "???";
    8000258c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258e:	fcfb6be3          	bltu	s6,a5,80002564 <procdump+0x5a>
    80002592:	1782                	slli	a5,a5,0x20
    80002594:	9381                	srli	a5,a5,0x20
    80002596:	078e                	slli	a5,a5,0x3
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f661                	bnez	a2,80002564 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7d1                	j	80002564 <procdump+0x5a>
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <clone>:

  return p;
}

int clone(void * stack, int size)
{
    800025b8:	7179                	addi	sp,sp,-48
    800025ba:	f406                	sd	ra,40(sp)
    800025bc:	f022                	sd	s0,32(sp)
    800025be:	ec26                	sd	s1,24(sp)
    800025c0:	e84a                	sd	s2,16(sp)
    800025c2:	e44e                	sd	s3,8(sp)
    800025c4:	e052                	sd	s4,0(sp)
    800025c6:	1800                	addi	s0,sp,48
 
  if (!stack) {
    800025c8:	c121                	beqz	a0,80002608 <clone+0x50>
    800025ca:	8a2a                	mv	s4,a0
    return -1;
  }
  
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	3e4080e7          	jalr	996(ra) # 800019b0 <myproc>
    800025d4:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025d6:	0000f497          	auipc	s1,0xf
    800025da:	0fa48493          	addi	s1,s1,250 # 800116d0 <proc>
    800025de:	00015917          	auipc	s2,0x15
    800025e2:	cf290913          	addi	s2,s2,-782 # 800172d0 <tickslock>
    acquire(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	5fc080e7          	jalr	1532(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    800025f0:	4c9c                	lw	a5,24(s1)
    800025f2:	c785                	beqz	a5,8000261a <clone+0x62>
      release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	6a2080e7          	jalr	1698(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025fe:	17048493          	addi	s1,s1,368
    80002602:	ff2492e3          	bne	s1,s2,800025e6 <clone+0x2e>
    80002606:	a285                	j	80002766 <clone+0x1ae>
    printf("clone: stack is null");
    80002608:	00006517          	auipc	a0,0x6
    8000260c:	c9050513          	addi	a0,a0,-880 # 80008298 <digits+0x258>
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	f78080e7          	jalr	-136(ra) # 80000588 <printf>
    return -1;
    80002618:	a2b9                	j	80002766 <clone+0x1ae>
  p->pid = allocpid();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	45a080e7          	jalr	1114(ra) # 80001a74 <allocpid>
    80002622:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002624:	4785                	li	a5,1
    80002626:	cc9c                	sw	a5,24(s1)
  if(((p->trapframe = (struct trapframe *)kalloc()) == 0)){
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	4cc080e7          	jalr	1228(ra) # 80000af4 <kalloc>
    80002630:	f0a8                	sd	a0,96(s1)
    80002632:	c141                	beqz	a0,800026b2 <clone+0xfa>
  memset(&p->context, 0, sizeof(p->context));
    80002634:	07000613          	li	a2,112
    80002638:	4581                	li	a1,0
    8000263a:	06848513          	addi	a0,s1,104
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	6a2080e7          	jalr	1698(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret_thread;
    80002646:	fffff797          	auipc	a5,0xfffff
    8000264a:	3e878793          	addi	a5,a5,1000 # 80001a2e <forkret_thread>
    8000264e:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002650:	64bc                	ld	a5,72(s1)
    80002652:	6705                	lui	a4,0x1
    80002654:	97ba                	add	a5,a5,a4
    80002656:	f8bc                	sd	a5,112(s1)
  //if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
  //  freeproc(np);
  // release(&np->lock);
  //  return -1;
  //}
  np->pagetable = p->pagetable;
    80002658:	0589b783          	ld	a5,88(s3)
    8000265c:	ecbc                	sd	a5,88(s1)
  np->sz = p->sz;
    8000265e:	0509b783          	ld	a5,80(s3)
    80002662:	e8bc                	sd	a5,80(s1)
  
  //update parent thread count and thread id
  p->tcnt +=1;
    80002664:	0389a783          	lw	a5,56(s3)
    80002668:	2785                	addiw	a5,a5,1
    8000266a:	02f9ac23          	sw	a5,56(s3)
  np->tid = p->tcnt;
    8000266e:	d8dc                	sw	a5,52(s1)

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);
    80002670:	0609b683          	ld	a3,96(s3)
    80002674:	87b6                	mv	a5,a3
    80002676:	70b8                	ld	a4,96(s1)
    80002678:	12068693          	addi	a3,a3,288
    8000267c:	0007b803          	ld	a6,0(a5)
    80002680:	6788                	ld	a0,8(a5)
    80002682:	6b8c                	ld	a1,16(a5)
    80002684:	6f90                	ld	a2,24(a5)
    80002686:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    8000268a:	e708                	sd	a0,8(a4)
    8000268c:	eb0c                	sd	a1,16(a4)
    8000268e:	ef10                	sd	a2,24(a4)
    80002690:	02078793          	addi	a5,a5,32
    80002694:	02070713          	addi	a4,a4,32
    80002698:	fed792e3          	bne	a5,a3,8000267c <clone+0xc4>
  np->trapframe->sp = (uint64) stack;// + size;
    8000269c:	70bc                	ld	a5,96(s1)
    8000269e:	0347b823          	sd	s4,48(a5)
  //np->trapframe->kernel_sp = (uint64) (stack+size);
	
  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;
    800026a2:	70bc                	ld	a5,96(s1)
    800026a4:	0607b823          	sd	zero,112(a5)
    800026a8:	0d800913          	li	s2,216

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    800026ac:	15800a13          	li	s4,344
    800026b0:	a035                	j	800026dc <clone+0x124>
    freeproc(p);
    800026b2:	8526                	mv	a0,s1
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	4f4080e7          	jalr	1268(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	5da080e7          	jalr	1498(ra) # 80000c98 <release>
    return 0;
    800026c6:	a045                	j	80002766 <clone+0x1ae>
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
    800026c8:	00002097          	auipc	ra,0x2
    800026cc:	0d4080e7          	jalr	212(ra) # 8000479c <filedup>
    800026d0:	012487b3          	add	a5,s1,s2
    800026d4:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800026d6:	0921                	addi	s2,s2,8
    800026d8:	01490763          	beq	s2,s4,800026e6 <clone+0x12e>
    if(p->ofile[i])
    800026dc:	012987b3          	add	a5,s3,s2
    800026e0:	6388                	ld	a0,0(a5)
    800026e2:	f17d                	bnez	a0,800026c8 <clone+0x110>
    800026e4:	bfcd                	j	800026d6 <clone+0x11e>
  np->cwd = idup(p->cwd);
    800026e6:	1589b503          	ld	a0,344(s3)
    800026ea:	00001097          	auipc	ra,0x1
    800026ee:	228080e7          	jalr	552(ra) # 80003912 <idup>
    800026f2:	14a4bc23          	sd	a0,344(s1)

  safestrcpy(np->name, p->name, sizeof(p->name));
    800026f6:	4641                	li	a2,16
    800026f8:	16098593          	addi	a1,s3,352
    800026fc:	16048513          	addi	a0,s1,352
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	732080e7          	jalr	1842(ra) # 80000e32 <safestrcpy>

  np->pid = allocpid();
    80002708:	fffff097          	auipc	ra,0xfffff
    8000270c:	36c080e7          	jalr	876(ra) # 80001a74 <allocpid>
    80002710:	85aa                	mv	a1,a0
    80002712:	d888                	sw	a0,48(s1)
  printf("pid from clone: %d\n",np->pid);
    80002714:	00006517          	auipc	a0,0x6
    80002718:	b9c50513          	addi	a0,a0,-1124 # 800082b0 <digits+0x270>
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	e6c080e7          	jalr	-404(ra) # 80000588 <printf>
  //np->tid = 1;

  release(&np->lock);
    80002724:	8526                	mv	a0,s1
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	572080e7          	jalr	1394(ra) # 80000c98 <release>

  acquire(&wait_lock);
    8000272e:	0000f917          	auipc	s2,0xf
    80002732:	b8a90913          	addi	s2,s2,-1142 # 800112b8 <wait_lock>
    80002736:	854a                	mv	a0,s2
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	4ac080e7          	jalr	1196(ra) # 80000be4 <acquire>
  np->parent = p;
    80002740:	0534b023          	sd	s3,64(s1)
  release(&wait_lock);
    80002744:	854a                	mv	a0,s2
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	552080e7          	jalr	1362(ra) # 80000c98 <release>

  acquire(&np->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	494080e7          	jalr	1172(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80002758:	478d                	li	a5,3
    8000275a:	cc9c                	sw	a5,24(s1)
  release(&np->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	53a080e7          	jalr	1338(ra) # 80000c98 <release>
  
  
  return pid;
}
    80002766:	557d                	li	a0,-1
    80002768:	70a2                	ld	ra,40(sp)
    8000276a:	7402                	ld	s0,32(sp)
    8000276c:	64e2                	ld	s1,24(sp)
    8000276e:	6942                	ld	s2,16(sp)
    80002770:	69a2                	ld	s3,8(sp)
    80002772:	6a02                	ld	s4,0(sp)
    80002774:	6145                	addi	sp,sp,48
    80002776:	8082                	ret

0000000080002778 <swtch>:
    80002778:	00153023          	sd	ra,0(a0)
    8000277c:	00253423          	sd	sp,8(a0)
    80002780:	e900                	sd	s0,16(a0)
    80002782:	ed04                	sd	s1,24(a0)
    80002784:	03253023          	sd	s2,32(a0)
    80002788:	03353423          	sd	s3,40(a0)
    8000278c:	03453823          	sd	s4,48(a0)
    80002790:	03553c23          	sd	s5,56(a0)
    80002794:	05653023          	sd	s6,64(a0)
    80002798:	05753423          	sd	s7,72(a0)
    8000279c:	05853823          	sd	s8,80(a0)
    800027a0:	05953c23          	sd	s9,88(a0)
    800027a4:	07a53023          	sd	s10,96(a0)
    800027a8:	07b53423          	sd	s11,104(a0)
    800027ac:	0005b083          	ld	ra,0(a1)
    800027b0:	0085b103          	ld	sp,8(a1)
    800027b4:	6980                	ld	s0,16(a1)
    800027b6:	6d84                	ld	s1,24(a1)
    800027b8:	0205b903          	ld	s2,32(a1)
    800027bc:	0285b983          	ld	s3,40(a1)
    800027c0:	0305ba03          	ld	s4,48(a1)
    800027c4:	0385ba83          	ld	s5,56(a1)
    800027c8:	0405bb03          	ld	s6,64(a1)
    800027cc:	0485bb83          	ld	s7,72(a1)
    800027d0:	0505bc03          	ld	s8,80(a1)
    800027d4:	0585bc83          	ld	s9,88(a1)
    800027d8:	0605bd03          	ld	s10,96(a1)
    800027dc:	0685bd83          	ld	s11,104(a1)
    800027e0:	8082                	ret

00000000800027e2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027e2:	1141                	addi	sp,sp,-16
    800027e4:	e406                	sd	ra,8(sp)
    800027e6:	e022                	sd	s0,0(sp)
    800027e8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ea:	00006597          	auipc	a1,0x6
    800027ee:	b3658593          	addi	a1,a1,-1226 # 80008320 <states.1716+0x30>
    800027f2:	00015517          	auipc	a0,0x15
    800027f6:	ade50513          	addi	a0,a0,-1314 # 800172d0 <tickslock>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	35a080e7          	jalr	858(ra) # 80000b54 <initlock>
}
    80002802:	60a2                	ld	ra,8(sp)
    80002804:	6402                	ld	s0,0(sp)
    80002806:	0141                	addi	sp,sp,16
    80002808:	8082                	ret

000000008000280a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000280a:	1141                	addi	sp,sp,-16
    8000280c:	e422                	sd	s0,8(sp)
    8000280e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002810:	00003797          	auipc	a5,0x3
    80002814:	60078793          	addi	a5,a5,1536 # 80005e10 <kernelvec>
    80002818:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000281c:	6422                	ld	s0,8(sp)
    8000281e:	0141                	addi	sp,sp,16
    80002820:	8082                	ret

0000000080002822 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002822:	1141                	addi	sp,sp,-16
    80002824:	e406                	sd	ra,8(sp)
    80002826:	e022                	sd	s0,0(sp)
    80002828:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	186080e7          	jalr	390(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002832:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002836:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002838:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000283c:	00004617          	auipc	a2,0x4
    80002840:	7c460613          	addi	a2,a2,1988 # 80007000 <_trampoline>
    80002844:	00004697          	auipc	a3,0x4
    80002848:	7bc68693          	addi	a3,a3,1980 # 80007000 <_trampoline>
    8000284c:	8e91                	sub	a3,a3,a2
    8000284e:	040007b7          	lui	a5,0x4000
    80002852:	17fd                	addi	a5,a5,-1
    80002854:	07b2                	slli	a5,a5,0xc
    80002856:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002858:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000285c:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000285e:	180026f3          	csrr	a3,satp
    80002862:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002864:	7138                	ld	a4,96(a0)
    80002866:	6534                	ld	a3,72(a0)
    80002868:	6585                	lui	a1,0x1
    8000286a:	96ae                	add	a3,a3,a1
    8000286c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000286e:	7138                	ld	a4,96(a0)
    80002870:	00000697          	auipc	a3,0x0
    80002874:	26068693          	addi	a3,a3,608 # 80002ad0 <usertrap>
    80002878:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000287a:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000287c:	8692                	mv	a3,tp
    8000287e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002880:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002884:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002888:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002890:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002892:	6f18                	ld	a4,24(a4)
    80002894:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002898:	6d2c                	ld	a1,88(a0)
    8000289a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000289c:	00004717          	auipc	a4,0x4
    800028a0:	7f470713          	addi	a4,a4,2036 # 80007090 <userret>
    800028a4:	8f11                	sub	a4,a4,a2
    800028a6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028a8:	577d                	li	a4,-1
    800028aa:	177e                	slli	a4,a4,0x3f
    800028ac:	8dd9                	or	a1,a1,a4
    800028ae:	02000537          	lui	a0,0x2000
    800028b2:	157d                	addi	a0,a0,-1
    800028b4:	0536                	slli	a0,a0,0xd
    800028b6:	9782                	jalr	a5
}
    800028b8:	60a2                	ld	ra,8(sp)
    800028ba:	6402                	ld	s0,0(sp)
    800028bc:	0141                	addi	sp,sp,16
    800028be:	8082                	ret

00000000800028c0 <usertrapret_thread>:

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//Lab3
void
usertrapret_thread(void)
{
    800028c0:	7179                	addi	sp,sp,-48
    800028c2:	f406                	sd	ra,40(sp)
    800028c4:	f022                	sd	s0,32(sp)
    800028c6:	ec26                	sd	s1,24(sp)
    800028c8:	e84a                	sd	s2,16(sp)
    800028ca:	e44e                	sd	s3,8(sp)
    800028cc:	e052                	sd	s4,0(sp)
    800028ce:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	0e0080e7          	jalr	224(ra) # 800019b0 <myproc>
    800028d8:	84aa                	mv	s1,a0
  printf("\nusertrapret_thread: init\n");	
    800028da:	00006517          	auipc	a0,0x6
    800028de:	a4e50513          	addi	a0,a0,-1458 # 80008328 <states.1716+0x38>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	ca6080e7          	jalr	-858(ra) # 80000588 <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ee:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028f4:	00004a17          	auipc	s4,0x4
    800028f8:	70ca0a13          	addi	s4,s4,1804 # 80007000 <_trampoline>
    800028fc:	00004797          	auipc	a5,0x4
    80002900:	70478793          	addi	a5,a5,1796 # 80007000 <_trampoline>
    80002904:	414787b3          	sub	a5,a5,s4
    80002908:	04000937          	lui	s2,0x4000
    8000290c:	197d                	addi	s2,s2,-1
    8000290e:	0932                	slli	s2,s2,0xc
    80002910:	97ca                	add	a5,a5,s2
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002912:	10579073          	csrw	stvec,a5

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002916:	70bc                	ld	a5,96(s1)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002918:	18002773          	csrr	a4,satp
    8000291c:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000291e:	70b8                	ld	a4,96(s1)
    80002920:	64bc                	ld	a5,72(s1)
    80002922:	6685                	lui	a3,0x1
    80002924:	97b6                	add	a5,a5,a3
    80002926:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002928:	70bc                	ld	a5,96(s1)
    8000292a:	00000717          	auipc	a4,0x0
    8000292e:	1a670713          	addi	a4,a4,422 # 80002ad0 <usertrap>
    80002932:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002934:	70bc                	ld	a5,96(s1)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002936:	8712                	mv	a4,tp
    80002938:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293a:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000293e:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002942:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002946:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000294a:	70bc                	ld	a5,96(s1)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000294c:	6f9c                	ld	a5,24(a5)
    8000294e:	14179073          	csrw	sepc,a5

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002952:	0584b983          	ld	s3,88(s1)
    80002956:	00c9d993          	srli	s3,s3,0xc
    8000295a:	57fd                	li	a5,-1
    8000295c:	17fe                	slli	a5,a5,0x3f
    8000295e:	00f9e9b3          	or	s3,s3,a5

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  printf("\nusertrapret_thread: before change\n");
    80002962:	00006517          	auipc	a0,0x6
    80002966:	9e650513          	addi	a0,a0,-1562 # 80008348 <states.1716+0x58>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c1e080e7          	jalr	-994(ra) # 80000588 <printf>
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002972:	00004797          	auipc	a5,0x4
    80002976:	71e78793          	addi	a5,a5,1822 # 80007090 <userret>
    8000297a:	414787b3          	sub	a5,a5,s4
    8000297e:	993e                	add	s2,s2,a5
  if (p->tid != 0){
    80002980:	58dc                	lw	a5,52(s1)
    80002982:	c7a1                	beqz	a5,800029ca <usertrapret_thread+0x10a>
  	printf("\nusertrapret_thread: if 1\n");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	9ec50513          	addi	a0,a0,-1556 # 80008370 <states.1716+0x80>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bfc080e7          	jalr	-1028(ra) # 80000588 <printf>
  	((void (*)(uint64,uint64))fn)(TRAPFRAME - (PGSIZE * p->tid), satp);
    80002994:	58c8                	lw	a0,52(s1)
    80002996:	00c5151b          	slliw	a0,a0,0xc
    8000299a:	020007b7          	lui	a5,0x2000
    8000299e:	85ce                	mv	a1,s3
    800029a0:	17fd                	addi	a5,a5,-1
    800029a2:	07b6                	slli	a5,a5,0xd
    800029a4:	40a78533          	sub	a0,a5,a0
    800029a8:	9902                	jalr	s2
  }
  else {
  	printf("\nusertrapret_thread: else 1\n");
  	((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
  }
  printf("\nusertrapret_thread: end\n");
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	a0650513          	addi	a0,a0,-1530 # 800083b0 <states.1716+0xc0>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd6080e7          	jalr	-1066(ra) # 80000588 <printf>
}
    800029ba:	70a2                	ld	ra,40(sp)
    800029bc:	7402                	ld	s0,32(sp)
    800029be:	64e2                	ld	s1,24(sp)
    800029c0:	6942                	ld	s2,16(sp)
    800029c2:	69a2                	ld	s3,8(sp)
    800029c4:	6a02                	ld	s4,0(sp)
    800029c6:	6145                	addi	sp,sp,48
    800029c8:	8082                	ret
  	printf("\nusertrapret_thread: else 1\n");
    800029ca:	00006517          	auipc	a0,0x6
    800029ce:	9c650513          	addi	a0,a0,-1594 # 80008390 <states.1716+0xa0>
    800029d2:	ffffe097          	auipc	ra,0xffffe
    800029d6:	bb6080e7          	jalr	-1098(ra) # 80000588 <printf>
  	((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029da:	85ce                	mv	a1,s3
    800029dc:	02000537          	lui	a0,0x2000
    800029e0:	157d                	addi	a0,a0,-1
    800029e2:	0536                	slli	a0,a0,0xd
    800029e4:	9902                	jalr	s2
    800029e6:	b7d1                	j	800029aa <usertrapret_thread+0xea>

00000000800029e8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e8:	1101                	addi	sp,sp,-32
    800029ea:	ec06                	sd	ra,24(sp)
    800029ec:	e822                	sd	s0,16(sp)
    800029ee:	e426                	sd	s1,8(sp)
    800029f0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f2:	00015497          	auipc	s1,0x15
    800029f6:	8de48493          	addi	s1,s1,-1826 # 800172d0 <tickslock>
    800029fa:	8526                	mv	a0,s1
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	1e8080e7          	jalr	488(ra) # 80000be4 <acquire>
  ticks++;
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	62c50513          	addi	a0,a0,1580 # 80009030 <ticks>
    80002a0c:	411c                	lw	a5,0(a0)
    80002a0e:	2785                	addiw	a5,a5,1
    80002a10:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	834080e7          	jalr	-1996(ra) # 80002246 <wakeup>
  release(&tickslock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	27c080e7          	jalr	636(ra) # 80000c98 <release>
}
    80002a24:	60e2                	ld	ra,24(sp)
    80002a26:	6442                	ld	s0,16(sp)
    80002a28:	64a2                	ld	s1,8(sp)
    80002a2a:	6105                	addi	sp,sp,32
    80002a2c:	8082                	ret

0000000080002a2e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a2e:	1101                	addi	sp,sp,-32
    80002a30:	ec06                	sd	ra,24(sp)
    80002a32:	e822                	sd	s0,16(sp)
    80002a34:	e426                	sd	s1,8(sp)
    80002a36:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a38:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a3c:	00074d63          	bltz	a4,80002a56 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a40:	57fd                	li	a5,-1
    80002a42:	17fe                	slli	a5,a5,0x3f
    80002a44:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a46:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a48:	06f70363          	beq	a4,a5,80002aae <devintr+0x80>
  }
}
    80002a4c:	60e2                	ld	ra,24(sp)
    80002a4e:	6442                	ld	s0,16(sp)
    80002a50:	64a2                	ld	s1,8(sp)
    80002a52:	6105                	addi	sp,sp,32
    80002a54:	8082                	ret
     (scause & 0xff) == 9){
    80002a56:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a5a:	46a5                	li	a3,9
    80002a5c:	fed792e3          	bne	a5,a3,80002a40 <devintr+0x12>
    int irq = plic_claim();
    80002a60:	00003097          	auipc	ra,0x3
    80002a64:	4b8080e7          	jalr	1208(ra) # 80005f18 <plic_claim>
    80002a68:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a6a:	47a9                	li	a5,10
    80002a6c:	02f50763          	beq	a0,a5,80002a9a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a70:	4785                	li	a5,1
    80002a72:	02f50963          	beq	a0,a5,80002aa4 <devintr+0x76>
    return 1;
    80002a76:	4505                	li	a0,1
    } else if(irq){
    80002a78:	d8f1                	beqz	s1,80002a4c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a7a:	85a6                	mv	a1,s1
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	95450513          	addi	a0,a0,-1708 # 800083d0 <states.1716+0xe0>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	b04080e7          	jalr	-1276(ra) # 80000588 <printf>
      plic_complete(irq);
    80002a8c:	8526                	mv	a0,s1
    80002a8e:	00003097          	auipc	ra,0x3
    80002a92:	4ae080e7          	jalr	1198(ra) # 80005f3c <plic_complete>
    return 1;
    80002a96:	4505                	li	a0,1
    80002a98:	bf55                	j	80002a4c <devintr+0x1e>
      uartintr();
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	f0e080e7          	jalr	-242(ra) # 800009a8 <uartintr>
    80002aa2:	b7ed                	j	80002a8c <devintr+0x5e>
      virtio_disk_intr();
    80002aa4:	00004097          	auipc	ra,0x4
    80002aa8:	978080e7          	jalr	-1672(ra) # 8000641c <virtio_disk_intr>
    80002aac:	b7c5                	j	80002a8c <devintr+0x5e>
    if(cpuid() == 0){
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	ed6080e7          	jalr	-298(ra) # 80001984 <cpuid>
    80002ab6:	c901                	beqz	a0,80002ac6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002abc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002abe:	14479073          	csrw	sip,a5
    return 2;
    80002ac2:	4509                	li	a0,2
    80002ac4:	b761                	j	80002a4c <devintr+0x1e>
      clockintr();
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	f22080e7          	jalr	-222(ra) # 800029e8 <clockintr>
    80002ace:	b7ed                	j	80002ab8 <devintr+0x8a>

0000000080002ad0 <usertrap>:
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	e426                	sd	s1,8(sp)
    80002ad8:	e04a                	sd	s2,0(sp)
    80002ada:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002adc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae0:	1007f793          	andi	a5,a5,256
    80002ae4:	e3ad                	bnez	a5,80002b46 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae6:	00003797          	auipc	a5,0x3
    80002aea:	32a78793          	addi	a5,a5,810 # 80005e10 <kernelvec>
    80002aee:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	ebe080e7          	jalr	-322(ra) # 800019b0 <myproc>
    80002afa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002afc:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afe:	14102773          	csrr	a4,sepc
    80002b02:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b04:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b08:	47a1                	li	a5,8
    80002b0a:	04f71c63          	bne	a4,a5,80002b62 <usertrap+0x92>
    if(p->killed)
    80002b0e:	551c                	lw	a5,40(a0)
    80002b10:	e3b9                	bnez	a5,80002b56 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b12:	70b8                	ld	a4,96(s1)
    80002b14:	6f1c                	ld	a5,24(a4)
    80002b16:	0791                	addi	a5,a5,4
    80002b18:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b1e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b22:	10079073          	csrw	sstatus,a5
    syscall();
    80002b26:	00000097          	auipc	ra,0x0
    80002b2a:	2e0080e7          	jalr	736(ra) # 80002e06 <syscall>
  if(p->killed)
    80002b2e:	549c                	lw	a5,40(s1)
    80002b30:	ebc1                	bnez	a5,80002bc0 <usertrap+0xf0>
  usertrapret();
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	cf0080e7          	jalr	-784(ra) # 80002822 <usertrapret>
}
    80002b3a:	60e2                	ld	ra,24(sp)
    80002b3c:	6442                	ld	s0,16(sp)
    80002b3e:	64a2                	ld	s1,8(sp)
    80002b40:	6902                	ld	s2,0(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret
    panic("usertrap: not from user mode");
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	8aa50513          	addi	a0,a0,-1878 # 800083f0 <states.1716+0x100>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	9f0080e7          	jalr	-1552(ra) # 8000053e <panic>
      exit(-1);
    80002b56:	557d                	li	a0,-1
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	7be080e7          	jalr	1982(ra) # 80002316 <exit>
    80002b60:	bf4d                	j	80002b12 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b62:	00000097          	auipc	ra,0x0
    80002b66:	ecc080e7          	jalr	-308(ra) # 80002a2e <devintr>
    80002b6a:	892a                	mv	s2,a0
    80002b6c:	c501                	beqz	a0,80002b74 <usertrap+0xa4>
  if(p->killed)
    80002b6e:	549c                	lw	a5,40(s1)
    80002b70:	c3a1                	beqz	a5,80002bb0 <usertrap+0xe0>
    80002b72:	a815                	j	80002ba6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b74:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b78:	5890                	lw	a2,48(s1)
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	89650513          	addi	a0,a0,-1898 # 80008410 <states.1716+0x120>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a06080e7          	jalr	-1530(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b92:	00006517          	auipc	a0,0x6
    80002b96:	8ae50513          	addi	a0,a0,-1874 # 80008440 <states.1716+0x150>
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	9ee080e7          	jalr	-1554(ra) # 80000588 <printf>
    p->killed = 1;
    80002ba2:	4785                	li	a5,1
    80002ba4:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002ba6:	557d                	li	a0,-1
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	76e080e7          	jalr	1902(ra) # 80002316 <exit>
  if(which_dev == 2)
    80002bb0:	4789                	li	a5,2
    80002bb2:	f8f910e3          	bne	s2,a5,80002b32 <usertrap+0x62>
    yield();
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	4c8080e7          	jalr	1224(ra) # 8000207e <yield>
    80002bbe:	bf95                	j	80002b32 <usertrap+0x62>
  int which_dev = 0;
    80002bc0:	4901                	li	s2,0
    80002bc2:	b7d5                	j	80002ba6 <usertrap+0xd6>

0000000080002bc4 <kerneltrap>:
{
    80002bc4:	7179                	addi	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	e84a                	sd	s2,16(sp)
    80002bce:	e44e                	sd	s3,8(sp)
    80002bd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bde:	1004f793          	andi	a5,s1,256
    80002be2:	cb85                	beqz	a5,80002c12 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bea:	ef85                	bnez	a5,80002c22 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	e42080e7          	jalr	-446(ra) # 80002a2e <devintr>
    80002bf4:	cd1d                	beqz	a0,80002c32 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf6:	4789                	li	a5,2
    80002bf8:	06f50a63          	beq	a0,a5,80002c6c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bfc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c00:	10049073          	csrw	sstatus,s1
}
    80002c04:	70a2                	ld	ra,40(sp)
    80002c06:	7402                	ld	s0,32(sp)
    80002c08:	64e2                	ld	s1,24(sp)
    80002c0a:	6942                	ld	s2,16(sp)
    80002c0c:	69a2                	ld	s3,8(sp)
    80002c0e:	6145                	addi	sp,sp,48
    80002c10:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c12:	00006517          	auipc	a0,0x6
    80002c16:	84e50513          	addi	a0,a0,-1970 # 80008460 <states.1716+0x170>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	924080e7          	jalr	-1756(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002c22:	00006517          	auipc	a0,0x6
    80002c26:	86650513          	addi	a0,a0,-1946 # 80008488 <states.1716+0x198>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	914080e7          	jalr	-1772(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002c32:	85ce                	mv	a1,s3
    80002c34:	00006517          	auipc	a0,0x6
    80002c38:	87450513          	addi	a0,a0,-1932 # 800084a8 <states.1716+0x1b8>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	94c080e7          	jalr	-1716(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c44:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c48:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4c:	00006517          	auipc	a0,0x6
    80002c50:	86c50513          	addi	a0,a0,-1940 # 800084b8 <states.1716+0x1c8>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	934080e7          	jalr	-1740(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002c5c:	00006517          	auipc	a0,0x6
    80002c60:	87450513          	addi	a0,a0,-1932 # 800084d0 <states.1716+0x1e0>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8da080e7          	jalr	-1830(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	d44080e7          	jalr	-700(ra) # 800019b0 <myproc>
    80002c74:	d541                	beqz	a0,80002bfc <kerneltrap+0x38>
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	d3a080e7          	jalr	-710(ra) # 800019b0 <myproc>
    80002c7e:	4d18                	lw	a4,24(a0)
    80002c80:	4791                	li	a5,4
    80002c82:	f6f71de3          	bne	a4,a5,80002bfc <kerneltrap+0x38>
    yield();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	3f8080e7          	jalr	1016(ra) # 8000207e <yield>
    80002c8e:	b7bd                	j	80002bfc <kerneltrap+0x38>

0000000080002c90 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	e426                	sd	s1,8(sp)
    80002c98:	1000                	addi	s0,sp,32
    80002c9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d14080e7          	jalr	-748(ra) # 800019b0 <myproc>
  switch (n) {
    80002ca4:	4795                	li	a5,5
    80002ca6:	0497e163          	bltu	a5,s1,80002ce8 <argraw+0x58>
    80002caa:	048a                	slli	s1,s1,0x2
    80002cac:	00006717          	auipc	a4,0x6
    80002cb0:	85c70713          	addi	a4,a4,-1956 # 80008508 <states.1716+0x218>
    80002cb4:	94ba                	add	s1,s1,a4
    80002cb6:	409c                	lw	a5,0(s1)
    80002cb8:	97ba                	add	a5,a5,a4
    80002cba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cbc:	713c                	ld	a5,96(a0)
    80002cbe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret
    return p->trapframe->a1;
    80002cca:	713c                	ld	a5,96(a0)
    80002ccc:	7fa8                	ld	a0,120(a5)
    80002cce:	bfcd                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a2;
    80002cd0:	713c                	ld	a5,96(a0)
    80002cd2:	63c8                	ld	a0,128(a5)
    80002cd4:	b7f5                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a3;
    80002cd6:	713c                	ld	a5,96(a0)
    80002cd8:	67c8                	ld	a0,136(a5)
    80002cda:	b7dd                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a4;
    80002cdc:	713c                	ld	a5,96(a0)
    80002cde:	6bc8                	ld	a0,144(a5)
    80002ce0:	b7c5                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a5;
    80002ce2:	713c                	ld	a5,96(a0)
    80002ce4:	6fc8                	ld	a0,152(a5)
    80002ce6:	bfe9                	j	80002cc0 <argraw+0x30>
  panic("argraw");
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	7f850513          	addi	a0,a0,2040 # 800084e0 <states.1716+0x1f0>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	84e080e7          	jalr	-1970(ra) # 8000053e <panic>

0000000080002cf8 <fetchaddr>:
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	e426                	sd	s1,8(sp)
    80002d00:	e04a                	sd	s2,0(sp)
    80002d02:	1000                	addi	s0,sp,32
    80002d04:	84aa                	mv	s1,a0
    80002d06:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	ca8080e7          	jalr	-856(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d10:	693c                	ld	a5,80(a0)
    80002d12:	02f4f863          	bgeu	s1,a5,80002d42 <fetchaddr+0x4a>
    80002d16:	00848713          	addi	a4,s1,8
    80002d1a:	02e7e663          	bltu	a5,a4,80002d46 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d1e:	46a1                	li	a3,8
    80002d20:	8626                	mv	a2,s1
    80002d22:	85ca                	mv	a1,s2
    80002d24:	6d28                	ld	a0,88(a0)
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	9d8080e7          	jalr	-1576(ra) # 800016fe <copyin>
    80002d2e:	00a03533          	snez	a0,a0
    80002d32:	40a00533          	neg	a0,a0
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6902                	ld	s2,0(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret
    return -1;
    80002d42:	557d                	li	a0,-1
    80002d44:	bfcd                	j	80002d36 <fetchaddr+0x3e>
    80002d46:	557d                	li	a0,-1
    80002d48:	b7fd                	j	80002d36 <fetchaddr+0x3e>

0000000080002d4a <fetchstr>:
{
    80002d4a:	7179                	addi	sp,sp,-48
    80002d4c:	f406                	sd	ra,40(sp)
    80002d4e:	f022                	sd	s0,32(sp)
    80002d50:	ec26                	sd	s1,24(sp)
    80002d52:	e84a                	sd	s2,16(sp)
    80002d54:	e44e                	sd	s3,8(sp)
    80002d56:	1800                	addi	s0,sp,48
    80002d58:	892a                	mv	s2,a0
    80002d5a:	84ae                	mv	s1,a1
    80002d5c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	c52080e7          	jalr	-942(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d66:	86ce                	mv	a3,s3
    80002d68:	864a                	mv	a2,s2
    80002d6a:	85a6                	mv	a1,s1
    80002d6c:	6d28                	ld	a0,88(a0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	a1c080e7          	jalr	-1508(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002d76:	00054763          	bltz	a0,80002d84 <fetchstr+0x3a>
  return strlen(buf);
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	0e8080e7          	jalr	232(ra) # 80000e64 <strlen>
}
    80002d84:	70a2                	ld	ra,40(sp)
    80002d86:	7402                	ld	s0,32(sp)
    80002d88:	64e2                	ld	s1,24(sp)
    80002d8a:	6942                	ld	s2,16(sp)
    80002d8c:	69a2                	ld	s3,8(sp)
    80002d8e:	6145                	addi	sp,sp,48
    80002d90:	8082                	ret

0000000080002d92 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	e426                	sd	s1,8(sp)
    80002d9a:	1000                	addi	s0,sp,32
    80002d9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	ef2080e7          	jalr	-270(ra) # 80002c90 <argraw>
    80002da6:	c088                	sw	a0,0(s1)
  return 0;
}
    80002da8:	4501                	li	a0,0
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	64a2                	ld	s1,8(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret

0000000080002db4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002db4:	1101                	addi	sp,sp,-32
    80002db6:	ec06                	sd	ra,24(sp)
    80002db8:	e822                	sd	s0,16(sp)
    80002dba:	e426                	sd	s1,8(sp)
    80002dbc:	1000                	addi	s0,sp,32
    80002dbe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc0:	00000097          	auipc	ra,0x0
    80002dc4:	ed0080e7          	jalr	-304(ra) # 80002c90 <argraw>
    80002dc8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dca:	4501                	li	a0,0
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	64a2                	ld	s1,8(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	e04a                	sd	s2,0(sp)
    80002de0:	1000                	addi	s0,sp,32
    80002de2:	84ae                	mv	s1,a1
    80002de4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	eaa080e7          	jalr	-342(ra) # 80002c90 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dee:	864a                	mv	a2,s2
    80002df0:	85a6                	mv	a1,s1
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	f58080e7          	jalr	-168(ra) # 80002d4a <fetchstr>
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6902                	ld	s2,0(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret

0000000080002e06 <syscall>:
[SYS_clone]   sys_clone,
};

void
syscall(void)
{
    80002e06:	1101                	addi	sp,sp,-32
    80002e08:	ec06                	sd	ra,24(sp)
    80002e0a:	e822                	sd	s0,16(sp)
    80002e0c:	e426                	sd	s1,8(sp)
    80002e0e:	e04a                	sd	s2,0(sp)
    80002e10:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	b9e080e7          	jalr	-1122(ra) # 800019b0 <myproc>
    80002e1a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e1c:	06053903          	ld	s2,96(a0)
    80002e20:	0a893783          	ld	a5,168(s2) # 40000a8 <_entry-0x7bffff58>
    80002e24:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e28:	37fd                	addiw	a5,a5,-1
    80002e2a:	4755                	li	a4,21
    80002e2c:	00f76f63          	bltu	a4,a5,80002e4a <syscall+0x44>
    80002e30:	00369713          	slli	a4,a3,0x3
    80002e34:	00005797          	auipc	a5,0x5
    80002e38:	6ec78793          	addi	a5,a5,1772 # 80008520 <syscalls>
    80002e3c:	97ba                	add	a5,a5,a4
    80002e3e:	639c                	ld	a5,0(a5)
    80002e40:	c789                	beqz	a5,80002e4a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e42:	9782                	jalr	a5
    80002e44:	06a93823          	sd	a0,112(s2)
    80002e48:	a839                	j	80002e66 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e4a:	16048613          	addi	a2,s1,352
    80002e4e:	588c                	lw	a1,48(s1)
    80002e50:	00005517          	auipc	a0,0x5
    80002e54:	69850513          	addi	a0,a0,1688 # 800084e8 <states.1716+0x1f8>
    80002e58:	ffffd097          	auipc	ra,0xffffd
    80002e5c:	730080e7          	jalr	1840(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e60:	70bc                	ld	a5,96(s1)
    80002e62:	577d                	li	a4,-1
    80002e64:	fbb8                	sd	a4,112(a5)
  }
}
    80002e66:	60e2                	ld	ra,24(sp)
    80002e68:	6442                	ld	s0,16(sp)
    80002e6a:	64a2                	ld	s1,8(sp)
    80002e6c:	6902                	ld	s2,0(sp)
    80002e6e:	6105                	addi	sp,sp,32
    80002e70:	8082                	ret

0000000080002e72 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e7a:	fec40593          	addi	a1,s0,-20
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	f12080e7          	jalr	-238(ra) # 80002d92 <argint>
    return -1;
    80002e88:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e8a:	00054963          	bltz	a0,80002e9c <sys_exit+0x2a>
  exit(n);
    80002e8e:	fec42503          	lw	a0,-20(s0)
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	484080e7          	jalr	1156(ra) # 80002316 <exit>
  return 0;  // not reached
    80002e9a:	4781                	li	a5,0
}
    80002e9c:	853e                	mv	a0,a5
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea6:	1141                	addi	sp,sp,-16
    80002ea8:	e406                	sd	ra,8(sp)
    80002eaa:	e022                	sd	s0,0(sp)
    80002eac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	b02080e7          	jalr	-1278(ra) # 800019b0 <myproc>
}
    80002eb6:	5908                	lw	a0,48(a0)
    80002eb8:	60a2                	ld	ra,8(sp)
    80002eba:	6402                	ld	s0,0(sp)
    80002ebc:	0141                	addi	sp,sp,16
    80002ebe:	8082                	ret

0000000080002ec0 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec0:	1141                	addi	sp,sp,-16
    80002ec2:	e406                	sd	ra,8(sp)
    80002ec4:	e022                	sd	s0,0(sp)
    80002ec6:	0800                	addi	s0,sp,16
  return fork();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	f04080e7          	jalr	-252(ra) # 80001dcc <fork>
}
    80002ed0:	60a2                	ld	ra,8(sp)
    80002ed2:	6402                	ld	s0,0(sp)
    80002ed4:	0141                	addi	sp,sp,16
    80002ed6:	8082                	ret

0000000080002ed8 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ee0:	fe840593          	addi	a1,s0,-24
    80002ee4:	4501                	li	a0,0
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	ece080e7          	jalr	-306(ra) # 80002db4 <argaddr>
    80002eee:	87aa                	mv	a5,a0
    return -1;
    80002ef0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ef2:	0007c863          	bltz	a5,80002f02 <sys_wait+0x2a>
  return wait(p);
    80002ef6:	fe843503          	ld	a0,-24(s0)
    80002efa:	fffff097          	auipc	ra,0xfffff
    80002efe:	224080e7          	jalr	548(ra) # 8000211e <wait>
}
    80002f02:	60e2                	ld	ra,24(sp)
    80002f04:	6442                	ld	s0,16(sp)
    80002f06:	6105                	addi	sp,sp,32
    80002f08:	8082                	ret

0000000080002f0a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f0a:	7179                	addi	sp,sp,-48
    80002f0c:	f406                	sd	ra,40(sp)
    80002f0e:	f022                	sd	s0,32(sp)
    80002f10:	ec26                	sd	s1,24(sp)
    80002f12:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f14:	fdc40593          	addi	a1,s0,-36
    80002f18:	4501                	li	a0,0
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	e78080e7          	jalr	-392(ra) # 80002d92 <argint>
    80002f22:	87aa                	mv	a5,a0
    return -1;
    80002f24:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f26:	0207c063          	bltz	a5,80002f46 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	a86080e7          	jalr	-1402(ra) # 800019b0 <myproc>
    80002f32:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f34:	fdc42503          	lw	a0,-36(s0)
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	e20080e7          	jalr	-480(ra) # 80001d58 <growproc>
    80002f40:	00054863          	bltz	a0,80002f50 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f44:	8526                	mv	a0,s1
}
    80002f46:	70a2                	ld	ra,40(sp)
    80002f48:	7402                	ld	s0,32(sp)
    80002f4a:	64e2                	ld	s1,24(sp)
    80002f4c:	6145                	addi	sp,sp,48
    80002f4e:	8082                	ret
    return -1;
    80002f50:	557d                	li	a0,-1
    80002f52:	bfd5                	j	80002f46 <sys_sbrk+0x3c>

0000000080002f54 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f54:	7139                	addi	sp,sp,-64
    80002f56:	fc06                	sd	ra,56(sp)
    80002f58:	f822                	sd	s0,48(sp)
    80002f5a:	f426                	sd	s1,40(sp)
    80002f5c:	f04a                	sd	s2,32(sp)
    80002f5e:	ec4e                	sd	s3,24(sp)
    80002f60:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f62:	fcc40593          	addi	a1,s0,-52
    80002f66:	4501                	li	a0,0
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	e2a080e7          	jalr	-470(ra) # 80002d92 <argint>
    return -1;
    80002f70:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f72:	06054563          	bltz	a0,80002fdc <sys_sleep+0x88>
  acquire(&tickslock);
    80002f76:	00014517          	auipc	a0,0x14
    80002f7a:	35a50513          	addi	a0,a0,858 # 800172d0 <tickslock>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	c66080e7          	jalr	-922(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002f86:	00006917          	auipc	s2,0x6
    80002f8a:	0aa92903          	lw	s2,170(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002f8e:	fcc42783          	lw	a5,-52(s0)
    80002f92:	cf85                	beqz	a5,80002fca <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f94:	00014997          	auipc	s3,0x14
    80002f98:	33c98993          	addi	s3,s3,828 # 800172d0 <tickslock>
    80002f9c:	00006497          	auipc	s1,0x6
    80002fa0:	09448493          	addi	s1,s1,148 # 80009030 <ticks>
    if(myproc()->killed){
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	a0c080e7          	jalr	-1524(ra) # 800019b0 <myproc>
    80002fac:	551c                	lw	a5,40(a0)
    80002fae:	ef9d                	bnez	a5,80002fec <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fb0:	85ce                	mv	a1,s3
    80002fb2:	8526                	mv	a0,s1
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	106080e7          	jalr	262(ra) # 800020ba <sleep>
  while(ticks - ticks0 < n){
    80002fbc:	409c                	lw	a5,0(s1)
    80002fbe:	412787bb          	subw	a5,a5,s2
    80002fc2:	fcc42703          	lw	a4,-52(s0)
    80002fc6:	fce7efe3          	bltu	a5,a4,80002fa4 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fca:	00014517          	auipc	a0,0x14
    80002fce:	30650513          	addi	a0,a0,774 # 800172d0 <tickslock>
    80002fd2:	ffffe097          	auipc	ra,0xffffe
    80002fd6:	cc6080e7          	jalr	-826(ra) # 80000c98 <release>
  return 0;
    80002fda:	4781                	li	a5,0
}
    80002fdc:	853e                	mv	a0,a5
    80002fde:	70e2                	ld	ra,56(sp)
    80002fe0:	7442                	ld	s0,48(sp)
    80002fe2:	74a2                	ld	s1,40(sp)
    80002fe4:	7902                	ld	s2,32(sp)
    80002fe6:	69e2                	ld	s3,24(sp)
    80002fe8:	6121                	addi	sp,sp,64
    80002fea:	8082                	ret
      release(&tickslock);
    80002fec:	00014517          	auipc	a0,0x14
    80002ff0:	2e450513          	addi	a0,a0,740 # 800172d0 <tickslock>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	ca4080e7          	jalr	-860(ra) # 80000c98 <release>
      return -1;
    80002ffc:	57fd                	li	a5,-1
    80002ffe:	bff9                	j	80002fdc <sys_sleep+0x88>

0000000080003000 <sys_kill>:

uint64
sys_kill(void)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003008:	fec40593          	addi	a1,s0,-20
    8000300c:	4501                	li	a0,0
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	d84080e7          	jalr	-636(ra) # 80002d92 <argint>
    80003016:	87aa                	mv	a5,a0
    return -1;
    80003018:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000301a:	0007c863          	bltz	a5,8000302a <sys_kill+0x2a>
  return kill(pid);
    8000301e:	fec42503          	lw	a0,-20(s0)
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	3ca080e7          	jalr	970(ra) # 800023ec <kill>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	6105                	addi	sp,sp,32
    80003030:	8082                	ret

0000000080003032 <sys_clone>:

uint64
sys_clone(void)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	1000                	addi	s0,sp,32
	uint64 st;
	int sz;
	if (argaddr(0,&st) <0)
    8000303a:	fe840593          	addi	a1,s0,-24
    8000303e:	4501                	li	a0,0
    80003040:	00000097          	auipc	ra,0x0
    80003044:	d74080e7          	jalr	-652(ra) # 80002db4 <argaddr>
		return -1;
    80003048:	57fd                	li	a5,-1
	if (argaddr(0,&st) <0)
    8000304a:	02054563          	bltz	a0,80003074 <sys_clone+0x42>
	if(argint(1,&sz)<0)
    8000304e:	fe440593          	addi	a1,s0,-28
    80003052:	4505                	li	a0,1
    80003054:	00000097          	auipc	ra,0x0
    80003058:	d3e080e7          	jalr	-706(ra) # 80002d92 <argint>
		return -1;
    8000305c:	57fd                	li	a5,-1
	if(argint(1,&sz)<0)
    8000305e:	00054b63          	bltz	a0,80003074 <sys_clone+0x42>

	return clone((void *)st, sz);
    80003062:	fe442583          	lw	a1,-28(s0)
    80003066:	fe843503          	ld	a0,-24(s0)
    8000306a:	fffff097          	auipc	ra,0xfffff
    8000306e:	54e080e7          	jalr	1358(ra) # 800025b8 <clone>
    80003072:	87aa                	mv	a5,a0
}
    80003074:	853e                	mv	a0,a5
    80003076:	60e2                	ld	ra,24(sp)
    80003078:	6442                	ld	s0,16(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret

000000008000307e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000307e:	1101                	addi	sp,sp,-32
    80003080:	ec06                	sd	ra,24(sp)
    80003082:	e822                	sd	s0,16(sp)
    80003084:	e426                	sd	s1,8(sp)
    80003086:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003088:	00014517          	auipc	a0,0x14
    8000308c:	24850513          	addi	a0,a0,584 # 800172d0 <tickslock>
    80003090:	ffffe097          	auipc	ra,0xffffe
    80003094:	b54080e7          	jalr	-1196(ra) # 80000be4 <acquire>
  xticks = ticks;
    80003098:	00006497          	auipc	s1,0x6
    8000309c:	f984a483          	lw	s1,-104(s1) # 80009030 <ticks>
  release(&tickslock);
    800030a0:	00014517          	auipc	a0,0x14
    800030a4:	23050513          	addi	a0,a0,560 # 800172d0 <tickslock>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	bf0080e7          	jalr	-1040(ra) # 80000c98 <release>
  return xticks;
}
    800030b0:	02049513          	slli	a0,s1,0x20
    800030b4:	9101                	srli	a0,a0,0x20
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6105                	addi	sp,sp,32
    800030be:	8082                	ret

00000000800030c0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030c0:	7179                	addi	sp,sp,-48
    800030c2:	f406                	sd	ra,40(sp)
    800030c4:	f022                	sd	s0,32(sp)
    800030c6:	ec26                	sd	s1,24(sp)
    800030c8:	e84a                	sd	s2,16(sp)
    800030ca:	e44e                	sd	s3,8(sp)
    800030cc:	e052                	sd	s4,0(sp)
    800030ce:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030d0:	00005597          	auipc	a1,0x5
    800030d4:	50858593          	addi	a1,a1,1288 # 800085d8 <syscalls+0xb8>
    800030d8:	00014517          	auipc	a0,0x14
    800030dc:	21050513          	addi	a0,a0,528 # 800172e8 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	a74080e7          	jalr	-1420(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	20078793          	addi	a5,a5,512 # 8001f2e8 <bcache+0x8000>
    800030f0:	0001c717          	auipc	a4,0x1c
    800030f4:	46070713          	addi	a4,a4,1120 # 8001f550 <bcache+0x8268>
    800030f8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030fc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003100:	00014497          	auipc	s1,0x14
    80003104:	20048493          	addi	s1,s1,512 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80003108:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000310a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000310c:	00005a17          	auipc	s4,0x5
    80003110:	4d4a0a13          	addi	s4,s4,1236 # 800085e0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80003114:	2b893783          	ld	a5,696(s2)
    80003118:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000311a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000311e:	85d2                	mv	a1,s4
    80003120:	01048513          	addi	a0,s1,16
    80003124:	00001097          	auipc	ra,0x1
    80003128:	4bc080e7          	jalr	1212(ra) # 800045e0 <initsleeplock>
    bcache.head.next->prev = b;
    8000312c:	2b893783          	ld	a5,696(s2)
    80003130:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003132:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003136:	45848493          	addi	s1,s1,1112
    8000313a:	fd349de3          	bne	s1,s3,80003114 <binit+0x54>
  }
}
    8000313e:	70a2                	ld	ra,40(sp)
    80003140:	7402                	ld	s0,32(sp)
    80003142:	64e2                	ld	s1,24(sp)
    80003144:	6942                	ld	s2,16(sp)
    80003146:	69a2                	ld	s3,8(sp)
    80003148:	6a02                	ld	s4,0(sp)
    8000314a:	6145                	addi	sp,sp,48
    8000314c:	8082                	ret

000000008000314e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000314e:	7179                	addi	sp,sp,-48
    80003150:	f406                	sd	ra,40(sp)
    80003152:	f022                	sd	s0,32(sp)
    80003154:	ec26                	sd	s1,24(sp)
    80003156:	e84a                	sd	s2,16(sp)
    80003158:	e44e                	sd	s3,8(sp)
    8000315a:	1800                	addi	s0,sp,48
    8000315c:	89aa                	mv	s3,a0
    8000315e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003160:	00014517          	auipc	a0,0x14
    80003164:	18850513          	addi	a0,a0,392 # 800172e8 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	a7c080e7          	jalr	-1412(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003170:	0001c497          	auipc	s1,0x1c
    80003174:	4304b483          	ld	s1,1072(s1) # 8001f5a0 <bcache+0x82b8>
    80003178:	0001c797          	auipc	a5,0x1c
    8000317c:	3d878793          	addi	a5,a5,984 # 8001f550 <bcache+0x8268>
    80003180:	02f48f63          	beq	s1,a5,800031be <bread+0x70>
    80003184:	873e                	mv	a4,a5
    80003186:	a021                	j	8000318e <bread+0x40>
    80003188:	68a4                	ld	s1,80(s1)
    8000318a:	02e48a63          	beq	s1,a4,800031be <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000318e:	449c                	lw	a5,8(s1)
    80003190:	ff379ce3          	bne	a5,s3,80003188 <bread+0x3a>
    80003194:	44dc                	lw	a5,12(s1)
    80003196:	ff2799e3          	bne	a5,s2,80003188 <bread+0x3a>
      b->refcnt++;
    8000319a:	40bc                	lw	a5,64(s1)
    8000319c:	2785                	addiw	a5,a5,1
    8000319e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031a0:	00014517          	auipc	a0,0x14
    800031a4:	14850513          	addi	a0,a0,328 # 800172e8 <bcache>
    800031a8:	ffffe097          	auipc	ra,0xffffe
    800031ac:	af0080e7          	jalr	-1296(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800031b0:	01048513          	addi	a0,s1,16
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	466080e7          	jalr	1126(ra) # 8000461a <acquiresleep>
      return b;
    800031bc:	a8b9                	j	8000321a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031be:	0001c497          	auipc	s1,0x1c
    800031c2:	3da4b483          	ld	s1,986(s1) # 8001f598 <bcache+0x82b0>
    800031c6:	0001c797          	auipc	a5,0x1c
    800031ca:	38a78793          	addi	a5,a5,906 # 8001f550 <bcache+0x8268>
    800031ce:	00f48863          	beq	s1,a5,800031de <bread+0x90>
    800031d2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031d4:	40bc                	lw	a5,64(s1)
    800031d6:	cf81                	beqz	a5,800031ee <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d8:	64a4                	ld	s1,72(s1)
    800031da:	fee49de3          	bne	s1,a4,800031d4 <bread+0x86>
  panic("bget: no buffers");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	40a50513          	addi	a0,a0,1034 # 800085e8 <syscalls+0xc8>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	358080e7          	jalr	856(ra) # 8000053e <panic>
      b->dev = dev;
    800031ee:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031f2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031f6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031fa:	4785                	li	a5,1
    800031fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	0ea50513          	addi	a0,a0,234 # 800172e8 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    8000320e:	01048513          	addi	a0,s1,16
    80003212:	00001097          	auipc	ra,0x1
    80003216:	408080e7          	jalr	1032(ra) # 8000461a <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000321a:	409c                	lw	a5,0(s1)
    8000321c:	cb89                	beqz	a5,8000322e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000321e:	8526                	mv	a0,s1
    80003220:	70a2                	ld	ra,40(sp)
    80003222:	7402                	ld	s0,32(sp)
    80003224:	64e2                	ld	s1,24(sp)
    80003226:	6942                	ld	s2,16(sp)
    80003228:	69a2                	ld	s3,8(sp)
    8000322a:	6145                	addi	sp,sp,48
    8000322c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000322e:	4581                	li	a1,0
    80003230:	8526                	mv	a0,s1
    80003232:	00003097          	auipc	ra,0x3
    80003236:	f14080e7          	jalr	-236(ra) # 80006146 <virtio_disk_rw>
    b->valid = 1;
    8000323a:	4785                	li	a5,1
    8000323c:	c09c                	sw	a5,0(s1)
  return b;
    8000323e:	b7c5                	j	8000321e <bread+0xd0>

0000000080003240 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003240:	1101                	addi	sp,sp,-32
    80003242:	ec06                	sd	ra,24(sp)
    80003244:	e822                	sd	s0,16(sp)
    80003246:	e426                	sd	s1,8(sp)
    80003248:	1000                	addi	s0,sp,32
    8000324a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000324c:	0541                	addi	a0,a0,16
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	466080e7          	jalr	1126(ra) # 800046b4 <holdingsleep>
    80003256:	cd01                	beqz	a0,8000326e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003258:	4585                	li	a1,1
    8000325a:	8526                	mv	a0,s1
    8000325c:	00003097          	auipc	ra,0x3
    80003260:	eea080e7          	jalr	-278(ra) # 80006146 <virtio_disk_rw>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret
    panic("bwrite");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	39250513          	addi	a0,a0,914 # 80008600 <syscalls+0xe0>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2c8080e7          	jalr	712(ra) # 8000053e <panic>

000000008000327e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000327e:	1101                	addi	sp,sp,-32
    80003280:	ec06                	sd	ra,24(sp)
    80003282:	e822                	sd	s0,16(sp)
    80003284:	e426                	sd	s1,8(sp)
    80003286:	e04a                	sd	s2,0(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000328c:	01050913          	addi	s2,a0,16
    80003290:	854a                	mv	a0,s2
    80003292:	00001097          	auipc	ra,0x1
    80003296:	422080e7          	jalr	1058(ra) # 800046b4 <holdingsleep>
    8000329a:	c92d                	beqz	a0,8000330c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000329c:	854a                	mv	a0,s2
    8000329e:	00001097          	auipc	ra,0x1
    800032a2:	3d2080e7          	jalr	978(ra) # 80004670 <releasesleep>

  acquire(&bcache.lock);
    800032a6:	00014517          	auipc	a0,0x14
    800032aa:	04250513          	addi	a0,a0,66 # 800172e8 <bcache>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	936080e7          	jalr	-1738(ra) # 80000be4 <acquire>
  b->refcnt--;
    800032b6:	40bc                	lw	a5,64(s1)
    800032b8:	37fd                	addiw	a5,a5,-1
    800032ba:	0007871b          	sext.w	a4,a5
    800032be:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032c0:	eb05                	bnez	a4,800032f0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032c2:	68bc                	ld	a5,80(s1)
    800032c4:	64b8                	ld	a4,72(s1)
    800032c6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032c8:	64bc                	ld	a5,72(s1)
    800032ca:	68b8                	ld	a4,80(s1)
    800032cc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ce:	0001c797          	auipc	a5,0x1c
    800032d2:	01a78793          	addi	a5,a5,26 # 8001f2e8 <bcache+0x8000>
    800032d6:	2b87b703          	ld	a4,696(a5)
    800032da:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032dc:	0001c717          	auipc	a4,0x1c
    800032e0:	27470713          	addi	a4,a4,628 # 8001f550 <bcache+0x8268>
    800032e4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032e6:	2b87b703          	ld	a4,696(a5)
    800032ea:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032ec:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	ff850513          	addi	a0,a0,-8 # 800172e8 <bcache>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	9a0080e7          	jalr	-1632(ra) # 80000c98 <release>
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret
    panic("brelse");
    8000330c:	00005517          	auipc	a0,0x5
    80003310:	2fc50513          	addi	a0,a0,764 # 80008608 <syscalls+0xe8>
    80003314:	ffffd097          	auipc	ra,0xffffd
    80003318:	22a080e7          	jalr	554(ra) # 8000053e <panic>

000000008000331c <bpin>:

void
bpin(struct buf *b) {
    8000331c:	1101                	addi	sp,sp,-32
    8000331e:	ec06                	sd	ra,24(sp)
    80003320:	e822                	sd	s0,16(sp)
    80003322:	e426                	sd	s1,8(sp)
    80003324:	1000                	addi	s0,sp,32
    80003326:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003328:	00014517          	auipc	a0,0x14
    8000332c:	fc050513          	addi	a0,a0,-64 # 800172e8 <bcache>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8b4080e7          	jalr	-1868(ra) # 80000be4 <acquire>
  b->refcnt++;
    80003338:	40bc                	lw	a5,64(s1)
    8000333a:	2785                	addiw	a5,a5,1
    8000333c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000333e:	00014517          	auipc	a0,0x14
    80003342:	faa50513          	addi	a0,a0,-86 # 800172e8 <bcache>
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	952080e7          	jalr	-1710(ra) # 80000c98 <release>
}
    8000334e:	60e2                	ld	ra,24(sp)
    80003350:	6442                	ld	s0,16(sp)
    80003352:	64a2                	ld	s1,8(sp)
    80003354:	6105                	addi	sp,sp,32
    80003356:	8082                	ret

0000000080003358 <bunpin>:

void
bunpin(struct buf *b) {
    80003358:	1101                	addi	sp,sp,-32
    8000335a:	ec06                	sd	ra,24(sp)
    8000335c:	e822                	sd	s0,16(sp)
    8000335e:	e426                	sd	s1,8(sp)
    80003360:	1000                	addi	s0,sp,32
    80003362:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003364:	00014517          	auipc	a0,0x14
    80003368:	f8450513          	addi	a0,a0,-124 # 800172e8 <bcache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	878080e7          	jalr	-1928(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003374:	40bc                	lw	a5,64(s1)
    80003376:	37fd                	addiw	a5,a5,-1
    80003378:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337a:	00014517          	auipc	a0,0x14
    8000337e:	f6e50513          	addi	a0,a0,-146 # 800172e8 <bcache>
    80003382:	ffffe097          	auipc	ra,0xffffe
    80003386:	916080e7          	jalr	-1770(ra) # 80000c98 <release>
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	64a2                	ld	s1,8(sp)
    80003390:	6105                	addi	sp,sp,32
    80003392:	8082                	ret

0000000080003394 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	e04a                	sd	s2,0(sp)
    8000339e:	1000                	addi	s0,sp,32
    800033a0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033a2:	00d5d59b          	srliw	a1,a1,0xd
    800033a6:	0001c797          	auipc	a5,0x1c
    800033aa:	61e7a783          	lw	a5,1566(a5) # 8001f9c4 <sb+0x1c>
    800033ae:	9dbd                	addw	a1,a1,a5
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	d9e080e7          	jalr	-610(ra) # 8000314e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033b8:	0074f713          	andi	a4,s1,7
    800033bc:	4785                	li	a5,1
    800033be:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033c2:	14ce                	slli	s1,s1,0x33
    800033c4:	90d9                	srli	s1,s1,0x36
    800033c6:	00950733          	add	a4,a0,s1
    800033ca:	05874703          	lbu	a4,88(a4)
    800033ce:	00e7f6b3          	and	a3,a5,a4
    800033d2:	c69d                	beqz	a3,80003400 <bfree+0x6c>
    800033d4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033d6:	94aa                	add	s1,s1,a0
    800033d8:	fff7c793          	not	a5,a5
    800033dc:	8ff9                	and	a5,a5,a4
    800033de:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033e2:	00001097          	auipc	ra,0x1
    800033e6:	118080e7          	jalr	280(ra) # 800044fa <log_write>
  brelse(bp);
    800033ea:	854a                	mv	a0,s2
    800033ec:	00000097          	auipc	ra,0x0
    800033f0:	e92080e7          	jalr	-366(ra) # 8000327e <brelse>
}
    800033f4:	60e2                	ld	ra,24(sp)
    800033f6:	6442                	ld	s0,16(sp)
    800033f8:	64a2                	ld	s1,8(sp)
    800033fa:	6902                	ld	s2,0(sp)
    800033fc:	6105                	addi	sp,sp,32
    800033fe:	8082                	ret
    panic("freeing free block");
    80003400:	00005517          	auipc	a0,0x5
    80003404:	21050513          	addi	a0,a0,528 # 80008610 <syscalls+0xf0>
    80003408:	ffffd097          	auipc	ra,0xffffd
    8000340c:	136080e7          	jalr	310(ra) # 8000053e <panic>

0000000080003410 <balloc>:
{
    80003410:	711d                	addi	sp,sp,-96
    80003412:	ec86                	sd	ra,88(sp)
    80003414:	e8a2                	sd	s0,80(sp)
    80003416:	e4a6                	sd	s1,72(sp)
    80003418:	e0ca                	sd	s2,64(sp)
    8000341a:	fc4e                	sd	s3,56(sp)
    8000341c:	f852                	sd	s4,48(sp)
    8000341e:	f456                	sd	s5,40(sp)
    80003420:	f05a                	sd	s6,32(sp)
    80003422:	ec5e                	sd	s7,24(sp)
    80003424:	e862                	sd	s8,16(sp)
    80003426:	e466                	sd	s9,8(sp)
    80003428:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000342a:	0001c797          	auipc	a5,0x1c
    8000342e:	5827a783          	lw	a5,1410(a5) # 8001f9ac <sb+0x4>
    80003432:	cbd1                	beqz	a5,800034c6 <balloc+0xb6>
    80003434:	8baa                	mv	s7,a0
    80003436:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003438:	0001cb17          	auipc	s6,0x1c
    8000343c:	570b0b13          	addi	s6,s6,1392 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003440:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003442:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003444:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003446:	6c89                	lui	s9,0x2
    80003448:	a831                	j	80003464 <balloc+0x54>
    brelse(bp);
    8000344a:	854a                	mv	a0,s2
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e32080e7          	jalr	-462(ra) # 8000327e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003454:	015c87bb          	addw	a5,s9,s5
    80003458:	00078a9b          	sext.w	s5,a5
    8000345c:	004b2703          	lw	a4,4(s6)
    80003460:	06eaf363          	bgeu	s5,a4,800034c6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003464:	41fad79b          	sraiw	a5,s5,0x1f
    80003468:	0137d79b          	srliw	a5,a5,0x13
    8000346c:	015787bb          	addw	a5,a5,s5
    80003470:	40d7d79b          	sraiw	a5,a5,0xd
    80003474:	01cb2583          	lw	a1,28(s6)
    80003478:	9dbd                	addw	a1,a1,a5
    8000347a:	855e                	mv	a0,s7
    8000347c:	00000097          	auipc	ra,0x0
    80003480:	cd2080e7          	jalr	-814(ra) # 8000314e <bread>
    80003484:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003486:	004b2503          	lw	a0,4(s6)
    8000348a:	000a849b          	sext.w	s1,s5
    8000348e:	8662                	mv	a2,s8
    80003490:	faa4fde3          	bgeu	s1,a0,8000344a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003494:	41f6579b          	sraiw	a5,a2,0x1f
    80003498:	01d7d69b          	srliw	a3,a5,0x1d
    8000349c:	00c6873b          	addw	a4,a3,a2
    800034a0:	00777793          	andi	a5,a4,7
    800034a4:	9f95                	subw	a5,a5,a3
    800034a6:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034aa:	4037571b          	sraiw	a4,a4,0x3
    800034ae:	00e906b3          	add	a3,s2,a4
    800034b2:	0586c683          	lbu	a3,88(a3) # 1058 <_entry-0x7fffefa8>
    800034b6:	00d7f5b3          	and	a1,a5,a3
    800034ba:	cd91                	beqz	a1,800034d6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034bc:	2605                	addiw	a2,a2,1
    800034be:	2485                	addiw	s1,s1,1
    800034c0:	fd4618e3          	bne	a2,s4,80003490 <balloc+0x80>
    800034c4:	b759                	j	8000344a <balloc+0x3a>
  panic("balloc: out of blocks");
    800034c6:	00005517          	auipc	a0,0x5
    800034ca:	16250513          	addi	a0,a0,354 # 80008628 <syscalls+0x108>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	070080e7          	jalr	112(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034d6:	974a                	add	a4,a4,s2
    800034d8:	8fd5                	or	a5,a5,a3
    800034da:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034de:	854a                	mv	a0,s2
    800034e0:	00001097          	auipc	ra,0x1
    800034e4:	01a080e7          	jalr	26(ra) # 800044fa <log_write>
        brelse(bp);
    800034e8:	854a                	mv	a0,s2
    800034ea:	00000097          	auipc	ra,0x0
    800034ee:	d94080e7          	jalr	-620(ra) # 8000327e <brelse>
  bp = bread(dev, bno);
    800034f2:	85a6                	mv	a1,s1
    800034f4:	855e                	mv	a0,s7
    800034f6:	00000097          	auipc	ra,0x0
    800034fa:	c58080e7          	jalr	-936(ra) # 8000314e <bread>
    800034fe:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003500:	40000613          	li	a2,1024
    80003504:	4581                	li	a1,0
    80003506:	05850513          	addi	a0,a0,88
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	7d6080e7          	jalr	2006(ra) # 80000ce0 <memset>
  log_write(bp);
    80003512:	854a                	mv	a0,s2
    80003514:	00001097          	auipc	ra,0x1
    80003518:	fe6080e7          	jalr	-26(ra) # 800044fa <log_write>
  brelse(bp);
    8000351c:	854a                	mv	a0,s2
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	d60080e7          	jalr	-672(ra) # 8000327e <brelse>
}
    80003526:	8526                	mv	a0,s1
    80003528:	60e6                	ld	ra,88(sp)
    8000352a:	6446                	ld	s0,80(sp)
    8000352c:	64a6                	ld	s1,72(sp)
    8000352e:	6906                	ld	s2,64(sp)
    80003530:	79e2                	ld	s3,56(sp)
    80003532:	7a42                	ld	s4,48(sp)
    80003534:	7aa2                	ld	s5,40(sp)
    80003536:	7b02                	ld	s6,32(sp)
    80003538:	6be2                	ld	s7,24(sp)
    8000353a:	6c42                	ld	s8,16(sp)
    8000353c:	6ca2                	ld	s9,8(sp)
    8000353e:	6125                	addi	sp,sp,96
    80003540:	8082                	ret

0000000080003542 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003542:	7179                	addi	sp,sp,-48
    80003544:	f406                	sd	ra,40(sp)
    80003546:	f022                	sd	s0,32(sp)
    80003548:	ec26                	sd	s1,24(sp)
    8000354a:	e84a                	sd	s2,16(sp)
    8000354c:	e44e                	sd	s3,8(sp)
    8000354e:	e052                	sd	s4,0(sp)
    80003550:	1800                	addi	s0,sp,48
    80003552:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003554:	47ad                	li	a5,11
    80003556:	04b7fe63          	bgeu	a5,a1,800035b2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000355a:	ff45849b          	addiw	s1,a1,-12
    8000355e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003562:	0ff00793          	li	a5,255
    80003566:	0ae7e363          	bltu	a5,a4,8000360c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000356a:	08052583          	lw	a1,128(a0)
    8000356e:	c5ad                	beqz	a1,800035d8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003570:	00092503          	lw	a0,0(s2)
    80003574:	00000097          	auipc	ra,0x0
    80003578:	bda080e7          	jalr	-1062(ra) # 8000314e <bread>
    8000357c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000357e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003582:	02049593          	slli	a1,s1,0x20
    80003586:	9181                	srli	a1,a1,0x20
    80003588:	058a                	slli	a1,a1,0x2
    8000358a:	00b784b3          	add	s1,a5,a1
    8000358e:	0004a983          	lw	s3,0(s1)
    80003592:	04098d63          	beqz	s3,800035ec <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003596:	8552                	mv	a0,s4
    80003598:	00000097          	auipc	ra,0x0
    8000359c:	ce6080e7          	jalr	-794(ra) # 8000327e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035a0:	854e                	mv	a0,s3
    800035a2:	70a2                	ld	ra,40(sp)
    800035a4:	7402                	ld	s0,32(sp)
    800035a6:	64e2                	ld	s1,24(sp)
    800035a8:	6942                	ld	s2,16(sp)
    800035aa:	69a2                	ld	s3,8(sp)
    800035ac:	6a02                	ld	s4,0(sp)
    800035ae:	6145                	addi	sp,sp,48
    800035b0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035b2:	02059493          	slli	s1,a1,0x20
    800035b6:	9081                	srli	s1,s1,0x20
    800035b8:	048a                	slli	s1,s1,0x2
    800035ba:	94aa                	add	s1,s1,a0
    800035bc:	0504a983          	lw	s3,80(s1)
    800035c0:	fe0990e3          	bnez	s3,800035a0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035c4:	4108                	lw	a0,0(a0)
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	e4a080e7          	jalr	-438(ra) # 80003410 <balloc>
    800035ce:	0005099b          	sext.w	s3,a0
    800035d2:	0534a823          	sw	s3,80(s1)
    800035d6:	b7e9                	j	800035a0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035d8:	4108                	lw	a0,0(a0)
    800035da:	00000097          	auipc	ra,0x0
    800035de:	e36080e7          	jalr	-458(ra) # 80003410 <balloc>
    800035e2:	0005059b          	sext.w	a1,a0
    800035e6:	08b92023          	sw	a1,128(s2)
    800035ea:	b759                	j	80003570 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035ec:	00092503          	lw	a0,0(s2)
    800035f0:	00000097          	auipc	ra,0x0
    800035f4:	e20080e7          	jalr	-480(ra) # 80003410 <balloc>
    800035f8:	0005099b          	sext.w	s3,a0
    800035fc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003600:	8552                	mv	a0,s4
    80003602:	00001097          	auipc	ra,0x1
    80003606:	ef8080e7          	jalr	-264(ra) # 800044fa <log_write>
    8000360a:	b771                	j	80003596 <bmap+0x54>
  panic("bmap: out of range");
    8000360c:	00005517          	auipc	a0,0x5
    80003610:	03450513          	addi	a0,a0,52 # 80008640 <syscalls+0x120>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	f2a080e7          	jalr	-214(ra) # 8000053e <panic>

000000008000361c <iget>:
{
    8000361c:	7179                	addi	sp,sp,-48
    8000361e:	f406                	sd	ra,40(sp)
    80003620:	f022                	sd	s0,32(sp)
    80003622:	ec26                	sd	s1,24(sp)
    80003624:	e84a                	sd	s2,16(sp)
    80003626:	e44e                	sd	s3,8(sp)
    80003628:	e052                	sd	s4,0(sp)
    8000362a:	1800                	addi	s0,sp,48
    8000362c:	89aa                	mv	s3,a0
    8000362e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	39850513          	addi	a0,a0,920 # 8001f9c8 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	5ac080e7          	jalr	1452(ra) # 80000be4 <acquire>
  empty = 0;
    80003640:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003642:	0001c497          	auipc	s1,0x1c
    80003646:	39e48493          	addi	s1,s1,926 # 8001f9e0 <itable+0x18>
    8000364a:	0001e697          	auipc	a3,0x1e
    8000364e:	e2668693          	addi	a3,a3,-474 # 80021470 <log>
    80003652:	a039                	j	80003660 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003654:	02090b63          	beqz	s2,8000368a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003658:	08848493          	addi	s1,s1,136
    8000365c:	02d48a63          	beq	s1,a3,80003690 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003660:	449c                	lw	a5,8(s1)
    80003662:	fef059e3          	blez	a5,80003654 <iget+0x38>
    80003666:	4098                	lw	a4,0(s1)
    80003668:	ff3716e3          	bne	a4,s3,80003654 <iget+0x38>
    8000366c:	40d8                	lw	a4,4(s1)
    8000366e:	ff4713e3          	bne	a4,s4,80003654 <iget+0x38>
      ip->ref++;
    80003672:	2785                	addiw	a5,a5,1
    80003674:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003676:	0001c517          	auipc	a0,0x1c
    8000367a:	35250513          	addi	a0,a0,850 # 8001f9c8 <itable>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	61a080e7          	jalr	1562(ra) # 80000c98 <release>
      return ip;
    80003686:	8926                	mv	s2,s1
    80003688:	a03d                	j	800036b6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368a:	f7f9                	bnez	a5,80003658 <iget+0x3c>
    8000368c:	8926                	mv	s2,s1
    8000368e:	b7e9                	j	80003658 <iget+0x3c>
  if(empty == 0)
    80003690:	02090c63          	beqz	s2,800036c8 <iget+0xac>
  ip->dev = dev;
    80003694:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003698:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000369c:	4785                	li	a5,1
    8000369e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036a2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036a6:	0001c517          	auipc	a0,0x1c
    800036aa:	32250513          	addi	a0,a0,802 # 8001f9c8 <itable>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	5ea080e7          	jalr	1514(ra) # 80000c98 <release>
}
    800036b6:	854a                	mv	a0,s2
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6a02                	ld	s4,0(sp)
    800036c4:	6145                	addi	sp,sp,48
    800036c6:	8082                	ret
    panic("iget: no inodes");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	f9050513          	addi	a0,a0,-112 # 80008658 <syscalls+0x138>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e6e080e7          	jalr	-402(ra) # 8000053e <panic>

00000000800036d8 <fsinit>:
fsinit(int dev) {
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	1800                	addi	s0,sp,48
    800036e6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036e8:	4585                	li	a1,1
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	a64080e7          	jalr	-1436(ra) # 8000314e <bread>
    800036f2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036f4:	0001c997          	auipc	s3,0x1c
    800036f8:	2b498993          	addi	s3,s3,692 # 8001f9a8 <sb>
    800036fc:	02000613          	li	a2,32
    80003700:	05850593          	addi	a1,a0,88
    80003704:	854e                	mv	a0,s3
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	63a080e7          	jalr	1594(ra) # 80000d40 <memmove>
  brelse(bp);
    8000370e:	8526                	mv	a0,s1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	b6e080e7          	jalr	-1170(ra) # 8000327e <brelse>
  if(sb.magic != FSMAGIC)
    80003718:	0009a703          	lw	a4,0(s3)
    8000371c:	102037b7          	lui	a5,0x10203
    80003720:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003724:	02f71263          	bne	a4,a5,80003748 <fsinit+0x70>
  initlog(dev, &sb);
    80003728:	0001c597          	auipc	a1,0x1c
    8000372c:	28058593          	addi	a1,a1,640 # 8001f9a8 <sb>
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	b4c080e7          	jalr	-1204(ra) # 8000427e <initlog>
}
    8000373a:	70a2                	ld	ra,40(sp)
    8000373c:	7402                	ld	s0,32(sp)
    8000373e:	64e2                	ld	s1,24(sp)
    80003740:	6942                	ld	s2,16(sp)
    80003742:	69a2                	ld	s3,8(sp)
    80003744:	6145                	addi	sp,sp,48
    80003746:	8082                	ret
    panic("invalid file system");
    80003748:	00005517          	auipc	a0,0x5
    8000374c:	f2050513          	addi	a0,a0,-224 # 80008668 <syscalls+0x148>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	dee080e7          	jalr	-530(ra) # 8000053e <panic>

0000000080003758 <iinit>:
{
    80003758:	7179                	addi	sp,sp,-48
    8000375a:	f406                	sd	ra,40(sp)
    8000375c:	f022                	sd	s0,32(sp)
    8000375e:	ec26                	sd	s1,24(sp)
    80003760:	e84a                	sd	s2,16(sp)
    80003762:	e44e                	sd	s3,8(sp)
    80003764:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003766:	00005597          	auipc	a1,0x5
    8000376a:	f1a58593          	addi	a1,a1,-230 # 80008680 <syscalls+0x160>
    8000376e:	0001c517          	auipc	a0,0x1c
    80003772:	25a50513          	addi	a0,a0,602 # 8001f9c8 <itable>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	3de080e7          	jalr	990(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000377e:	0001c497          	auipc	s1,0x1c
    80003782:	27248493          	addi	s1,s1,626 # 8001f9f0 <itable+0x28>
    80003786:	0001e997          	auipc	s3,0x1e
    8000378a:	cfa98993          	addi	s3,s3,-774 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000378e:	00005917          	auipc	s2,0x5
    80003792:	efa90913          	addi	s2,s2,-262 # 80008688 <syscalls+0x168>
    80003796:	85ca                	mv	a1,s2
    80003798:	8526                	mv	a0,s1
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	e46080e7          	jalr	-442(ra) # 800045e0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037a2:	08848493          	addi	s1,s1,136
    800037a6:	ff3498e3          	bne	s1,s3,80003796 <iinit+0x3e>
}
    800037aa:	70a2                	ld	ra,40(sp)
    800037ac:	7402                	ld	s0,32(sp)
    800037ae:	64e2                	ld	s1,24(sp)
    800037b0:	6942                	ld	s2,16(sp)
    800037b2:	69a2                	ld	s3,8(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret

00000000800037b8 <ialloc>:
{
    800037b8:	715d                	addi	sp,sp,-80
    800037ba:	e486                	sd	ra,72(sp)
    800037bc:	e0a2                	sd	s0,64(sp)
    800037be:	fc26                	sd	s1,56(sp)
    800037c0:	f84a                	sd	s2,48(sp)
    800037c2:	f44e                	sd	s3,40(sp)
    800037c4:	f052                	sd	s4,32(sp)
    800037c6:	ec56                	sd	s5,24(sp)
    800037c8:	e85a                	sd	s6,16(sp)
    800037ca:	e45e                	sd	s7,8(sp)
    800037cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ce:	0001c717          	auipc	a4,0x1c
    800037d2:	1e672703          	lw	a4,486(a4) # 8001f9b4 <sb+0xc>
    800037d6:	4785                	li	a5,1
    800037d8:	04e7fa63          	bgeu	a5,a4,8000382c <ialloc+0x74>
    800037dc:	8aaa                	mv	s5,a0
    800037de:	8bae                	mv	s7,a1
    800037e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037e2:	0001ca17          	auipc	s4,0x1c
    800037e6:	1c6a0a13          	addi	s4,s4,454 # 8001f9a8 <sb>
    800037ea:	00048b1b          	sext.w	s6,s1
    800037ee:	0044d593          	srli	a1,s1,0x4
    800037f2:	018a2783          	lw	a5,24(s4)
    800037f6:	9dbd                	addw	a1,a1,a5
    800037f8:	8556                	mv	a0,s5
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	954080e7          	jalr	-1708(ra) # 8000314e <bread>
    80003802:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003804:	05850993          	addi	s3,a0,88
    80003808:	00f4f793          	andi	a5,s1,15
    8000380c:	079a                	slli	a5,a5,0x6
    8000380e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003810:	00099783          	lh	a5,0(s3)
    80003814:	c785                	beqz	a5,8000383c <ialloc+0x84>
    brelse(bp);
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	a68080e7          	jalr	-1432(ra) # 8000327e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000381e:	0485                	addi	s1,s1,1
    80003820:	00ca2703          	lw	a4,12(s4)
    80003824:	0004879b          	sext.w	a5,s1
    80003828:	fce7e1e3          	bltu	a5,a4,800037ea <ialloc+0x32>
  panic("ialloc: no inodes");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	e6450513          	addi	a0,a0,-412 # 80008690 <syscalls+0x170>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d0a080e7          	jalr	-758(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    8000383c:	04000613          	li	a2,64
    80003840:	4581                	li	a1,0
    80003842:	854e                	mv	a0,s3
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	49c080e7          	jalr	1180(ra) # 80000ce0 <memset>
      dip->type = type;
    8000384c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	ca8080e7          	jalr	-856(ra) # 800044fa <log_write>
      brelse(bp);
    8000385a:	854a                	mv	a0,s2
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	a22080e7          	jalr	-1502(ra) # 8000327e <brelse>
      return iget(dev, inum);
    80003864:	85da                	mv	a1,s6
    80003866:	8556                	mv	a0,s5
    80003868:	00000097          	auipc	ra,0x0
    8000386c:	db4080e7          	jalr	-588(ra) # 8000361c <iget>
}
    80003870:	60a6                	ld	ra,72(sp)
    80003872:	6406                	ld	s0,64(sp)
    80003874:	74e2                	ld	s1,56(sp)
    80003876:	7942                	ld	s2,48(sp)
    80003878:	79a2                	ld	s3,40(sp)
    8000387a:	7a02                	ld	s4,32(sp)
    8000387c:	6ae2                	ld	s5,24(sp)
    8000387e:	6b42                	ld	s6,16(sp)
    80003880:	6ba2                	ld	s7,8(sp)
    80003882:	6161                	addi	sp,sp,80
    80003884:	8082                	ret

0000000080003886 <iupdate>:
{
    80003886:	1101                	addi	sp,sp,-32
    80003888:	ec06                	sd	ra,24(sp)
    8000388a:	e822                	sd	s0,16(sp)
    8000388c:	e426                	sd	s1,8(sp)
    8000388e:	e04a                	sd	s2,0(sp)
    80003890:	1000                	addi	s0,sp,32
    80003892:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003894:	415c                	lw	a5,4(a0)
    80003896:	0047d79b          	srliw	a5,a5,0x4
    8000389a:	0001c597          	auipc	a1,0x1c
    8000389e:	1265a583          	lw	a1,294(a1) # 8001f9c0 <sb+0x18>
    800038a2:	9dbd                	addw	a1,a1,a5
    800038a4:	4108                	lw	a0,0(a0)
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	8a8080e7          	jalr	-1880(ra) # 8000314e <bread>
    800038ae:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b0:	05850793          	addi	a5,a0,88
    800038b4:	40c8                	lw	a0,4(s1)
    800038b6:	893d                	andi	a0,a0,15
    800038b8:	051a                	slli	a0,a0,0x6
    800038ba:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038bc:	04449703          	lh	a4,68(s1)
    800038c0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038c4:	04649703          	lh	a4,70(s1)
    800038c8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038cc:	04849703          	lh	a4,72(s1)
    800038d0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038d4:	04a49703          	lh	a4,74(s1)
    800038d8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038dc:	44f8                	lw	a4,76(s1)
    800038de:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038e0:	03400613          	li	a2,52
    800038e4:	05048593          	addi	a1,s1,80
    800038e8:	0531                	addi	a0,a0,12
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	456080e7          	jalr	1110(ra) # 80000d40 <memmove>
  log_write(bp);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	c06080e7          	jalr	-1018(ra) # 800044fa <log_write>
  brelse(bp);
    800038fc:	854a                	mv	a0,s2
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	980080e7          	jalr	-1664(ra) # 8000327e <brelse>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6902                	ld	s2,0(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret

0000000080003912 <idup>:
{
    80003912:	1101                	addi	sp,sp,-32
    80003914:	ec06                	sd	ra,24(sp)
    80003916:	e822                	sd	s0,16(sp)
    80003918:	e426                	sd	s1,8(sp)
    8000391a:	1000                	addi	s0,sp,32
    8000391c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000391e:	0001c517          	auipc	a0,0x1c
    80003922:	0aa50513          	addi	a0,a0,170 # 8001f9c8 <itable>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	2be080e7          	jalr	702(ra) # 80000be4 <acquire>
  ip->ref++;
    8000392e:	449c                	lw	a5,8(s1)
    80003930:	2785                	addiw	a5,a5,1
    80003932:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003934:	0001c517          	auipc	a0,0x1c
    80003938:	09450513          	addi	a0,a0,148 # 8001f9c8 <itable>
    8000393c:	ffffd097          	auipc	ra,0xffffd
    80003940:	35c080e7          	jalr	860(ra) # 80000c98 <release>
}
    80003944:	8526                	mv	a0,s1
    80003946:	60e2                	ld	ra,24(sp)
    80003948:	6442                	ld	s0,16(sp)
    8000394a:	64a2                	ld	s1,8(sp)
    8000394c:	6105                	addi	sp,sp,32
    8000394e:	8082                	ret

0000000080003950 <ilock>:
{
    80003950:	1101                	addi	sp,sp,-32
    80003952:	ec06                	sd	ra,24(sp)
    80003954:	e822                	sd	s0,16(sp)
    80003956:	e426                	sd	s1,8(sp)
    80003958:	e04a                	sd	s2,0(sp)
    8000395a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000395c:	c115                	beqz	a0,80003980 <ilock+0x30>
    8000395e:	84aa                	mv	s1,a0
    80003960:	451c                	lw	a5,8(a0)
    80003962:	00f05f63          	blez	a5,80003980 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003966:	0541                	addi	a0,a0,16
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	cb2080e7          	jalr	-846(ra) # 8000461a <acquiresleep>
  if(ip->valid == 0){
    80003970:	40bc                	lw	a5,64(s1)
    80003972:	cf99                	beqz	a5,80003990 <ilock+0x40>
}
    80003974:	60e2                	ld	ra,24(sp)
    80003976:	6442                	ld	s0,16(sp)
    80003978:	64a2                	ld	s1,8(sp)
    8000397a:	6902                	ld	s2,0(sp)
    8000397c:	6105                	addi	sp,sp,32
    8000397e:	8082                	ret
    panic("ilock");
    80003980:	00005517          	auipc	a0,0x5
    80003984:	d2850513          	addi	a0,a0,-728 # 800086a8 <syscalls+0x188>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	bb6080e7          	jalr	-1098(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003990:	40dc                	lw	a5,4(s1)
    80003992:	0047d79b          	srliw	a5,a5,0x4
    80003996:	0001c597          	auipc	a1,0x1c
    8000399a:	02a5a583          	lw	a1,42(a1) # 8001f9c0 <sb+0x18>
    8000399e:	9dbd                	addw	a1,a1,a5
    800039a0:	4088                	lw	a0,0(s1)
    800039a2:	fffff097          	auipc	ra,0xfffff
    800039a6:	7ac080e7          	jalr	1964(ra) # 8000314e <bread>
    800039aa:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039ac:	05850593          	addi	a1,a0,88
    800039b0:	40dc                	lw	a5,4(s1)
    800039b2:	8bbd                	andi	a5,a5,15
    800039b4:	079a                	slli	a5,a5,0x6
    800039b6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039b8:	00059783          	lh	a5,0(a1)
    800039bc:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039c0:	00259783          	lh	a5,2(a1)
    800039c4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039c8:	00459783          	lh	a5,4(a1)
    800039cc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039d0:	00659783          	lh	a5,6(a1)
    800039d4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039d8:	459c                	lw	a5,8(a1)
    800039da:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039dc:	03400613          	li	a2,52
    800039e0:	05b1                	addi	a1,a1,12
    800039e2:	05048513          	addi	a0,s1,80
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	35a080e7          	jalr	858(ra) # 80000d40 <memmove>
    brelse(bp);
    800039ee:	854a                	mv	a0,s2
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	88e080e7          	jalr	-1906(ra) # 8000327e <brelse>
    ip->valid = 1;
    800039f8:	4785                	li	a5,1
    800039fa:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039fc:	04449783          	lh	a5,68(s1)
    80003a00:	fbb5                	bnez	a5,80003974 <ilock+0x24>
      panic("ilock: no type");
    80003a02:	00005517          	auipc	a0,0x5
    80003a06:	cae50513          	addi	a0,a0,-850 # 800086b0 <syscalls+0x190>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	b34080e7          	jalr	-1228(ra) # 8000053e <panic>

0000000080003a12 <iunlock>:
{
    80003a12:	1101                	addi	sp,sp,-32
    80003a14:	ec06                	sd	ra,24(sp)
    80003a16:	e822                	sd	s0,16(sp)
    80003a18:	e426                	sd	s1,8(sp)
    80003a1a:	e04a                	sd	s2,0(sp)
    80003a1c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a1e:	c905                	beqz	a0,80003a4e <iunlock+0x3c>
    80003a20:	84aa                	mv	s1,a0
    80003a22:	01050913          	addi	s2,a0,16
    80003a26:	854a                	mv	a0,s2
    80003a28:	00001097          	auipc	ra,0x1
    80003a2c:	c8c080e7          	jalr	-884(ra) # 800046b4 <holdingsleep>
    80003a30:	cd19                	beqz	a0,80003a4e <iunlock+0x3c>
    80003a32:	449c                	lw	a5,8(s1)
    80003a34:	00f05d63          	blez	a5,80003a4e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	c36080e7          	jalr	-970(ra) # 80004670 <releasesleep>
}
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	64a2                	ld	s1,8(sp)
    80003a48:	6902                	ld	s2,0(sp)
    80003a4a:	6105                	addi	sp,sp,32
    80003a4c:	8082                	ret
    panic("iunlock");
    80003a4e:	00005517          	auipc	a0,0x5
    80003a52:	c7250513          	addi	a0,a0,-910 # 800086c0 <syscalls+0x1a0>
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	ae8080e7          	jalr	-1304(ra) # 8000053e <panic>

0000000080003a5e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a5e:	7179                	addi	sp,sp,-48
    80003a60:	f406                	sd	ra,40(sp)
    80003a62:	f022                	sd	s0,32(sp)
    80003a64:	ec26                	sd	s1,24(sp)
    80003a66:	e84a                	sd	s2,16(sp)
    80003a68:	e44e                	sd	s3,8(sp)
    80003a6a:	e052                	sd	s4,0(sp)
    80003a6c:	1800                	addi	s0,sp,48
    80003a6e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a70:	05050493          	addi	s1,a0,80
    80003a74:	08050913          	addi	s2,a0,128
    80003a78:	a021                	j	80003a80 <itrunc+0x22>
    80003a7a:	0491                	addi	s1,s1,4
    80003a7c:	01248d63          	beq	s1,s2,80003a96 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a80:	408c                	lw	a1,0(s1)
    80003a82:	dde5                	beqz	a1,80003a7a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a84:	0009a503          	lw	a0,0(s3)
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	90c080e7          	jalr	-1780(ra) # 80003394 <bfree>
      ip->addrs[i] = 0;
    80003a90:	0004a023          	sw	zero,0(s1)
    80003a94:	b7dd                	j	80003a7a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a96:	0809a583          	lw	a1,128(s3)
    80003a9a:	e185                	bnez	a1,80003aba <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a9c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aa0:	854e                	mv	a0,s3
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	de4080e7          	jalr	-540(ra) # 80003886 <iupdate>
}
    80003aaa:	70a2                	ld	ra,40(sp)
    80003aac:	7402                	ld	s0,32(sp)
    80003aae:	64e2                	ld	s1,24(sp)
    80003ab0:	6942                	ld	s2,16(sp)
    80003ab2:	69a2                	ld	s3,8(sp)
    80003ab4:	6a02                	ld	s4,0(sp)
    80003ab6:	6145                	addi	sp,sp,48
    80003ab8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	690080e7          	jalr	1680(ra) # 8000314e <bread>
    80003ac6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ac8:	05850493          	addi	s1,a0,88
    80003acc:	45850913          	addi	s2,a0,1112
    80003ad0:	a811                	j	80003ae4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ad2:	0009a503          	lw	a0,0(s3)
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	8be080e7          	jalr	-1858(ra) # 80003394 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ade:	0491                	addi	s1,s1,4
    80003ae0:	01248563          	beq	s1,s2,80003aea <itrunc+0x8c>
      if(a[j])
    80003ae4:	408c                	lw	a1,0(s1)
    80003ae6:	dde5                	beqz	a1,80003ade <itrunc+0x80>
    80003ae8:	b7ed                	j	80003ad2 <itrunc+0x74>
    brelse(bp);
    80003aea:	8552                	mv	a0,s4
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	792080e7          	jalr	1938(ra) # 8000327e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003af4:	0809a583          	lw	a1,128(s3)
    80003af8:	0009a503          	lw	a0,0(s3)
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	898080e7          	jalr	-1896(ra) # 80003394 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b04:	0809a023          	sw	zero,128(s3)
    80003b08:	bf51                	j	80003a9c <itrunc+0x3e>

0000000080003b0a <iput>:
{
    80003b0a:	1101                	addi	sp,sp,-32
    80003b0c:	ec06                	sd	ra,24(sp)
    80003b0e:	e822                	sd	s0,16(sp)
    80003b10:	e426                	sd	s1,8(sp)
    80003b12:	e04a                	sd	s2,0(sp)
    80003b14:	1000                	addi	s0,sp,32
    80003b16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b18:	0001c517          	auipc	a0,0x1c
    80003b1c:	eb050513          	addi	a0,a0,-336 # 8001f9c8 <itable>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	0c4080e7          	jalr	196(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b28:	4498                	lw	a4,8(s1)
    80003b2a:	4785                	li	a5,1
    80003b2c:	02f70363          	beq	a4,a5,80003b52 <iput+0x48>
  ip->ref--;
    80003b30:	449c                	lw	a5,8(s1)
    80003b32:	37fd                	addiw	a5,a5,-1
    80003b34:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b36:	0001c517          	auipc	a0,0x1c
    80003b3a:	e9250513          	addi	a0,a0,-366 # 8001f9c8 <itable>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	15a080e7          	jalr	346(ra) # 80000c98 <release>
}
    80003b46:	60e2                	ld	ra,24(sp)
    80003b48:	6442                	ld	s0,16(sp)
    80003b4a:	64a2                	ld	s1,8(sp)
    80003b4c:	6902                	ld	s2,0(sp)
    80003b4e:	6105                	addi	sp,sp,32
    80003b50:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b52:	40bc                	lw	a5,64(s1)
    80003b54:	dff1                	beqz	a5,80003b30 <iput+0x26>
    80003b56:	04a49783          	lh	a5,74(s1)
    80003b5a:	fbf9                	bnez	a5,80003b30 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b5c:	01048913          	addi	s2,s1,16
    80003b60:	854a                	mv	a0,s2
    80003b62:	00001097          	auipc	ra,0x1
    80003b66:	ab8080e7          	jalr	-1352(ra) # 8000461a <acquiresleep>
    release(&itable.lock);
    80003b6a:	0001c517          	auipc	a0,0x1c
    80003b6e:	e5e50513          	addi	a0,a0,-418 # 8001f9c8 <itable>
    80003b72:	ffffd097          	auipc	ra,0xffffd
    80003b76:	126080e7          	jalr	294(ra) # 80000c98 <release>
    itrunc(ip);
    80003b7a:	8526                	mv	a0,s1
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	ee2080e7          	jalr	-286(ra) # 80003a5e <itrunc>
    ip->type = 0;
    80003b84:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	00000097          	auipc	ra,0x0
    80003b8e:	cfc080e7          	jalr	-772(ra) # 80003886 <iupdate>
    ip->valid = 0;
    80003b92:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b96:	854a                	mv	a0,s2
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	ad8080e7          	jalr	-1320(ra) # 80004670 <releasesleep>
    acquire(&itable.lock);
    80003ba0:	0001c517          	auipc	a0,0x1c
    80003ba4:	e2850513          	addi	a0,a0,-472 # 8001f9c8 <itable>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	03c080e7          	jalr	60(ra) # 80000be4 <acquire>
    80003bb0:	b741                	j	80003b30 <iput+0x26>

0000000080003bb2 <iunlockput>:
{
    80003bb2:	1101                	addi	sp,sp,-32
    80003bb4:	ec06                	sd	ra,24(sp)
    80003bb6:	e822                	sd	s0,16(sp)
    80003bb8:	e426                	sd	s1,8(sp)
    80003bba:	1000                	addi	s0,sp,32
    80003bbc:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	e54080e7          	jalr	-428(ra) # 80003a12 <iunlock>
  iput(ip);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	f42080e7          	jalr	-190(ra) # 80003b0a <iput>
}
    80003bd0:	60e2                	ld	ra,24(sp)
    80003bd2:	6442                	ld	s0,16(sp)
    80003bd4:	64a2                	ld	s1,8(sp)
    80003bd6:	6105                	addi	sp,sp,32
    80003bd8:	8082                	ret

0000000080003bda <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bda:	1141                	addi	sp,sp,-16
    80003bdc:	e422                	sd	s0,8(sp)
    80003bde:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003be0:	411c                	lw	a5,0(a0)
    80003be2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003be4:	415c                	lw	a5,4(a0)
    80003be6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003be8:	04451783          	lh	a5,68(a0)
    80003bec:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bf0:	04a51783          	lh	a5,74(a0)
    80003bf4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bf8:	04c56783          	lwu	a5,76(a0)
    80003bfc:	e99c                	sd	a5,16(a1)
}
    80003bfe:	6422                	ld	s0,8(sp)
    80003c00:	0141                	addi	sp,sp,16
    80003c02:	8082                	ret

0000000080003c04 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c04:	457c                	lw	a5,76(a0)
    80003c06:	0ed7e963          	bltu	a5,a3,80003cf8 <readi+0xf4>
{
    80003c0a:	7159                	addi	sp,sp,-112
    80003c0c:	f486                	sd	ra,104(sp)
    80003c0e:	f0a2                	sd	s0,96(sp)
    80003c10:	eca6                	sd	s1,88(sp)
    80003c12:	e8ca                	sd	s2,80(sp)
    80003c14:	e4ce                	sd	s3,72(sp)
    80003c16:	e0d2                	sd	s4,64(sp)
    80003c18:	fc56                	sd	s5,56(sp)
    80003c1a:	f85a                	sd	s6,48(sp)
    80003c1c:	f45e                	sd	s7,40(sp)
    80003c1e:	f062                	sd	s8,32(sp)
    80003c20:	ec66                	sd	s9,24(sp)
    80003c22:	e86a                	sd	s10,16(sp)
    80003c24:	e46e                	sd	s11,8(sp)
    80003c26:	1880                	addi	s0,sp,112
    80003c28:	8baa                	mv	s7,a0
    80003c2a:	8c2e                	mv	s8,a1
    80003c2c:	8ab2                	mv	s5,a2
    80003c2e:	84b6                	mv	s1,a3
    80003c30:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c32:	9f35                	addw	a4,a4,a3
    return 0;
    80003c34:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c36:	0ad76063          	bltu	a4,a3,80003cd6 <readi+0xd2>
  if(off + n > ip->size)
    80003c3a:	00e7f463          	bgeu	a5,a4,80003c42 <readi+0x3e>
    n = ip->size - off;
    80003c3e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c42:	0a0b0963          	beqz	s6,80003cf4 <readi+0xf0>
    80003c46:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c48:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c4c:	5cfd                	li	s9,-1
    80003c4e:	a82d                	j	80003c88 <readi+0x84>
    80003c50:	020a1d93          	slli	s11,s4,0x20
    80003c54:	020ddd93          	srli	s11,s11,0x20
    80003c58:	05890613          	addi	a2,s2,88
    80003c5c:	86ee                	mv	a3,s11
    80003c5e:	963a                	add	a2,a2,a4
    80003c60:	85d6                	mv	a1,s5
    80003c62:	8562                	mv	a0,s8
    80003c64:	ffffe097          	auipc	ra,0xffffe
    80003c68:	7fa080e7          	jalr	2042(ra) # 8000245e <either_copyout>
    80003c6c:	05950d63          	beq	a0,s9,80003cc6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c70:	854a                	mv	a0,s2
    80003c72:	fffff097          	auipc	ra,0xfffff
    80003c76:	60c080e7          	jalr	1548(ra) # 8000327e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7a:	013a09bb          	addw	s3,s4,s3
    80003c7e:	009a04bb          	addw	s1,s4,s1
    80003c82:	9aee                	add	s5,s5,s11
    80003c84:	0569f763          	bgeu	s3,s6,80003cd2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c88:	000ba903          	lw	s2,0(s7)
    80003c8c:	00a4d59b          	srliw	a1,s1,0xa
    80003c90:	855e                	mv	a0,s7
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	8b0080e7          	jalr	-1872(ra) # 80003542 <bmap>
    80003c9a:	0005059b          	sext.w	a1,a0
    80003c9e:	854a                	mv	a0,s2
    80003ca0:	fffff097          	auipc	ra,0xfffff
    80003ca4:	4ae080e7          	jalr	1198(ra) # 8000314e <bread>
    80003ca8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003caa:	3ff4f713          	andi	a4,s1,1023
    80003cae:	40ed07bb          	subw	a5,s10,a4
    80003cb2:	413b06bb          	subw	a3,s6,s3
    80003cb6:	8a3e                	mv	s4,a5
    80003cb8:	2781                	sext.w	a5,a5
    80003cba:	0006861b          	sext.w	a2,a3
    80003cbe:	f8f679e3          	bgeu	a2,a5,80003c50 <readi+0x4c>
    80003cc2:	8a36                	mv	s4,a3
    80003cc4:	b771                	j	80003c50 <readi+0x4c>
      brelse(bp);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	5b6080e7          	jalr	1462(ra) # 8000327e <brelse>
      tot = -1;
    80003cd0:	59fd                	li	s3,-1
  }
  return tot;
    80003cd2:	0009851b          	sext.w	a0,s3
}
    80003cd6:	70a6                	ld	ra,104(sp)
    80003cd8:	7406                	ld	s0,96(sp)
    80003cda:	64e6                	ld	s1,88(sp)
    80003cdc:	6946                	ld	s2,80(sp)
    80003cde:	69a6                	ld	s3,72(sp)
    80003ce0:	6a06                	ld	s4,64(sp)
    80003ce2:	7ae2                	ld	s5,56(sp)
    80003ce4:	7b42                	ld	s6,48(sp)
    80003ce6:	7ba2                	ld	s7,40(sp)
    80003ce8:	7c02                	ld	s8,32(sp)
    80003cea:	6ce2                	ld	s9,24(sp)
    80003cec:	6d42                	ld	s10,16(sp)
    80003cee:	6da2                	ld	s11,8(sp)
    80003cf0:	6165                	addi	sp,sp,112
    80003cf2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf4:	89da                	mv	s3,s6
    80003cf6:	bff1                	j	80003cd2 <readi+0xce>
    return 0;
    80003cf8:	4501                	li	a0,0
}
    80003cfa:	8082                	ret

0000000080003cfc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cfc:	457c                	lw	a5,76(a0)
    80003cfe:	10d7e863          	bltu	a5,a3,80003e0e <writei+0x112>
{
    80003d02:	7159                	addi	sp,sp,-112
    80003d04:	f486                	sd	ra,104(sp)
    80003d06:	f0a2                	sd	s0,96(sp)
    80003d08:	eca6                	sd	s1,88(sp)
    80003d0a:	e8ca                	sd	s2,80(sp)
    80003d0c:	e4ce                	sd	s3,72(sp)
    80003d0e:	e0d2                	sd	s4,64(sp)
    80003d10:	fc56                	sd	s5,56(sp)
    80003d12:	f85a                	sd	s6,48(sp)
    80003d14:	f45e                	sd	s7,40(sp)
    80003d16:	f062                	sd	s8,32(sp)
    80003d18:	ec66                	sd	s9,24(sp)
    80003d1a:	e86a                	sd	s10,16(sp)
    80003d1c:	e46e                	sd	s11,8(sp)
    80003d1e:	1880                	addi	s0,sp,112
    80003d20:	8b2a                	mv	s6,a0
    80003d22:	8c2e                	mv	s8,a1
    80003d24:	8ab2                	mv	s5,a2
    80003d26:	8936                	mv	s2,a3
    80003d28:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d2a:	00e687bb          	addw	a5,a3,a4
    80003d2e:	0ed7e263          	bltu	a5,a3,80003e12 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d32:	00043737          	lui	a4,0x43
    80003d36:	0ef76063          	bltu	a4,a5,80003e16 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3a:	0c0b8863          	beqz	s7,80003e0a <writei+0x10e>
    80003d3e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d40:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d44:	5cfd                	li	s9,-1
    80003d46:	a091                	j	80003d8a <writei+0x8e>
    80003d48:	02099d93          	slli	s11,s3,0x20
    80003d4c:	020ddd93          	srli	s11,s11,0x20
    80003d50:	05848513          	addi	a0,s1,88
    80003d54:	86ee                	mv	a3,s11
    80003d56:	8656                	mv	a2,s5
    80003d58:	85e2                	mv	a1,s8
    80003d5a:	953a                	add	a0,a0,a4
    80003d5c:	ffffe097          	auipc	ra,0xffffe
    80003d60:	758080e7          	jalr	1880(ra) # 800024b4 <either_copyin>
    80003d64:	07950263          	beq	a0,s9,80003dc8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d68:	8526                	mv	a0,s1
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	790080e7          	jalr	1936(ra) # 800044fa <log_write>
    brelse(bp);
    80003d72:	8526                	mv	a0,s1
    80003d74:	fffff097          	auipc	ra,0xfffff
    80003d78:	50a080e7          	jalr	1290(ra) # 8000327e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d7c:	01498a3b          	addw	s4,s3,s4
    80003d80:	0129893b          	addw	s2,s3,s2
    80003d84:	9aee                	add	s5,s5,s11
    80003d86:	057a7663          	bgeu	s4,s7,80003dd2 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d8a:	000b2483          	lw	s1,0(s6)
    80003d8e:	00a9559b          	srliw	a1,s2,0xa
    80003d92:	855a                	mv	a0,s6
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	7ae080e7          	jalr	1966(ra) # 80003542 <bmap>
    80003d9c:	0005059b          	sext.w	a1,a0
    80003da0:	8526                	mv	a0,s1
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	3ac080e7          	jalr	940(ra) # 8000314e <bread>
    80003daa:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dac:	3ff97713          	andi	a4,s2,1023
    80003db0:	40ed07bb          	subw	a5,s10,a4
    80003db4:	414b86bb          	subw	a3,s7,s4
    80003db8:	89be                	mv	s3,a5
    80003dba:	2781                	sext.w	a5,a5
    80003dbc:	0006861b          	sext.w	a2,a3
    80003dc0:	f8f674e3          	bgeu	a2,a5,80003d48 <writei+0x4c>
    80003dc4:	89b6                	mv	s3,a3
    80003dc6:	b749                	j	80003d48 <writei+0x4c>
      brelse(bp);
    80003dc8:	8526                	mv	a0,s1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	4b4080e7          	jalr	1204(ra) # 8000327e <brelse>
  }

  if(off > ip->size)
    80003dd2:	04cb2783          	lw	a5,76(s6)
    80003dd6:	0127f463          	bgeu	a5,s2,80003dde <writei+0xe2>
    ip->size = off;
    80003dda:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003dde:	855a                	mv	a0,s6
    80003de0:	00000097          	auipc	ra,0x0
    80003de4:	aa6080e7          	jalr	-1370(ra) # 80003886 <iupdate>

  return tot;
    80003de8:	000a051b          	sext.w	a0,s4
}
    80003dec:	70a6                	ld	ra,104(sp)
    80003dee:	7406                	ld	s0,96(sp)
    80003df0:	64e6                	ld	s1,88(sp)
    80003df2:	6946                	ld	s2,80(sp)
    80003df4:	69a6                	ld	s3,72(sp)
    80003df6:	6a06                	ld	s4,64(sp)
    80003df8:	7ae2                	ld	s5,56(sp)
    80003dfa:	7b42                	ld	s6,48(sp)
    80003dfc:	7ba2                	ld	s7,40(sp)
    80003dfe:	7c02                	ld	s8,32(sp)
    80003e00:	6ce2                	ld	s9,24(sp)
    80003e02:	6d42                	ld	s10,16(sp)
    80003e04:	6da2                	ld	s11,8(sp)
    80003e06:	6165                	addi	sp,sp,112
    80003e08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e0a:	8a5e                	mv	s4,s7
    80003e0c:	bfc9                	j	80003dde <writei+0xe2>
    return -1;
    80003e0e:	557d                	li	a0,-1
}
    80003e10:	8082                	ret
    return -1;
    80003e12:	557d                	li	a0,-1
    80003e14:	bfe1                	j	80003dec <writei+0xf0>
    return -1;
    80003e16:	557d                	li	a0,-1
    80003e18:	bfd1                	j	80003dec <writei+0xf0>

0000000080003e1a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e1a:	1141                	addi	sp,sp,-16
    80003e1c:	e406                	sd	ra,8(sp)
    80003e1e:	e022                	sd	s0,0(sp)
    80003e20:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e22:	4639                	li	a2,14
    80003e24:	ffffd097          	auipc	ra,0xffffd
    80003e28:	f94080e7          	jalr	-108(ra) # 80000db8 <strncmp>
}
    80003e2c:	60a2                	ld	ra,8(sp)
    80003e2e:	6402                	ld	s0,0(sp)
    80003e30:	0141                	addi	sp,sp,16
    80003e32:	8082                	ret

0000000080003e34 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e34:	7139                	addi	sp,sp,-64
    80003e36:	fc06                	sd	ra,56(sp)
    80003e38:	f822                	sd	s0,48(sp)
    80003e3a:	f426                	sd	s1,40(sp)
    80003e3c:	f04a                	sd	s2,32(sp)
    80003e3e:	ec4e                	sd	s3,24(sp)
    80003e40:	e852                	sd	s4,16(sp)
    80003e42:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e44:	04451703          	lh	a4,68(a0)
    80003e48:	4785                	li	a5,1
    80003e4a:	00f71a63          	bne	a4,a5,80003e5e <dirlookup+0x2a>
    80003e4e:	892a                	mv	s2,a0
    80003e50:	89ae                	mv	s3,a1
    80003e52:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e54:	457c                	lw	a5,76(a0)
    80003e56:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e58:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5a:	e79d                	bnez	a5,80003e88 <dirlookup+0x54>
    80003e5c:	a8a5                	j	80003ed4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e5e:	00005517          	auipc	a0,0x5
    80003e62:	86a50513          	addi	a0,a0,-1942 # 800086c8 <syscalls+0x1a8>
    80003e66:	ffffc097          	auipc	ra,0xffffc
    80003e6a:	6d8080e7          	jalr	1752(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003e6e:	00005517          	auipc	a0,0x5
    80003e72:	87250513          	addi	a0,a0,-1934 # 800086e0 <syscalls+0x1c0>
    80003e76:	ffffc097          	auipc	ra,0xffffc
    80003e7a:	6c8080e7          	jalr	1736(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7e:	24c1                	addiw	s1,s1,16
    80003e80:	04c92783          	lw	a5,76(s2)
    80003e84:	04f4f763          	bgeu	s1,a5,80003ed2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e88:	4741                	li	a4,16
    80003e8a:	86a6                	mv	a3,s1
    80003e8c:	fc040613          	addi	a2,s0,-64
    80003e90:	4581                	li	a1,0
    80003e92:	854a                	mv	a0,s2
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	d70080e7          	jalr	-656(ra) # 80003c04 <readi>
    80003e9c:	47c1                	li	a5,16
    80003e9e:	fcf518e3          	bne	a0,a5,80003e6e <dirlookup+0x3a>
    if(de.inum == 0)
    80003ea2:	fc045783          	lhu	a5,-64(s0)
    80003ea6:	dfe1                	beqz	a5,80003e7e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ea8:	fc240593          	addi	a1,s0,-62
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	f6c080e7          	jalr	-148(ra) # 80003e1a <namecmp>
    80003eb6:	f561                	bnez	a0,80003e7e <dirlookup+0x4a>
      if(poff)
    80003eb8:	000a0463          	beqz	s4,80003ec0 <dirlookup+0x8c>
        *poff = off;
    80003ebc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ec0:	fc045583          	lhu	a1,-64(s0)
    80003ec4:	00092503          	lw	a0,0(s2)
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	754080e7          	jalr	1876(ra) # 8000361c <iget>
    80003ed0:	a011                	j	80003ed4 <dirlookup+0xa0>
  return 0;
    80003ed2:	4501                	li	a0,0
}
    80003ed4:	70e2                	ld	ra,56(sp)
    80003ed6:	7442                	ld	s0,48(sp)
    80003ed8:	74a2                	ld	s1,40(sp)
    80003eda:	7902                	ld	s2,32(sp)
    80003edc:	69e2                	ld	s3,24(sp)
    80003ede:	6a42                	ld	s4,16(sp)
    80003ee0:	6121                	addi	sp,sp,64
    80003ee2:	8082                	ret

0000000080003ee4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ee4:	711d                	addi	sp,sp,-96
    80003ee6:	ec86                	sd	ra,88(sp)
    80003ee8:	e8a2                	sd	s0,80(sp)
    80003eea:	e4a6                	sd	s1,72(sp)
    80003eec:	e0ca                	sd	s2,64(sp)
    80003eee:	fc4e                	sd	s3,56(sp)
    80003ef0:	f852                	sd	s4,48(sp)
    80003ef2:	f456                	sd	s5,40(sp)
    80003ef4:	f05a                	sd	s6,32(sp)
    80003ef6:	ec5e                	sd	s7,24(sp)
    80003ef8:	e862                	sd	s8,16(sp)
    80003efa:	e466                	sd	s9,8(sp)
    80003efc:	1080                	addi	s0,sp,96
    80003efe:	84aa                	mv	s1,a0
    80003f00:	8b2e                	mv	s6,a1
    80003f02:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f04:	00054703          	lbu	a4,0(a0)
    80003f08:	02f00793          	li	a5,47
    80003f0c:	02f70363          	beq	a4,a5,80003f32 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f10:	ffffe097          	auipc	ra,0xffffe
    80003f14:	aa0080e7          	jalr	-1376(ra) # 800019b0 <myproc>
    80003f18:	15853503          	ld	a0,344(a0)
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	9f6080e7          	jalr	-1546(ra) # 80003912 <idup>
    80003f24:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f26:	02f00913          	li	s2,47
  len = path - s;
    80003f2a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f2c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f2e:	4c05                	li	s8,1
    80003f30:	a865                	j	80003fe8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f32:	4585                	li	a1,1
    80003f34:	4505                	li	a0,1
    80003f36:	fffff097          	auipc	ra,0xfffff
    80003f3a:	6e6080e7          	jalr	1766(ra) # 8000361c <iget>
    80003f3e:	89aa                	mv	s3,a0
    80003f40:	b7dd                	j	80003f26 <namex+0x42>
      iunlockput(ip);
    80003f42:	854e                	mv	a0,s3
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	c6e080e7          	jalr	-914(ra) # 80003bb2 <iunlockput>
      return 0;
    80003f4c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f4e:	854e                	mv	a0,s3
    80003f50:	60e6                	ld	ra,88(sp)
    80003f52:	6446                	ld	s0,80(sp)
    80003f54:	64a6                	ld	s1,72(sp)
    80003f56:	6906                	ld	s2,64(sp)
    80003f58:	79e2                	ld	s3,56(sp)
    80003f5a:	7a42                	ld	s4,48(sp)
    80003f5c:	7aa2                	ld	s5,40(sp)
    80003f5e:	7b02                	ld	s6,32(sp)
    80003f60:	6be2                	ld	s7,24(sp)
    80003f62:	6c42                	ld	s8,16(sp)
    80003f64:	6ca2                	ld	s9,8(sp)
    80003f66:	6125                	addi	sp,sp,96
    80003f68:	8082                	ret
      iunlock(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	aa6080e7          	jalr	-1370(ra) # 80003a12 <iunlock>
      return ip;
    80003f74:	bfe9                	j	80003f4e <namex+0x6a>
      iunlockput(ip);
    80003f76:	854e                	mv	a0,s3
    80003f78:	00000097          	auipc	ra,0x0
    80003f7c:	c3a080e7          	jalr	-966(ra) # 80003bb2 <iunlockput>
      return 0;
    80003f80:	89d2                	mv	s3,s4
    80003f82:	b7f1                	j	80003f4e <namex+0x6a>
  len = path - s;
    80003f84:	40b48633          	sub	a2,s1,a1
    80003f88:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f8c:	094cd463          	bge	s9,s4,80004014 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f90:	4639                	li	a2,14
    80003f92:	8556                	mv	a0,s5
    80003f94:	ffffd097          	auipc	ra,0xffffd
    80003f98:	dac080e7          	jalr	-596(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	01279763          	bne	a5,s2,80003fae <namex+0xca>
    path++;
    80003fa4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fa6:	0004c783          	lbu	a5,0(s1)
    80003faa:	ff278de3          	beq	a5,s2,80003fa4 <namex+0xc0>
    ilock(ip);
    80003fae:	854e                	mv	a0,s3
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	9a0080e7          	jalr	-1632(ra) # 80003950 <ilock>
    if(ip->type != T_DIR){
    80003fb8:	04499783          	lh	a5,68(s3)
    80003fbc:	f98793e3          	bne	a5,s8,80003f42 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fc0:	000b0563          	beqz	s6,80003fca <namex+0xe6>
    80003fc4:	0004c783          	lbu	a5,0(s1)
    80003fc8:	d3cd                	beqz	a5,80003f6a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fca:	865e                	mv	a2,s7
    80003fcc:	85d6                	mv	a1,s5
    80003fce:	854e                	mv	a0,s3
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	e64080e7          	jalr	-412(ra) # 80003e34 <dirlookup>
    80003fd8:	8a2a                	mv	s4,a0
    80003fda:	dd51                	beqz	a0,80003f76 <namex+0x92>
    iunlockput(ip);
    80003fdc:	854e                	mv	a0,s3
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	bd4080e7          	jalr	-1068(ra) # 80003bb2 <iunlockput>
    ip = next;
    80003fe6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fe8:	0004c783          	lbu	a5,0(s1)
    80003fec:	05279763          	bne	a5,s2,8000403a <namex+0x156>
    path++;
    80003ff0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ff2:	0004c783          	lbu	a5,0(s1)
    80003ff6:	ff278de3          	beq	a5,s2,80003ff0 <namex+0x10c>
  if(*path == 0)
    80003ffa:	c79d                	beqz	a5,80004028 <namex+0x144>
    path++;
    80003ffc:	85a6                	mv	a1,s1
  len = path - s;
    80003ffe:	8a5e                	mv	s4,s7
    80004000:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004002:	01278963          	beq	a5,s2,80004014 <namex+0x130>
    80004006:	dfbd                	beqz	a5,80003f84 <namex+0xa0>
    path++;
    80004008:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000400a:	0004c783          	lbu	a5,0(s1)
    8000400e:	ff279ce3          	bne	a5,s2,80004006 <namex+0x122>
    80004012:	bf8d                	j	80003f84 <namex+0xa0>
    memmove(name, s, len);
    80004014:	2601                	sext.w	a2,a2
    80004016:	8556                	mv	a0,s5
    80004018:	ffffd097          	auipc	ra,0xffffd
    8000401c:	d28080e7          	jalr	-728(ra) # 80000d40 <memmove>
    name[len] = 0;
    80004020:	9a56                	add	s4,s4,s5
    80004022:	000a0023          	sb	zero,0(s4)
    80004026:	bf9d                	j	80003f9c <namex+0xb8>
  if(nameiparent){
    80004028:	f20b03e3          	beqz	s6,80003f4e <namex+0x6a>
    iput(ip);
    8000402c:	854e                	mv	a0,s3
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	adc080e7          	jalr	-1316(ra) # 80003b0a <iput>
    return 0;
    80004036:	4981                	li	s3,0
    80004038:	bf19                	j	80003f4e <namex+0x6a>
  if(*path == 0)
    8000403a:	d7fd                	beqz	a5,80004028 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000403c:	0004c783          	lbu	a5,0(s1)
    80004040:	85a6                	mv	a1,s1
    80004042:	b7d1                	j	80004006 <namex+0x122>

0000000080004044 <dirlink>:
{
    80004044:	7139                	addi	sp,sp,-64
    80004046:	fc06                	sd	ra,56(sp)
    80004048:	f822                	sd	s0,48(sp)
    8000404a:	f426                	sd	s1,40(sp)
    8000404c:	f04a                	sd	s2,32(sp)
    8000404e:	ec4e                	sd	s3,24(sp)
    80004050:	e852                	sd	s4,16(sp)
    80004052:	0080                	addi	s0,sp,64
    80004054:	892a                	mv	s2,a0
    80004056:	8a2e                	mv	s4,a1
    80004058:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000405a:	4601                	li	a2,0
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	dd8080e7          	jalr	-552(ra) # 80003e34 <dirlookup>
    80004064:	e93d                	bnez	a0,800040da <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004066:	04c92483          	lw	s1,76(s2)
    8000406a:	c49d                	beqz	s1,80004098 <dirlink+0x54>
    8000406c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000406e:	4741                	li	a4,16
    80004070:	86a6                	mv	a3,s1
    80004072:	fc040613          	addi	a2,s0,-64
    80004076:	4581                	li	a1,0
    80004078:	854a                	mv	a0,s2
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	b8a080e7          	jalr	-1142(ra) # 80003c04 <readi>
    80004082:	47c1                	li	a5,16
    80004084:	06f51163          	bne	a0,a5,800040e6 <dirlink+0xa2>
    if(de.inum == 0)
    80004088:	fc045783          	lhu	a5,-64(s0)
    8000408c:	c791                	beqz	a5,80004098 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408e:	24c1                	addiw	s1,s1,16
    80004090:	04c92783          	lw	a5,76(s2)
    80004094:	fcf4ede3          	bltu	s1,a5,8000406e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004098:	4639                	li	a2,14
    8000409a:	85d2                	mv	a1,s4
    8000409c:	fc240513          	addi	a0,s0,-62
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	d54080e7          	jalr	-684(ra) # 80000df4 <strncpy>
  de.inum = inum;
    800040a8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ac:	4741                	li	a4,16
    800040ae:	86a6                	mv	a3,s1
    800040b0:	fc040613          	addi	a2,s0,-64
    800040b4:	4581                	li	a1,0
    800040b6:	854a                	mv	a0,s2
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	c44080e7          	jalr	-956(ra) # 80003cfc <writei>
    800040c0:	872a                	mv	a4,a0
    800040c2:	47c1                	li	a5,16
  return 0;
    800040c4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c6:	02f71863          	bne	a4,a5,800040f6 <dirlink+0xb2>
}
    800040ca:	70e2                	ld	ra,56(sp)
    800040cc:	7442                	ld	s0,48(sp)
    800040ce:	74a2                	ld	s1,40(sp)
    800040d0:	7902                	ld	s2,32(sp)
    800040d2:	69e2                	ld	s3,24(sp)
    800040d4:	6a42                	ld	s4,16(sp)
    800040d6:	6121                	addi	sp,sp,64
    800040d8:	8082                	ret
    iput(ip);
    800040da:	00000097          	auipc	ra,0x0
    800040de:	a30080e7          	jalr	-1488(ra) # 80003b0a <iput>
    return -1;
    800040e2:	557d                	li	a0,-1
    800040e4:	b7dd                	j	800040ca <dirlink+0x86>
      panic("dirlink read");
    800040e6:	00004517          	auipc	a0,0x4
    800040ea:	60a50513          	addi	a0,a0,1546 # 800086f0 <syscalls+0x1d0>
    800040ee:	ffffc097          	auipc	ra,0xffffc
    800040f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
    panic("dirlink");
    800040f6:	00004517          	auipc	a0,0x4
    800040fa:	70a50513          	addi	a0,a0,1802 # 80008800 <syscalls+0x2e0>
    800040fe:	ffffc097          	auipc	ra,0xffffc
    80004102:	440080e7          	jalr	1088(ra) # 8000053e <panic>

0000000080004106 <namei>:

struct inode*
namei(char *path)
{
    80004106:	1101                	addi	sp,sp,-32
    80004108:	ec06                	sd	ra,24(sp)
    8000410a:	e822                	sd	s0,16(sp)
    8000410c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000410e:	fe040613          	addi	a2,s0,-32
    80004112:	4581                	li	a1,0
    80004114:	00000097          	auipc	ra,0x0
    80004118:	dd0080e7          	jalr	-560(ra) # 80003ee4 <namex>
}
    8000411c:	60e2                	ld	ra,24(sp)
    8000411e:	6442                	ld	s0,16(sp)
    80004120:	6105                	addi	sp,sp,32
    80004122:	8082                	ret

0000000080004124 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004124:	1141                	addi	sp,sp,-16
    80004126:	e406                	sd	ra,8(sp)
    80004128:	e022                	sd	s0,0(sp)
    8000412a:	0800                	addi	s0,sp,16
    8000412c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000412e:	4585                	li	a1,1
    80004130:	00000097          	auipc	ra,0x0
    80004134:	db4080e7          	jalr	-588(ra) # 80003ee4 <namex>
}
    80004138:	60a2                	ld	ra,8(sp)
    8000413a:	6402                	ld	s0,0(sp)
    8000413c:	0141                	addi	sp,sp,16
    8000413e:	8082                	ret

0000000080004140 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004140:	1101                	addi	sp,sp,-32
    80004142:	ec06                	sd	ra,24(sp)
    80004144:	e822                	sd	s0,16(sp)
    80004146:	e426                	sd	s1,8(sp)
    80004148:	e04a                	sd	s2,0(sp)
    8000414a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000414c:	0001d917          	auipc	s2,0x1d
    80004150:	32490913          	addi	s2,s2,804 # 80021470 <log>
    80004154:	01892583          	lw	a1,24(s2)
    80004158:	02892503          	lw	a0,40(s2)
    8000415c:	fffff097          	auipc	ra,0xfffff
    80004160:	ff2080e7          	jalr	-14(ra) # 8000314e <bread>
    80004164:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004166:	02c92683          	lw	a3,44(s2)
    8000416a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000416c:	02d05763          	blez	a3,8000419a <write_head+0x5a>
    80004170:	0001d797          	auipc	a5,0x1d
    80004174:	33078793          	addi	a5,a5,816 # 800214a0 <log+0x30>
    80004178:	05c50713          	addi	a4,a0,92
    8000417c:	36fd                	addiw	a3,a3,-1
    8000417e:	1682                	slli	a3,a3,0x20
    80004180:	9281                	srli	a3,a3,0x20
    80004182:	068a                	slli	a3,a3,0x2
    80004184:	0001d617          	auipc	a2,0x1d
    80004188:	32060613          	addi	a2,a2,800 # 800214a4 <log+0x34>
    8000418c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000418e:	4390                	lw	a2,0(a5)
    80004190:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004192:	0791                	addi	a5,a5,4
    80004194:	0711                	addi	a4,a4,4
    80004196:	fed79ce3          	bne	a5,a3,8000418e <write_head+0x4e>
  }
  bwrite(buf);
    8000419a:	8526                	mv	a0,s1
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	0a4080e7          	jalr	164(ra) # 80003240 <bwrite>
  brelse(buf);
    800041a4:	8526                	mv	a0,s1
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	0d8080e7          	jalr	216(ra) # 8000327e <brelse>
}
    800041ae:	60e2                	ld	ra,24(sp)
    800041b0:	6442                	ld	s0,16(sp)
    800041b2:	64a2                	ld	s1,8(sp)
    800041b4:	6902                	ld	s2,0(sp)
    800041b6:	6105                	addi	sp,sp,32
    800041b8:	8082                	ret

00000000800041ba <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ba:	0001d797          	auipc	a5,0x1d
    800041be:	2e27a783          	lw	a5,738(a5) # 8002149c <log+0x2c>
    800041c2:	0af05d63          	blez	a5,8000427c <install_trans+0xc2>
{
    800041c6:	7139                	addi	sp,sp,-64
    800041c8:	fc06                	sd	ra,56(sp)
    800041ca:	f822                	sd	s0,48(sp)
    800041cc:	f426                	sd	s1,40(sp)
    800041ce:	f04a                	sd	s2,32(sp)
    800041d0:	ec4e                	sd	s3,24(sp)
    800041d2:	e852                	sd	s4,16(sp)
    800041d4:	e456                	sd	s5,8(sp)
    800041d6:	e05a                	sd	s6,0(sp)
    800041d8:	0080                	addi	s0,sp,64
    800041da:	8b2a                	mv	s6,a0
    800041dc:	0001da97          	auipc	s5,0x1d
    800041e0:	2c4a8a93          	addi	s5,s5,708 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041e6:	0001d997          	auipc	s3,0x1d
    800041ea:	28a98993          	addi	s3,s3,650 # 80021470 <log>
    800041ee:	a035                	j	8000421a <install_trans+0x60>
      bunpin(dbuf);
    800041f0:	8526                	mv	a0,s1
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	166080e7          	jalr	358(ra) # 80003358 <bunpin>
    brelse(lbuf);
    800041fa:	854a                	mv	a0,s2
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	082080e7          	jalr	130(ra) # 8000327e <brelse>
    brelse(dbuf);
    80004204:	8526                	mv	a0,s1
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	078080e7          	jalr	120(ra) # 8000327e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420e:	2a05                	addiw	s4,s4,1
    80004210:	0a91                	addi	s5,s5,4
    80004212:	02c9a783          	lw	a5,44(s3)
    80004216:	04fa5963          	bge	s4,a5,80004268 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000421a:	0189a583          	lw	a1,24(s3)
    8000421e:	014585bb          	addw	a1,a1,s4
    80004222:	2585                	addiw	a1,a1,1
    80004224:	0289a503          	lw	a0,40(s3)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	f26080e7          	jalr	-218(ra) # 8000314e <bread>
    80004230:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004232:	000aa583          	lw	a1,0(s5)
    80004236:	0289a503          	lw	a0,40(s3)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	f14080e7          	jalr	-236(ra) # 8000314e <bread>
    80004242:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004244:	40000613          	li	a2,1024
    80004248:	05890593          	addi	a1,s2,88
    8000424c:	05850513          	addi	a0,a0,88
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	af0080e7          	jalr	-1296(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	fe6080e7          	jalr	-26(ra) # 80003240 <bwrite>
    if(recovering == 0)
    80004262:	f80b1ce3          	bnez	s6,800041fa <install_trans+0x40>
    80004266:	b769                	j	800041f0 <install_trans+0x36>
}
    80004268:	70e2                	ld	ra,56(sp)
    8000426a:	7442                	ld	s0,48(sp)
    8000426c:	74a2                	ld	s1,40(sp)
    8000426e:	7902                	ld	s2,32(sp)
    80004270:	69e2                	ld	s3,24(sp)
    80004272:	6a42                	ld	s4,16(sp)
    80004274:	6aa2                	ld	s5,8(sp)
    80004276:	6b02                	ld	s6,0(sp)
    80004278:	6121                	addi	sp,sp,64
    8000427a:	8082                	ret
    8000427c:	8082                	ret

000000008000427e <initlog>:
{
    8000427e:	7179                	addi	sp,sp,-48
    80004280:	f406                	sd	ra,40(sp)
    80004282:	f022                	sd	s0,32(sp)
    80004284:	ec26                	sd	s1,24(sp)
    80004286:	e84a                	sd	s2,16(sp)
    80004288:	e44e                	sd	s3,8(sp)
    8000428a:	1800                	addi	s0,sp,48
    8000428c:	892a                	mv	s2,a0
    8000428e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	1e048493          	addi	s1,s1,480 # 80021470 <log>
    80004298:	00004597          	auipc	a1,0x4
    8000429c:	46858593          	addi	a1,a1,1128 # 80008700 <syscalls+0x1e0>
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	8b2080e7          	jalr	-1870(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800042aa:	0149a583          	lw	a1,20(s3)
    800042ae:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042b0:	0109a783          	lw	a5,16(s3)
    800042b4:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042b6:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ba:	854a                	mv	a0,s2
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	e92080e7          	jalr	-366(ra) # 8000314e <bread>
  log.lh.n = lh->n;
    800042c4:	4d3c                	lw	a5,88(a0)
    800042c6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042c8:	02f05563          	blez	a5,800042f2 <initlog+0x74>
    800042cc:	05c50713          	addi	a4,a0,92
    800042d0:	0001d697          	auipc	a3,0x1d
    800042d4:	1d068693          	addi	a3,a3,464 # 800214a0 <log+0x30>
    800042d8:	37fd                	addiw	a5,a5,-1
    800042da:	1782                	slli	a5,a5,0x20
    800042dc:	9381                	srli	a5,a5,0x20
    800042de:	078a                	slli	a5,a5,0x2
    800042e0:	06050613          	addi	a2,a0,96
    800042e4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042e6:	4310                	lw	a2,0(a4)
    800042e8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042ea:	0711                	addi	a4,a4,4
    800042ec:	0691                	addi	a3,a3,4
    800042ee:	fef71ce3          	bne	a4,a5,800042e6 <initlog+0x68>
  brelse(buf);
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	f8c080e7          	jalr	-116(ra) # 8000327e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042fa:	4505                	li	a0,1
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	ebe080e7          	jalr	-322(ra) # 800041ba <install_trans>
  log.lh.n = 0;
    80004304:	0001d797          	auipc	a5,0x1d
    80004308:	1807ac23          	sw	zero,408(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	e34080e7          	jalr	-460(ra) # 80004140 <write_head>
}
    80004314:	70a2                	ld	ra,40(sp)
    80004316:	7402                	ld	s0,32(sp)
    80004318:	64e2                	ld	s1,24(sp)
    8000431a:	6942                	ld	s2,16(sp)
    8000431c:	69a2                	ld	s3,8(sp)
    8000431e:	6145                	addi	sp,sp,48
    80004320:	8082                	ret

0000000080004322 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004322:	1101                	addi	sp,sp,-32
    80004324:	ec06                	sd	ra,24(sp)
    80004326:	e822                	sd	s0,16(sp)
    80004328:	e426                	sd	s1,8(sp)
    8000432a:	e04a                	sd	s2,0(sp)
    8000432c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000432e:	0001d517          	auipc	a0,0x1d
    80004332:	14250513          	addi	a0,a0,322 # 80021470 <log>
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	8ae080e7          	jalr	-1874(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    8000433e:	0001d497          	auipc	s1,0x1d
    80004342:	13248493          	addi	s1,s1,306 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004346:	4979                	li	s2,30
    80004348:	a039                	j	80004356 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000434a:	85a6                	mv	a1,s1
    8000434c:	8526                	mv	a0,s1
    8000434e:	ffffe097          	auipc	ra,0xffffe
    80004352:	d6c080e7          	jalr	-660(ra) # 800020ba <sleep>
    if(log.committing){
    80004356:	50dc                	lw	a5,36(s1)
    80004358:	fbed                	bnez	a5,8000434a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435a:	509c                	lw	a5,32(s1)
    8000435c:	0017871b          	addiw	a4,a5,1
    80004360:	0007069b          	sext.w	a3,a4
    80004364:	0027179b          	slliw	a5,a4,0x2
    80004368:	9fb9                	addw	a5,a5,a4
    8000436a:	0017979b          	slliw	a5,a5,0x1
    8000436e:	54d8                	lw	a4,44(s1)
    80004370:	9fb9                	addw	a5,a5,a4
    80004372:	00f95963          	bge	s2,a5,80004384 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004376:	85a6                	mv	a1,s1
    80004378:	8526                	mv	a0,s1
    8000437a:	ffffe097          	auipc	ra,0xffffe
    8000437e:	d40080e7          	jalr	-704(ra) # 800020ba <sleep>
    80004382:	bfd1                	j	80004356 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004384:	0001d517          	auipc	a0,0x1d
    80004388:	0ec50513          	addi	a0,a0,236 # 80021470 <log>
    8000438c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	90a080e7          	jalr	-1782(ra) # 80000c98 <release>
      break;
    }
  }
}
    80004396:	60e2                	ld	ra,24(sp)
    80004398:	6442                	ld	s0,16(sp)
    8000439a:	64a2                	ld	s1,8(sp)
    8000439c:	6902                	ld	s2,0(sp)
    8000439e:	6105                	addi	sp,sp,32
    800043a0:	8082                	ret

00000000800043a2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043a2:	7139                	addi	sp,sp,-64
    800043a4:	fc06                	sd	ra,56(sp)
    800043a6:	f822                	sd	s0,48(sp)
    800043a8:	f426                	sd	s1,40(sp)
    800043aa:	f04a                	sd	s2,32(sp)
    800043ac:	ec4e                	sd	s3,24(sp)
    800043ae:	e852                	sd	s4,16(sp)
    800043b0:	e456                	sd	s5,8(sp)
    800043b2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043b4:	0001d497          	auipc	s1,0x1d
    800043b8:	0bc48493          	addi	s1,s1,188 # 80021470 <log>
    800043bc:	8526                	mv	a0,s1
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	826080e7          	jalr	-2010(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    800043c6:	509c                	lw	a5,32(s1)
    800043c8:	37fd                	addiw	a5,a5,-1
    800043ca:	0007891b          	sext.w	s2,a5
    800043ce:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043d0:	50dc                	lw	a5,36(s1)
    800043d2:	efb9                	bnez	a5,80004430 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043d4:	06091663          	bnez	s2,80004440 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043d8:	0001d497          	auipc	s1,0x1d
    800043dc:	09848493          	addi	s1,s1,152 # 80021470 <log>
    800043e0:	4785                	li	a5,1
    800043e2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8b2080e7          	jalr	-1870(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043ee:	54dc                	lw	a5,44(s1)
    800043f0:	06f04763          	bgtz	a5,8000445e <end_op+0xbc>
    acquire(&log.lock);
    800043f4:	0001d497          	auipc	s1,0x1d
    800043f8:	07c48493          	addi	s1,s1,124 # 80021470 <log>
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	7e6080e7          	jalr	2022(ra) # 80000be4 <acquire>
    log.committing = 0;
    80004406:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000440a:	8526                	mv	a0,s1
    8000440c:	ffffe097          	auipc	ra,0xffffe
    80004410:	e3a080e7          	jalr	-454(ra) # 80002246 <wakeup>
    release(&log.lock);
    80004414:	8526                	mv	a0,s1
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	882080e7          	jalr	-1918(ra) # 80000c98 <release>
}
    8000441e:	70e2                	ld	ra,56(sp)
    80004420:	7442                	ld	s0,48(sp)
    80004422:	74a2                	ld	s1,40(sp)
    80004424:	7902                	ld	s2,32(sp)
    80004426:	69e2                	ld	s3,24(sp)
    80004428:	6a42                	ld	s4,16(sp)
    8000442a:	6aa2                	ld	s5,8(sp)
    8000442c:	6121                	addi	sp,sp,64
    8000442e:	8082                	ret
    panic("log.committing");
    80004430:	00004517          	auipc	a0,0x4
    80004434:	2d850513          	addi	a0,a0,728 # 80008708 <syscalls+0x1e8>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	106080e7          	jalr	262(ra) # 8000053e <panic>
    wakeup(&log);
    80004440:	0001d497          	auipc	s1,0x1d
    80004444:	03048493          	addi	s1,s1,48 # 80021470 <log>
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffe097          	auipc	ra,0xffffe
    8000444e:	dfc080e7          	jalr	-516(ra) # 80002246 <wakeup>
  release(&log.lock);
    80004452:	8526                	mv	a0,s1
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	844080e7          	jalr	-1980(ra) # 80000c98 <release>
  if(do_commit){
    8000445c:	b7c9                	j	8000441e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000445e:	0001da97          	auipc	s5,0x1d
    80004462:	042a8a93          	addi	s5,s5,66 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004466:	0001da17          	auipc	s4,0x1d
    8000446a:	00aa0a13          	addi	s4,s4,10 # 80021470 <log>
    8000446e:	018a2583          	lw	a1,24(s4)
    80004472:	012585bb          	addw	a1,a1,s2
    80004476:	2585                	addiw	a1,a1,1
    80004478:	028a2503          	lw	a0,40(s4)
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	cd2080e7          	jalr	-814(ra) # 8000314e <bread>
    80004484:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004486:	000aa583          	lw	a1,0(s5)
    8000448a:	028a2503          	lw	a0,40(s4)
    8000448e:	fffff097          	auipc	ra,0xfffff
    80004492:	cc0080e7          	jalr	-832(ra) # 8000314e <bread>
    80004496:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004498:	40000613          	li	a2,1024
    8000449c:	05850593          	addi	a1,a0,88
    800044a0:	05848513          	addi	a0,s1,88
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	89c080e7          	jalr	-1892(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800044ac:	8526                	mv	a0,s1
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	d92080e7          	jalr	-622(ra) # 80003240 <bwrite>
    brelse(from);
    800044b6:	854e                	mv	a0,s3
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	dc6080e7          	jalr	-570(ra) # 8000327e <brelse>
    brelse(to);
    800044c0:	8526                	mv	a0,s1
    800044c2:	fffff097          	auipc	ra,0xfffff
    800044c6:	dbc080e7          	jalr	-580(ra) # 8000327e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ca:	2905                	addiw	s2,s2,1
    800044cc:	0a91                	addi	s5,s5,4
    800044ce:	02ca2783          	lw	a5,44(s4)
    800044d2:	f8f94ee3          	blt	s2,a5,8000446e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044d6:	00000097          	auipc	ra,0x0
    800044da:	c6a080e7          	jalr	-918(ra) # 80004140 <write_head>
    install_trans(0); // Now install writes to home locations
    800044de:	4501                	li	a0,0
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	cda080e7          	jalr	-806(ra) # 800041ba <install_trans>
    log.lh.n = 0;
    800044e8:	0001d797          	auipc	a5,0x1d
    800044ec:	fa07aa23          	sw	zero,-76(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	c50080e7          	jalr	-944(ra) # 80004140 <write_head>
    800044f8:	bdf5                	j	800043f4 <end_op+0x52>

00000000800044fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044fa:	1101                	addi	sp,sp,-32
    800044fc:	ec06                	sd	ra,24(sp)
    800044fe:	e822                	sd	s0,16(sp)
    80004500:	e426                	sd	s1,8(sp)
    80004502:	e04a                	sd	s2,0(sp)
    80004504:	1000                	addi	s0,sp,32
    80004506:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004508:	0001d917          	auipc	s2,0x1d
    8000450c:	f6890913          	addi	s2,s2,-152 # 80021470 <log>
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6d2080e7          	jalr	1746(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000451a:	02c92603          	lw	a2,44(s2)
    8000451e:	47f5                	li	a5,29
    80004520:	06c7c563          	blt	a5,a2,8000458a <log_write+0x90>
    80004524:	0001d797          	auipc	a5,0x1d
    80004528:	f687a783          	lw	a5,-152(a5) # 8002148c <log+0x1c>
    8000452c:	37fd                	addiw	a5,a5,-1
    8000452e:	04f65e63          	bge	a2,a5,8000458a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004532:	0001d797          	auipc	a5,0x1d
    80004536:	f5e7a783          	lw	a5,-162(a5) # 80021490 <log+0x20>
    8000453a:	06f05063          	blez	a5,8000459a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000453e:	4781                	li	a5,0
    80004540:	06c05563          	blez	a2,800045aa <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004544:	44cc                	lw	a1,12(s1)
    80004546:	0001d717          	auipc	a4,0x1d
    8000454a:	f5a70713          	addi	a4,a4,-166 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000454e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004550:	4314                	lw	a3,0(a4)
    80004552:	04b68c63          	beq	a3,a1,800045aa <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004556:	2785                	addiw	a5,a5,1
    80004558:	0711                	addi	a4,a4,4
    8000455a:	fef61be3          	bne	a2,a5,80004550 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000455e:	0621                	addi	a2,a2,8
    80004560:	060a                	slli	a2,a2,0x2
    80004562:	0001d797          	auipc	a5,0x1d
    80004566:	f0e78793          	addi	a5,a5,-242 # 80021470 <log>
    8000456a:	963e                	add	a2,a2,a5
    8000456c:	44dc                	lw	a5,12(s1)
    8000456e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004570:	8526                	mv	a0,s1
    80004572:	fffff097          	auipc	ra,0xfffff
    80004576:	daa080e7          	jalr	-598(ra) # 8000331c <bpin>
    log.lh.n++;
    8000457a:	0001d717          	auipc	a4,0x1d
    8000457e:	ef670713          	addi	a4,a4,-266 # 80021470 <log>
    80004582:	575c                	lw	a5,44(a4)
    80004584:	2785                	addiw	a5,a5,1
    80004586:	d75c                	sw	a5,44(a4)
    80004588:	a835                	j	800045c4 <log_write+0xca>
    panic("too big a transaction");
    8000458a:	00004517          	auipc	a0,0x4
    8000458e:	18e50513          	addi	a0,a0,398 # 80008718 <syscalls+0x1f8>
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	fac080e7          	jalr	-84(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000459a:	00004517          	auipc	a0,0x4
    8000459e:	19650513          	addi	a0,a0,406 # 80008730 <syscalls+0x210>
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	f9c080e7          	jalr	-100(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800045aa:	00878713          	addi	a4,a5,8
    800045ae:	00271693          	slli	a3,a4,0x2
    800045b2:	0001d717          	auipc	a4,0x1d
    800045b6:	ebe70713          	addi	a4,a4,-322 # 80021470 <log>
    800045ba:	9736                	add	a4,a4,a3
    800045bc:	44d4                	lw	a3,12(s1)
    800045be:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045c0:	faf608e3          	beq	a2,a5,80004570 <log_write+0x76>
  }
  release(&log.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	eac50513          	addi	a0,a0,-340 # 80021470 <log>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
}
    800045d4:	60e2                	ld	ra,24(sp)
    800045d6:	6442                	ld	s0,16(sp)
    800045d8:	64a2                	ld	s1,8(sp)
    800045da:	6902                	ld	s2,0(sp)
    800045dc:	6105                	addi	sp,sp,32
    800045de:	8082                	ret

00000000800045e0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045e0:	1101                	addi	sp,sp,-32
    800045e2:	ec06                	sd	ra,24(sp)
    800045e4:	e822                	sd	s0,16(sp)
    800045e6:	e426                	sd	s1,8(sp)
    800045e8:	e04a                	sd	s2,0(sp)
    800045ea:	1000                	addi	s0,sp,32
    800045ec:	84aa                	mv	s1,a0
    800045ee:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045f0:	00004597          	auipc	a1,0x4
    800045f4:	16058593          	addi	a1,a1,352 # 80008750 <syscalls+0x230>
    800045f8:	0521                	addi	a0,a0,8
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	55a080e7          	jalr	1370(ra) # 80000b54 <initlock>
  lk->name = name;
    80004602:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004606:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000460a:	0204a423          	sw	zero,40(s1)
}
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6902                	ld	s2,0(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000461a:	1101                	addi	sp,sp,-32
    8000461c:	ec06                	sd	ra,24(sp)
    8000461e:	e822                	sd	s0,16(sp)
    80004620:	e426                	sd	s1,8(sp)
    80004622:	e04a                	sd	s2,0(sp)
    80004624:	1000                	addi	s0,sp,32
    80004626:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004628:	00850913          	addi	s2,a0,8
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	5b6080e7          	jalr	1462(ra) # 80000be4 <acquire>
  while (lk->locked) {
    80004636:	409c                	lw	a5,0(s1)
    80004638:	cb89                	beqz	a5,8000464a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000463a:	85ca                	mv	a1,s2
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffe097          	auipc	ra,0xffffe
    80004642:	a7c080e7          	jalr	-1412(ra) # 800020ba <sleep>
  while (lk->locked) {
    80004646:	409c                	lw	a5,0(s1)
    80004648:	fbed                	bnez	a5,8000463a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000464a:	4785                	li	a5,1
    8000464c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000464e:	ffffd097          	auipc	ra,0xffffd
    80004652:	362080e7          	jalr	866(ra) # 800019b0 <myproc>
    80004656:	591c                	lw	a5,48(a0)
    80004658:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000465a:	854a                	mv	a0,s2
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	63c080e7          	jalr	1596(ra) # 80000c98 <release>
}
    80004664:	60e2                	ld	ra,24(sp)
    80004666:	6442                	ld	s0,16(sp)
    80004668:	64a2                	ld	s1,8(sp)
    8000466a:	6902                	ld	s2,0(sp)
    8000466c:	6105                	addi	sp,sp,32
    8000466e:	8082                	ret

0000000080004670 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	e04a                	sd	s2,0(sp)
    8000467a:	1000                	addi	s0,sp,32
    8000467c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000467e:	00850913          	addi	s2,a0,8
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	560080e7          	jalr	1376(ra) # 80000be4 <acquire>
  lk->locked = 0;
    8000468c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004690:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004694:	8526                	mv	a0,s1
    80004696:	ffffe097          	auipc	ra,0xffffe
    8000469a:	bb0080e7          	jalr	-1104(ra) # 80002246 <wakeup>
  release(&lk->lk);
    8000469e:	854a                	mv	a0,s2
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	5f8080e7          	jalr	1528(ra) # 80000c98 <release>
}
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6902                	ld	s2,0(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046b4:	7179                	addi	sp,sp,-48
    800046b6:	f406                	sd	ra,40(sp)
    800046b8:	f022                	sd	s0,32(sp)
    800046ba:	ec26                	sd	s1,24(sp)
    800046bc:	e84a                	sd	s2,16(sp)
    800046be:	e44e                	sd	s3,8(sp)
    800046c0:	1800                	addi	s0,sp,48
    800046c2:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046c4:	00850913          	addi	s2,a0,8
    800046c8:	854a                	mv	a0,s2
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	51a080e7          	jalr	1306(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046d2:	409c                	lw	a5,0(s1)
    800046d4:	ef99                	bnez	a5,800046f2 <holdingsleep+0x3e>
    800046d6:	4481                	li	s1,0
  release(&lk->lk);
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
  return r;
}
    800046e2:	8526                	mv	a0,s1
    800046e4:	70a2                	ld	ra,40(sp)
    800046e6:	7402                	ld	s0,32(sp)
    800046e8:	64e2                	ld	s1,24(sp)
    800046ea:	6942                	ld	s2,16(sp)
    800046ec:	69a2                	ld	s3,8(sp)
    800046ee:	6145                	addi	sp,sp,48
    800046f0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f2:	0284a983          	lw	s3,40(s1)
    800046f6:	ffffd097          	auipc	ra,0xffffd
    800046fa:	2ba080e7          	jalr	698(ra) # 800019b0 <myproc>
    800046fe:	5904                	lw	s1,48(a0)
    80004700:	413484b3          	sub	s1,s1,s3
    80004704:	0014b493          	seqz	s1,s1
    80004708:	bfc1                	j	800046d8 <holdingsleep+0x24>

000000008000470a <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000470a:	1141                	addi	sp,sp,-16
    8000470c:	e406                	sd	ra,8(sp)
    8000470e:	e022                	sd	s0,0(sp)
    80004710:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004712:	00004597          	auipc	a1,0x4
    80004716:	04e58593          	addi	a1,a1,78 # 80008760 <syscalls+0x240>
    8000471a:	0001d517          	auipc	a0,0x1d
    8000471e:	e9e50513          	addi	a0,a0,-354 # 800215b8 <ftable>
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	432080e7          	jalr	1074(ra) # 80000b54 <initlock>
}
    8000472a:	60a2                	ld	ra,8(sp)
    8000472c:	6402                	ld	s0,0(sp)
    8000472e:	0141                	addi	sp,sp,16
    80004730:	8082                	ret

0000000080004732 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004732:	1101                	addi	sp,sp,-32
    80004734:	ec06                	sd	ra,24(sp)
    80004736:	e822                	sd	s0,16(sp)
    80004738:	e426                	sd	s1,8(sp)
    8000473a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000473c:	0001d517          	auipc	a0,0x1d
    80004740:	e7c50513          	addi	a0,a0,-388 # 800215b8 <ftable>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	4a0080e7          	jalr	1184(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000474c:	0001d497          	auipc	s1,0x1d
    80004750:	e8448493          	addi	s1,s1,-380 # 800215d0 <ftable+0x18>
    80004754:	0001e717          	auipc	a4,0x1e
    80004758:	e1c70713          	addi	a4,a4,-484 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    8000475c:	40dc                	lw	a5,4(s1)
    8000475e:	cf99                	beqz	a5,8000477c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004760:	02848493          	addi	s1,s1,40
    80004764:	fee49ce3          	bne	s1,a4,8000475c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004768:	0001d517          	auipc	a0,0x1d
    8000476c:	e5050513          	addi	a0,a0,-432 # 800215b8 <ftable>
    80004770:	ffffc097          	auipc	ra,0xffffc
    80004774:	528080e7          	jalr	1320(ra) # 80000c98 <release>
  return 0;
    80004778:	4481                	li	s1,0
    8000477a:	a819                	j	80004790 <filealloc+0x5e>
      f->ref = 1;
    8000477c:	4785                	li	a5,1
    8000477e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004780:	0001d517          	auipc	a0,0x1d
    80004784:	e3850513          	addi	a0,a0,-456 # 800215b8 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	510080e7          	jalr	1296(ra) # 80000c98 <release>
}
    80004790:	8526                	mv	a0,s1
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	64a2                	ld	s1,8(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret

000000008000479c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000479c:	1101                	addi	sp,sp,-32
    8000479e:	ec06                	sd	ra,24(sp)
    800047a0:	e822                	sd	s0,16(sp)
    800047a2:	e426                	sd	s1,8(sp)
    800047a4:	1000                	addi	s0,sp,32
    800047a6:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047a8:	0001d517          	auipc	a0,0x1d
    800047ac:	e1050513          	addi	a0,a0,-496 # 800215b8 <ftable>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	434080e7          	jalr	1076(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800047b8:	40dc                	lw	a5,4(s1)
    800047ba:	02f05263          	blez	a5,800047de <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047be:	2785                	addiw	a5,a5,1
    800047c0:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	df650513          	addi	a0,a0,-522 # 800215b8 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	4ce080e7          	jalr	1230(ra) # 80000c98 <release>
  return f;
}
    800047d2:	8526                	mv	a0,s1
    800047d4:	60e2                	ld	ra,24(sp)
    800047d6:	6442                	ld	s0,16(sp)
    800047d8:	64a2                	ld	s1,8(sp)
    800047da:	6105                	addi	sp,sp,32
    800047dc:	8082                	ret
    panic("filedup");
    800047de:	00004517          	auipc	a0,0x4
    800047e2:	f8a50513          	addi	a0,a0,-118 # 80008768 <syscalls+0x248>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d58080e7          	jalr	-680(ra) # 8000053e <panic>

00000000800047ee <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047ee:	7139                	addi	sp,sp,-64
    800047f0:	fc06                	sd	ra,56(sp)
    800047f2:	f822                	sd	s0,48(sp)
    800047f4:	f426                	sd	s1,40(sp)
    800047f6:	f04a                	sd	s2,32(sp)
    800047f8:	ec4e                	sd	s3,24(sp)
    800047fa:	e852                	sd	s4,16(sp)
    800047fc:	e456                	sd	s5,8(sp)
    800047fe:	0080                	addi	s0,sp,64
    80004800:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004802:	0001d517          	auipc	a0,0x1d
    80004806:	db650513          	addi	a0,a0,-586 # 800215b8 <ftable>
    8000480a:	ffffc097          	auipc	ra,0xffffc
    8000480e:	3da080e7          	jalr	986(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004812:	40dc                	lw	a5,4(s1)
    80004814:	06f05163          	blez	a5,80004876 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004818:	37fd                	addiw	a5,a5,-1
    8000481a:	0007871b          	sext.w	a4,a5
    8000481e:	c0dc                	sw	a5,4(s1)
    80004820:	06e04363          	bgtz	a4,80004886 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004824:	0004a903          	lw	s2,0(s1)
    80004828:	0094ca83          	lbu	s5,9(s1)
    8000482c:	0104ba03          	ld	s4,16(s1)
    80004830:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004834:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004838:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000483c:	0001d517          	auipc	a0,0x1d
    80004840:	d7c50513          	addi	a0,a0,-644 # 800215b8 <ftable>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	454080e7          	jalr	1108(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    8000484c:	4785                	li	a5,1
    8000484e:	04f90d63          	beq	s2,a5,800048a8 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004852:	3979                	addiw	s2,s2,-2
    80004854:	4785                	li	a5,1
    80004856:	0527e063          	bltu	a5,s2,80004896 <fileclose+0xa8>
    begin_op();
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	ac8080e7          	jalr	-1336(ra) # 80004322 <begin_op>
    iput(ff.ip);
    80004862:	854e                	mv	a0,s3
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	2a6080e7          	jalr	678(ra) # 80003b0a <iput>
    end_op();
    8000486c:	00000097          	auipc	ra,0x0
    80004870:	b36080e7          	jalr	-1226(ra) # 800043a2 <end_op>
    80004874:	a00d                	j	80004896 <fileclose+0xa8>
    panic("fileclose");
    80004876:	00004517          	auipc	a0,0x4
    8000487a:	efa50513          	addi	a0,a0,-262 # 80008770 <syscalls+0x250>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	cc0080e7          	jalr	-832(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004886:	0001d517          	auipc	a0,0x1d
    8000488a:	d3250513          	addi	a0,a0,-718 # 800215b8 <ftable>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	40a080e7          	jalr	1034(ra) # 80000c98 <release>
  }
}
    80004896:	70e2                	ld	ra,56(sp)
    80004898:	7442                	ld	s0,48(sp)
    8000489a:	74a2                	ld	s1,40(sp)
    8000489c:	7902                	ld	s2,32(sp)
    8000489e:	69e2                	ld	s3,24(sp)
    800048a0:	6a42                	ld	s4,16(sp)
    800048a2:	6aa2                	ld	s5,8(sp)
    800048a4:	6121                	addi	sp,sp,64
    800048a6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048a8:	85d6                	mv	a1,s5
    800048aa:	8552                	mv	a0,s4
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	34c080e7          	jalr	844(ra) # 80004bf8 <pipeclose>
    800048b4:	b7cd                	j	80004896 <fileclose+0xa8>

00000000800048b6 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048b6:	715d                	addi	sp,sp,-80
    800048b8:	e486                	sd	ra,72(sp)
    800048ba:	e0a2                	sd	s0,64(sp)
    800048bc:	fc26                	sd	s1,56(sp)
    800048be:	f84a                	sd	s2,48(sp)
    800048c0:	f44e                	sd	s3,40(sp)
    800048c2:	0880                	addi	s0,sp,80
    800048c4:	84aa                	mv	s1,a0
    800048c6:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048c8:	ffffd097          	auipc	ra,0xffffd
    800048cc:	0e8080e7          	jalr	232(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048d0:	409c                	lw	a5,0(s1)
    800048d2:	37f9                	addiw	a5,a5,-2
    800048d4:	4705                	li	a4,1
    800048d6:	04f76763          	bltu	a4,a5,80004924 <filestat+0x6e>
    800048da:	892a                	mv	s2,a0
    ilock(f->ip);
    800048dc:	6c88                	ld	a0,24(s1)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	072080e7          	jalr	114(ra) # 80003950 <ilock>
    stati(f->ip, &st);
    800048e6:	fb840593          	addi	a1,s0,-72
    800048ea:	6c88                	ld	a0,24(s1)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	2ee080e7          	jalr	750(ra) # 80003bda <stati>
    iunlock(f->ip);
    800048f4:	6c88                	ld	a0,24(s1)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	11c080e7          	jalr	284(ra) # 80003a12 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048fe:	46e1                	li	a3,24
    80004900:	fb840613          	addi	a2,s0,-72
    80004904:	85ce                	mv	a1,s3
    80004906:	05893503          	ld	a0,88(s2)
    8000490a:	ffffd097          	auipc	ra,0xffffd
    8000490e:	d68080e7          	jalr	-664(ra) # 80001672 <copyout>
    80004912:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004916:	60a6                	ld	ra,72(sp)
    80004918:	6406                	ld	s0,64(sp)
    8000491a:	74e2                	ld	s1,56(sp)
    8000491c:	7942                	ld	s2,48(sp)
    8000491e:	79a2                	ld	s3,40(sp)
    80004920:	6161                	addi	sp,sp,80
    80004922:	8082                	ret
  return -1;
    80004924:	557d                	li	a0,-1
    80004926:	bfc5                	j	80004916 <filestat+0x60>

0000000080004928 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004928:	7179                	addi	sp,sp,-48
    8000492a:	f406                	sd	ra,40(sp)
    8000492c:	f022                	sd	s0,32(sp)
    8000492e:	ec26                	sd	s1,24(sp)
    80004930:	e84a                	sd	s2,16(sp)
    80004932:	e44e                	sd	s3,8(sp)
    80004934:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004936:	00854783          	lbu	a5,8(a0)
    8000493a:	c3d5                	beqz	a5,800049de <fileread+0xb6>
    8000493c:	84aa                	mv	s1,a0
    8000493e:	89ae                	mv	s3,a1
    80004940:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004942:	411c                	lw	a5,0(a0)
    80004944:	4705                	li	a4,1
    80004946:	04e78963          	beq	a5,a4,80004998 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000494a:	470d                	li	a4,3
    8000494c:	04e78d63          	beq	a5,a4,800049a6 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004950:	4709                	li	a4,2
    80004952:	06e79e63          	bne	a5,a4,800049ce <fileread+0xa6>
    ilock(f->ip);
    80004956:	6d08                	ld	a0,24(a0)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	ff8080e7          	jalr	-8(ra) # 80003950 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004960:	874a                	mv	a4,s2
    80004962:	5094                	lw	a3,32(s1)
    80004964:	864e                	mv	a2,s3
    80004966:	4585                	li	a1,1
    80004968:	6c88                	ld	a0,24(s1)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	29a080e7          	jalr	666(ra) # 80003c04 <readi>
    80004972:	892a                	mv	s2,a0
    80004974:	00a05563          	blez	a0,8000497e <fileread+0x56>
      f->off += r;
    80004978:	509c                	lw	a5,32(s1)
    8000497a:	9fa9                	addw	a5,a5,a0
    8000497c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000497e:	6c88                	ld	a0,24(s1)
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	092080e7          	jalr	146(ra) # 80003a12 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004988:	854a                	mv	a0,s2
    8000498a:	70a2                	ld	ra,40(sp)
    8000498c:	7402                	ld	s0,32(sp)
    8000498e:	64e2                	ld	s1,24(sp)
    80004990:	6942                	ld	s2,16(sp)
    80004992:	69a2                	ld	s3,8(sp)
    80004994:	6145                	addi	sp,sp,48
    80004996:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004998:	6908                	ld	a0,16(a0)
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	3c8080e7          	jalr	968(ra) # 80004d62 <piperead>
    800049a2:	892a                	mv	s2,a0
    800049a4:	b7d5                	j	80004988 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049a6:	02451783          	lh	a5,36(a0)
    800049aa:	03079693          	slli	a3,a5,0x30
    800049ae:	92c1                	srli	a3,a3,0x30
    800049b0:	4725                	li	a4,9
    800049b2:	02d76863          	bltu	a4,a3,800049e2 <fileread+0xba>
    800049b6:	0792                	slli	a5,a5,0x4
    800049b8:	0001d717          	auipc	a4,0x1d
    800049bc:	b6070713          	addi	a4,a4,-1184 # 80021518 <devsw>
    800049c0:	97ba                	add	a5,a5,a4
    800049c2:	639c                	ld	a5,0(a5)
    800049c4:	c38d                	beqz	a5,800049e6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049c6:	4505                	li	a0,1
    800049c8:	9782                	jalr	a5
    800049ca:	892a                	mv	s2,a0
    800049cc:	bf75                	j	80004988 <fileread+0x60>
    panic("fileread");
    800049ce:	00004517          	auipc	a0,0x4
    800049d2:	db250513          	addi	a0,a0,-590 # 80008780 <syscalls+0x260>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	b68080e7          	jalr	-1176(ra) # 8000053e <panic>
    return -1;
    800049de:	597d                	li	s2,-1
    800049e0:	b765                	j	80004988 <fileread+0x60>
      return -1;
    800049e2:	597d                	li	s2,-1
    800049e4:	b755                	j	80004988 <fileread+0x60>
    800049e6:	597d                	li	s2,-1
    800049e8:	b745                	j	80004988 <fileread+0x60>

00000000800049ea <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049ea:	715d                	addi	sp,sp,-80
    800049ec:	e486                	sd	ra,72(sp)
    800049ee:	e0a2                	sd	s0,64(sp)
    800049f0:	fc26                	sd	s1,56(sp)
    800049f2:	f84a                	sd	s2,48(sp)
    800049f4:	f44e                	sd	s3,40(sp)
    800049f6:	f052                	sd	s4,32(sp)
    800049f8:	ec56                	sd	s5,24(sp)
    800049fa:	e85a                	sd	s6,16(sp)
    800049fc:	e45e                	sd	s7,8(sp)
    800049fe:	e062                	sd	s8,0(sp)
    80004a00:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a02:	00954783          	lbu	a5,9(a0)
    80004a06:	10078663          	beqz	a5,80004b12 <filewrite+0x128>
    80004a0a:	892a                	mv	s2,a0
    80004a0c:	8aae                	mv	s5,a1
    80004a0e:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a10:	411c                	lw	a5,0(a0)
    80004a12:	4705                	li	a4,1
    80004a14:	02e78263          	beq	a5,a4,80004a38 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a18:	470d                	li	a4,3
    80004a1a:	02e78663          	beq	a5,a4,80004a46 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a1e:	4709                	li	a4,2
    80004a20:	0ee79163          	bne	a5,a4,80004b02 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a24:	0ac05d63          	blez	a2,80004ade <filewrite+0xf4>
    int i = 0;
    80004a28:	4981                	li	s3,0
    80004a2a:	6b05                	lui	s6,0x1
    80004a2c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a30:	6b85                	lui	s7,0x1
    80004a32:	c00b8b9b          	addiw	s7,s7,-1024
    80004a36:	a861                	j	80004ace <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a38:	6908                	ld	a0,16(a0)
    80004a3a:	00000097          	auipc	ra,0x0
    80004a3e:	22e080e7          	jalr	558(ra) # 80004c68 <pipewrite>
    80004a42:	8a2a                	mv	s4,a0
    80004a44:	a045                	j	80004ae4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a46:	02451783          	lh	a5,36(a0)
    80004a4a:	03079693          	slli	a3,a5,0x30
    80004a4e:	92c1                	srli	a3,a3,0x30
    80004a50:	4725                	li	a4,9
    80004a52:	0cd76263          	bltu	a4,a3,80004b16 <filewrite+0x12c>
    80004a56:	0792                	slli	a5,a5,0x4
    80004a58:	0001d717          	auipc	a4,0x1d
    80004a5c:	ac070713          	addi	a4,a4,-1344 # 80021518 <devsw>
    80004a60:	97ba                	add	a5,a5,a4
    80004a62:	679c                	ld	a5,8(a5)
    80004a64:	cbdd                	beqz	a5,80004b1a <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a66:	4505                	li	a0,1
    80004a68:	9782                	jalr	a5
    80004a6a:	8a2a                	mv	s4,a0
    80004a6c:	a8a5                	j	80004ae4 <filewrite+0xfa>
    80004a6e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a72:	00000097          	auipc	ra,0x0
    80004a76:	8b0080e7          	jalr	-1872(ra) # 80004322 <begin_op>
      ilock(f->ip);
    80004a7a:	01893503          	ld	a0,24(s2)
    80004a7e:	fffff097          	auipc	ra,0xfffff
    80004a82:	ed2080e7          	jalr	-302(ra) # 80003950 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a86:	8762                	mv	a4,s8
    80004a88:	02092683          	lw	a3,32(s2)
    80004a8c:	01598633          	add	a2,s3,s5
    80004a90:	4585                	li	a1,1
    80004a92:	01893503          	ld	a0,24(s2)
    80004a96:	fffff097          	auipc	ra,0xfffff
    80004a9a:	266080e7          	jalr	614(ra) # 80003cfc <writei>
    80004a9e:	84aa                	mv	s1,a0
    80004aa0:	00a05763          	blez	a0,80004aae <filewrite+0xc4>
        f->off += r;
    80004aa4:	02092783          	lw	a5,32(s2)
    80004aa8:	9fa9                	addw	a5,a5,a0
    80004aaa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004aae:	01893503          	ld	a0,24(s2)
    80004ab2:	fffff097          	auipc	ra,0xfffff
    80004ab6:	f60080e7          	jalr	-160(ra) # 80003a12 <iunlock>
      end_op();
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	8e8080e7          	jalr	-1816(ra) # 800043a2 <end_op>

      if(r != n1){
    80004ac2:	009c1f63          	bne	s8,s1,80004ae0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ac6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aca:	0149db63          	bge	s3,s4,80004ae0 <filewrite+0xf6>
      int n1 = n - i;
    80004ace:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ad2:	84be                	mv	s1,a5
    80004ad4:	2781                	sext.w	a5,a5
    80004ad6:	f8fb5ce3          	bge	s6,a5,80004a6e <filewrite+0x84>
    80004ada:	84de                	mv	s1,s7
    80004adc:	bf49                	j	80004a6e <filewrite+0x84>
    int i = 0;
    80004ade:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ae0:	013a1f63          	bne	s4,s3,80004afe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ae4:	8552                	mv	a0,s4
    80004ae6:	60a6                	ld	ra,72(sp)
    80004ae8:	6406                	ld	s0,64(sp)
    80004aea:	74e2                	ld	s1,56(sp)
    80004aec:	7942                	ld	s2,48(sp)
    80004aee:	79a2                	ld	s3,40(sp)
    80004af0:	7a02                	ld	s4,32(sp)
    80004af2:	6ae2                	ld	s5,24(sp)
    80004af4:	6b42                	ld	s6,16(sp)
    80004af6:	6ba2                	ld	s7,8(sp)
    80004af8:	6c02                	ld	s8,0(sp)
    80004afa:	6161                	addi	sp,sp,80
    80004afc:	8082                	ret
    ret = (i == n ? n : -1);
    80004afe:	5a7d                	li	s4,-1
    80004b00:	b7d5                	j	80004ae4 <filewrite+0xfa>
    panic("filewrite");
    80004b02:	00004517          	auipc	a0,0x4
    80004b06:	c8e50513          	addi	a0,a0,-882 # 80008790 <syscalls+0x270>
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	a34080e7          	jalr	-1484(ra) # 8000053e <panic>
    return -1;
    80004b12:	5a7d                	li	s4,-1
    80004b14:	bfc1                	j	80004ae4 <filewrite+0xfa>
      return -1;
    80004b16:	5a7d                	li	s4,-1
    80004b18:	b7f1                	j	80004ae4 <filewrite+0xfa>
    80004b1a:	5a7d                	li	s4,-1
    80004b1c:	b7e1                	j	80004ae4 <filewrite+0xfa>

0000000080004b1e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b1e:	7179                	addi	sp,sp,-48
    80004b20:	f406                	sd	ra,40(sp)
    80004b22:	f022                	sd	s0,32(sp)
    80004b24:	ec26                	sd	s1,24(sp)
    80004b26:	e84a                	sd	s2,16(sp)
    80004b28:	e44e                	sd	s3,8(sp)
    80004b2a:	e052                	sd	s4,0(sp)
    80004b2c:	1800                	addi	s0,sp,48
    80004b2e:	84aa                	mv	s1,a0
    80004b30:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b32:	0005b023          	sd	zero,0(a1)
    80004b36:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	bf8080e7          	jalr	-1032(ra) # 80004732 <filealloc>
    80004b42:	e088                	sd	a0,0(s1)
    80004b44:	c551                	beqz	a0,80004bd0 <pipealloc+0xb2>
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	bec080e7          	jalr	-1044(ra) # 80004732 <filealloc>
    80004b4e:	00aa3023          	sd	a0,0(s4)
    80004b52:	c92d                	beqz	a0,80004bc4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	fa0080e7          	jalr	-96(ra) # 80000af4 <kalloc>
    80004b5c:	892a                	mv	s2,a0
    80004b5e:	c125                	beqz	a0,80004bbe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b60:	4985                	li	s3,1
    80004b62:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b66:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b6a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b6e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b72:	00004597          	auipc	a1,0x4
    80004b76:	c2e58593          	addi	a1,a1,-978 # 800087a0 <syscalls+0x280>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	fda080e7          	jalr	-38(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004b82:	609c                	ld	a5,0(s1)
    80004b84:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b88:	609c                	ld	a5,0(s1)
    80004b8a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b8e:	609c                	ld	a5,0(s1)
    80004b90:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b94:	609c                	ld	a5,0(s1)
    80004b96:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b9a:	000a3783          	ld	a5,0(s4)
    80004b9e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ba2:	000a3783          	ld	a5,0(s4)
    80004ba6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004baa:	000a3783          	ld	a5,0(s4)
    80004bae:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bb2:	000a3783          	ld	a5,0(s4)
    80004bb6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bba:	4501                	li	a0,0
    80004bbc:	a025                	j	80004be4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bbe:	6088                	ld	a0,0(s1)
    80004bc0:	e501                	bnez	a0,80004bc8 <pipealloc+0xaa>
    80004bc2:	a039                	j	80004bd0 <pipealloc+0xb2>
    80004bc4:	6088                	ld	a0,0(s1)
    80004bc6:	c51d                	beqz	a0,80004bf4 <pipealloc+0xd6>
    fileclose(*f0);
    80004bc8:	00000097          	auipc	ra,0x0
    80004bcc:	c26080e7          	jalr	-986(ra) # 800047ee <fileclose>
  if(*f1)
    80004bd0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bd4:	557d                	li	a0,-1
  if(*f1)
    80004bd6:	c799                	beqz	a5,80004be4 <pipealloc+0xc6>
    fileclose(*f1);
    80004bd8:	853e                	mv	a0,a5
    80004bda:	00000097          	auipc	ra,0x0
    80004bde:	c14080e7          	jalr	-1004(ra) # 800047ee <fileclose>
  return -1;
    80004be2:	557d                	li	a0,-1
}
    80004be4:	70a2                	ld	ra,40(sp)
    80004be6:	7402                	ld	s0,32(sp)
    80004be8:	64e2                	ld	s1,24(sp)
    80004bea:	6942                	ld	s2,16(sp)
    80004bec:	69a2                	ld	s3,8(sp)
    80004bee:	6a02                	ld	s4,0(sp)
    80004bf0:	6145                	addi	sp,sp,48
    80004bf2:	8082                	ret
  return -1;
    80004bf4:	557d                	li	a0,-1
    80004bf6:	b7fd                	j	80004be4 <pipealloc+0xc6>

0000000080004bf8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bf8:	1101                	addi	sp,sp,-32
    80004bfa:	ec06                	sd	ra,24(sp)
    80004bfc:	e822                	sd	s0,16(sp)
    80004bfe:	e426                	sd	s1,8(sp)
    80004c00:	e04a                	sd	s2,0(sp)
    80004c02:	1000                	addi	s0,sp,32
    80004c04:	84aa                	mv	s1,a0
    80004c06:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	fdc080e7          	jalr	-36(ra) # 80000be4 <acquire>
  if(writable){
    80004c10:	02090d63          	beqz	s2,80004c4a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c14:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c18:	21848513          	addi	a0,s1,536
    80004c1c:	ffffd097          	auipc	ra,0xffffd
    80004c20:	62a080e7          	jalr	1578(ra) # 80002246 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c24:	2204b783          	ld	a5,544(s1)
    80004c28:	eb95                	bnez	a5,80004c5c <pipeclose+0x64>
    release(&pi->lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	06c080e7          	jalr	108(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004c34:	8526                	mv	a0,s1
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	dc2080e7          	jalr	-574(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004c3e:	60e2                	ld	ra,24(sp)
    80004c40:	6442                	ld	s0,16(sp)
    80004c42:	64a2                	ld	s1,8(sp)
    80004c44:	6902                	ld	s2,0(sp)
    80004c46:	6105                	addi	sp,sp,32
    80004c48:	8082                	ret
    pi->readopen = 0;
    80004c4a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c4e:	21c48513          	addi	a0,s1,540
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	5f4080e7          	jalr	1524(ra) # 80002246 <wakeup>
    80004c5a:	b7e9                	j	80004c24 <pipeclose+0x2c>
    release(&pi->lock);
    80004c5c:	8526                	mv	a0,s1
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	03a080e7          	jalr	58(ra) # 80000c98 <release>
}
    80004c66:	bfe1                	j	80004c3e <pipeclose+0x46>

0000000080004c68 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c68:	7159                	addi	sp,sp,-112
    80004c6a:	f486                	sd	ra,104(sp)
    80004c6c:	f0a2                	sd	s0,96(sp)
    80004c6e:	eca6                	sd	s1,88(sp)
    80004c70:	e8ca                	sd	s2,80(sp)
    80004c72:	e4ce                	sd	s3,72(sp)
    80004c74:	e0d2                	sd	s4,64(sp)
    80004c76:	fc56                	sd	s5,56(sp)
    80004c78:	f85a                	sd	s6,48(sp)
    80004c7a:	f45e                	sd	s7,40(sp)
    80004c7c:	f062                	sd	s8,32(sp)
    80004c7e:	ec66                	sd	s9,24(sp)
    80004c80:	1880                	addi	s0,sp,112
    80004c82:	84aa                	mv	s1,a0
    80004c84:	8aae                	mv	s5,a1
    80004c86:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	d28080e7          	jalr	-728(ra) # 800019b0 <myproc>
    80004c90:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	f50080e7          	jalr	-176(ra) # 80000be4 <acquire>
  while(i < n){
    80004c9c:	0d405163          	blez	s4,80004d5e <pipewrite+0xf6>
    80004ca0:	8ba6                	mv	s7,s1
  int i = 0;
    80004ca2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ca4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ca6:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004caa:	21c48c13          	addi	s8,s1,540
    80004cae:	a08d                	j	80004d10 <pipewrite+0xa8>
      release(&pi->lock);
    80004cb0:	8526                	mv	a0,s1
    80004cb2:	ffffc097          	auipc	ra,0xffffc
    80004cb6:	fe6080e7          	jalr	-26(ra) # 80000c98 <release>
      return -1;
    80004cba:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cbc:	854a                	mv	a0,s2
    80004cbe:	70a6                	ld	ra,104(sp)
    80004cc0:	7406                	ld	s0,96(sp)
    80004cc2:	64e6                	ld	s1,88(sp)
    80004cc4:	6946                	ld	s2,80(sp)
    80004cc6:	69a6                	ld	s3,72(sp)
    80004cc8:	6a06                	ld	s4,64(sp)
    80004cca:	7ae2                	ld	s5,56(sp)
    80004ccc:	7b42                	ld	s6,48(sp)
    80004cce:	7ba2                	ld	s7,40(sp)
    80004cd0:	7c02                	ld	s8,32(sp)
    80004cd2:	6ce2                	ld	s9,24(sp)
    80004cd4:	6165                	addi	sp,sp,112
    80004cd6:	8082                	ret
      wakeup(&pi->nread);
    80004cd8:	8566                	mv	a0,s9
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	56c080e7          	jalr	1388(ra) # 80002246 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ce2:	85de                	mv	a1,s7
    80004ce4:	8562                	mv	a0,s8
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	3d4080e7          	jalr	980(ra) # 800020ba <sleep>
    80004cee:	a839                	j	80004d0c <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cf0:	21c4a783          	lw	a5,540(s1)
    80004cf4:	0017871b          	addiw	a4,a5,1
    80004cf8:	20e4ae23          	sw	a4,540(s1)
    80004cfc:	1ff7f793          	andi	a5,a5,511
    80004d00:	97a6                	add	a5,a5,s1
    80004d02:	f9f44703          	lbu	a4,-97(s0)
    80004d06:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d0a:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d0c:	03495d63          	bge	s2,s4,80004d46 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004d10:	2204a783          	lw	a5,544(s1)
    80004d14:	dfd1                	beqz	a5,80004cb0 <pipewrite+0x48>
    80004d16:	0289a783          	lw	a5,40(s3)
    80004d1a:	fbd9                	bnez	a5,80004cb0 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d1c:	2184a783          	lw	a5,536(s1)
    80004d20:	21c4a703          	lw	a4,540(s1)
    80004d24:	2007879b          	addiw	a5,a5,512
    80004d28:	faf708e3          	beq	a4,a5,80004cd8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d2c:	4685                	li	a3,1
    80004d2e:	01590633          	add	a2,s2,s5
    80004d32:	f9f40593          	addi	a1,s0,-97
    80004d36:	0589b503          	ld	a0,88(s3)
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	9c4080e7          	jalr	-1596(ra) # 800016fe <copyin>
    80004d42:	fb6517e3          	bne	a0,s6,80004cf0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d46:	21848513          	addi	a0,s1,536
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	4fc080e7          	jalr	1276(ra) # 80002246 <wakeup>
  release(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	f44080e7          	jalr	-188(ra) # 80000c98 <release>
  return i;
    80004d5c:	b785                	j	80004cbc <pipewrite+0x54>
  int i = 0;
    80004d5e:	4901                	li	s2,0
    80004d60:	b7dd                	j	80004d46 <pipewrite+0xde>

0000000080004d62 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d62:	715d                	addi	sp,sp,-80
    80004d64:	e486                	sd	ra,72(sp)
    80004d66:	e0a2                	sd	s0,64(sp)
    80004d68:	fc26                	sd	s1,56(sp)
    80004d6a:	f84a                	sd	s2,48(sp)
    80004d6c:	f44e                	sd	s3,40(sp)
    80004d6e:	f052                	sd	s4,32(sp)
    80004d70:	ec56                	sd	s5,24(sp)
    80004d72:	e85a                	sd	s6,16(sp)
    80004d74:	0880                	addi	s0,sp,80
    80004d76:	84aa                	mv	s1,a0
    80004d78:	892e                	mv	s2,a1
    80004d7a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	c34080e7          	jalr	-972(ra) # 800019b0 <myproc>
    80004d84:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d86:	8b26                	mv	s6,s1
    80004d88:	8526                	mv	a0,s1
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	e5a080e7          	jalr	-422(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d92:	2184a703          	lw	a4,536(s1)
    80004d96:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d9a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9e:	02f71463          	bne	a4,a5,80004dc6 <piperead+0x64>
    80004da2:	2244a783          	lw	a5,548(s1)
    80004da6:	c385                	beqz	a5,80004dc6 <piperead+0x64>
    if(pr->killed){
    80004da8:	028a2783          	lw	a5,40(s4)
    80004dac:	ebc1                	bnez	a5,80004e3c <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dae:	85da                	mv	a1,s6
    80004db0:	854e                	mv	a0,s3
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	308080e7          	jalr	776(ra) # 800020ba <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dba:	2184a703          	lw	a4,536(s1)
    80004dbe:	21c4a783          	lw	a5,540(s1)
    80004dc2:	fef700e3          	beq	a4,a5,80004da2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc6:	09505263          	blez	s5,80004e4a <piperead+0xe8>
    80004dca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dcc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dce:	2184a783          	lw	a5,536(s1)
    80004dd2:	21c4a703          	lw	a4,540(s1)
    80004dd6:	02f70d63          	beq	a4,a5,80004e10 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dda:	0017871b          	addiw	a4,a5,1
    80004dde:	20e4ac23          	sw	a4,536(s1)
    80004de2:	1ff7f793          	andi	a5,a5,511
    80004de6:	97a6                	add	a5,a5,s1
    80004de8:	0187c783          	lbu	a5,24(a5)
    80004dec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df0:	4685                	li	a3,1
    80004df2:	fbf40613          	addi	a2,s0,-65
    80004df6:	85ca                	mv	a1,s2
    80004df8:	058a3503          	ld	a0,88(s4)
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	876080e7          	jalr	-1930(ra) # 80001672 <copyout>
    80004e04:	01650663          	beq	a0,s6,80004e10 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e08:	2985                	addiw	s3,s3,1
    80004e0a:	0905                	addi	s2,s2,1
    80004e0c:	fd3a91e3          	bne	s5,s3,80004dce <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e10:	21c48513          	addi	a0,s1,540
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	432080e7          	jalr	1074(ra) # 80002246 <wakeup>
  release(&pi->lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	e7a080e7          	jalr	-390(ra) # 80000c98 <release>
  return i;
}
    80004e26:	854e                	mv	a0,s3
    80004e28:	60a6                	ld	ra,72(sp)
    80004e2a:	6406                	ld	s0,64(sp)
    80004e2c:	74e2                	ld	s1,56(sp)
    80004e2e:	7942                	ld	s2,48(sp)
    80004e30:	79a2                	ld	s3,40(sp)
    80004e32:	7a02                	ld	s4,32(sp)
    80004e34:	6ae2                	ld	s5,24(sp)
    80004e36:	6b42                	ld	s6,16(sp)
    80004e38:	6161                	addi	sp,sp,80
    80004e3a:	8082                	ret
      release(&pi->lock);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	e5a080e7          	jalr	-422(ra) # 80000c98 <release>
      return -1;
    80004e46:	59fd                	li	s3,-1
    80004e48:	bff9                	j	80004e26 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4a:	4981                	li	s3,0
    80004e4c:	b7d1                	j	80004e10 <piperead+0xae>

0000000080004e4e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e4e:	df010113          	addi	sp,sp,-528
    80004e52:	20113423          	sd	ra,520(sp)
    80004e56:	20813023          	sd	s0,512(sp)
    80004e5a:	ffa6                	sd	s1,504(sp)
    80004e5c:	fbca                	sd	s2,496(sp)
    80004e5e:	f7ce                	sd	s3,488(sp)
    80004e60:	f3d2                	sd	s4,480(sp)
    80004e62:	efd6                	sd	s5,472(sp)
    80004e64:	ebda                	sd	s6,464(sp)
    80004e66:	e7de                	sd	s7,456(sp)
    80004e68:	e3e2                	sd	s8,448(sp)
    80004e6a:	ff66                	sd	s9,440(sp)
    80004e6c:	fb6a                	sd	s10,432(sp)
    80004e6e:	f76e                	sd	s11,424(sp)
    80004e70:	0c00                	addi	s0,sp,528
    80004e72:	84aa                	mv	s1,a0
    80004e74:	dea43c23          	sd	a0,-520(s0)
    80004e78:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	b34080e7          	jalr	-1228(ra) # 800019b0 <myproc>
    80004e84:	892a                	mv	s2,a0

  begin_op();
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	49c080e7          	jalr	1180(ra) # 80004322 <begin_op>

  if((ip = namei(path)) == 0){
    80004e8e:	8526                	mv	a0,s1
    80004e90:	fffff097          	auipc	ra,0xfffff
    80004e94:	276080e7          	jalr	630(ra) # 80004106 <namei>
    80004e98:	c92d                	beqz	a0,80004f0a <exec+0xbc>
    80004e9a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e9c:	fffff097          	auipc	ra,0xfffff
    80004ea0:	ab4080e7          	jalr	-1356(ra) # 80003950 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ea4:	04000713          	li	a4,64
    80004ea8:	4681                	li	a3,0
    80004eaa:	e5040613          	addi	a2,s0,-432
    80004eae:	4581                	li	a1,0
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	d52080e7          	jalr	-686(ra) # 80003c04 <readi>
    80004eba:	04000793          	li	a5,64
    80004ebe:	00f51a63          	bne	a0,a5,80004ed2 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ec2:	e5042703          	lw	a4,-432(s0)
    80004ec6:	464c47b7          	lui	a5,0x464c4
    80004eca:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ece:	04f70463          	beq	a4,a5,80004f16 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	cde080e7          	jalr	-802(ra) # 80003bb2 <iunlockput>
    end_op();
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	4c6080e7          	jalr	1222(ra) # 800043a2 <end_op>
  }
  return -1;
    80004ee4:	557d                	li	a0,-1
}
    80004ee6:	20813083          	ld	ra,520(sp)
    80004eea:	20013403          	ld	s0,512(sp)
    80004eee:	74fe                	ld	s1,504(sp)
    80004ef0:	795e                	ld	s2,496(sp)
    80004ef2:	79be                	ld	s3,488(sp)
    80004ef4:	7a1e                	ld	s4,480(sp)
    80004ef6:	6afe                	ld	s5,472(sp)
    80004ef8:	6b5e                	ld	s6,464(sp)
    80004efa:	6bbe                	ld	s7,456(sp)
    80004efc:	6c1e                	ld	s8,448(sp)
    80004efe:	7cfa                	ld	s9,440(sp)
    80004f00:	7d5a                	ld	s10,432(sp)
    80004f02:	7dba                	ld	s11,424(sp)
    80004f04:	21010113          	addi	sp,sp,528
    80004f08:	8082                	ret
    end_op();
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	498080e7          	jalr	1176(ra) # 800043a2 <end_op>
    return -1;
    80004f12:	557d                	li	a0,-1
    80004f14:	bfc9                	j	80004ee6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f16:	854a                	mv	a0,s2
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	ba2080e7          	jalr	-1118(ra) # 80001aba <proc_pagetable>
    80004f20:	8baa                	mv	s7,a0
    80004f22:	d945                	beqz	a0,80004ed2 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f24:	e7042983          	lw	s3,-400(s0)
    80004f28:	e8845783          	lhu	a5,-376(s0)
    80004f2c:	c7ad                	beqz	a5,80004f96 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f2e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f30:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f32:	6c85                	lui	s9,0x1
    80004f34:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f38:	def43823          	sd	a5,-528(s0)
    80004f3c:	a42d                	j	80005166 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f3e:	00004517          	auipc	a0,0x4
    80004f42:	86a50513          	addi	a0,a0,-1942 # 800087a8 <syscalls+0x288>
    80004f46:	ffffb097          	auipc	ra,0xffffb
    80004f4a:	5f8080e7          	jalr	1528(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f4e:	8756                	mv	a4,s5
    80004f50:	012d86bb          	addw	a3,s11,s2
    80004f54:	4581                	li	a1,0
    80004f56:	8526                	mv	a0,s1
    80004f58:	fffff097          	auipc	ra,0xfffff
    80004f5c:	cac080e7          	jalr	-852(ra) # 80003c04 <readi>
    80004f60:	2501                	sext.w	a0,a0
    80004f62:	1aaa9963          	bne	s5,a0,80005114 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f66:	6785                	lui	a5,0x1
    80004f68:	0127893b          	addw	s2,a5,s2
    80004f6c:	77fd                	lui	a5,0xfffff
    80004f6e:	01478a3b          	addw	s4,a5,s4
    80004f72:	1f897163          	bgeu	s2,s8,80005154 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f76:	02091593          	slli	a1,s2,0x20
    80004f7a:	9181                	srli	a1,a1,0x20
    80004f7c:	95ea                	add	a1,a1,s10
    80004f7e:	855e                	mv	a0,s7
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	0ee080e7          	jalr	238(ra) # 8000106e <walkaddr>
    80004f88:	862a                	mv	a2,a0
    if(pa == 0)
    80004f8a:	d955                	beqz	a0,80004f3e <exec+0xf0>
      n = PGSIZE;
    80004f8c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f8e:	fd9a70e3          	bgeu	s4,s9,80004f4e <exec+0x100>
      n = sz - i;
    80004f92:	8ad2                	mv	s5,s4
    80004f94:	bf6d                	j	80004f4e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f96:	4901                	li	s2,0
  iunlockput(ip);
    80004f98:	8526                	mv	a0,s1
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	c18080e7          	jalr	-1000(ra) # 80003bb2 <iunlockput>
  end_op();
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	400080e7          	jalr	1024(ra) # 800043a2 <end_op>
  p = myproc();
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	a06080e7          	jalr	-1530(ra) # 800019b0 <myproc>
    80004fb2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fb4:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004fb8:	6785                	lui	a5,0x1
    80004fba:	17fd                	addi	a5,a5,-1
    80004fbc:	993e                	add	s2,s2,a5
    80004fbe:	757d                	lui	a0,0xfffff
    80004fc0:	00a977b3          	and	a5,s2,a0
    80004fc4:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fc8:	6609                	lui	a2,0x2
    80004fca:	963e                	add	a2,a2,a5
    80004fcc:	85be                	mv	a1,a5
    80004fce:	855e                	mv	a0,s7
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	452080e7          	jalr	1106(ra) # 80001422 <uvmalloc>
    80004fd8:	8b2a                	mv	s6,a0
  ip = 0;
    80004fda:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fdc:	12050c63          	beqz	a0,80005114 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fe0:	75f9                	lui	a1,0xffffe
    80004fe2:	95aa                	add	a1,a1,a0
    80004fe4:	855e                	mv	a0,s7
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	65a080e7          	jalr	1626(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fee:	7c7d                	lui	s8,0xfffff
    80004ff0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ff2:	e0043783          	ld	a5,-512(s0)
    80004ff6:	6388                	ld	a0,0(a5)
    80004ff8:	c535                	beqz	a0,80005064 <exec+0x216>
    80004ffa:	e9040993          	addi	s3,s0,-368
    80004ffe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005002:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	e60080e7          	jalr	-416(ra) # 80000e64 <strlen>
    8000500c:	2505                	addiw	a0,a0,1
    8000500e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005012:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005016:	13896363          	bltu	s2,s8,8000513c <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000501a:	e0043d83          	ld	s11,-512(s0)
    8000501e:	000dba03          	ld	s4,0(s11)
    80005022:	8552                	mv	a0,s4
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	e40080e7          	jalr	-448(ra) # 80000e64 <strlen>
    8000502c:	0015069b          	addiw	a3,a0,1
    80005030:	8652                	mv	a2,s4
    80005032:	85ca                	mv	a1,s2
    80005034:	855e                	mv	a0,s7
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	63c080e7          	jalr	1596(ra) # 80001672 <copyout>
    8000503e:	10054363          	bltz	a0,80005144 <exec+0x2f6>
    ustack[argc] = sp;
    80005042:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005046:	0485                	addi	s1,s1,1
    80005048:	008d8793          	addi	a5,s11,8
    8000504c:	e0f43023          	sd	a5,-512(s0)
    80005050:	008db503          	ld	a0,8(s11)
    80005054:	c911                	beqz	a0,80005068 <exec+0x21a>
    if(argc >= MAXARG)
    80005056:	09a1                	addi	s3,s3,8
    80005058:	fb3c96e3          	bne	s9,s3,80005004 <exec+0x1b6>
  sz = sz1;
    8000505c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005060:	4481                	li	s1,0
    80005062:	a84d                	j	80005114 <exec+0x2c6>
  sp = sz;
    80005064:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005066:	4481                	li	s1,0
  ustack[argc] = 0;
    80005068:	00349793          	slli	a5,s1,0x3
    8000506c:	f9040713          	addi	a4,s0,-112
    80005070:	97ba                	add	a5,a5,a4
    80005072:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005076:	00148693          	addi	a3,s1,1
    8000507a:	068e                	slli	a3,a3,0x3
    8000507c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005080:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005084:	01897663          	bgeu	s2,s8,80005090 <exec+0x242>
  sz = sz1;
    80005088:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000508c:	4481                	li	s1,0
    8000508e:	a059                	j	80005114 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005090:	e9040613          	addi	a2,s0,-368
    80005094:	85ca                	mv	a1,s2
    80005096:	855e                	mv	a0,s7
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	5da080e7          	jalr	1498(ra) # 80001672 <copyout>
    800050a0:	0a054663          	bltz	a0,8000514c <exec+0x2fe>
  p->trapframe->a1 = sp;
    800050a4:	060ab783          	ld	a5,96(s5)
    800050a8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050ac:	df843783          	ld	a5,-520(s0)
    800050b0:	0007c703          	lbu	a4,0(a5)
    800050b4:	cf11                	beqz	a4,800050d0 <exec+0x282>
    800050b6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050b8:	02f00693          	li	a3,47
    800050bc:	a039                	j	800050ca <exec+0x27c>
      last = s+1;
    800050be:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050c2:	0785                	addi	a5,a5,1
    800050c4:	fff7c703          	lbu	a4,-1(a5)
    800050c8:	c701                	beqz	a4,800050d0 <exec+0x282>
    if(*s == '/')
    800050ca:	fed71ce3          	bne	a4,a3,800050c2 <exec+0x274>
    800050ce:	bfc5                	j	800050be <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d0:	4641                	li	a2,16
    800050d2:	df843583          	ld	a1,-520(s0)
    800050d6:	160a8513          	addi	a0,s5,352
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	d58080e7          	jalr	-680(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800050e2:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    800050e6:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    800050ea:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050ee:	060ab783          	ld	a5,96(s5)
    800050f2:	e6843703          	ld	a4,-408(s0)
    800050f6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050f8:	060ab783          	ld	a5,96(s5)
    800050fc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005100:	85ea                	mv	a1,s10
    80005102:	ffffd097          	auipc	ra,0xffffd
    80005106:	a54080e7          	jalr	-1452(ra) # 80001b56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000510a:	0004851b          	sext.w	a0,s1
    8000510e:	bbe1                	j	80004ee6 <exec+0x98>
    80005110:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005114:	e0843583          	ld	a1,-504(s0)
    80005118:	855e                	mv	a0,s7
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	a3c080e7          	jalr	-1476(ra) # 80001b56 <proc_freepagetable>
  if(ip){
    80005122:	da0498e3          	bnez	s1,80004ed2 <exec+0x84>
  return -1;
    80005126:	557d                	li	a0,-1
    80005128:	bb7d                	j	80004ee6 <exec+0x98>
    8000512a:	e1243423          	sd	s2,-504(s0)
    8000512e:	b7dd                	j	80005114 <exec+0x2c6>
    80005130:	e1243423          	sd	s2,-504(s0)
    80005134:	b7c5                	j	80005114 <exec+0x2c6>
    80005136:	e1243423          	sd	s2,-504(s0)
    8000513a:	bfe9                	j	80005114 <exec+0x2c6>
  sz = sz1;
    8000513c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005140:	4481                	li	s1,0
    80005142:	bfc9                	j	80005114 <exec+0x2c6>
  sz = sz1;
    80005144:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005148:	4481                	li	s1,0
    8000514a:	b7e9                	j	80005114 <exec+0x2c6>
  sz = sz1;
    8000514c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005150:	4481                	li	s1,0
    80005152:	b7c9                	j	80005114 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005154:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005158:	2b05                	addiw	s6,s6,1
    8000515a:	0389899b          	addiw	s3,s3,56
    8000515e:	e8845783          	lhu	a5,-376(s0)
    80005162:	e2fb5be3          	bge	s6,a5,80004f98 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005166:	2981                	sext.w	s3,s3
    80005168:	03800713          	li	a4,56
    8000516c:	86ce                	mv	a3,s3
    8000516e:	e1840613          	addi	a2,s0,-488
    80005172:	4581                	li	a1,0
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	a8e080e7          	jalr	-1394(ra) # 80003c04 <readi>
    8000517e:	03800793          	li	a5,56
    80005182:	f8f517e3          	bne	a0,a5,80005110 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005186:	e1842783          	lw	a5,-488(s0)
    8000518a:	4705                	li	a4,1
    8000518c:	fce796e3          	bne	a5,a4,80005158 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005190:	e4043603          	ld	a2,-448(s0)
    80005194:	e3843783          	ld	a5,-456(s0)
    80005198:	f8f669e3          	bltu	a2,a5,8000512a <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000519c:	e2843783          	ld	a5,-472(s0)
    800051a0:	963e                	add	a2,a2,a5
    800051a2:	f8f667e3          	bltu	a2,a5,80005130 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051a6:	85ca                	mv	a1,s2
    800051a8:	855e                	mv	a0,s7
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	278080e7          	jalr	632(ra) # 80001422 <uvmalloc>
    800051b2:	e0a43423          	sd	a0,-504(s0)
    800051b6:	d141                	beqz	a0,80005136 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800051b8:	e2843d03          	ld	s10,-472(s0)
    800051bc:	df043783          	ld	a5,-528(s0)
    800051c0:	00fd77b3          	and	a5,s10,a5
    800051c4:	fba1                	bnez	a5,80005114 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051c6:	e2042d83          	lw	s11,-480(s0)
    800051ca:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051ce:	f80c03e3          	beqz	s8,80005154 <exec+0x306>
    800051d2:	8a62                	mv	s4,s8
    800051d4:	4901                	li	s2,0
    800051d6:	b345                	j	80004f76 <exec+0x128>

00000000800051d8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051d8:	7179                	addi	sp,sp,-48
    800051da:	f406                	sd	ra,40(sp)
    800051dc:	f022                	sd	s0,32(sp)
    800051de:	ec26                	sd	s1,24(sp)
    800051e0:	e84a                	sd	s2,16(sp)
    800051e2:	1800                	addi	s0,sp,48
    800051e4:	892e                	mv	s2,a1
    800051e6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051e8:	fdc40593          	addi	a1,s0,-36
    800051ec:	ffffe097          	auipc	ra,0xffffe
    800051f0:	ba6080e7          	jalr	-1114(ra) # 80002d92 <argint>
    800051f4:	04054063          	bltz	a0,80005234 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051f8:	fdc42703          	lw	a4,-36(s0)
    800051fc:	47bd                	li	a5,15
    800051fe:	02e7ed63          	bltu	a5,a4,80005238 <argfd+0x60>
    80005202:	ffffc097          	auipc	ra,0xffffc
    80005206:	7ae080e7          	jalr	1966(ra) # 800019b0 <myproc>
    8000520a:	fdc42703          	lw	a4,-36(s0)
    8000520e:	01a70793          	addi	a5,a4,26
    80005212:	078e                	slli	a5,a5,0x3
    80005214:	953e                	add	a0,a0,a5
    80005216:	651c                	ld	a5,8(a0)
    80005218:	c395                	beqz	a5,8000523c <argfd+0x64>
    return -1;
  if(pfd)
    8000521a:	00090463          	beqz	s2,80005222 <argfd+0x4a>
    *pfd = fd;
    8000521e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005222:	4501                	li	a0,0
  if(pf)
    80005224:	c091                	beqz	s1,80005228 <argfd+0x50>
    *pf = f;
    80005226:	e09c                	sd	a5,0(s1)
}
    80005228:	70a2                	ld	ra,40(sp)
    8000522a:	7402                	ld	s0,32(sp)
    8000522c:	64e2                	ld	s1,24(sp)
    8000522e:	6942                	ld	s2,16(sp)
    80005230:	6145                	addi	sp,sp,48
    80005232:	8082                	ret
    return -1;
    80005234:	557d                	li	a0,-1
    80005236:	bfcd                	j	80005228 <argfd+0x50>
    return -1;
    80005238:	557d                	li	a0,-1
    8000523a:	b7fd                	j	80005228 <argfd+0x50>
    8000523c:	557d                	li	a0,-1
    8000523e:	b7ed                	j	80005228 <argfd+0x50>

0000000080005240 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005240:	1101                	addi	sp,sp,-32
    80005242:	ec06                	sd	ra,24(sp)
    80005244:	e822                	sd	s0,16(sp)
    80005246:	e426                	sd	s1,8(sp)
    80005248:	1000                	addi	s0,sp,32
    8000524a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000524c:	ffffc097          	auipc	ra,0xffffc
    80005250:	764080e7          	jalr	1892(ra) # 800019b0 <myproc>
    80005254:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005256:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd90d8>
    8000525a:	4501                	li	a0,0
    8000525c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000525e:	6398                	ld	a4,0(a5)
    80005260:	cb19                	beqz	a4,80005276 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005262:	2505                	addiw	a0,a0,1
    80005264:	07a1                	addi	a5,a5,8
    80005266:	fed51ce3          	bne	a0,a3,8000525e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000526a:	557d                	li	a0,-1
}
    8000526c:	60e2                	ld	ra,24(sp)
    8000526e:	6442                	ld	s0,16(sp)
    80005270:	64a2                	ld	s1,8(sp)
    80005272:	6105                	addi	sp,sp,32
    80005274:	8082                	ret
      p->ofile[fd] = f;
    80005276:	01a50793          	addi	a5,a0,26
    8000527a:	078e                	slli	a5,a5,0x3
    8000527c:	963e                	add	a2,a2,a5
    8000527e:	e604                	sd	s1,8(a2)
      return fd;
    80005280:	b7f5                	j	8000526c <fdalloc+0x2c>

0000000080005282 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005282:	715d                	addi	sp,sp,-80
    80005284:	e486                	sd	ra,72(sp)
    80005286:	e0a2                	sd	s0,64(sp)
    80005288:	fc26                	sd	s1,56(sp)
    8000528a:	f84a                	sd	s2,48(sp)
    8000528c:	f44e                	sd	s3,40(sp)
    8000528e:	f052                	sd	s4,32(sp)
    80005290:	ec56                	sd	s5,24(sp)
    80005292:	0880                	addi	s0,sp,80
    80005294:	89ae                	mv	s3,a1
    80005296:	8ab2                	mv	s5,a2
    80005298:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000529a:	fb040593          	addi	a1,s0,-80
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	e86080e7          	jalr	-378(ra) # 80004124 <nameiparent>
    800052a6:	892a                	mv	s2,a0
    800052a8:	12050f63          	beqz	a0,800053e6 <create+0x164>
    return 0;

  ilock(dp);
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	6a4080e7          	jalr	1700(ra) # 80003950 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052b4:	4601                	li	a2,0
    800052b6:	fb040593          	addi	a1,s0,-80
    800052ba:	854a                	mv	a0,s2
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	b78080e7          	jalr	-1160(ra) # 80003e34 <dirlookup>
    800052c4:	84aa                	mv	s1,a0
    800052c6:	c921                	beqz	a0,80005316 <create+0x94>
    iunlockput(dp);
    800052c8:	854a                	mv	a0,s2
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	8e8080e7          	jalr	-1816(ra) # 80003bb2 <iunlockput>
    ilock(ip);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffe097          	auipc	ra,0xffffe
    800052d8:	67c080e7          	jalr	1660(ra) # 80003950 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052dc:	2981                	sext.w	s3,s3
    800052de:	4789                	li	a5,2
    800052e0:	02f99463          	bne	s3,a5,80005308 <create+0x86>
    800052e4:	0444d783          	lhu	a5,68(s1)
    800052e8:	37f9                	addiw	a5,a5,-2
    800052ea:	17c2                	slli	a5,a5,0x30
    800052ec:	93c1                	srli	a5,a5,0x30
    800052ee:	4705                	li	a4,1
    800052f0:	00f76c63          	bltu	a4,a5,80005308 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052f4:	8526                	mv	a0,s1
    800052f6:	60a6                	ld	ra,72(sp)
    800052f8:	6406                	ld	s0,64(sp)
    800052fa:	74e2                	ld	s1,56(sp)
    800052fc:	7942                	ld	s2,48(sp)
    800052fe:	79a2                	ld	s3,40(sp)
    80005300:	7a02                	ld	s4,32(sp)
    80005302:	6ae2                	ld	s5,24(sp)
    80005304:	6161                	addi	sp,sp,80
    80005306:	8082                	ret
    iunlockput(ip);
    80005308:	8526                	mv	a0,s1
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	8a8080e7          	jalr	-1880(ra) # 80003bb2 <iunlockput>
    return 0;
    80005312:	4481                	li	s1,0
    80005314:	b7c5                	j	800052f4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005316:	85ce                	mv	a1,s3
    80005318:	00092503          	lw	a0,0(s2)
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	49c080e7          	jalr	1180(ra) # 800037b8 <ialloc>
    80005324:	84aa                	mv	s1,a0
    80005326:	c529                	beqz	a0,80005370 <create+0xee>
  ilock(ip);
    80005328:	ffffe097          	auipc	ra,0xffffe
    8000532c:	628080e7          	jalr	1576(ra) # 80003950 <ilock>
  ip->major = major;
    80005330:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005334:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005338:	4785                	li	a5,1
    8000533a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000533e:	8526                	mv	a0,s1
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	546080e7          	jalr	1350(ra) # 80003886 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005348:	2981                	sext.w	s3,s3
    8000534a:	4785                	li	a5,1
    8000534c:	02f98a63          	beq	s3,a5,80005380 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005350:	40d0                	lw	a2,4(s1)
    80005352:	fb040593          	addi	a1,s0,-80
    80005356:	854a                	mv	a0,s2
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	cec080e7          	jalr	-788(ra) # 80004044 <dirlink>
    80005360:	06054b63          	bltz	a0,800053d6 <create+0x154>
  iunlockput(dp);
    80005364:	854a                	mv	a0,s2
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	84c080e7          	jalr	-1972(ra) # 80003bb2 <iunlockput>
  return ip;
    8000536e:	b759                	j	800052f4 <create+0x72>
    panic("create: ialloc");
    80005370:	00003517          	auipc	a0,0x3
    80005374:	45850513          	addi	a0,a0,1112 # 800087c8 <syscalls+0x2a8>
    80005378:	ffffb097          	auipc	ra,0xffffb
    8000537c:	1c6080e7          	jalr	454(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005380:	04a95783          	lhu	a5,74(s2)
    80005384:	2785                	addiw	a5,a5,1
    80005386:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000538a:	854a                	mv	a0,s2
    8000538c:	ffffe097          	auipc	ra,0xffffe
    80005390:	4fa080e7          	jalr	1274(ra) # 80003886 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005394:	40d0                	lw	a2,4(s1)
    80005396:	00003597          	auipc	a1,0x3
    8000539a:	44258593          	addi	a1,a1,1090 # 800087d8 <syscalls+0x2b8>
    8000539e:	8526                	mv	a0,s1
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	ca4080e7          	jalr	-860(ra) # 80004044 <dirlink>
    800053a8:	00054f63          	bltz	a0,800053c6 <create+0x144>
    800053ac:	00492603          	lw	a2,4(s2)
    800053b0:	00003597          	auipc	a1,0x3
    800053b4:	43058593          	addi	a1,a1,1072 # 800087e0 <syscalls+0x2c0>
    800053b8:	8526                	mv	a0,s1
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	c8a080e7          	jalr	-886(ra) # 80004044 <dirlink>
    800053c2:	f80557e3          	bgez	a0,80005350 <create+0xce>
      panic("create dots");
    800053c6:	00003517          	auipc	a0,0x3
    800053ca:	42250513          	addi	a0,a0,1058 # 800087e8 <syscalls+0x2c8>
    800053ce:	ffffb097          	auipc	ra,0xffffb
    800053d2:	170080e7          	jalr	368(ra) # 8000053e <panic>
    panic("create: dirlink");
    800053d6:	00003517          	auipc	a0,0x3
    800053da:	42250513          	addi	a0,a0,1058 # 800087f8 <syscalls+0x2d8>
    800053de:	ffffb097          	auipc	ra,0xffffb
    800053e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    return 0;
    800053e6:	84aa                	mv	s1,a0
    800053e8:	b731                	j	800052f4 <create+0x72>

00000000800053ea <sys_dup>:
{
    800053ea:	7179                	addi	sp,sp,-48
    800053ec:	f406                	sd	ra,40(sp)
    800053ee:	f022                	sd	s0,32(sp)
    800053f0:	ec26                	sd	s1,24(sp)
    800053f2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053f4:	fd840613          	addi	a2,s0,-40
    800053f8:	4581                	li	a1,0
    800053fa:	4501                	li	a0,0
    800053fc:	00000097          	auipc	ra,0x0
    80005400:	ddc080e7          	jalr	-548(ra) # 800051d8 <argfd>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005406:	02054363          	bltz	a0,8000542c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000540a:	fd843503          	ld	a0,-40(s0)
    8000540e:	00000097          	auipc	ra,0x0
    80005412:	e32080e7          	jalr	-462(ra) # 80005240 <fdalloc>
    80005416:	84aa                	mv	s1,a0
    return -1;
    80005418:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000541a:	00054963          	bltz	a0,8000542c <sys_dup+0x42>
  filedup(f);
    8000541e:	fd843503          	ld	a0,-40(s0)
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	37a080e7          	jalr	890(ra) # 8000479c <filedup>
  return fd;
    8000542a:	87a6                	mv	a5,s1
}
    8000542c:	853e                	mv	a0,a5
    8000542e:	70a2                	ld	ra,40(sp)
    80005430:	7402                	ld	s0,32(sp)
    80005432:	64e2                	ld	s1,24(sp)
    80005434:	6145                	addi	sp,sp,48
    80005436:	8082                	ret

0000000080005438 <sys_read>:
{
    80005438:	7179                	addi	sp,sp,-48
    8000543a:	f406                	sd	ra,40(sp)
    8000543c:	f022                	sd	s0,32(sp)
    8000543e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005440:	fe840613          	addi	a2,s0,-24
    80005444:	4581                	li	a1,0
    80005446:	4501                	li	a0,0
    80005448:	00000097          	auipc	ra,0x0
    8000544c:	d90080e7          	jalr	-624(ra) # 800051d8 <argfd>
    return -1;
    80005450:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005452:	04054163          	bltz	a0,80005494 <sys_read+0x5c>
    80005456:	fe440593          	addi	a1,s0,-28
    8000545a:	4509                	li	a0,2
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	936080e7          	jalr	-1738(ra) # 80002d92 <argint>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005466:	02054763          	bltz	a0,80005494 <sys_read+0x5c>
    8000546a:	fd840593          	addi	a1,s0,-40
    8000546e:	4505                	li	a0,1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	944080e7          	jalr	-1724(ra) # 80002db4 <argaddr>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547a:	00054d63          	bltz	a0,80005494 <sys_read+0x5c>
  return fileread(f, p, n);
    8000547e:	fe442603          	lw	a2,-28(s0)
    80005482:	fd843583          	ld	a1,-40(s0)
    80005486:	fe843503          	ld	a0,-24(s0)
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	49e080e7          	jalr	1182(ra) # 80004928 <fileread>
    80005492:	87aa                	mv	a5,a0
}
    80005494:	853e                	mv	a0,a5
    80005496:	70a2                	ld	ra,40(sp)
    80005498:	7402                	ld	s0,32(sp)
    8000549a:	6145                	addi	sp,sp,48
    8000549c:	8082                	ret

000000008000549e <sys_write>:
{
    8000549e:	7179                	addi	sp,sp,-48
    800054a0:	f406                	sd	ra,40(sp)
    800054a2:	f022                	sd	s0,32(sp)
    800054a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a6:	fe840613          	addi	a2,s0,-24
    800054aa:	4581                	li	a1,0
    800054ac:	4501                	li	a0,0
    800054ae:	00000097          	auipc	ra,0x0
    800054b2:	d2a080e7          	jalr	-726(ra) # 800051d8 <argfd>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b8:	04054163          	bltz	a0,800054fa <sys_write+0x5c>
    800054bc:	fe440593          	addi	a1,s0,-28
    800054c0:	4509                	li	a0,2
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	8d0080e7          	jalr	-1840(ra) # 80002d92 <argint>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054cc:	02054763          	bltz	a0,800054fa <sys_write+0x5c>
    800054d0:	fd840593          	addi	a1,s0,-40
    800054d4:	4505                	li	a0,1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	8de080e7          	jalr	-1826(ra) # 80002db4 <argaddr>
    return -1;
    800054de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e0:	00054d63          	bltz	a0,800054fa <sys_write+0x5c>
  return filewrite(f, p, n);
    800054e4:	fe442603          	lw	a2,-28(s0)
    800054e8:	fd843583          	ld	a1,-40(s0)
    800054ec:	fe843503          	ld	a0,-24(s0)
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	4fa080e7          	jalr	1274(ra) # 800049ea <filewrite>
    800054f8:	87aa                	mv	a5,a0
}
    800054fa:	853e                	mv	a0,a5
    800054fc:	70a2                	ld	ra,40(sp)
    800054fe:	7402                	ld	s0,32(sp)
    80005500:	6145                	addi	sp,sp,48
    80005502:	8082                	ret

0000000080005504 <sys_close>:
{
    80005504:	1101                	addi	sp,sp,-32
    80005506:	ec06                	sd	ra,24(sp)
    80005508:	e822                	sd	s0,16(sp)
    8000550a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000550c:	fe040613          	addi	a2,s0,-32
    80005510:	fec40593          	addi	a1,s0,-20
    80005514:	4501                	li	a0,0
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	cc2080e7          	jalr	-830(ra) # 800051d8 <argfd>
    return -1;
    8000551e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005520:	02054463          	bltz	a0,80005548 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	48c080e7          	jalr	1164(ra) # 800019b0 <myproc>
    8000552c:	fec42783          	lw	a5,-20(s0)
    80005530:	07e9                	addi	a5,a5,26
    80005532:	078e                	slli	a5,a5,0x3
    80005534:	97aa                	add	a5,a5,a0
    80005536:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000553a:	fe043503          	ld	a0,-32(s0)
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	2b0080e7          	jalr	688(ra) # 800047ee <fileclose>
  return 0;
    80005546:	4781                	li	a5,0
}
    80005548:	853e                	mv	a0,a5
    8000554a:	60e2                	ld	ra,24(sp)
    8000554c:	6442                	ld	s0,16(sp)
    8000554e:	6105                	addi	sp,sp,32
    80005550:	8082                	ret

0000000080005552 <sys_fstat>:
{
    80005552:	1101                	addi	sp,sp,-32
    80005554:	ec06                	sd	ra,24(sp)
    80005556:	e822                	sd	s0,16(sp)
    80005558:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000555a:	fe840613          	addi	a2,s0,-24
    8000555e:	4581                	li	a1,0
    80005560:	4501                	li	a0,0
    80005562:	00000097          	auipc	ra,0x0
    80005566:	c76080e7          	jalr	-906(ra) # 800051d8 <argfd>
    return -1;
    8000556a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000556c:	02054563          	bltz	a0,80005596 <sys_fstat+0x44>
    80005570:	fe040593          	addi	a1,s0,-32
    80005574:	4505                	li	a0,1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	83e080e7          	jalr	-1986(ra) # 80002db4 <argaddr>
    return -1;
    8000557e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005580:	00054b63          	bltz	a0,80005596 <sys_fstat+0x44>
  return filestat(f, st);
    80005584:	fe043583          	ld	a1,-32(s0)
    80005588:	fe843503          	ld	a0,-24(s0)
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	32a080e7          	jalr	810(ra) # 800048b6 <filestat>
    80005594:	87aa                	mv	a5,a0
}
    80005596:	853e                	mv	a0,a5
    80005598:	60e2                	ld	ra,24(sp)
    8000559a:	6442                	ld	s0,16(sp)
    8000559c:	6105                	addi	sp,sp,32
    8000559e:	8082                	ret

00000000800055a0 <sys_link>:
{
    800055a0:	7169                	addi	sp,sp,-304
    800055a2:	f606                	sd	ra,296(sp)
    800055a4:	f222                	sd	s0,288(sp)
    800055a6:	ee26                	sd	s1,280(sp)
    800055a8:	ea4a                	sd	s2,272(sp)
    800055aa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ac:	08000613          	li	a2,128
    800055b0:	ed040593          	addi	a1,s0,-304
    800055b4:	4501                	li	a0,0
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	820080e7          	jalr	-2016(ra) # 80002dd6 <argstr>
    return -1;
    800055be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c0:	10054e63          	bltz	a0,800056dc <sys_link+0x13c>
    800055c4:	08000613          	li	a2,128
    800055c8:	f5040593          	addi	a1,s0,-176
    800055cc:	4505                	li	a0,1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	808080e7          	jalr	-2040(ra) # 80002dd6 <argstr>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d8:	10054263          	bltz	a0,800056dc <sys_link+0x13c>
  begin_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	d46080e7          	jalr	-698(ra) # 80004322 <begin_op>
  if((ip = namei(old)) == 0){
    800055e4:	ed040513          	addi	a0,s0,-304
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	b1e080e7          	jalr	-1250(ra) # 80004106 <namei>
    800055f0:	84aa                	mv	s1,a0
    800055f2:	c551                	beqz	a0,8000567e <sys_link+0xde>
  ilock(ip);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	35c080e7          	jalr	860(ra) # 80003950 <ilock>
  if(ip->type == T_DIR){
    800055fc:	04449703          	lh	a4,68(s1)
    80005600:	4785                	li	a5,1
    80005602:	08f70463          	beq	a4,a5,8000568a <sys_link+0xea>
  ip->nlink++;
    80005606:	04a4d783          	lhu	a5,74(s1)
    8000560a:	2785                	addiw	a5,a5,1
    8000560c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005610:	8526                	mv	a0,s1
    80005612:	ffffe097          	auipc	ra,0xffffe
    80005616:	274080e7          	jalr	628(ra) # 80003886 <iupdate>
  iunlock(ip);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	3f6080e7          	jalr	1014(ra) # 80003a12 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005624:	fd040593          	addi	a1,s0,-48
    80005628:	f5040513          	addi	a0,s0,-176
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	af8080e7          	jalr	-1288(ra) # 80004124 <nameiparent>
    80005634:	892a                	mv	s2,a0
    80005636:	c935                	beqz	a0,800056aa <sys_link+0x10a>
  ilock(dp);
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	318080e7          	jalr	792(ra) # 80003950 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005640:	00092703          	lw	a4,0(s2)
    80005644:	409c                	lw	a5,0(s1)
    80005646:	04f71d63          	bne	a4,a5,800056a0 <sys_link+0x100>
    8000564a:	40d0                	lw	a2,4(s1)
    8000564c:	fd040593          	addi	a1,s0,-48
    80005650:	854a                	mv	a0,s2
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	9f2080e7          	jalr	-1550(ra) # 80004044 <dirlink>
    8000565a:	04054363          	bltz	a0,800056a0 <sys_link+0x100>
  iunlockput(dp);
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	552080e7          	jalr	1362(ra) # 80003bb2 <iunlockput>
  iput(ip);
    80005668:	8526                	mv	a0,s1
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	4a0080e7          	jalr	1184(ra) # 80003b0a <iput>
  end_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	d30080e7          	jalr	-720(ra) # 800043a2 <end_op>
  return 0;
    8000567a:	4781                	li	a5,0
    8000567c:	a085                	j	800056dc <sys_link+0x13c>
    end_op();
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	d24080e7          	jalr	-732(ra) # 800043a2 <end_op>
    return -1;
    80005686:	57fd                	li	a5,-1
    80005688:	a891                	j	800056dc <sys_link+0x13c>
    iunlockput(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	526080e7          	jalr	1318(ra) # 80003bb2 <iunlockput>
    end_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	d0e080e7          	jalr	-754(ra) # 800043a2 <end_op>
    return -1;
    8000569c:	57fd                	li	a5,-1
    8000569e:	a83d                	j	800056dc <sys_link+0x13c>
    iunlockput(dp);
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	510080e7          	jalr	1296(ra) # 80003bb2 <iunlockput>
  ilock(ip);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	2a4080e7          	jalr	676(ra) # 80003950 <ilock>
  ip->nlink--;
    800056b4:	04a4d783          	lhu	a5,74(s1)
    800056b8:	37fd                	addiw	a5,a5,-1
    800056ba:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	1c6080e7          	jalr	454(ra) # 80003886 <iupdate>
  iunlockput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	4e8080e7          	jalr	1256(ra) # 80003bb2 <iunlockput>
  end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	cd0080e7          	jalr	-816(ra) # 800043a2 <end_op>
  return -1;
    800056da:	57fd                	li	a5,-1
}
    800056dc:	853e                	mv	a0,a5
    800056de:	70b2                	ld	ra,296(sp)
    800056e0:	7412                	ld	s0,288(sp)
    800056e2:	64f2                	ld	s1,280(sp)
    800056e4:	6952                	ld	s2,272(sp)
    800056e6:	6155                	addi	sp,sp,304
    800056e8:	8082                	ret

00000000800056ea <sys_unlink>:
{
    800056ea:	7151                	addi	sp,sp,-240
    800056ec:	f586                	sd	ra,232(sp)
    800056ee:	f1a2                	sd	s0,224(sp)
    800056f0:	eda6                	sd	s1,216(sp)
    800056f2:	e9ca                	sd	s2,208(sp)
    800056f4:	e5ce                	sd	s3,200(sp)
    800056f6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056f8:	08000613          	li	a2,128
    800056fc:	f3040593          	addi	a1,s0,-208
    80005700:	4501                	li	a0,0
    80005702:	ffffd097          	auipc	ra,0xffffd
    80005706:	6d4080e7          	jalr	1748(ra) # 80002dd6 <argstr>
    8000570a:	18054163          	bltz	a0,8000588c <sys_unlink+0x1a2>
  begin_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	c14080e7          	jalr	-1004(ra) # 80004322 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005716:	fb040593          	addi	a1,s0,-80
    8000571a:	f3040513          	addi	a0,s0,-208
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	a06080e7          	jalr	-1530(ra) # 80004124 <nameiparent>
    80005726:	84aa                	mv	s1,a0
    80005728:	c979                	beqz	a0,800057fe <sys_unlink+0x114>
  ilock(dp);
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	226080e7          	jalr	550(ra) # 80003950 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005732:	00003597          	auipc	a1,0x3
    80005736:	0a658593          	addi	a1,a1,166 # 800087d8 <syscalls+0x2b8>
    8000573a:	fb040513          	addi	a0,s0,-80
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	6dc080e7          	jalr	1756(ra) # 80003e1a <namecmp>
    80005746:	14050a63          	beqz	a0,8000589a <sys_unlink+0x1b0>
    8000574a:	00003597          	auipc	a1,0x3
    8000574e:	09658593          	addi	a1,a1,150 # 800087e0 <syscalls+0x2c0>
    80005752:	fb040513          	addi	a0,s0,-80
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	6c4080e7          	jalr	1732(ra) # 80003e1a <namecmp>
    8000575e:	12050e63          	beqz	a0,8000589a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005762:	f2c40613          	addi	a2,s0,-212
    80005766:	fb040593          	addi	a1,s0,-80
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	6c8080e7          	jalr	1736(ra) # 80003e34 <dirlookup>
    80005774:	892a                	mv	s2,a0
    80005776:	12050263          	beqz	a0,8000589a <sys_unlink+0x1b0>
  ilock(ip);
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	1d6080e7          	jalr	470(ra) # 80003950 <ilock>
  if(ip->nlink < 1)
    80005782:	04a91783          	lh	a5,74(s2)
    80005786:	08f05263          	blez	a5,8000580a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000578a:	04491703          	lh	a4,68(s2)
    8000578e:	4785                	li	a5,1
    80005790:	08f70563          	beq	a4,a5,8000581a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005794:	4641                	li	a2,16
    80005796:	4581                	li	a1,0
    80005798:	fc040513          	addi	a0,s0,-64
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	544080e7          	jalr	1348(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057a4:	4741                	li	a4,16
    800057a6:	f2c42683          	lw	a3,-212(s0)
    800057aa:	fc040613          	addi	a2,s0,-64
    800057ae:	4581                	li	a1,0
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	54a080e7          	jalr	1354(ra) # 80003cfc <writei>
    800057ba:	47c1                	li	a5,16
    800057bc:	0af51563          	bne	a0,a5,80005866 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057c0:	04491703          	lh	a4,68(s2)
    800057c4:	4785                	li	a5,1
    800057c6:	0af70863          	beq	a4,a5,80005876 <sys_unlink+0x18c>
  iunlockput(dp);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	3e6080e7          	jalr	998(ra) # 80003bb2 <iunlockput>
  ip->nlink--;
    800057d4:	04a95783          	lhu	a5,74(s2)
    800057d8:	37fd                	addiw	a5,a5,-1
    800057da:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057de:	854a                	mv	a0,s2
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	0a6080e7          	jalr	166(ra) # 80003886 <iupdate>
  iunlockput(ip);
    800057e8:	854a                	mv	a0,s2
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	3c8080e7          	jalr	968(ra) # 80003bb2 <iunlockput>
  end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	bb0080e7          	jalr	-1104(ra) # 800043a2 <end_op>
  return 0;
    800057fa:	4501                	li	a0,0
    800057fc:	a84d                	j	800058ae <sys_unlink+0x1c4>
    end_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	ba4080e7          	jalr	-1116(ra) # 800043a2 <end_op>
    return -1;
    80005806:	557d                	li	a0,-1
    80005808:	a05d                	j	800058ae <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	ffe50513          	addi	a0,a0,-2 # 80008808 <syscalls+0x2e8>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d2c080e7          	jalr	-724(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000581a:	04c92703          	lw	a4,76(s2)
    8000581e:	02000793          	li	a5,32
    80005822:	f6e7f9e3          	bgeu	a5,a4,80005794 <sys_unlink+0xaa>
    80005826:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000582a:	4741                	li	a4,16
    8000582c:	86ce                	mv	a3,s3
    8000582e:	f1840613          	addi	a2,s0,-232
    80005832:	4581                	li	a1,0
    80005834:	854a                	mv	a0,s2
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	3ce080e7          	jalr	974(ra) # 80003c04 <readi>
    8000583e:	47c1                	li	a5,16
    80005840:	00f51b63          	bne	a0,a5,80005856 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005844:	f1845783          	lhu	a5,-232(s0)
    80005848:	e7a1                	bnez	a5,80005890 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000584a:	29c1                	addiw	s3,s3,16
    8000584c:	04c92783          	lw	a5,76(s2)
    80005850:	fcf9ede3          	bltu	s3,a5,8000582a <sys_unlink+0x140>
    80005854:	b781                	j	80005794 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005856:	00003517          	auipc	a0,0x3
    8000585a:	fca50513          	addi	a0,a0,-54 # 80008820 <syscalls+0x300>
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	ce0080e7          	jalr	-800(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005866:	00003517          	auipc	a0,0x3
    8000586a:	fd250513          	addi	a0,a0,-46 # 80008838 <syscalls+0x318>
    8000586e:	ffffb097          	auipc	ra,0xffffb
    80005872:	cd0080e7          	jalr	-816(ra) # 8000053e <panic>
    dp->nlink--;
    80005876:	04a4d783          	lhu	a5,74(s1)
    8000587a:	37fd                	addiw	a5,a5,-1
    8000587c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	004080e7          	jalr	4(ra) # 80003886 <iupdate>
    8000588a:	b781                	j	800057ca <sys_unlink+0xe0>
    return -1;
    8000588c:	557d                	li	a0,-1
    8000588e:	a005                	j	800058ae <sys_unlink+0x1c4>
    iunlockput(ip);
    80005890:	854a                	mv	a0,s2
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	320080e7          	jalr	800(ra) # 80003bb2 <iunlockput>
  iunlockput(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	316080e7          	jalr	790(ra) # 80003bb2 <iunlockput>
  end_op();
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	afe080e7          	jalr	-1282(ra) # 800043a2 <end_op>
  return -1;
    800058ac:	557d                	li	a0,-1
}
    800058ae:	70ae                	ld	ra,232(sp)
    800058b0:	740e                	ld	s0,224(sp)
    800058b2:	64ee                	ld	s1,216(sp)
    800058b4:	694e                	ld	s2,208(sp)
    800058b6:	69ae                	ld	s3,200(sp)
    800058b8:	616d                	addi	sp,sp,240
    800058ba:	8082                	ret

00000000800058bc <sys_open>:

uint64
sys_open(void)
{
    800058bc:	7131                	addi	sp,sp,-192
    800058be:	fd06                	sd	ra,184(sp)
    800058c0:	f922                	sd	s0,176(sp)
    800058c2:	f526                	sd	s1,168(sp)
    800058c4:	f14a                	sd	s2,160(sp)
    800058c6:	ed4e                	sd	s3,152(sp)
    800058c8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058ca:	08000613          	li	a2,128
    800058ce:	f5040593          	addi	a1,s0,-176
    800058d2:	4501                	li	a0,0
    800058d4:	ffffd097          	auipc	ra,0xffffd
    800058d8:	502080e7          	jalr	1282(ra) # 80002dd6 <argstr>
    return -1;
    800058dc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058de:	0c054163          	bltz	a0,800059a0 <sys_open+0xe4>
    800058e2:	f4c40593          	addi	a1,s0,-180
    800058e6:	4505                	li	a0,1
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	4aa080e7          	jalr	1194(ra) # 80002d92 <argint>
    800058f0:	0a054863          	bltz	a0,800059a0 <sys_open+0xe4>

  begin_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	a2e080e7          	jalr	-1490(ra) # 80004322 <begin_op>

  if(omode & O_CREATE){
    800058fc:	f4c42783          	lw	a5,-180(s0)
    80005900:	2007f793          	andi	a5,a5,512
    80005904:	cbdd                	beqz	a5,800059ba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005906:	4681                	li	a3,0
    80005908:	4601                	li	a2,0
    8000590a:	4589                	li	a1,2
    8000590c:	f5040513          	addi	a0,s0,-176
    80005910:	00000097          	auipc	ra,0x0
    80005914:	972080e7          	jalr	-1678(ra) # 80005282 <create>
    80005918:	892a                	mv	s2,a0
    if(ip == 0){
    8000591a:	c959                	beqz	a0,800059b0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000591c:	04491703          	lh	a4,68(s2)
    80005920:	478d                	li	a5,3
    80005922:	00f71763          	bne	a4,a5,80005930 <sys_open+0x74>
    80005926:	04695703          	lhu	a4,70(s2)
    8000592a:	47a5                	li	a5,9
    8000592c:	0ce7ec63          	bltu	a5,a4,80005a04 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005930:	fffff097          	auipc	ra,0xfffff
    80005934:	e02080e7          	jalr	-510(ra) # 80004732 <filealloc>
    80005938:	89aa                	mv	s3,a0
    8000593a:	10050263          	beqz	a0,80005a3e <sys_open+0x182>
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	902080e7          	jalr	-1790(ra) # 80005240 <fdalloc>
    80005946:	84aa                	mv	s1,a0
    80005948:	0e054663          	bltz	a0,80005a34 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000594c:	04491703          	lh	a4,68(s2)
    80005950:	478d                	li	a5,3
    80005952:	0cf70463          	beq	a4,a5,80005a1a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005956:	4789                	li	a5,2
    80005958:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000595c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005960:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005964:	f4c42783          	lw	a5,-180(s0)
    80005968:	0017c713          	xori	a4,a5,1
    8000596c:	8b05                	andi	a4,a4,1
    8000596e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005972:	0037f713          	andi	a4,a5,3
    80005976:	00e03733          	snez	a4,a4
    8000597a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000597e:	4007f793          	andi	a5,a5,1024
    80005982:	c791                	beqz	a5,8000598e <sys_open+0xd2>
    80005984:	04491703          	lh	a4,68(s2)
    80005988:	4789                	li	a5,2
    8000598a:	08f70f63          	beq	a4,a5,80005a28 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000598e:	854a                	mv	a0,s2
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	082080e7          	jalr	130(ra) # 80003a12 <iunlock>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	a0a080e7          	jalr	-1526(ra) # 800043a2 <end_op>

  return fd;
}
    800059a0:	8526                	mv	a0,s1
    800059a2:	70ea                	ld	ra,184(sp)
    800059a4:	744a                	ld	s0,176(sp)
    800059a6:	74aa                	ld	s1,168(sp)
    800059a8:	790a                	ld	s2,160(sp)
    800059aa:	69ea                	ld	s3,152(sp)
    800059ac:	6129                	addi	sp,sp,192
    800059ae:	8082                	ret
      end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	9f2080e7          	jalr	-1550(ra) # 800043a2 <end_op>
      return -1;
    800059b8:	b7e5                	j	800059a0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059ba:	f5040513          	addi	a0,s0,-176
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	748080e7          	jalr	1864(ra) # 80004106 <namei>
    800059c6:	892a                	mv	s2,a0
    800059c8:	c905                	beqz	a0,800059f8 <sys_open+0x13c>
    ilock(ip);
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	f86080e7          	jalr	-122(ra) # 80003950 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059d2:	04491703          	lh	a4,68(s2)
    800059d6:	4785                	li	a5,1
    800059d8:	f4f712e3          	bne	a4,a5,8000591c <sys_open+0x60>
    800059dc:	f4c42783          	lw	a5,-180(s0)
    800059e0:	dba1                	beqz	a5,80005930 <sys_open+0x74>
      iunlockput(ip);
    800059e2:	854a                	mv	a0,s2
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	1ce080e7          	jalr	462(ra) # 80003bb2 <iunlockput>
      end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	9b6080e7          	jalr	-1610(ra) # 800043a2 <end_op>
      return -1;
    800059f4:	54fd                	li	s1,-1
    800059f6:	b76d                	j	800059a0 <sys_open+0xe4>
      end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	9aa080e7          	jalr	-1622(ra) # 800043a2 <end_op>
      return -1;
    80005a00:	54fd                	li	s1,-1
    80005a02:	bf79                	j	800059a0 <sys_open+0xe4>
    iunlockput(ip);
    80005a04:	854a                	mv	a0,s2
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	1ac080e7          	jalr	428(ra) # 80003bb2 <iunlockput>
    end_op();
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	994080e7          	jalr	-1644(ra) # 800043a2 <end_op>
    return -1;
    80005a16:	54fd                	li	s1,-1
    80005a18:	b761                	j	800059a0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a1a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a1e:	04691783          	lh	a5,70(s2)
    80005a22:	02f99223          	sh	a5,36(s3)
    80005a26:	bf2d                	j	80005960 <sys_open+0xa4>
    itrunc(ip);
    80005a28:	854a                	mv	a0,s2
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	034080e7          	jalr	52(ra) # 80003a5e <itrunc>
    80005a32:	bfb1                	j	8000598e <sys_open+0xd2>
      fileclose(f);
    80005a34:	854e                	mv	a0,s3
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	db8080e7          	jalr	-584(ra) # 800047ee <fileclose>
    iunlockput(ip);
    80005a3e:	854a                	mv	a0,s2
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	172080e7          	jalr	370(ra) # 80003bb2 <iunlockput>
    end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	95a080e7          	jalr	-1702(ra) # 800043a2 <end_op>
    return -1;
    80005a50:	54fd                	li	s1,-1
    80005a52:	b7b9                	j	800059a0 <sys_open+0xe4>

0000000080005a54 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a54:	7175                	addi	sp,sp,-144
    80005a56:	e506                	sd	ra,136(sp)
    80005a58:	e122                	sd	s0,128(sp)
    80005a5a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	8c6080e7          	jalr	-1850(ra) # 80004322 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a64:	08000613          	li	a2,128
    80005a68:	f7040593          	addi	a1,s0,-144
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	368080e7          	jalr	872(ra) # 80002dd6 <argstr>
    80005a76:	02054963          	bltz	a0,80005aa8 <sys_mkdir+0x54>
    80005a7a:	4681                	li	a3,0
    80005a7c:	4601                	li	a2,0
    80005a7e:	4585                	li	a1,1
    80005a80:	f7040513          	addi	a0,s0,-144
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	7fe080e7          	jalr	2046(ra) # 80005282 <create>
    80005a8c:	cd11                	beqz	a0,80005aa8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	124080e7          	jalr	292(ra) # 80003bb2 <iunlockput>
  end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	90c080e7          	jalr	-1780(ra) # 800043a2 <end_op>
  return 0;
    80005a9e:	4501                	li	a0,0
}
    80005aa0:	60aa                	ld	ra,136(sp)
    80005aa2:	640a                	ld	s0,128(sp)
    80005aa4:	6149                	addi	sp,sp,144
    80005aa6:	8082                	ret
    end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	8fa080e7          	jalr	-1798(ra) # 800043a2 <end_op>
    return -1;
    80005ab0:	557d                	li	a0,-1
    80005ab2:	b7fd                	j	80005aa0 <sys_mkdir+0x4c>

0000000080005ab4 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ab4:	7135                	addi	sp,sp,-160
    80005ab6:	ed06                	sd	ra,152(sp)
    80005ab8:	e922                	sd	s0,144(sp)
    80005aba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005abc:	fffff097          	auipc	ra,0xfffff
    80005ac0:	866080e7          	jalr	-1946(ra) # 80004322 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ac4:	08000613          	li	a2,128
    80005ac8:	f7040593          	addi	a1,s0,-144
    80005acc:	4501                	li	a0,0
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	308080e7          	jalr	776(ra) # 80002dd6 <argstr>
    80005ad6:	04054a63          	bltz	a0,80005b2a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ada:	f6c40593          	addi	a1,s0,-148
    80005ade:	4505                	li	a0,1
    80005ae0:	ffffd097          	auipc	ra,0xffffd
    80005ae4:	2b2080e7          	jalr	690(ra) # 80002d92 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ae8:	04054163          	bltz	a0,80005b2a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005aec:	f6840593          	addi	a1,s0,-152
    80005af0:	4509                	li	a0,2
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	2a0080e7          	jalr	672(ra) # 80002d92 <argint>
     argint(1, &major) < 0 ||
    80005afa:	02054863          	bltz	a0,80005b2a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005afe:	f6841683          	lh	a3,-152(s0)
    80005b02:	f6c41603          	lh	a2,-148(s0)
    80005b06:	458d                	li	a1,3
    80005b08:	f7040513          	addi	a0,s0,-144
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	776080e7          	jalr	1910(ra) # 80005282 <create>
     argint(2, &minor) < 0 ||
    80005b14:	c919                	beqz	a0,80005b2a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	09c080e7          	jalr	156(ra) # 80003bb2 <iunlockput>
  end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	884080e7          	jalr	-1916(ra) # 800043a2 <end_op>
  return 0;
    80005b26:	4501                	li	a0,0
    80005b28:	a031                	j	80005b34 <sys_mknod+0x80>
    end_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	878080e7          	jalr	-1928(ra) # 800043a2 <end_op>
    return -1;
    80005b32:	557d                	li	a0,-1
}
    80005b34:	60ea                	ld	ra,152(sp)
    80005b36:	644a                	ld	s0,144(sp)
    80005b38:	610d                	addi	sp,sp,160
    80005b3a:	8082                	ret

0000000080005b3c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b3c:	7135                	addi	sp,sp,-160
    80005b3e:	ed06                	sd	ra,152(sp)
    80005b40:	e922                	sd	s0,144(sp)
    80005b42:	e526                	sd	s1,136(sp)
    80005b44:	e14a                	sd	s2,128(sp)
    80005b46:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b48:	ffffc097          	auipc	ra,0xffffc
    80005b4c:	e68080e7          	jalr	-408(ra) # 800019b0 <myproc>
    80005b50:	892a                	mv	s2,a0
  
  begin_op();
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	7d0080e7          	jalr	2000(ra) # 80004322 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b5a:	08000613          	li	a2,128
    80005b5e:	f6040593          	addi	a1,s0,-160
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	272080e7          	jalr	626(ra) # 80002dd6 <argstr>
    80005b6c:	04054b63          	bltz	a0,80005bc2 <sys_chdir+0x86>
    80005b70:	f6040513          	addi	a0,s0,-160
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	592080e7          	jalr	1426(ra) # 80004106 <namei>
    80005b7c:	84aa                	mv	s1,a0
    80005b7e:	c131                	beqz	a0,80005bc2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	dd0080e7          	jalr	-560(ra) # 80003950 <ilock>
  if(ip->type != T_DIR){
    80005b88:	04449703          	lh	a4,68(s1)
    80005b8c:	4785                	li	a5,1
    80005b8e:	04f71063          	bne	a4,a5,80005bce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b92:	8526                	mv	a0,s1
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	e7e080e7          	jalr	-386(ra) # 80003a12 <iunlock>
  iput(p->cwd);
    80005b9c:	15893503          	ld	a0,344(s2)
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	f6a080e7          	jalr	-150(ra) # 80003b0a <iput>
  end_op();
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	7fa080e7          	jalr	2042(ra) # 800043a2 <end_op>
  p->cwd = ip;
    80005bb0:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bb4:	4501                	li	a0,0
}
    80005bb6:	60ea                	ld	ra,152(sp)
    80005bb8:	644a                	ld	s0,144(sp)
    80005bba:	64aa                	ld	s1,136(sp)
    80005bbc:	690a                	ld	s2,128(sp)
    80005bbe:	610d                	addi	sp,sp,160
    80005bc0:	8082                	ret
    end_op();
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	7e0080e7          	jalr	2016(ra) # 800043a2 <end_op>
    return -1;
    80005bca:	557d                	li	a0,-1
    80005bcc:	b7ed                	j	80005bb6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bce:	8526                	mv	a0,s1
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	fe2080e7          	jalr	-30(ra) # 80003bb2 <iunlockput>
    end_op();
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	7ca080e7          	jalr	1994(ra) # 800043a2 <end_op>
    return -1;
    80005be0:	557d                	li	a0,-1
    80005be2:	bfd1                	j	80005bb6 <sys_chdir+0x7a>

0000000080005be4 <sys_exec>:

uint64
sys_exec(void)
{
    80005be4:	7145                	addi	sp,sp,-464
    80005be6:	e786                	sd	ra,456(sp)
    80005be8:	e3a2                	sd	s0,448(sp)
    80005bea:	ff26                	sd	s1,440(sp)
    80005bec:	fb4a                	sd	s2,432(sp)
    80005bee:	f74e                	sd	s3,424(sp)
    80005bf0:	f352                	sd	s4,416(sp)
    80005bf2:	ef56                	sd	s5,408(sp)
    80005bf4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bf6:	08000613          	li	a2,128
    80005bfa:	f4040593          	addi	a1,s0,-192
    80005bfe:	4501                	li	a0,0
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	1d6080e7          	jalr	470(ra) # 80002dd6 <argstr>
    return -1;
    80005c08:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c0a:	0c054a63          	bltz	a0,80005cde <sys_exec+0xfa>
    80005c0e:	e3840593          	addi	a1,s0,-456
    80005c12:	4505                	li	a0,1
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	1a0080e7          	jalr	416(ra) # 80002db4 <argaddr>
    80005c1c:	0c054163          	bltz	a0,80005cde <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c20:	10000613          	li	a2,256
    80005c24:	4581                	li	a1,0
    80005c26:	e4040513          	addi	a0,s0,-448
    80005c2a:	ffffb097          	auipc	ra,0xffffb
    80005c2e:	0b6080e7          	jalr	182(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c32:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c36:	89a6                	mv	s3,s1
    80005c38:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c3a:	02000a13          	li	s4,32
    80005c3e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c42:	00391513          	slli	a0,s2,0x3
    80005c46:	e3040593          	addi	a1,s0,-464
    80005c4a:	e3843783          	ld	a5,-456(s0)
    80005c4e:	953e                	add	a0,a0,a5
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	0a8080e7          	jalr	168(ra) # 80002cf8 <fetchaddr>
    80005c58:	02054a63          	bltz	a0,80005c8c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c5c:	e3043783          	ld	a5,-464(s0)
    80005c60:	c3b9                	beqz	a5,80005ca6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c62:	ffffb097          	auipc	ra,0xffffb
    80005c66:	e92080e7          	jalr	-366(ra) # 80000af4 <kalloc>
    80005c6a:	85aa                	mv	a1,a0
    80005c6c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c70:	cd11                	beqz	a0,80005c8c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c72:	6605                	lui	a2,0x1
    80005c74:	e3043503          	ld	a0,-464(s0)
    80005c78:	ffffd097          	auipc	ra,0xffffd
    80005c7c:	0d2080e7          	jalr	210(ra) # 80002d4a <fetchstr>
    80005c80:	00054663          	bltz	a0,80005c8c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c84:	0905                	addi	s2,s2,1
    80005c86:	09a1                	addi	s3,s3,8
    80005c88:	fb491be3          	bne	s2,s4,80005c3e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	10048913          	addi	s2,s1,256
    80005c90:	6088                	ld	a0,0(s1)
    80005c92:	c529                	beqz	a0,80005cdc <sys_exec+0xf8>
    kfree(argv[i]);
    80005c94:	ffffb097          	auipc	ra,0xffffb
    80005c98:	d64080e7          	jalr	-668(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9c:	04a1                	addi	s1,s1,8
    80005c9e:	ff2499e3          	bne	s1,s2,80005c90 <sys_exec+0xac>
  return -1;
    80005ca2:	597d                	li	s2,-1
    80005ca4:	a82d                	j	80005cde <sys_exec+0xfa>
      argv[i] = 0;
    80005ca6:	0a8e                	slli	s5,s5,0x3
    80005ca8:	fc040793          	addi	a5,s0,-64
    80005cac:	9abe                	add	s5,s5,a5
    80005cae:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cb2:	e4040593          	addi	a1,s0,-448
    80005cb6:	f4040513          	addi	a0,s0,-192
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	194080e7          	jalr	404(ra) # 80004e4e <exec>
    80005cc2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc4:	10048993          	addi	s3,s1,256
    80005cc8:	6088                	ld	a0,0(s1)
    80005cca:	c911                	beqz	a0,80005cde <sys_exec+0xfa>
    kfree(argv[i]);
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	d2c080e7          	jalr	-724(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd4:	04a1                	addi	s1,s1,8
    80005cd6:	ff3499e3          	bne	s1,s3,80005cc8 <sys_exec+0xe4>
    80005cda:	a011                	j	80005cde <sys_exec+0xfa>
  return -1;
    80005cdc:	597d                	li	s2,-1
}
    80005cde:	854a                	mv	a0,s2
    80005ce0:	60be                	ld	ra,456(sp)
    80005ce2:	641e                	ld	s0,448(sp)
    80005ce4:	74fa                	ld	s1,440(sp)
    80005ce6:	795a                	ld	s2,432(sp)
    80005ce8:	79ba                	ld	s3,424(sp)
    80005cea:	7a1a                	ld	s4,416(sp)
    80005cec:	6afa                	ld	s5,408(sp)
    80005cee:	6179                	addi	sp,sp,464
    80005cf0:	8082                	ret

0000000080005cf2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cf2:	7139                	addi	sp,sp,-64
    80005cf4:	fc06                	sd	ra,56(sp)
    80005cf6:	f822                	sd	s0,48(sp)
    80005cf8:	f426                	sd	s1,40(sp)
    80005cfa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	cb4080e7          	jalr	-844(ra) # 800019b0 <myproc>
    80005d04:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d06:	fd840593          	addi	a1,s0,-40
    80005d0a:	4501                	li	a0,0
    80005d0c:	ffffd097          	auipc	ra,0xffffd
    80005d10:	0a8080e7          	jalr	168(ra) # 80002db4 <argaddr>
    return -1;
    80005d14:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d16:	0e054063          	bltz	a0,80005df6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d1a:	fc840593          	addi	a1,s0,-56
    80005d1e:	fd040513          	addi	a0,s0,-48
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	dfc080e7          	jalr	-516(ra) # 80004b1e <pipealloc>
    return -1;
    80005d2a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d2c:	0c054563          	bltz	a0,80005df6 <sys_pipe+0x104>
  fd0 = -1;
    80005d30:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d34:	fd043503          	ld	a0,-48(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	508080e7          	jalr	1288(ra) # 80005240 <fdalloc>
    80005d40:	fca42223          	sw	a0,-60(s0)
    80005d44:	08054c63          	bltz	a0,80005ddc <sys_pipe+0xea>
    80005d48:	fc843503          	ld	a0,-56(s0)
    80005d4c:	fffff097          	auipc	ra,0xfffff
    80005d50:	4f4080e7          	jalr	1268(ra) # 80005240 <fdalloc>
    80005d54:	fca42023          	sw	a0,-64(s0)
    80005d58:	06054863          	bltz	a0,80005dc8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d5c:	4691                	li	a3,4
    80005d5e:	fc440613          	addi	a2,s0,-60
    80005d62:	fd843583          	ld	a1,-40(s0)
    80005d66:	6ca8                	ld	a0,88(s1)
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	90a080e7          	jalr	-1782(ra) # 80001672 <copyout>
    80005d70:	02054063          	bltz	a0,80005d90 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d74:	4691                	li	a3,4
    80005d76:	fc040613          	addi	a2,s0,-64
    80005d7a:	fd843583          	ld	a1,-40(s0)
    80005d7e:	0591                	addi	a1,a1,4
    80005d80:	6ca8                	ld	a0,88(s1)
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	8f0080e7          	jalr	-1808(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d8a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d8c:	06055563          	bgez	a0,80005df6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d90:	fc442783          	lw	a5,-60(s0)
    80005d94:	07e9                	addi	a5,a5,26
    80005d96:	078e                	slli	a5,a5,0x3
    80005d98:	97a6                	add	a5,a5,s1
    80005d9a:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005d9e:	fc042503          	lw	a0,-64(s0)
    80005da2:	0569                	addi	a0,a0,26
    80005da4:	050e                	slli	a0,a0,0x3
    80005da6:	9526                	add	a0,a0,s1
    80005da8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005dac:	fd043503          	ld	a0,-48(s0)
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	a3e080e7          	jalr	-1474(ra) # 800047ee <fileclose>
    fileclose(wf);
    80005db8:	fc843503          	ld	a0,-56(s0)
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	a32080e7          	jalr	-1486(ra) # 800047ee <fileclose>
    return -1;
    80005dc4:	57fd                	li	a5,-1
    80005dc6:	a805                	j	80005df6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dc8:	fc442783          	lw	a5,-60(s0)
    80005dcc:	0007c863          	bltz	a5,80005ddc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dd0:	01a78513          	addi	a0,a5,26
    80005dd4:	050e                	slli	a0,a0,0x3
    80005dd6:	9526                	add	a0,a0,s1
    80005dd8:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005ddc:	fd043503          	ld	a0,-48(s0)
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	a0e080e7          	jalr	-1522(ra) # 800047ee <fileclose>
    fileclose(wf);
    80005de8:	fc843503          	ld	a0,-56(s0)
    80005dec:	fffff097          	auipc	ra,0xfffff
    80005df0:	a02080e7          	jalr	-1534(ra) # 800047ee <fileclose>
    return -1;
    80005df4:	57fd                	li	a5,-1
}
    80005df6:	853e                	mv	a0,a5
    80005df8:	70e2                	ld	ra,56(sp)
    80005dfa:	7442                	ld	s0,48(sp)
    80005dfc:	74a2                	ld	s1,40(sp)
    80005dfe:	6121                	addi	sp,sp,64
    80005e00:	8082                	ret
	...

0000000080005e10 <kernelvec>:
    80005e10:	7111                	addi	sp,sp,-256
    80005e12:	e006                	sd	ra,0(sp)
    80005e14:	e40a                	sd	sp,8(sp)
    80005e16:	e80e                	sd	gp,16(sp)
    80005e18:	ec12                	sd	tp,24(sp)
    80005e1a:	f016                	sd	t0,32(sp)
    80005e1c:	f41a                	sd	t1,40(sp)
    80005e1e:	f81e                	sd	t2,48(sp)
    80005e20:	fc22                	sd	s0,56(sp)
    80005e22:	e0a6                	sd	s1,64(sp)
    80005e24:	e4aa                	sd	a0,72(sp)
    80005e26:	e8ae                	sd	a1,80(sp)
    80005e28:	ecb2                	sd	a2,88(sp)
    80005e2a:	f0b6                	sd	a3,96(sp)
    80005e2c:	f4ba                	sd	a4,104(sp)
    80005e2e:	f8be                	sd	a5,112(sp)
    80005e30:	fcc2                	sd	a6,120(sp)
    80005e32:	e146                	sd	a7,128(sp)
    80005e34:	e54a                	sd	s2,136(sp)
    80005e36:	e94e                	sd	s3,144(sp)
    80005e38:	ed52                	sd	s4,152(sp)
    80005e3a:	f156                	sd	s5,160(sp)
    80005e3c:	f55a                	sd	s6,168(sp)
    80005e3e:	f95e                	sd	s7,176(sp)
    80005e40:	fd62                	sd	s8,184(sp)
    80005e42:	e1e6                	sd	s9,192(sp)
    80005e44:	e5ea                	sd	s10,200(sp)
    80005e46:	e9ee                	sd	s11,208(sp)
    80005e48:	edf2                	sd	t3,216(sp)
    80005e4a:	f1f6                	sd	t4,224(sp)
    80005e4c:	f5fa                	sd	t5,232(sp)
    80005e4e:	f9fe                	sd	t6,240(sp)
    80005e50:	d75fc0ef          	jal	ra,80002bc4 <kerneltrap>
    80005e54:	6082                	ld	ra,0(sp)
    80005e56:	6122                	ld	sp,8(sp)
    80005e58:	61c2                	ld	gp,16(sp)
    80005e5a:	7282                	ld	t0,32(sp)
    80005e5c:	7322                	ld	t1,40(sp)
    80005e5e:	73c2                	ld	t2,48(sp)
    80005e60:	7462                	ld	s0,56(sp)
    80005e62:	6486                	ld	s1,64(sp)
    80005e64:	6526                	ld	a0,72(sp)
    80005e66:	65c6                	ld	a1,80(sp)
    80005e68:	6666                	ld	a2,88(sp)
    80005e6a:	7686                	ld	a3,96(sp)
    80005e6c:	7726                	ld	a4,104(sp)
    80005e6e:	77c6                	ld	a5,112(sp)
    80005e70:	7866                	ld	a6,120(sp)
    80005e72:	688a                	ld	a7,128(sp)
    80005e74:	692a                	ld	s2,136(sp)
    80005e76:	69ca                	ld	s3,144(sp)
    80005e78:	6a6a                	ld	s4,152(sp)
    80005e7a:	7a8a                	ld	s5,160(sp)
    80005e7c:	7b2a                	ld	s6,168(sp)
    80005e7e:	7bca                	ld	s7,176(sp)
    80005e80:	7c6a                	ld	s8,184(sp)
    80005e82:	6c8e                	ld	s9,192(sp)
    80005e84:	6d2e                	ld	s10,200(sp)
    80005e86:	6dce                	ld	s11,208(sp)
    80005e88:	6e6e                	ld	t3,216(sp)
    80005e8a:	7e8e                	ld	t4,224(sp)
    80005e8c:	7f2e                	ld	t5,232(sp)
    80005e8e:	7fce                	ld	t6,240(sp)
    80005e90:	6111                	addi	sp,sp,256
    80005e92:	10200073          	sret
    80005e96:	00000013          	nop
    80005e9a:	00000013          	nop
    80005e9e:	0001                	nop

0000000080005ea0 <timervec>:
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	e10c                	sd	a1,0(a0)
    80005ea6:	e510                	sd	a2,8(a0)
    80005ea8:	e914                	sd	a3,16(a0)
    80005eaa:	6d0c                	ld	a1,24(a0)
    80005eac:	7110                	ld	a2,32(a0)
    80005eae:	6194                	ld	a3,0(a1)
    80005eb0:	96b2                	add	a3,a3,a2
    80005eb2:	e194                	sd	a3,0(a1)
    80005eb4:	4589                	li	a1,2
    80005eb6:	14459073          	csrw	sip,a1
    80005eba:	6914                	ld	a3,16(a0)
    80005ebc:	6510                	ld	a2,8(a0)
    80005ebe:	610c                	ld	a1,0(a0)
    80005ec0:	34051573          	csrrw	a0,mscratch,a0
    80005ec4:	30200073          	mret
	...

0000000080005eca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eca:	1141                	addi	sp,sp,-16
    80005ecc:	e422                	sd	s0,8(sp)
    80005ece:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ed0:	0c0007b7          	lui	a5,0xc000
    80005ed4:	4705                	li	a4,1
    80005ed6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ed8:	c3d8                	sw	a4,4(a5)
}
    80005eda:	6422                	ld	s0,8(sp)
    80005edc:	0141                	addi	sp,sp,16
    80005ede:	8082                	ret

0000000080005ee0 <plicinithart>:

void
plicinithart(void)
{
    80005ee0:	1141                	addi	sp,sp,-16
    80005ee2:	e406                	sd	ra,8(sp)
    80005ee4:	e022                	sd	s0,0(sp)
    80005ee6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	a9c080e7          	jalr	-1380(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ef0:	0085171b          	slliw	a4,a0,0x8
    80005ef4:	0c0027b7          	lui	a5,0xc002
    80005ef8:	97ba                	add	a5,a5,a4
    80005efa:	40200713          	li	a4,1026
    80005efe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f02:	00d5151b          	slliw	a0,a0,0xd
    80005f06:	0c2017b7          	lui	a5,0xc201
    80005f0a:	953e                	add	a0,a0,a5
    80005f0c:	00052023          	sw	zero,0(a0)
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret

0000000080005f18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f18:	1141                	addi	sp,sp,-16
    80005f1a:	e406                	sd	ra,8(sp)
    80005f1c:	e022                	sd	s0,0(sp)
    80005f1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	a64080e7          	jalr	-1436(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f28:	00d5179b          	slliw	a5,a0,0xd
    80005f2c:	0c201537          	lui	a0,0xc201
    80005f30:	953e                	add	a0,a0,a5
  return irq;
}
    80005f32:	4148                	lw	a0,4(a0)
    80005f34:	60a2                	ld	ra,8(sp)
    80005f36:	6402                	ld	s0,0(sp)
    80005f38:	0141                	addi	sp,sp,16
    80005f3a:	8082                	ret

0000000080005f3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f3c:	1101                	addi	sp,sp,-32
    80005f3e:	ec06                	sd	ra,24(sp)
    80005f40:	e822                	sd	s0,16(sp)
    80005f42:	e426                	sd	s1,8(sp)
    80005f44:	1000                	addi	s0,sp,32
    80005f46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	a3c080e7          	jalr	-1476(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f50:	00d5151b          	slliw	a0,a0,0xd
    80005f54:	0c2017b7          	lui	a5,0xc201
    80005f58:	97aa                	add	a5,a5,a0
    80005f5a:	c3c4                	sw	s1,4(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret

0000000080005f66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f66:	1141                	addi	sp,sp,-16
    80005f68:	e406                	sd	ra,8(sp)
    80005f6a:	e022                	sd	s0,0(sp)
    80005f6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f6e:	479d                	li	a5,7
    80005f70:	06a7c963          	blt	a5,a0,80005fe2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005f74:	0001d797          	auipc	a5,0x1d
    80005f78:	08c78793          	addi	a5,a5,140 # 80023000 <disk>
    80005f7c:	00a78733          	add	a4,a5,a0
    80005f80:	6789                	lui	a5,0x2
    80005f82:	97ba                	add	a5,a5,a4
    80005f84:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f88:	e7ad                	bnez	a5,80005ff2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f8a:	00451793          	slli	a5,a0,0x4
    80005f8e:	0001f717          	auipc	a4,0x1f
    80005f92:	07270713          	addi	a4,a4,114 # 80025000 <disk+0x2000>
    80005f96:	6314                	ld	a3,0(a4)
    80005f98:	96be                	add	a3,a3,a5
    80005f9a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f9e:	6314                	ld	a3,0(a4)
    80005fa0:	96be                	add	a3,a3,a5
    80005fa2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fa6:	6314                	ld	a3,0(a4)
    80005fa8:	96be                	add	a3,a3,a5
    80005faa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fae:	6318                	ld	a4,0(a4)
    80005fb0:	97ba                	add	a5,a5,a4
    80005fb2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005fb6:	0001d797          	auipc	a5,0x1d
    80005fba:	04a78793          	addi	a5,a5,74 # 80023000 <disk>
    80005fbe:	97aa                	add	a5,a5,a0
    80005fc0:	6509                	lui	a0,0x2
    80005fc2:	953e                	add	a0,a0,a5
    80005fc4:	4785                	li	a5,1
    80005fc6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fca:	0001f517          	auipc	a0,0x1f
    80005fce:	04e50513          	addi	a0,a0,78 # 80025018 <disk+0x2018>
    80005fd2:	ffffc097          	auipc	ra,0xffffc
    80005fd6:	274080e7          	jalr	628(ra) # 80002246 <wakeup>
}
    80005fda:	60a2                	ld	ra,8(sp)
    80005fdc:	6402                	ld	s0,0(sp)
    80005fde:	0141                	addi	sp,sp,16
    80005fe0:	8082                	ret
    panic("free_desc 1");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	86650513          	addi	a0,a0,-1946 # 80008848 <syscalls+0x328>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	86650513          	addi	a0,a0,-1946 # 80008858 <syscalls+0x338>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	544080e7          	jalr	1348(ra) # 8000053e <panic>

0000000080006002 <virtio_disk_init>:
{
    80006002:	1101                	addi	sp,sp,-32
    80006004:	ec06                	sd	ra,24(sp)
    80006006:	e822                	sd	s0,16(sp)
    80006008:	e426                	sd	s1,8(sp)
    8000600a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000600c:	00003597          	auipc	a1,0x3
    80006010:	85c58593          	addi	a1,a1,-1956 # 80008868 <syscalls+0x348>
    80006014:	0001f517          	auipc	a0,0x1f
    80006018:	11450513          	addi	a0,a0,276 # 80025128 <disk+0x2128>
    8000601c:	ffffb097          	auipc	ra,0xffffb
    80006020:	b38080e7          	jalr	-1224(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006024:	100017b7          	lui	a5,0x10001
    80006028:	4398                	lw	a4,0(a5)
    8000602a:	2701                	sext.w	a4,a4
    8000602c:	747277b7          	lui	a5,0x74727
    80006030:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006034:	0ef71163          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006038:	100017b7          	lui	a5,0x10001
    8000603c:	43dc                	lw	a5,4(a5)
    8000603e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006040:	4705                	li	a4,1
    80006042:	0ce79a63          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006046:	100017b7          	lui	a5,0x10001
    8000604a:	479c                	lw	a5,8(a5)
    8000604c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000604e:	4709                	li	a4,2
    80006050:	0ce79363          	bne	a5,a4,80006116 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006054:	100017b7          	lui	a5,0x10001
    80006058:	47d8                	lw	a4,12(a5)
    8000605a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605c:	554d47b7          	lui	a5,0x554d4
    80006060:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006064:	0af71963          	bne	a4,a5,80006116 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	100017b7          	lui	a5,0x10001
    8000606c:	4705                	li	a4,1
    8000606e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006070:	470d                	li	a4,3
    80006072:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006074:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006076:	c7ffe737          	lui	a4,0xc7ffe
    8000607a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000607e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006080:	2701                	sext.w	a4,a4
    80006082:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006084:	472d                	li	a4,11
    80006086:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006088:	473d                	li	a4,15
    8000608a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000608c:	6705                	lui	a4,0x1
    8000608e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006090:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006094:	5bdc                	lw	a5,52(a5)
    80006096:	2781                	sext.w	a5,a5
  if(max == 0)
    80006098:	c7d9                	beqz	a5,80006126 <virtio_disk_init+0x124>
  if(max < NUM)
    8000609a:	471d                	li	a4,7
    8000609c:	08f77d63          	bgeu	a4,a5,80006136 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060a0:	100014b7          	lui	s1,0x10001
    800060a4:	47a1                	li	a5,8
    800060a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060a8:	6609                	lui	a2,0x2
    800060aa:	4581                	li	a1,0
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	c2c080e7          	jalr	-980(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060bc:	0001d717          	auipc	a4,0x1d
    800060c0:	f4470713          	addi	a4,a4,-188 # 80023000 <disk>
    800060c4:	00c75793          	srli	a5,a4,0xc
    800060c8:	2781                	sext.w	a5,a5
    800060ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800060cc:	0001f797          	auipc	a5,0x1f
    800060d0:	f3478793          	addi	a5,a5,-204 # 80025000 <disk+0x2000>
    800060d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800060d6:	0001d717          	auipc	a4,0x1d
    800060da:	faa70713          	addi	a4,a4,-86 # 80023080 <disk+0x80>
    800060de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800060e0:	0001e717          	auipc	a4,0x1e
    800060e4:	f2070713          	addi	a4,a4,-224 # 80024000 <disk+0x1000>
    800060e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ea:	4705                	li	a4,1
    800060ec:	00e78c23          	sb	a4,24(a5)
    800060f0:	00e78ca3          	sb	a4,25(a5)
    800060f4:	00e78d23          	sb	a4,26(a5)
    800060f8:	00e78da3          	sb	a4,27(a5)
    800060fc:	00e78e23          	sb	a4,28(a5)
    80006100:	00e78ea3          	sb	a4,29(a5)
    80006104:	00e78f23          	sb	a4,30(a5)
    80006108:	00e78fa3          	sb	a4,31(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6105                	addi	sp,sp,32
    80006114:	8082                	ret
    panic("could not find virtio disk");
    80006116:	00002517          	auipc	a0,0x2
    8000611a:	76250513          	addi	a0,a0,1890 # 80008878 <syscalls+0x358>
    8000611e:	ffffa097          	auipc	ra,0xffffa
    80006122:	420080e7          	jalr	1056(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006126:	00002517          	auipc	a0,0x2
    8000612a:	77250513          	addi	a0,a0,1906 # 80008898 <syscalls+0x378>
    8000612e:	ffffa097          	auipc	ra,0xffffa
    80006132:	410080e7          	jalr	1040(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006136:	00002517          	auipc	a0,0x2
    8000613a:	78250513          	addi	a0,a0,1922 # 800088b8 <syscalls+0x398>
    8000613e:	ffffa097          	auipc	ra,0xffffa
    80006142:	400080e7          	jalr	1024(ra) # 8000053e <panic>

0000000080006146 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006146:	7159                	addi	sp,sp,-112
    80006148:	f486                	sd	ra,104(sp)
    8000614a:	f0a2                	sd	s0,96(sp)
    8000614c:	eca6                	sd	s1,88(sp)
    8000614e:	e8ca                	sd	s2,80(sp)
    80006150:	e4ce                	sd	s3,72(sp)
    80006152:	e0d2                	sd	s4,64(sp)
    80006154:	fc56                	sd	s5,56(sp)
    80006156:	f85a                	sd	s6,48(sp)
    80006158:	f45e                	sd	s7,40(sp)
    8000615a:	f062                	sd	s8,32(sp)
    8000615c:	ec66                	sd	s9,24(sp)
    8000615e:	e86a                	sd	s10,16(sp)
    80006160:	1880                	addi	s0,sp,112
    80006162:	892a                	mv	s2,a0
    80006164:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006166:	00c52c83          	lw	s9,12(a0)
    8000616a:	001c9c9b          	slliw	s9,s9,0x1
    8000616e:	1c82                	slli	s9,s9,0x20
    80006170:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006174:	0001f517          	auipc	a0,0x1f
    80006178:	fb450513          	addi	a0,a0,-76 # 80025128 <disk+0x2128>
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	a68080e7          	jalr	-1432(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006184:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006186:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006188:	0001db97          	auipc	s7,0x1d
    8000618c:	e78b8b93          	addi	s7,s7,-392 # 80023000 <disk>
    80006190:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006192:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006194:	8a4e                	mv	s4,s3
    80006196:	a051                	j	8000621a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006198:	00fb86b3          	add	a3,s7,a5
    8000619c:	96da                	add	a3,a3,s6
    8000619e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061a4:	0207c563          	bltz	a5,800061ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061a8:	2485                	addiw	s1,s1,1
    800061aa:	0711                	addi	a4,a4,4
    800061ac:	25548063          	beq	s1,s5,800063ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061b2:	0001f697          	auipc	a3,0x1f
    800061b6:	e6668693          	addi	a3,a3,-410 # 80025018 <disk+0x2018>
    800061ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061bc:	0006c583          	lbu	a1,0(a3)
    800061c0:	fde1                	bnez	a1,80006198 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061c2:	2785                	addiw	a5,a5,1
    800061c4:	0685                	addi	a3,a3,1
    800061c6:	ff879be3          	bne	a5,s8,800061bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061ca:	57fd                	li	a5,-1
    800061cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061ce:	02905a63          	blez	s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061d2:	f9042503          	lw	a0,-112(s0)
    800061d6:	00000097          	auipc	ra,0x0
    800061da:	d90080e7          	jalr	-624(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061de:	4785                	li	a5,1
    800061e0:	0297d163          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061e4:	f9442503          	lw	a0,-108(s0)
    800061e8:	00000097          	auipc	ra,0x0
    800061ec:	d7e080e7          	jalr	-642(ra) # 80005f66 <free_desc>
      for(int j = 0; j < i; j++)
    800061f0:	4789                	li	a5,2
    800061f2:	0097d863          	bge	a5,s1,80006202 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061f6:	f9842503          	lw	a0,-104(s0)
    800061fa:	00000097          	auipc	ra,0x0
    800061fe:	d6c080e7          	jalr	-660(ra) # 80005f66 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006202:	0001f597          	auipc	a1,0x1f
    80006206:	f2658593          	addi	a1,a1,-218 # 80025128 <disk+0x2128>
    8000620a:	0001f517          	auipc	a0,0x1f
    8000620e:	e0e50513          	addi	a0,a0,-498 # 80025018 <disk+0x2018>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	ea8080e7          	jalr	-344(ra) # 800020ba <sleep>
  for(int i = 0; i < 3; i++){
    8000621a:	f9040713          	addi	a4,s0,-112
    8000621e:	84ce                	mv	s1,s3
    80006220:	bf41                	j	800061b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006222:	20058713          	addi	a4,a1,512
    80006226:	00471693          	slli	a3,a4,0x4
    8000622a:	0001d717          	auipc	a4,0x1d
    8000622e:	dd670713          	addi	a4,a4,-554 # 80023000 <disk>
    80006232:	9736                	add	a4,a4,a3
    80006234:	4685                	li	a3,1
    80006236:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000623a:	20058713          	addi	a4,a1,512
    8000623e:	00471693          	slli	a3,a4,0x4
    80006242:	0001d717          	auipc	a4,0x1d
    80006246:	dbe70713          	addi	a4,a4,-578 # 80023000 <disk>
    8000624a:	9736                	add	a4,a4,a3
    8000624c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006250:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006254:	7679                	lui	a2,0xffffe
    80006256:	963e                	add	a2,a2,a5
    80006258:	0001f697          	auipc	a3,0x1f
    8000625c:	da868693          	addi	a3,a3,-600 # 80025000 <disk+0x2000>
    80006260:	6298                	ld	a4,0(a3)
    80006262:	9732                	add	a4,a4,a2
    80006264:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006266:	6298                	ld	a4,0(a3)
    80006268:	9732                	add	a4,a4,a2
    8000626a:	4541                	li	a0,16
    8000626c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000626e:	6298                	ld	a4,0(a3)
    80006270:	9732                	add	a4,a4,a2
    80006272:	4505                	li	a0,1
    80006274:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006278:	f9442703          	lw	a4,-108(s0)
    8000627c:	6288                	ld	a0,0(a3)
    8000627e:	962a                	add	a2,a2,a0
    80006280:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	6290                	ld	a2,0(a3)
    80006288:	963a                	add	a2,a2,a4
    8000628a:	05890513          	addi	a0,s2,88
    8000628e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006290:	6294                	ld	a3,0(a3)
    80006292:	96ba                	add	a3,a3,a4
    80006294:	40000613          	li	a2,1024
    80006298:	c690                	sw	a2,8(a3)
  if(write)
    8000629a:	140d0063          	beqz	s10,800063da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000629e:	0001f697          	auipc	a3,0x1f
    800062a2:	d626b683          	ld	a3,-670(a3) # 80025000 <disk+0x2000>
    800062a6:	96ba                	add	a3,a3,a4
    800062a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062ac:	0001d817          	auipc	a6,0x1d
    800062b0:	d5480813          	addi	a6,a6,-684 # 80023000 <disk>
    800062b4:	0001f517          	auipc	a0,0x1f
    800062b8:	d4c50513          	addi	a0,a0,-692 # 80025000 <disk+0x2000>
    800062bc:	6114                	ld	a3,0(a0)
    800062be:	96ba                	add	a3,a3,a4
    800062c0:	00c6d603          	lhu	a2,12(a3)
    800062c4:	00166613          	ori	a2,a2,1
    800062c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062cc:	f9842683          	lw	a3,-104(s0)
    800062d0:	6110                	ld	a2,0(a0)
    800062d2:	9732                	add	a4,a4,a2
    800062d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d8:	20058613          	addi	a2,a1,512
    800062dc:	0612                	slli	a2,a2,0x4
    800062de:	9642                	add	a2,a2,a6
    800062e0:	577d                	li	a4,-1
    800062e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e6:	00469713          	slli	a4,a3,0x4
    800062ea:	6114                	ld	a3,0(a0)
    800062ec:	96ba                	add	a3,a3,a4
    800062ee:	03078793          	addi	a5,a5,48
    800062f2:	97c2                	add	a5,a5,a6
    800062f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800062f6:	611c                	ld	a5,0(a0)
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	4685                	li	a3,1
    800062fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062fe:	611c                	ld	a5,0(a0)
    80006300:	97ba                	add	a5,a5,a4
    80006302:	4809                	li	a6,2
    80006304:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006308:	611c                	ld	a5,0(a0)
    8000630a:	973e                	add	a4,a4,a5
    8000630c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006310:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006314:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006318:	6518                	ld	a4,8(a0)
    8000631a:	00275783          	lhu	a5,2(a4)
    8000631e:	8b9d                	andi	a5,a5,7
    80006320:	0786                	slli	a5,a5,0x1
    80006322:	97ba                	add	a5,a5,a4
    80006324:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006328:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000632c:	6518                	ld	a4,8(a0)
    8000632e:	00275783          	lhu	a5,2(a4)
    80006332:	2785                	addiw	a5,a5,1
    80006334:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006338:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000633c:	100017b7          	lui	a5,0x10001
    80006340:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006344:	00492703          	lw	a4,4(s2)
    80006348:	4785                	li	a5,1
    8000634a:	02f71163          	bne	a4,a5,8000636c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000634e:	0001f997          	auipc	s3,0x1f
    80006352:	dda98993          	addi	s3,s3,-550 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006356:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006358:	85ce                	mv	a1,s3
    8000635a:	854a                	mv	a0,s2
    8000635c:	ffffc097          	auipc	ra,0xffffc
    80006360:	d5e080e7          	jalr	-674(ra) # 800020ba <sleep>
  while(b->disk == 1) {
    80006364:	00492783          	lw	a5,4(s2)
    80006368:	fe9788e3          	beq	a5,s1,80006358 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000636c:	f9042903          	lw	s2,-112(s0)
    80006370:	20090793          	addi	a5,s2,512
    80006374:	00479713          	slli	a4,a5,0x4
    80006378:	0001d797          	auipc	a5,0x1d
    8000637c:	c8878793          	addi	a5,a5,-888 # 80023000 <disk>
    80006380:	97ba                	add	a5,a5,a4
    80006382:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006386:	0001f997          	auipc	s3,0x1f
    8000638a:	c7a98993          	addi	s3,s3,-902 # 80025000 <disk+0x2000>
    8000638e:	00491713          	slli	a4,s2,0x4
    80006392:	0009b783          	ld	a5,0(s3)
    80006396:	97ba                	add	a5,a5,a4
    80006398:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000639c:	854a                	mv	a0,s2
    8000639e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063a2:	00000097          	auipc	ra,0x0
    800063a6:	bc4080e7          	jalr	-1084(ra) # 80005f66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063aa:	8885                	andi	s1,s1,1
    800063ac:	f0ed                	bnez	s1,8000638e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063ae:	0001f517          	auipc	a0,0x1f
    800063b2:	d7a50513          	addi	a0,a0,-646 # 80025128 <disk+0x2128>
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	8e2080e7          	jalr	-1822(ra) # 80000c98 <release>
}
    800063be:	70a6                	ld	ra,104(sp)
    800063c0:	7406                	ld	s0,96(sp)
    800063c2:	64e6                	ld	s1,88(sp)
    800063c4:	6946                	ld	s2,80(sp)
    800063c6:	69a6                	ld	s3,72(sp)
    800063c8:	6a06                	ld	s4,64(sp)
    800063ca:	7ae2                	ld	s5,56(sp)
    800063cc:	7b42                	ld	s6,48(sp)
    800063ce:	7ba2                	ld	s7,40(sp)
    800063d0:	7c02                	ld	s8,32(sp)
    800063d2:	6ce2                	ld	s9,24(sp)
    800063d4:	6d42                	ld	s10,16(sp)
    800063d6:	6165                	addi	sp,sp,112
    800063d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063da:	0001f697          	auipc	a3,0x1f
    800063de:	c266b683          	ld	a3,-986(a3) # 80025000 <disk+0x2000>
    800063e2:	96ba                	add	a3,a3,a4
    800063e4:	4609                	li	a2,2
    800063e6:	00c69623          	sh	a2,12(a3)
    800063ea:	b5c9                	j	800062ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063ec:	f9042583          	lw	a1,-112(s0)
    800063f0:	20058793          	addi	a5,a1,512
    800063f4:	0792                	slli	a5,a5,0x4
    800063f6:	0001d517          	auipc	a0,0x1d
    800063fa:	cb250513          	addi	a0,a0,-846 # 800230a8 <disk+0xa8>
    800063fe:	953e                	add	a0,a0,a5
  if(write)
    80006400:	e20d11e3          	bnez	s10,80006222 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006404:	20058713          	addi	a4,a1,512
    80006408:	00471693          	slli	a3,a4,0x4
    8000640c:	0001d717          	auipc	a4,0x1d
    80006410:	bf470713          	addi	a4,a4,-1036 # 80023000 <disk>
    80006414:	9736                	add	a4,a4,a3
    80006416:	0a072423          	sw	zero,168(a4)
    8000641a:	b505                	j	8000623a <virtio_disk_rw+0xf4>

000000008000641c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000641c:	1101                	addi	sp,sp,-32
    8000641e:	ec06                	sd	ra,24(sp)
    80006420:	e822                	sd	s0,16(sp)
    80006422:	e426                	sd	s1,8(sp)
    80006424:	e04a                	sd	s2,0(sp)
    80006426:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006428:	0001f517          	auipc	a0,0x1f
    8000642c:	d0050513          	addi	a0,a0,-768 # 80025128 <disk+0x2128>
    80006430:	ffffa097          	auipc	ra,0xffffa
    80006434:	7b4080e7          	jalr	1972(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006438:	10001737          	lui	a4,0x10001
    8000643c:	533c                	lw	a5,96(a4)
    8000643e:	8b8d                	andi	a5,a5,3
    80006440:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006442:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006446:	0001f797          	auipc	a5,0x1f
    8000644a:	bba78793          	addi	a5,a5,-1094 # 80025000 <disk+0x2000>
    8000644e:	6b94                	ld	a3,16(a5)
    80006450:	0207d703          	lhu	a4,32(a5)
    80006454:	0026d783          	lhu	a5,2(a3)
    80006458:	06f70163          	beq	a4,a5,800064ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000645c:	0001d917          	auipc	s2,0x1d
    80006460:	ba490913          	addi	s2,s2,-1116 # 80023000 <disk>
    80006464:	0001f497          	auipc	s1,0x1f
    80006468:	b9c48493          	addi	s1,s1,-1124 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000646c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006470:	6898                	ld	a4,16(s1)
    80006472:	0204d783          	lhu	a5,32(s1)
    80006476:	8b9d                	andi	a5,a5,7
    80006478:	078e                	slli	a5,a5,0x3
    8000647a:	97ba                	add	a5,a5,a4
    8000647c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000647e:	20078713          	addi	a4,a5,512
    80006482:	0712                	slli	a4,a4,0x4
    80006484:	974a                	add	a4,a4,s2
    80006486:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000648a:	e731                	bnez	a4,800064d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000648c:	20078793          	addi	a5,a5,512
    80006490:	0792                	slli	a5,a5,0x4
    80006492:	97ca                	add	a5,a5,s2
    80006494:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006496:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000649a:	ffffc097          	auipc	ra,0xffffc
    8000649e:	dac080e7          	jalr	-596(ra) # 80002246 <wakeup>

    disk.used_idx += 1;
    800064a2:	0204d783          	lhu	a5,32(s1)
    800064a6:	2785                	addiw	a5,a5,1
    800064a8:	17c2                	slli	a5,a5,0x30
    800064aa:	93c1                	srli	a5,a5,0x30
    800064ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064b0:	6898                	ld	a4,16(s1)
    800064b2:	00275703          	lhu	a4,2(a4)
    800064b6:	faf71be3          	bne	a4,a5,8000646c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064ba:	0001f517          	auipc	a0,0x1f
    800064be:	c6e50513          	addi	a0,a0,-914 # 80025128 <disk+0x2128>
    800064c2:	ffffa097          	auipc	ra,0xffffa
    800064c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
}
    800064ca:	60e2                	ld	ra,24(sp)
    800064cc:	6442                	ld	s0,16(sp)
    800064ce:	64a2                	ld	s1,8(sp)
    800064d0:	6902                	ld	s2,0(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret
      panic("virtio_disk_intr status");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	40250513          	addi	a0,a0,1026 # 800088d8 <syscalls+0x3b8>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	060080e7          	jalr	96(ra) # 8000053e <panic>
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
