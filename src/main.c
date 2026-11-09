#include "../incl/woody.h"

int main(int argc, char **argv)
{
    t_woody *woody;

    if (argc != 2)
    {
        printf("[ERROR:] Usage: ./woody_woodpacker <elf64>\n");
        return (0);
    }

    woody = malloc(sizeof(t_woody));
    if (!woody)
        return (1);

    if (ft_is_valid_elf64(woody, argv[1]) == -1)
    {
        printf("[ERROR] File architecture not supported. x86_64 only\n");
        return (0);
    }
    return (0);
}