[org 0x0100]
jmp Start

score: db "Score:"
scoresize:dw 6
scorecount:dw 0
tickcount: dw 0
check: dw 0
index: dw 0
restore: dw 0
oldisr: dd 0
oldisr2:dd 0
stop: dw 0
flag: dw 0



;****************************************
clrscr:
        push es
		push ax
		push cx
		push di
		mov ax, 0xb800
		mov es, ax ; point es to video base
		xor di, di ; point di to top left column
		mov ax, 0x0720 ; space char in normal attribute
		mov cx, 2000 ; number of screen locations
		cld ; auto increment mode
		rep stosw ; clear the whole screen
		pop di
		pop cx
		pop ax
		pop es
		ret

;*****************************************
greenpoints:
push ax
push bx
push cx
push di
push es

mov ax,0xb800
mov es,ax
mov di,40
mov cx,25
mov ax,0x2020
mov bx,115

loop1:
mov [es:di],ax
add di,bx
loop loop2

pop es
pop di
pop cx
pop bx
pop ax
ret
;-----------------------------------------
redpoints:
push ax
push bx
push cx
push es
push di

mov ax,0xb800
mov es,ax
mov bx,198
mov ax,0x4020
mov cx,15
mov di,114

loop2:
mov [es:di],ax
add di,bx
loop loop2

pop di
pop es
pop cx
pop bx
pop ax
ret

;*****************************************
ScoreBoard:
		pusha
		push 0xb800
		pop es
		mov si,score
		mov cx,[scoresize]
		mov di,140
		mov ah,0x07
		cld
		SB:
		    lodsb
			stosw
			loop SB
		mov bx,[scorecount]
		push bx
		call printnum
		popa
		ret


printnum: 
        push bp
		mov bp, sp
		push es
		push ax
		push bx
		push cx
		push dx
		push di
		mov di,152
		mov ax, 0xb800
		mov es, ax ; point es to video base
		mov ax, [bp+4] ; load number in ax
		mov bx, 10 ; use base 10 for division
		mov cx, 0 ; initialize count of digits
		nextdigit: mov dx, 0 ; zero upper half of dividend
		div bx ; divide by 10
		add dl, 0x30 ; convert digit into ascii value
		push dx ; save ascii value on stack
		inc cx ; increment count of values
		cmp ax, 0 ; is the quotient zero
		jnz nextdigit ; if no divide it again
		nextpos: pop dx ; remove a digit from the stack
		mov dh, 0x07 ; use normal attribute
		mov [es:di], dx ; print char on screen
		add di, 2 ; move to next screen location
		loop nextpos ; repeat for all digits on stack
		pop di
		pop dx
		pop cx
		pop bx
		pop ax
		pop es
		pop bp
		ret 2
		
		
		

