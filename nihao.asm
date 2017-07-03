	TEMPER_L	EQU	36H
	TEMPER_H	EQU	35H
	TEMPER		EQU	34H
	TEMPER_NUM	EQU	60H
	SDA	BIT	P1.0
	SCL	BIT	P1.1
	WSLA	EQU	070H
	RSLA	EQU	071H
	FLAG1		BIT	00H
	DQ		BIT	P3.3
	BUZZ		BIT	P3.1


	ORG	0000H
	LJMP	MAIN
	ORG	001BH
	LJMP	INT_T1
	ORG	0100H
MAIN:	MOV	SP,#70H
	MOV	TMOD,#10H
	MOV	TL1,#033H
	MOV	TH1,#0FEH
	SETB	ET1
	SETB	EA
LP1:	LCALL	GET_TEMPER
	LCALL	TEMPER_COV
	MOV	A,TEMPER
	
	LCALL	DISP1
	MOV	A,R6
	CJNE	A,#1EH,L2
L2:	JC	L3
	SETB	TR1
	SJMP	NEXT
L3:	CLR	TR1	
NEXT:	SJMP	LP1
	
GET_TEMPER:
	SETB	DQ
BCD:	LCALL	INIT_1820
	JB	FLAG1,S22
	LJMP	BCD
S22:	LCALL	DELAY1
	MOV	A,#0CCH
	LCALL	WRITE_1820
	MOV	A,#44H
	LCALL	WRITE_1820
	LCALL	DELAY
CBA:	LCALL	INIT_1820
	JB	FLAG1,ABC
	LJMP	CBA
ABC:	LCALL	DELAY1
	MOV	A,#0CCH
	LCALL	WRITE_1820
	MOV	A,#0BEH
	LCALL	WRITE_1820
	LCALL	READ_1820
	RET

WRITE_1820:
	MOV	R2,#8
	CLR	C
WR1:	CLR	DQ
	MOV	R3,#7
	DJNZ	R3,$
	RRC	A
	MOV	DQ,C
	MOV	R3,#15H
	DJNZ	R3,$
	SETB	DQ
	NOP
	DJNZ	R2,WR1
	SETB	DQ
	RET

READ_1820:
	PUSH	02H
	PUSH	04H
	MOV	R4,#2
	MOV	R1,#36H
RE00:	MOV	R2,#8
RE01:	CLR	C
	SETB	DQ
	NOP
	CLR	DQ
	NOP
	NOP
	NOP
	NOP
	NOP
	SETB	DQ
	MOV	R3,#5
	DJNZ	R3,$
	MOV	C,DQ
	MOV	R3,#1CH
	DJNZ	R3,$
	RRC	A
	DJNZ	R2,RE01
	MOV	@R1,A
	DEC	R1
	DJNZ	R4,RE00
	POP	04H
	POP	02H
	RET
	
TEMPER_COV:
	MOV	A,#0F0H
	ANL	A,TEMPER_L
	SWAP	A
	MOV	TEMPER_NUM,A
	MOV	A,TEMPER_L
	ANL	A,#0FH
	MOV	B,#0AH
	DIV	AB
	MOV	R7,B
	MOV	A,TEMPER_L
	JNB	ACC.3,TEMPER_COV1
	JNB	ACC.2,LOOP2
	JMP	TEMPER_COV1
LOOP2:	JNB	ACC.1,TEMPER_COV1
	INC	TEMPER_NUM

TEMPER_COV1:
	MOV	A,TEMPER_H
	ANL	A,#07H
	SWAP	A
	ADD	A,TEMPER_NUM
	MOV	TEMPER_NUM,A
	MOV	R6,TEMPER_NUM
	RET

INIT_1820:
	SETB	DQ
	NOP
	CLR	DQ
	MOV	R0,#0ECH
TSR1:	DJNZ	R0,TSR1
	SETB	DQ
	MOV	R0,#1CH
TSR2:	DJNZ	R0,TSR2
	JNB	DQ,TSR3
	LJMP	TSR4
TSR3:	SETB	FLAG1
	LJMP	TSR5
TSR4:	CLR	FLAG1
	LJMP	TSR7
TSR5:	MOV	R0,#0E0H
TSR6:	DJNZ	R0,TSR6
TSR7:	SETB	DQ
	RET
	
