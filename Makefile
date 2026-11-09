NAME =  woody_woodpacker
CC = gcc
AS = nasm 
CFLAGS = -Wall -Werror -Wextra -g3 #-fsanitize=address
ASFLAGS = -f elf64 
RM = rm -f

SRC = src/main.c
OBJ = $(SRC.c=.o)

PAYLOAD_SRC = src/stubs/payload.s 
PAYLOAD_OBJ = src/stubs/payload.o	
PAYLOAD_BIN = src/stubs/payload.bin
PAYLOAD_HDR = src/stubs/payload.h

all: $(NAME)

$(NAME): $(OBJ) $(PAYLOAD_OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(NAME)

$(PAYLOAD_OBJ): $(PAYLOAD_SRC)
	$(AS) $(ASFLAGS) $(PAYLOAD_SRC) -o $(PAYLOAD_OBJ)

$(PAYLOAD_BIN): $(PAYLOAD_OBJ)
	objcopy -o binary $(PAYLOAD_OBJ) $(PAYLOAD_BIN)

$(PAYLOAD_HDR): $(PAYLOAD_BIN)
	xxd -i $(PAYLOAD_BIN) > $(PAYLOAD_HDR)

src/injector.o: src/injector.c $(PAYLOAD_HDR)
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) $(OBJ) $(PAYLOAD_OBJ) $(PAYLOAD_BIN) $(PAYLOAD_HDR)

fclean: clean
	S(RM) $(NAME)

re: fclean all

.PHONY: all clean fclean re
