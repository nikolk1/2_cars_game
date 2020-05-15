dosseg
model small
.data
stack
open_message db "please press enter to continue$"
button db "play$"
score db "Score: $"
game_name db "2 CARS$"
points db 30h,30h,30h
car1_loc dw 160*20+46
car2_loc dw 160*20+106
replay_button db "replay$"
obj1 dw ?
obj2 dw ?
external_objects db 1,2,1,2,1,1,2,1,1,2,2,1,2,'$'
locations_pos dw 160*3+46,160*3+106,160*3+66,160*3+86,160*3+46,160*3+106,160*3+66,160*3+106,160*3+66,160*3+106,160*3+66,160*3+86,160*3+46,160*3+106,160*3+66,160*3+86,160*3+46,160*3+106,'$'
flag db 0
crash_flag db 0
end_flag db 0
point_flag db 0
skip_flag db 0
counter dw 4
direction_flag db 0

;car 1 - red
;car 2 - blue
.code
;-------------------------functions area---------------------------
;this function prints lines to the screen
print_lines proc
	lines:	mov es:[si],dx
			add si,2
	loop lines
	ret
endp

;this function prints columns to the screen
print_column proc
	columns:mov es:[si],dx
			add si,160
	loop columns
	ret
endp

;this function prints pixel col-2, row-1
pixel proc
	push cx
	push si
	call print_column
	pop si
	add si,2
	pop cx
	call print_column
	ret
endp

;This function clears the screen
cls proc
	mov cx,2000
	mov si,0
	mov dl,20h
        mov dh,01110111b
	call print_lines
	ret
endp

;this function cancel the blink and add more optional colors
colors proc
        mov ax, 1003h
        mov bx, 0
        int 10h
        ret
endp

;this function prints the lines on the road
white_lines proc
	mov dh,11111111b
        mov si,160*0+100
	mov cx,25
	call print_column
        mov si,160*0+60
	mov cx,25
	call print_column
	ret
endp

;this function prints the grass and limit between the two cars
screen proc
        mov si,160*0+80
	mov cx,25
	mov dl,20h
        mov dh,10001000b
	call print_column

	mov si,0
	mov dl,20h
	mov dh,10101010b
        mov cx,25
        area1:  push cx
                mov cx,19
                call print_lines
                add si,122
                pop cx
        loop area1
        mov si,160*0+120
        mov cx,25
        area2:  push cx
                mov cx,20
                call print_lines
                add si,120
                pop cx
	loop area2
        ret        
endp

;this function prints the start screen
start_features proc
	mov si,160*13+72
	mov cx,3
        mov dh,10001011b
	b1:	push cx
		mov cx,8
		call print_lines
		add si,144
		pop cx
	loop b1
        mov si,160*14+76
	lea bx,button
	mov cx,4
        call print_string
	mov si,160*24+50
	mov dh,01110000b
	mov cx,30
	lea bx,open_message
	call print_string
	ret
endp

;this function prints the name of the game
print_name proc
	mov dh,00001111b
	mov si,160*7+74
	lea bx,game_name
	mov cx,6
	call print_string
	ret
endp

;this function prints the car
print_car proc 
	mov dl,20h
        mov cx,3
        car:push cx
            mov cx,4
            call print_lines
            add si,152
            pop cx
	loop car
	ret
endp

;this function prints obstacles for car1
obstacles_1 proc
	mov dh,01000100b
        mov dl,20h
        mov cx,5
	call print_lines
	ret
endp

;this function prints obstacles for car2
obstacles_2 proc
    mov dh,00010001b
    mov dl,20h
    mov cx,5
    call print_lines
    ret
endp

;this function compare the letter which was entered 
move_car proc
        start_cmp: cmp al,27
                   jne check_left_1
                   jmp exit
        check_left_1:   cmp al,'a'
                        jne check_left_2
                        lea bx,car1_loc
                        mov direction_flag,1
                        mov dh,11001100b
                        jmp e6
        check_left_2:   cmp al,'4'
                        jne check_right_1
                        lea bx,car2_loc
                        mov direction_flag,1
                        mov dh,10011001b
                        jmp e6
        check_right_1:  cmp al,'d'
                        jne check_right_2
                        lea bx,car1_loc
                        mov direction_flag,2
                        mov dh,11001100b
                        jmp e6
        check_right_2:  cmp al,'6'
                        jne input_again
                        lea bx,car2_loc
                        mov direction_flag,2
                        mov dh,10011001b
                        jmp e6
	input_again:	mov ah,0
                        int 16h
                        jmp start_cmp
	e6:	call check_limits
	ret
