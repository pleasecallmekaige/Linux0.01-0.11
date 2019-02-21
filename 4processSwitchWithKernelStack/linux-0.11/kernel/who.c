/*
 *  linux/kernel/who.c
 *
 *  (C) 2019  pleasecallmekaige
 */

/*
 *
 */

#include <linux/kernel.h>
//#include <linux/sched.h>
#include <asm/segment.h>

//void sys_sync(void);	/* it's really int */
namek[24] = {0};

int sizeofk(const char *name)
{
	char * s_addr  = name;
	int count  = 0;
	while('\0' != get_fs_byte(s_addr))
	{
		++count;
		++s_addr;
	}
	return count;
}
int sizeofs(const char *name)
{
	char * s_addr  = name;
	int count  = 0;
	while('\0' != *s_addr)
	{
		++count;
		++s_addr;
	}
	return count;
}
void clearnamek()
{
	int i=0;
	for(i=0;i<24;i++)
	{
		namek[i]=0;
	}
}

int sys_iam(const char *name)
{
	char * s_addr  = name;         //源地址 用户空间地址
	char * d_addr = namek;       //目的地址 内核空间地址
	int count = sizeofk(name);  //用户空间字符个数 不能大于23个
	if(count > 23)
	{
		printk("eorr:number of char > 23\n");
		return -1;
	}
	clearnamek();
	while('\0' != get_fs_byte(s_addr))
	{
		*d_addr = get_fs_byte(s_addr);
		++s_addr;
		++d_addr;
	}
	return count;
}

int sys_whoami(char *name, unsigned int size)
{
	char * s_addr  = namek;          //源地址 内核空间地址
	char * d_addr = name;          //目的地址 用户空间地址
	int count = sizeofs(namek);     //内核空间字符个数  （+1）不能大于size个
	if((count+1) > size)
	{
		printk("eorr:size is too small!\n");
		return -1;
	}
	while('\0' != *s_addr)
	{
		put_fs_byte(*s_addr,d_addr );
		++s_addr;
		++d_addr;
	}
	put_fs_byte(*s_addr,d_addr );
	return count;
}
