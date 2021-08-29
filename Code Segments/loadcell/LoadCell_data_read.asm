;-------------------------------------------------------------------------------
; Author  : E/ 17 /146
; Version : 1.0
; Description : iterrupt is triggered when the coin weight has been detected 
;		after a coin has been entered. This will happen after 400ms 
;		after a coin has been entered to the machine. 
; Registers used : 0x14 , 0x15 , 0x16 , 0x17
;-------------------------------------------------------------------------------
    
    list p = 16f84a 
    #include <p16f84a.inc>
    
    org 0x00
    
    goto main				; goto the main program
     
    ; select 3 general purpose registers in order to move those 24 bits coming from the HX 711
    
    ; interrupts are taken from the RB0/INT pin 
    
;***********************INTERRUPT ROUTINE***************************************
    
    org  0x04				; interrupt routine 
    
    movf 0x14 ;				; move the working register values to a temporary register 0x14 this is to start the main program from where left-off
					;->in this case the idle_state
    
    bcf INTCON,GIE			; disable the GIE to make the RB0 pin an input 
    
loop
    
    decfsz 0x15 ,1 
    
    goto clock_pulses 
    
    ;take in the 24 bits from the ADC 
    ;send one clock pulse then recive one data bit , like wise do that 24 times 
    
    bsf INTCON,GIE  ; again make the GIE enable to make RB0 an interrupt pin 
    
    
;--------------------------------------------------------------------------------------------------------------------------------------
clock_pulses 
    
    bsf PORTA,RA0			;Data line output is ready to give out 
    bcf PORTA,RA0			;Data line gives its data at the falling edge
    
    rlf PORTB ,1			;Bits from the ADC are moved to the left as coming from the serial data line
    rlf 0x16 ,1				;when the 8 bits are full in the PORTB then goes to the C flag => 0x16 register bit 0 and so on 
    rlf 0x17 ,1				;With this register all 24 bits have received  
    
    goto loop
    
;-------------------------------------------------------------------------------------------------------------------------------------
    
main 
   
    bsf  INTCON , GIE			; Global Interrupt Enable bit set to one
    
    bcf  OPTION_REG , INTEDG		; make the interrupts triggered at the falling edge-> this is to check the ADC is ready to transmit the data
    
    bsf  INTCON, INTE			; External interrupt has been enabled to RB0 pin
    
    bcf  INTCON , INTF			; clearing the interrup flag just in case it had been set in some operation
    
    bsf STATUS , RP0			; select the bank 1 to access TRISB 
    
    movlw b'11111101'
    movwf TRISB				; make the RB0 pin an input and RB1  pin output 
					; RB0 => Serial Data line
					; RB1 => Serial Clock line
					
    movlw b'11111110'			; make the RA0 pin an output => this is for the clock pulses
    movwf TRISA 
    
    movlw b'11111110'
    movwf PORTA				; make the RA0 pin Low to turn the ADC on
					;( Serial Clock pin should be down for the device turn-on )
    movlw b'00000001'
    movwf PORTB				;and RB0 pin high for the interrupt trigger ditection 
					
    bcf STATUS , RP0			; move back to the bank 0
    
    movlw 0x19				; move 25 to the working register->for the 25 pulse counting
    movwf 0x15				; mov the 25 to the register 0x15
    
    movlw 0x00
    movwf 0x16
    
    movlw 0x00
    movwf 0x17
    
    
    
    ;Each time the there is no coin input the machine is in the idle state which in this case is 
    ; the motoring operations. Then an interrupt is triggered that will stop the idle state immediately and 
    ;come to the interrupt routine 
    
    
idle_state
    
    NOP; what happens in the idle state=> in order to save power on operation is carried out 
					; Since this power consumption in operational mode and NOP is different
    goto idle_state 

    end 
    
    