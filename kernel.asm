bits 16
org 0x7E00    ; Kernel loads at 0x7E00

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Clear screen
    mov ax, 0x0003
    int 0x10

    ; Show boot screen
    mov si, boot_screen
    call print_string

    ; Delay loop (~4–5 seconds)
    mov cx, 0x0010
.seconds_loop:
    push cx
    mov cx, 0xFFFF
.middle_loop:
    push cx
    mov cx, 0x0FFF
.inner_loop:
    nop
    nop
    nop
    nop
    nop
    nop
    loop .inner_loop
    pop cx
    loop .middle_loop
    pop cx
    loop .seconds_loop

    ; Redraw clean UI
    mov ax, 0x0003
    int 0x10
    call draw_border
    call draw_header
    
    ; Position cursor for content
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 4
    mov dl, 3
    int 0x10
    
    mov si, welcome_msg
    call print_string_wrapped
    
    call update_status
    
    ; Input prompt
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 22
    mov dl, 3
    int 0x10
    mov ah, 0x0E
    mov bh, 0x00
    mov al, '>'
    int 0x10
    mov al, ' '
    int 0x10

    jmp shell_loop

; === UI Functions ===

draw_border:
    pusha
    
    ; Top border
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0
    mov dl, 0
    int 0x10
    mov cx, 80
    mov ah, 0x0E
    mov al, 0xC4
.top:
    int 0x10
    loop .top
    
    ; Bottom border
    mov ah, 0x02
    mov dh, 24
    mov dl, 0
    int 0x10
    mov cx, 80
    mov ah, 0x0E
    mov al, 0xC4
.bottom:
    int 0x10
    loop .bottom
    
    ; Side borders
    mov dh, 1
.sides:
    cmp dh, 24
    jge .corners
    
    mov ah, 0x02
    mov dl, 0
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3
    int 0x10
    
    mov ah, 0x02
    mov dl, 79
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3
    int 0x10
    
    inc dh
    jmp .sides

.corners:
    ; Corners
    mov ah, 0x02
    mov dh, 0
    mov dl, 0
    int 0x10
    mov ah, 0x0E
    mov al, 0xDA
    int 0x10
    
    mov ah, 0x02
    mov dl, 79
    int 0x10
    mov ah, 0x0E
    mov al, 0xBF
    int 0x10
    
    mov ah, 0x02
    mov dh, 24
    mov dl, 0
    int 0x10
    mov ah, 0x0E
    mov al, 0xC0
    int 0x10
    
    mov ah, 0x02
    mov dl, 79
    int 0x10
    mov ah, 0x0E
    mov al, 0xD9
    int 0x10
    
    popa
    ret

draw_header:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 1
    mov dl, 2
    int 0x10
    
    mov si, header_title
    call print_string_centered
    
    mov ah, 0x02
    mov dh, 2
    mov dl, 2
    int 0x10
    mov cx, 76
    mov ah, 0x0E
    mov al, 0xC4
.separator:
    int 0x10
    loop .separator
    
    popa
    ret

update_status:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 24
    mov dl, 2
    int 0x10
    
    mov si, status_left
    call print_string
    
    mov cx, 76
    sub cx, status_left_len
.clear_loop:
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    loop .clear_loop
    
    mov ah, 0x02
    mov dl, 60
    int 0x10
    
    mov ah, 0x02
    int 0x1A
    jc .no_time
    
    mov al, ch
    call print_bcd
    mov al, ':'
    mov ah, 0x0E
    int 0x10
    mov al, cl
    call print_bcd
    jmp .done
    
.no_time:
    mov si, no_time_msg
    call print_string
    
.done:
    popa
    ret

; === Printing ===

print_string_wrapped:
    pusha
    mov bx, 3
    mov dh, [current_line]
.wrap_loop:
    lodsb
    test al, al
    jz .wrap_done
    
    cmp al, 13
    je .newline
    cmp al, 10
    je .newline
    
    cmp bx, 77
    jl .print_char
    
    call .newline_no_inc
    jmp .wrap_loop

.print_char:
    mov ah, 0x0E
    mov bh, 0x00
    int 0x10
    inc bx
    jmp .wrap_loop

.newline:
    call .newline_no_inc
    jmp .wrap_loop

.newline_no_inc:
    inc dh
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 3
    int 0x10
    mov bx, 3
    mov [current_line], dh
    ret

.wrap_done:
    mov [current_line], dh
    popa
    ret

print_string_centered:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 25
    int 0x10
    call print_string
    popa
    ret

print_string:
    mov ah, 0x0E
    mov bh, 0x00
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; === String comparison ===

compare_string:
    push si
    push di
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_equal
    test al, al
    jz .equal
    inc si
    inc di
    jmp .loop
.equal:
    mov ax, 1
    pop di
    pop si
    ret
.not_equal:
    mov ax, 0
    pop di
    pop si
    ret

; === Reboot ===

reboot_system:
    mov si, reboot_msg
    call print_string_wrapped
    
    mov cx, 0xFFFF
.delay:
    nop
    loop .delay
    
    int 0x19
    mov al, 0xFE
    out 0x64, al
    
    mov ax, 0
    mov ds, ax
    mov [0], ax
    jmp 0xFFFF:0x0000
    ret

; === Time Display ===

show_time:
    mov ah, 0x02
    int 0x1A
    jc .time_error
    
    mov si, time_msg
    call print_string_wrapped
    
    mov al, ch
    call print_bcd
    mov ah, 0x0E
    mov al, ':'
    int 0x10
    mov al, cl
    call print_bcd
    ret

.time_error:
    mov si, time_error_msg
    call print_string_wrapped
    ret

print_bcd:
    push ax
    mov bl, al
    shr al, 4
    add al, '0'
    mov ah, 0x0E
    int 0x10
    mov al, bl
    and al, 0x0F
    add al, '0'
    int 0x10
    pop ax
    ret

; === Clear Content Area ===

clear_content_area:
    pusha
    mov cx, 18
    mov dh, 4
.clear_lines:
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 3
    int 0x10
    
    mov bx, 76
.clear_line:
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    dec bx
    jnz .clear_line
    
    inc dh
    loop .clear_lines
    
    mov byte [current_line], 4
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 4
    mov dl, 3
    int 0x10
    popa
    ret

; === Calculator ===

calculator:
    call clear_content_area
    mov si, calc_welcome
    call print_string_wrapped
    
.calc_loop:
    mov di, calc_buffer
    mov cx, 32
.clear_buffer:
    mov byte [di], 0
    inc di
    loop .clear_buffer
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 3
    int 0x10
    mov cx, 74
.clear_input_line:
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    loop .clear_input_line
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 3
    int 0x10
    mov si, calc_prompt
    call print_string
    
    mov di, calc_buffer
    call read_calc_string
    
    mov si, calc_buffer
    mov di, calc_exit_cmd
    call compare_string
    cmp ax, 1
    je .calc_done
    
    call process_calculation
    jmp .calc_loop

.calc_done:
    call clear_content_area
    ret

read_calc_string:
    mov cx, 0
    mov di, calc_buffer
    mov byte [di], 0
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 9
    int 0x10
    
.input_loop:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D
    je .done
    cmp al, 0x08
    je .backspace
    
    mov bx, cx
    add bx, 9
    cmp bx, 77
    jge .input_loop
    
    mov [di], al
    inc di
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .input_loop

.backspace:
    test cx, cx
    jz .input_loop
    dec di
    dec cx
    mov byte [di], 0
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .input_loop

.done:
    mov byte [di], 0
    ret

; === Calculator Processing ===

process_calculation:
    mov si, calc_buffer
    call parse_number
    mov [num1], ax
    
.find_op:
    lodsb
    cmp al, ' '
    je .find_op
    cmp al, '+'
    je .add
    cmp al, '-'
    je .subtract
    cmp al, '*'
    je .multiply
    cmp al, 'x'
    je .multiply
    cmp al, 'X'
    je .multiply
    cmp al, '/'
    je .divide
    cmp al, 0
    je .show_single
    jmp .invalid

.add:
    call parse_number
    add [num1], ax
    jmp .show_result

.subtract:
    call parse_number
    sub [num1], ax
    jmp .show_result

.multiply:
    call parse_number
    mov bx, ax
    mov ax, [num1]
    mul bx
    mov [num1], ax
    jmp .show_result

.divide:
    call parse_number
    mov bx, ax
    cmp bx, 0
    je .division_error
    
    mov ax, [num1]
    mov dx, 0
    div bx
    mov [num1], ax
    mov [remainder], dx
    jmp .show_division_result

.division_error:
    mov si, division_error_msg
    call print_string_wrapped
    ret

.show_single:
    jmp .show_result

