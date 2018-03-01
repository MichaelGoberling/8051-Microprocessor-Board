;****************************************
;*Author: Michael Goberling		*
;*Course: 4330 Microprocessor Design	*
;*Assignment: 8051 Source Code		*
;*Due date: 5/2/17			*
;*Revision: 1.46			*
;****************************************


		org 0h
		sjmp	start
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


;================================================================================
;| Start of the program								|
;================================================================================
start:		
		LCALL	LCD_INIT		;LCD initialization	
		
		MOV	R0, #IO_SEVENSEG	;clear 7 segment
		MOV	A, #11111111B
		LCALL	IOTOGGLE
		
		LCALL	wakeUp			;7 segment initialization(3 decimal place blinks)
relogin:	LCALL	login			;waits for a user to press 1 to continue
		LCALL	getPasscode		;user enters passcode that allows them access
		LCALL	RTC_INIT		;initialize the RTC so that login time is kept
		
monitormenu:	LCALL	displayMenu		;Display menu options
		
monitor:
		;LCALL	flash7seg		;quickly flash status of 7 segment
		LCALL	getTemp			;temperature in A now
		LCALL	getRTC			;update time by reading RTC regs
		LCALL	hexToAscii
		LCALL	printTemp		;print values in R6 and R7 to LCD

		;42h = move
		;44h = dump
		;45h = edit
		;46h = find
		LCALL	pollKeypad
		
		CJNE	A, #42H, compare1	;check for move, or 'B'
		LCALL	CLEAR_LCD		;if found, clear lcd
		MOV	DPTR, #test1		;print selection string
		LCALL	printString
		LCALL	halfseconddelay		;leave it up for some time
		LCALL	CLEAR_LCD		;clear lcd for entering menu
		LCALL	promptMove
		LCALL	MOVE			;go to main move function
		sjmp	monitormenu		;jump back
compare1:	
		CJNE	A, #44H, compare2	;check for dump, or 'D'
		LCALL	CLEAR_LCD			
		MOV	DPTR, #test2
		LCALL	printString
		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LCALL	promptDump
		LCALL	DUMP
		sjmp	monitormenu
compare2:
		CJNE	A, #45H, compare3	;check for edit, or 'E'
		LCALL	CLEAR_LCD
		MOV	DPTR, #test3
		LCALL	printString
		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LCALL	PROMPTEDIT
		LCALL	EDIT
		SJMP	monitormenu
compare3:
		CJNE	A, #46H, compare4	;check for find, or 'F'
		LCALL	CLEAR_LCD
		MOV	DPTR, #test4
		LCALL	printString
		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LCALL	PROMPTFIND
		LCALL	FIND
		SJMP	monitormenu
compare4:
		CJNE	A, #31H, compare5 	;check for logout, or '1'
		LCALL	CLEAR_LCD
		MOV	DPTR, #goodbye
		LCALL	printString
		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LJMP	relogin
compare5:
		CJNE	A, #31H, monitorLJMP	;check for logout, or '1'
		LCALL	CLEAR_LCD		;implemented monitorLJMP for 8-bit
		MOV	DPTR, #sevensegmsg	;address issues
		LCALL	printString
		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LJMP	sevenseg
		LJMP	monitormenu

monitorLJMP:	LJMP	monitor

FOREVER:	SJMP	FOREVER
;================================================================================
;| prompt for value between 30h and 7Fh to not mess with registers		|
;================================================================================
promptMove:
		
bdata:		Lcall	clear_lcd
		mov	DPTR, #bSource		;print menu message
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE			;2 byte block size will be in R1
		
		mov	A, R1
		mov	R2, A			;XX00H IN R2
		
		LCALL	GETBYTE

		MOV	A, R1
		MOV	R3, A			;00XXH IN R3

CONT27:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT26		;IF THEY HIT 'A' AND ACCEPT
		LJMP	REDO			;MOVE FORWARD
		
CONT26:		CJNE	A, #44H, CONT27		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	BDATA	
		
REDO:		LCALL	clear_lcd
		mov	DPTR, #bblock
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING

		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE			;Source address will be in R1
		mov	A, R1
		mov	R4, A			;XX00H IN R4

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R5, A			;00XXH IN R5

CONT29:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT28		;IF THEY HIT 'A' AND ACCEPT
		LJMP	CONT32			;MOVE FORWARD
		
CONT28:		CJNE	A, #44H, CONT29		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	REDO
	
CONT32:		CJNE	R5, #0, CONT6
		CJNE	R4, #0, CONT6		;CANT HAVE 0 AS THE BLOCK SIZE
		SJMP	REDO
		
CONT6:		LCALL	clear_lcd
		mov	DPTR, #bDest
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING

		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE			;Destination address now will be in R1
		mov	A, R1
		mov	R6, A			;XX00H IN R6

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R7, A			;00XXH IN R7

CONT31:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT30		;IF THEY HIT 'A' AND ACCEPT
		LJMP	ENDPROMPTMOVE		;MOVE FORWARD
		
CONT30:		CJNE	A, #44H, CONT31		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	CONT6	
		
ENDPROMPTMOVE:		
		RET
;================================================================================
;| Copy a block of memory to another location					|
;================================================================================
;SOURCE R2R3H
;BLOCK 	R4R5H
;DEST 	R6R7H

MOVE:	
		CLR	P3.0
						
back:		
		mov	DPH, R2
		mov	DPL, R3			;DPTR NOW CONTAINS SOURCE ADDR
		movx	A, @DPTR

		mov	DPH, R6
		mov	DPL, R7			;DPTR NOW CONTAINS DEST ADDR
		movx	@DPTR, A

		inc 	R3			;INC LOWER BYTES
		inc	R7

		DEC	R5			;DEC LOWER BYTE OF BLOCK SIZE

		CJNE	R3, #00H, CONT4		;IF LOWER BYTE OF SOURCE IS 00H AFTER INC
		INC	R2			;INC HIGH BYTE OF SOURCE
CONT4:
		CJNE	R7, #00H, CONT5		;IF LOWER BYTE OF DEST IS 00H AFTER INC
		INC	R6			;INC HIGH BYTE OF DEST	
CONT5:
		CJNE	R5, #0FFH, CONT3	;IF R7 IS FFH AFTER DEC, THEN DEC THE HIGH BYTE
		DEC	R4			;HERE
CONT3:
						;ELSE CONTINUE THE PROGRAM
		CJNE	R4, #0, BACK		;IF HIGH BYTE IS NOT ZERO, CONTINUE
		CJNE	R5, #0, BACK		;IF LOW BYTE IS NOT ZERO, CONTINUE
						;ELSE, IF BOTH ARE ZERO, THEN DONE
		LCALL	clear_lcd
		mov	DPTR, #bdone
		Lcall	printString
		LCALL	halfseconddelay
	
		RET
;================================================================================
;| prompt for values to show a given block of memory				|
;================================================================================
promptDump:
		LCALL	clear_lcd
		mov	DPTR, #bsource
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE			;Start address will be in R1
		mov	A, R1
		mov	R4, A			;XX00H IN DPH (R4)

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R5, A			;00XXH IN DPL (R5)

CONT35:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT34		;IF THEY HIT 'A' AND ACCEPT
		LJMP	BSIZEPROMPT		;MOVE FORWARD
		
CONT34:		CJNE	A, #44H, CONT35		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	PROMPTDUMP

BSIZEPROMPT:	LCALL	clear_lcd
		mov	DPTR, #bBlock
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB
		
		LCALL	GETBYTE			
		mov	A, R1
		mov	R2, A			;XX00H WILL BE IN R2

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R3, A			;00XXH WILL BE IN R3

CONT37:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT36		;IF THEY HIT 'A' AND ACCEPT
		LJMP	CONT33			;MOVE FORWARD
		
CONT36:		CJNE	A, #44H, CONT37		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	BSIZEPROMPT

CONT33:		CJNE	R2, #0, CONT14
		CJNE	R3, #0, CONT14
		LJMP	BSIZEPROMPT
CONT14:
		LCALL	CLEAR_LCD
		RET
;================================================================================
;| Show the contents of a given block of memory 				|
;================================================================================
;BLOCK SIZE:		R2R3H
;CURRENT ADDR:		R4R5H
;# Printed to Line:	R0H
;PAGE #:		R6H
;# PRINTED TO LCD:	R7H
;Temp reg for printing:	R1H
		
Dump:		
		CLR	P3.0
		MOV	R6, #0			;MAKE PAGE # 0 AS ORIGIN
		MOV	R7, #0			; # PRINTED TO LCD to 0
		MOV	R0, #0
		
loop:	
		MOV	DPH, R4
		MOV	DPL, R5
		MOVX	A, @DPTR		;(R4R5h)
		MOV	B, A
		anl	A, #0f0h
		rr	A
		rr	A
		rr	A
		rr	A
		mov	R1, A			;To save the raw value
		CLR	C
		SUBB	A, #0Ah			;check if letter
		jnc	letter3
		mov	A, R1			;Reload A
		orl	A, #30h			;Should have ascii number value now(03h --> 33h)
		LCALL	printChar		;put character to LCD
		sjmp	next
letter3:	mov	A, R1
		orl	A, #30h			;ascii non-normalized
		add	A, #07h			;ascii normalized (3Fh --> 46h)
		LCALL	printChar
next:		mov	A, B
		anl	A, #0fh
		mov	R1, A			;to copy before check
		CLR	C
		subb	A, #0Ah
		jnc	letter4
		mov	A, R1
		orl	A, #30h
		LCALL	printChar
		sjmp	finish
letter4:	mov	A, R1
		orl	A, #30h
		add	A, #07h
		LCALL	printChar		;print the normalized second character
finish:		mov	A, #20h
		LCALL	printChar		;print space
		

		INC	R0			;INC AMOUNT PRINTED TO LINE
		INC	R5			;INC CURRENT ADDRESS
		INC	R7			;INC AMOUNT PRINTED TO LCD

		
		CJNE	R5, #00H, CONT13
		INC	R4			;INC HIGH BYTE IF LOW BYTE OV
CONT13:
		DEC	R3			;DEC LOW BYTE OF BLOCK SIZE
		CJNE	R3, #0FFH, CONT15
		DEC	R2			;DEC HIGH BYTE IF LOW BYTE UV
CONT15:

		CJNE	R2, #0, CONT11		;If maximum block size hasnt been reached, then move
		CJNE	R3, #0, CONT11		;forward
		LJMP	DONE			;IF BOTH HIGH AND LOW BYTE OF BLOCK SIZE 0, JUMP
						;TO DONE AND PROMPT
CONT11:
		CJNE	R0, #6, LOOP		;IF LINE ISNT FILLED, KEEP PRINTING
		LCALL	PUT_LINE2		;OTHERWISE, MOVE TO SECOND LINE
		MOV	R0, #0			;CLEAR AMOUNT PRINTED TO LINE, AND PRINT NEXT LINE
		CJNE	R7, #12, LOOP		;CHECK IF TOTAL AMOUNT PRINTED TO LCD IS 12
						
DONE:		
		MOV	DPH, R4
		MOV	DPL, R5
		
		PUSH	DPH
		PUSH	DPL
		
		MOV	DPTR, #DUMPPROMPT
		LCALL	PUT_LINE3
		LCALL	PRINTSTRING

		MOV	DPTR, #DUMPPROMPT2
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		
		POP	DPL
		POP	DPH
		
		;LCALL	PUTDUMPADDR		;PRINT NEXT ADDRESS
		
DONE3:		LCALL	PROMPTKEYPAD		;WHEN BLOCK SIZE IS FULL, PROMPT, 
						;WHEN LCD IS FILLED, PROMPT
		CJNE	A, #32H, CONT16		;PROMPT FOR EXIT, IF NOT PRESSED, CHECK '0'
		LJMP	ENDDUMP
		
CONT16:		CJNE	A, #30H, CONT17		;TRY TO GO TO NEXT PAGE, IF NOT PRESSED, CHECK '1'
		CJNE	R2, #0, NEXTPAGE	;If maximum block size has been reached, then DONT GO
		CJNE	R3, #0, NEXTPAGE	;TO NEXT PAGE
		LJMP	DONE3			;IF BLOCK SIZE REACHED, INVALID KEY PRESS

CONT17:		CJNE	A, #31H, DONE3		;TRY TO GO TO PREVIOUS PAGE, IF NOT PRESSED, REPROMPT
		CJNE	R6, #0, PREVPAGE	;CHECK PAGE ZER0 
		LJMP	DONE3			;IF PAGE 0, REPROMPT

NEXTPAGE:	LCALL	CLEAR_LCD		;next page routine
		INC	R6			;INC PAGE #
		MOV	R7, #0
		LJMP	LOOP
		
PREVPAGE:	LCALL	CLEAR_LCD		;previous page routine
		MOV	R0, #0			;RESET AMOUNT PRINTED TO LINE
		DEC	R6			;DEC PAGE #

		MOV	A, R3			;LOW BYTE OF BLOCK SIZE
		CLR	C
		ADD	A, R7			;REUPDATE BLOCK SIZE
		JC	INCHBYTE
		CLR	C
		ADD	A, #12			;ADD LAST PAGE AMOUNT
		JC	INCHBYTE2
		MOV	R3, A			;UPDATE LOW BYTE OF BLOCK
		SJMP	CONT18


INCHBYTE:	INC	R2			;INC HIGH BYTE IF CARRY ON R7 ADDITION
		ADD	A, #12
		MOV	R3, A			;UPDATE LOW BYTE OF BLOCK
		SJMP	CONT18
		
INCHBYTE2:	INC	R2			;INC HIGH BYTE IF CARRY ON 12 ADDITION
		MOV	R3, A			;UPDATE LOW BYTE OF BLOCK
	
CONT18:		MOV	A, R5			;MOVE BACK LOW BYTE OF CURRENT ADDRESS 
		CLR	C
		SUBB	A, #12
		JC	DECHBYTE		;NO CARRY ON FIRST SUBB
		CLR	C
		SUBB	A, R7			;SUBB CURRENT PAGE AMOUNT
		JC	DECHBYTE2		;CHECK IS CARRY ON PAGE AMOUNT SUBB
		MOV	R5, A
		MOV	R7, #0			;clear amount printed to page
		LJMP	LOOP
		
DECHBYTE:
		DEC	R4			;CARRY ON FIRST SUBB, UPPER BYTE UPDATED
		SUBB	A, R7			;SUBB CURRENT PAGE AMOUNT
		MOV	R5, A
		MOV	R7, #0			;clear amount printed to page
		LJMP	LOOP			;REPRINT AND REPROMPT WITH NEW ADDRESS
		
DECHBYTE2:	DEC	R4			;PREVIOUS ADDRESS
		MOV	R5, A
		MOV	R7, #0			;CLEAR AMOUNT PRINTED TO PAGE
		LJMP	LOOP
ENDDUMP:		
		RET
;================================================================================
;| PRINT ADDRESS FOR DUMP						|
;================================================================================
PUTDUMPADDR:
		LCALL	PUT_ADDR
		mov	A, #28h				;print '('
		LCALL	printChar

		MOV	DPH, R4				;PUT SAVED DPH IN DPH
		MOV	A, R4
		LCALL 	PRINTADDR			;printAddr will print HIGH BYTE 

		MOV	DPL, R5				;PUT SAVED DPL IN DPL
		MOV	A, R5				;PRINTADRR WILL PRINT LOW BYTE
		LCALL	PRINTADDR
		
		mov	A, #68h				;print 'h'
		LCALL	printChar
		
		mov	A, #29h				;print ')'
		LCALL	printChar
		
		RET
;================================================================================
;| Prompt for edit values							|
;================================================================================
promptEdit:
		
		LCALL	clear_lcd
		mov	DPTR, #eSource
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB

bData1:		LCALL	GETBYTE			;Source address will be in R1
		mov	A, R1			
		mov	DPH, A			;DPH NOW XX00H
		MOV	R3, A			;SAVE DPH IN R3

		LCALL	GETBYTE
		MOV	A, R1
		MOV	DPL, A			;DPL NOW 00XXH
		MOV	R4, A			;SAVE DPL IN R4

CONT40:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT39		;IF THEY HIT 'A' AND ACCEPT
		LJMP	CONT38			;MOVE FORWARD
		
CONT39:		CJNE	A, #44H, CONT40		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	PROMPTEDIT

CONT38:
		
	here12:	RET
;================================================================================
;| edit byte by byte starting at a location					|
;================================================================================
edit:
		CLR	P3.0
		
		LCALL	clear_lcd
		mov	A, #28h				;print '('
		LCALL	printChar

		MOV	DPH, R3				;PUT SAVED DPH IN DPH
		MOV	A, R3
		LCALL 	PRINTADDR			;printAddr will print HIGH BYTE 

		MOV	DPL, R4				;PUT SAVED DPL IN DPL
		MOV	A, R4				;PRINTADRR WILL PRINT LOW BYTE
		LCALL	PRINTADDR
		
		mov	A, #68h				;print 'h'
		LCALL	printChar
		
		mov	A, #29h				;print ')'
		LCALL	printChar
	
		mov	A, #3Ah				;print ':'
		LCALL	printChar
	
		mov	A, #20h				;print space
		LCALL	printchar
		
		LCALL	printByte			;print the byte
		
		LCALL 	PUT_LINE2			;Go to next line
		
		PUSH	DPH
		PUSH	DPL
		
		mov	DPTR, #replace			;Point dptr to replace request string
		LCALL	PRINTSTRING

		MOV	DPTR, #DIGITMSG1
		LCALL	PUT_LINE3
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE4_CB

		POP	DPL
		POP	DPH
		
		LCALL	GETBYTE				;New byte should be in R1
		
		MOV	A, R1				;new byte is in A
		MOV	DPH, R3
		MOV	DPL, R4
		MOVX	@DPTR, A			;move new byte to source address location

		LCALL	clear_lcd
		mov	A, #28h				;print '('
		LCALL	printChar
		
		MOV	DPH, R3
		MOV	A, DPH
		LCALL 	PRINTADDR			;printAddr will print HIGH BYTE 

		MOV	DPL, R4
		MOV	A, DPL				;PRINTADRR WILL PRINT LOW BYTE
		LCALL	PRINTADDR
	
		mov	A, #68h				;print 'h'
		LCALL	printChar
		
		mov	A, #29h				;print ')'
		LCALL	printChar
	
		mov	A, #3Ah				;print ':'
		LCALL	printChar
	
		mov	A, #20h				;print space
		LCALL	printchar
		
		LCALL	printByte			;print the updated byte
		
		mov	A, #68h
		LCALL	printchar
		
		LCALL	PUT_LINE2
		mov	DPTR, #user1
		LCALL	printString

		LCALL	PUT_LINE3
		MOV	DPTR, #user2
		LCALL	PRINTSTRING
		
	eInput:	LCALL	promptKeypad			;To get a decision from the user
		cjne	A, #31h, cont1			;if key press is 1 exit, else continue
		mov	DPTR, #exitmsg
		LCALL	clear_lcd
		LCALL	printString
		sjmp	done2
		
	cont1:	cjne	A, #30h, eInput
		INC	R4
		CJNE	R4, #00H, OV1
		INC	R3
OV1:		
		LJMP	Edit		
done2:
		RET
;================================================================================
;| PROMPT USED FOR FIND								|
;================================================================================
promptFind:
		LCALL	clear_lcd
		mov	DPTR, #esource
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE
		mov	A, R1
		mov	R2, A			;high byte of address now in xx00h R2

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R3, A			;low byte of address now in 00xxh R3
						;source address now in DPTR
CONT42:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT41		;IF THEY HIT 'A' AND ACCEPT
		LJMP	ZERO			;MOVE FORWARD
		
CONT41:		CJNE	A, #44H, CONT42		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	PROMPTFIND
		
ZERO:		LCALL	clear_lcd
		mov	DPTR, #fBlock
		LCALL	printString

		MOV	DPTR, #DIGITMSG
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING
		
		LCALL	PUT_LINE3_CB
		
		LCALL	GETBYTE
		mov	A, R1
		mov	R4, A			;XX00H OF BLOCK SIZE IN R4

		LCALL	GETBYTE
		MOV	A, R1
		MOV	R5, A			;00XXH OF BLOCK SIZE IN R5

CONT44:		MOV	DPTR, #VERIFYINPUT
		LCALL	PUT_LINE4
		LCALL	PRINTSTRING
		LCALL	PROMPTKEYPAD
		
		CJNE	A, #41H, CONT43		;IF THEY HIT 'A' AND ACCEPT
		LJMP	CONT45			;MOVE FORWARD
		
CONT43:		CJNE	A, #44H, CONT44		;IF THEY HIT 'D' AND WANT TO REDO
		LJMP	ZERO
		
CONT45:		CJNE	R5, #0, CONT7
		CJNE	R4, #0, CONT7		;CANT HAVE BLOCK SIZE OF ZERO
		LJMP	ZERO
CONT7:
		LCALL	clear_lcd
		mov	DPTR, #FindByte
		LCALL	printString

		MOV	DPTR, #DIGITMSG1
		LCALL	PUT_LINE2
		LCALL	PRINTSTRING

		LCALL	PUT_LINE3_CB
		LCALL	GETBYTE
		mov	A, R1
		mov	R6, A			;byte to find in R6

		LCALL	clear_lcd
		RET

;================================================================================
;| See if a byte is in a specific location					|
;================================================================================
;SOURCE	R2R3H
;BLOCK	R4R5H
;BYTE	R6H
find:
		CLR	P3.0
		
		MOV	DPH, R2
		MOV	DPL, R3
		movx	A, @DPTR		;GET VALUE IN AT ADDRESS LOCATION

		CLR	C
		subb	A, R6			
		jz	Found			;IF THE RESULT IS ZERO, THEN THE BYTE IS FOUND
		
		CJNE	R4, #0, CONT8
		CJNE	R5, #0, CONT8		;SEE IF WE ARE OUT OF BLOCK SIZE
						;IF NOT, CONTINUE, INC DPTR, DEC BLOCK SIZE
		MOV	DPTR, #nFound		;Didn't find byte, print message
		LCALL	printSTRING
		LCALL	HALFSECONDDELAY
		LCALL	HALFSECONDDELAY

		SJMP	HERE14			;RETURN TO THE PROGRAM

