processor		16F84A					; turn on listing output
#include		<p16f84a.inc>		    ; include file for register names

resVect			code	    0x00	    ; upcode
    goto init
    
intVect			code	    0x04	    ; interrupt service routine
    retfie
	
count1			equ			0x0c		; used in a decfsz
count2			equ			0x0d		; used in a decfsz
count3			equ			0x0e		; used in a decfsz
    
init									; initialisation
	bsf			STATUS,		RP0			; access bank 1
	movlw		b'00000000'				; set port A as output
	movwf		TRISA					; 
	bcf			STATUS,		RP0			; access bank 0
	movlw		b'00000000'				; initialize port A with all pins off
	movwf		PORTA					; 
	call servo3
	call servo2Pos1
	call servo1Pos2
	goto main
    
main									; main code
	;-----------------------------------
	call		testAll
	;-----------------------------------
	goto main
    
servo3									; open and close gate
	movlw		b'00000100'				; turn on RA2
	movwf		PORTA					; 
	movlw		d'149'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'3'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 90deg on time
	movlw		b'00000000'				; turn off RA2
	movwf		PORTA
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	movlw		b'00000100'				; turn on RA2
	movwf		PORTA					; 
	movlw		d'238'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'2'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg on time
	movlw		b'00000000'				; turn off RA2
	movwf		PORTA					; 
	movlw		d'161'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg off time
	return
	
servo2Pos1								; rotate platform to 0 degree position
	movlw		b'00000010'				; turn on RA1
	movwf		PORTA					; 
	movlw		d'238'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'2'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg on time
	movlw		b'00000000'				; turn off RA1
	movwf		PORTA					; 
	movlw		d'161'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg off time
	return
	
servo2Pos2								; rotate platform to 90 degree position
	movlw		b'00000010'				; turn on RA1
	movwf		PORTA					; 
	movlw		d'149'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'3'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 90deg on time
	movlw		b'00000000'				; turn off RA1
	movwf		PORTA					; 
	return
	
servo1Pos1								; tip platform to -30 degree position
	movlw		b'00000001'				; turn on RA0
	movwf		PORTA					; 
	movlw		d'183'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'2'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; -30deg on time
	movlw		b'00000000'				; turn off RA0
	movwf		PORTA					; 
	movlw		d'217'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; -30deg off time				; 
	return
	
servo1Pos2								; tip platform to 0 degree position
	movlw		b'00000001'				; turn on RA0
	movwf		PORTA					; 
	movlw		d'238'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'2'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg on time
	movlw		b'00000000'				; turn off RA0
	movwf		PORTA					; 
	movlw		d'161'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 0deg off time
	return
	
servo1Pos3								; tip platform to +30 degree position
	movlw		b'00000001'				; turn on RA0
	movwf		PORTA					; 
	movlw		d'37'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'3'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 30deg on time
	movlw		b'00000000'				; turn off RA0
	movwf		PORTA					; 
	movlw		d'106'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; 30deg off time
	return
	
delay									; = 18 + (count1-1)*3 + (count2-1)*770 + (count3-1)*197140 ns
	decfsz		count1
	goto delay
	
	decfsz		count2
	goto delay
	
	decfsz		count3
	goto delay
	
  	return
	
testPWM
	movlw		b'00000001'				; turn on RA0
	movwf		PORTA					; 
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'1'					; set layer 3 delay counter
	movwf		count3					; 
	call delay
	movlw		b'00000000'				; turn off RA0
	movwf		PORTA					;
	return
	
testAll
	call servo3
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	call servo2Pos2
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	call servo2Pos1
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	call servo1Pos1
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	call servo1Pos3
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'3'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	call servo1Pos2
	movlw		d'1'					; set layer 1 delay counter
	movwf		count1					; 
	movlw		d'1'					; set layer 2 delay counter
	movwf		count2					; 
	movlw		d'6'					; set layer 3 delay counter
	movwf		count3					; 
	call delay							; wait time
	
end