.show_division_result:
    mov cx, 14
    mov dh, 8
.clear_results:
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 3
    int 0x10
    
    mov bx, 74
.clear_line:
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    dec bx
    jnz .clear_line
    inc dh
    loop .clear_results
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 8
    mov dl, 3
    int 0x10
    mov si, calc_division_result
    call print_string
    mov ax, [num1]
    call print_number
    
    mov ax, [remainder]
    cmp ax, 0
    je .done_division

; Show remainder
mov ah, 0x02
mov bh, 0x00
mov dh, 9
mov dl, 3
int 0x10
mov si, calc_remainder
call print_string
mov ax, [remainder]
call print_number

.done_division:
ret

.show_result:
; Clear previous result area
mov cx, 14
mov dh, 8
.clear_results2:
mov ah, 0x02
mov bh, 0x00
mov dl, 3
int 0x10

mov bx, 74
.clear_line2:
mov ah, 0x0E
mov al, ' '
int 0x10
dec bx
jnz .clear_line2
inc dh
loop .clear_results2

; Display result
mov ah, 0x02
mov bh, 0x00
mov dh, 8
mov dl, 3
int 0x10
mov si, calc_result
call print_string
mov ax, [num1]
call print_number
ret

.invalid:
mov si, calc_invalid
call print_string_wrapped
ret

; Parse number from string (SI)
parse_number:
mov word [temp_num], 0
.skip_spaces:
mov al, [si]
cmp al, ' '
jne .parse_loop
inc si
jmp .skip_spaces
.parse_loop:
lodsb
test al, al
jz .parse_done
cmp al, ' '
je .parse_done
cmp al, '0'
jb .parse_done
cmp al, '9'
ja .parse_done
sub al, '0'
mov bx, ax
mov ax, [temp_num]
mov cx, 10
mul cx
add ax, bx
mov [temp_num], ax
jmp .parse_loop
.parse_done:
mov ax, [temp_num]
ret

; Print number in AX
print_number:
pusha
mov cx, 0
mov bx, 10
.convert_loop:
mov dx, 0
div bx
push dx
inc cx
test ax, ax
jnz .convert_loop
.print_loop:
pop ax
add al, '0'
mov ah, 0x0E
int 0x10
loop .print_loop
popa
ret

; SIMPLE TYPING GAME
type_game_handler:
call typing_game
jmp shell_loop.prompt

typing_game:
call clear_content_area

; Show instructions
mov si, type_instructions
call print_string_wrapped

; Wait for key to start
mov ah, 0x00
int 0x16

call clear_content_area

; Initialize game
mov word [type_score], 0
mov byte [type_lives], 3
mov byte [current_word_pos], 0

; Game loop
type_main_loop:
call type_display_game
call type_get_input

; Check if game over
cmp byte [type_lives], 0
jle type_game_over

jmp type_main_loop

type_game_over:
call clear_content_area
mov si, type_game_over_msg
call print_string_wrapped

; Display final score
mov ah, 0x02
mov bh, 0x00
mov dh, 8
mov dl, 3
int 0x10

mov si, type_final_score
call print_string
mov ax, [type_score]
call print_number

mov ah, 0x00
int 0x16
ret

; Display typing game screen
type_display_game:
pusha

; Clear game area
mov cx, 12
mov dh, 7
type_clear_area:
mov ah, 0x02
mov bh, 0x00
mov dl, 10
int 0x10

mov bx, 61
type_clear_line:
mov ah, 0x0E
mov al, ' '
int 0x10
dec bx
jnz type_clear_line
inc dh
loop type_clear_area

; Display score and lives
mov ah, 0x02
mov bh, 0x00
mov dh, 7
mov dl, 10
int 0x10

mov si, type_score_msg
call print_string
mov ax, [type_score]
call print_number

mov ah, 0x02
mov bh, 0x00
mov dh, 7
mov dl, 40
int 0x10

mov si, type_lives_msg
call print_string
mov al, [type_lives]
add al, '0'
mov ah, 0x0E
int 0x10

; Display current word
mov ah, 0x02
mov bh, 0x00
mov dh, 10
mov dl, 25
int 0x10

; Get current word
mov si, type_words
mov al, [current_word_pos]
mov bl, 6
mul bl
add si, ax
call print_string

; Display input prompt
mov ah, 0x02
mov bh, 0x00
mov dh, 12
mov dl, 10
int 0x10

mov si, type_prompt
call print_string

popa
ret

; Get typing input
type_get_input:
pusha

; Position cursor after prompt
mov ah, 0x02
mov bh, 0x00
mov dh, 12
mov dl, 17
int 0x10

; Read input
mov di, type_buffer
mov cx, 0
type_input_main:
mov ah, 0x00
int 0x16

cmp al, 0x0D
je type_check_input

cmp al, 0x08
je type_handle_backspace

cmp cx, 15
jge type_input_main

mov [di], al
inc di
inc cx
mov ah, 0x0E
int 0x10
jmp type_input_main

type_handle_backspace:
cmp cx, 0
je type_input_main
dec di
dec cx
mov byte [di], 0
mov ah, 0x0E
mov al, 0x08
int 0x10
mov al, ' '
int 0x10
mov al, 0x08
int 0x10
jmp type_input_main

type_check_input:
mov byte [di], 0

; Compare with current word
mov si, type_words
mov al, [current_word_pos]
mov bl, 6
mul bl
add si, ax

mov di, type_buffer
call compare_string
cmp ax, 1
je type_correct_answer

; Wrong word
dec byte [type_lives]
jmp type_next_round

type_correct_answer:
; Correct word - add score
add word [type_score], 10

type_next_round:
; Move to next word
inc byte [current_word_pos]
cmp byte [current_word_pos], 9
jl type_cleanup
mov byte [current_word_pos], 0

type_cleanup:
; Clear input buffer
mov di, type_buffer
mov cx, 16
type_clear_buf:
mov byte [di], 0
inc di
loop type_clear_buf

popa
ret

; SYSTEM INFO COMMAND
sysinfo_command:
call clear_content_area
mov si, sysinfo_msg
call print_string_wrapped
call detect_memory
ret

; DISK INFO COMMAND
diskinfo_command:
call clear_content_area
mov si, diskinfo_msg
call print_string_wrapped
call detect_disk
ret

; Optional: Detect memory
detect_memory:
mov ah, 0x88
int 0x15
jc .memory_done

mov ah, 0x02
mov bh, 0x00
mov dh, 10
mov dl, 3
int 0x10

mov si, memory_detected_msg
call print_string
call print_number
mov si, kb_msg
call print_string

.memory_done:
ret

; Optional: Detect disk parameters
detect_disk:
mov ah, 0x08
mov dl, 0x00
int 0x13
jc .disk_done

mov ah, 0x02
mov bh, 0x00
mov dh, 10
mov dl, 3
int 0x10

mov si, disk_params_msg
call print_string

.disk_done:
ret

; SHELL LOOP
shell_loop:
mov ah, 0x02
mov bh, 0x00
mov dh, 22
mov dl, 3
int 0x10

mov cx, 74
.clear_input:
mov ah, 0x0E
mov al, ' '
int 0x10
loop .clear_input

mov ah, 0x02
mov bh, 0x00
mov dh, 22
mov dl, 3
int 0x10
mov ah, 0x0E
mov al, '>'
int 0x10
mov al, ' '
int 0x10

mov di, buffer
call read_string

mov byte [current_line], 4
mov ah, 0x02
mov bh, 0x00
mov dh, 4
mov dl, 3
int 0x10

mov si, buffer
cmp byte [si], 0
je .empty

mov di, cmd_help
call compare_string
je .help

mov di, cmd_clear
call compare_string
je .clear

mov di, cmd_info
call compare_string
je .info

mov di, cmd_about
call compare_string
je .about

mov di, cmd_time
call compare_string
je .time

mov di, cmd_reboot
call compare_string
je .reboot

mov di, cmd_calc
call compare_string
cmp ax, 1
je .calc

mov di, cmd_snake
call compare_string
cmp ax, 1
je .snake

mov di, cmd_pong
call compare_string
cmp ax, 1
je .pong

mov di, cmd_gallery
call compare_string
cmp ax, 1
je .gallery

mov di, cmd_cat
call compare_string
cmp ax, 1
je .cat

mov di, cmd_ship
call compare_string
cmp ax, 1
je .ship

mov di, cmd_tree
call compare_string
cmp ax, 1
je .tree

mov di, cmd_chud
call compare_string
cmp ax, 1
je .chud

mov di, cmd_mem
call compare_string
cmp ax, 1
je .mem

mov di, cmd_invaders
call compare_string
cmp ax, 1
je .invaders

