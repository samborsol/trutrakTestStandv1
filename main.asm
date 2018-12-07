TITLE "MAIN"
LIST P=16F1826
#INCLUDE "P16F1826.INC"

__CONFIG _CONFIG1,(_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF &_MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF)

CBLOCK	0X20
	d1
	d2
	resulthi
	resultlo
ENDC

ORG 0X0000
 	GOTO	START
	NOP
ORG 0x0010

START	
	CLRF	STATUS
	CLRF	LATA
	CLRF	LATB
	MOVLB	1
	MOVLW	0XC6
	MOVWF	TRISB
	MOVLW	0X3F
	MOVWF	TRISA
	MOVLW	0xF0
	MOVWF	OSCCON
	MOVLB	3
	MOVLW	0X00
	MOVWF	ANSELB
	MOVLW	0X10
	MOVWF	ANSELA
	MOVLB	0
	MOVLW	0X01
	BANKSEL	ADCON1	
	MOVLW	B'01110000'
	MOVWF	ADCON1

LOOP
	CALL	SET_ROLL
	CALL	DO_ADC
	CALL	COMPARE_PITCH_TORQUE
	CALL 	SET_PITCH
	GOTO	LOOP
	NOP

SET_PITCH
	BANKSEL PORTB
	BTFSS	WREG,0
	BCF		PORTB,3
	NOP
	BTFSC	WREG,0
	BSF		PORTB,3	
	NOP
	RETURN

DO_ADC
	BANKSEL	ADCON0 ;
	MOVLW 	B'00010001' 
	MOVWF 	ADCON0 		
	CALL 	DELAY
	BSF		ADCON0,ADGO
	BTFSC	ADCON0,ADGO
	GOTO	$-1
	RETURN

COMPARE_PITCH_TORQUE
	BANKSEL	ADRESH
	MOVF	ADRESH,W
	BTFSC	WREG,7
	RETLW	B'00000001'
	NOP
	RETLW	B'00000000'
	NOP

SET_ROLL
	BANKSEL PORTA
	BTFSS	PORTA,3
	BCF		PORTB,5
	NOP
	BTFSC	PORTA,3
	BSF		PORTB,5	
	NOP
	RETURN

DELAY
	NOP
	NOP
	NOP
	NOP
	return
END  