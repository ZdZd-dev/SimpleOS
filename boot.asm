bits 16
org 0x7c00

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00


    mov bx, 0x7E00
    mov ah, 0x02
    mov al, 32
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13
    jc .halt

    jmp 0x0000:0x7E00

.halt:
    jmp $

times 510-($-$$) db 0
dw 0xAA55