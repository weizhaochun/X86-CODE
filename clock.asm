;*****************************************************
SDA			BIT		P1.0		;定义I2C信号引脚
SCL			BIT		P1.1  
WSLA_8563	EQU		0A2H		;PCF8563口地址
RSLA_8563	EQU		0A3H
WSLA_7290	EQU		70H			;ZLG7290口地址
RSLA_7290	EQU		71H
	ORG		8000H
	LJMP	8100H 	
	ORG		8003H
	LJMP	INT_RCT
	ORG		8100H
START:  	MOV		SP,#60H
	CLR		P1.7   		;7290复位
	LCALL	DELAY	
	SETB	P1.7	
;***********************************************************
;设定PCF8563的时间和命令参数（参数和控制命令缓冲区10H-1DH）
;***********************************************************
	MOV	10H,#00H	;启动控制字
	MOV	11H,#1FH	;设置报警及定时器中断
	MOV	12H,#20H 	;秒单元
	MOV	13H,#03H	;分单元
	MOV	14H,#10H	;小时单元
	MOV	15H,#30H 	;日期单元
	MOV	16H,#03H    ;星期单元
	MOV	17H,#01H  	;月单元
  	MOV	18H,#08H	;年单元
	MOV	19H,#00H 	;设定分报警
	MOV	1AH,#00H	;设定小时报警
	MOV	1BH,#00H 	;设定日报警
	MOV	1CH,#00H	;设定星期报警
	MOV	1DH,#83H	;设定CLKOUT的频率（1S）
;************************************************************
	MOV	R7,#0EH			;写入参数个数（时间和控制字）    
	MOV	R0,#10H	        ;参数和控制命令缓冲区首地址
	MOV	R2,#00H			;从器件内部从地址	
	MOV	R3,#WSLA_8563	;准备向PCF8563T写入数据串
	LCALL	WRNBYT		;写入时间、控制命令到8563 
	SETB	EA
	SETB	EX0
	SETB	IT0
SJMP	$   		;等待中断
;***********************************************************
;			中断服务子程序
;***********************************************************
INT_RCT:	MOV		R7,#07H		;读出数个数
	MOV		R0,#20H	    ;目标数据块首址
	MOV		R2,#02H		;从器件内部从地址
	MOV		R3,#WSLA_8563
	MOV		R4,#RSLA_8563;准备读PCF8563T的时间参数	
	LCALL	RDADD		;调读数据子程序,将读出的数据
;存放于单片机20-26H中	
	LCALL	ADJUST		;调时间调整子程序
	LCALL	CHAFEN      ;调拆分子程序(包含查表) 
						;将20H-26H中的参数分别存于
;28-2FH、38H-3FH单元) 	
	MOV		R7,#08H
	MOV		R2,#10H
	MOV		R3,#WSLA_7290
	JNB		P1.2,YEARS		;使用P1.2控制显示内容
	MOV		R0,#38H			;显示小时、分钟和秒
	SJMP	DISP
YEARS:		MOV		R0,#28H 		;显示年、月和日期	
DISP:		LCALL	WRNBYT			;调7290显示
			JNB		P3.2,$
			RETI
;*********************************************************
;			各子程序 
;*********************************************************			 
			ORG		8300H 
CHAFEN:		PUSH	PSW    		;对20H-26H单元的参数拆分,
			PUSH	ACC			;查表后送28H-2FH(年月日) 
			PUSH 	03H 		;和38H-3FH （时分秒）
			PUSH	04H
	MOV	A,20H			;取秒参数
	LCALL	CF 			;拆分、查表在R4（H）、R3中
	MOV	38H,R3			;送秒的个位
	MOV	39H,R4			;送秒的十位
	MOV	3AH,#02H		;送分隔符-

	MOV	A,21H			;取分参数
	LCALL	CF 			;拆分、查表在R4（H）、R3中
	MOV	3BH,R3			;送分的个位
	MOV	3CH,R4			;送分的十位
	MOV	3DH,#02H		;送分隔符-

	MOV	A,22H			;取小时参数
	LCALL	CF 			;拆分、查表在R4（H）、R3中
	MOV	3EH,R3			;送小时的个位
	MOV	3FH,R4			;送小时的十位

	MOV	A,23H			;取日起参数
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	28H,R3
	MOV	29H,R4

	MOV	A,25H			;取月参数
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	2AH,R3
	MOV	2BH,R4

	MOV	A,26H			;取年参数
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	2CH,R3
	MOV	2DH,R4
	MOV	2EH,#0FCH		;年的高两位处理
	MOV	2FH,#0DAH
	POP	04H
	POP	03H
	POP	ACC
	POP	PSW
	RET
;*******************************************************************
CF:			PUSH	02H 			;将A中的数据拆分为两个独立的
	PUSH	DPH				; BCD码并查表
	PUSH	DPL				; 结果分别存于R4、R3中
	MOV		DPTR,#LEDSEG
	MOV		R2,A
	ANL		A,#0FH
	MOVC	A,@A+DPTR
	MOV		R3,A
	MOV		A,R2
	SWAP	A
	ANL		A,#0FH
	MOVC	A,@A+DPTR
	MOV		R4,A
	POP		DPL
	POP		DPH
	POP		02H
	RET
;*******************************************************************
LEDSEG:		DB	0FCH,60H,0DAH,0F2H,66H,0B6H,0BEH,0E4H
			DB	0FEH,0F6H,0EEH,3EH,9CH,7AH,9EH,8EH		
;*******************************************************************
;将20H -26H中从PCF8563中读出的7个字节参数的无关位屏蔽掉（参见表8.7）
;*******************************************************************
ADJUST:		PUSH	ACC
	MOV		A,20H  		;处理秒单元
	ANL		A,#7FH
	MOV		20H,A
	MOV		A,21H		;处理分单元
	ANL		A,#7FH
	MOV		21H,A
	MOV		A,22H		;处理小时单元
	ANL		A,#3FH
	MOV		22H,A
	MOV		A,23H		;处理日期单元
	ANL		A,#3FH
	MOV		23H,A
	MOV		A,24H		;处理星期单元
	ANL		A,#07H
	MOV		24H,A
	MOV		A,25H		;处理月单元
	ANL		A,#1FH
	MOV		25H,A
	POP		ACC
	RET
;*******************************************************************
;       	延时子程序
;*******************************************************************
DELAY:		PUSH	00H
			PUSH	01H
			MOV	R0,#00H
DELAY1:		MOV	R1,#00H
	DJNZ	R1,$
	DJNZ	R0,DELAY1
	POP	01H
	POP	00H
	RET
;************************************************************************************
;相关的I2C子程序（WRNBYT、RDADD 、WRBYT、STOP、CACK、STA）这里省略。参见8.1.4的内容;
;************************************************************************************
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

