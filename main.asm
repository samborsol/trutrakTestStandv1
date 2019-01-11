TITLE "MAIN"
LIST P=16F1826
#INCLUDE "P16F1826.INC"

__CONFIG _CONFIG1,(_FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF &_MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_OFF)

UDATA
	STATE_CURR	RES	1
	STATE_PREV	RES	1

ORG 0X0000
	GOTO	START

ORG	0X0004
	GOTO	ISR

ORG 0X0010
	START	
	CLRF	STATUS		; STATUS contains the arithmetic state of the ALU and the reset status. CLRF clears the file-register.
	CLRF	LATA		; LATA is the PORTA data latch register.
	CLRF	LATB		; LATB is the PORTB data latch register.
	BANKSEL	TRISB		; TRISB is the I/O status of PORTB, 1 means input, 0 means output. 
	MOVLW	B'11011111' ; all but RB5 are inputs, because PORTB has interrupts
	MOVWF	TRISB
	MOVLW	B'00111100'	; for now, important that RA0 and RA1 are outputs, for vert torque and quadrature LED.
	MOVWF	TRISA
	MOVLW	0xF0		; b'11110000'
	MOVWF	OSCCON		; OSCCON is the oscillator control register. 4x PLL is enabled. Internal osciallator freq is 16 MHz HF.
	BANKSEL	ANSELB		; ANSELB AND ANSELA set the analogue or digital status of PORTB and PORTA, respectively.
	MOVLW	0X00
	MOVWF	ANSELB
	MOVLW	0X10		; set the PORTA bit for the ADC input.
	MOVWF	ANSELA

	BANKSEL STATE_CURR
	MOVLW	b'00000000'	; set the STATE_CURR and STATE_PREV for the quadrature test, so there state going in is unambiguous.
	MOVWF	STATE_CURR
	MOVLW	b'00000000'
	MOVWF	STATE_PREV

	BANKSEL	PIR1		; PIR1 contains the interrupt flag bigs.
	BCF		PIR1,6 		; clear adc interrupt flag
	BANKSEL PIE1		; PIE1 contains the interrupt enable bits.
	BSF		PIE1,6		; enable adc interrupt
	MOVLW	B'11001000'	; also enable interrupt on change, enable global and peripheral interrupt
	MOVWF	INTCON		; INTCON contains the various enable and flag bits for TMR0 register overflow, interrupt-on-change and external INT pin interrupts.
	BANKSEL	IOCBP
	MOVLW	B'00011000'
	MOVWF	IOCBP		; IOCBP, interrupt-on-change enabled on the pin for a positive going edge. Associated status bit and interrupt flag will be set upon detecting an edge.
	MOVLW	B'00000110'
	MOVWF	IOCBN
	BANKSEL	ADCON1	
	MOVLW	B'01110000'	; ADC control registers 1 and 2
	MOVWF	ADCON1		; right justified adc reading
	MOVLW	B'00010011'
	MOVWF	ADCON0		; pick out the channel for ADC and turn on

LOOP
	GOTO	LOOP		; main loop, wait here for an interrupt

ISR
;	BANKSEL ADCON0	
;	BTFSS	ADCON0,ADGO
;	GOTO	ADC_ISR
	GOTO	QUAD_ISR

ADC_ISR
	BANKSEL	ADRESH
	MOVF	ADRESH,0 	; copy over voltage reading to WREG
	BANKSEL	PORTA
	BTFSS	WREG,7		; check if greater than " VRT TORQUE
	BCF 	PORTA,7
	BTFSC	WREG,7
	BSF 	PORTA,7	
	BSF		ADCON0,ADGO	; start the adc again
	BSF 	INTCON,7	; re-enable the global interrupt
	BANKSEL	PIR1
	BCF		PIR1,6 		; clear adc interrupt flag
	RETFIE	

QUAD_ISR
	BANKSEL	PORTB
	MOVF	PORTB,0
	ANDLW	B'00011110'
	
	BANKSEL	STATE_CURR
	MOVWF	STATE_CURR

	BANKSEL STATE_CURR
	MOVF	STATE_PREV,0	;check to make sure that there is a 
	SUBLW	0X00
	BTFSC	STATUS,Z
	GOTO	SET_STATE_PREV

	MOVF	STATE_CURR,0
	SUBLW	0X06			;THIS IS STATE A
	BTFSC	STATUS,Z
	GOTO	IF_STATE_AorD

	MOVF	STATE_CURR,0
	SUBLW	0X0A			;THIS IS STATE B
	BTFSC	STATUS,Z
	GOTO	IF_STATE_BorC

	MOVF	STATE_CURR,0
	SUBLW	0X14			;THIS IS STATE C
	BTFSC	STATUS,Z
	GOTO	IF_STATE_BorC

	MOVF	STATE_CURR,0
	SUBLW	0X18			;THIS IS STATE D
	BTFSC	STATUS,Z
	GOTO	IF_STATE_AorD

	;GETS THIS FAR IT MEANS FAILURE!!
	GOTO	FIRE_LIGHT

SET_STATE_PREV
	BANKSEL STATE_CURR
	MOVF	STATE_CURR,0
	MOVWF	STATE_PREV
	RETFIE

IF_STATE_AorD
	BANKSEL STATE_CURR
	MOVF 	STATE_PREV,0	;for state A or D,
 	SUBLW 	0X0A			;check that previous states, B and C.
	BTFSC	STATUS,Z
	GOTO	DIM_LIGHT

	MOVF	STATE_PREV,0	
 	SUBLW 	0X14
	BTFSC	STATUS,Z
	GOTO	DIM_LIGHT

	GOTO	FIRE_LIGHT

IF_STATE_BorC
	BANKSEL	STATE_CURR
	MOVF 	STATE_PREV,0	;for state B or C,
  	SUBLW 	0X06			;check that previous states, A and D.
	BTFSC	STATUS,Z
	GOTO	DIM_LIGHT

	MOVF	STATE_PREV,0	
  	SUBLW 	0X18
	BTFSC	STATUS,Z
	GOTO	DIM_LIGHT

	GOTO 	FIRE_LIGHT

FIRE_LIGHT
	BANKSEL PORTA
	BSF		PORTA,0
	GOTO SET_STATE_PREV

DIM_LIGHT
	BANKSEL	PORTA
	BCF		PORTA,0
	GOTO	SET_STATE_PREV

END