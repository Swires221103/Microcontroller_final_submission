#include <xc.inc>

;***************************************************************************
; Declaring Variables and Functions
;***************************************************************************
global Init_manual, man_loop_1   ; Declare global functions
extrn	UD_res, LR_res          ; Declare external variables used from other modules

psect	udata_acs
delay_outer_timer:	    ds 1   ; Reserve 1 byte for outer delay timer
delay_inner_timer:	    ds 1   ; Reserve 1 byte for inner delay timer

;***************************************************************************
; Initialization
;***************************************************************************
psect	joystick_code, class=CODE

Init_manual:
    ; Configure joystick port and initialize direction result variables.
    movlw   0xFF             ; Set PORTJ as input
    movwf   TRISJ, A

    movlw   0x00             ; Initialize Up/Down result to 0
    movwf   UD_res, A

    movlw   0x00             ; Initialize Left/Right result to 0
    movwf   LR_res, A
    return

;***************************************************************************
; Main Loop
;***************************************************************************
man_loop_1:
    ; Perform the first delay
    call    big_delay

    ; Reset UD_res and LR_res
    movlw   0x00
    movwf   UD_res, A
    movlw   0x00
    movwf   LR_res, A

    ; Check PORTJ for joystick position and update UD_res
    movlw   0b11010101       ; Joystick UP pattern
    cpfseq  PORTJ, A         ; Compare PORTJ with pattern
    goto    man_loop_2       ; If not equal, go to the next check
    movlw   0x01             ; Set UD_res to 0x01 for UP
    movwf   UD_res, A
    return

man_loop_2:
    movlw   0b01011101       ; Joystick DOWN pattern
    cpfseq  PORTJ, A         ; Compare PORTJ with pattern
    goto    man_loop_3       ; If not equal, go to the next check
    movlw   0xFF             ; Set UD_res to 0xFF for DOWN
    movwf   UD_res, A
    return

man_loop_3:
    movlw   0b01110101       ; Joystick LEFT pattern
    cpfseq  PORTJ, A         ; Compare PORTJ with pattern
    goto    man_loop_4       ; If not equal, go to the next check
    movlw   0xFF             ; Set LR_res to 0xFF for LEFT
    movwf   LR_res, A
    return

man_loop_4:
    movlw   0b01010111       ; Joystick RIGHT pattern
    cpfseq  PORTJ, A         ; Compare PORTJ with pattern
    return                   ; If not equal, joystick is in neutral position
    movlw   0x01             ; Set LR_res to 0x01 for RIGHT
    movwf   LR_res, A
    return

;***************************************************************************
; Delay Subroutine
;***************************************************************************
big_delay:
    ; Generate a long delay using nested loops
    movlw	0x10             ; Load outer loop timer with 0x10
    movwf	delay_outer_timer
    movlw	0xFF             ; Load inner loop timer with 0xFF
    movwf	delay_inner_timer

    movlw 	0x00             ; Initialize W to 0
inner_lpp_p: 	
    decf 	delay_inner_timer, f, A		; Decrement inner timer
    subwfb 	delay_outer_timer, f, A		; Decrement outer timer
    bc 	    inner_lpp_p				; Repeat until carry flag is set
    return					; Return when delay completes

END