endp

;this function checks if the car can move left without passing the limits
check_limits proc
	mov si,[bx]
	cmp direction_flag,1
	jne r_limits
	sub si,16
	jmp check_limit
	r_limits:	add si,16
	check_limit:	mov ax,es:[si]
                        cmp ah,01110111b
                        je check1
                        jmp e4
        check1: cmp dh,11001100b
			je smaller
			cmp si,160*20+80
			jg c1
			jmp e4
			smaller:cmp si,160*20+80
                                jl c1
                                jmp e4
	c1:	call move 
	e4:	ret
endp

;moves the car to the right
move proc
	mov di,[bx]
	mov cx,10
	step:	push cx
			call fix_background
			cmp direction_flag,1
			je mov_left
			add di,2
			jmp c_step
			mov_left:	sub di,2
        c_step:         mov [bx],di ;updating the position in the data
			push si
			call wrong_move
			pop si
			mov si,di
			call print_car
			mov di,[bx]
			pop cx
	loop step
	ret
endp

;this function fix the background back after the car move 
fix_background proc
	push dx
	call white_lines
	call print_car
	mov dh,01110111b
	mov si,di
	call print_car
	pop dx
        e1: ret
endp

;this function prints the score board
print_score_board proc
	push si
	push bx
	lea bx,score
	mov dh,11101000b
        mov si,160*2+70
	mov cx,7
	call print_string
	lea bx,points
	mov cx,3
        show_points:    mov dl,[bx]
                        mov es:[si],dx
                        add si,2
                        inc bx
        loop show_points
	pop bx
	pop si		
	ret
endp

;this function prints string to the screen
print_string proc
	string:	push cx
                mov cx,1
                mov dl,[bx]
                call print_lines
                inc bx
                pop cx
	loop string
	ret
endp

;this function updating the points on the screen
change_points proc
	lea bx,points
	add bx,2
	mov cx,2
	change_score:	mov al,[bx]
                        cmp al,39h
                        je zero
                        inc al
                        mov [bx],al
                        jmp next
                        zero:   mov [bx],byte ptr 30h
                                dec bx
	loop change_score
	next:	mov cx,0
	ret
endp


;this function prints the points on the screen
print_points proc ;the points to collect on the screen
	mov dl,20h
	mov dh,11101110b
	mov es:[si],dx
	ret
endp

;this function checks if the user pressed enter to start the game
press_start proc
	mov ah,7
	int 21h
	cmp al,27
	jne continue
	jmp exit
	continue:	cmp al,13
                        jne again
                        jmp e2
	again:	call start
	e2:	ret
endp

;this function prints the letter g
g proc
	mov si,160*2+16
	mov dh,11111111b
	mov dl,20h
	mov cx,2
	g1:	push cx
		mov cx,6
		call print_lines
		mov si,160*6+16
		pop cx
	loop g1
	
	mov si,160*3+12
	mov cx,3
	call pixel

	mov si,160*4+24
	mov cx,2
	call pixel

	mov si,160*4+22
	mov cx,1
	call print_lines
	ret
endp

;this function prints the letter a
a proc
	mov si,160*2+34
	mov cx,4
	call print_lines
	mov si,160*3+30
	mov cx,2
	a1:	push cx
		mov cx,4
		call pixel
		mov si,160*3+42
		pop cx
	loop a1
	mov si,160*4+30
	mov cx,8
	call print_lines
	ret
endp

;this function prints the letter m
m proc
	mov si,160*2+48
	mov cx,2
	m1:	push cx
		mov cx,5
		call pixel
		mov si,160*2+60
		pop cx
	loop m1

	mov si,160*3+52
	mov es:[si],dx
	
	mov si,160*4+54
	mov cx,1
	call pixel
	
	mov si,160*3+58
	mov es:[si],dx
	ret
endp

