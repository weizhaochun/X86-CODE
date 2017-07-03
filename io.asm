        org  0000h
	ljmp start
	org  0030h
start:  mov  sp,#60h
        mov  a,#0feh
loop:   mov  p1,a
        lcall delay
	jb	p0.0,loop1
	rl	a
	jmp	loop2
loop1:	rr	a
loop2:	sjmp loop

delay:	push 01h
        push 02h
	mov  r1,#00h
delay1: mov  r2,#00h
        djnz r2,$
        djnz r1,delay1
	pop  02h
	pop  01h
	ret

	end