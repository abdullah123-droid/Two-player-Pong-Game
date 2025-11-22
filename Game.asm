[org 0x0100]

jmp start

paddle_width: db 6
paddle_height: db 28

paddle1_y: dw 90
paddle2_y: dw 90
ball_x: dw 160
ball_y: dw 100
ball_dx: db 3
ball_dy: db 3
score1: db 0
score2: db 0
key_w: db 0
key_s: db 0
key_up: db 0
key_down: db 0
ball_size: db 5

restart_msg: db 'Do you want to restart? (Y/N)$'
exit_msg: db 'Game exited$'

handle_input:
mov ah, 0x01
int 0x16
jz skip_esc_check

mov ah, 0x00
int 0x16
cmp al, 27
je done

skip_esc_check:
clear_buffer:
mov ah, 0x01
int 0x16
jz buffer_cleared
mov ah, 0x00
int 0x16
jmp clear_buffer

buffer_cleared:
in al, 0x60

cmp al, 0x11
je p1_up

cmp al, 0x1F
je p1_down

cmp al, 0x48
je p2_up

cmp al, 0x50
je p2_down

jmp done

p1_up:
mov ax, [paddle1_y]
cmp ax, 5
jle done
sub word [paddle1_y], 6
jmp done

p1_down:
mov ax, [paddle1_y]
cmp ax, 167
jge done
add word [paddle1_y], 6
jmp done

p2_up:
mov ax, [paddle2_y]
cmp ax, 5
jle done
sub word [paddle2_y], 6
jmp done

p2_down:
mov ax, [paddle2_y]
cmp ax, 167
jge done
add word [paddle2_y], 6

done:
ret

update_ball:
mov ax, [ball_x]
mov bl, [ball_dx]
mov bh, 0
cmp bl, 128
jb positive_dx
mov bh, 0xFF
positive_dx:
add ax, bx
mov [ball_x], ax

mov ax, [ball_y]
mov bl, [ball_dy]
mov bh, 0
cmp bl, 128
jb positive_dy
mov bh, 0xFF
positive_dy:
add ax, bx
mov [ball_y], ax
ret

check_collisions:
mov ax, [ball_y]
cmp ax, 2
jle bounce_y_top
mov bx, ax
add bx, 5
cmp bx, 198
jge bounce_y_bottom
jmp check_paddles

bounce_y_top:
mov word [ball_y], 2
mov al, [ball_dy]
mov bl, 0
sub bl, al
mov [ball_dy], bl
jmp check_paddles

bounce_y_bottom:
mov word [ball_y], 193
mov al, [ball_dy]
mov bl, 0
sub bl, al
mov [ball_dy], bl

check_paddles:
mov ax, [ball_x]
cmp ax, 16
jl check_left_paddle_collision
cmp ax, 304
jg check_right_paddle_collision
jmp check_scoring

check_left_paddle_collision:
mov ax, [ball_x]
cmp ax, 16
jg check_scoring

mov ax, [ball_y]
add ax, 2
mov bx, [paddle1_y]
sub bx, 5
cmp ax, bx
jl check_scoring

mov bx, [paddle1_y]
add bx, 33
cmp ax, bx
jg check_scoring

mov byte [ball_dx], 3
mov word [ball_x], 16
jmp check_scoring

check_right_paddle_collision:
mov ax, [ball_x]
add ax, 5
cmp ax, 310
jl check_scoring

mov ax, [ball_y]
add ax, 2
mov bx, [paddle2_y]
sub bx, 5
cmp ax, bx
jl check_scoring

mov bx, [paddle2_y]
add bx, 33
cmp ax, bx
jg check_scoring

mov al, [ball_dx]
mov bl, 0
sub bl, al
mov [ball_dx], bl
mov word [ball_x], 305
jmp check_scoring

check_scoring:
mov ax, [ball_x]
cmp ax, 5
jle score_p2
add ax, 5
cmp ax, 320
jge score_p1
jmp done_collision

score_p1:
inc byte [score1]
call reset_ball
cmp byte [score1], 7
je show_restart_screen
jmp done_collision

score_p2:
inc byte [score2]
call reset_ball
cmp byte [score2], 7
je show_restart_screen

done_collision:
ret

show_restart_screen:
mov ax, 0x0003
int 0x10

mov ah, 0x02
mov bh, 0
mov dh, 12
mov dl, 20
int 0x10

mov ah, 0x09
mov dx, restart_msg
int 0x21

wait_for_input:
mov ah, 0x00
int 0x16

cmp al, 'Y'
je restart_game
cmp al, 'y'
je restart_game

cmp al, 'N'
je exit_game
cmp al, 'n'
je exit_game

jmp wait_for_input

restart_game:
mov byte [score1], 0
mov byte [score2], 0

mov word [paddle1_y], 90
mov word [paddle2_y], 90

mov word [ball_x], 160
mov word [ball_y], 100
mov byte [ball_dx], 3
mov byte [ball_dy], 3

mov ax, 0x0013
int 0x10

ret

exit_game:
mov ax, 0x0003
int 0x10

mov ah, 0x02
mov bh, 0
mov dh, 12
mov dl, 30
int 0x10

mov ah, 0x09
mov dx, exit_msg
int 0x21

mov cx, 0x0010
mov dx, 0x0000
mov ah, 0x86
int 0x15

mov ax, 0x0003
int 0x10

mov ax, 0x4C00
int 0x21

reset_ball:
mov word [ball_x], 160
mov word [ball_y], 100
mov al, [ball_dx]
mov bl, 0
sub bl, al
mov [ball_dx], bl
ret

clear_screen:
push es
mov ax, 0xA000
mov es, ax
xor di, di
mov cx, 32000
xor ax, ax
rep stosw
pop es
ret

draw_paddles:
mov ax, [paddle1_y]
mov bx, 10
mov si, 5
call draw_rectangle

mov ax, [paddle2_y]
mov bx, 310
mov si, 11
call draw_rectangle
ret

draw_rectangle:
push es
mov dx, 0xA000
mov es, dx

mov dl, [paddle_height]
mov dh, 0
row_loop:
push bx
push ax
push dx

mov di, ax
shl di, 6
mov bp, ax
shl bp, 8
add di, bp
add di, bx

mov cl, [paddle_width]
mov ch, 0
col_loop:
mov [es:di], si
inc di
dec cx
jnz col_loop

pop dx
pop ax
pop bx
inc ax
dec dx
jnz row_loop

pop es
ret

draw_ball:
push es
mov ax, 0xA000
mov es, ax

mov ax, [ball_y]
mov bx, [ball_x]

mov di, ax
shl di, 6
mov bp, ax
shl bp, 8
add di, bp
add di, bx

mov byte [es:di], 14
mov byte [es:di+1], 14
mov byte [es:di+2], 14
mov byte [es:di+3], 14
mov byte [es:di+4], 14
add di, 320
mov byte [es:di], 14
mov byte [es:di+1], 14
mov byte [es:di+2], 14
mov byte [es:di+3], 14
mov byte [es:di+4], 14
add di, 320
mov byte [es:di], 14
mov byte [es:di+1], 14
mov byte [es:di+2], 14
mov byte [es:di+3], 14
mov byte [es:di+4], 14
add di, 320
mov byte [es:di], 14
mov byte [es:di+1], 14
mov byte [es:di+2], 14
mov byte [es:di+3], 14
mov byte [es:di+4], 14
add di, 320
mov byte [es:di], 14
mov byte [es:di+1], 14
mov byte [es:di+2], 14
mov byte [es:di+3], 14
mov byte [es:di+4], 14

pop es
ret

draw_center_line:
push es
mov ax, 0xA000
mov es, ax

mov cx, 25
mov bx, 0
loop1:
mov di, bx
shl di, 6
mov ax, bx
shl ax, 8
add di, ax
add di, 160

mov byte [es:di], 8
add di, 320
mov byte [es:di], 8
add di, 320
mov byte [es:di], 8

add bx, 8
loop loop1

pop es
ret

draw_scores:
push es
mov ax, 0xA000
mov es, ax

mov al, [score1]
mov bx, 40
mov dx, 10
call draw_digit

mov al, [score2]
mov bx, 280
mov dx, 10
call draw_digit

pop es
ret

draw_digit:
push es
push ax
push bx
push cx
push dx

mov di, dx
shl di, 6
mov bp, dx
shl bp, 8
add di, bp
add di, bx

cmp al, 0
je draw_0
cmp al, 1
je draw_1
cmp al, 2
je draw_2
cmp al, 3
je draw_3
cmp al, 4
je draw_4
cmp al, 5
je draw_5
cmp al, 6
je draw_6
cmp al, 7
je draw_7
jmp digit_done

draw_0:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
jmp digit_done

draw_1:
mov byte [es:di+1], 15
add di, 320
mov byte [es:di+1], 15
add di, 320
mov byte [es:di+1], 15
add di, 320
mov byte [es:di+1], 15
add di, 320
mov byte [es:di+1], 15
jmp digit_done

draw_2:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
jmp digit_done

draw_3:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
jmp digit_done

draw_4:
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
jmp digit_done

draw_5:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
jmp digit_done

draw_6:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
jmp digit_done

draw_7:
mov byte [es:di], 15
mov byte [es:di+1], 15
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15
add di, 320
mov byte [es:di+2], 15

digit_done:
pop dx
pop cx
pop bx
pop ax
pop es
ret

delay:
mov cx, 0x0000
mov dx, 0xC000
mov ah, 0x86
int 0x15
ret

start:
mov ax, 0x0013
int 0x10

game_loop:
call handle_input
call update_ball
call check_collisions
call clear_screen
call draw_paddles
call draw_ball
call draw_center_line
call draw_scores
call delay

mov ah, 0x01
int 0x16
jz game_loop

mov ah, 0x00
int 0x16
cmp al, 27
jne game_loop

mov ax, 0x0003
int 0x10

mov ax, 0x4C00
int 0x21