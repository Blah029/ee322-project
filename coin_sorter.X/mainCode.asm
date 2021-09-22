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
#include <p16f84a.inc>                  ; Include file for register names
        list        p = 16f84a          ; Microcontroller model
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Pin Designations
; * RA0: Servo Motor 1 (COIN_GATE)
; * RA1: Servo Motor 2 (ROTATE)
; * RA2: Servo Motor 3 (TILT)
; * RB0: Connected to DOUT (Data line Out) of HX711 module
; * RA3: Connected to  SCK  (Serial Clock) of HX711 module
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; GPRs
; Counter variables for delays (all delays)
count1  equ         0x0c		; used in a decfsz
count2  equ         0x0d		; used in a decfsz
count3  equ         0x0e		; used in a decfsz

; A variable to store the bit index currently being read from the ADC
; of HX711
BitIdx  equ         0x0f                

; Three 8-bit registers to store the incoming 24-bit number from
; the ADC of HX711.        Arrangement: [00000000,00000000,00000000]
;                                       [  Byte2 ,  Byte1 ,  Byte0 ]
Byte2   equ         0x10
Byte1   equ         0x11
Byte0   equ         0x12

; Flag register: to store bits corresponding to specific purposes
; Bit 0: EOC (0: Not EOC, 1: EOC)
Flags   equ         0x14

; Other
tmp1    equ         0x15                                                            ; temporary register; delete later
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Constants
                                                                                    ; Constants for weight thresholds
                                                                                    ; Set the values of GPRs at INIT
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Define origin and interrupt vectors
        org         0x000               ; Origin vector
        goto        INIT
        
        org         0x04                ; Interrupt vector
        goto        ISR_ADC_READY       ; Go to ISR_ADC_READY
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Routine "INIT"
;       Executed once. Configures general settings in PIC.

INIT:
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        
; Set Interrupt Settings
        bsf         INTCON, INTE        ; Enable the RB0/INT interrupt
        
        bcf         INTCON, GIE         ; Disable all un-masked (global)
                                        ; interrupts (turn this on only
                                        ; when needed)
                                        
        bcf         INTCON, INTF        ; Clear the RB0/INT flag
        
        bcf         OPTION_REG, INTEDG  ; Interrupt on falling edge of
                                        ; RB0/INT pin (required by HX711)
                                        ; Falling edge = ADC is ready to
                                        ;                transmit data
                                        
; Set PORTA, PORTB pin modes (default)
        movlw       b'00000001'         ; PORTB I/O pattern
        movwf       TRISB               ; Set PORTB pin modes
        
        movlw       b'00000000'         ; PORTA I/O pattern
        movwf       TRISA               ; Set PORTA pin modes
        
        bcf         STATUS, RP0         ; Bank 0 select

; Reset flags (clear all)
        clrf        Flags               ; User-defined flags
        
; Initialize PORTA and PORTB                                                        ; See whether this will be needed later
        ;movlw       b'00000000'         ; All zeros
        ;movwf       PORTB
        ;movlw       b'00000000'         ; All zeros
        ;movwf       PORTA
        
; Initialize positions of the three motors to zero        
        movlw       b'00000111'         ; Turn on RA0, RA1, RA2
        movwf       PORTA               ; 
        call        MOTOR_0_ON          ;
        
        movlw       b'00000000'         ; Turn off RA0, RA1, RA2
        movwf       PORTA               ; 
        call        MOTOR_0_OFF         ;

; Finally switch to the MAIN routine
        call        MAIN
        
;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
; MAIN: Main routine
MAIN:
        call        READ_FROM_ADC       ; Read a raw value from ADC
        
        bsf         PORTA, RA3          ; ADC: Power down mode
        call        DELAY_100us         ;
        
        ; Display the read bits
        movf        Byte2, W            ; Byte2
        movwf       tmp1                ;
        call        _DISP_BITS          ;
        call        DELAY_1S            ;
        
        movf        Byte1, W            ; Byte1
        movwf       tmp1                ;
        call        _DISP_BITS          ;
        call        DELAY_1S            ;
        
        movf        Byte0, W            ; Byte0
        movwf       tmp1                ;
        call        _DISP_BITS          ;
        call        DELAY_1S            ;
        
        movlw       b'00000000'         ; Display zero
        movwf       tmp1                ;
        call        _DISP_BITS          ;
        call        DELAY_1S            ;
        
        bcf         PORTA, RA3          ; ADC: Power up mode
        
