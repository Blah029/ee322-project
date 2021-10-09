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
; PIC pin designations (for reference)
; * RA0          : COIN_GATE (Servo Motor 1)
; * RA1          : ROTATE (Servo Motor 2)
; * RA2          : TILT (Servo Motor 3)
; * RA3          : SCK (Serial Clock) of HX711 module
; * RA4          : 
; * RB0          : DOUT (Data line Out) of HX711 module
; * RA4, RB1-RB7 : Display
;-------------------------------------------------------------------------------

;<editor-fold defaultstate="collapsed" desc="DECLARATIONS">
;-------------------------------------------------------------------------------
; Header
#include <p16f84a.inc>                  ; Include file for register names
            list        p = 16f84a      ; Microcontroller model
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Constant Literals

; Reference Values for coin weights
CType1Byte0 equ         b'00000000'     ; Rs. 1
CType1Byte1 equ         b'10100000'
CType1Byte2 equ         b'01111101'

CType2Byte0 equ         b'00000000'     ; Rs. 2
CType2Byte1 equ         b'10000000'
CType2Byte2 equ         b'01111011'

CType3Byte0 equ         b'00000000'     ; Rs. 5
CType3Byte1 equ         b'00100000'
CType3Byte2 equ         b'01111011'

CType4Byte0 equ         b'00000000'     ; Rs. 10
CType4Byte1 equ         b'10100000'
CType4Byte2 equ         b'01111010'
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; GPRs: Defines variable names for memory addresses used in the program.

; Three 8-bit registers to store the incoming 24-bit number from
; the HX711 module           Bit setup: [xxxxxxxx, xxxxxxxx, xxxxxxxx]
;                                       [  Byte2 ,   Byte1 ,   Byte0 ]
Byte2       equ         0x10
Byte1       equ         0x11
Byte0       equ         0x12

; Three 8-bit registers to store a reference 24-bit number corresponding
; to a coin type.            Bit setup: [xxxxxxxx, xxxxxxxx, xxxxxxxx]
;                                       [RefByte2, RefByte1, RefByte0]
RefByte2    equ         0x13
RefByte1    equ         0x14
RefByte0    equ         0x15

; A variable to store the bit index currently being read from the ADC
; of the HX711 module
BitIdx      equ         0x0f                
      
; Flag register: Stores bits corresponding to specific purposes
; Bit 0: EOC                            (0: Not EOC, 1: EOC)
; Bit 1: Byte1 comparison result        (0: Unequal, 1: Equal)
; Bit 2: Byte2 comparison result        (0: Unequal, 1: Equal)
Flags       equ         0x16
      
; Counter variables for DELAY subroutine
VarX        equ         0x0c		; Used in decfsz
VarY        equ         0x0d		; Used in decfsz
VarZ        equ         0x0e		; Used in decfsz

; Processing
CoinType    equ         0x18            ; Store the current coin type
TotalAmount equ         0x17            ; Store the running sum of coin values
BCDAmount   equ         0x19            ; Stores the BCD digits corresponding
                                        ; to the runninng sum of coin values

; Display
DisplayReg  equ         0x1a            ; Register used for the display

;-------------------------------------------------------------------------------
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="INITIALIZATION">

;-------------------------------------------------------------------------------
; # PROGRAM START #
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Define origin and interrupt vectors
    org         0x000               ; Origin vector
    goto        INIT
        
    org         0x04                ; Interrupt vector
    goto        ISR_ADC_READY       ; Go to ISR_ADC_READY
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; INIT: Initialization routine
;       Executed once. Configures general settings in PIC.
INIT:
    bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        
; Set Interrupt Settings
    bsf         INTCON, INTE        ; Enable the RB0/INT interrupt
        
    bcf         INTCON, GIE         ; Disable all un-masked (global)
                                    ; interrupts and turn this on only
                                    ; when needed
                                        
    bcf         INTCON, INTF        ; Clear the RB0/INT flag
        
    bcf         OPTION_REG, INTEDG  ; Interrupt on falling edge of
                                    ; RB0/INT pin (required by HX711)
                                    ; Falling edge = ADC is ready to
                                    ;                transmit data

; Set PORTA, PORTB pin modes (default)
    movlw       b'00000001'         ; PORTB I/O pattern
    movwf       TRISB               ; Set PORTB pin modes
        
    movlw       b'00000'            ; PORTA I/O pattern
    movwf       TRISA               ; Set PORTA pin modes
        
    bcf         STATUS, RP0         ; Bank 0 select

; Reset flags (clear all)
    clrf        Flags               ; Clear user-defined flags
    clrf        TotalAmount         ; Reset total amount to zero
        
; Initialize PORTA and PORTB to zeros
    movlw       b'00000000'         ; All zeros
    movwf       PORTB
    movlw       b'00000'            ; All zeros
    movwf       PORTA
        
; Initialize positions of the three motors to zero
    movlw       b'00111'            ; Turn on RA0, RA1, RA2
    movwf       PORTA               ; 
    call        MOTOR_0_ON          ;
        
    movlw       b'00000'            ; Turn off RA0, RA1, RA2
    movwf       PORTA               ; 
    call        MOTOR_0_OFF         ;

; Finally switch to the MAIN routine
    call        MAIN
        
;-------------------------------------------------------------------------------
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="MAIN ROUTINE">
    
;-------------------------------------------------------------------------------
; MAIN: Main routine (loop)
MAIN:
; Read a raw value from ADC of HX711 module
    call        READ_FROM_ADC

; Power down the ADC temporarily
    bsf         PORTA, RA3          ; ADC: Power down mode
    call        DELAY_100us         ;
        
; Processing
    goto        COMPARE_WEIGHT      ; Processing

; Latter part of the MAIN routine
END_MAIN:
; Reset the motor positions
; Turn the TILT motor back to its original position
    bsf         PORTA, 2            ; Turn TILT motor to 0 degrees
    call        MOTOR_0_ON          ;
    bcf         PORTA, 2            ;
    call        MOTOR_0_OFF         ;
    
    call        DELAY_500ms         ; Keep a delay
    
; Turn the TURN motor back to its original position
    bsf         PORTA, 1            ; Turn TURN motor to 0 degrees
    call        MOTOR_0_ON          ;
    bcf         PORTA, 1            ;
    call        MOTOR_0_OFF         ;
    
    call        DELAY_500ms         ; Keep a delay
    
; Turn on the ADC again for the next cycle
    bcf         PORTA, RA3          ; ADC: Power up mode
                                    ; Turn on the ADC for the next loop

    goto        MAIN                ; Go to the MAIN routine again
;-------------------------------------------------------------------------------
    
;</editor-fold>

;<editor-fold defaultstate="collapsed" desc="SUB ROUTINES">

;-------------------------------------------------------------------------------
; INPUT: ADC

;<editor-fold defaultstate="collapsed" desc="INPUT">
        
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
        
; Turn on the ADC
    bcf         PORTA, RA3          ; SCK: 0 (Clear SCK line)
        
    bsf         PORTB, 0            ; DOUT: 1 (Set this to 1. 
                                    ; Interrupt will then trigger
                                    ; at a falling edge of this pin)
    
    bcf         Flags, 0            ; Clear EOC flag
    
    bsf         STATUS, RP0         ; Bank 1 select (bit 5)
    bsf         INTCON, GIE         ; Enable GIE to make the
                                    ; RB0 pin an interrupt pin
    bcf         STATUS, RP0         ; Bank 0 select (bit 5)

; Wait until ADC is ready. That is, wait until a falling-edge occurs on RB0.
; If it does, the PIC goes to the ISR.
IDLE_STATE:
    btfss       Flags, 0            ; Check if the EOC flag is set.
    goto        IDLE_STATE          ; If not, stay until the ADC is ready.
                                    ; (loop)

EOC: ; End of conversion
    return                          ; If EOC flag is set, then a single
                                    ; read cycle is completed. Go back
                                    ; to the MAIN routine.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ISR_ADC_READY: Occurs when ADC is ready to send data. Triggered through RB0
;                interrupt.
ISR_ADC_READY:
    bsf         STATUS, RP0         ; Bank 1 select (bit 5)
    bcf         INTCON, GIE         ; Disable GIE to make the RB0 pin
                                    ; temporarily an input
    bcf         STATUS, RP0         ; Bank 0 select (bit 5)

BIT_READ_LOOP_START:
    decfsz      BitIdx, f           ; Decrement the current bit index
    goto        ADC_READ_BIT        ; Get the latest bit from the ADC

BIT_READ_LOOP_END:
    bsf         Flags, 0            ; Set EOC flag to mark the EOC
    
    bsf         PORTA, RA3          ; Turn on the SCK pin of HX711
    nop

; Post-processing of received data
POST_PROC:    
; Raw output conditioning
    movf        Byte2, W            ;
    xorlw       b'10000000'         ; XOR Byte2 with 0x80 (10000000)
    movwf       Byte2               ; (Inverts the MSB of Byte2)
    
    bcf         PORTA, RA3          ; Turn off the SCK pin of HX711
    nop                             ;
        
    return                          ; Return from ISR_ADC_READY
                                    ; Goes back to IDLE_STATE (EOC)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ADC_READ_BIT: Read a bit from the ADC
ADC_READ_BIT:

; Left-shift Byte2, Byte1 and Byte0 by one bit. Carries between the registers
; are automatically handled.
    rlf         Byte0, f            ; Left-shift Byte0
    rlf         Byte1, f            ; Left-shift Byte1
    rlf         Byte2, f            ; Left-shift Byte2
    bcf         Byte0, 0            ; Clear the LSB of Byte0
                                        
; Get the incoming bit and assign it to the LSB of Byte0
    bsf         PORTA, RA3          ; Turn on the SCK pin of HX711
    nop
        
    bcf         PORTA, RA3          ; Turn off the SCK pin of HX711
    nop
        
    btfsc       PORTB, RB0          ; Capture the incoming bit from the
                                    ; ADC by checking whether it is 1
        
    bsf         Byte0, 0            ; Set the LSB of the 24-bit number
                                    ; with the new bit (if it is 1)
        
    goto        BIT_READ_LOOP_START ; Go back to the beginning of a new bit
                                    ; read cycle
;-------------------------------------------------------------------------------
;</editor-fold>

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; PROCESSING

;<editor-fold defaultstate="collapsed" desc="PROCESSING">

;-------------------------------------------------------------------------------
; COMPARE_WEIGHT: Compares the weight of the coin on the platform
;                 (if any) with the reference coin weights and determines the
;                 coin type
COMPARE_WEIGHT:

COIN_TYPE_1:
    movlw       CType1Byte0         ; Load coin type 1 reference value
    movwf       RefByte0            ;
    movlw       CType1Byte1         ;
    movwf       RefByte1            ;
    movlw       CType1Byte2         ;
    movwf       RefByte2            ;
        
    call        CHECK_TOLERANCE     ; Compare the 24-bit value from the
                                    ; ADC with the chosen reference value
                                        
    btfss       STATUS, Z           ; Check if the last comparison
                                    ; resulted 1
    goto        COIN_TYPE_2         ; Check the next coin type in case of
                                    ; unsuccessful comparison
; Successful comparison
    movlw       d'1'
    movwf       CoinType
    goto        COIN_GATE_OPEN      ; Accept the coin

COIN_TYPE_2:
    movlw       CType2Byte0         ; Load coin type 2 reference value
    movwf       RefByte0            ;
    movlw       CType2Byte1         ;
    movwf       RefByte1            ;
    movlw       CType2Byte2         ;
    movwf       RefByte2            ;
        
    call        CHECK_TOLERANCE     ; Compare the 24-bit value from the
                                    ; ADC with the chosen reference value
                                        
    btfss       STATUS, Z           ; Check if the last comparison
                                    ; resulted 1
    goto        COIN_TYPE_3         ; Check the next coin type in case of
                                    ; unsuccessful comparison
; Successful comparison
    movlw       d'2'
    movwf       CoinType
    goto        COIN_GATE_OPEN      ; Accept the coin
        
COIN_TYPE_3:
    movlw       CType3Byte0         ; Load coin type 3 reference value
    movwf       RefByte0            ;
    movlw       CType3Byte1         ;
    movwf       RefByte1            ;
    movlw       CType3Byte2         ;
    movwf       RefByte2            ;
        
    call        CHECK_TOLERANCE     ; Compare the 24-bit value from the
                                    ; ADC with the chosen reference value
                                        
    btfss       STATUS, Z           ; Check if the last comparison
                                    ; resulted 1
    goto        COIN_TYPE_4         ; Check the next coin type in case of
                                    ; unsuccessful comparison
; Successful comparison
    movlw       d'5'
    movwf       CoinType
    goto        COIN_GATE_OPEN      ; Accept the coin
                                        
COIN_TYPE_4:
    movlw       CType4Byte0         ; Load coin type 4 reference value
    movwf       RefByte0            ;
    movlw       CType4Byte1         ;
    movwf       RefByte1            ;
    movlw       CType4Byte2         ;
    movwf       RefByte2            ;
        
    call        CHECK_TOLERANCE     ; Compare the 24-bit value from the
                                    ; ADC with the chosen reference value
        
    btfss       STATUS, Z           ; Check if the last comparison
                                    ; resulted 1
    goto        END_MAIN            ; In case of unsuccessful comparison,
                                    ; end data processing
; Successful comparison
    movlw       d'10'
    movwf       CoinType
    goto        COIN_GATE_OPEN      ; Accept the coin
        
; ------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; CHECK_TOLERANCE: Tests whether the 24-bit value read from the HX711 module
;                  matches the given reference value by comparing a specified
;                  number of most significant bits.
CHECK_TOLERANCE:
    clrf        Flags               ; Clear flags register
        
    ; Byte2
    movf        Byte2, W            ; Copy Byte2 to W
    subwf       RefByte2, W         ; Subtract Byte2 from RefByte2
    btfsc       STATUS, Z           ; Test whether the Z flag is set.
                                    ; Z = 1 when Byte2 is equal to the
                                    ; reference
    bsf         Flags, 2            ; Set flag 2 if the Byte2 matches the
                                    ; reference
                                        
    ; Byte1
    movf        Byte1, W            ; Copy Byte1 to W
    andlw       b'11100000'         ; Filter out Byte1
    subwf       RefByte1, W         ; Subtract Byte1 from RefByte1
    btfsc       STATUS, Z           ; Test whether the Z flag is set.
                                    ; Z = 1 when Byte1 is equal to the
                                    ; reference
    bsf         Flags, 1            ; Set flag 1 if the Byte1 matches the
                                    ; reference
        
    ; Check equality
    movf        Flags, W            ; Get the Flags register to W
    sublw       b'00000110'         ; Check whether all the 2 flags
                                    ; (corresponding to Byte1, and Byte2)
                                    ; are 1. If yes, the weight of
                                    ; the coin is within a valid range.
    
    return                          ; Return

;-------------------------------------------------------------------------------

;</editor-fold>

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; ACTUATION: Motors, motor delays etc.

;<editor-fold defaultstate="collapsed" desc="ACTUATION">

;-------------------------------------------------------------------------------
; COIN_GATE_OPEN: Takes the coin in if the coin weight matches the reference
;                 values.
COIN_GATE_OPEN:
    bsf         PORTA, 0            ; Open COIN_GATE
    call        MOTOR_PLUS90_ON     ;
    bcf         PORTA, 0            ;
    call        MOTOR_PLUS90_OFF    ;
    
    call        DELAY_500ms         ; Keep a delay
    
    bsf         PORTA, 0            ; Close COIN_GATE
    call        MOTOR_0_ON          ;
    bcf         PORTA, 0            ;
    call        MOTOR_0_OFF         ;
    
    call        DELAY_500ms         ; Keep a delay
    
UPDATE_DISPLAY:
    ; Update the total amount register (running sum)
    movf        CoinType, W         ; Update value count
    addwf       TotalAmount, f      ; 
    
    call        BIN_TO_BCD          ; Convert the 8-bit binary number to BCD
                                    ; (without altering the actual sum)
    
    movf        BCDAmount, W        ; Send the BCDAmount to the display
    movwf       DisplayReg          ; register.
    call        DISPLAY_BITS        ;
    call        DELAY_500ms         ; Keep a delay

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; TURN_AND_TILT: Turns and tilts the platform based on the type of coin and
;                returns back to END_MAIN.

TURN_AND_TILT:
    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'1'                ; Check if coin type is d'1'
    btfsc       STATUS, Z           ;
    goto        TURN_PLUS90         ; If yes, turn TURN motor to +90 degrees

    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'5'                ; Check if coin type is d'5'
    btfsc       STATUS, Z           ;
    goto        TURN_PLUS90         ; If yes, turn TURN motor to +90 degrees

TILT:
    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'1'                ; Check if coin type is d'1'
    btfsc       STATUS, Z           ; 
    goto        TILT_PLUS30         ; If yes, turn TILT motor to +30 degrees

    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'10'               ; Check if coin type is d'10'
    btfsc       STATUS, Z           ; 
    goto        TILT_PLUS30         ; If yes, turn TILT motor to +30 degrees

    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'2'                ; Check if coin type is d'2'
    btfsc       STATUS, Z           ; 
    goto        TILT_MINUS30        ; If yes, turn TILT motor to -30 degrees

    movf        CoinType, W         ; Take the identified coin type to W
    sublw       d'5'                ; Check if coin type is d'5'
    btfsc       STATUS, Z           ; 
    goto        TILT_MINUS30        ; If yes, turn TILT motor to -30 degrees

TURN_PLUS90:
    bsf         PORTA, 1            ; Turn TURN motor to +90 degrees
    call        MOTOR_PLUS90_ON     ;
    bcf         PORTA, 1            ;
    call        MOTOR_PLUS90_OFF    ;

    call        DELAY_500ms         ; Keep a delay

    goto        TILT

TILT_PLUS30:
    bsf         PORTA, 2            ; Turn TURN motor to +30 degrees
    call        MOTOR_PLUS30_ON     ;
    bcf         PORTA, 2            ;
    call        MOTOR_PLUS30_OFF    ;
        
    call        DELAY_500ms         ; Keep a delay
        
    goto        END_MAIN            ;

TILT_MINUS30:
    bsf         PORTA, 2            ; Turn TURN motor to -30 degrees
    call        MOTOR_MINUS30_ON    ;
    bcf         PORTA, 2            ;
    call        MOTOR_MINUS30_OFF   ;
        
    call        DELAY_500ms         ; Keep a delay
        
    goto        END_MAIN            ;
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Subroutines for motor PWM delays

MOTOR_PLUS90_ON:
    movlw       d'148'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'3'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
MOTOR_PLUS90_OFF:
    movlw       d'1'                ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'1'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'3'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return

MOTOR_0_ON:
    movlw       d'237'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'2'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
MOTOR_0_OFF:
    movlw       d'160'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'1'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
MOTOR_MINUS30_ON:
    movlw       d'181'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'2'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
MOTOR_MINUS30_OFF:
    movlw       d'217'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'1'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return

MOTOR_PLUS30_ON:
    movlw       d'36'               ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'3'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
MOTOR_PLUS30_OFF:
    movlw       d'105'              ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'1'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return

DELAY_500ms:
    movlw       d'72'               ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'138'              ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'3'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return
        
