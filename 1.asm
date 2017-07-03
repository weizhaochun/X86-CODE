        org  0000h
	ljmp start
	org  0030h
start:  mov  sp,#60h
loop:	mov	p0,#0dh
	mov	p1,#11110111b
	lcall	delay
	mov	p0,#99h
	mov	p1,#11111011b
	lcall	delay
	mov	p0,#49h
	mov	p1,#11111101b
	lcall	delay
	mov	p0,#41h
	mov	p1,#11111110b
	lcall	delay
	sjmp loop

delay:	push 01h
        push 02h
	mov  r1,#00h
delay1: mov  r2,#09h
        djnz r2,$
        djnz r1,delay1
	pop  02h
	pop  01h
	ret

	end
