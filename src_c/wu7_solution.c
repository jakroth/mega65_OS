#include "unit7.h"

u_int32_t p_start=0;
u_int32_t p_size=0;

u_int32_t f_reserved_sectors=0;
u_int32_t f_sectors_per_fat=0;
u_int32_t f_clusters=0;
unsigned char f_sectors_per_cluster=0;
u_int32_t f_fat1_sector=0;
u_int32_t f_fat2_sector=0;
u_int32_t f_rootdir_sector=0;
u_int32_t f_rootdir_cluster=0;
u_int32_t cluster_size=0;



// FUNCTION
u_int32_t extract_uint32(int offset)
{
  return sector_buffer[offset+0]
    +(sector_buffer[offset+1]<<8)
    +(sector_buffer[offset+2]<<16)
    +(sector_buffer[offset+3]<<24);
}



// FUNCTION
u_int32_t extract_uint16(int offset)
{
  return sector_buffer[offset+0]
    +(sector_buffer[offset+1]<<8);
}



// FUNCTION
void extract_filename(int offset, char *dest)
{
  // Extract 8.3 filename to a coherent string
  int o=0;
  for(int i=0;i<8;i++) dest[i]=sector_buffer[offset+i];
  o=8;
  while(o&&dest[o-1]==' ') o--;
  dest[o++]='.';
  for(int i=0;i<3;i++) dest[o++]=sector_buffer[offset+8+i];
  while(o&&dest[o-1]==' ') o--;
  dest[o]=0;
}


void print_sector(const u_int32_t sector_number){
	sdcard_readsector(sector_number);
	//print sector buffer

	printf("Sector Number: %d \n", sector_number);
	for(int i = 0; i < 32; i++){
		printf("%08X : ",i*16);
		for(int j = 0; j < 16; j++){
			printf("%02X ",sector_buffer[i*16+j]);
		}
		printf("\n");
	}
	printf("\n");
}


void print_fat_sectors(){
	for(int i=0;i<20;i++){	
		printf("FAT1 Sector: %d \n", i); 
		print_sector(f_fat1_sector+i); 
	}	
}

// FUNCTION
void wu7_examine_file_system(void)
{
  // XXX - First, read the Master Boot Record, which is in the first sector of the disk.
  // Within that, find the partition entry that has a FAT32 partition in it (partition type
  // will be 0x0c), and then use extract_uint32() to get the start and size of the partition
  // into p_start and p_size.
  // Complexity guide: My solution was 6 lines long.

	sdcard_readsector(0);
	int fat32;
	for(int i=0x01c2;i<0x01fe;i+=0x10){
		if(sector_buffer[i]==0x0c) fat32 = i;
	}
	p_start = extract_uint32(fat32+0x04);
	p_size = extract_uint32(fat32+0x08);
	printf("The 1st partition (if any) is %ld sectors long.\n",extract_uint32(0x1be +0x0c));
	//The location of the 3rd partition entry in the MBR 
	//The offset of the LBS size filed in a Partition Entry
	

  // Then read the first sector of the FAT32 partition, and use extract_uint32(), extract_uint16()
  // or simply reading bytes from sector_buffer[] to get the values for:
  // f_sectors_per_fat, f_rootdir_cluster, f_reserved_sectors and f_sectors_per_cluster.
  // Then use those values to compute the values of f_fat1_Sector, f_fat2_sector, f_rootdir_sector
  // and f_clusters (this last one can be calculated simple as the number of sectors per fat multiplied
  // by the number of 32-bit values (i.e., 4 bytes long each) that can be packed into a 512 byte sector).
  // Complexity guide: My solution was 11 lines long.
	

	sdcard_readsector(p_start);	// == $0800 or 2048 // read this sector because this is p_start == the start of the FAT32 partition	
	//the rest of these values to lookup are obtained from wikipedia
	f_sectors_per_fat = extract_uint32(0x24); // 137 or 0xca ??does this change each time?
	f_rootdir_cluster = extract_uint32(0x2c); // 2
	f_reserved_sectors = extract_uint16(0x0e); // 568 or 0x238
	f_sectors_per_cluster = sector_buffer[0x0d]; // 8

	f_fat1_sector = p_start + f_reserved_sectors; // 2616 or 0xa38 // FAT = file allocation table, says which sector each file is in
	f_fat2_sector = f_fat1_sector + f_sectors_per_fat; // 2753 or 0xb02 ??does this change each time? based on sectors per fat
	f_rootdir_sector = f_fat2_sector + f_sectors_per_fat;  // 2890 or 0xc06
	f_clusters = f_sectors_per_fat * 128; // 128 == 512 (sector size) / 4 (fat entry) * 137 = 17536 FAT entries
	cluster_size = f_sectors_per_cluster * 512;  // cluster size in bytes. I think it is always 4096.
}



