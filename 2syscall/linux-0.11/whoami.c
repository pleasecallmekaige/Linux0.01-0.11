#define __LIBRARY__
#include <unistd.h>
#include <errno.h>


_syscall2(int, whoami, const char*, name, int ,size)

#define NAMELEN 100
char name[NAMELEN];

int main(int argc, char *argv[])
{
	int res;
	int namelen = 0;
	if (1 == argc) {
		res = whoami(name,100);
		printf("name:%s\n",name);
		if(res<0)
			errno = EINVAL;
		return res;
	}
}