mov di, cmd_notepad
call compare_string
cmp ax, 1
je .notepad

mov di, cmd_type
call compare_string
cmp ax, 1
je type_game_handler

mov di, cmd_sysinfo
call compare_string
cmp ax, 1
je .sysinfo

mov di, cmd_diskinfo
call compare_string
cmp ax, 1
je .diskinfo

call clear_content_area
mov si, unknown_msg
call print_string_wrapped
jmp .prompt

.help:
call clear_content_area
mov si, help_msg
call print_string_wrapped
jmp .prompt

.clear:
call clear_content_area
mov byte [current_line], 4
mov ah, 0x02
mov bh, 0x00
mov dh, 4
mov dl, 3
int 0x10
mov si, welcome_msg
call print_string_wrapped
jmp .prompt

.clear_content:
mov ah, 0x02
mov bh, 0x00
mov dl, 3
int 0x10

mov bx, 74
.clear_line:
mov ah, 0x0E
mov al, ' '
int 0x10
dec bx
jnz .clear_line

inc dh
loop .clear_content

mov byte [current_line], 4
mov ah, 0x02
mov bh, 0x00
mov dh, 4
mov dl, 3
int 0x10
jmp .prompt

.info:
call clear_content_area
mov si, info_msg
call print_string_wrapped
jmp .prompt

.about:
call clear_content_area
mov si, about_msg
call print_string_wrapped
jmp .prompt

.time:
call clear_content_area
call clear_content_area
call show_time
jmp .prompt

.reboot:
call clear_content_area
call reboot_system
mov si, reboot_failed_msg
call print_string_wrapped
jmp .prompt

.calc:
call calculator
jmp .prompt

.snake:
call snake_game
jmp .prompt

.pong:
call pong_game
jmp .prompt

.gallery:
call clear_content_area
call show_gallery
jmp .prompt

.cat:
call clear_content_area
call show_cat
jmp .prompt

.ship:
call clear_content_area
call show_ship
jmp .prompt

.tree:
call clear_content_area
call show_tree
jmp .prompt

.chud:
call clear_content_area
call show_chud
jmp .prompt

.mem:
call clear_content_area
call show_memory_info
jmp .prompt

.invaders:
call space_invaders_game
jmp .prompt

.notepad:
call notepad_app
jmp .prompt

.sysinfo:
call sysinfo_command
jmp .prompt

.diskinfo:
call diskinfo_command
jmp .prompt

.empty:
.prompt:
call update_status
jmp shell_loop


; === Simple input function ===
read_string:
    mov cx, 0
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 22
    mov dl, 5      ; After "> " prompt
    int 0x10
    
.input:
    mov ah, 0x00
    int 0x16
    
    cmp al, 0x0D          ; Enter
    je .done
    
    cmp al, 0x08          ; Backspace
    je .backspace
    
    ; Check if we have space (respect right border)
    mov bx, cx
    add bx, 5              ; Current position (prompt + input)
    cmp bx, 77             ; Right border - 2
    jge .input             ; Don't accept more input if at border
    
    ; Store and echo character
    mov [di], al
    inc di
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .input

.backspace:
    test cx, cx
    jz .input
    dec di
    dec cx
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .input

.done:
    mov byte [di], 0      ; Null terminate
    ret













; === Snake Game ===
snake_game:
    call clear_content_area
    
    ; Show instructions
    mov si, snake_instructions
    call print_string_wrapped
    
    ; Wait for key press to start
    mov ah, 0x00
    int 0x16
    
    ; Clear everything and set up game
    call clear_content_area
    call draw_snake_border
    
    ; Initialize snake
    call init_snake
    
    ; Initial draw
    call draw_snake
    call draw_food
    
    ; Game loop
.game_loop:
    ; Adjust delay based on movement direction
    mov al, [snake_dir]
    cmp al, 0          ; Right
    je .horizontal
    cmp al, 2          ; Left  
    je .horizontal
    ; Otherwise vertical (up/down)
    
.vertical:
    ; Shorter delay for vertical movement (appears faster due to character height)
    mov cx, 0x0600
    jmp .do_delay
    
.horizontal:
    ; Longer delay for horizontal movement (appears slower due to character width)
    mov cx, 0x0300
    
.do_delay:
    push cx
.delay:
    push cx
    mov cx, 0xFFFF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .delay
    pop cx
    
    ; Check for key press without waiting
    mov ah, 0x01
    int 0x16
    jz .no_key
    
    ; Get key and process
    mov ah, 0x00
    int 0x16
    call process_snake_input
    
.no_key:
    ; Update game state
    call update_snake
    call check_collision
    jc .game_over
    
    ; Redraw
    call clear_snake_area
    call draw_snake
    call draw_food
    
    jmp .game_loop

.game_over:
    ; Clear the entire content area (removes snake borders and everything)
    call clear_content_area
    
    ; Show game over message
    mov si, snake_game_over
    call print_string_wrapped
    
    ; Wait for any key
    mov ah, 0x00
    int 0x16
    
    ; Return to shell - the shell loop will redraw the proper UI
    ret

; Draw snake game border
draw_snake_border:
    pusha
    ; Draw border around play area (lines 6-20, columns 10-70)
    
    ; Top border (line 6, columns 10-70)
    mov dh, 6
    mov dl, 10
    mov cx, 61
.top_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .top_border
    
    ; Bottom border (line 20, columns 10-70)
    mov dh, 20
    mov dl, 10
    mov cx, 61
.bottom_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .bottom_border
    
    ; Left border (lines 7-19, column 10)
    mov dh, 7
    mov dl, 10
    mov cx, 13
.left_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  ; Vertical line
    int 0x10
    inc dh
    loop .left_border
    
    ; Right border (lines 7-19, column 70)
    mov dh, 7
    mov dl, 70
    mov cx, 13
.right_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  ; Vertical line
    int 0x10
    inc dh
    loop .right_border
    
    ; Corners
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 10
    int 0x10
    mov ah, 0x0E
    mov al, 0xDA  ; Top-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 70
    int 0x10
    mov ah, 0x0E
    mov al, 0xBF  ; Top-right
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 10
    int 0x10
    mov ah, 0x0E
    mov al, 0xC0  ; Bottom-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 70
    int 0x10
    mov ah, 0x0E
    mov al, 0xD9  ; Bottom-right
    int 0x10
    
    popa
    ret

; Clear only the snake play area (not the borders)
clear_snake_area:
    pusha
    mov dh, 7
.clear_lines:
    cmp dh, 20
    jge .done_clear
    
    mov dl, 11
.clear_columns:
    cmp dl, 70
    jge .next_line
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    
    inc dl
    jmp .clear_columns
    
.next_line:
    inc dh
    jmp .clear_lines
    
.done_clear:
    popa
    ret

; Initialize snake
init_snake:
    mov byte [snake_length], 3
    
    ; Initial snake positions (head at center)
    mov byte [snake_x], 40
    mov byte [snake_y], 13
    
    mov byte [snake_x+1], 39
    mov byte [snake_y+1], 13
    
    mov byte [snake_x+2], 38
    mov byte [snake_y+2], 13
    
    ; Initial direction (right)
    mov byte [snake_dir], 0
    
    ; Initial food
    call spawn_food
    ret

; Update snake position
update_snake:
    ; Move body segments (from tail to head)
    mov cl, [snake_length]
    dec cl
    mov ch, 0
.move_body:
    mov si, cx
    mov al, [snake_x + si - 1]
    mov [snake_x + si], al
    mov al, [snake_y + si - 1]
    mov [snake_y + si], al
    loop .move_body
    
    ; Move head based on direction
    mov al, [snake_dir]
    cmp al, 0
    je .move_right
    cmp al, 1
    je .move_down
    cmp al, 2
    je .move_left
    cmp al, 3
    je .move_up
    
.move_right:
    inc byte [snake_x]
    jmp .done_move
.move_down:
    inc byte [snake_y]
    jmp .done_move
.move_left:
    dec byte [snake_x]
    jmp .done_move
.move_up:
    dec byte [snake_y]
.done_move:
    ret

; Draw snake
draw_snake:
    pusha
    mov cl, [snake_length]
    mov ch, 0
.draw_loop:
    mov si, cx
    dec si  ; Convert to 0-based index
    
    ; Get position
    mov dh, [snake_y + si]
    mov dl, [snake_x + si]
    
    ; Set cursor position
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    ; Draw snake segment
    mov ah, 0x0E
    cmp si, 0
    je .draw_head
    mov al, 'O'  ; Body
    jmp .draw_char
.draw_head:
    mov al, '#'  ; Head
.draw_char:
    int 0x10
    
    loop .draw_loop
    
    popa
    ret

; Draw food
draw_food:
    pusha
    mov dh, [food_y]
    mov dl, [food_x]
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, '*'  ; Food
    int 0x10
    popa
    ret

; Spawn food at random position
spawn_food:
.spawn_again:
    ; Simple pseudo-random position
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    mov dx, 0
    mov cx, 58  ; 69-11 = 58 possible x positions
    div cx
    add dl, 11  ; Minimum x is 11
    mov [food_x], dl
    
    mov ah, 0x00
    int 0x1A
    mov ax, dx
    mov dx, 0
    mov cx, 12  ; 19-7 = 12 possible y positions
    div cx
    add dl, 7   ; Minimum y is 7
    mov [food_y], dl
    
    ; Check if food spawns on snake (simple check - just head)
    mov al, [food_x]
    cmp al, [snake_x]
    jne .spawn_done
    mov al, [food_y]
    cmp al, [snake_y]
    je .spawn_again
    
.spawn_done:
    ret

; Check collisions
check_collision:
    ; Wall collision
    mov al, [snake_x]
    cmp al, 11
    jl .collision
    cmp al, 69
    jg .collision
    mov al, [snake_y]
    cmp al, 7
    jl .collision
    cmp al, 19
    jg .collision
    
    ; Food collision
    mov al, [snake_x]
    cmp al, [food_x]
    jne .no_food_collision
    mov al, [snake_y]
    cmp al, [food_y]
    jne .no_food_collision
    
    ; Eat food - grow snake
    mov al, [snake_length]
    cmp al, 100  ; Max length
    jge .no_grow
    
    ; Add new segment at tail position
    mov si, ax  ; si = snake_length
    mov bl, [snake_x + si - 1]
    mov [snake_x + si], bl
    mov bl, [snake_y + si - 1]
    mov [snake_y + si], bl
    
    inc byte [snake_length]
    
    ; Spawn new food
    call spawn_food
    
.no_food_collision:
    clc
    ret
    
.collision:
    stc
    ret
    
.no_grow:
    call spawn_food
    clc
    ret

; Process keyboard input for snake
process_snake_input:
    cmp ah, 0x48  ; Up arrow
    je .up
    cmp ah, 0x50  ; Down arrow
    je .down
    cmp ah, 0x4B  ; Left arrow
    je .left
    cmp ah, 0x4D  ; Right arrow
    je .right
    cmp al, 'w'   ; W key
    je .up
    cmp al, 's'   ; S key
    je .down
    cmp al, 'a'   ; A key
    je .left
    cmp al, 'd'   ; D key
    je .right
    ret

.up:
    cmp byte [snake_dir], 1  ; Can't reverse from down to up
    je .done
    mov byte [snake_dir], 3
    jmp .done
.down:
    cmp byte [snake_dir], 3  ; Can't reverse from up to down
    je .done
    mov byte [snake_dir], 1
    jmp .done
.left:
    cmp byte [snake_dir], 0  ; Can't reverse from right to left
    je .done
    mov byte [snake_dir], 2
    jmp .done
.right:
    cmp byte [snake_dir], 2  ; Can't reverse from left to right
    je .done
    mov byte [snake_dir], 0
.done:
    ret





; === Pong Game ===
pong_game:
    call clear_content_area
    
    ; Show instructions
    mov si, pong_instructions
    call print_string_wrapped
    
    ; Wait for key press to start
    mov ah, 0x00
    int 0x16
    
    ; Clear everything and set up game
    call clear_content_area
    call draw_pong_border
    
    ; Initialize game state
    call init_pong
    
    ; Game loop
.pong_loop:
    ; Delay for game speed
    mov cx, 0x2000
.delay:
    push cx
    mov cx, 0x00FF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .delay
    
    ; Check for key press without waiting
    mov ah, 0x01
    int 0x16
    jz .no_key
    
    ; Get key and process
    mov ah, 0x00
    int 0x16
    call process_pong_input
    
.no_key:
    ; Update game state
    call update_pong
    call check_pong_collision
    
    ; Redraw
    call clear_pong_area
    call draw_paddles
    call draw_ball
    call draw_scores
    
    ; Check if game should end
    mov al, [player_score]
    cmp al, 5
    jge .game_over
    mov al, [cpu_score]
    cmp al, 5
    jge .game_over
    
    jmp .pong_loop

.game_over:
    ; Clear the entire content area
    call clear_content_area
    
    ; Show game over message
    mov si, pong_game_over
    call print_string_wrapped
    
    ; Wait for any key
    mov ah, 0x00
    int 0x16
    
    ; Return to shell
    ret

; Draw pong game border
draw_pong_border:
    pusha
    ; Draw border around play area (lines 6-20, columns 10-70)
    
    ; Top border (line 6, columns 10-70)
    mov dh, 6
    mov dl, 10
    mov cx, 61
.top_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .top_border
    
    ; Bottom border (line 20, columns 10-70)
    mov dh, 20
    mov dl, 10
    mov cx, 61
.bottom_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .bottom_border
    
    ; Left border (lines 7-19, column 10)
    mov dh, 7
    mov dl, 10
    mov cx, 13
.left_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  ; Vertical line
    int 0x10
    inc dh
    loop .left_border
    
    ; Right border (lines 7-19, column 70)
    mov dh, 7
    mov dl, 70
    mov cx, 13
.right_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  ; Vertical line
    int 0x10
    inc dh
    loop .right_border
    
    ; Corners
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 10
    int 0x10
    mov ah, 0x0E
    mov al, 0xDA  ; Top-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 70
    int 0x10
    mov ah, 0x0E
    mov al, 0xBF  ; Top-right
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 10
    int 0x10
    mov ah, 0x0E
    mov al, 0xC0  ; Bottom-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 70
    int 0x10
    mov ah, 0x0E
    mov al, 0xD9  ; Bottom-right
    int 0x10
    
    popa
    ret

; Clear only the pong play area (not the borders)
clear_pong_area:
    pusha
    mov dh, 7
.clear_lines:
    cmp dh, 20
    jge .done_clear
    
    mov dl, 11
.clear_columns:
    cmp dl, 70
    jge .next_line
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    
    inc dl
    jmp .clear_columns
    
.next_line:
    inc dh
    jmp .clear_lines
    
.done_clear:
    popa
    ret

; Initialize pong game state
init_pong:
    mov byte [player_y], 10
    mov byte [cpu_y], 10
    mov byte [ball_x], 40
    mov byte [ball_y], 13
    mov byte [ball_dir], 1  ; 1=right, -1=left
    mov byte [player_score], 0
    mov byte [cpu_score], 0
    ret

; Update pong game state
update_pong:
    ; Move ball
    mov al, [ball_dir]
    add [ball_x], al
    
    ; Simple CPU AI - follow ball with some imperfection
    mov al, [ball_y]
    cmp al, [cpu_y]
    jl .cpu_move_up
    jg .cpu_move_down
    jmp .ball_movement
    
.cpu_move_up:
    dec byte [cpu_y]
    cmp byte [cpu_y], 8
    jge .ball_movement
    mov byte [cpu_y], 8
    jmp .ball_movement
    
.cpu_move_down:
    inc byte [cpu_y]
    cmp byte [cpu_y], 17
    jle .ball_movement
    mov byte [cpu_y], 17
    
.ball_movement:
    ; Add some vertical movement based on direction
    mov ah, 0x00
    int 0x1A
    and dl, 0x03  ; Only 2 bits for 4 possible outcomes
    
    cmp dl, 0
    je .move_up
    cmp dl, 1
    je .move_down
    ; 2 and 3 = no vertical movement
    jmp .done_update
    
.move_up:
    dec byte [ball_y]
    cmp byte [ball_y], 8
    jge .done_update
    mov byte [ball_y], 8
    jmp .done_update
    
.move_down:
    inc byte [ball_y]
    cmp byte [ball_y], 17
    jle .done_update
    mov byte [ball_y], 17
    
.done_update:
    ret

; Check pong collisions
check_pong_collision:
    ; Ball hits left paddle (player)
    cmp byte [ball_x], 12
    jne .check_cpu_paddle
    
    mov al, [ball_y]
    mov bl, [player_y]
    sub bl, 2
    cmp al, bl
    jl .player_miss
    add bl, 4
    cmp al, bl
    jg .player_miss
    
    ; Hit - reverse direction
    mov byte [ball_dir], 1
    jmp .done_collision
    
.player_miss:
    ; Player missed - CPU scores
    inc byte [cpu_score]
    call reset_ball
    jmp .done_collision
    
