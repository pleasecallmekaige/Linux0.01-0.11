!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!

! NOTE! These had better be the same as in bootsect.s!

INITSEG  = 0x9000	! we move boot here - out of the way
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020	! this is the current segment

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
start:
###############################################################
	!设置附加数据段寄存器ES的值指向SETUPSEG，以便可以正常显示字符串数据
	mov ax, #SETUPSEG
	mov	es,ax

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#23
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#msg
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

###############################################################
! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.
! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Get video-card data:

	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

! check for EGA/VGA and some config parameters

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx

! Get hd0 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x41]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080
	mov	cx,#0x10
	rep
	movsb

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x46]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	rep
	movsb

! Check that there IS a hd1 :-)

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1
	cmp	ah,#3
	je	is_disk1
no_disk1:
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb
is_disk1:

###############################################################
	!设置附加数据段寄存器ES的值指向SETUPSEG，以便可以正常显示字符串数据
	mov ax, #SETUPSEG
	mov	es,ax

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#23
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#Mem_1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

	mov ax, #2			!set bp = 0x0000
	mov bp, ax
	call print_hex


	mov ax, #SETUPSEG
	mov	es,ax

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10

	mov	cx,#4
	mov	bx,#0x0007		! page 0, attribute 7 (normal)
	mov	bp,#Mem_2
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

###############################################################
death_loop:
	jmp death_loop


!以16进制方式打印栈顶的16位数
print_hex:
	mov cx, #4		!4个十六进制数字
	mov dx, (bp)	!将(bp)所指的值放入dx中，如果bp是指向栈顶的话
print_digital:
	rol dx, #4
	mov ax, #0xe0f
	and al, dl
	add al, #0x30
	cmp al, #0x3a
	jl outp
	add al, #0x07
outp:
	int 0x10
	loop print_digital
	ret

!打印回车换行
print_nl:
	mov ax, #0xe0d
	int 0x10
	mov al, #0xa
	int 0x10
	ret
##########################################################
Mem_1:
	.byte 13,10
	.ascii "Memory parameters is:"

Mem_2:
	.ascii "KB"
	.byte 13,10,13,10

msg:
	.byte 13,10
	.ascii "Now we are in SETUP"
	.byte 13,10

##########################################################

	
.text
endtext:
.data
enddata:
.bss
endbss:
