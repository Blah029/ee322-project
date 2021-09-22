processor		16F84A					; turn on listing output
#include		<p16f84a.inc>		    ; include file for register names

resVect			code	    0x00	    ; upcode
    goto		init
    
intVect			code	    0x04	    ; interrupt service routine
    ; insert code
    retfie

; declare global variables
refByte2		equ         0x0c
refByte1		equ         0x0d
refByte0		equ         0x0e
inByte2			equ         0x0f
inByte1			equ         0x10
inByte0			equ         0x11
xorResult		equ			0x12
flags			equ			0x13		; bit 0 xorResult flag: 0 if in range, else 1

init									; initialisation
    ; insert code
	movlw		b'11001000'				; set first reference byte
	movwf		refByte2				;
	movlw		b'10101111'				; set second reference byte
	movwf		refByte1				;
	movlw		b'10010110'				; set last reference byte
	movwf		refByte0				;
	movlw		b'11001000'				; emulate first input byte
	movwf		inByte2					;
	movlw		d'0'					; clear all flags
	movwf		flags					;
    goto main
    
main									; main code
    ; insert code
	call checkTolerance
	goto main
	
checkTolerance
	bsf			STATUS,		RP0			; access bank 0
	bcf			flags,		0			; clear xorResult flag
	movfw		inByte2					; copy first input byte to WREG
	xorwf		refByte2,	0			; perform xor with first reference byte
	andlw		b'11111000'				; keep first 5 bits
	movwf		xorResult				;
	incf		xorResult				; check if zero
	decfsz		xorResult				;
		bsf		flags,		0			; set xorReslut flag
	return
    
end