.check_cpu_paddle:
    ; Ball hits right paddle (CPU)
    cmp byte [ball_x], 67
    jne .check_walls
    
    mov al, [ball_y]
    mov bl, [cpu_y]
    sub bl, 2
    cmp al, bl
    jl .cpu_miss
    add bl, 4
    cmp al, bl
    jg .cpu_miss
    
    ; Hit - reverse direction
    mov byte [ball_dir], -1
    jmp .done_collision
    
.cpu_miss:
    ; CPU missed - player scores
    inc byte [player_score]
    call reset_ball
    jmp .done_collision
    
.check_walls:
    ; Ball hits top wall
    cmp byte [ball_y], 8
    jle .hit_top
    ; Ball hits bottom wall  
    cmp byte [ball_y], 17
    jge .hit_bottom
    jmp .done_collision

.hit_top:
    ; Bounce down from top
    mov byte [ball_y], 9
    jmp .done_collision

.hit_bottom:
    ; Bounce up from bottom
    mov byte [ball_y], 16
    jmp .done_collision
    
.done_collision:
    ret

; Reset ball to center
reset_ball:
    mov byte [ball_x], 40
    mov byte [ball_y], 13
    ; Randomize starting direction
    mov ah, 0x00
    int 0x1A
    test dl, 1
    jz .go_left
    mov byte [ball_dir], 1
    ret
.go_left:
    mov byte [ball_dir], -1
    ret

; Draw paddles
draw_paddles:
    pusha
    
    ; Draw player paddle (left)
    mov dh, [player_y]
    sub dh, 2
    mov cx, 5  ; 5 segments tall
.draw_player:
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 11
    int 0x10
    
    mov ah, 0x0E
    mov al, '|'
    int 0x10
    
    inc dh
    loop .draw_player
    
    ; Draw CPU paddle (right)
    mov dh, [cpu_y]
    sub dh, 2
    mov cx, 5  ; 5 segments tall
.draw_cpu:
    mov ah, 0x02
    mov bh, 0x00
    mov dl, 68
    int 0x10
    
    mov ah, 0x0E
    mov al, '|'
    int 0x10
    
    inc dh
    loop .draw_cpu
    
    popa
    ret

; Draw ball
draw_ball:
    pusha
    mov dh, [ball_y]
    mov dl, [ball_x]
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, 'O'
    int 0x10
    popa
    ret

; Draw scores
draw_scores:
    pusha
    
    ; Player score (top left)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 15
    int 0x10
    
    mov si, player_score_msg
    call print_string
    mov al, [player_score]
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
    ; CPU score (top right)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 55
    int 0x10
    
    mov si, cpu_score_msg
    call print_string
    mov al, [cpu_score]
    add al, '0'
    mov ah, 0x0E
    int 0x10
    
    popa
    ret

; Process pong input
process_pong_input:
    cmp al, 'w'   ; W key - move up
    je .move_up
    cmp al, 's'   ; S key - move down
    je .move_down
    cmp al, 'q'   ; Q key - quit
    je .quit
    ret

.move_up:
    dec byte [player_y]
    cmp byte [player_y], 9
    jge .done
    mov byte [player_y], 9
    jmp .done

.move_down:
    inc byte [player_y]
    cmp byte [player_y], 16
    jle .done
    mov byte [player_y], 16
    jmp .done

.quit:
    pop ax  ; Clean up stack from call
    jmp pong_game.game_over

.done:
    ret





; === Gallery Functions ===


show_gallery:
    pusha
    
    ; Display title
    mov si, gallery_title
    call print_string_wrapped
    

    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    

    mov byte [current_line], 6
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 8
    int 0x10
    mov si, mini_cat_art
    call print_string_wrapped
    

    mov byte [current_line], 6
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 20
    int 0x10
    mov si, mini_ship_art
    call print_string_wrapped
    

    mov byte [current_line], 6
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 32
    int 0x10
    mov si, mini_tree_art
    call print_string_wrapped
    

    mov byte [current_line], 6
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 44
    int 0x10
    mov si, mini_chud_art
    call print_string_wrapped
    
    ; Add usage instructions
    mov byte [current_line], 12
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 12
    mov dl, 3
    int 0x10
    
    mov si, gallery_help
    call print_string_wrapped
    
    popa
    ret


show_cat:
    pusha
    mov si, cat_art
    call print_string_wrapped
    popa
    ret


show_ship:
    pusha
    mov si, ship_art
    call print_string_wrapped
    popa
    ret


show_tree:
    pusha
    mov si, tree_art
    call print_string_wrapped
    popa
    ret


show_chud:
    pusha
    mov si, chud_art
    call print_string_wrapped
    popa
    ret

; Gallery help text
gallery_help:
    db "Commands: cat, over, tree, chud - View full size", 13, 10
    db "clear - Return to desktop", 13, 10, 0



; === Space Invaders Game ===
space_invaders_game:
    call clear_content_area
    
    ; Show instructions
    mov si, invaders_instructions
    call print_string_wrapped
    
    ; Wait for key press to start
    mov ah, 0x00
    int 0x16
    
    ; Clear everything and set up game
    call clear_content_area
    call draw_invaders_border
    
    ; Initialize game
    call init_invaders
    
    ; Game loop
.game_loop:

    mov cx, 0x4000
.delay:
    push cx
    mov cx, 0x00FF
.inner_delay:
    nop
    loop .inner_delay
    pop cx
    loop .delay
    

    mov ah, 0x01
    int 0x16
    jz .no_key
    

    mov ah, 0x00
    int 0x16
    call process_invaders_input
    cmp byte [game_active], 0
    je .game_over
    
.no_key:

    call update_invaders
    cmp byte [game_active], 0
    je .game_over
    

    cmp byte [aliens_remaining], 0
    je .win
    

    call clear_invaders_area
    call draw_player
    call draw_aliens
    call draw_bullets
    call draw_invaders_info
    
    jmp .game_loop

.game_over:

    call clear_content_area
    

    mov si, invaders_game_over
    call print_string_wrapped
    

    mov ah, 0x00
    int 0x16
    

    ret

.win:

    call clear_content_area
    

    mov si, invaders_win
    call print_string_wrapped
    

    mov ah, 0x00
    int 0x16
    

    ret

; Draw space invaders border
draw_invaders_border:
    pusha

    

    mov dh, 6
    mov dl, 15
    mov cx, 51
.top_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .top_border
    

    mov dh, 20
    mov dl, 15
    mov cx, 51
.bottom_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  ; Horizontal line
    int 0x10
    inc dl
    loop .bottom_border


    mov dh, 7
    mov dl, 15
    mov cx, 13
.left_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  
    int 0x10
    inc dh
    loop .left_border
    

    mov dh, 7
    mov dl, 65
    mov cx, 13
.right_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3  
    int 0x10
    inc dh
    loop .right_border
    

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 15
    int 0x10
    mov ah, 0x0E
    mov al, 0xDA  ; Top-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 6
    mov dl, 65
    int 0x10
    mov ah, 0x0E
    mov al, 0xBF  ; Top-right
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 15
    int 0x10
    mov ah, 0x0E
    mov al, 0xC0  ; Bottom-left
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 20
    mov dl, 65
    int 0x10
    mov ah, 0x0E
    mov al, 0xD9  ; Bottom-right
    int 0x10
    
    popa
    ret

; Clear only the invaders play area
clear_invaders_area:
    pusha
    mov dh, 7
.clear_lines:
    cmp dh, 20
    jge .done_clear
    
    mov dl, 16
.clear_columns:
    cmp dl, 65
    jge .next_line
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    
    inc dl
    jmp .clear_columns
    
.next_line:
    inc dh
    jmp .clear_lines
    
.done_clear:
    popa
    ret


init_invaders:

    mov byte [player_x], 35  
    

mov cx, 30
mov si, 0
mov bl, 18  
mov bh, 1  
.init_aliens:
    mov [alien_x + si], bl
    mov [alien_y + si], bh
    mov byte [alien_active + si], 1
    
    add bl, 8   
    inc si
    cmp si, 6   
    jl .continue_row
    mov bl, 18  
    add bh, 2   
    mov si, 0
.continue_row:
    loop .init_aliens
    
    ; Initialize game state
    mov word [invaders_score], 0
    mov byte [aliens_remaining], 30
    mov byte [player_bullet_active], 0
    mov byte [alien_bullet_active], 0
    mov byte [alien_direction], 1
    mov byte [alien_speed], 45
    mov byte [game_active], 1
    
    ret


update_invaders:

dec byte [alien_speed]
jnz .skip_alien_move


mov byte [alien_speed], 25


mov cx, 30
mov si, 0
.move_aliens:
    cmp byte [alien_active + si], 0
    je .skip_alien
    

    mov al, [alien_direction]
    add [alien_x + si], al
    

    cmp byte [alien_x + si], 16
    jle .change_direction
    cmp byte [alien_x + si], 63
    jge .change_direction
    
