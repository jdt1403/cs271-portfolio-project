TITLE String Primitives & Macros     (Proj6_toussaij.asm)

; Author: Jonathan Toussaint
; Last Modified: 12/05/2021
; OSU email address: toussaij@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:   6              Due Date: 12/05/2021
; Description: Implements and tests two macros for string processing (mGetString 
;	and mDisplayString) as well as two procedures for signed integers which use
;	string primitive instructions (ReadVal and WriteVal).

INCLUDE Irvine32.inc


; -- mGetString -- 
; prompts user to enter a string, and stores inputted string in memory variable
; receives: address of prompt, output variable, and bytes read
; returns: number of characters inputted in bytesRead
mGetString MACRO prompt,outVar,bytesRead
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX

	MOV		EDX, prompt
	CALL	WriteString			; display prompt

	MOV		EDX, outVar			; input buffer address in EDX
	MOV		ECX, MAX_SIZE		; buffer size in ECX
	CALL	ReadString			; user string in EDX
	MOV		bytesRead, EAX		; number of characters in bytesRead

	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
ENDM


; -- mDisplayString --
; prints the string at the given address
; receives: address = array address
mDisplayString MACRO address
	PUSH	EDX
	MOV		EDX, address
	CALL	WriteString
	POP		EDX
ENDM


NUM_INTS = 10
MAX_SIZE = 12

.data

progTitle		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",13,10,0
author			BYTE	"Written by: Jonathan Toussaint",13,10,0
instructions1	BYTE	"Please provide 10 signed decimal integers.",13,10,0
instructions3	BYTE	"Each number needs to be small enough to fit inside a 32 bit register. ",13,10,0
instructions4	BYTE	"After you have finished inputting the raw numbers I will display a list of ",13,10,0
instructions5	BYTE	"the integers, their sum, and their average value.",13,10,0
farewellMsg		BYTE	"Thanks for playing!",13,10,0
numPrompt		BYTE	"Please enter a signed number: ",0
inputErrMsg		BYTE	"ERROR: You did not enter a signed number or your number was too big.",13,10,0
userString		BYTE	MAX_SIZE DUP(0)
userBytesRead	DWORD	?
numsCollected	DWORD	0
convertedNum	SDWORD	?
isNeg			DWORD	0
numsArray		SDWORD	10	DUP(?)
numToPrint		BYTE	MAX_SIZE DUP(0)
charsCount		DWORD	?
displayNumsMsg	BYTE	"You entered the following numbers:",13,10,0
numDelimiter	BYTE	", ",0
displaySumMsg	BYTE	"The sum of these numbers is: ",0
displayAvgMsg	BYTE	"The rounded average is: ",0
clearArray		BYTE	MAX_SIZE DUP(0)
sum				SDWORD	?
average			SDWORD	?

.code
main PROC
	
; introduce program and instructions
	PUSH	OFFSET	progTitle
	PUSH	OFFSET	author
	PUSH	OFFSET	instructions1
	PUSH	OFFSET	instructions3
	PUSH	OFFSET	instructions4
	PUSH	OFFSET	instructions5
	CALL	introduction

; get 10 valid integers from user and store in an array
	MOV		EDI, OFFSET	numsArray
_getNum:
	PUSH	EDI
	PUSH	OFFSET	isNeg
	PUSH	OFFSET	convertedNum
	PUSH	OFFSET	numsCollected		; readVal will increment numsCollected if num is valid
	PUSH	OFFSET	numPrompt
	PUSH	OFFSET	userString
	PUSH	OFFSET	userBytesRead
	PUSH	OFFSET	inputErrMsg
	CALL	readVal
	CMP		numsCollected, NUM_INTS
	JL		_getNum
	CALL	CrLf

; display the integers
	mDisplayString	OFFSET	displayNumsMsg
	PUSH	ECX
	MOV		ECX, NUM_INTS-1
	MOV		ESI, OFFSET numsArray
_printLoop:
	PUSH	OFFSET	clearArray
	PUSH	OFFSET	charsCount
	PUSH	OFFSET	isNeg
	PUSH	OFFSET	numToPrint
	PUSH	ESI
	CALL	writeVal
	mDisplayString	OFFSET	numDelimiter
	ADD		ESI, 4
	LOOP	_printLoop
_printLastNum:
	MOV		ESI, OFFSET	numsArray
	ADD		ESI, SIZEOF numsArray
	SUB		ESI, 4						; point to last element
	PUSH	OFFSET	clearArray
	PUSH	OFFSET	charsCount
	PUSH	OFFSET	isNeg
	PUSH	OFFSET	numToPrint
	PUSH	ESI
	CALL	writeVal
	CALL	CrLf
	CALL	CrLf
	POP		ECX

; display the sum of the integers
	PUSH	OFFSET	sum
	PUSH	OFFSET	clearArray
	PUSH	OFFSET	charsCount
	PUSH	OFFSET	isNeg
	PUSH	OFFSET	numToPrint
	PUSH	OFFSET	displaySumMsg
	PUSH	OFFSET	numsArray
	CALL	displaySum
	CALL	CrLf