PROCESS_DATA:
        ; Process Byte2, Byte1, Byte0
                                                                                    ; Do the rest
        
        goto        MAIN
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
_DISP_BITS:                                                                         ; temporary function to display a register
        bcf         PORTA, RA4                                                      ; delete later
        btfsc       tmp1, 0
        bsf         PORTA, RA4
        
        bcf         PORTB, RB1
        btfsc       tmp1, 1
        bsf         PORTB, RB1
        
        bcf         PORTB, RB2
        btfsc       tmp1, 2
        bsf         PORTB, RB2
        
        bcf         PORTB, RB3
        btfsc       tmp1, 3
        bsf         PORTB, RB3
        
        bcf         PORTB, RB4
        btfsc       tmp1, 4
        bsf         PORTB, RB4
        
        bcf         PORTB, RB5
        btfsc       tmp1, 5
        bsf         PORTB, RB5
        
        bcf         PORTB, RB6
        btfsc       tmp1, 6
        bsf         PORTB, RB6
        
        bcf         PORTB, RB7
        btfsc       tmp1, 7
        bsf         PORTB, RB7
        
        return
;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
; READ_FROM_ADC: Read a 24-bit raw value from the HX711 module
READ_FROM_ADC:
        bsf         STATUS, RP0         ; Switch to Bank 1 (bit 5)
        
        bcf         INTCON, GIE         ; Disable all un-masked (global)
                                        ; interrupts (turn this on only
                                        ; when needed)
                                        
        bcf         INTCON, INTF        ; Clear the RB0/INT flag
        bcf         STATUS, RP0         ; Bank 0 select
        
SOC: ; Start of conversion
        movlw       d'25'               ; Reset the bit index to 25
        movwf       BitIdx              ; (to count 24 bits)

; Reset the 24-bit number
        clrf        Byte2               ; Clear Byte2 register
        clrf        Byte1               ; Clear Byte2 register
        clrf        Byte0               ; Clear Byte2 register
        
; Turn on the ADC
        movlw       b'00000000'         ; SCK: 0 (Clear SCK line)
        movwf       PORTA               ; RA0, RA1                              
        
        movlw       b'00000001'         ; DOUT: 1 (Set this to 1.               
                                        ; Interrupt will then trigger
        movwf       PORTB               ; at a falling edge of this pin)
        
        bcf         Flags, 0            ; Clear EOC flag
        
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        bsf         INTCON, GIE         ; Enable GIE to make the
                                        ; RB0 pin an interrupt pin
        bcf         STATUS, RP0         ; Bank 0 select (bit 5)

; Wait until ADC is ready (i.e. wait until RB0 is falling-edge triggered)
IDLE_STATE:
        btfss       Flags, 0            ; Check if the EOC flag is set
        goto        IDLE_STATE          ; Go to the MAIN routine again (loop)

EOC: ; End of conversion
        return                          ; If EOC flag is set, then a single
                                        ; read cycle is completed. Go back
                                        ; to the MAIN routine.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ISR_ADC_READY: Occurs when ADC is ready to send data
ISR_ADC_READY:
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        bcf         INTCON, GIE         ; Disable GIE to make the RB0 pin
                                        ; temporarily an input
        bcf         STATUS, RP0         ; Bank 0 select (bit 5)

BIT_READ_LOOP:
        decfsz      BitIdx, f           ; Decrement the current bit index
        goto        ADC_READ_BIT        ; Get the latest bit from the ADC

BIT_READ_END:
        bsf         Flags, 0            ; Set EOC flag to mark the EOC

