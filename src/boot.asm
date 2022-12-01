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

mov ax, 0xb800 ; 0xb800 文本显示器的内存区域
mov ds, ax
mov byte [0], 'W'

jmp $ ; 阻塞

; 主引导扇区必须有 512 字节
; 填充为 0
times 510 - ($ - $$) db 0

; 主引导结束标志
; dw 0xaa55
db 0x55, 0xaa