.skip_alien:
    inc si
    loop .move_aliens
    jmp .skip_alien_move

.change_direction:
    neg byte [alien_direction]
    mov cx, 30
    mov si, 0
.move_down:
    cmp byte [alien_active + si], 0
    je .skip_move_down
    

    inc byte [alien_y + si]
    cmp byte [alien_y + si], 19
    jl .not_at_bottom
    mov byte [alien_y + si], 18 
    
.not_at_bottom:
    ; Check if aliens reached player level (game over)
    cmp byte [alien_y + si], 18
    jge .invaders_reached_bottom
    
.skip_move_down:
    inc si
    loop .move_down

.skip_alien_move:

cmp byte [player_bullet_active], 1
jne .no_player_bullet

dec byte [player_bullet_y]
cmp byte [player_bullet_y], 7    
jle .bullet_off_screen


call check_bullet_collision
jmp .no_player_bullet

.bullet_off_screen:
mov byte [player_bullet_active], 0

.no_player_bullet:
call alien_shoot


cmp byte [alien_bullet_active], 1
jne .no_alien_bullet

inc byte [alien_bullet_y]
cmp byte [alien_bullet_y], 19   
jge .alien_bullet_off_screen


mov al, [alien_bullet_x]
cmp al, [player_x]
jne .no_alien_bullet
mov al, [alien_bullet_y]
cmp al, 18
jne .no_alien_bullet


mov byte [game_active], 0
jmp .alien_bullet_off_screen

.alien_bullet_off_screen:
mov byte [alien_bullet_active], 0
    

.no_alien_bullet:
    ret

.invaders_reached_bottom:
    mov byte [game_active], 0
    ret


check_bullet_collision:
    mov cx, 30
    mov si, 0
.check_alien:
    cmp byte [alien_active + si], 0
    je .next_alien
    
    mov al, [player_bullet_x]
    cmp al, [alien_x + si]
    jne .next_alien
    
    mov al, [player_bullet_y]
    cmp al, [alien_y + si]
    jne .next_alien
    

    mov byte [alien_active + si], 0
    mov byte [player_bullet_active], 0
    dec byte [aliens_remaining]
    add word [invaders_score], 100
    ret

.next_alien:
    inc si
    loop .check_alien
    ret

; Alien shooting logic
alien_shoot:
    cmp byte [alien_bullet_active], 1
    je .done_shoot
    

    mov ah, 0x00
    int 0x1A
    test dl, 0x1F  
    jnz .done_shoot
.find_shooter:
    mov ah, 0x00
    int 0x1A
    and dx, 31  
    cmp dx, 30
    jge .find_shooter
    
    mov si, dx
    cmp byte [alien_active + si], 0
    je .find_shooter
    

    mov al, [alien_x + si]
    mov [alien_bullet_x], al
    mov al, [alien_y + si]
    inc al
    mov [alien_bullet_y], al
    mov byte [alien_bullet_active], 1

.done_shoot:
    ret

; Draw player
draw_player:
    pusha
    mov dh, 18 
    mov dl, [player_x]
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, '^' 
    int 0x10
    popa
    ret

; Draw aliens
draw_aliens:
    pusha
    mov cx, 30
    mov si, 0
.draw_alien:
    cmp byte [alien_active + si], 0
    je .skip_alien
    
    mov dh, [alien_y + si]
    mov dl, [alien_x + si]
    

    cmp dl, 16       
    jl .skip_alien
    cmp dl, 63  
    jg .skip_alien
    cmp dh, 7     
    jl .skip_alien
    cmp dh, 19  
    jg .skip_alien
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, 'M'  
    int 0x10

.skip_alien:
    inc si
    loop .draw_alien
    popa
    ret

; Draw bullets
draw_bullets:
    pusha
    

    cmp byte [player_bullet_active], 1
    jne .no_player_bullet
    
    mov dh, [player_bullet_y]
    mov dl, [player_bullet_x]
    

    cmp dh, 7
    jl .no_player_bullet
    cmp dh, 19
    jg .no_player_bullet
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, '|' 
    int 0x10

.no_player_bullet:

    cmp byte [alien_bullet_active], 1
    jne .no_alien_bullet
    
    mov dh, [alien_bullet_y]
    mov dl, [alien_bullet_x]
    

    cmp dh, 7
    jl .no_alien_bullet
    cmp dh, 19
    jg .no_alien_bullet
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, '.'  
    int 0x10

.no_alien_bullet:
    popa
    ret


draw_invaders_info:
    pusha
    
    ; Score (top left)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 17
    int 0x10
    
    mov si, invaders_score_msg
    call print_string
    mov ax, [invaders_score]
    call print_number
    
    ; Aliens remaining (top right)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 50
    int 0x10
    
    mov si, invaders_aliens_left_msg
    call print_string
    mov al, [aliens_remaining]
    mov ah, 0
    call print_number
    
    popa
    ret

; Process space invaders input
process_invaders_input:
    cmp al, 'a'   
    je .move_left
    cmp al, 'd'   
    je .move_right
    cmp al, ' '  
    je .shoot
    cmp al, 'q'   
    je .quit
    ret

.move_left:
    dec byte [player_x]
    cmp byte [player_x], 16   
    jge .done
    mov byte [player_x], 16
    jmp .done

.move_right:
    inc byte [player_x]
    cmp byte [player_x], 63 
    jle .done
    mov byte [player_x], 63
    jmp .done

.shoot:
    cmp byte [player_bullet_active], 1
    je .done  
    
    ; Create new bullet at player position
    mov al, [player_x]
    mov [player_bullet_x], al
    mov byte [player_bullet_y], 17
    mov byte [player_bullet_active], 1
    jmp .done

.quit:
    mov byte [game_active], 0
.done:
    ret



; === Memory Information ===
show_memory_info:
    pusha
    

    mov si, mem_title
    call print_string_wrapped
    

    mov si, mem_kernel
    call print_string_wrapped
    
    mov si, mem_kernel_size
    call print_string_wrapped
    

    mov si, mem_total
    call print_string_wrapped
    
    mov si, mem_available
    call print_string_wrapped
    

    mov ah, 0x0E
    mov al, 13
    int 0x10
    mov al, 10
    int 0x10
    

    mov si, mem_layout
    call print_string_wrapped
    

    call try_detect_memory
    
    popa
    ret


try_detect_memory:

    mov ah, 0x88
    int 0x15
    jc .memory_error
    

    
    mov si, detected_mem_msg
    call print_string_wrapped
    

    call print_number
    mov si, kb_msg
    call print_string_wrapped
    ret
    
.memory_error:

    ret

detected_mem_msg db "Extended memory detected: ", 0








; === Notepad Application ===
notepad_app:
    call clear_content_area
    
    ; Show instructions
    mov si, notepad_instructions
    call print_string_wrapped
    

    mov ah, 0x00
    int 0x16
    

    call clear_content_area
    call draw_notepad_border
    

    call init_notepad
    

.notepad_loop:

    call draw_notepad_content
    

    call position_notepad_cursor
    

    mov ah, 0x00
    int 0x16
    

    call process_notepad_input
    cmp al, 0x1B 
    jne .notepad_loop
    

    call clear_content_area
    mov si, notepad_exit_msg
    call print_string_wrapped
    ret

; Draw notepad border
draw_notepad_border:
    pusha

    mov dh, 5
    mov dl, 15
    mov cx, 51
.top_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4 
    int 0x10
    inc dl
    loop .top_border
    

    mov dh, 19
    mov dl, 15
    mov cx, 51
.bottom_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xC4  
    int 0x10
    inc dl
    loop .bottom_border
    

    mov dh, 6
    mov dl, 15
    mov cx, 13
.left_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3 
    int 0x10
    inc dh
    loop .left_border
    

    mov dh, 6
    mov dl, 65
    mov cx, 13
.right_border:
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    mov ah, 0x0E
    mov al, 0xB3 
    int 0x10
    inc dh
    loop .right_border
    

    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 15
    int 0x10
    mov ah, 0x0E
    mov al, 0xDA  
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 65
    int 0x10
    mov ah, 0x0E
    mov al, 0xBF  
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 19
    mov dl, 15
    int 0x10
    mov ah, 0x0E
    mov al, 0xC0 
    int 0x10
    
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 19
    mov dl, 65
    int 0x10
    mov ah, 0x0E
    mov al, 0xD9  
    int 0x10
    
    ; Title
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 5
    mov dl, 28
    int 0x10
    mov si, notepad_title
    call print_string
    
    popa
    ret