// GLOBAL VARIABLES
u_int32_t dir_sector=0;
u_int32_t dir_sector_offset=0;
u_int32_t dir_sector_max=0;



// FUNCTION
void my_opendir(void)
{
	// XXX - Use the three convenient variables above to point to the start of
  // the first sector of the root directory of the file system.
  // Then work out the last valid sector number of the directory.  This will
  // be the last sector in the cluster, as for simplicity, we are assuming
  // that the directory is only one cluster long.  You will thus need to know
  // how many sectors in a cluster, and add one less than that to the starting
  // sector of the root directory.
  // Complexity guide: My solution was 3 lines long.
	dir_sector=f_rootdir_sector;
	dir_sector_offset=0;
	dir_sector_max=dir_sector+f_sectors_per_cluster-1; // there are 8 sectors in a cluster ~ 2890 + 7 = 2897.
																										 // since root cluster is cluster#2, 2898 will be first sector in cluster#3. 
}



// GLOBAL VARIABLES
struct my_dirent return_structure;



// FUNCTION - returns the next directory entry (start of a file) in the root directory. Returned as a struct my_dirent
struct my_dirent *my_readdir(void)
{
  // XXX - First, find the next directory entry in the directory that is valid.
  // A valid directory entry has a file name in it that doesn't begin with the null
  // character or the special chartacter 0xe5 that is used to indicate a deleted file.
  // If you get to the end of a sector, you will need to read the next sector, and try
  // looking there.  Don't forget to use sdcard_readsector() to read the sector before
  // fishing around in sector_buffer[] for the bytes of the directory entry.  I suggest
  // that you use dir_sector_offset to keep track of the directory entry you are looking at.
  // You would abort by returning NULL if you reach the end of the directory, i.e.,
  // you go past the end of dir_sector_max.
  // Complexity guide: My solution was 11 lines long.
	
	int found = 0;
	while(dir_sector<dir_sector_max){ // check that we haven't reached the end of the cluster = root sector + 7 // I think this won't read the last sector
		sdcard_readsector(dir_sector);
		while(dir_sector_offset<0x0200){	// check that we haven't reached the end of the sector = 512 or 0x200
			if(sector_buffer[dir_sector_offset]!=0x00 || sector_buffer[dir_sector_offset]!=0xe5){  // check if there is a valid entry in this location
				found = 1;
			}
			if(found==1) break;
			dir_sector_offset+=0x20; // add 0x20 to offset, because each directory entry is 32 bytes long
		}
		if(found==1) break;
		dir_sector_offset=0;  // if a file is not found, start looking in the next sector in the cluster
		dir_sector++;
	}	
	if (found==0) return NULL;  	
	
  // At this point you have the directory entry located at offset dir_sector_offset in
  // sector_buffer[]. You can now use the convenience functions extract_uint32(), extract_uint16()
  // and extract_filename() that I have provided for you to extract the necessary values
  // into return_structure, where required. To get the attribs field, you don't need any of those,
  // because it is a single byte long. To get the cluster out, you will need to use extract_uint16()
  // on the two separate places where the halves of the cluster number are located, and then use
  // some addition and bit-shifting to combine the two halves to make a valid cluster number.
  // This is the trickiest part of this checkpoint.
  // Your solution will look like a series of return_structure.member=extract....() lines,
  // plus a call to extract_filename().
  // Complexity guide: My solution was 5 lines long.
	
	// extract the details in the directory entry
	extract_filename(dir_sector_offset,return_structure.name); 										// Filename 
	return_structure.length=extract_uint32(dir_sector_offset+0x1c);								// Length
	return_structure.attribs=sector_buffer[dir_sector_offset+0x0b];								// Attributes
	int tempcluster=extract_uint16(dir_sector_offset+0x14)<<16;										// High Cluster bytes (2 bytes) so 0x0000
	return_structure.cluster=tempcluster+extract_uint16(dir_sector_offset+0x1a);	// plus Low Cluster bytes (2 bytes) so 0x0000


  // XXX - Finally, advance dir_sector_offset (and dir_sector if the offset goes past the end of the sector), 
  // so that it is pointing at the next directory entry, ready for the next call to this function.
  // Complexity guide: My solution was 5 lines long.
	dir_sector_offset+=0x20;
	if(dir_sector_offset>=0x0200){
		dir_sector_offset=0;
		dir_sector++;
	}	
	
