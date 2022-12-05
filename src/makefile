BUILD:=../build
SRC:=.


$(BUILD)/boot/%.bin: $(SRC)/boot/%.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@


$(BUILD)/main.img: $(BUILD)/boot/boot.bin \
	$(BUILD)/boot/loader.bin

	qemu-img create -f raw -o size=32M $@
	dd if=$(BUILD)/boot/boot.bin of=$@ bs=512 count=1 conv=notrunc
	dd if=$(BUILD)/boot/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc

test: $(BUILD)/main.img

.PHONY: clean # means the Makefile has nothing to do with a file called "clean" 
clean:
	rm -rf $(BUILD)