DELAY_100us: ; For ADC power off
    movlw       d'28'               ; set layer 1 delay counter
    movwf       VarX                ; 
    movlw       d'1'                ; set layer 2 delay counter
    movwf       VarY                ; 
    movlw       d'1'                ; set layer 3 delay counter
    movwf       VarZ                ; 
    call        DELAY               ; keep the set-up delay
        
    return

;-------------------------------------------------------------------------------

;</editor-fold>

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; DISPLAY: Functions related to display

;<editor-fold defaultstate="collapsed" desc="DISPLAY">

;-------------------------------------------------------------------------------
; DISPLAY_BITS: Sends the contents in the register DisplayReg to the display
;               unit.

DISPLAY_BITS:
    bcf         PORTA, RA4
    btfsc       DisplayReg, 0
    bsf         PORTA, RA4
        
    bcf         PORTB, RB1
    btfsc       DisplayReg, 1
    bsf         PORTB, RB1
        
    bcf         PORTB, RB2
    btfsc       DisplayReg, 2
    bsf         PORTB, RB2
        
    bcf         PORTB, RB3
    btfsc       DisplayReg, 3
    bsf         PORTB, RB3
        
    bcf         PORTB, RB4
    btfsc       DisplayReg, 4
    bsf         PORTB, RB4
        
    bcf         PORTB, RB5
    btfsc       DisplayReg, 5
    bsf         PORTB, RB5
        
    bcf         PORTB, RB6
    btfsc       DisplayReg, 6
    bsf         PORTB, RB6
        
    bcf         PORTB, RB7
    btfsc       DisplayReg, 7
    bsf         PORTB, RB7
        
    return

;-------------------------------------------------------------------------------

;</editor-fold>

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; GENERAL SUBROUTINES: Helper functions

;<editor-fold defaultstate="collapsed" desc="GENERAL SUBROUTINES">

;-------------------------------------------------------------------------------
; DELAY: Generic delay subroutine
; T = 18 + (VarX-1)*3 + (VarY-1)*770 + (VarZ-1)*197140 ns
DELAY:
    decfsz      VarX, f
    goto        DELAY
    
    decfsz      VarY, f
    goto        DELAY
    
    decfsz      VarZ, f
    goto        DELAY
    
    return
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; BIN_TO_BCD: 8-bit binary to BCD conversion. Used for the display.
;             Uses Double-Dabble algorithm (for an 8-bit number <= 99).

BIN_TO_BCD:
    movlw       d'8'                ; Initialize counter variable VarX at 8
    movwf       VarX                ; 
    
    movf        TotalAmount, W      ; Copy TotalAmount to VarY
    movwf       VarY                ;
    
    clrf        BCDAmount           ; Clear the BCDAmount register
    
BB_LOOP_CHECK:
    rlf         VarY, f             ; Left-shift VarY
    rlf         BCDAmount, f        ; Left-shift BCDAmount
    
    decfsz      VarX, f             ; Decrement the loop index counter
    goto        BB_LOOP_START       ; If VarX > 0, step into loop
    goto        BB_LOOP_END         ; If VarX = 0, step out of loop

BB_LOOP_START:
; Check the four LSBs
    movlw       b'00001111'         ; Filter our the 4 LSBs of BCDAmount
    andwf       BCDAmount, W        ; and place it in W
    
    sublw       d'4'                ; Check if the last 4 bits of current
                                    ; BCDAmount is >= 5.
    movf        BCDAmount, W        ; Restore the original value of BCDAmount
                                    ; to W
    btfss       STATUS, C           ; If yes, add 3 to BCDAmount (in W)
    addlw       d'3'                ;
    
    movwf       BCDAmount           ; Move BCDAmount in W to BCDAmount
    
    goto        BB_LOOP_CHECK       ; Go to the beginning of the loop
                                    ; and check if further iterations are
                                    ; necessary.
    
BB_LOOP_END:
    
    return                          ; Return back to the caller function
;-------------------------------------------------------------------------------

;</editor-fold>

;-------------------------------------------------------------------------------

;</editor-fold>

;-------------------------------------------------------------------------------
; Assembler directive: end
        end
;-------------------------------------------------------------------------------