; display the average of the integers (w/ floor rounding)
	PUSH	OFFSET	clearArray
	PUSH	OFFSET	charsCount
	PUSH	OFFSET	isNeg
	PUSH	OFFSET	numToPrint
	PUSH	OFFSET	average
	PUSH	sum
	PUSH	OFFSET	displayAvgMsg
	CALL	displayAvg
	CALL	CrLf

; display closing message
	PUSH	OFFSET	farewellMsg
	CALL	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP


; -- introduction --
; displays the program title, author, and instructions
; receives: string offsets on the stack
introduction PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX					; preserve registers
	PUSH	EDX

	mDisplayString	[EBP+28]	; display title and author
	mDisplayString	[EBP+24]
	CALL	CrLf				; display instructions
	mDisplayString	[EBP+20]
	mDisplayString	[EBP+16]
	mDisplayString	[EBP+12]
	mDisplayString	[EBP+8]
	CALL	CrLf

	POP		EDX					; restore registers
	POP		EAX
	POP		EBP
	RET		24
introduction ENDP


; -- readVal --
; reads a user input string using mGetString macro, validates number and converts to sdword
; receives: offsets of isNeg, convertedNum, numsCollected, numPrompt, userString, 
;	userBytesRead, and inputErrMsg all passed on the stack
; returns: sdword in memory variable, increments numsCollected if num is valid
; registers changed: EDI (adds 4 if num is valid)
readVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ESI
	PUSH	EAX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDX
; get user input
	mGetString [EBP+20],[EBP+16],[EBP+12]

; convert ascii to numeric sdword and validate is a valid number
	MOV		ESI, [EBP+16]
	MOV		EBX, 0					; EBX holds num int (to be set to integer value of string)
	CLD								; move forward through the string

; check if first character is '-'
	MOV		EAX, 0
	MOV		AL, BYTE PTR [ESI]
	CMP		EAX, 45					; compare ascii value with '-'
	JE		_setNegFlag
; check if first character is '+'
	CMP		EAX, 43
	JE		_positiveSignGiven
	JMP		_clearNegFlag

_setNegFlag:
	ADD		ESI, 1
	MOV		DWORD PTR [EBP+28], 1
	JMP		_convertCharToDigit
_positiveSignGiven:
	ADD		ESI, 1
_clearNegFlag:
	MOV		DWORD PTR [EBP+28], 0

_convertCharToDigit:
	MOV		EAX, 0					; clear out EAX
; read char as ascii number
	LODSB	[ESI]					; move ascii char byte into AL, adds 1 to ESI
; verify ascii <= 57d
	CMP		AL, 57
	JG		_notNumber
; verify ascii >= 48d
	CMP		AL, 48
	JL		_notNumber
_validNumber:
; convert ascii string to sdword
	SUB		AL, 48
	PUSH	EAX
	MOV		EAX, EBX
	MOV		ECX, 10
	MUL		ECX
	MOV		EBX, EAX
	POP		EAX
	ADD		EBX, EAX				; numInt = 10*numInt + AL
	CMP		BYTE PTR [ESI],0	; check if there is another inputted character
	JNE		_convertCharToDigit
; check our isNeg flag
	PUSH	EAX
	MOV		EAX, [EBP+28]
	CMP		EAX,0
	JNE		_negateVal
_handledNegation:
	POP		EAX
; check for overflow
	MOV		EDX, [EBP+16]
	MOV		ECX, [EBP+12]
	CALL	ParseInteger32
	JO		_notNumber
	
; move sdword into nums array
	MOV		[EBP+28], SDWORD PTR EBX			; store value in memory variable
	MOV		[EDI], SDWORD PTR EBX
; increment numsCollected
	MOV		EBX, [EBP+24]
	INC		DWORD PTR [EBX]
; move EDI to next array element address
	ADD		EDI, 4
	JMP	_done
_notNumber:
	mDisplayString	[EBP+8]
_done:
	POP		EDX
	POP		ECX
	POP		EBX
	POP		EAX
	POP		ESI
	POP		EBP
	RET		28

_negateVal:
	NEG		EBX
	JMP		_handledNegation
readVal ENDP


; -- writeVal --
; converts the SDWORD value pointed to by the last-pushed stack variable to an ascii string and prints it to the screen
; receives: offsets of clearArray, charsCount, isNeg, numToPrint, and sdword to print all on the stack
writeVal PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	ESI
	PUSH	EDI
	PUSH	EAX
	PUSH	EDX
	PUSH	EBX
	PUSH	ECX
	MOV		[EBP+20], DWORD PTR 0		; initialize charsCount to 0
; convert numeric sdword value to a string of ascii digits
	MOV		ESI, SDWORD PTR [EBP+8]
