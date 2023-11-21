all: main

main: main.o
	ld -o $@ $^ -nostdlib -static

main.o: main.asm
	nasm -f elf64 $< -o $@

clean:
	rm -f *.o main