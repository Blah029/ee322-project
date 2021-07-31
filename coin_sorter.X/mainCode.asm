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
#include "p16f84a.inc"      ; Include file
        list    p = 16f84a  ; Microcontroller model
        org     0x000       ; Origin
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Constants

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Routine "main"
main
        bsf     STATUS,5    ; Select Bank 1
        movlw   b'00000000' ; Move literal to W
        movwf   TRISB       ; W -> TRISB (port B as output)
        bcf     STATUS, 5   ; Select Bank 0
        
        movlw   b'11111111' ; -> to W
        movwf   PORTB       ; W -> PORTB (port B as high)
        
        goto    $
        end
;-------------------------------------------------------------------------------