;*****************************************
moveasterisk:
	push es
	push ax
	push bx
	push dx
	push cx
	push di
	mov ax, 0xb800
	mov es, ax
	mov ax, 0x072A;Asterisk
	mov cx,[cs:check]
	cmp cx, 0;right
	je right
	cmp cx, 1;down
	je down1
	cmp cx, 2;left
	je left1
	cmp cx, 3;up
	je up1
	down1:
		jmp down
	
	right:
		mov di, [cs:index]
		mov bx, word[cs:restore]
		mov word[es:di], bx	
		cmp bx,0x2020;green
		jne skip3
		;update scoreboard
		mov word[es:di],0x0720
		mov dx,[scorecount]
		inc dx
		mov [scorecount],dx
		push dx
		call printnum
		skip3:
			cmp bx,0x4020;red
			jne cont
			mov word[flag],1;terminating condition
		cont:
			add di, 2
			cmp di,158
			jne skip1
			mov di,0
		skip1:;update
			mov [cs:index], di
			mov bx, word[es:di]
			mov word[cs:restore], bx
			mov word[es:di], ax


	match_di1:
		jmp function_ret

	left1:
		jmp left
	up1:
		jmp up

	down:
		;restore
		mov di, [cs:index]
		mov bx, word[cs:restore]
		mov word[es:di], bx		
		
		cmp bx,0x2020;grean
		jne skip4
		;update scoreboard
		mov word[es:di],0x0720
		mov dx,[scorecount]
		inc dx
		mov [scorecount],dx
		push dx
		call printnum
		skip4:
			cmp bx,0x4020;terminate on red
			jne cont1
			mov word[flag],1
		cont1:
			add di, 160
			cmp di,4000
			jna skip
			sub di,4000
		skip:
			;update values
			mov [cs:index], di
			mov bx, word[es:di]
			mov word[cs:restore], bx
			mov word[es:di], ax


	match_di2:
			jmp function_ret
		


	left:
		;restore
		mov di, [cs:index]
		mov bx, word[cs:restore]
		mov word[es:di], bx	
		cmp bx,0x2020;green
		jne skip5
		;update score
		mov word[es:di],0x0720
		mov dx,[scorecount]
		inc dx
		mov [scorecount],dx
		push dx
		call printnum
		skip5:
			cmp bx,0x4020;TERMINATE ON RED
			jne cont2
			mov word[flag],1
		cont2:
			;CONTINUE AND UPDATE
			sub di, 2
			mov [cs:index], di
			mov bx, word[es:di]
			mov word[cs:restore], bx
			mov word[es:di], ax
	match_di3:
			jmp function_ret

	up:
		;RESTORE VALUES
		mov di, [cs:index]
		mov bx, word[cs:restore]
		mov word[es:di], bx
		cmp bx,0x2020;GREEN
		jne skip6
		;UPDATE Score
		mov word[es:di],0x0720
		mov dx,[scorecount]
		inc dx
		mov [scorecount],dx
		push dx
		call printnum
		skip6:	
		;TERMINATE ON RED
		cmp bx,0x4020
		jne cont3
		mov word[flag],1
		cont3:
		;CONTINUE AND UPDATE
		sub di, 160
		cmp di,4160
		jna skip2
		add di,4000
		skip2:
		mov [cs:index], di
		mov bx, word[es:di]
		mov word[cs:restore], bx
		mov word[es:di], ax

	match_di4:
			jmp function_ret

	function_ret:
		pop di
		pop cx
		pop dx
		pop bx
		pop ax
		pop es
		ret

;****************************
;keyboard Interrupt
kbisr:
	push ax
	push es
	in al, 0x60
	cmp al,0x50;Down Arrow
	jne nextcmp
	mov cx,1
	mov [cs:check], cx
	nextcmp:;Right Arrow
		cmp al,0x4D
		jne nextcmp2
		mov cx,0
		mov [cs:check],cx
	nextcmp2:;Left Arrow
		cmp al,0x4B
		jne nextcmp3
		mov cx,2
		mov [cs:check],cx
	nextcmp3:;Up Arrow
		cmp al,0x48
		jne ending
		mov cx,3
		mov [cs:check],cx
	ending:
		pop es
		pop ax
		jmp far [cs:oldisr]
		

;Timer Interrupt	
timer:		
    push ax
	push cx
	mov cx, [stop]
	cmp cx, 1
	je notasec
	inc byte [cs:tickcount]
   	cmp byte[cs:tickcount], 17
   	jne notasec
	call moveasterisk
    mov byte[cs:tickcount], 0

	notasec:
		mov al, 0x20
		out 0x20, al
		pop cx
		pop ax
		iret
		
;**************************************

Start:
		call clrscr
		call greenpoints
		call redpoints
		xor ax, ax
		mov es, ax
		mov ax, [es:8*4]
		mov [oldisr], ax
		mov ax, [es:8*4+2]
		mov [oldisr+2], ax
		xor ax, ax
		mov es, ax
		xor ax, ax
		mov es, ax
		mov ax, [es:9*4]
		mov [oldisr2], ax
		mov ax, [es:9*4+2]
		mov [oldisr2+2], ax
		xor ax, ax
		mov es, ax
		cli
		mov word [es:8*4], timer
		mov [es:8*4+2], cs
		mov word [es:9*4], kbisr
		mov [es:9*4+2], cs
		sti
		l7:cmp word[flag],1
		jne l7
		mov ax,[flag]
		call clrscr
		mov ax,[oldisr]
		mov bx,[oldisr+2]
		cli
		mov [es:8*4],ax 
		mov [es:8*4+2],bx
		sti
		mov ax,[oldisr2]
		mov bx,[oldisr2+2]
		cli
		mov [es:9*4],ax 
		mov [es:9*4+2],bx
		sti
		mov ax, 0x4c00
		int 0x21