TITLE "MAIN"
LIST P=16F1826
#INCLUDE "P16F1826.INC"

__CONFIG _CONFIG1,(_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF &_MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_ON & _IESO_OFF & _FCMEN_OFF)

__CONFIG _CONFIG2, (_PLLEN_ON)

UDATA
	COUNTC		RES 1

ORG 0X0000
	GOTO	START

ORG	0X0004
	GOTO	ISR

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
	
	BANKSEL	COUNTC
	MOVLW	0X00
	MOVWF	COUNTC

	BANKSEL	PIR1		
	BCF		PIR1,6 			
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
	BSF 	INTCON,7
	BCF		INTCON,INTF
		
	BANKSEL	PIR1
	BCF		PIR1,6
 			
	RETFIE	

QUAD_ISR
	BANKSEL	PORTB
	MOVLW	0X00
	BTFSS	PORTB,1
	ADDLW	0X01
	BTFSS	PORTB,2
	ADDLW	0X01
	BTFSS	PORTB,3
	ADDLW	0X01	
	BTFSS	PORTB,4
	ADDLW	0X01
	
	BANKSEL COUNTC
	MOVWF	COUNTC
	MOVF	COUNTC,0
	SUBLW	0X01
	BTFSC	STATUS,Z
	GOTO 	DIM_LIGHT

	MOVF	COUNTC,0
	SUBLW	0X02
	BTFSC	STATUS,Z
	GOTO 	DIM_LIGHT

	GOTO	FIRE_LIGHT

FIRE_LIGHT
	BANKSEL PORTA
	BSF		PORTA,0
	MOVLW	0X00	

	BANKSEL	COUNTC
	MOVFW 	COUNTC

	RETFIE

DIM_LIGHT
	BANKSEL	INTCON
	BCF		INTCON,INTF
	RETFIE

END


