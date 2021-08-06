;-------------------------------------------------------------------------------
; EE322 Embedded Systems Design
; Year 3 Semester 1
; Group Project
; Title: Coin Sorter and Calculator
; 
; Group G1
;    E/17/146: Jayawickrama, J.P.D.D.M.
;    E/17/234: Pandukabhaya, V.K.M.
;    E/17/371: Warnakulasuriya, R.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Header
#include "p16f84a.inc"                  ; Include file
        list        p = 16f84a          ; Microcontroller model
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Constants

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Define origin and interrupt vectors
        org         0x000               ; Origin
        goto        INIT
        
        org         0x04                ; Interrupt vector
        goto        COIN_INSERT
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Routine "INIT"
;       Executed once

INIT:
; Set Interrupt Settings
        bsf         INTCON, INTE        ; Enable the RB0/INT interrupt
        
        bsf         INTCON, GIE         ; Enable all un-masked (global)
                                        ; interrupts
                                    
        bcf         INTCON, INTF        ; Clear the RB0/INT flag
        
        bsf         OPTION_REG, INTEDG  ; Interrupt on rising edge of
                                        ; RB0/INT pin

; Set PORTA as output, and PORTB as input (all pins)
        bsf         STATUS, 5           ; Bank 1 select
        movlw       b'11111111'
        movwf       TRISB
        movlw       b'00000'
        movwf       TRISA
        bcf         STATUS, 5           ; Bank 0 select

; Initialize PORTA and PORTB
        movlw       b'00000000'
        movwf       PORTB
        movlw       b'00000'
        movwf       PORTA
        
;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
; Routine "MAIN"
MAIN:
        ; Do something here
        
        goto        MAIN                ; Go to the MAIN routine again (loop)

;-------------------------------------------------------------------------------
; ISR "COIN_INSERT"
COIN_INSERT:
        ; Do something when a coin is inserted
        retfie                          ; Return from interrupt

;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
        goto    $
        end
;-------------------------------------------------------------------------------