init_notepad:

    mov di, notepad_buffer
    mov cx, 637  
    mov al, ' '  
.clear_buffer:
    mov [di], al
    inc di
    loop .clear_buffer
    

    mov di, notepad_buffer
    add di, 636
    mov byte [di], 0
    

    mov byte [cursor_x], 0
    mov byte [cursor_y], 0
    
    ret


draw_notepad_content:
    pusha
    

    mov dh, 6
.clear_lines:
    cmp dh, 19
    jge .draw_content
    
    mov dl, 16
.clear_columns:
    cmp dl, 65
    jge .next_clear_line
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    
    inc dl
    jmp .clear_columns
    
.next_clear_line:
    inc dh
    jmp .clear_lines

.draw_content:

    mov dh, 6    
    mov dl, 16  
    mov si, notepad_buffer  
    
.draw_line:

    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    

    mov cx, 49  
.draw_char:
    mov al, [si]
    cmp al, 0   
    je .draw_done
    cmp al, 13    
    je .skip_cr
    

    mov ah, 0x0E
    int 0x10
    
.skip_cr:
    inc si
    inc dl
    loop .draw_char
    

    inc dh
    mov dl, 16
    cmp dh, 19  
    jl .draw_line

.draw_done:
    popa
    ret

; Position cursor in notepad
position_notepad_cursor:
    pusha

    mov dh, [cursor_y]
    add dh, 6     
    mov dl, [cursor_x]
    add dl, 16    
    
    mov ah, 0x02
    mov bh, 0x00
    int 0x10
    popa
    ret


process_notepad_input:

    cmp al, 0x0D   ; Enter key
    je .enter
    

    cmp ah, 0x48   ; Up arrow
    je .arrow_up
    cmp ah, 0x50   ; Down arrow
    je .arrow_down
    cmp ah, 0x4B   ; Left arrow
    je .arrow_left
    cmp ah, 0x4D   ; Right arrow
    je .arrow_right
    

    cmp al, 0x08   ; Backspace
    je .backspace
    cmp al, 0x1B   ; ESC
    je .done
    

    cmp al, 32
    jl .done
    cmp al, 126
    jg .done
    
    call add_character
    jmp .done

.arrow_up:
    cmp byte [cursor_y], 0
    je .done
    dec byte [cursor_y]
    jmp .done

.arrow_down:
    cmp byte [cursor_y], 12  
    je .done
    inc byte [cursor_y]
    jmp .done

.arrow_left:
    cmp byte [cursor_x], 0
    je .done
    dec byte [cursor_x]
    jmp .done

.arrow_right:
    cmp byte [cursor_x], 48  
    je .done
    inc byte [cursor_x]
    jmp .done

.backspace:
    call delete_character
    jmp .done

.enter:
    call add_newline
    jmp .done

.done:
    ret


add_character:
    pusha

    call calculate_buffer_position
    
    ; Store the character
    mov [si], al
    
    ; Move cursor right
    inc byte [cursor_x]
    cmp byte [cursor_x], 49  
    jl .add_done
    
    ; Auto-wrap to next line
    mov byte [cursor_x], 0
    inc byte [cursor_y]
    cmp byte [cursor_y], 13   
    jl .add_done
    mov byte [cursor_y], 12  

.add_done:
    popa
    ret


delete_character:
    pusha
    cmp byte [cursor_x], 0
    jne .delete_normal
    

    popa
    ret

.delete_normal:

    dec byte [cursor_x]
    call calculate_buffer_position
    mov byte [si], ' ' 
    
    popa
    ret


add_newline:
    pusha
    

    call calculate_buffer_position
    

    mov di, si
    add di, (49 - 1)  
    

    mov si, notepad_buffer
    mov al, [cursor_y]
    inc al          
    mov bl, 49
    mul bl
    add si, ax      
    

    cmp byte [cursor_y], 11   
    jge .just_move_cursor
    


.just_move_cursor:

    mov byte [cursor_x], 0
    inc byte [cursor_y]
    cmp byte [cursor_y], 13 
    jl .newline_done
    mov byte [cursor_y], 12   

.newline_done:
    popa
    ret


calculate_buffer_position:
    push ax
    push bx
    

    mov al, [cursor_y]
    mov bl, 49
    mul bl
    mov bl, [cursor_x]
    mov bh, 0
    add ax, bx
    
    mov si, notepad_buffer
    add si, ax
    
    pop bx
    pop ax
    ret

notepad_title db " Notepad ", 0













; === Data Section ===

; Current line tracker
current_line db 4

; UI Strings
header_title db "simpleOS Professional Edition v2.0", 0
status_left db "Ready | Commands: help, clear", 0
status_left_len equ $ - status_left - 1
no_time_msg db "--:--", 0
unknown_msg db "Unknown command. Type 'help'", 0

; Welcome message
welcome_msg db "                         === simpleOS Desktop ===", 13, 10, \
            "  +------------+    +------------+    +------------+    +------------+", 13, 10, \
            "  | Calculator |    | Snake Game |    | Pong Game  |    |  Gallery   |", 13, 10, \
            "  +------------+    +------------+    +------------+    +------------+", 13, 10, \
            "  +------------+    +------------+    +------------+    +------------+", 13, 10, \
            "  |   Memory   |    |  Invaders  |    |  Notepad   |    | Type game  |", 13, 10, \
            "  +------------+    +------------+    +------------+    +------------+", 13, 10, 13, 10, \
            "Type app name or 'help' for commands.", 13, 10, 0

; Command strings
cmd_help db "help", 0
cmd_clear db "clear", 0
cmd_info db "info", 0
cmd_about db "about", 0
cmd_time db "time", 0
cmd_reboot db "reboot", 0
cmd_calc db "calculator", 0
cmd_snake db "snake", 0
cmd_pong db "pong", 0
cmd_gallery db "gallery", 0
cmd_cat db "cat", 0
cmd_ship db "over", 0
cmd_tree db "tree", 0
cmd_chud db "chud", 0
cmd_mem db "memory", 0
cmd_invaders db "invaders", 0
cmd_notepad db "notepad", 0
cmd_type db "type", 0
cmd_sysinfo db "sysinfo", 0
cmd_diskinfo db "diskinfo", 0

; Help message
help_msg db "                         Available commands:", 13, 10, \
            "[ == help == ]  [ == clear == ]  [ == info == ] [ == sysinfo == ]", 13, 10, \
            "[ == time == ]  [ == about == ]  [ == reboot ==] [ == diskinfo == ]", 13, 10, \
            "Type app name or 'help' for commands.", 13, 10, 0



; help_msg db "Available commands:", 13, 10, \
;            "help   - show this help", 13, 10, \
;            "clear  - clear screen", 13, 10, \
;            "info   - system info", 13, 10, \
;            "about  - about this OS", 13, 10, \
;            "time   - show current time", 13, 10, \
;            "calc   - simple calculator", 13, 10, \
;            "snake  - play snake game", 13, 10, \
;            "reboot - restart system", 13, 10, 0

; Info message  
info_msg db "simpleOS v2.0", 13, 10, \
          "16-bit Real Mode", 13, 10, \
          "Professional Edition", 13, 10, 0

; About msg
about_msg db "Developed by Luka", 13, 10, \
           "Property of Luka", 13, 10, 0

time_msg db "Current time: ", 0
time_error_msg db "Error reading time", 0
reboot_msg db "Rebooting system...", 0
reboot_failed_msg db "Reboot failed! System may be unstable.", 0

; Calculator data
calc_welcome db "Calculator - Type 'exit' to return || Supports: +, -, *, x, X, /", 13, 10, 0
calc_prompt db "calc> ", 0
calc_exit_cmd db "exit", 0
calc_buffer times 32 db 0
calc_result db "Result: ", 0
calc_division_result db "Quotient: ", 0
calc_remainder db "Remainder: ", 0
division_error_msg db "Error: Division by zero!", 13, 10, 0
calc_invalid db "Invalid format. Use: 5 + 3, 6 * 2, 10 / 3", 13, 10, 0
num1 dw 0
temp_num dw 0
remainder dw 0


; Boot screen data
boot_screen:
    db "                                                                 ", 13, 10
    db "                                                                 ", 13, 10
    db "                                                                 ", 13, 10
    db "              +--------------------------------------------------+", 13, 10
    db "              |                                                  |", 13, 10
    db "              |                                                  |", 13, 10
    db "              |                   SIMPLEOS                       |", 13, 10
    db "              |                                                  |", 13, 10
    db "              |              Professional Edition                |", 13, 10
    db "              |                  Version 2.0                     |", 13, 10
    db "              |                                                  |", 13, 10
    db "              |                                                  |", 13, 10
    db "              |               Booting system...                  |", 13, 10
    db "              |                                                  |", 13, 10
    db "              |                                                  |", 13, 10
    db "              +__________________________________________________+", 13, 10, 0


