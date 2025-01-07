#include <xc.inc>

;***************************************************************************
; Declaring Variables and Functions
;***************************************************************************
; Declare global variables and external references used in the program.
global  motor_setup, int_mhi, delay_1ms, theta_upper, theta_lower, phi_upper, phi_lower, delay_1ms
extrn	UD_res, LR_res

psect	udata_acs
ms1_outer_timer:	    ds 1   ; Reserve 1 byte for 'outer_timer' used in 1ms delay
ms1_inner_timer:	    ds 1   ; Reserve 1 byte for 'inner_timer' used in 1ms delay
msnt_outer_timer:	    ds 1   ; Reserve 1 byte for 'outer_timer' used in theta pulse delay
msnt_inner_timer:	    ds 1   ; Reserve 1 byte for 'inner_timer' used in theta pulse delay
msnp_outer_timer:	    ds 1   ; Reserve 1 byte for 'outer_timer' used in phi pulse delay
msnp_inner_timer:	    ds 1   ; Reserve 1 byte for 'inner_timer' used in phi pulse delay
theta_upper:		    ds 1   ; Upper byte of theta pulse delay
theta_lower:		    ds 1   ; Lower byte of theta pulse delay
phi_upper:		        ds 1   ; Upper byte of phi pulse delay
phi_lower:		        ds 1   ; Lower byte of phi pulse delay

;***************************************************************************
; Initialization
;***************************************************************************
psect	motor_code, class=CODE

motor_setup:
    ; Configure PORTD as output and initialize it to zero.
    clrf    TRISD,  A      ; Set PORTD as output
    clrf    PORTD,  A      ; Clear PORTD
    clrf    LATD,   A      ; Clear PORTD latches
    
    ; Configure Timer0
    movlw   10000001B      ; Configure Timer0 (T0CON)
    movwf   T0CON, A
    bsf	    TMR0IE          ; Enable Timer0 interrupt
    bsf	    GIE             ; Enable global interrupts
    return

;***************************************************************************
; Interrupts
;***************************************************************************
; Interrupt Service Routine for Timer0
int_mhi:
    btfss   TMR0IF          ; Check if Timer0 overflow interrupt occurred
    retfie  f               ; Return from interrupt if not set
    bsf	    LATD, 2, A       ; Set motor control pin for theta (LATD2)
    call    delay_1ms       ; Delay for 1ms
    call    delay_pulse_theta; Generate theta pulse delay
    bcf	    LATD, 2, A       ; Clear motor control pin for theta
    
    bsf	    LATD, 5, A       ; Set motor control pin for phi (LATD5)
    call    delay_1ms       ; Delay for 1ms
    call    delay_pulse_phi ; Generate phi pulse delay
    bcf	    LATD, 5, A       ; Clear motor control pin for phi
    bcf	    TMR0IF           ; Clear Timer0 interrupt flag
    retfie  f               ; Return from interrupt

;***************************************************************************
; Delays
;***************************************************************************
; 1ms Delay Subroutine
delay_1ms:
    movlw	0x12             ; Outer timer value for 1ms delay
    movwf	ms1_outer_timer, A
    movlw	0xFF             ; Inner timer value for 1ms delay
    movwf	ms1_inner_timer, A

    movlw 	0x00             ; Initialize W to 0
inner_lpp_1: 	
    decf 	ms1_inner_timer, f, A		; Decrement inner timer
    subwfb 	ms1_outer_timer, f, A		; Decrement outer timer
    bc 	    inner_lpp_1				; Loop if carry is not set
    return					; Return when delay completes

; Theta Pulse Delay Subroutine
delay_pulse_theta:
    movff   theta_upper, msnt_outer_timer, A ; Load theta_upper into outer timer
    movff   theta_lower, msnt_inner_timer, A ; Load theta_lower into inner timer

    movlw 	0x00             ; Initialize W to 0
inner_lpp_t: 	
    decf 	msnt_inner_timer, f, A		; Decrement inner timer
    subwfb 	msnt_outer_timer, f, A		; Decrement outer timer
    bc 	    inner_lpp_t				; Loop if carry is not set
    return					; Return when delay completes

; Phi Pulse Delay Subroutine
delay_pulse_phi:
    movff   phi_upper, msnp_outer_timer, A ; Load phi_upper into outer timer
    movff   phi_lower, msnp_inner_timer, A ; Load phi_lower into inner timer

    movlw 	0x00             ; Initialize W to 0
inner_lpp_p: 	
    decf 	msnp_inner_timer, f, A		; Decrement inner timer
    subwfb 	msnp_outer_timer, f, A		; Decrement outer timer
    bc 	    inner_lpp_p				; Loop if carry is not set
    return					; Return when delay completes

end