; point to the last byte of the destination array
	MOV		EDI, [EBP+12]				
	ADD		EDI, MAX_SIZE - 1
	STD									; set direction flag to traverse byte array backwards
	MOV		AL, 0						; set terminating byte
	STOSB

	CMP		SDWORD PTR [ESI], 0			; check if negative
	JS		_neg
_notNeg:	
	MOV		[EBP+16], DWORD PTR 0
	PUSH	[ESI]
	JMP		_setUpLoop
_neg:
	MOV		[EBP+16], DWORD PTR 1		; set isNeg to 1 if value is negative
	PUSH	[ESI]
	NEG		DWORD PTR [ESI]
_setUpLoop:
	MOV		EAX, [ESI]					; set up division
	
_loop:
	MOV		EDX, 0
	MOV		EBX, 10
	DIV		EBX
	PUSH	EAX
	MOV		EAX, EDX					
	ADD		EAX, 48						; convert remainder to ascii
	STOSB								; store remainder (digit) in current byte
	POP		EAX							; EAX holds new quotient for next iteration
	INC		DWORD PTR [EBP+20]			; increment charsCount
	CMP		EAX, 0
	JNE		_loop
_loopDone:
	CMP		[EBP+16], DWORD PTR 1		; check our isNeg flag
	JE		_prependNegSign

; display ascii string
_printCharString:
	MOV		EDI, [EBP+12]				
	ADD		EDI, MAX_SIZE - 1
	SUB		EDI, [EBP+20]				; point to start of ascii string
	mDisplayString	EDI
; clear numToPrint array
	MOV		ESI, [EBP+24]				; empty array in ESI
	MOV		EDI, [EBP+12]
	MOV		ECX, MAX_SIZE
	REP		MOVSB						; copy empty array into numToPrint array
; restore raw array value
	MOV		ESI, SDWORD PTR [EBP+8]
	POP		[ESI]

	POP		ECX
	POP		EBX
	POP		EDX
	POP		EAX
	POP		EDI
	POP		ESI
	POP		EBP
	RET		20
_prependNegSign:
	MOV		EAX, 45						; add ascii '-' as first byte of string
	STOSB
	INC		DWORD PTR [EBP+20]			; increment charCount
	JMP		_printCharString
writeVal ENDP


; -- displaySum --
; calculates and displays the sum of the elements of the specified sdword array
; receives: address of array, intro text string, and address of sum (and all prerequisites of writeVal) on the stack
; returns: summed value in memory variable sum
displaySum PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX				; preserve registers
	PUSH	EBX
	PUSH	ECX				
	PUSH	ESI
	PUSH	EDI

	mDisplayString	[EBP+12]	; display intro text

	MOV		ECX, NUM_INTS	; array length in ECX
	MOV		ESI, [EBP+8]	; offset of nums array in EAX
	MOV		EAX, 0			; hold running sum in EAX
	MOV		EDI, [EBP+32]	; address of sum var in EDI
_sumLoop:
	ADD		EAX, [ESI]		; add current element to sum
	ADD		ESI, 4			; move pointer to next element
	LOOP	_sumLoop
	MOV		[EDI], EAX
	PUSH	[EBP+28]
	PUSH	[EBP+24]
	PUSH	[EBP+20]
	PUSH	[EBP+16]
	MOV		ESI, [EBP+32]
	PUSH	ESI
	CALL	writeVal		; display sum using writeVal
	CALL	CrLf

	POP		EDI
	POP		ESI				; restore registers
	POP		ECX				
	POP		EBX
	POP		EAX
	POP		EBP
	RET		28
displaySum ENDP


; -- displayAvg --
; calculates and displays the (floor-rounded) average of the values in the specified sdword array
; receives: sum, address of average and intro message (and all prerequisites of writeVal) on the stack
; returns: average value in memory variable average
displayAvg PROC
	PUSH	EBP
	MOV		EBP, ESP
	PUSH	EAX
	PUSH	EDX
	PUSH	EDI
	PUSH	EBX

	MOV		EDI, [EBP+16]		; move output var average address into EDI
	mDisplayString	[EBP+8]		; print intro text

	MOV		EAX, [EBP+12]		; sum in EAX
	CDQ							; prep for division
	MOV		EBX, NUM_INTS
	IDIV	EBX
	MOV		[EDI], EAX			; move rounded average into memory variable

	PUSH	[EBP+32]
	PUSH	[EBP+28]
	PUSH	[EBP+24]
	PUSH	[EBP+20]
	PUSH	EDI
	CALL	writeVal			; print average

	POP		EBX
	POP		EDI
	POP		EDX
	POP		EAX
	POP		EBP
	RET		28
displayAvg ENDP


; -- farewell --
; displays a closing message to the user
; receives: address of string on the stack
farewell PROC
	PUSH	EBP
	MOV		EBP, ESP
	CALL	CrLf
	mDisplayString	[EBP+8]
	CALL	CrLf
	POP		EBP
	RET		4
farewell ENDP

END main
