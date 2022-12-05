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
mov ecx, 2; 起始扇区
mov bl, 4; 扇区数量
call read_disk

cmp word [0x1000], 0x55aa
jnz error
jmp 0:0x1002

; jmp $

read_disk:

    ; 设置读写扇区的数量
    mov dx, 0x1f2
    mov al, bl
    out dx, al

    inc dx; 0x1f3
    mov al, cl; 起始扇区的前八位
    out dx, al

    inc dx; 0x1f4
    shr ecx, 8
    mov al, cl; 起始扇区的中八位
    out dx, al

    inc dx; 0x1f5
    shr ecx, 8
    mov al, cl; 起始扇区的高八位
    out dx, al

    inc dx; 0x1f6
    shr ecx, 8
    and cl, 0b1111; 将高四位置为 0

    mov al, 0b1110_0000;
    or al, cl
    out dx, al; 主盘 - LBA 模式

    inc dx; 0x1f7
    mov al, 0x20; 读硬盘
    out dx, al

    xor ecx, ecx; 将 ecx 清空
    mov cl, bl; 得到读写扇区的数量

    .read:
        push cx; 保存 cx
        call .waits; 等待数据准备完毕
        call .reads; 读取一个扇区
        pop cx; 恢复 cx
        loop .read

    ret

    .waits:
        mov dx, 0x1f7
        .check:
            in al, dx
            jmp $+2; nop 直接跳转到下一行
            jmp $+2; 一点点延迟
            jmp $+2
            and al, 0b1000_1000
            cmp al, 0b0000_1000
            jnz .check
        ret

    .reads:
        mov dx, 0x1f0
        mov cx, 256; 一个扇区 256 字
        .readw:
            in ax, dx
            jmp $+2; 一点点延迟
            jmp $+2
            jmp $+2
            mov [edi], ax
            add edi, 2
            loop .readw
        ret

; write_disk:
;     ; 设置读写扇区数量
;     mov dx, 0x1f2;
;     mov al, bl
;     out dx, al
;     ; 设置读写扇区起始位置
;     mov dx, 0x1f3 ; 低 8 位
;     mov al, cl
;     out dx, al

;     mov dx, 0x1f4 ; 中 8 位
;     shr ecx, 8
;     mov al, cl
;     out dx, al

;     mov dx, 0x1f5 ; 高 8 位
;     shr ecx, 8
;     mov al, cl
;     out dx, al

;     mov dx, 0x1f6 ; LBA 模式 
;     shr ecx, 8
;     and cl, 0b00001111
;     mov al, 0b11100000
;     or al, cl
;     out dx, al

;     ; 写硬盘
;     mov dx, 0x1f7;
;     mov al, 0x30;
;     out dx, al

;     xor ecx, ecx;
;     mov cl, bl; 获取读写扇区数量

;     .write:
;         push cx
;         call .writes ; 写入一个扇区
;         call .waits ; 等待数据繁忙结束
;         pop cx
;         ret
    
;     .waits:
;         mov dx, 0x1f7
;         .check:
;             in al, dx
;             jmp $+2; nop; 消耗一些时钟周期
;             jmp $+2; nop; 消耗一些时钟周期
;             jmp $+2; nop; 消耗一些时钟周期
;             and al, 0b1000_0000
;             cmp al, 0b0000_0000
;             jnz .check
;         ret

;     .writes:
;         mov dx, 0x1f0
;         mov cx, 256; 一个扇区有 512 字节（256 个字）
;         .writew:
;             mov ax, [edi]
;             out dx, ax
;             jmp $+2; nop; 消耗一些时钟周期
;             jmp $+2; nop; 消耗一些时钟周期
;             jmp $+2; nop; 消耗一些时钟周期
;             add edi, 2
;             loop .writew
;         ret

print:
    mov ah, 0x0e
.next:
    mov al, [si]
    cmp al, 0
    jz .done
    int 0x10
    inc si
    jmp .next
.done:
    ret

booting:
    db "Booting H1KOS ...", 10, 13, 0; \n\r

error:
    mov si, .msg
    call print
    hlt
    jmp $
    .msg db "Booting Error!", 10, 13, 0


; 主引导扇区必须有 512 字节
; 填充为 0
times 510 - ($ - $$) db 0

; 主引导结束标志
; dw 0xaa55
db 0x55, 0xaa