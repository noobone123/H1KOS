[bits 32]
global _start ; 将 _start 标记为全局符号，导出
_start:
    mov byte [0xb8000], 'K' ; 将字符 'K' 写入显存
    jmp $