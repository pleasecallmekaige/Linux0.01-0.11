!
! SYS_SIZE is the number of clicks (16 bytes) to be loaded.
! 0x3000 is 0x30000 bytes = 196kB, more than enough for current
! versions of linux
!
SYSSIZE = 0x3000 //16bytes 的个数
!
!	bootsect.s		(C) 1991 Linus Torvalds
!
! bootsect.s is loaded at 0x7c00 by the bios-startup routines, and moves
! iself out of the way to address 0x90000, and jumps there.
!
! It then loads 'setup' directly after itself (0x90200), and the system
! at 0x10000, using BIOS interrupts. 
!
! NOTE! currently system is at most 8*65536 bytes long. This should be no
! problem, even in the future. I want to keep it simple. This 512 kB
! kernel size should be enough, especially as this doesn't contain the
! buffer cache as in minix
!
! The loader has been made as simple as possible, and continuos
! read errors will result in a unbreakable loop. Reboot by hand. It
! loads pretty fast by getting whole sectors at a time whenever possible.

.globl begtext, begdata, begbss, endtext, enddata, endbss //表示定义了这些全局可见的，即链接器可以识别，外部程序可见
.text  //.text等是伪操作符，告诉编译器产生文本段，.text用于标识文本段的开始位置，
             //此处的.text .data .bss表明这三个段重叠，不分段
begtext:
.data
begdata:
.bss
begbss:
.text

SETUPLEN = 4				! nr（读） of setup-sectors   //boot 将要读后续setup扇区的个数
BOOTSEG  = 0x07c0			! original address of boot-sector  计算机上电完成后，BIOS把boot-sector读取到0x07c0:0x0000地址处
INITSEG  = 0x9000			! we move boot here - out of the way 将要把boot移动到0x9000:0x0000处
SETUPSEG = 0x9020			! setup starts here  将要吧setup扇区读取到0x9020:0x0000处
SYSSEG   = 0x1000			! system loaded at 0x10000 (65536). 将要吧system扇区读取到0x1000:0x0000处
ENDSEG   = SYSSEG + SYSSIZE		! where to stop loading

! ROOT_DEV:	0x000 - same type of floppy as boot.
!		0x301 - first partition on first drive etc
ROOT_DEV = 0x306

entry start //entry是一个伪指令，用来告诉编译器程序入口
start:
	mov	ax,#BOOTSEG
	mov	ds,ax // ds = 0x07c0
	mov	ax,#INITSEG
	mov	es,ax // es = 0x9000
	mov	cx,#256 //要读取的字长  一个字=两个字节 即为512个字节
	sub	si,si //si=0  ds:si = 0x7c00 源地址
	sub	di,di //di=0  es:di = 0x9000 目的地址
	rep
	movw  //开始搬动字
	jmpi	go,INITSEG //(jump intersegment)段间跳转 IP=go  CS=INITSEG 然后跳转到CS:IP
go:	mov	ax,cs //cs = 0x9000
	mov	ds,ax
	mov	es,ax
! put stack at 0x9ff00.
	mov	ss,ax
	mov	sp,#0xFF00		! arbitrary value >>512

! load the setup-sectors directly after the bootblock.//下面的代码是吧setup-sector放到bootblock后面
! Note that 'es' is already set up.//ex已经设置好了

load_setup:
	mov	dx,#0x0000		! drive 0, head 0  //dl=驱动器号  dh=磁头号
	mov	cx,#0x0002		! sector 2, track 0  //cl=开始扇区 ch=柱面号
	mov	bx,#0x0200		! address = 512, in INITSEG //ex:bx=读取到这个地址  ex=INITSEG的 bx=512，即把setup读取到紧接着boot之后
	mov	ax,#0x0200+SETUPLEN	! service 2, nr of sectors //al=扇区数量（SETUPLEN） ah=0x02-读磁盘
	int	0x13			! read it BIOS读磁盘中断调用
	jnc	ok_load_setup		! ok - continue
	mov	dx,#0x0000
	mov	ax,#0x0000		! reset the diskette 复位
	int	0x13
	j	load_setup

ok_load_setup:

! Get disk drive parameters, specifically nr of sectors/track

	mov	dl,#0x00
	mov	ax,#0x0800		! AH=8 is get drive parameters
	int	0x13
	mov	ch,#0x00
	seg cs       //见当前目录下的about_seg.md介绍
	mov	sectors,cx
	mov	ax,#INITSEG
	mov	es,ax

! Print some inane message

	mov	ah,#0x03		! read cursor pos  读取光标位置
	xor	bh,bh
	int	0x10
	
	mov	cx,#24       //字符串的长度
	mov	bx,#0x0007		! page 0, attribute 7 (normal) 这是配置INT10的视频页和属性值
	mov	bp,#msg1        //ES:BP 字符串的段:偏移地址
	mov	ax,#0x1301		! write string, move cursor ah=13-写字符串 al=01-移动光标
	int	0x10                       //调用bios中断显示INITSEG:masg1处的字符串，上面的都算参数

! ok, we've written the message, now
! we want to load the system (at 0x10000)

	mov	ax,#SYSSEG
	mov	es,ax		! segment of 0x010000
	call	read_it
	call	kill_motor

! After that we check which root-device to use. If the device is
! defined (!= 0), nothing is done and the given device is used.
! Otherwise, either /dev/PS0 (2,28) or /dev/at0 (2,8), depending
! on the number of sectors that the BIOS reports currently.

	seg cs
	mov	ax,root_dev
	cmp	ax,#0
	jne	root_defined
	seg cs
	mov	bx,sectors
	mov	ax,#0x0208		! /dev/ps0 - 1.2Mb
	cmp	bx,#15
	je	root_defined
	mov	ax,#0x021c		! /dev/PS0 - 1.44Mb
	cmp	bx,#18
	je	root_defined
undef_root:
	jmp undef_root
root_defined:
	seg cs
	mov	root_dev,ax

! after that (everyting loaded), we jump to
! the setup-routine loaded directly after
! the bootblock:

	jmpi	0,SETUPSEG  //boot过程全部完成，跳转到setup.s

! This routine loads the system at address 0x10000, making sure
! no 64kB boundaries are crossed. We try to load it as fast as
! possible, loading whole tracks whenever we can.
!
! in:	es - starting address segment (normally 0x1000)
!
sread:	.word 1+SETUPLEN	! sectors read of current track
head:	.word 0			! current head
track:	.word 0			! current track

read_it:
	mov ax,es
	test ax,#0x0fff
die:	jne die			! es must be at 64kB boundary
	xor bx,bx		! bx is starting address within segment
rp_read:
	mov ax,es
	cmp ax,#ENDSEG		! have we loaded all yet?
	jb ok1_read
	ret
ok1_read:
	seg cs
	mov ax,sectors
	sub ax,sread
	mov cx,ax
	shl cx,#9
	add cx,bx
	jnc ok2_read
	je ok2_read
	xor ax,ax
	sub ax,bx
	shr ax,#9
ok2_read:
	call read_track
	mov cx,ax
	add ax,sread
	seg cs
	cmp ax,sectors
	jne ok3_read
	mov ax,#1
	sub ax,head
	jne ok4_read
	inc track
ok4_read:
	mov head,ax
	xor ax,ax
ok3_read:
	mov sread,ax
	shl cx,#9
	add bx,cx
	jnc rp_read
	mov ax,es
	add ax,#0x1000
	mov es,ax
	xor bx,bx
	jmp rp_read

read_track:
	push ax
	push bx
	push cx
	push dx
	mov dx,track
	mov cx,sread
	inc cx
	mov ch,dl
	mov dx,head
	mov dh,dl
	mov dl,#0
	and dx,#0x0100
	mov ah,#2
	int 0x13
	jc bad_rt
	pop dx
	pop cx
	pop bx
	pop ax
	ret
bad_rt:	mov ax,#0
	mov dx,#0
	int 0x13
	pop dx
	pop cx
	pop bx
	pop ax
	jmp read_track

/*
 * This procedure turns off the floppy drive motor, so
 * that we enter the kernel in a known state, and
 * don't have to worry about it later.
 */
kill_motor:
	push dx
	mov dx,#0x3f2
	mov al,#0
	outb
	pop dx
	ret

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Loading system ..."
	.byte 13,10,13,10

.org 508
root_dev:
	.word ROOT_DEV
boot_flag:
	.word 0xAA55    //512个字节最后两个，一定要设置为0x55 和0xAA ，bios才能识别boot为引导代码

.text
endtext:
.data
enddata:
.bss
endbss:
