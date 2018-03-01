;****************************************
;*Author: Michael Goberling		*
;*Course: 4330 Microprocessor Design	*
;*Assignment: Laboratory 5		*
;*Due date: 3/28/17			*
;*Revision: 0.3				*
;****************************************

		org 0h
		sjmp	main
		
;========================================================
;| Data equates 					|
;========================================================
io_temp 	EQU	10h
io_sevenseg	EQU	20h
io_rtc 		EQU	40h
io_lcd		EQU	80h

lcd_clear	equ	00000001b
lcd_home	equ	00000010b
lcd_fn_set	equ	00111100b
lcd_onoff_cntl	equ	00001111b
lcd_entry_set	equ	00000110b
lcd_ddram	equ	10000001b

RS		EQU	P3.2
RW		EQU	P3.1

keypad		EQU	P1

		;-------------------------------------------------------------------------------------------
main:		
		ACALL	RTC_INIT
		ACALL	LCD_INIT			;LCD initialization
REPEAT:
		ACALL	PUT_RTC				;print it to the correct spot

		MOV	R0, #45H			;FIRST HOUR DIGIT
		ACALL	readReg
		ORL	A, #30H				;CONVER TO ASCII
		ACALL	printChar				

		MOV	R0, #44H			;BOTTOM HOUR DIGIT
		ACALL	readReg
		ORL	A, #30H
		ACALL	printChar
		
		MOV	A, #3Ah				;PRINT SEMICOLON
		ACALL	printChar

		MOV	R0, #43H			;TOP MIN DIGIT
		ACALL	readReg
		ORL	A, #30H
		ACALL	printChar

		MOV	R0, #42H			;BOTTOM MIN DIGI
		ACALL	readReg
		ORL	A, #30H				;CONVERT TO ASCII
		ACALL	printChar

		MOV	A, #3AH				;print ":"
		ACALL	printChar

		MOV	R0, #41H			;ETC...
		ACALL	readReg
		ORL	A, #30H
		ACALL	printChar

		MOV	R0, #40H
		ACALL	readReg
		ORL	A, #30H
		ACALL	printChar

		MOV	A, #20H
		ACALL	printChar

		ACALL	halfseconddelay
		ACALL	halfseconddelay

		SJMP	REPEAT

FOREVER:	SJMP	FOREVER
;================================================================================
;| RTC initialization								|
;================================================================================
RTC_INIT:
		
		MOV	R0, #4Fh			;F REG INIT
		MOV	A, #00h
		ACALL	ioToggle			;Send whats in R0 to Address bus
							;Send whats in A to data bus
		MOV	R0, #4Dh
		MOV	A, #00h				;CD register init
		ACALL	ioToggle

		;ACALL	checkBusy
		
		MOV	R0, #4FH
		MOV	A, #03H				;RESET THE COUNTER
		ACALL	ioToggle

		;SET CURRENT TIME FOR REGS
		MOV	R0, #40H			;FIRST SECONDS
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #41H			;SECOND SECONDS
		MOV	A, #00H		
		ACALL	ioToggle

			
		MOV	R0, #42H			;ETC...
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #43H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #44H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #45H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #46H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #47H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #48H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #49H
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #4AH
		MOV	A, #00H		
		ACALL	ioToggle

		MOV	R0, #4BH
		MOV	A, #00H		
		ACALL	ioToggle

		
		;START COUNTER AND RELEASE HOLD
		MOV	R0, #4Fh			;F REG INIT
		MOV	A, #00h
		ACALL	ioToggle

		MOV	R0, #4Dh
		MOV	A, #00h				;CD register init
		ACALL	ioToggle
		
		RET
;================================================================================
;| Check if the RTC is busy							|
;================================================================================
checkBusy:
		PUSH	0
		PUSH	ACC
		MOV	R0, #4Dh		;TO ACCESS CD REG IN RTC
waitBusy:	
		MOV	A, #05H
		SETB	P3.0
		MOVX	@R0, A			;SET HOLD
		CLR	P3.0

		SETB	P3.0
		MOVX	A, @R0			;READ IN THE CD REG
		CLR	P3.0

		JNB	ACC.1, busyReady	;CHECK IF BUSY BIT HIGH

		MOV	A, #04h
		SETB	P3.0
		MOVX	@R0, A			;clear hold to let busy bit update
		CLR	P3.0
		ACALL	DELAY_1MS
		SJMP	waitBusy

busyReady:	
		POP	ACC
		POP	0
		
		RET
;================================================================================
;| Read a register in the RTC							|
;================================================================================
readReg:	
		
		;ACALL	checkBusy		;Wait until not busy
		SETB	P3.0			;READ VALUE
		MOVX 	A, @R0
		CLR	P3.0
		
		ANL	A, #0FH			;MASK OFF LOWER HALF
		PUSH	ACC			;SAVE VALUE
		
		MOV	R0, #4DH		;CLR THE HOLD BIT
		MOV	A, #04H
		
		SETB	P3.0			;SEND ADDR AND DATA TO BUSSES
		MOVX	@R0, A
		CLR	P3.0
		
		POP	ACC
		
		RET
;================================================================================
;| Write to a register in the RTC						|
;================================================================================
writeReg:	
		ACALL	checkBusy			;Wait until not busy

		SETB	P3.0
		MOVX	@R0, A				;Read in value
		CLR	P3.0

		PUSH	ACC
		MOV	R0, #4DH
		MOV	A, #04H				;Clear hold
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0
		POP	ACC
		
		RET
