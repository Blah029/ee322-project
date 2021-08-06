<<<<<<< Updated upstream
=======
;-------------------------------------------------------------------------------
>>>>>>> Stashed changes
; EE322 Embedded Systems Design
; Year 3 Semester 1
; Group Project
; Title: Coin Sorter and Calculator
; 
; Group G1
<<<<<<< Updated upstream
;     E/17/146: Jayawickrama J.P.D.D.M
;     E/17/234: Pandukabhaya V.K.M
;     E/17/371: Warnakulasuriya R

=======
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
        bsf     STATUS,5
        movlw   b'00000000'
        movwf   TRISB
        bcf     STATUS, 5

        goto    $
        end
;-------------------------------------------------------------------------------
>>>>>>> Stashed changes
