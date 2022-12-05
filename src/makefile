%.bin: %.asm
	nasm -f bin $< -o $@

main.img: boot.bin loader.bin
	qemu-img create -f raw -o size=32M main.img
	dd if=boot.bin of=main.img bs=512 count=1 conv=notrunc
	dd if=loader.bin of=main.img bs=512 count=4 seek=2 conv=notrunc

.PHONY: clean # means the Makefile has nothing to do with a file called "clean" 
clean:
	rm -rf *.bin
	rm -rf *.img