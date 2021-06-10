E EQU P3.2
RS EQU P3.3

	MOV TMOD, #51H ;Set timer 0 to timer mode and timer 1 to counter mode
	MOV 43H, #30H ;Store Charactor '0' at address 0x43H
	MOV 44H, #30H ;Store Charactor '0' at address 0x44H
START:
	;SETB TR1 ;Start timer 1
	ACALL MOTOR_START ;Start Motor
	ACALL DELAY10	;10ms Delay
	;CLR TR1	;After 10ms, stop timer 1
	ACALL HEXtoDEC ;Convert the value in timer 1 to decimal
	ACALL LCD_INIT ;Initialize LCD
	ACALL PRINT ;Print RPS at LCD
	MOV TL1, #00H ;Clear timer 1 for the next cycle
	MOV TH1, #00H ;Clear timer 1 for the next cycle
HERE:
	SJMP START
;-----Hex to Decimal-----
HEXtoDEC:
	MOV A, TL1
	MOV R1, #42H ;R1 indicates the address of where the conversion result is saved
	MOV R2, #03H ;Because the result in decimal has 3 digits, we do the division process 3 times
DIVISION:
	MOV B, #10 ;Copy 10 into register B
	DIV AB ;Divide A by 10
	MOV @R1, B ;Copy the result into the address indicated by R1
	DEC R1 ;Move R1 to the next address
	DJNZ R2, DIVISION ;Repeat until all 3 digits have been converted
	MOV R2, TH1
	CJNE R2, #0, UPPER_BYTE ;Check if TH1 is not 0
	LJMP ENDD_CONVERSION
UPPER_BYTE: ;For each 1 cycle, add 256 to the current result
	MOV R1, #42H
	;Add 6 to the current digit
	MOV A, #6
	ADD A, @R1
	MOV B, #10
	DIV AB
	MOV @R1, B ;The remainder is the new number at the lowest order digit
	DEC R1
	ADD A, #5 ;Add 5 to the quotient
	ADD A, @R1 ;Add the previous result to the middle digit
	MOV B, #10
	DIV AB
	MOV @R1, B ;The remainder is the new number at the middle digit
	DEC R1
	ADD A, #2 ;Add 2 to the quotient
	ADD A, @R1 ;Add the previous result to the highest order digit
	MOV B, #10
	DIV AB
	MOV @R1, B ;The remainder is the new number at the highest order digit
	DJNZ R2, UPPER_BYTE ;Repeat until the upper byte becomes 0
ENDD_CONVERSION:
	MOV R2, #03H
	MOV R1, #42H
LOOP: ;Add 30H to each digit to get the ASCII character
	MOV A, @R1
	ADD A, #30H
	MOV @R1, A
	DEC R1
	DJNZ R2, LOOP
	RET
;-----Motor Functions-----
MOTOR_START: ;Start the motor in forward direction, which corresponds to P3.1 = 0  and P3.0 = 1
	CLR P3.1
	SETB P3.0
	RET
MOTOR_STOP: ;Stop the motor by setting both P3.0 and P3.1 to 0
	CLR P3.1
	CLR P3.0
	RET
;-----LCD Functions-----
LCD_INIT:
	MOV A, #38H ;Set interface data length to 8 bits, 2 line, 5x7 characters
	ACALL CMD
	MOV A, #06H ;Set to increment without shift
	ACALL CMD
	MOV A, #0FH ;display on, cursor on and blink on
	ACALL CMD
	MOV A, #80H ;Force cursor to beginning of line 1
	ACALL CMD
	RET

;-----Print----- 
PRINT:
	MOV R0, #40H
	MOV R3, #05H ;There will be a total of 5 digits
	SETB RS
OUTPUT:
	MOV P1, @R0	;Move the content at @R0 to P1
	ACALL PULSE ;Output it to the LCD
	INC R0	;Move R0 to the next address
	DJNZ R3, OUTPUT ;Repeat until all 5 digits have been displayed
	RET
;-----CMD----- Send LCD command
CMD:
	CLR RS
	MOV P1, A
	ACALL PULSE
	RET
;-----Pulse-----
PULSE:
	SETB E
	ACALL DELAY
	CLR E
;-----Delays-----
DELAY:	;LCD delay
	MOV R7, #50
	DJNZ R7, $
	RET

DELAY10:	;10ms delay corresponds to THTL=D8F0H
	;65536-10000=55536, 55536=D8F0H
	MOV TH0, #0D8H
	MOV TL0, #0F0H
	SETB TR0
	SETB TR1
	JNB TF0, $
	CLR TR1
	CLR TR0
	CLR TF0
	RET
	
