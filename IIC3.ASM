	SDA	BIT	P1.0
	SCL	BIT	P1.1
	WSLA_8563	EQU	0A2H
	RSLA_8563	EQU	0A3H
	WSLA_7290	EQU	70H
	RSLA_7290	EQU	71H
	ORG	0000H
	LJMP	0100H
	ORG	0003H
	LJMP	INT_RCT
	ORG	0100H
START:	MOV	SP,#60H
	CLR	P1.7
	LCALL	DELAY
	SETB	P1.7
	
	MOV	10H,#00H
	MOV	11H,#1FH
	MOV	12H,#20H
	MOV	13H,#03H
	MOV	14H,#10H
	MOV	15H,#01H
	MOV	16H,#06H
	MOV	17H,#04H
	MOV	18H,#17H
	MOV	19H,#00H
	MOV	1AH,#00H
	MOV	1BH,#00H
	MOV	1CH,#00H
	MOV	1DH,#83H
	MOV	50H,#11H
	MOV	51H,#70H
	MOV	52H,#0FH


	MOV	R7,#01H
	MOV	R0,#50H
	MOV	R2,#0CH
	MOV	R3,#WSLA_7290
	LCALL	WRNBYT

	MOV	R7,#02H
	MOV	R0,#51H
	MOV	R2,#07H
	MOV	R3,#WSLA_7290
	LCALL	WRNBYT

	MOV	R7,#0EH
	MOV	R0,#10H
	MOV	R2,#00H
	MOV	R3,#WSLA_8563
	LCALL	WRNBYT
	SETB	EA
	SETB	EX0
	SETB	IT0
	SJMP	$


INT_RCT:	
	MOV	R7,#07H
	MOV	R0,#20H	
	MOV	R2,#02H
	MOV	R3,#WSLA_8563
	MOV	R4,#RSLA_8563
	LCALL	RDADD
	LCALL	ADJUST
	LCALL	CHAFEN
	MOV	R7,#08H
	MOV	R2,#10H
	MOV	R3,#WSLA_7290
	JNB	P1.2,YEARS
	MOV	R0,#38H
	SJMP	DISP
YEARS:	MOV	R0,#28H
DISP:	LCALL	WRNBYT
	JNB	P3.2,$
	RETI

CHAFEN:	PUSH	PSW
	PUSH	ACC
	PUSH	03H
	PUSH	04H
	MOV	A,20H
	LCALL	CF
	MOV	38H,R3
	MOV	39H,R4
	MOV	3AH,#02H

	MOV	A,21H
	LCALL	CF
	MOV	3BH,R3
	MOV	3CH,R4
	MOV	3DH,#02H

	MOV	A,22H
	LCALL	CF
	MOV	3EH,R3
	MOV	3FH,R4
	
	MOV	A,23H
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	28H,R3
	MOV	29H,R4

	MOV	A,25H
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	2AH,R3
	MOV	2BH,R4

	MOV	A,26H
	LCALL	CF
	MOV	A,R3
	ORL	A,#01H
	MOV	R3,A
	MOV	2CH,R3
	MOV	2DH,R4
	MOV	2EH,#0FCH
	MOV	2FH,#0DAH
	POP	04H
	POP	03H
	POP	ACC
	POP	PSW
	RET

CF:	PUSH	02H
	PUSH	DPH
	PUSH	DPL
	MOV	DPTR,#LEDSEG
	MOV	R2,A
	ANL	A,#0FH
	MOVC	A,@A+DPTR
	MOV	R3,A
	MOV	A,R2
	SWAP	A
	ANL	A,#0FH
	MOVC	A,@A+DPTR
	MOV	R4,A
	POP	DPL
	POP	DPH
	POP	02H
	RET

LEDSEG:	DB	0FCH,60H,0DAH,0F2H,66H,0B6H,0BEH,0E4H
	DB	0FEH,0F6H,0EEH,3EH,9CH,7AH,9EH,8EH

ADJUST:	PUSH	ACC
	MOV	A,20H
	ANL	A,#7FH
	MOV	20H,A
	MOV	A,21H
	ANL	A,#7FH
	MOV	21H,A
	MOV	A,22H
	ANL	A,#3FH
	MOV	22H,A
	MOV	A,23H
	ANL	A,#3FH
	MOV	23H,A
	MOV	A,24H
	ANL	A,#07H
	MOV	24H,A
	MOV	A,25H
	ANL	A,#1FH
	MOV	25H,A
	POP	ACC
	RET


DELAY:	PUSH	00H
	PUSH	01H
	MOV	R0,#00H
DELAY1:	MOV	R1,#00H
	DJNZ	R1,$
	DJNZ	R0,DELAY1
	POP	01H
	POP	00H
	RET
