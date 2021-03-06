TITLE "MAIN"
LIST P=16F1826
#INCLUDE "P16F1826.INC"

__CONFIG _CONFIG1,(_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF &_MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_ON & _IESO_OFF & _FCMEN_OFF)

__CONFIG _CONFIG2, (_PLLEN_ON)

UDATA
	STATE_A	RES 1
	STATE_B	RES	1
	TALLY	RES	1
	CURRENT	RES 1
ORG 0X0000
	GOTO	START

ORG	0X0004
	GOTO	ISR
 
;input voltage to servo, ADC, needs to fire at 11 volts
;vert torque fires at 4.79 V or above
;trim voltage, pin 7, 2.5 V

ORG 0X0010
	START	
	CLRF	STATUS			
	CLRF	LATA			
	CLRF	LATB		
	BANKSEL	TRISB		
	MOVLW	B'11011111' 
	MOVWF	TRISB
	MOVLW	B'00111100'	
	MOVWF	TRISA
	MOVLW	0xF0		
	MOVWF	OSCCON			
	BANKSEL	ANSELB			
	MOVLW	0X00
	MOVWF	ANSELB
	MOVLW	0X10			
	MOVWF	ANSELA
	BANKSEL PIE1			
	BSF		PIE1,6			
	MOVLW	B'11001000'	
	MOVWF	INTCON		
	BANKSEL	IOCBP
	MOVLW	B'00011110'
	MOVWF	IOCBP
	MOVWF	IOCBN
	BANKSEL	ADCON0				
	MOVLW	B'00010011'
	MOVWF	ADCON0	
	MOVLW	B'01000000'		
	MOVWF	ADCON1		

LOOP
	GOTO	LOOP

ISR
	BANKSEL ADCON0	
	BTFSS	ADCON0,ADGO
	GOTO	ADC_ISR
	GOTO	QUAD_ISR

ADC_ISR
	BANKSEL	ADRESH
	MOVF	ADRESH,0 	
	BANKSEL	PORTA
	BTFSS	WREG,7		
	BCF 	PORTA,7
	BTFSC	WREG,7
	BSF 	PORTA,7
	BANKSEL ADCON0
	BSF		ADCON0,ADGO	
	BANKSEL	INTCON	
	BCF		INTCON,INTF
	RETFIE	

QUAD_ISR
	;Set both STATE_A and STATE_B to "11" in binary
	BANKSEL	PORTB	
	MOVF	PORTB,W
	BANKSEL	STATE_A
	MOVWF	CURRENT
	MOVLW	0X03
	MOVWF	STATE_A
	MOVWF	STATE_B
	MOVLW	0X00
	MOVWF	TALLY


	;Save [2,3] in STATE_A
	CALL 	GET_PAIR_23

	;Save [4,5] in STATE_B
	CALL 	GET_PAIR_45

	CALL	CHECKER

	;Clear interrupt flag and leave
	BANKSEL INTCON
	BCF		INTCON,INTF
	RETFIE


GET_PAIR_23:
	BANKSEL CURRENT
	MOVF 	CURRENT,W
	BANKSEL	STATE_A
	BTFSS	WREG,2
	BCF		STATE_A,0
	BTFSS	WREG,3
	BCF		STATE_A,1
	RETURN

GET_PAIR_45:
	BANKSEL CURRENT
	MOVF 	CURRENT,W
	BANKSEL	STATE_B
	BTFSS	WREG,1
	BCF		STATE_B,0
	BTFSS	WREG,4
	BCF		STATE_B,1
	RETURN

CHECKER:
	BANKSEL	STATE_A
	MOVLW	0X00
	SUBWF	STATE_A,0
	BTFSC	STATUS,Z
	GOTO	FIRE_LIGHT
	
	MOVLW	0X00
	SUBWF	STATE_B,0
	BTFSC	STATUS,Z
	GOTO	FIRE_LIGHT

	BTFSC	STATE_A,0
	INCF	TALLY
	BTFSC	STATE_A,1
	INCF	TALLY
	BTFSC	STATE_B,0
	INCF	TALLY
	BTFSC	STATE_B,1
	INCF	TALLY

	MOVLW	0X01
	SUBWF	TALLY,0
	BTFSC	STATUS,Z
	GOTO	FIRE_LIGHT

	MOVLW	0X04	
	SUBWF	TALLY,0
	BTFSC	STATUS,Z
	GOTO	FIRE_LIGHT

	RETURN
	
FIRE_LIGHT:
	BANKSEL	PORTA
	BSF		PORTA,0
	RETURN

END