DELAY1:	PUSH	07H
	MOV	R7,#20H
	DJNZ	R7,$
	POP	07H
	RET

DELAY:	PUSH	00H
	PUSH	01H
	MOV	R0,#05H
LP:	MOV	R1,#00H
	DJNZ	R1,$
	DJNZ	R0,LP
	POP	00H
	POP	00H
	RET

DELAYL:	PUSH	00H
	PUSH	01H
	MOV	R0,#50H
LOP:	MOV	R1,#00H
	DJNZ	R1,$
	DJNZ	R0,LOP
	POP	01H
	POP	00H
	RET
INT_T1:
	MOV	TL1,#33H
	MOV	TH1,#0FEH
	CPL	BUZZ
	RETI

DISP:	PUSH	ACC
	MOV	A,R7
	MOV		DPTR,#LEDSEG
	MOV		B,#0AH
	DIV		AB
	MOV		R2,B
	MOV	A,R6
	MOV		B,#0AH
	DIV		AB
	MOV		R4,B
	MOV		B,#0AH
	DIV		AB
	MOV		R3,B
	MOV		B,#0AH
	DIV		AB
	MOV		R0,B
	MOV		P1,#11110111B
	MOV		A,R0
	MOVC	A,@A+DPTR
	MOV		P0,A
	LCALL	DELAY
	MOV		P1,#11111011B
	MOV		A,R3
	MOVC	A,@A+DPTR
	MOV		P0,A
	LCALL	DELAY
	MOV		DPTR,#LEDSEG1
	MOV		P1,#11111101B
	MOV		A,R4
	MOVC	A,@A+DPTR
	MOV		P0,A
	LCALL	DELAY
	MOV		DPTR,#LEDSEG
	MOV		P1,#11111110B
	MOV		A,R2
	MOVC	A,@A+DPTR
	MOV		P0,A
	LCALL	DELAY
	MOV		P1,#11111111B
	POP		ACC
	RET
DISP1:	CLR	P1.7
	LCALL	DELAY
	SETB	P1.7
	MOV	A,R7
	MOV		B,#0AH
	DIV		AB
	MOV		R2,B
	MOV	A,R6
	MOV		B,#0AH
	DIV		AB
	MOV		R4,B
	MOV		B,#0AH
	DIV		AB
	MOV		R3,B
	MOV		B,#0AH
	DIV		AB
	MOV		R0,B
	MOV	40H,R2
	MOV	41H,R4
	MOV	42H,R3
	MOV	33H,R0	
	MOV	34H,#05H
	MOV	35H,#06H
	MOV	36H,#07H
	MOV	37H,#08H
	MOV	DPTR,#LEDSEG2
	CLR	A
	MOV	R7,#04H
	MOV	R0,#20H
	MOV	R1,#40H
LOOP1:	MOV	A,@R1
	MOVC	A,@A+DPTR
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R7,LOOP1
	MOV	R7,#04H
	MOV	R0,#20H
	MOV	R2,#10H
	MOV	R3,#WSLA
	LCALL	WRNBYT
	LCALL	DELAY
	RET

LEDSEG:	DB	03H,9FH,25H,0DH,99H,49H,41H,1BH,01H,09H,11H,0C1H,63H,85H,61H,71H
LEDSEG1:DB 	02H,9EH,24H,0CH,98H,48H,40H,1AH,00H,08H,10H,0C0H,62H,84H,60H,70H
LEDSEG2:	DB	0FCH,60H,0DAH,0F2H,66H,0B6H,0BEH,0E4H
	DB	0FEH,0F6H,0EEH,3EH,9CH,7AH,9EH,8EH

WRNBYT:	PUSH	PSW		
		PUSH	ACC				
WRADD:	MOV		A,R3		;取外围器件地地址（包含r/w=0）	
		LCALL	STA		;发送起始信号S  
		LCALL	WRBYT		;发送外围地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,WRADD	;如果应
		MOV		A,R2
		LCALL	WRBYT		;发送内部寄存器首地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,WRADD	;如果应答不正确返回重来 	
WRDA:	MOV		A,@R0
		LCALL	WRBYT		;发送外围地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,WRADD	;如果应答不正确返回重来
		INC		R0
		DJNZ  	R7,WRDA
		LCALL	STOP 	
		POP		ACC
		POP		PSW
		RET 	       
