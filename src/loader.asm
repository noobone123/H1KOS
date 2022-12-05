[org 0x1000]

dw 0x55aa ; magic number, used to identify the loader

; 打印 loader 字符串
mov si, loading
call print

detect_memory:
    xor ebx, ebx
    
    ; es:di 保存结构体的缓存地址
    mov ax, 0
    mov es, ax  ; 段寄存器不能直接 mov 一个立即数进去
    mov edi, ards_buffer

    mov edx, 0x534d4150 ; 'SMAP'

.next
    mov eax, 0xe820
    mov ecx, 0x20
    int 0x15

    jc error

    add di, cx
    inc word [ards_cnt]

    cmp ebx, 0
    jnz .next

    mov si, detecting
    call print

    jmp prepare_protect_mode

prepare_protect_mode:
    cli;

    ; 打开 A20 地址线
    in al, 0x92
    or al, 0b10
    out 0x92, al

    ; 加载 GDT
    lgdt [gdt_ptr]; 加载 gdt
    
    ; 启动保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 使用跳转来刷新指令缓存，从而启用保护模式
    jmp dword code_selector:protect_mode

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

loading:
    db "Loading H1KOS ...", 10, 13, 0; \n\r

detecting:
    db "Detecting memory success ...", 10, 13, 0; \n\r

loading_error:
    db "Loading H1KOS error ...", 10, 13, 0; \n\r

detect_memory_error:
    db "Detecting memory error ...", 10, 13, 0; \n\r

error:
    mov si, loading_error
    call print
    hlt


[bits 32]
protect_mode:
    mov ax, data_selector
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax ; 初始化段寄存器
    mov esp, 0x10000 ; 初始化栈顶指针
    
    mov byte [0xb8000], 'P' ; 可以直接访问这里了内存了
    mov byte [0x200000], 'P'

jmp $


code_selector equ (1 << 3)
data_selector equ (2 << 3)

memory_base equ 0 ; 内存开始的位置，基地址
memory_limit equ ((1024 * 1024 * 1024 * 4) / (1024 * 4)) - 1 ; 内存界限，4G / 4K - 1

gdt_ptr:
    dw (gdt_end - gdt_base) - 1 ; gdt 的长度
    dd gdt_base ; gdt 的基地址
gdt_base:
    dd 0, 0; NULL 描述符
gdt_code:
    dw memory_limit & 0xffff; 段界限 0 ~ 15 位
    dw memory_base & 0xffff; 基地址 0 ~ 15 位
    db (memory_base >> 16) & 0xff; 基地址 16 ~ 23 位
    db 0b_1_00_1_1_0_1_0; P = 1, DPL = 0, S = 1, TYPE = 0b1010
    db 0b1_1_0_0_0000 | ((memory_limit >> 16) & 0xf); G = 1, D/B = 1, L = 0, AVL = 0, 段界限 16 ~ 19 位
    db (memory_base >> 24) & 0xff; 基地址 24 ~ 31 位
gdt_data:
    dw memory_limit & 0xffff; 段界限 0 ~ 15 位
    dw memory_base & 0xffff; 基地址 0 ~ 15 位
    db (memory_base >> 16) & 0xff; 基地址 16 ~ 23 位
    db 0b_1_00_1_0_0_1_0; P = 1, DPL = 0, S = 1, TYPE = 0b1010
    db 0b1_1_0_0_0000 | ((memory_limit >> 16) & 0xf); G = 1, D/B = 1, L = 0, AVL = 0, 段界限 16 ~ 19 位
    db (memory_base >> 24) & 0xff; 基地址 24 ~ 31 位
gdt_end:

ards_cnt:
    dw 0
ards_buffer:
