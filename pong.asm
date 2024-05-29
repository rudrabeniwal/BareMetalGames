BITS 16 ; the code will use 16-bit instructions
org 0x7C00 ; 0x7C00, the typical load address for bootloaders

start:
    cli ; clear interrupts
    xor ax, ax 
    mov ds, ax ; data segment to zero
    mov es, ax ; extra segment to zero
    mov ss, ax ; stack segment to zero
    mov sp, 0x7C00 ; stack pointer to end of bootloader

    ; set video mode to 320x200 256-color
    mov ax, 0x13
    int 0x10

    call init_game

game_loop:
    call draw_game
    call handle_input
    call update_ball
    jmp game_loop

init_game:
    ; initialize paddle and ball positions
    mov word [paddle_y], 90
    mov word [ball_x], 160
    mov word [ball_y], 100
    mov word [ball_dx], 1
    mov word [ball_dy], 1
    ret

draw_game:
    ; clear screen
    call clear_screen

    ; draw paddle
    mov bx, [paddle_y]
    call draw_paddle

    ; draw ball
    mov ax, [ball_x]
    mov bx, [ball_y]
    call draw_ball
    ret

clear_screen:
    mov ax, 0A000h ; In real mode (16-bit mode), memory is accessed through segments, and 0xA000 is the segment address where video memory starts in 256-color mode.
    mov es, ax ; The ES register will now point to the video memory segment
    xor di, di ; DI stands for Destination Index and is used here to point to the current position within the ES segment (video memory). By setting it to 0, it starts at the beginning of the video memory segment.
    mov cx, 320*200 ; This instruction sets the CX register to 64,000. The CX register is used as a counter for repeating instructions. Here, it counts the number of pixels on the screen
    xor al, al ; we are specifying that the value to be written to video memory is 0, which typically represents the color black in 256-color mode
    rep stosb ; rep stosb: This is a repeat instruction. It repeats the stosb (store byte) instruction CX times.
              ; stosb: stosb stores the value in AL (which is 0) into the memory location pointed to by ES:DI (video memory starting at segment 0xA000 and offset DI).
              ; After storing the value, DI is automatically incremented to point to the next byte in the segment.
              ; rep prefix causes the stosb instruction to repeat CX times (which is 64,000), effectively setting all 64,000 pixels to the color black.
    ret

draw_paddle:
    ; draw a paddle at (10, bx)
    mov ax, 0A000h
    mov es, ax
    mov di, bx
    shl di, 8
    shl di, 2
    add di, 10
    mov cx, 10
.draw_segment:
    mov [es:di], byte 0x0F
    add di, 320
    loop .draw_segment
    ret

draw_ball:
    ; draw the ball at (ax, bx)
    mov ax, 0A000h
    mov es, ax
    mov di, bx ; Move the value of BX (the y-coordinate) into DI. The BX register holds the y-coordinate of the ball
    ; calculate the offset for y coordinate | offset = y × width + x
    shl di, 8 ; Shift DI left by 8 bits. This is equivalent to multiplying DI by 256
    shl di, 2 ; shl di, 2: Shift DI left by 2 more bits. This is equivalent to multiplying the result by 4.
    ; y × 256 × 4 = y × 1024
    ; Multiplying by 1024 is a bitwise shift approximation that makes the calculation easier and faster in assembly
    ; Example: Drawing a Pixel at (50, 20)
    ; i'll only explain:
    ; shl di, 8      DI = 20 * 256 = 5120
    ; shl di, 2      DI = 5120 * 4 = 20480
    ; add di, ax     DI = 20480 + 50 = 20530
    ; ES:DI translates to 0xA000:20530 in segment notation.
    ; In linear address terms, this is calculated as (0xA000 * 16) + 20530 = 655360 + 20530 = 675890.
    ; The pixel at (50, 20) on the screen is now set to color 0x0F in video memory.
    add di, ax
    mov [es:di], byte 0x0F ; mov [es], byte 0x0F: Store the byte value 0x0F (which represents a specific color, typically white or bright) at the memory address pointed to by ES:DI
    ret

handle_input:
    ; Check for keyboard input
    mov ah, 0x01 ; This instruction prepares the CPU to call a BIOS interrupt to check for keyboard input.
    int 0x16 ; This is the BIOS interrupt for keyboard services.
    ; With AH set to 0x01, int 0x16 checks if there is a key pressed.
    jz .no_key ; The function will return if no key is pressed.
    mov ah, 0x00 ; Load the AH register with 0x00 to prepare for reading the key press using the BIOS interrupt (int 0x16).
    int 0x16 ; Call the BIOS interrupt to read the key press. The key code is returned in the AL register.
    cmp al, 0x48 ; up arrow key
    jne .check_down
    mov cx, [paddle_y]
    dec cx
    mov [paddle_y], cx
    jmp .no_key

.check_down:
    cmp al, 0x50 ; down arrow key
    jne .no_key
    mov cx, [paddle_y]
    inc cx
    mov [paddle_y], cx

.no_key:
    ret

update_ball:
    ; update ball position and check for collisions
    mov ax, [ball_x]
    add ax, [ball_dx]
    mov [ball_x], ax
    mov bx, [ball_y]
    add bx, [ball_dy]
    mov [ball_y], bx
    ; check for screen boundaries
    cmp ax, 0
    jge .check_right
    neg word [ball_dx]
    jmp .end_update

.check_right:
    cmp ax, 319
    jle .check_top
    neg word [ball_dx]
    jmp .end_update

.check_top:
    cmp bx, 0
    jge .check_bottom
    neg word [ball_dy]
    jmp .end_update

.check_bottom:
    cmp bx, 199
    jle .end_update
    neg word [ball_dy]

.end_update:
    ret

paddle_y dw 0
ball_x dw 0
ball_y dw 0
ball_dx dw 0
ball_dy dw 0

times 510-($-$$) db 0
dw 0xAA55
