#include <xc.inc>

;***************************************************************************
; Declaring Variables and Functions
;***************************************************************************
; Declaring global variables and functions used in the program.
global  sensor_setup, Check_UD_axis, Check_LR_axis, UD_res, LR_res

psect	udata_acs
UD_res:	    ds 1   ; Reserve 1 byte for variable 'UD_result'
LR_res:	    ds 1   ; Reserve 1 byte for variable 'LR_result'
delay_outer_timer:	    ds 1   ; Reserve 1 byte for 'outer_timer'
delay_inner_timer:	    ds 1   ; Reserve 1 byte for 'inner_timer'

;***************************************************************************
; Initialization
;***************************************************************************
psect	sensor_code, class=CODE

sensor_setup:
    ; Configure PORTC and PORTE as input/output for sensors and LEDs
    ;banksel ANCON2       ; Uncomment if using analog configuration (not used here)
    ;clrf    ANCON2, A    ; Clear analog settings
    ;banksel 0
    movlw   0xFF          ; Configure PORTC as inputs
    movwf   TRISC, A
    clrf    PORTC, A       ; Clear PORTC
    clrf    LATC, A        ; Clear PORTC latches
    
    movlw   0x00          ; Configure PORTE as outputs
    movwf   TRISE, A
    clrf    LATE, A        ; Clear PORTE latches
    return

;=====================================    
; Up - Down Checking
;===================================== 
; Routine to check the state of the up-down axis sensors.
Check_UD_axis:
    call	big_delay         ; Introduce delay to stabilize sensor readings
    clrf	UD_res, A         ; Clear previous result for Up/Down axis
    btfsc	PORTC, 0, A       ; Check if UP_SENSOR is high
    goto	Check_down_high   ; If high, check DOWN_SENSOR state
    goto	Check_down_low    ; If low, check DOWN_SENSOR state

Check_down_low:
    btfsc	PORTC, 1, A       ; Check if DOWN_SENSOR is high
    goto	DOWN_condition_met; If high, execute DOWN condition
    bcf		PORTE, 1, A       ; Clear LED1
    bcf		PORTE, 2, A       ; Clear LED2
    return                  ; If both sensors are low, return

Check_down_high:
    btfss	PORTC, 1, A       ; Check if DOWN_SENSOR is low
    goto	UP_condition_met  ; If low, execute UP condition
    bcf		PORTE, 1, A       ; Clear LED1
    bcf		PORTE, 2, A       ; Clear LED2
    return                  ; If both sensors are high, return

UP_condition_met:
    movlw	0x01              ; Set result for Up/Down axis as "UP"
    movwf	UD_res, A         ; Store result in UD_result
    bsf		PORTE, 1, A       ; Turn on LED1 to indicate UP condition
    return
    
DOWN_condition_met:
    movlw	0xFF              ; Set result for Up/Down axis as "DOWN"
    movwf	UD_res, A         ; Store result in UD_result
    bsf		PORTE, 2, A       ; Turn on LED2 to indicate DOWN condition
    return

;=====================================    
; Left - Right Checking
;===================================== 
; Routine to check the state of the left-right axis sensors.
Check_LR_axis:
    call	big_delay         ; Introduce delay to stabilize sensor readings
    clrf	LR_res, A         ; Clear previous result for Left/Right axis
    btfsc	PORTC, 2, A       ; Check if LEFT_SENSOR is high
    goto	Check_right_high  ; If high, check RIGHT_SENSOR state
    goto	Check_right_low   ; If low, check RIGHT_SENSOR state

Check_right_low:
    btfsc	PORTC, 3, A       ; Check if RIGHT_SENSOR is high
    goto	RIGHT_condition_met; If high, execute RIGHT condition
    bcf		PORTE, 1, A       ; Clear LED1
    bcf		PORTE, 2, A       ; Clear LED2
    return                  ; If both sensors are low, return

Check_right_high:
    btfss	PORTC, 3, A       ; Check if RIGHT_SENSOR is low
    goto	LEFT_condition_met; If low, execute LEFT condition
    bcf		PORTE, 1, A       ; Clear LED1
    bcf		PORTE, 2, A       ; Clear LED2
    return                  ; If both sensors are high, return

LEFT_condition_met:
    movlw	0x01              ; Set result for Left/Right axis as "LEFT"
    movwf	LR_res, A         ; Store result in LR_result
    bsf		PORTE, 1, A       ; Turn on LED1 to indicate LEFT condition
    return
    
RIGHT_condition_met:
    movlw	0xFF              ; Set result for Left/Right axis as "RIGHT"
    movwf	LR_res, A         ; Store result in LR_result
    bsf		PORTE, 2, A       ; Turn on LED2 to indicate RIGHT condition
    return

;=====================================    
; Delay Subroutine
;===================================== 
; Generates a delay using nested loops.
big_delay:
    movlw	0x05              ; Outer timer initial value
    movwf	delay_outer_timer
    movlw	0xF0              ; Inner timer initial value
    movwf	delay_inner_timer
    
    movlw 	0x00              ; Set W=0
inner_lpp_p: 	
    decf 	delay_inner_timer, f, A	; Decrement inner timer
    subwfb 	delay_outer_timer, f, A	; Decrement outer timer
    bc 	inner_lpp_p	            ; Loop if carry flag is clear
    return	
END  