;*******************************************************************










;（2）带有内部单元地址的多字节读操作子程序 RDADD 
;*******************************************************************
;通用的I2C通讯子程序（多字节读操作）
;入口参数R7字节数；
;R0目标数据块首地址；R2从器件内部子地址；
;R3器件地址（写）；R4器件地址（读）
;相关子程序WRBYT、STOP、CACK、STA、MNACK 
;*******************************************************************	
RDADD:  PUSH	PSW			;从PCF8563的02H单元读入7个参数
		PUSH	ACC			;存放于20H-26H单元	
RDADD1:	LCALL	STA 
		MOV		A,R3		;取器件地址（写）
		LCALL	WRBYT		;发送外围地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,RDADD1	;如果应答不正确返回重来
		MOV		A,R2		;取内部地址	
		LCALL	WRBYT		;发送外围地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,RDADD1	;如果应答不正确返回重来	
		LCALL	STA
		MOV		A,R4		;取器件地址（读）
		LCALL	WRBYT		;发送外围地址
		LCALL	CACK		;检测外围器件的应答信号
		JB		F0,RDADD1	;如果应答不正确返回重来
RDN:	LCALL	RDBYT 	
		MOV		@R0,A
		DJNZ	R7,ACK
		LCALL	MNACK
		LCALL	STOP	
		POP		ACC
		POP		PSW
		RET
ACK:	LCALL	MACK
		INC		R0
		SJMP	RDN 







;（3）I2C各个信号子程序
;**********************************************************************
;						启动信号子程序S 
;**********************************************************************
STA:	SETB	SDA		;启动信号S
		SETB	SCL
		NOP				;产生4.7US延时
		NOP
		NOP
		NOP
		NOP	
		CLR		SDA
		NOP				;产生4.7US延时
		NOP
		NOP
		NOP
		NOP 	
		CLR		SCL
		RET 
;**********************************************************************
;						停止信号子程序P 
;**********************************************************************
STOP:	CLR		SDA 	;停止信号P
		SETB	SCL
		NOP				;产生4.7US延时
		NOP
		NOP
		NOP
		NOP	
		SETB	SDA
		NOP				;产生4.7US延时
		NOP
		NOP
		NOP
		NOP	
		CLR		SCL
		CLR		SDA
		RET 
;**********************************************************************
;						应答信号子程序   MACK
;**********************************************************************
MACK:	CLR		SDA	;发送应答信号ACK
		SETB	SCL
		NOP			;产生4.7US延时
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		SETB	SDA
		RET
;**********************************************************************
;						非应答法信号子程序MNACK
;**********************************************************************
MNACK:	SETB	SDA		;发送非应答信号NACK
		SETB	SCL
		NOP				;产生4.7US延时
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		CLR		SDA
		RET
;**********************************************************************
;						应答检测子程序CACK
;**********************************************************************
CACK:	SETB	SDA		;应答位检测子程序
		SETB	SCL 
		CLR		F0
		MOV		C,SDA	;采样SDA
		JNC		CEND	;应答正确时转CEND
		SETB	F0		;应答错误时F0置一
CEND:	CLR		SCL
		RET
;**********************************************************************
;						发送一个字节子程序WRBYT
;**********************************************************************
WRBYT:	PUSH	06H
MOV		R6,#08H		;发送一个字节子程序 
WLP:	RLC		A 			;(入口参数A)
		MOV		SDA,C
		SETB	SCL
		NOP					;产生4.7US延时
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		DJNZ	R6,WLP
		POP		06H
		RET
;**********************************************************************
;						接收一个字节子程序RDBYT 
;**********************************************************************
RDBYT: 	PUSH	06H
		MOV		R6,#08H	;接收一个字节子程序
RLP:	SETB	SDA
		SETB	SCL
;  *******************************************
	NOP			;!!!!!产生大于15微秒的延时!!!!!!
	NOP 		;注意这是专门为ZLG7290
	NOP 		;添加的20微秒延时部分
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
;  ********************************************	
	MOV		C,SDA
	MOV		A,R2
	RLC		A
	MOV		R2,A
	CLR		SCL
	DJNZ	R6,RLP 		;(出口参数R2)
	POP		06H
	RET 

	END
