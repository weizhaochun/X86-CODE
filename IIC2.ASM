	SDA	BIT	P1.0
	SCL	BIT	P1.1
	WSLA	EQU	070H
	RSLA	EQU	071H
	DISDA	EQU	20H
	DISCON	EQU	08H
	DATA_1	EQU	30H
	ORG	0000H
	LJMP	0100H
	ORG	0003H
	LJMP	INT_7290
	ORG	0100H
START:	
	MOV	SP,#60H
	CLR	P1.7
	LCALL	DELAY
	SETB	P1.7
	SETB	EA
	SETB	EX0
	SETB	IT0
	MOV	DATA_1,#13H
	MOV	DATA_1+1,#13H
	MOV	DATA_1+2,#13H
	MOV	DATA_1+3,#12H	
	MOV	DATA_1+4,#10H
	MOV	DATA_1+5,#11H
	MOV	DATA_1+6,#10H
	MOV	DATA_1+7,#0DH
	MOV	DPTR,#LEDSEG
	MOV	R7,#DISCON
	MOV	R0,#DISDA
	MOV	R1,#DATA_1
LOOP1:	MOV	A,@R1
	MOVC	A,@A+DPTR
	MOV	@R0,A
	INC	R1
	INC	R0
	DJNZ	R7,LOOP1
LOOP:
	MOV	R7,#DISCON
	MOV	R0,#DISDA
	MOV	R2,#10H
	MOV	R3,#WSLA
	LCALL	WRNBYT
	LCALL	DELAY
	SJMP	LOOP
LEDSEG:	DB	0FCH,60H,0DAH,0F2H,66H,0B6H,0BEH,0E4H
	DB	0FEH,0F6H,0EEH,3EH,9CH,7AH,9EH,8EH
	DB	0FAH,1EH,12H,00H



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

INT_7290:
	PUSH	00H
	PUSH	02H
	PUSH	03H
	PUSH	04H
	PUSH	07H
	PUSH	ACC
	PUSH	PSW
	MOV	R0,#28H
	MOV	R7,#04H
	MOV	R2,#00H
	MOV	R3,#WSLA
	MOV	R4,#RSLA
	LCALL	RDADD
	NOP
	MOV	A,29H
	LCALL	CF
	MOV	20H,R3
	MOV	21H,R4
	POP	PSW
	POP	ACC
	POP	07H
	POP	04H
	POP	03H
	POP	02H
	POP	00H
	RETI



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