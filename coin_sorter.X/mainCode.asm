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

;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Variables
; Counter variables for delays
count1  equ         0x0c		; used in a decfsz
count2  equ         0x0d		; used in a decfsz
count3  equ         0x0e		; used in a decfsz
sensorbitcounter    equ     0x0f
TestCount           equ     0x10
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Constants
;       define constants for weight thresholds
;       Set the values of GPRs at INIT
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Define origin and interrupt vectors
        org         0x000               ; Origin
        goto        INIT
        
        org         0x04                ; Interrupt vector
        goto        ISR                 ; Unimplemented
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Routine "INIT"
;       Executed once. Configures settings in PIC.

INIT:
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)

; Set Interrupt Settings
        bsf         INTCON, INTE        ; Enable the RB0/INT interrupt
        
        bsf         INTCON, GIE         ; Enable all un-masked (global)
                                        ; interrupts
                                    
        bcf         INTCON, INTF        ; Clear the RB0/INT flag
        
        bsf         OPTION_REG, INTEDG  ; Interrupt on rising edge of
                                        ; RB0/INT pin

; Set PORTA, PORTB pin modes
        movlw       b'00000000'         ; PORTB I/O pattern
        movwf       TRISB               ; Set PORTB pin modes
        
        movlw       b'00001000'         ; PORTA I/O pattern (DOUT as input)
        movwf       TRISA               ; Set PORTA pin modes
        
        bcf         STATUS, RP0         ; Bank 0 select

; Initialize PORTA and PORTB
        movlw       b'00000000'         ; All zeros
        movwf       PORTB
        movlw       b'00000000'         ; All zeros
        movwf       PORTA
        
; Initialize positions of the three motors to zero        
        movlw       b'00000111'         ; turn on RA0, RA1, RA2
        movwf       PORTA               ; 
        call        MOTOR_0_ON          ;
        
        movlw       b'00000000'         ; turn off RA0, RA1, RA2
        movwf       PORTA               ; 
        call        MOTOR_0_OFF         ;
        
        call        DELAY_1S
        
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Routine "MAIN"
MAIN:
        ; The MAIN loop
        call        READ_SENSOR_VALUE
        
        ; TODO:
        ;           check for coin
        ;           if coin, (try to use an interrupt for this)
        ;               measure the weight
        ;               open the gate
        ;               close the gate
        ;               wait
        ;               turn the platform according to weight
        ;               tilt the platform
        ;               reset platform position
        
        goto        MAIN                ; Go to the MAIN routine again (loop)

;-------------------------------------------------------------------------------
; Subroutine "READ_SENSOR_VALUE"
READ_SENSOR_VALUE:
        ;        unsigned long Count;
        ;        unsigned char i;
    
;        pinMode(DT, OUTPUT);
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        movlw       b'00000000'         ; PORTA I/O pattern
        movwf       TRISA               ; Set PORTA pin modes
        
;        digitalWrite(DT,HIGH);
;        digitalWrite(SCK,LOW);
        bcf         STATUS, RP0         ; Bank 0 select
        movlw       b'00001000'         ; turn on DOUT, turn off SCK
        movwf       PORTA               ; 
        
;        count = 0
        movlw       b'00000000'
        movwf       TestCount
        

;        pinMode(DT, INPUT);
        bsf         STATUS, RP0         ; Bank 1 select (bit 5)
        movlw       b'00001000'         ; PORTA I/O pattern
        movwf       TRISA               ; Set PORTA pin modes
        
        bcf         STATUS, RP0         ; Bank 0 select

;        while(digitalRead(DT));
DOUT_1:
        btfsc       PORTA, 4
        goto        DOUT_1
        
        movlw       d'23'
        movwf       sensorbitcounter
        
;        for (i = 0; i < 24; i++)
BIT_READ:
        decfsz      sensorbitcounter, f
        goto        ITER
        goto        BIT_READ_END
        
ITER:
;          digitalWrite(SCK, HIGH);
        movlw       b'00010000'         ; turn on SCK
        movwf       PORTA               ; 
        
;          Count = Count << 1;
        rlf         TestCount, f
        
;          digitalWrite(SCK, LOW);
        movlw       b'00000000'         ; turn off SCK
        movwf       PORTA               ; 

;if (digitalRead(DT)) 
        btfsc       PORTA, 3
;              Count++;
        incf        TestCount, f

        
        movf        TestCount, w
        
        ;movlw       b'11111111'
        movwf       PORTB
        
        call        DELAY_1S
        
        movlw       b'00000000'
        movwf       PORTB
        
        call        DELAY_1S
        
        
        
        
        
        goto        BIT_READ
        
BIT_READ_END:
        
;        digitalWrite(SCK,HIGH);
        movlw       b'00010000'         ; turn on SCK
        movwf       PORTA               ; 
        
        ; Count = Count^0x800000;
        
;        digitalWrite(SCK,LOW);
        movlw       b'00000000'         ; turn off SCK
        movwf       PORTA               ; 
        
        ; return(Count);
        
;-------------------------------------------------------------------------------
;        unsigned long Count;
;        unsigned char i;
;        pinMode(DT, OUTPUT);
;        digitalWrite(DT,HIGH);
;        digitalWrite(SCK,LOW);
;        Count=0
;        pinMode(DT, INPUT);
;        while(digitalRead(DT));
;        for (i=0; i<24; i++)
;        {
;          digitalWrite(SCK, HIGH);
;          Count = Count << 1;
;          digitalWrite(SCK, LOW);
;          if (digitalRead(DT)) 
;               Count++;
;        }
;        digitalWrite(SCK,HIGH);
;        Count=Count^0x800000;
;        digitalWrite(SCK,LOW);
;        return(Count);
;-------------------------------------------------------------------------------
        
        return
        
;-------------------------------------------------------------------------------
; ISR ""
ISR:
        ; Interrupt occurred event
        retfie                          ; Return from interrupt
;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
; Delay subroutine (general)
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
	call        DELAY               ; 90deg on time
        
        return
        
MOTOR_PLUS90_OFF:
	movlw       d'1'                ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'3'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; 90deg off time
        
        return

MOTOR_0_ON:
        movlw       d'238'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; 0deg on time
        
        return
        
MOTOR_0_OFF:
	movlw       d'161'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; 0deg off time
        
        return
        
MOTOR_MINUS30_ON:
        movlw       d'183'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'2'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; -30deg on time
        
        return
        
MOTOR_MINUS30_OFF:
	movlw       d'217'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; -30deg off time
        
        return

MOTOR_PLUS30_ON:
        movlw       d'37'               ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'3'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; +30deg on time
        
        return
        
MOTOR_PLUS30_OFF:
	movlw       d'106'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'1'                ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'1'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; +30deg off time
        
        return
        
DELAY_1S:
	movlw       d'142'              ; set layer 1 delay counter
	movwf       count1              ; 
	movlw       d'19'               ; set layer 2 delay counter
	movwf       count2              ; 
	movlw       d'6'                ; set layer 3 delay counter
	movwf       count3              ; 
	call        DELAY               ; +30deg off time
        
        return
        
;-------------------------------------------------------------------------------
INF_LOOP:
        goto    $
;-------------------------------------------------------------------------------
        
;-------------------------------------------------------------------------------
        end
;-------------------------------------------------------------------------------