CONT8:		
		
		INC	R3
		CJNE	R3, #00H, CONT9
		INC	R2			;CHECK IF LOWER BYTE HAS BEEN OVERFLOWED
CONT9:
		DEC	R5
		CJNE	R5, #0FFH, CONT10
		DEC	R4			;CHECK IF LOWER BYTE HAS ROLLED OVER
CONT10:
		LJMP	FIND			;HAVE NEW DPTR VALUE, AND NEW BLOCK SIZE
		
Found:		
		PUSH	DPH
		PUSH	DPL
		mov	DPTR, #FOUNDBYTE	;Found the byte, print message
		LCALL	printSTRING

		POP	DPL
		POP	DPH

		LCALL	PUT_LINE2
		mov	A, #28h			;put '('
		LCALL	PRINTchar

		MOV	A, DPH			;PRINT DPH
		LCALL	PRINTADDR		;print the address it was found at @DPTR

		MOV	A, DPL			;PRINT DPL
		LCALL	PRINTADDR
		
		mov	A, #68h			;print 'h'
		LCALL	PRINTChar
	
		mov	A, #29h			;'put ')'
		LCALL	PRINTchar		

		LCALL	HALFSECONDDELAY
		LCALL	HALFSECONDDELAY
		LCALL	HALFSECONDDELAY
		LCALL	HALFSECONDDELAY
		
		here14:	RET	
;================================================================================
;| To flash status decimal place						|
;================================================================================
flash7seg:
		PUSH	0
		SETB	P3.0
		MOV	R0, #io_sevenseg

		MOV	A, #01111111b
		LCALL	ioToggle			;what is in dptr goes to address, A to data
		LCALL	delay_50ms
		
		MOV	A, #11111111b
		LCALL	ioToggle
		
		POP	0
		CLR	P3.0
		RET
;================================================================================
;| To update the time... 							|
;================================================================================	
getRTC:	
		push	0
		push	acc
		
		LCALL	PUT_RTC				;print it to the correct spot

		MOV	R0, #45H			;top hour digit
		LCALL	readReg
		ORL	A, #30H				;convert to ascii
		LCALL	printChar				

		MOV	R0, #44H			;bottom hour digit
		LCALL	readReg
		ORL	A, #30H
		LCALL	printChar
		
		MOV	A, #3Ah				;print ":"
		LCALL	printChar

		MOV	R0, #43H			;get top minute digit
		LCALL	readReg
		ORL	A, #30H
		LCALL	printChar

		MOV	R0, #42H			;get bottom minute digit
		LCALL	readReg
		ORL	A, #30H				;convert to ascii
		LCALL	printChar

		MOV	A, #3AH				;print ":"
		LCALL	printChar

		MOV	R0, #41H
		LCALL	readReg
		ORL	A, #30H
		LCALL	printChar

		MOV	R0, #40H
		LCALL	readReg
		ORL	A, #30H
		LCALL	printChar

		pop	acc
		pop	0
		RET

;================================================================================
;| To update the temperature... 						|
;================================================================================
getTemp:	
		PUSH	0
		MOV	R0, #10H
		SETB	P3.0				;Get the info from the ADC
		MOVX	A, @R0
		SUBB	A, #9
		CLR	P3.0
		POP	0
		
		RET
;================================================================================
;| To print the byte at an address						|
;================================================================================
printAddr:
		push	0E0h
		push 	1		
		MOV	B, A
		anl	A, #0f0h
		rr	A
		rr	A
		rr	A
		rr	A
		mov	R7, A			;To save the raw value
		CLR	C
		SUBB	A, #0Ah			;check if letter
		jnc	letter5
		mov	A, R7			;Reload A
		orl	A, #30h			;Should have ascii number value now(03h --> 33h)
		LCALL	printChar			;put character to LCD
		sjmp	next2
	letter5:mov	A, R7
		orl	A, #30h			;ascii non-normalized
		add	A, #07h			;ascii normalized (3Fh --> 46h)
		LCALL	printChar
	next2:	mov	A, B
		anl	A, #0fh
		mov	R7, A			;to copy before check
		CLR	C
		subb	A, #0Ah
		jnc	letter6
		mov	A, R7
		orl	A, #30h
		LCALL	printChar
		sjmp	finish2
	letter6:mov	A, R7
		orl	A, #30h
		add	A, #07h
		LCALL	printChar			;print the normalized second character
	finish2:
		pop	1
		pop	0E0h
		RET

;================================================================================
;| To print temperature to the LCD						|
;================================================================================
printTemp:	
		
		LCALL	PUT_TEMP			
		MOV	A, R6				;10s place of the temp
		LCALL	printChar
		MOV	A, R7				;1s place of the temp
		LCALL	printChar
		MOV	A, #0DFH			;print degree symbol
		LCALL	printChar
		MOV	A, #43H
		LCALL	printChar
		
		RET	
;================================================================================
;| Converts byte in A from hex to ascii						|
;================================================================================
hexToAscii:
		MOV	B, #10
		DIV	AB
		MOV	R7, B
		MOV	B, #10
		DIV	AB
		MOV	R6, B
		MOV	R5, A
		ORL	7, #30H				;first digit in R7
		ORL	6, #30H				;Second digit in R6
		ORL	5, #30H				;Third digit in R5
		RET
;================================================================================
;| Waits for somebody to login							|
;================================================================================
login:		
		LCALL	CLEAR_LCD
		MOV	A, #0CH				;TURN CURSOR OFF
		LCALL	COMNWRT

REPRINT:	
		MOV	R0, #92H			;TOP RIGHT
		MOV	R1, #95H			;BOTTOM LEFT
		MOV	R2, #20H			;SPACE
		MOV	R3, #0C0H			;LEFT BAR
		MOV	R4, #0D3H			;RIGHT BAR

CONTPRINT:	MOV	DPTR, #LOGINART1
		LCALL	PUT_LINE1
		LCALL	PRINTSTRING
		
		MOV	DPTR, #osName
		LCALL	PUT_LINE2
		LCALL	printString

		MOV	DPTR, #LOGINART2
		LCALL	PUT_LINE3
		LCALL	PRINTSTRING
		
		MOV	DPTR, #loginMSG
		LCALL	PUT_LINE4
		LCALL	printString

CONT22:		LCALL	PROMPTKEYPAD
		CJNE	A, #31h, CONT22			;IF A ONE IS NOT PRESSED, KEEP PRINTING ART
		LJMP	ENDLOGIN			;OTHERWISE IF IT IS EQUAL TO 1, LOGIN

		;BORDER ART AND ANIMATION
;		MOV	A, R0				;PUT AT APPROPRIATE ADDRESS OF TOP BAR
;		LCALL	PUT_FLEX
;		MOV	A, R2				;LOAD SPACE
;		LCALL	PRINTCHAR
;		DEC	R0				;DECREMENT THE TOP BAR ADDRESS
;
;		MOV	A, R1
;		LCALL	PUT_FLEX			;PUT AT BOTTOM BAR
;		MOV	A, R2				;LOAD SPACE
;		LCALL	PRINTCHAR
;		CJNE	R1, #0A6H, CONT21
;		LJMP	RIGHTLEFT
;CONT21:
;		LCALL	POLLKEYPAD
;		CJNE	A, #31h, CONT19			;IF A ONE IS NOT PRESSED, KEEP PRINTING ART
;		SJMP	ENDLOGIN			;OTHERWISE IF IT IS EQUAL TO 1, LOGIN
;CONT19:	
;		INC	R1				;INCREMENT THE BOTTOM BAR ADDRESS
;		;LCALL	DELAY_100MS
;		LJMP	CONTPRINT
;
;RIGHTLEFT:
;		MOV	A, R3				;PRINT SPACE AT LEFT BAR
;		LCALL	PUT_FLEX
;		MOV	A, R2
;		LCALL	PRINTCHAR
;
;		MOV	A, R4				;PRINT SPACE AT RIGHT BAR
;		LCALL	PUT_FLEX
;		MOV	A, R2
;		LCALL	PRINTCHAR
;
;		LCALL	POLLKEYPAD
;		CJNE	A, #31h, CONT22			;IF A ONE IS NOT PRESSED, KEEP PRINTING ART
;		LJMP	ENDLOGIN			;OTHERWISE IF IT IS EQUAL TO 1, LOGIN
;CONT22:
;
;		;LCALL	DELAY_100MS		
;		LJMP	REPRINT
ENDLOGIN:	
		RET
;================================================================================
;| Displays the passcode prompt messages					|
;================================================================================
displayPasscode:
		LCALL	CLEAR_LCD
		MOV	DPTR, #myPasscode
		LCALL	PUT_LINE1
		LCALL	printString

		LCALL	PUT_LINE2_CB
		;MOV	DPTR, #myPasscode2
		;LCALL	PUT_LINE2
		;LCALL	printString
		
		RET
;================================================================================
;| Gets the key presses and decides if they are valid				|
;================================================================================
getPasscode:
		CLR	A
		MOV	R6, #3					;TRIES LEFT
		MOV	R5, #0					;PROFILE #
retry:			
		MOV	DPTR, #attempts				;print attempts string
		LCALL	PUT_LINE4
		LCALL	printString

		MOV	A, R6					;print attempts left number
		ORL	A, #30H
		LCALL	printChar
		CLR	A

		LCALL	displayPasscode				;display passcode message
		
		CLR	A
		LCALL	promptKeypad				;get first digit in ascii from keypad
		;MOV	A, #38h					;TEST

		PUSH	ACC
		MOV	A, #2AH
		LCALL	printChar				;print * to the LCD
		POP	ACC

		ANL	A, #0FH
		LCALL	rotateleft
		MOV	R1, A					;move to R0 to save

		CLR	A
		LCALL	promptKeypad
		;MOV	A, #37H					;TEST
		PUSH	ACC
		MOV	A, #2AH
		LCALL	printChar				;print * to the LCD
		POP	ACC
		ANL	A, #0FH
		ORL	A, R1					;first byte of pw in R1
		MOV	R1, A					;new cumulative saved
		MOV	R2, A					;saved in R2 also

		CLR	A
		LCALL	promptKeypad
		;MOV	A, #30H					;TEST
		PUSH	ACC
		MOV	A, #2AH
		LCALL	printChar				;print * to the LCD
		POP	ACC
		ANL	A, #0FH
		LCALL	rotateleft
		MOV	R0, A					;new cumulative saved
		
		CLR	A
		LCALL 	promptKeypad
		;MOV	A, #31H					;TEST
		PUSH	ACC
		MOV	A, #2AH
		LCALL	printChar				;print * to the LCD
		POP	ACC
		ANL	A, #0FH
		ORL	A, R0					;second byte of pw stored in r0
		MOV	R3, A					;saved in R3 also
		MOV	R0, A

		LCALL	delay_100ms				;so you can see full password
		
;R1 and R2 contain xx 
;R0 and R3 contain yy 
;to make 'xxyy' the password

		MOV	DPTR, #pwList				;LUT of valid passwords
checkPW:	CLR	A
		MOV	A, R2					;load saved cumulative value
		MOV	R1, A
		CLR	A
		MOVC	A, @A+DPTR				;grab actuall password value from LUT
		JZ	doOver					;if end of LUT is hit, reprompt

		CLR	C
		SUBB	A, R1					;otherwise check xx
		JZ	secondByte				;if they are exact, valid xx
		INC	DPTR					;otherwise, pw cannot be valid at all
		INC	DPTR					;inc dptr and jump to next xxyy

		CLR	A
		MOVC	A, @A+DPTR				;check first byte of next xxyy
		JZ	doOver					;if zero, end of LUT reached
		INC	R5					;otherwise, increment potential profile
		sjmp 	checkPW					;check the next pw in LUT
secondByte:
		INC	DPTR
		MOV	A, R3					;load yy
		MOV	R0, A
		CLR	A				
		MOVC	A, @A+DPTR				;load yy of saved LUT value

		CLR	C					
		SUBB	A, R0					;check if equal
		JZ	success					;if exact, valid yy
		INC	DPTR					;otherwise jump to next xxyy
		INC	R5					;update potential profile
		SJMP	checkPW					;repeat check
doOver:		
		MOV	R5, #0					;clear potential profile if re-entering
		LCALL	CLEAR_LCD				
		MOV	DPTR, #incorrectCode			;print incorrect code prompt
		LCALL	PUT_LINE1
		LCALL	printString
		LCALL	halfseconddelay

		LCALL	CLEAR_LCD
		CLR	A					;conditional to check if we should
		DEC	R6					;retry or lock the system
		MOV	A, R6
		JZ	lockout					;jump if zero to lock system

		MOV	DPTR, #tryagain				;prompt again if more tries
		LCALL	PUT_LINE1
		LCALL	printString
		LCALL	halfseconddelay
		LJMP	retry

		
		;DJNZ	R6, retry				;Three tries to get pw right before
		;SJMP	lockout					;entering lockout

success:	LCALL	CLEAR_LCD				;clear the lcd
		MOV	DPTR, #pwSuccess			;and print success message
		LCALL	printString

		;check profiles to display
		;michael = 0
		;collin = 1
		;riley = 2
		
		LCALL	checkProfile				;uses R5 to determine what profile 
								;has put their passcode in
		
		RET
;================================================================================
;| After 3 unsuccessful logins, lock the board					|
;================================================================================		
lockout:	
		LCALL	CLEAR_LCD
		MOV	DPTR, #lockedmsg		;display lockout message for all-time
		LCALL	PUT_LINE1			;on line 1 of LCD
		LCALL	printString
		
locked:		SJMP	locked				;infinite loop

		RET		
;================================================================================
;| [UNUSED]Scramble the input value in A for security				|
;================================================================================		
scrambleKey:
		ADD	A, #23H				;Michael Jordan

		RL	A				;Rotate left three times for '91-'93
		RL	A
		RL	A				

		RL	A				;Rotate left three more times for '96-'98
		RL	A
		RL	A			

		RET

;================================================================================
;| iterate through list of profiles to compare R5 to 				|
;================================================================================
checkProfile:	
		LCALL	PUT_LINE2
		CJNE	R5, #0, checkCollin			;check for michael
		MOV	DPTR, #michael
		SJMP	printName

checkCollin:	CJNE	R5, #1, checkRiley			;check for collin
		MOV	DPTR, #collin
		SJMP	printName

checkRiley:	CJNE	R5, #2, checkSharif			;check for riley
		MOV	DPTR, #riley				;if not, exit (should never happen)
		SJMP	printName

checkSharif:	CJNE	R5, #3, checkJeff			;check for prof. sharif
		MOV	DPTR, #sharif
		SJMP	printName
		
checkJeff:	CJNE	R5, #4, exit				;check for jeff
		MOV	DPTR, #jeff

printName:	LCALL	printString
		LCALL	halfseconddelay
exit:				
		RET
;================================================================================
;| Procedure for 7-segment interaction						|
;================================================================================
sevenseg:
		push	0
		MOV	R0, #IO_SEVENSEG
		
		;will implement 7-segment interaction
		;at a later date

		pop	0
		
		RET
;================================================================================
;| Rotates left 4 times								|
;================================================================================		
rotateleft:	
		RL	A
		RL	A
		RL	A
		RL	A
		RET
;================================================================================
;| Procedure to wait for an ascii byte press by the user; "1" = 31h		|
;================================================================================
promptKeypad:
		MOV 	keypad, #0FFh
	K1:	MOV	keypad, #0FH			
		MOV	A, keypad
		ANL	A, #0Fh
		CJNE	A, #0Fh, K1			;check if key is still pressed on pad
	K2:	LCALL	delay_1ms				
		MOV	A, keypad
		ANL	A, #0Fh
		CJNE	A, #0Fh, OVER			;if not, then ground each row until 0 found
		SJMP	K2
	OVER:	LCALL	delay_1ms
		MOV	A, keypad
		ANL	A, #0Fh
		CJNE	A, #0Fh, OVER1
		SJMP	K2
	OVER1:	MOV	keypad, #0EFH			;row 0 (1110)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, ROW_0
		MOV	keypad, #0DFH			;row 1 (1101)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, ROW_1
		MOV	keypad, #0BFH			;row 2 (1011)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, ROW_2			;row 3 (0111)
		MOV	keypad, #07FH
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, ROW_3
		LJMP	K2
	ROW_0:	MOV	DPTR, #KCODE0
		sjmp 	kFIND
	ROW_1:	MOV	DPTR, #KCODE1
		sjmp 	kFIND
	ROW_2:	MOV	DPTR, #KCODE2
		sjmp 	kFIND
	ROW_3:	MOV	DPTR, #KCODE3
		sjmp 	kFIND
	kFIND:	RRC	A
		JNC	MATCH
		INC	DPTR
		sjmp	kFIND
	MATCH:	CLR	A
		MOVC	A, @A+DPTR
		MOV	keypad, A
		RET
;================================================================================
;| Procedure to poll for an ascii byte press by the user; "1" = 31h		|
;================================================================================
pollKeypad:
		MOV	keypad, #0FFh
	K3:	MOV	keypad, #0Fh
		LCALL	delay_1ms
		MOV	A, keypad
		ANL	A, #0Fh
		CJNE	A, #0Fh, OVER3
		SJMP	exit1				;otherwise, exit and go back to updating
	OVER3:	MOV	keypad, #0EFH			;row 0 (1110)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, xROW_0
		MOV	keypad, #0DFH			;row 1 (1101)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, xROW_1
		MOV	keypad, #0BFH			;row 2 (1011)
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, xROW_2			;row 3 (0111)
		MOV	keypad, #07FH
		MOV	A, keypad
		ANL	A, #0FH
		CJNE	A, #0FH, xROW_3
		LJMP	exit1
	xROW_0:	MOV	DPTR, #KCODE0
		sjmp 	kFIND2
	xROW_1:	MOV	DPTR, #KCODE1
		sjmp 	kFIND2
	xROW_2:	MOV	DPTR, #KCODE2
		sjmp 	kFIND2
	xROW_3:	MOV	DPTR, #KCODE3
		sjmp 	kFIND2
	kFIND2:	RRC	A
		JNC	MATCH2
		INC	DPTR
		sjmp	kFIND2
	MATCH2:	CLR	A
		MOVC	A, @A+DPTR
		MOV	keypad, A
	exit1:	
		RET
;================================================================================
;| 7 Segment wakeup procedure (3 DP blinks)				 	|
;================================================================================
wakeUp:		
		PUSH	0
		SETB	P3.0
		MOV	R0, #io_sevenseg

		MOV	A, #01111111b
		LCALL	ioToggle			;what is in dptr goes to address, A to data
		LCALL	delay_100ms
		LCALL	delay_100ms
		
		MOV	A, #11111111b
		LCALL	ioToggle
		LCALL	delay_100ms
		LCALL	delay_100ms

		MOV	A, #01111111b
		LCALL	ioToggle
		LCALL	delay_100ms
		LCALL	delay_100ms

		MOV	A, #11111111b
		LCALL	ioToggle
		LCALL	delay_100ms
		LCALL	delay_100ms

		MOV	A, #01111111b
		LCALL	ioToggle
		LCALL	delay_100ms
		LCALL	delay_100ms

		MOV	A, #11111111b
		LCALL	ioToggle
		LCALL	delay_100ms
		LCALL	delay_100ms
		POP	0
		CLR	P3.0
		
		RET
;================================================================================
;| Procedure to display my name on the LCD					|
;================================================================================
displayName:
		LCALL	PUT_LINE1
		MOV	DPTR, #myName
		LCALL	printString

		LCALL	PUT_LINE2
		MOV	DPTR, #myClass
		LCALL	printString

		LCALL	halfseconddelay
		LCALL	CLEAR_LCD
		LCALL	halfseconddelay
		
		RET
;================================================================================
;| Procedure to display the menu on the LCD screen				|
;================================================================================
displayMenu:
		LCALL	CLEAR_LCD
		LCALL	PUT_LINE2			;print choices 1
		MOV	DPTR, #menu1
		LCALL	printString			;will print the string pointed @ by dptr

		LCALL	PUT_LINE3			;print choices 2
		MOV	DPTR, #menu2
		LCALL	printString

		LCALL	PUT_LINE4			;print choices 2
		MOV	DPTR, #logout
		LCALL	printString
		
		RET
;================================================================================
;| Procedure to initialize the LCD						|
;================================================================================
LCD_INIT:			
		CLR	RW
		CLR	RS
				
		LCALL	DELAY_50MS

		MOV	A, #38H
		LCALL	COMNWRT
		LCALL	DELAY_1MS

		MOV	A, #38H
		LCALL	COMNWRT
		LCALL	DELAY_1MS

		MOV	A, #0CH
		LCALL	COMNWRT
		LCALL	DELAY_1MS

		MOV	A, #01H
		LCALL	COMNWRT
		LCALL	DELAY_5MS

		MOV	A, #06H
		LCALL	COMNWRT

		RET
;================================================================================
;| RTC initialization								|
;================================================================================
RTC_INIT:
		
		MOV	R0, #4Fh			;F REG INIT
		MOV	A, #00h
		LCALL	ioToggle			;Send whats in R0 to Address bus
							;Send whats in A to data bus
		MOV	R0, #4Dh
		MOV	A, #00h				;CD register init
		LCALL	ioToggle

		;LCALL	checkBusy
		
		MOV	R0, #4FH
		MOV	A, #03H				;RESET THE COUNTER
		LCALL	ioToggle

		;SET CURRENT TIME FOR REGS
		MOV	R0, #40H			;FIRST SECONDS
		MOV	A, #00H		
		;LCALL	SETHOLD	
		LCALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #41H			;SECOND SECONDS
		MOV	A, #00H		
		;LCALL	SETHOLD	
		LCALL	IOTOGGLE
		;LCALL	CLEARHOLD
			
		MOV	R0, #42H			;ETC...
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #43H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #44H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #45H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #46H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #47H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #48H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #49H
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #4AH
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		MOV	R0, #4BH
		MOV	A, #00H		
		;LCALL	SETHOLD	
		CALL	IOTOGGLE
		;LCALL	CLEARHOLD

		
		;START COUNTER AND RELEASE HOLD
		MOV	R0, #4Fh			;F REG INIT
		MOV	A, #00h
		LCALL	ioToggle

		MOV	R0, #4Dh
		MOV	A, #00h				;CD register init
		LCALL	ioToggle
		
		RET
;================================================================================
;| Check if the RTC is busy							|
;================================================================================
checkBusy:
		PUSH	0
		PUSH	ACC
		MOV	R0, #4Dh			;GET CD REG IN RTC
waitBusy:	
		MOV	A, #05H
		SETB	P3.0
		MOVX	@R0, A			;SET HOLD
		CLR	P3.0

		SETB	P3.0
		MOVX	A, @R0			;READ IN THE CD REG
		CLR	P3.0

		;JNB	ACC.1, busyReady	;CHECK IF BUSY BIT HIGH

		MOV	A, #04h
		SETB	P3.0
		MOVX	@R0, A			;clear hold to let busy bit update
		CLR	P3.0
		LCALL	DELAY_1MS
		SJMP	waitBusy

busyReady:	
		POP	ACC
		POP	0
		
		RET
;================================================================================
;| Read a register in the RTC							|
;================================================================================
readReg:	
		PUSH	0
		PUSH	ACC
		
		MOV	R0, #4DH			;SET THE HOLD BIT
		MOV	A, #05H
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0
		
		POP	ACC
		POP	0
		
		;LCALL	checkBusy			;Wait until not busy
		SETB	P3.0					;read valUE
		MOVX 	A, @R0
		CLR	P3.0

		ANL	A, #0FH				;MASK OFF LOWER HALF
		
		PUSH	ACC
		
		MOV	R0, #4DH			;CLR THE HOLD BIT
		MOV	A, #04H
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0
		POP	ACC
		
		
		
		RET
;================================================================================
;| Write to a register in the RTC							|
;================================================================================
writeReg:	
		;LCALL	checkBusy			;Wait until not busy
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
;| To write a command to the LCD THAT IS IN A					|
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
		LCALL	DELAY_1MS
		POP	ACC
		POP	0
		RET

;================================================================================
;| To clear the LCD								|
;================================================================================
CLEAR_LCD:
		PUSH	0
		push	ACC
		MOV	A,#01H
		LCALL	COMNWRT				;CLEAR THE LCD
		LCALL	DELAY_5MS
		MOV	A, #0CH				;REMOVE THE CURSOR
		LCALL	COMNWRT
		pop	ACC
		pop	0
		RET
;================================================================================
;| To print the temperature in the top right corner				|
;================================================================================
PUT_TEMP:	
		push	0
		push	ACC
		CLR	RS
		MOV	R0, io_lcd	
		MOV	A, #090H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		pop	ACC
		pop	0
		RET	
;================================================================================
;| Put the temperature in the top left of the LCD				|
;================================================================================
PUT_RTC:	
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd	
		MOV	A, #080H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		RET	
;================================================================================
;| Print the string on the first line of the LCD				|
;================================================================================
PUT_LINE1:	
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd	
		MOV	A, #080H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		RET	
;================================================================================
;| Put string on the second line of the LCD					|
;================================================================================
PUT_LINE2:	
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd	
		MOV	A, #0C0H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		RET	
;================================================================================
;| Put string on the second line of the LCD w/ cursor blinking			|
;================================================================================
PUT_LINE2_CB:	
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd	
		MOV	A, #0C0H			;DDRAM ADDRESS
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		MOV	A, #0FH				;SET CURSOR ON AND BLINKING
		LCALL	COMNWRT
		LCALL	DELAY_1MS
		SETB	RS
		POP	ACC
		POP	0
		RET	
;================================================================================
;| Put string on line 3 of the lCD						|
;================================================================================
PUT_LINE3:		
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd
		MOV	A, #94H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		
		RET	

;================================================================================
;| Put string on line 3 of the LCD w/ cursor blinking				|
;================================================================================
PUT_LINE3_CB:		
		PUSH	0
		PUSH	ACC
		CLR	RS
		MOV	R0, io_lcd
		MOV	A, #94H				;DDRAM ADDRESS
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		MOV	A, #0FH				;CURSOR BLINKING
		LCALL	COMNWRT
		LCALL	DELAY_1MS
		SETB	RS
		POP	ACC
		POP	0
		
		RET	
;================================================================================
;| Put string on line 4 of the LCD					|
;================================================================================
PUT_LINE4:		
		PUSH	0
		PUSH	ACC
		MOV	R0, io_lcd
		CLR	RS
		MOV	A, #0D4H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		MOV	A, #0CH
		LCALL	COMNWRT
		LCALL	DELAY_1MS
		SETB	RS
		POP	ACC
		POP	0
		RET	

;================================================================================
;| Put string on line 4 of the LCD w/ cursor blinking				|
;================================================================================
PUT_LINE4_CB:		
		PUSH	0
		PUSH	ACC
		MOV	R0, io_lcd
		CLR	RS
		MOV	A, #0D4H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		MOV	A, #0FH
		LCALL	COMNWRT
		LCALL	DELAY_1MS
		SETB	RS
		POP	ACC
		POP	0
		RET	

;================================================================================
;| PRINTS ADDRESS OF DUMP ON LINE 3					|
;================================================================================
PUT_ADDR:
		PUSH	0
		PUSH	ACC
		MOV	R0, io_lcd
		CLR	RS
		MOV	A, #0A1H
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		RET	

;================================================================================
;| STARTINGS PRINTING AT THE DDRAM VALUE OF A BEFORE ENTERING SUBROUTINE	|
;================================================================================
PUT_FLEX:
		PUSH	0
		PUSH	ACC
		MOV	R0, io_lcd
		CLR	RS
		LCALL	COMNWRT
		LCALL	DELAY_5MS
		SETB	RS
		POP	ACC
		POP	0
		RET	
		
;GETBYTE grabs two key presses and combines them into a single byte value
;the byte value will be returned in R1, or is available on key_out
;================================================================================
;| grabs two key presses and combines them into a single byte value, returns	|
;| in A										|
;================================================================================
GETBYTE:
		push	0
		PUSH	7
		LCALL	promptKeypad		;Get first digit of block
		LCALL	PRINTCHAR
		;mov	A, keypad		;move first digit to A
		MOV	R7, A			;SAVE VALUE
		SUBB	A, #40h
		jnc	letter
		mov	A, R7			;else, regrab the output from key
		anl 	A, #0fh			;mask to get data 
		sjmp	rotate
	letter:	mov	A, R7			;if letter regrab, data
		anl	A, #0fh			;mask off lower half
		;add	A, #09h			;add 09h to normalize
		ADD	A, #09H			;it is normalize
	rotate:	RL	A
		RL	A
		RL	A
		RL	A
		mov	R0, A
	invalid:LCALL	promptKeypad		;Get first digit of block
		LCALL	PRINTCHAR
		;mov	A, KEYPAD		;move first digit to A
		MOV	R7, A
		SUBB	A, #40h
		jnc	letter2
		mov	A, R7		;else, regrab the output from key
		anl 	A, #0fh			;mask to get data 
		sjmp	here13
	letter2:mov	A, R7		;if letter regrab, data
		anl	A, #0fh			;mask off lower half
		;add	A, #09h			;add 09h to normalize
		ADD	A, #09H
		anl	A, #0fh
	here13:	orl	A, R0			;Now both bits are in A
		mov	R1, A			;To preserve block size in R1
		POP	7
		pop	0
		RET

;================================================================================
;| Print a string to the LCD							|
;================================================================================
printString:	
		CLR	A
		movc	A, @A+DPTR
		JZ	pExit
		LCALL	printChar
		INC 	DPTR
		SJMP 	printString
pExit:		RET
;================================================================================
;| Print a byte in A to the LCD							|
;================================================================================
printByte:
		push	0E0h
		push 	1		
		MOVX	A, @DPTR
		MOV	B, A
		ANL	A, #0f0h
		rr	A
		rr	A
		rr	A
		rr	A
		mov	R7, A			;To save the raw value
		CLR	C
		SUBB	A, #0Ah			;check if letter
		jnc	letter13
		mov	A, R7			;Reload A
		orl	A, #30h			;Should have ascii number value now(03h --> 33h)
		LCALL	printChar			;put character to LCD
		sjmp	next1
letter13:	mov	A, R7
		orl	A, #30h			;ascii non-normalized
		add	A, #07h			;ascii normalized (3Fh --> 46h)
		LCALL	printChar
next1:		mov	A, B
		anl	A, #0fh
		mov	R7, A			;to copy before check
		CLR	C
		subb	A, #0Ah
		jnc	letter14
		mov	A, R7
		orl	A, #30h
		LCALL	printChar
		sjmp	finish1
letter14:	mov	A, R7
		orl	A, #30h
		add	A, #07h
		LCALL	printChar			;print the normalized second character
finish1:	mov	A, #20h
		pop	1
		pop	0E0h
		
		RET
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
		LCALL	delay_1MS
		CLR	P3.0
		pop	0
		RET
;================================================================================
;| A delay for .5s							 	|
;================================================================================
halfSecondDelay:
		LCALL	delay_100ms
		LCALL	delay_100ms
		LCALL	delay_100ms
		LCALL	delay_100ms
		LCALL	delay_100ms
		RET
;================================================================================
;| Procedure that sends A to data bus and whats in DPTR to the address bus 	|
;================================================================================
ioToggle:
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0
		RET
;================================================================================
;| clear hold bit on rtc							|
;================================================================================
setHold:
		PUSH	0
		PUSH	ACC
		
		MOV	R0, #4DH			;SET THE HOLD BIT
		MOV	A, #05H
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0

		POP	ACC
		POP	0
		RET
;================================================================================
;| clear hold bit on rtc							|
;================================================================================
clearHold:
		PUSH	0
		PUSH	ACC
		
		MOV	R0, #4DH			;CLR THE HOLD BIT
		MOV	A, #04H
		SETB	P3.0
		MOVX	@R0, A
		CLR	P3.0

		POP	ACC
		POP	0
		RET
;================================================================================
;| Iterative 100ms delay using delay_1ms					|
;================================================================================
DELAY_100ms:							
	
		PUSH	3
		MOV	R3,#97
	HERE7:	LCALL	DELAY_1ms
		DJNZ	R3,HERE7
		POP	3
		RET
;================================================================================
;| Iterative 50ms delay using delay_1ms						|
;================================================================================
DELAY_50ms:							
	
		PUSH	3
		MOV	R3,#50
	HERE8:	LCALL	DELAY_1ms
		DJNZ	R3,HERE2
		POP	3
		RET
;================================================================================
;| Iterative 10ms delay using delay_1ms						|
;================================================================================
DELAY_10ms:							
	
		PUSH	3
		MOV	R3,#10
	HERE2:	LCALL	DELAY_1ms
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
	HERE3:	LCALL	DELAY_1MS
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
;login strings
loginMSG:	db	' Press [1] to Login \0'
goodbye:	db	'     Logged Out     \0'
LOGINART1:	DB	'O------------------O\0'
osName:		db	'|   Goberling OS   |\0'
LOGINART2:	DB	'O------------------O\0'
DIGITMSG:	DB	'4 Digits (xxxxh)\0'
DIGITMSG1:	DB	'2 Digits (xxh)\0'

;program strings
bBlock:		db	'Enter Block Size\0'
bSource:	db	'Enter Source Addr.\0'
bDest:		db	'Enter Dest. Addr.\0'
bdone:		db	'Move Complete.\0'
eSource:	db	'Enter Source Addr.\0'
fBlock:		db	'Enter Block Size\0'
replace:	db	'Enter Desired value\0'
exitmsg:	db	'Program Exited\0'
user1:		db	'[0]Next Addr \0'
user2:		db	'[1]Exit \0''
FindByte:	db	'Enter value to Find\0'
FoundByte:	db	'Found value @ \0'
nFound:		db	'Byte Not Found\0'
memend:		db	'End of Memory (FFh)\0'
exitmsg2:	db	'[2] Exit\0'
DUMPPROMPT:	DB	'[0] Next \0'
DUMPPROMPT2:	DB	'[1] Prev.   [2] Exit\0'

;password strings
myPasscode:	db	'Enter 4-Digit PIN: \0'
VERIFYINPUT:	DB	'[A] Submit  [D] Redo\0'
incorrectCode:	db	'Incorrect Passcode\0'
tryAgain:	db	'Please Try Again\0'
pwSuccess:	db	'Welcome Back\0'
lockedMsg:	db	'System Locked.\0'
attempts:	db	'Tries Left: \0'

;name strings
michael:	db	'Michael!\0'
collin:		db	'Collin!\0'
riley:		db	'Riley!\0'
sharif:		db	'Prof. Sharif!\0'
jeff:		db	'Jeff!\0'

;menu strings
myName:		db	'Michael Goberling\0'
myClass:	db	'CEEN 4330 \0'
menu1:		db	'[B] Move    [D] Dump\0'
menu2:		db	'[E] Edit    [F] Find\0'
logout:		db	'[1] Logout  [7] 7Seg\0'
runtimeMenu:	db	'[Runtime] \0'
tempMenu:	db 	'[Temp] \0'

;test strings
test1:		db	'Move Selected.\0'
test2:		db	'Dump Selected.\0'
test3:		db	'Edit Selected.\0'
test4:		db	'Find Selected.\0'
sevensegmsg:	db	'7Seg Selected.\0'

;Profiles:
;	Michael	0
;	Collin	1	  
;	Riley	2
;	Sharif	3
;	Jeff	4

;profiles      ;0	 ;1	   ;2	     ;3        ;4
pwList:	db	97h, 01h, 34H, 25H, 11H, 11H, 43H, 30H, 60H, 73H, 0	
;compare valid passwords 2 bytes at a time

;matrix keypad LUT
KCODE0:	db	'1', '2', '3', 'A'
KCODE1:	db	'4', '5', '6', 'B'
KCODE2:	db	'7', '8', '9', 'C'
KCODE3:	db	'F', '0', 'E', 'D'
		END