  // And really last of all, we return a pointer to the return_structure, which I have done for you here:
  return &return_structure;
}



// GLOBAL VARIABLES
u_int32_t file_cluster=-1;
u_int32_t cluster_offset=-1;
u_int32_t file_length_remaining=-1;



// FUNCTION
int my_open(char *filename)
{
  // XXX - First, find the file by using my_opendir() and my_readdir() to iterate through the directory. 
  // You will probably want to use some variable like struct my_dirent *de = NULL; and test if de->name is equal to the
  // filename that has been passed in.  strcmp() is a handy function for this.
  // Complexity guide: My solution was 5 lines long.
	printf("%s \n", "got here 1"); 
	my_opendir(); // resets the directory sector variable to the start of the root directory, and directory sector offset variable to 0 													
	struct my_dirent *de = my_readdir();						// returns the first valid file in the directory
	while(de!=NULL){											
		if (strcmp(de->name, filename)==0) break; 		// checks if the name of the file matches the filename parameter										
		de = my_readdir(); 														// iterates through the rest of the files
	}		
	
	printf("%s \n", "got here 2"); 
  // XXX - Next, abort if you couldn't find the file.  You can detect this
  // by seeing if my_readdir() has gotten to the end of the directory, and
  // stopped returning new directory entry structures.  You should return -1
  // in this case.
  // Complexity guide: My solution was 1 line long.
	if(my_readdir() == NULL) return -1;
	printf("%s \n", "got here 3"); 
	
  // XXX - Finally, record the cluster where the file begins, reset the offset in the cluster to zero, 
  // and set the remaining file length to the length field of the directory entry of the file. Then return 0 to indicate success.
  // You can stash these values in the three convenient variables that I have defined for you just before this function.
  // Complexity guide: My solution was 4 lines long.
	file_cluster=de->cluster;
	cluster_offset=0;
	file_length_remaining=de->length;
	printf("%s \n", "got here 4"); 
	return 0;
}



