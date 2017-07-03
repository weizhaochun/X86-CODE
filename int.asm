	ORG	0000H
	LJMP	0040H
	ORG	0003H
	LJMP	INT_0
	ORG	0013H
	LJMP	INT_1

	ORG	0040H
START:	MOV	SP,#60H	
	SETB	PX1
	MOV	TCON,#00H	
	SETB	EX0	
	SETB	EX1
	SETB	EA
	MOV	A,#00H
LOOP:	MOV	P1,A	
	LCALL	DELAY		
	CPL	A
	SJMP	LOOP

INT_0:	PUSH	ACC	
	MOV	A,#3FH
LOOP1:	MOV	P1,A
	LCALL	DELAY		
	RR	A		
	JNB	P3.2,LOOP1
	POP	ACC
	RETI

INT_1:	PUSH	ACC	
	MOV	A,#0FEH
LOOP2:	MOV	P1,A
	LCALL	DELAY		
	RL	A		
	JNB	P3.3,LOOP2
	POP	ACC
	RETI

DELAY:	PUSH	00H	
	PUSH	01H
	MOV	R1,#00H
LOOP3:	MOV	R0,#00H
	DJNZ	R0,$
	DJNZ	R1,LOOP3
	POP	01H
	POP	00H
	RET

	END
