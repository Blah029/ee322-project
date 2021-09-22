;------------------------------------------------------
; Transferred to mainCode.asm with some modifications.
; Code in this file has not been modified.
;------------------------------------------------------

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
	;call servo3
	;call servo2Pos1
	;call servo1Pos2
	call calibrate
	goto main
    
main									; main code
	;-----------------------------------
	
	;-----------------------------------
	goto main
    	
delay									; = 22 + (count1-1)*3 + (count2-1)*770 + (count3-1)*197140 ns
	decfsz		count1
	goto delay
	
	decfsz		count2
	goto delay
	
	decfsz		count3
	goto delay
	
  	return
	
motorPlus90_on
    movlw       d'148'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'3'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
        
motorPlus90_off
	movlw       d'1'                ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'3'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return

motor0_on
    movlw       d'237'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
        
motor0_off
	movlw       d'160'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
        
motorMinus30_on
    movlw       d'181'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
        
motorMinus30_off
	movlw       d'217'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return

motorPlus30_on
    movlw       d'36'               ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'3'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
        
motorPlus30_off
	movlw       d'105'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        delay               ; keep the set-up delay
        
    return
	
calibrate
	movlw		b'00000111'			; turn on port A
	movwf		PORTA				;
	call motorPlus30_on
	movlw		b'00000000'			; turn off port A
	movwf		PORTA				;
	call motorPlus30_off
	
	return
end