;����¼һ���ɻ�����Ա��Ƶ�I2CͨѶ�ӳ���
;����  ʾ�����г�������ϵͳʱ��Ϊ12MHZ����11.0592MHZ������NOPָ��Ϊ1΢�����ҡ�
;��1�������ڲ���Ԫ��ַ�Ķ��ֽ�д�����ӳ��� WRNBYT
;*******************************************************************
;ͨ�õ�I2CͨѶ�ӳ��򣨶��ֽ�д������
;��ڲ���R7�ֽ���,R0:Դ���ݿ��׵�ַ
;R0ԭ���ݿ��׵�ַ��R2�������ڲ��ӵ�ַ;R3:��Χ������ַ��д��
;����ӳ���WWRBYT��STOP��CACK��STA
;*******************************************************************	
WRNBYT:	PUSH	PSW		
		PUSH	ACC				
WRADD:	MOV		A,R3		;ȡ��Χ�����ص�ַ������r/w=0��	
		LCALL	STA		;������ʼ�ź�S  
		LCALL	WRBYT		;������Χ��ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,WRADD	;���Ӧ
		MOV		A,R2
		LCALL	WRBYT		;�����ڲ��Ĵ����׵�ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,WRADD	;���Ӧ����ȷ�������� 	
WRDA:	MOV		A,@R0
		LCALL	WRBYT		;������Χ��ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,WRADD	;���Ӧ����ȷ��������
		INC		R0
		DJNZ  	R7,WRDA
		LCALL	STOP 	
		POP		ACC
		POP		PSW
		RET 	       
;*******************************************************************










;��2�������ڲ���Ԫ��ַ�Ķ��ֽڶ������ӳ��� RDADD 
;*******************************************************************
;ͨ�õ�I2CͨѶ�ӳ��򣨶��ֽڶ�������
;��ڲ���R7�ֽ�����
;R0Ŀ�����ݿ��׵�ַ��R2�������ڲ��ӵ�ַ��
;R3������ַ��д����R4������ַ������
;����ӳ���WWRBYT��STOP��CACK��STA��MNACK 
;*******************************************************************	
RDADD:  PUSH	PSW			;��PCF8563��02H��Ԫ����7������
		PUSH	ACC			;�����20H-26H��Ԫ	
RDADD1:	LCALL	STA 
		MOV		A,R3		;ȡ������ַ��д��
		LCALL	WRBYT		;������Χ��ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,RDADD1	;���Ӧ����ȷ��������
		MOV		A,R2		;ȡ�ڲ���ַ	
		LCALL	WRBYT		;������Χ��ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,RDADD1	;���Ӧ����ȷ��������	
		LCALL	STA
		MOV		A,R4		;ȡ������ַ������
		LCALL	WRBYT		;������Χ��ַ
		LCALL	CACK		;�����Χ������Ӧ���ź�
		JB		F0,RDADD1	;���Ӧ����ȷ��������
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







;��3��I2C�����ź��ӳ���
;**********************************************************************
;						�����ź��ӳ���S 
;**********************************************************************
STA:	SETB	SDA		;�����ź�S
		SETB	SCL
		NOP				;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP	
		CLR		SDA
		NOP				;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP 	
		CLR		SCL
		RET 
;**********************************************************************
;						ֹͣ�ź��ӳ���P 
;**********************************************************************
STOP:	CLR		SDA 	;ֹͣ�ź�P
		SETB	SCL
		NOP				;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP	
		SETB	SDA
		NOP				;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP	
		CLR		SCL
		CLR		SDA
		RET 
;**********************************************************************
;						Ӧ���ź��ӳ���   MACK
;**********************************************************************
MACK:	CLR		SDA	;����Ӧ���ź�ACK
		SETB	SCL
		NOP			;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		SETB	SDA
		RET
;**********************************************************************
;						��Ӧ���ź��ӳ���MNACK
;**********************************************************************
MNACK:	SETB	SDA		;���ͷ�Ӧ���ź�NACK
		SETB	SCL
		NOP				;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		CLR		SDA
		RET
;**********************************************************************
;						Ӧ�����ӳ���CACK
;**********************************************************************
CACK:	SETB	SDA		;Ӧ��λ����ӳ���
		SETB	SCL 
		CLR		F0
		MOV		C,SDA	;����SDA
		JNC		CEND	;Ӧ����ȷʱתCEND
		SETB	F0		;Ӧ�����ʱF0��һ
CEND:	CLR		SCL
		RET
;**********************************************************************
;						����һ���ֽ��ӳ���WRBYT
;**********************************************************************
WRBYT:	PUSH	06H
MOV		R6,#08H		;����һ���ֽ��ӳ��� 
WLP:	RLC		A 			;(��ڲ���A)
		MOV		SDA,C
		SETB	SCL
		NOP					;����4.7US��ʱ
		NOP
		NOP
		NOP
		NOP
		CLR		SCL
		DJNZ	R6,WLP
		POP		06H
		RET
;**********************************************************************
;						����һ���ֽ��ӳ���RDBYT 
;**********************************************************************
RDBYT: 	PUSH	06H
		MOV		R6,#08H	;����һ���ֽ��ӳ���
RLP:	SETB	SDA
		SETB	SCL
;  *******************************************
	NOP			;!!!!!��������15΢�����ʱ!!!!!!
	NOP 		;ע������ר��ΪZLG7290
	NOP 		;���ӵ�20΢����ʱ����
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
	DJNZ	R6,RLP 		;(���ڲ���R2)
	POP		06H
	RET  
;**********************************************************************
	END









