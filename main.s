#include <xc.inc>

;***************************************************************************
; Declaring Variables and Functions
;***************************************************************************
; External variables and subroutines are declared here to be used throughout the program.
; Includes motor setup, sensor setup, manual mode, and axes checking functions.

   extrn    motor_setup, int_mhi, theta_upper, theta_lower, phi_upper, phi_lower, delay_1ms 
   extrn    sensor_setup, Check_UD_axis, Check_LR_axis, UD_res, LR_res  
   extrn    Init_manual, man_loop_1
   
;***************************************************************************
; Main Loops
;***************************************************************************   
; Code section defining program execution starting from the reset vector and interrupt.

   psect   code,abs
   rst:                ; Reset vector
    org	    0x0000      ; Start of program memory
    goto    setup       ; Jump to the setup routine
   
   int_hi:             ; High-priority interrupt vector
    org	    0x08        ; Interrupt memory location
    goto    int_mhi     ; Jump to the high-priority interrupt handler
    
; Setup routine to initialize peripherals and clear variables
   setup:
    call    motor_setup
    call    sensor_setup
    call    Init_manual
    clrf    phi_upper   ; Clear upper byte of phi
    clrf    phi_lower   ; Clear lower byte of phi
    clrf    theta_upper ; Clear upper byte of theta
    clrf    theta_lower ; Clear lower byte of theta

; Mode selection based on PORTC, bit 4
   mode:  
    btfsc   PORTC, 4, A ; Check if PORTC, bit 4 is set
    goto    auto_loop   ; If set, jump to auto mode
    goto    manual_loop ; Otherwise, jump to manual mode

;***************************************************************************
; Manual Mode Loop
;***************************************************************************
; Handles manual joystick-controlled gimbal operation.
   manual_loop:
    call    man_loop_1
    movlw   0x00
    cpfseq  UD_res, A   ; Check up-down result
    call    change_theta
    cpfseq  LR_res, A   ; Check left-right result
    call    change_phi
    goto    mode        ; Return to mode selection

;***************************************************************************
; Automatic Mode Loop
;***************************************************************************
; Handles motion tracking using sensor input.
   auto_loop:
    call    Check_UD_axis ; Check up-down axis
    call    Check_LR_axis ; Check left-right axis
    movlw   0x00
    cpfseq  UD_res, A     ; Check up-down result
    call    change_theta
    nop                   ; Delay for timing
    cpfseq  LR_res, A     ; Check left-right result
    call    change_phi
    nop                   ; Delay for timing
   
    goto    mode          ; Return to mode selection
    
;***************************************************************************
; Main Subroutines
;***************************************************************************

;==========================================================
; CHANGE THETA OR PHI
;==========================================================   
; Determine whether to increment or decrement theta/phi based on the result.
   change_theta:
    movlw   0x01
    cpfseq  UD_res, A      ; Check result for theta
    goto    dec_theta_check
    goto    add_theta_check1

   change_phi:
    movlw   0x01
    cpfseq  LR_res, A      ; Check result for phi
    goto    dec_phi_check
    goto    add_phi_check1
    
;==========================================================
; INCREMENT THETA
;==========================================================
; Increment theta value while ensuring it stays within range.
   add_theta_check1:
    movlw   0x14           ; Upper limit for theta
    cpfslt  theta_upper, A
    goto    add_theta_check2
    goto    add_theta

   add_theta_check2:
    movlw   0xFE           ; Lower limit for theta
    cpfslt  theta_lower, A
    return
    goto    add_theta
   
   add_theta:
    movlw   0x01
    addwf   theta_lower, f, A ; Add to lower byte
    btfsc   STATUS, 0, A      ; Check for carry
    incf    theta_upper, f, A ; Increment upper byte if carry
    bcf	    STATUS,0,A         ; Clear carry flag
    return
  

;==========================================================
; DECREMENT THETA
;==========================================================
; Decrement theta value while ensuring it stays within range.
   dec_theta_check:
    movlw   0x00           ; Upper limit for theta
    cpfseq  theta_upper, A
    goto    dec_theta
    goto    dec_theta_check2
    
   dec_theta_check2:
    movlw   0x02           ; Lower limit for theta
    cpfslt  theta_lower, A
    goto    dec_theta
    return
    
   dec_theta:
    movlw   0x01
    subwf   theta_lower, f, A ; Subtract from lower byte
    btfss   STATUS, 0, A      ; Check for borrow
    decf    theta_upper, f, A ; Decrement upper byte if borrow
    bcf	    STATUS, 0, A         ; Clear borrow flag
    return
    
;==========================================================
; INCREMENT PHI
;==========================================================
; Increment phi value while ensuring it stays within range.
   add_phi_check1:
    movlw   0x14           ; Upper limit for phi
    cpfslt  phi_upper, A
    goto    add_phi_check2
    goto    add_phi

   add_phi_check2:
    movlw   0xFE           ; Lower limit for phi
    cpfslt  phi_lower, A
    return
    goto    add_phi

   add_phi:
    movlw   0x01
    addwf   phi_lower, f, A ; Add to lower byte
    btfsc   STATUS, 0, A    ; Check for carry
    incf    phi_upper, f, A ; Increment upper byte if carry
    bcf	    STATUS,0,A       ; Clear carry flag
    return    

;==========================================================
; DECREMENT PHI
;==========================================================
; Decrement phi value while ensuring it stays within range.
   dec_phi_check:
    movlw   0x00           ; Upper limit for phi
    cpfseq  phi_upper, A
    goto    dec_phi
    goto    dec_phi_check2
    
   dec_phi_check2:
    movlw   0x02           ; Lower limit for phi
    cpfslt  phi_lower, A
    goto    dec_phi
    return
    
   dec_phi:
    movlw   0x01
    subwf   phi_lower, f, A ; Subtract from lower byte
    btfss   STATUS, 0, A    ; Check for borrow
    decf    phi_upper, f, A ; Decrement upper byte if borrow
    bcf	    STATUS,0,A       ; Clear borrow flag
    return
end

   


