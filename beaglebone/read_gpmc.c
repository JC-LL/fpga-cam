#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>

#define MEM_BASE_ADDR	 0x09000000


int main(int argc, char ** argv){
	int fd ;
	int i, page_size ;
	volatile unsigned short * gpmc_pointer ; 
	unsigned short dummy_data [256] ;
	for(i = 0 ; i < 256 ; i ++){
		dummy_data[i] = 0 ;
	}

	fd = open("/dev/mem", O_RDWR | O_SYNC);
	if(fd == -1){
		perror("Error opening file");
		printf("error opening /dev/mem \n");
		exit(EXIT_FAILURE);
	}


	page_size = getpagesize();
	printf("page size is : %d \n", page_size);
	//sleep(1);
	gpmc_pointer = (volatile unsigned short *) mmap(0, page_size, 
PROT_READ | 
	PROT_WRITE, 
	MAP_SHARED ,fd, 
	MEM_BASE_ADDR);
	if(gpmc_pointer == -1){
		printf("cannot allocate pointer on %x \n", MEM_BASE_ADDR);
		exit(EXIT_FAILURE);
	}
	printf("pointer allocated with address %x \n", gpmc_pointer);
	memcpy((void *) dummy_data, (void *) &gpmc_pointer[1], 255 * 
sizeof(unsigned short));
	for( i = 0 ; i < 255 ; i ++ ){
		printf("%d \n ", dummy_data[i]);	
	}
	printf("\n");	
	
	munmap((void *) gpmc_pointer, page_size);
	close(fd);
	return 0 ;
}