;this function prints the letter e
e proc
	push si
	mov cx,3
	e3:	push cx
		mov cx,6
		call print_lines
		add si,308
		pop cx
	loop e3
	pop si
	mov cx,5
	call pixel
	ret
endp

;this function prints the letter o
o proc
	mov si,160*2+90
	mov cx,2
	o1:	push cx
		mov cx,5
		call print_lines
		mov si,160*6+90
		pop cx
	loop o1
	mov si,160*3+86
	mov cx,2
	o2:	push cx
		mov cx,3
		call pixel
		mov si,160*3+100
		pop cx
	loop o2
	ret
endp

;this function prints the letter v
v proc
	mov si,160*2+106
	mov cx,2
	v1:	push cx
		mov cx,3
		call pixel
		mov si,160*2+118
		pop cx
	loop v1
	
	mov si,160*5+110
	mov es:[si],dx
	
	mov si,160*6+112
	mov cx,1
	call pixel
	
	mov si,160*5+116
	mov es:[si],dx
	ret
endp

;this function prints the letter r
r proc
	mov si,160*2+138
	mov cx,2
	r1:	push cx
		mov cx,5
		call print_lines
		mov si,160*4+138
		pop cx
	loop r1
	mov si,160*2+138
	mov cx,5
	call pixel
	mov si,160*3+148
	mov cx,2
	call pixel
	mov cx,2
	mov si,160*5+144
	r2:	push cx
		mov cx,1
		call pixel
		mov si,160*6+148
		pop cx
	loop r2
	ret
endp

;this function checks if the car while moving left or right, crash/meet point/obstcale
wrong_move proc
	mov si,[bx]
	mov cx,5
	cmp direction_flag,1
	jne right_move
	sub si,2
	jmp crash_l
	right_move:	add si,2
	crash_l:	mov ax,es:[si]
                        cmp ah,01000100b
                        je e8
                        cmp ah,00010001b
                        je e8
                        cmp ah,11101110b
                        jne co_check
                        mov point_flag,1
                        jmp e9
                co_check:       add si,160
        loop crash_l
	jmp e9
	e8:	call game_over_screen
	e9:	ret
endp

;this function cleans where the obstacle was
clear proc
	mov dh,01110111b
	mov dl,20h
	mov cx,5
	call print_lines
	ret
endp

;this function cleans where the point was
clear_p proc
	mov dh,01110111b
	mov dl,20h
	mov es:[si],dx
	call restart_car
	ret
endp

;this function stops the run of the program for...
stop proc
	push dx
	mov cx,02h
	mov dx,100h
	mov ah,86h
	int 15h
	pop dx
	ret
endp

;this function checks if the car crush with an obsticale
check_crash proc
	push ax
	mov cx,5                   
	add si,160
        obs:    mov ax,es:[si]
		cmp ah,01110111b
		je searching
		cmp si,160*24
		jg searching
		mov crash_flag,1
		jmp e7
	searching:	add si,2
        loop obs
	e7:	pop ax
	ret
endp

;this function checks if the objects reached the end of the screen
check_end_screen proc
	push si
	add si,160
	cmp si,160*24
	jl e13
	mov end_flag,1
        e13:    pop si
        ret
endp

;checks where to print obsticale and where to print point 
check_option proc
        op1:    mov al,[di]
		cmp al,1
		jne op2
		call option1
		jmp endd
        op2:    cmp al,2
		jne restart
		call option2
		jmp endd
	restart:lea di,external_objects
                call zeroing
                jmp op1
	endd:	ret
endp

;this function move the objects - option 1
option1 proc
	mov si,obj1
	call clear
	mov si,obj1
	call check_end_screen
	add obj1,160
	mov si,obj1
	call check_crash
	mov si,obj1
	call obstacles_1

	mov si,obj2
	call clear_p
	mov si,obj2
	cmp skip_flag,1
	je fin1
	add obj2,160
	mov si,obj2
	call print_points
	call check_collect
	fin1:	ret
endp

;this function move the objects - option 2
option2 proc
	mov si,obj1
	call clear_p
	mov si,obj1
	cmp skip_flag,1
	je obj2_con
	add obj1,160
	mov si,obj1
	call print_points
	call check_collect

	obj2_con:	
	mov si,obj2
	call clear
	call check_end_screen
	mov si,obj2
	add obj2,160
	mov si, obj2
	call check_crash
	mov si,obj2
	call obstacles_2
	ret
