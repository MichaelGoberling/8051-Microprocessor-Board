	org	0
	jmp	start

RS	bit	P3.2
RW	bit	P3.1

LINE1	set	10000001b	; DDRAM location on LCD for Line 1
LINE2	set	11000001b	; DDRAM location on LCD for Line 2
Clear_LCD	set	00000001b	; Clears LCD

IO_M	BIT	P3.0

cmd	macro	cmd_code
	PUSH	ACC
	PUSH	0
	SETB	IO_m
	MOV	R0,#80h
	MOV	A, cmd_code
	MOVX	@R0, A
	MOV	A, #02d
	ACALL	DELAY_MS
	POP	0
	POP	ACC
endm

start:	

main:	
	ACALL	INITIALIZE		;Initialize LCD and PORTS
FOREVER:

	MOV	R0, #00010000B		;ADC
	MOVX	A, @R0		;Take in ADC value
	MOV	B,#5
	
	

	
	MOV	A,R6
	ACALL	PRINT_CHAR
	MOV	A,R7
	ACALL	PRINT_CHAR

	MOV	A, #250d
	ACALL	DELAY_MS
	MOV	A, #250d
	ACALL	DELAY_MS
	MOV	A, #250d
	ACALL	DELAY_MS
	MOV	A, #250d
	ACALL	DELAY_MS

	CLR	RS
	cmd	#Clear_LCD
	cmd	#LINE1
	AJMP	FOREVER
	
;*************************************************
BCD_to_ASCII:
	MOV	R6,A	;Keep copy in R1 for now
	ANL	A,#0FH	;Mask upper nibble
	ORL	A,#30H	;Add 30H
	PUSH	ACC
	CLR	C
	SUBB	A,#3AH	;See if a 0-9 Digit
	POP	ACC
	JC	SECOND_NIBBLE
	ADD	A,#07H	;Add 7 to make hex value

SECOND_NIBBLE:
	MOV	R7,A	;Store lower nibble in A
	MOV	A,R6	
	SWAP	A	;Now convert upper nibble
	ANL	A,#0FH	;Mask lower nibble
	ORL	A,#30H	;Add 30H
	CLR	C
	PUSH	ACC
	SUBB	A,#3AH	;See if a 0-9 Digit
	POP	ACC
	JC	END_CONVERT
	ADD	A,#07H	;Add 7 to make hex value
	
END_CONVERT:
	MOV	R6,A
	RET
	
;*************************************************
Initialize:
	clr	RW
	clr	RS
	MOV	A,#50d		;40ms delay
	ACALL	DELAY_MS
	cmd	#00111000b	; Function set
	ACALL	DELAY_1MS
	cmd	#00111000b	; Function set
	ACALL	DELAY_1MS
	cmd	#00001111b	; Display ON/OFF control
	ACALL	DELAY_1MS
	cmd	#00000001b	; Clear display
	MOV	A,#03d		;3ms delay
	ACALL	DELAY_MS
	cmd	#00000110b	; Entry mode set
	RET

;*************************************************
; Print the string ...
PRINT_LCD:
	setb	RS
	mov	R2, #0
print:	mov	A, R2
	inc	R2
	movc	A, @A+DPTR
	cjne	A, #0, CONT_PRINT
	SJMP	END_PRINT
CONT_PRINT:
	cmd	A
	SJMP	print
END_PRINT:
	RET

;*********************************************************
PRINT_CHAR:
	setb	RS
	cmd	A
	RET

;********************************************
DELAY_1ms:
	PUSH	0
	PUSH	1

	MOV	R1, #2h
DELAY_1:
	MOV	R0, #0A4h
DELAY_2:
	NOP
	DJNZ	R0, DELAY_2
	DJNZ	R1, DELAY_1

	POP	1
	POP	0
	RET

;***********************************************
;The time in ms should be placed into A
DELAY_ms:
	ACALL	DELAY_1MS
	DJNZ	ACC, DELAY_ms
	RET
	
	end