// FUNCTION
int my_read(unsigned char *buffer,int count)
{
  // XXX - First check that you have not reached the end of the file.
  // You should check both for illegal cluster values, and end of cluster chain values, as well as that 
  // you haven't reached the end of the file as reported by the file length field of the file's directory entry.
  // Complexity guide: My solution was 4 lines long.
  int offset=0;  // this is for the *buffer offset
  if (!file_cluster) return 0;
  if (file_cluster&0xf0000000) return 0;
  if (!file_length_remaining) return 0;
	printf("%s \n", "got here 5"); 

  // XXX - Now you know you aren't yet at the end of the file.
  // You need to read the file data one sector at a time, and output it into the buffer.  
  // To write data to a specific offset in the buffer, you can use something like:
  
  // bcopy(&sector_buffer[the offset in the sector buffer you want to read from],
  //       &buffer[the offset in the buffer you want to write to],
  //       the number of bytes you want to copy);
  
  // You need to remember to advance the sector each time, and to follow the
  // chain of clusters for the file from the FAT after you have read all the
  // sectors in the current cluster.  To get the checkpoint, you MUST demonstrate
  // in your code that you are reading the next cluster value from the FAT.
  // Complexity guide: My solution was 23 lines long.
  
  u_int32_t zero_sector = f_rootdir_sector - (8<<1); 	// this gets a theoretical cluster#0 sector, although this doesn't exist in the data region
		
	//printf("%s \n", "zero sector"); 																					 				// allows us to calculate the first sector of each cluster
	//print_sector(zero_sector); 
	//printf("%s \n", "rootdir_sector"); 	
	//print_sector(f_rootdir_sector);  

	u_int32_t start_sector;								// this will hold the first sector of each cluster, defined in the loop
	u_int32_t buffer_offset = 0;  				// this might be what int count does in the parameters...??
	u_int32_t fat_sector;									// this will hold the current FAT sector we are reading (there are 137 FAT sectors)
	u_int32_t fat_offset;									// this will hold the first byte of the entry within the FAT sector
	u_int32_t loop_count =0;
	u_int32_t bytes_read =0;
	file_cluster = file_cluster-0x80;  		// need this adjustment for some reason

	// Find the length of this file
	my_opendir(); // resets the directory sector variable to the start of the root directory, and directory sector offset variable to 0 													
	struct my_dirent *de = my_readdir();						// returns the first valid file in the directory
	while(1){											
		if (de->cluster==file_cluster) break; 				// checks if the file clusters match									
		de = my_readdir(); 														// iterates through the rest of the files
	}	
	file_length_remaining = de->length;


	printf("Cluster %08X \n", file_cluster);
	printf("File Length Remaining %08X \n", file_length_remaining);
	printf("Count Length  %08X \n", count);
	//print_sector(zero_sector+(file_cluster*8));		
	//printf("%s \n", "start sector + 7");		
	//print_sector(zero_sector+(file_cluster*8)+7);
	//printf("%s \n", "got here 6"); 
	while(loop_count<f_clusters){
		printf("%s \n", "loop start"); 
		start_sector = zero_sector + (file_cluster<<3); 	// finds the first sector in the cluster -- <<3 == *8  (cause 2^3) 

		while(cluster_offset<f_sectors_per_cluster){ 			// loop until we reach the end of the cluster -- usually 8 sectors
			sdcard_readsector(start_sector+cluster_offset); // read the sector at this cluster offset
			//printf("%s \n", "start_sector+cluster_offset");
			//print_sector(start_sector+cluster_offset); 
			
			if(file_length_remaining>=0x200){   												// checks to see if we should copy the whole 512 bytes in this sector
				printf("%s \n", "inner loop 1"); 
				//printf("%s \n", "inner loop 1"); 
				bcopy(&sector_buffer[0],&buffer[buffer_offset],0x200);  // copy a full sector to the buffer
				buffer_offset += 0x200;																	// advance the buffer by 1 full sector of bytes
				cluster_offset++;																				// advance cluster offset by 1 sector
				file_length_remaining-=0x200;														// reduce file size remaining
				bytes_read+=0x200;
			} else {   																	
				//printf("%s \n", "inner loop 2");
				bcopy(&sector_buffer[0],&buffer[buffer_offset],file_length_remaining); 	// or else just copies the remaining count
				buffer_offset += file_length_remaining;																	// advance the buffer by remaining count  																		
				bytes_read += file_length_remaining;	
				file_length_remaining = 0;			
				printf("%s \n", "exited in loop 2"); 
				return bytes_read;																	// this means we've read the whole file and can return success (0)											
			} 
		}
		cluster_offset=0;  	// Reset the cluster_offset to 0

		// Now we need to find the next cluster by reading the FAT
		// Each FAT sector holds 128 cluster entries (512 / 4)
		// So need to work out which FAT sector to read = file_cluster % 128
		//printf("%s \n", "FAT stuff start");
		fat_sector = f_fat1_sector + (file_cluster / 0x80); 									// so cluster 300 will be in fat sector 2 (with fat sectors starting at 0)
		//printf("FAT Sector: %08X \n", fat_sector); 
		fat_offset = (file_cluster % 0x80)<<2; 						// this will get the first byte of the cluster's FAT entry within the FAT table
		//printf("FAT Offset: %08X \n", fat_offset); 				// so for cluster 140 will be (140-128) * 4 == entry 12 * 4 == byte 48 (of 512)
		
		sdcard_readsector(fat_sector);
		//print_sector(fat_sector);
		file_cluster = sector_buffer[fat_offset]+									// lowest byte
										(sector_buffer[fat_offset+1]<<8)+				
										(sector_buffer[fat_offset+2]<<16)+
										((sector_buffer[fat_offset+3]&0xf)<<24);	// highest byte -- cause these are really 28 bit addresses, this might cause an issue
		
		printf("Cluster %08X \n", file_cluster); 
		//printf("%s \n", "FAT stuff end");
		if(file_cluster>0xffffff7){
			printf("%s \n", "exited here"); 		
			return bytes_read;											// this would represent an end of file marker, so return success (0)
		}
		loop_count++;
		//printf("Loop count: %ld\n", loop_count); 
	}
	printf("%s \n", "shouldn't get here"); 
}




// FUNCTION
struct my_dirent *my_findfile(char *name)
{
  // It's up to you whether you use these, but they are one way to hold the
  // path segments
#define MAX_LEVELS 16  
  char paths[MAX_LEVELS][16];
  int path_count=0;

  // XXX - Seperate out each path segment, which will be delineated by / or the end
  // of the string
  // Complexity guide: My solution was 12 lines long.
 

  // XXX - Now starting at the root directory, use my_readdir() to check each directory
  // entry to see if it matches the one you are looking for. If it matches, you need
  // to get the starting cluster of the sub-directory, and start iterating through that
  // in the same way. This is repeated until you find the file you are looking for.
  // At that point, you should return the directory entry structure that my_readdir()
  // gave you as the result.  If you can't find the file, you should return NULL instead.
  // Complexity guide: My solution was 23 lines long.
  
  return NULL;
}