endp

;this function checks if the car collected a point
check_collect proc
	push ax
	add si,160
	mov ax, es:[si]
	cmp ah,01110111b
	je end1
	mov point_flag,1
	end1:	pop ax
	ret
endp

;this function checks the flag and running acoording to the flags
check_flags proc
	push ax
	cmp crash_flag,1
	je finish
	mov al,point_flag
	mov ah,end_flag
	moving:
			cmp al,1
			jne cmp_end
			cmp skip_flag,1
			je check_skip
			call change_points
			call print_score_board
			mov skip_flag,1
			jmp cmp_end
	check_skip:	cmp ah,1
                        je next_obj
                        jmp fin
	cmp_end:	cmp ah,1
                        je finish
                        jmp fin
	next_obj:	call delete
                        call zeroing
                        inc di
                        jmp fin
	finish:	call game_over_screen
        fin:    pop ax
	ret
endp

;this function restart the flags for the next round of objects
zeroing proc
	lea bx,locations_pos
	add bx,counter
	mov ax,[bx]
	cmp ax,'$'
	je reset
	change_loc:	mov ax,[bx]
                        mov obj1,ax
                        add bx,2
                        mov ax,[bx]
                        mov obj2,ax
                        add bx,2
                        add counter,4
                        jmp z
	reset:	lea bx,locations_pos
                mov counter,0                                                                                                                                                                                                                                                                           
                jmp change_loc
	z:	mov flag,0
                mov crash_flag, 0
                mov point_flag, 0                                                                                                                                                                                                                                                                                                                                                       
                mov skip_flag,0
                mov end_flag,0
	ret
endp

;this function deletes the objects when they reach the end of the screen
delete proc
	mov cx,4
	mov si,160*24+46
	clean:	push cx
                mov cx,5
                mov dh,01110111b
                call print_lines
                add si,10
                pop cx
	loop clean
	ret
endp

;this function restarts the locations of the car
restart_car proc
	lea bx,car1_loc
	mov si,[bx]
	mov dh,11001100b
	call print_car

	lea bx,car2_loc
	mov si,[bx]
	mov dh,10011001b
	call print_car
	ret
endp

;this function restart the variables in data segment
new_game proc
	lea bx,points
	mov cx,3
	null:	mov [bx],byte ptr 30h
                inc bx
	loop null
	mov car1_loc, 160*20+46
	mov car2_loc,160*20+106
	mov counter, word ptr 4
	mov direction_flag,0
	ret
endp

;this function prints game over screen
game_over_screen proc
	call cls
	call g
	call a
	call m
	mov si,160*2+66
	call e
	call o
	call v
	mov si,160*2+124
	call e
	call r
	mov si,160*18+70
	mov dh,11101000b
	mov cx,3
	b2:	push cx
		mov cx,10
		call print_lines
		add si,140
		pop cx
	loop b2
	mov cx,6
	lea bx,replay_button
	mov si,160*19+74
	call print_string
	mov si,160*24+50
	mov dh,01110000b
	mov cx,30
	lea bx,open_message
	call print_string
	get_input:	mov ah,7
				int 21h
	cmp al,27
	je t_exit
	cmp al,13
	jne get_input
	call zeroing
	call new_game
	jmp run
	endd1:	ret
endp

;-----------------------------main--------------------------------
start:
mov ax,@data
mov ds,ax
mov ax,0b800h
mov es,ax

run:call cls
    call colors                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    call start_features
    call print_name
    call restart_car
    call press_start

call cls
call screen
call white_lines
call print_score_board

jmp continue1
t_exit:jmp exit

continue1:
call restart_car

push dx
lea bx,locations_pos
mov dx,[bx]
mov obj1,dx
add bx,2
mov dx,[bx]
mov obj2,dx
add bx,2
pop dx

lea di,external_objects
main:  	call check_option
        call stop
        call check_flags
        input:  xor ax,ax
                mov ah,1
                int 16h
		jz main
		mov ah,0
		int 16h
		push di
		call move_car
		pop di
		jmp main

exit:	mov ah,4ch
        int 21h
        end start