;================================================================================
;| Procedure to initialize the LCD						|
;================================================================================
LCD_INIT:					
		ACALL	DELAY_50MS

		MOV	A, #38H				;FUNCTION SET
		ACALL	COMNWRT
		ACALL	DELAY_1MS

		MOV	A, #38H				;FUNCTION SET
		ACALL	COMNWRT
		ACALL	DELAY_1MS

		MOV	A, #0FH				
		ACALL	COMNWRT
		ACALL	DELAY_1MS

		MOV	A, #01H
		ACALL	COMNWRT
		ACALL	DELAY_5MS

		MOV	A, #06H
		ACALL	COMNWRT
		
		RET
;================================================================================
;| To write a command to the LCD						|
;================================================================================
COMNWRT:	
		PUSH	ACC
		PUSH	0
		MOV	R0, #io_lcd	
		CLR	RS				;RS
		CLR	RW				;RW
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0			
		ACALL	DELAY_1MS
		POP	ACC
		POP	0
		RET

;================================================================================
;| To clear the LCD								|
;================================================================================
CLEAR_LCD:
		MOV	A,#01H
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		RET
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_TEMP:	
		push	0
		push	ACC
		CLR	RS
		MOV	R0, io_lcd			;TARGET LCD @ DDRAM LOCATION 4D
		MOV	A, #0CDH
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		pop	ACC
		pop	0
		RET	
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_RTC:	
		CLR	RS
		MOV	R0, io_lcd			;TARGET LCD @ DDRAM LOCATION 5D
		MOV	A, #0DDH
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		RET	
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_LINE1:	
		CLR	RS
		MOV	R0, io_lcd			;TARGET LCD HOME ADDRESS
		MOV	A, #080H
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		RET	
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_LINE2:	
		CLR	RS
		MOV	R0, io_lcd			;TARGET LCD 2ND LINE
		MOV	A, #0C0H
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		RET	
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_LINE3:		
		CLR	RS
		MOV	R0, io_lcd				;TARGET LCD  @ 14H
		MOV	A, #94H
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		RET	
;================================================================================
;| Carriage Return, Line Feed to the LCD					|
;================================================================================
PUT_LINE4:		
		MOV	R0, io_lcd
		CLR	RS
		MOV	A, #0D4H				;TARGET LCD @ 54H
		ACALL	COMNWRT
		ACALL	DELAY_5MS
		SETB	RS
		RET	
;================================================================================
;| Print a string ot the LCD							|
;================================================================================
printString:	
		CLR	A
		movc	A, @A+DPTR
		JZ	pExit
		ACALL	printChar
		INC 	DPTR
		SJMP 	printString
pExit:		RET
;================================================================================
;| Print a character to the LCD	IN ACC						|
;================================================================================
printChar:
		push	0
		SETB	RS
		CLR	RW
		MOV	R0, #io_lcd
		SETB	P3.0
		MOVX	@R0, A
		acall	delay_5MS
		CLR	P3.0
		pop	0
		RET
;================================================================================
;| A delay for .5s							 	|
;================================================================================
halfSecondDelay:
		ACALL	delay_100ms
		ACALL	delay_100ms
		ACALL	delay_100ms
		ACALL	delay_100ms
		ACALL	delay_100ms
;================================================================================
;| Procedure that sends A to data bus and whats in DPTR to the address bus 	|
;================================================================================
ioToggle:
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0
		RET
;================================================================================
;| Iterative 100ms delay using delay_`1ms					|
;================================================================================
DELAY_100ms:							
	
		PUSH	3
		MOV	R3,#100
	HERE7:	ACALL	DELAY_1ms
		DJNZ	R3,HERE7
		POP	3
		RET
;================================================================================
;| Iterative 50ms delay using delay_1m						|
;================================================================================
DELAY_50ms:							
	
		PUSH	3
		MOV	R3,#50
	HERE8:	ACALL	DELAY_1ms
		DJNZ	R3,HERE2
		POP	3
		RET
;================================================================================
;| Iterative 10ms delay using delay_1m						|
;================================================================================
DELAY_10ms:							
	
		PUSH	3
		MOV	R3,#10
	HERE2:	ACALL	DELAY_1ms
		DJNZ	R3,HERE2
		POP	3
		RET
;================================================================================
;| Iterative 5ms delay using delay_1ms						|
;================================================================================
DELAY_5ms:
		PUSH 	3
		MOV 	A, #5
		MOV 	R3, A
	HERE3:	ACALL	DELAY_1MS
		DJNZ 	R3, HERE3
		POP 	3
		RET
;================================================================================
;| 1ms delay 									|
;================================================================================
DELAY_1ms:								
		PUSH 	3
		PUSH	4
					
		MOV	R3,#33
	
	HERE6:	MOV	R4,#14
	HERE5:	DJNZ	R4,HERE5
		DJNZ	R3,HERE6
		POP	4
		POP	3
		RET	
;================================================================================
;| Look up tables & Strings							|
;================================================================================

menu1:		db	'Michael Goberling\0'
menu2:		db	'B: Move D: Dump\0'
menu3:		db	'E: Edit F: Find\0'
menu4:		db	'Runtime: \0'
tempMenu:	db 	'Temperature: \0'

KCODE0:	db	'1', '2', '3', 'A'
KCODE1:	db	'4', '5', '6', 'B'
KCODE2:	db	'7', '8', '9', 'C'
KCODE3:	db	'F', '0', 'E', 'D'
		END