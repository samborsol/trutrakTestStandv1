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

ORG	0X0004
	GOTO	ISR

ORG 0X0010
	START	
	CLRF	STATUS
	CLRF	LATA
	CLRF	LATB
	BANKSEL	TRISB
	MOVLW	0XC6
	MOVWF	TRISB
	MOVLW	0X3F
	MOVWF	TRISA
	MOVLW	0xF0
	MOVWF	OSCCON
	BANKSEL	ANSELB
	MOVLW	0X00
	MOVWF	ANSELB
	MOVLW	0X10
	MOVWF	ANSELA
	BANKSEL	PIR1
	BCF	PIR1,6 		;clear adc interrupt flag
	BANKSEL PIE1
	BSF	PIE1,6		;enable adc interrupt
	MOVLW	B'11000000'
	MOVWF	INTCON		;enable global and peripheral interrupt
	BANKSEL	ADCON1	
	MOVLW	B'01110000'
	MOVWF	ADCON1		;right justified adc reading
	MOVLW	B'00010011'
	MOVWF	ADCON0		;pick out the channel for ADC and turn on
LOOP
	BANKSEL	PORTA
	BTFSS	PORTA,3
	BCF 	PORTB,5
	BTFSC	PORTA,3
	BSF 	PORTB,5	
	GOTO	LOOP
ISR
	BANKSEL	ADRESH
	MOVF	ADRESH,W 	;copy over voltage reading to WREG
	BANKSEL	PORTB
	BTFSS	WREG,7		;check if greater than "6" on VRT TORQUE
	BCF 	PORTB,3
	BTFSC	WREG,7
	BSF 	PORTB,3	
	BSF	ADCON0,ADGO	;start the adc again
	BSF 	INTCON,7	;re-enable the global interrupt
	BANKSEL	PIR1
	BCF	PIR1,6 		;clear adc interrupt flag
	GOTO	LOOP
END