#ifndef WOODY_H
#define WOODY_H

# include <string.h>
# include <unistd.h>
# include <stdlib.h>
# include <stdio.h>
# include <stdint.h>
# include <elf.h>
# include <dirent.h>
# include <ctype.h>
# include <errno.h>
# include <fcntl.h>
# include <sys/stat.h>
# include <sys/mman.h>
# include <sys/types.h>
# include <sys/ptrace.h>

/*  STRUCT   */

typedef struct s_woosy
{
    int             fd;
    int             file_size;
    char            *strtab;
    const char      *binary;
    unsigned char   *elf;
    Elf64_Ehdr      *e_header;
    Elf64_Shdr      *s_header;
    struct stat     file_info;
    struct dirent   *read_dir;
}   t_woody;

/*  FUNCTIONS   */

int ft_is_valid_elf64(t_woody *woody, char *str);

#endif