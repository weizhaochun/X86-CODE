	SDA	BIT	P1.0
	SCL	BIT	P1.1
	WSLA	EQU	070H
	RSLA	EQU	071H
	ORG	0000H
	LJMP	0100H
	ORG	0100H
START:	CLR	P1.7
	LCALL	DELAY
	SETB	P1.7
	MOV	30H,#01H
	MOV	31H,#02H
	MOV	32H,#03H
	MOV	33H,#04H	
	MOV	34H,#05H
	MOV	35H,#06H
	MOV	36H,#07H
	MOV	37H,#08H
	MOV	DPTR,#LEDSEG
	CLR	A
	MOV	R7,#08H
	MOV	R0,#20H
	MOV	R1,#30H
LOOP1:	MOV	A,@R1
	MOVC	A,@A+DPTR
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R7,LOOP1
LOOP:
	MOV	R7,#08H
	MOV	R0,#20H
	MOV	R2,#10H
	MOV	R3,#WSLA
	LCALL	WRNBYT
	LCALL	DELAY
	SJMP	LOOP
LEDSEG:	DB	0FCH,60H,0DAH,0F2H,66H,0B6H,0BEH,0E4H
	DB	0FEH,0F6H,0EEH,3EH,9CH,7AH,9EH,8EH
DELAY:	PUSH	00H
	PUSH	01H
	MOV	R0,#00H
DELAY1:	MOV	R1,#00H
	DJNZ	R1,$
	DJNZ	R0,DELAY1
	POP	01H
	POP	00H
	RET
;【附录一】由汇编语言编制的I2C通讯子程序
;【提  示】下列程序是在系统时钟为12MHZ（或11.0592MHZ），即NOP指令为1微秒左右。
;（1）带有内部单元地址的多字节写操作子程序 WRNBYT
;*******************************************************************
;通用的I2C通讯子程序（多字节写操作）
;入口参数R7字节数,R0:源数据块首地址
;R0原数据块首地址；R2从器件内部子地址;R3:外围器件地址（写）
;相关子程序WRBYT、STOP、CACK、STA
;*******************************************************************	
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
;**********************************************************************
	END
