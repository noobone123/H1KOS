all: boot.bin main.img

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

main.img: boot.bin
	qemu-img create -f raw -o size=32M main.img
	dd if=boot.bin of=main.img bs=512 count=1 conv=notrunc

.PHONY: clean # means the Makefile has nothing to do with a file called "clean" 
clean:
	rm -rf *.bin
	rm -rf *.img