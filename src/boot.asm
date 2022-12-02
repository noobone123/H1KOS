[org 0x7c00] ; 代码在内存中的位置

; 设置屏幕模式为文本模式，清除屏幕
mov ax, 3
int 0x10

; 初始化段寄存器
mov ax, 0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00

mov si, booting
call print

mov edi, 0x1000; 读取到的目标内存
mov ecx, 0; 起始扇区
mov bl, 1; 扇区数量
call read_disk

mov edi, 0x1000;
mov ecx, 2
mov bl, 1
call write_disk

jmp $ ; 阻塞

read_disk:
    ; 设置读写扇区数量
    mov dx, 0x1f2;
    mov al, bl
    out dx, al
    ; 设置读写扇区起始位置
    mov dx, 0x1f3 ; 低 8 位
    mov al, cl
    out dx, al

    mov dx, 0x1f4 ; 中 8 位
    shr ecx, 8
    mov al, cl
    out dx, al

    mov dx, 0x1f5 ; 高 8 位
    shr ecx, 8
    mov al, cl
    out dx, al

    mov dx, 0x1f6 ; LBA 模式 
    shr ecx, 8
    and cl, 0b00001111
    mov al, 0b11100000
    or al, cl
    out dx, al

    ; 读硬盘
    mov dx, 0x1f7;
    mov al, 0x20;
    out dx, al

    xor ecx, ecx;
    mov cl, bl; 获取读取扇区数量

    .read:
        push cx
        call .waits ; 等待数据准备好
        call .reads ; 读取一个扇区
        pop cx
        ret
    
    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret

    .reads:
        mov dx, 0x1f0
        mov cx, 256; 一个扇区有 512 字节（256 个字）
        .readw:
            in ax, dx
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            mov [edi], ax
            add edi, 2
            loop .readw
        ret

write_disk:
    ; 设置读写扇区数量
    mov dx, 0x1f2;
    mov al, bl
    out dx, al
    ; 设置读写扇区起始位置
    mov dx, 0x1f3 ; 低 8 位
    mov al, cl
    out dx, al

    mov dx, 0x1f4 ; 中 8 位
    shr ecx, 8
    mov al, cl
    out dx, al

    mov dx, 0x1f5 ; 高 8 位
    shr ecx, 8
    mov al, cl
    out dx, al

    mov dx, 0x1f6 ; LBA 模式 
    shr ecx, 8
    and cl, 0b00001111
    mov al, 0b11100000
    or al, cl
    out dx, al

    ; 写硬盘
    mov dx, 0x1f7;
    mov al, 0x30;
    out dx, al

    xor ecx, ecx;
    mov cl, bl; 获取读写扇区数量

    .write:
        push cx
        call .writes ; 写入一个扇区
        call .waits ; 等待数据繁忙结束
        pop cx
        ret
    
    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            and al, 0b1000_0000
            cmp al, 0b0000_0000
            jnz .check
        ret

    .writes:
        mov dx, 0x1f0
        mov cx, 256; 一个扇区有 512 字节（256 个字）
        .writew:
            mov ax, [edi]
            out dx, ax
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            jmp $+2; nop; 消耗一些时钟周期
            add edi, 2
            loop .writew
        ret

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done
    ret

booting:
    db "Booting H1KOS ...", 10, 13, 0; \n\r

; 主引导扇区必须有 512 字节
; 填充为 0
times 510 - ($ - $$) db 0

; 主引导结束标志
; dw 0xaa55
db 0x55, 0xaa