; Snake game data
snake_instructions db "Snake Game - Use arrow keys or WASD to move", 13, 10, \
                   "Press any key to start...", 13, 10, 0
snake_game_over db "Game Over! Press any key to return.", 13, 10, 0
snake_length db 0
snake_x times 100 db 0
snake_y times 100 db 0
snake_dir db 0 
food_x db 0
food_y db 0





; Pong game data
pong_instructions db "Pong Game - W/S to move paddle, Q to quit", 13, 10, \
                  "First to 5 points wins!", 13, 10, \
                  "Press any key to start...", 13, 10, 0
pong_game_over db "Game Over! Press any key to return.", 13, 10, 0
player_score_msg db "Player: ", 0
cpu_score_msg db "CPU: ", 0

; Pong game state
player_y db 0
cpu_y db 0
ball_x db 0
ball_y db 0
ball_dir db 0  
player_score db 0
cpu_score db 0



; ASCII Art Data
cat_art:
    db "  /\_/\ ", 13, 10
    db " ( o.o )", 13, 10
    db "  > ^ < ", 13, 10, 0

ship_art:
    db "     ..#*-*##*#*=-:..-+:..........-=...:::..::.::......:::......", 10
    db " .:@%+@@@@@@+##.#@@@%.....:.-@@@@*.=@*..+@:*@@@@@=.@@@@@-...", 10
    db " ..@%=@@@@@@+##-@@@@@*......#@@@@@-.@%:.*@.*@@@@@=.@@@@@@:..", 10
    db " ..@%=:=@@-..+++@@:+@%.....:@@==@@+.@@:.%@.*@=.....@%-+@@*..", 10
    db " ..@%:=-@@=..:.=@@.-%%.....:@@..%@+.%@-:@*.*@=.....@%:.#@*..", 10
    db " ..@%:.=@@-....-@@%........:@@..%@+.+@+:@=.*@=.....@@:.#@+:.", 10
    db " ..@%:.-@@-.....#@@*.......:@@..%@+.-@%-@-.*@*+=...@@*#@%...", 10
    db " ..@%:.-@@-.....:%@@*......-@@..%@+.:@@+@-.*@@@@-..@@@@@-...", 10
    db "...@%:.=@@-......:@@@-.....:@@..%@+.:@@@@:.*@@@@:..@@@@@@...", 10
    db "...@%:.=@@-....::.:@@%.....:@@..%@+..#@@#:.*@-.....@#::@@:..", 10
    db "...@%:.=@@:....#@-.*@%.....:@@..%@+..+@@*..*@=.....@%:.%@-..", 10
    db " ..@%:.=@@:....*@@=%@#.....:@@==@@-..+@@+..*@=.....@%:.%@-..", 10
    db " ..@%:.=@@:....:@@@@@.......*@@@@%...=@@+..*@@@@@+.@%:.%@-..", 10
    db " ..@#:.=%%:.....=@@@=.......:%@@%....-@@=..*@@@@@+.@%:.%@-..", 10
    db " .............................::......::...::----:.--..--:..", 10
    db " ....................                  .....................", 10, 0


tree_art:
    db "   *   ", 13, 10
    db "  ***  ", 13, 10
    db " ***** ", 13, 10
    db "*******", 13, 10
    db "  |||  ", 13, 10, 0

chud_art:
    db "        ..:-=++++=-:......       ", 10
    db "     .+@@@@%#######@@@@@@@@%.    ", 10
    db "    .+@+.              ...-@:    ", 10
    db "    .@-       :.    .:    -@=    ", 10
    db "    =@- .     .-   .:.    .%=.=  ", 10
    db "  ..-@. .@@@@%:.: :..*%@@@-:.:.  ", 10
    db "  .-:. .=.-@=:++++++.=*%=+..-    ", 10
    db "    :+. -:..::::  :=.....-...                Nothing ever", 10
    db "     .:        -  .-       :.                Happens...", 10
    db "     .:        -   -.     .=.    ", 10
    db "     .:       :=:.-=.     ..                 It's truly over...", 10
    db "      ..     ..  . ..:.   :.     ", 10
    db "      .-  .-..-:.=-.=..= .=      ", 10
    db "       :. .:+:.....::.=:.-.      ", 10
    db "        :.. .:.. .::=. .=.       ", 10
    db "         .-.  .::::  .:.         ", 10
    db "           .=.     .-.           ", 10
    db "            ..:---..             ", 10, 0


mini_cat_art:
    db " /_/ ", 13, 10
    db "(o.o)", 13, 10
    db " ^ ^ ", 0

mini_ship_art:
    db "  |  ", 13, 10
    db " \|/ ", 13, 10
    db " -0- ", 0

mini_tree_art:
    db "  *  ", 13, 10
    db " *** ", 13, 10
    db "*****", 13, 10
    db " ||| ", 0

mini_chud_art:
    db " @@@ ", 13, 10
    db "@@@@%", 13, 10
    db " %@# ", 0

gallery_title db "ASCII Art Gallery - Miniature View", 13, 10, 0
art_separator db "----------------", 0





; Memory info data
mem_title db "Memory Information", 13, 10, 0
mem_kernel db "Kernel base: 0x7E00", 13, 10, 0
mem_kernel_size db "Kernel size: 16 KB", 13, 10, 0
mem_total db "Total RAM: 640 KB", 13, 10, 0
mem_available db "Available: ~624 KB", 13, 10, 0
mem_layout db "", 13, 10, 0





; Space Invaders game data
invaders_instructions db "Space Invaders - A/D to move, SPACE to shoot", 13, 10, \
                      "Q to quit, Destroy all aliens!", 13, 10, \
                      "Press any key to start...", 13, 10, 0
invaders_game_over db "Game Over! Press any key to return.", 13, 10, 0
invaders_win db "You Win! All aliens destroyed!", 13, 10, 0
invaders_score_msg db "Score: ", 0
invaders_aliens_left_msg db "Aliens: ", 0

; Space Invaders game state
player_x db 0
player_bullet_x db 0
player_bullet_y db 0
player_bullet_active db 0
alien_x times 30 db 0   
alien_y times 30 db 0
alien_active times 30 db 1 
alien_direction db 1      
alien_speed db 15       
alien_bullet_x db 0
alien_bullet_y db 0
alien_bullet_active db 0
invaders_score dw 0
aliens_remaining db 30
game_active db 1


; Notepad data
notepad_instructions db "Notepad - Type text, Backspace to delete, Enter for new line", 13, 10, \
                     "ESC to exit, Arrow keys to move cursor", 13, 10, \
                     "Press any key to start...", 13, 10, 0
notepad_exit_msg db "Notepad closed.", 13, 10, 0
notepad_status db "Editing | ESC to exit", 0

; Notepad state
notepad_buffer times 585 db 0  
cursor_x db 0
cursor_y db 0
buffer_pos dw 0







; Typing game data
type_instructions db "TYPING GAME - Type the words correctly!",13,10,\
                   "Press any key to start...",13,10,0
type_game_over_msg db "Game Over! Press any key to return.",13,10,0
type_score_msg db "Score: ",0
type_lives_msg db "Lives: ",0
type_final_score db "Final Score: ",0
type_prompt db "Type: ",0

; Word list
type_words:
    db "HELLO",0
    db "WORLD",0  
    db "CODE ",0
    db "BYTE ",0
    db "STACK",0
    db "ARRAY",0
    db "INPUT",0
    db "PRINT",0
    db "CACHE",0

; Game state
type_score dw 0
type_lives db 3
current_word_pos db 0
type_buffer times 16 db 0







; System info messages
sysinfo_msg db "System Information:",13,10,\
             "CPU: 8086/8088 Compatible",13,10,\
             "Base Memory: 640KB",13,10,\
             "Video: VGA 80x25 Text Mode",13,10,\
             "Boot Device: Floppy Drive",13,10,\
             "Kernel: simpleOS v2.0",13,10,\
             "Mode: 16-bit Real Mode",13,10,0

; Disk info messages  
diskinfo_msg db "Disk Information:",13,10,\
              "Drive A: 1.44MB Floppy",13,10,\
              "Drive C: Not Present",13,10,\
              "Sector Size: 512 bytes",13,10,\
              "Heads: 2, Cylinders: 80",13,10,\
              "Sectors/Track: 18",13,10,0

; Optional detection messages
memory_detected_msg db "Extended memory: ",0
disk_params_msg db "Disk parameters detected",13,10,0
kb_msg db " KB",13,10,0






buffer times 64 db 0
times 16384-($-$$) db 0