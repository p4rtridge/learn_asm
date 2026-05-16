compile:
    nasm -f elf64 main.asm -o main.o && \
    ld -e _main main.o -o main

clean:
    rm -f main.o main