; Post-processing of received data
POST_PROC:
; XOR the raw output
        movlw       b'00001000'         ; Turn on the SCK pin of HX711
        movwf       PORTA               ; 
        nop
        
        movf        Byte2, W            ;                                           ; Reason for XORing?
        xorlw       b'10000000'         ; XOR Byte2 with 0x80 (10000000)
        movwf       Byte2               ; 
        
        movf        Byte1, W            ; 
        xorlw       b'00000000'         ; XOR Byte1 with 0x00 (00000000)
        movwf       Byte1               ;
        
        movf        Byte0, W            ;
        xorlw       b'00000000'         ; XOR Byte0 with 0x00 (00000000)
        movwf       Byte0               ;
        
        movlw       b'00000000'         ; Turn off the SCK pin of HX711
        movwf       PORTA               ;
        nop                             ;
        
        return                          ; Return from ISR_ADC_READY
                                        ; Goes back to IDLE_STATE (EOC)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ADC_READ_BIT: Read a bit from the ADC
ADC_READ_BIT:

; Left-shift Byte2, Byte1 and Byte0 by one bit
        rlf         Byte0, f            ; Left-shift Byte0
        rlf         Byte1, f            ; Left-shift Byte1
        rlf         Byte2, f            ; Left-shift Byte2
        
        
    
;        rlf         Byte2, f            ; Left-shift Byte2
;        
;        bcf         Byte2, 0            ; Clear the LSB of Byte2
;        
;        rlf         Byte1, f            ; Left-shift Byte1
;        
;        btfsc       STATUS, C           ; Get the carry bit of Byte1 after
;                                        ; Left-shifting
;                                        
;        bsf         Byte2, 0            ; Set the LSB of Byte2 equal to the
;                                        ; carry of Byte1
;        
;        rlf         Byte0, f            ; Left-shift Byte0
;        
;        bcf         Byte1, 0            ; Clear the LSB of Byte1
;        
;        btfsc       STATUS, C           ; Get the carry bit of Byte0 after
;                                        ; Left-shifting
;                                        
;        bsf         Byte1, 0            ; Set the LSB of Byte1 equal to the
;                                        ; carry of Byte0
                                        
                                        
        
        bcf         Byte0, 0            ; Clear the LSB of Byte0
                                        
; Get the incoming bit and assign it to the LSB of Byte0
; Apply a clock pulse
        movlw       b'00001000'         ; Turn on the SCK pin of HX711
        movwf       PORTA               ;
        nop
        
        movlw       b'00000000'         ; Turn off the SCK pin of HX711
        movwf       PORTA
        nop
        
        btfsc       PORTB, RB0          ; Capture the incoming bit from the
                                        ; ADC by checking whether it is 1
        
        bsf         Byte0, 0            ; Set the LSB of the 24-bit number
                                        ; with the new bit (if it is 1)
        
        goto        BIT_READ_LOOP
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; DELAY: Generic delay subroutine
; T = 18 + (count1-1)*3 + (count2-1)*770 + (count3-1)*197140 ns
DELAY
	decfsz      count1, f
	goto        DELAY
	
	decfsz      count2, f
	goto        DELAY
	
	decfsz      count3, f
	goto        DELAY
	
  	return
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Motor Controller subroutines
MOTOR_PLUS90_ON:
        movlw       d'149'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'3'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
MOTOR_PLUS90_OFF:
	movlw       d'1'                ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'3'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return

MOTOR_0_ON:
        movlw       d'238'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
MOTOR_0_OFF:
	movlw       d'161'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
MOTOR_MINUS30_ON:
        movlw       d'183'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
MOTOR_MINUS30_OFF:
	movlw       d'217'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return

MOTOR_PLUS30_ON:
        movlw       d'37'               ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'3'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
MOTOR_PLUS30_OFF:
	movlw       d'106'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return
        
DELAY_1S:
	movlw       d'142'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'19'               ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'6'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return

DELAY_100us: ; For ADC power off
	movlw       d'28'               ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; keep the set-up delay
        
        return

;-------------------------------------------------------------------------------

INF_LOOP:
        goto    $

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
        end
;-------------------------------------------------------------------------------
