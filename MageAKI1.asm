; original File = Tasta.hex from MacFaulkner's AKI
; Based on the v1.1A Tasta.hex file
;
; This was a .hex to .asm conversion, German layout stripped out, and
; various fixes provided by Nathan Hartwell
;
; Apologies to the international community. Since I was fixing things to
; make better sense (to me, anyway), some of the German mappings were in
; the way.  I've released this as open source for anyone else to rework
; the mapping to suit their own desires or purposes.
;


; Macro for special key processing
;
;  base - value returned to allow any Control and Shift combination
;  norm - value returned, preventing any meta application
;  shft - value returned, allowing for key + Shift only
;
Do_Key macro base, norm, shft

       movlw norm                      ; Load normal value
       btfsc KBDmeta,pcCtrl            ; Skip if pcCtrl inactive
       retlw base
       btfss KBDmeta,pcShift           ; Skip if pcShift active
       btfsc KBDmeta,pcShift           ; Skip if pcShift inactive
       movlw shft                      ; Load Shift value
       goto FullKey

       endm


; Macro for processing all 4 meta modes
;
;  norm - value returned, preventing any meta application
;  shft - value returned, allowing for key + Shift only
;  ctrl - value returned, allowing for key + Ctrl only
;  both - value returned, allowing for key + Ctrl AND Shift
;
AllKey macro norm, shft, ctrl, both

       ; Check if Ctrl is used
       btfss KBDmeta,pcCtrl            ; Skip if pcCtrl active
       goto $ + 6                      ; Jump to non-Ctrl processing
       ; Ctrl or Ctrl+Shift
       movlw ctrl                      ; Load Ctrl value
       btfss KBDmeta,pcShift           ; Skip if pcShift active
       btfsc KBDmeta,pcShift           ; Skip if pcShift inactive
       movlw both                      ; Load Ctrl+Shift value
       goto FullKey
       ; normal or Shift
       movlw norm                      ; Load normal value
       btfss KBDmeta,pcShift           ; Skip if pcShift active
       btfsc KBDmeta,pcShift           ; Skip if pcShift inactive
       movlw shft                      ; Load Shift value
       goto FullKey

       endm

    processor 16F84A                   ; 1k word flash

    #include <P16F84.INC>
    __config _CP_OFF & _PWRTE_OFF & _WDT_ON & _HS_OSC

	errorlevel -302

    __idlocs 0x2012


;   EEPROM-Data
    Org 0x2100
    DE 0x00, 0x05, 0x2A, 0x2B, 0x0E, 0x38, 0x30, 0x42
    DE 0x21, 0x25, 0x3F, 0x12, 0x28, 0x08, 0x1F, 0xFF
    DE 0x00, 0x05, 0x2A, 0x2B, 0x0E, 0x38, 0x1F, 0x32
    DE 0x42, 0x25, 0x3F, 0x12, 0x28, 0x08, 0x1E, 0xFF
    DE 0x00, 0x05, 0x2A, 0x2B, 0x0E, 0x38, 0x1F, 0x1F
    DE 0x42, 0x25, 0x3F, 0x12, 0x28, 0x08, 0x1A, 0xFF
    DE 0x00, 0x05, 0x2A, 0x2B, 0x0E, 0x38, 0x1F, 0x1E
    DE 0x42, 0x25, 0x3F, 0x12, 0x28, 0x08, 0x18, 0xFF


; RAM-Variable
savW_PS     equ 0x0C
savSTAT_PS  equ 0x0D
AtariCode   equ 0x0E
POKEY_Meta  equ 0x0F
ScanCount   equ 0x10
Scan_Swap   equ 0x11
Timer       equ 0x13
savW_KBD    equ 0x14
savSTAT_KBD equ 0x15
KBDbuff1    equ 0x16
KBDbuff2    equ 0x17
PA_Shadow   equ 0x18
PB_Shadow   equ 0x19
PB_prev     equ 0x1B
KBDbitcnt   equ 0x21
KBDbyte     equ 0x23
KBDmeta     equ 0x24
Locks       equ 0x25
Flags       equ 0x26
Temp1       equ 0x29
Temp2       equ 0x2A
Macro_Ptr   equ 0x2B


; PC Keyboard I/O defines
#define KBCLK  PORTA,RA4
#define KBDATA PORTA,RA3


; Locks equates
NumLock     equ 7
;           equ 6
ScrollLck   equ 5
;           equ 4
_NumLock    equ 3
;           equ 2
;           equ 1
;           equ 0


; PC Keyboard Meta Key equates
pcCtrl      equ 7
pcShift     equ 6
pcAlt       equ 5
pcAltCtrl   equ 4
;           equ 3
;           equ 2
;           equ 1
;           equ 0


; Atari Meta Key equates
_Ctrl       equ 7
_Shift      equ 5
_Break      equ 1


; Misc KB state (Flags var) equates
;           equ 7
PauseKey    equ 6
;           equ 5
;           equ 4
Nullify     equ 3
FixedMeta   equ 2
ExtKey      equ 1
KeyUp       equ 0


; AKI Meta Key equates
Ctrl        equ 7
Shift       equ 6


; Pokey signal defines
#define K5_prev PB_prev,RB7
#define K5      PORTB,RB7
#define K0      PORTB,RB6
#define KR1     PORTB,RB5
#define KR2     PORTB,RB4
#define _Reset  PORTB,RB3
#define _Option PORTB,RB2
#define _Select PORTB,RB1
#define _Start  PORTB,RB0


; Program

#ifdef NEWVARS
RST         code
#else
    Org 0x0000
#endif

;   Reset-Vector
    bsf STATUS,RP0                     ; Set Register Bank 1
    goto Init
    nop
    nop
;   Interrupt-Vector
ISR
    btfss INTCON,T0IF                  ; Skip if TMR0 (aka KBCLK) activated
    goto PokeyScan_jump                ; Nope, jump to POKEY scan processing
    movwf savW_KBD
    swapf STATUS,W
    movwf savSTAT_KBD
    goto KBD_ISR
PokeyScan_jump
    movwf savW_PS                      ; Save W register
    swapf STATUS,W                     ; Swap STATUS, placing result in W
    movwf savSTAT_PS                   ; Save W (swapped STATUS) register
    goto PokeyScan_ISR
XL8_SC2                                ; Add Scan Code (Set 2) to PCL
    addwf PCL,F                        ; Code - Description
    retlw 0xFF                         ; 0x00 - should never see this code
    goto Proc_F9                       ; 0x01 - F9
    retlw 0xFF                         ; 0x02
    goto Proc_F5                       ; 0x03 - F5
    retlw 0x13                         ; 0x04 - F3
    goto Proc_F1                       ; 0x05 - F1
    retlw 0x04                         ; 0x06 - F2
    goto Proc_F12                      ; 0x07 - F12
    retlw 0xFF                         ; 0x08
    goto Proc_F10                      ; 0x09 - F10
    goto Proc_F8                       ; 0x0A - F8
    goto Proc_F6                       ; 0x0B - F6
    goto Proc_F4                       ; 0x0C - F4
    retlw 0x2C                         ; 0x0D - Tab
    retlw 0x09                         ; 0x0E - ` (~)
    retlw 0xFF                         ; 0x0F
    retlw 0xFF                         ; 0x10 - (extended: WWW Search)
    goto Proc_Alt                      ; 0x11 - Alt (extended: RAlt)
    goto Proc_Shift                    ; 0x12 - LShift
    retlw 0xFF                         ; 0x13
    goto Proc_Ctrl                     ; 0x14 - Ctrl (extended: RCtrl)
    retlw 0x2F                         ; 0x15 - Q (extended: Previous Track)
    retlw 0x1F                         ; 0x16 - 1
    retlw 0xFF                         ; 0x17
    retlw 0xFF                         ; 0x18 - (extended: WWW Favorites)
    retlw 0xFF                         ; 0x19
    retlw 0x17                         ; 0x1A - Z
    retlw 0x3E                         ; 0x1B - S
    retlw 0x3F                         ; 0x1C - A
    retlw 0x2E                         ; 0x1D - W
    goto Proc_2                        ; 0x1E - 2
    retlw 0x27                         ; 0x1F - (extended: LGUI)
    retlw 0xFF                         ; 0x20 - (extended: WWW Refresh)
    retlw 0x12                         ; 0x21 - C (extended: Volume Down)
    retlw 0x16                         ; 0x22 - X
    retlw 0x3A                         ; 0x23 - D (extended: Mute)
    retlw 0x2A                         ; 0x24 - E
    retlw 0x18                         ; 0x25 - 4
    retlw 0x1A                         ; 0x26 - 3
    retlw 0x27                         ; 0x27 - (extended: RGUI)
    retlw 0xFF                         ; 0x28 - (extended: WWW Stop. in the Name of Love?)
    retlw 0x21                         ; 0x29 - Space (the Final Frontier?)
    retlw 0x10                         ; 0x2A - V
    retlw 0x38                         ; 0x2B - F (extended: Calculator)
    retlw 0x2D                         ; 0x2C - T
    retlw 0x28                         ; 0x2D - R
    retlw 0x1D                         ; 0x2E - 5
    retlw 0x3B                         ; 0x2F - (extended: Menu/Apps)
    retlw 0xFF                         ; 0x30 - (extended: WWW Forward)
    retlw 0x23                         ; 0x31 - N
    retlw 0x15                         ; 0x32 - B (extended: Volume Up)
    retlw 0x39                         ; 0x33 - H
    retlw 0x3D                         ; 0x34 - G (extended: Play/Pause)
    retlw 0x2B                         ; 0x35 - Y
    goto Proc_6                        ; 0x36 - 6
    retlw 0xFF                         ; 0x37 - (extended: Power)
    retlw 0xFF                         ; 0x38 - (extended: WWW Back)
    retlw 0xFF                         ; 0x39
    retlw 0x25                         ; 0x3A - M (extended: WWW Home)
    retlw 0x01                         ; 0x3B - J (extended: Stop)
    retlw 0x0B                         ; 0x3C - U
    goto Proc_7                        ; 0x3D - 7
    goto Proc_8                        ; 0x3E - 8
    retlw 0xFF                         ; 0x3F - (extended: Sleep)
    retlw 0xFF                         ; 0x40 - (extended: My Computer)
    goto Proc_Comma                    ; 0x41 - ,
    retlw 0x05                         ; 0x42 - K
    retlw 0x0D                         ; 0x43 - I
    retlw 0x08                         ; 0x44 - O
    retlw 0x32                         ; 0x45 - 0
    retlw 0x30                         ; 0x46 - 9
    retlw 0xFF                         ; 0x47
    retlw 0xFF                         ; 0x48 - (extended: E-Mail)
    goto Proc_Period                   ; 0x49 - .
    retlw 0x26                         ; 0x4A - /
    retlw 0x00                         ; 0x4B - L
    retlw 0x02                         ; 0x4C - ;
    retlw 0x0A                         ; 0x4D - P (extended: Next Track)
    retlw 0x0E                         ; 0x4E - - (aka Dash or Minus)
    retlw 0xFF                         ; 0x4F
    retlw 0xFF                         ; 0x50 - (extended: Media Select)
    retlw 0xFF                         ; 0x51
    goto Proc_Apostrophe               ; 0x52 - '
    retlw 0xFF                         ; 0x53
    goto Proc_LBracket                 ; 0x54 - [
    goto Proc_Equal                    ; 0x55 - =
    retlw 0xFF                         ; 0x56
    retlw 0xFF                         ; 0x57
    retlw 0x3C                         ; 0x58 - CapsLock
    goto Proc_Shift                    ; 0x59 - RShift
    retlw 0x0C                         ; 0x5A - Enter (extended: KeyPad Enter)
    goto Proc_RBracket                 ; 0x5B - ]
    retlw 0xFF                         ; 0x5C
    goto Proc_BackSlash                ; 0x5D - \
    retlw 0xFF                         ; 0x5E - (extended: Wake)
    retlw 0xFF                         ; 0x5F
    retlw 0xFF                         ; 0x60
    retlw 0xFF                         ; 0x61
    retlw 0xFF                         ; 0x62
    retlw 0xFF                         ; 0x63
    retlw 0xFF                         ; 0x64
    retlw 0xFF                         ; 0x65
    retlw 0x34                         ; 0x66 - Backspace
    retlw 0xFF                         ; 0x67
    retlw 0xFF                         ; 0x68
    goto Proc_KP1                      ; 0x69 - KP1 (extended: End)
    retlw 0xFF                         ; 0x6A
    goto Proc_KP4                      ; 0x6B - KP4 (extended: Left)
    goto Proc_KP7                      ; 0x6C - KP7 (extended: Home)
    retlw 0xFF                         ; 0x6D
    retlw 0xFF                         ; 0x6E
    retlw 0xFF                         ; 0x6F
    goto Proc_KP0                      ; 0x70 - KP0 (extended: Ins)
    goto Proc_KPperiod                 ; 0x71 - KP. (extended: Del)
    goto Proc_KP2                      ; 0x72 - KP2 (extended: Down)
    goto Proc_KP5                      ; 0x73 - KP5 (extended: Omni for Northgate Omni keyboards)
    goto Proc_KP6                      ; 0x74 - KP6 (extended: Right)
    goto Proc_KP8                      ; 0x75 - KP8 (extended: Up)
    retlw 0x1C                         ; 0x76 - Escape
    goto Proc_NumLock                  ; 0x77 - NumLock
    goto Proc_F11                      ; 0x78 - F11
    retlw 0x06                         ; 0x79 - KP+
    goto Proc_KP3                      ; 0x7A - KP3 (extended: PgDn)
    retlw 0x0E                         ; 0x7B - KP-
    goto Proc_KPstar                   ; 0x7C - KP* (extended: PrtScr)
    goto Proc_KP9                      ; 0x7D - KP9 (extended: PgUp)
    goto Proc_ScrollLock               ; 0x7E - ScrollLock
    retlw 0xFF                         ; 0x7F
    retlw 0x32                         ; 0x80 - 0 (German layout?)
    retlw 0x20                         ; 0x81 - ,
    retlw 0x1E                         ; 0x82 - 2 (German layout?)
    goto Proc_F7                       ; 0x83 - F7
    goto Proc_SysRq                    ; 0x84 - Alt-SysRq
    retlw 0x35                         ; 0x85 - 8 (German layout?)
    retlw 0x1C                         ; 0x86 - Escape (German layout?)
    retlw 0xFF                         ; 0x87
    retlw 0xFF                         ; 0x88
    retlw 0x06                         ; 0x89 - + (German layout?)
    retlw 0x1A                         ; 0x8A - 3 (German layout?)
    retlw 0x0E                         ; 0x8B - - (German layout?)
    retlw 0x07                         ; 0x8C - * (German layout?)
    retlw 0x30                         ; 0x8D - 9 (German layout?)
    retlw 0xFF                         ; 0x8E
    retlw 0xFF                         ; 0x8F
KBD_ISR
    bcf STATUS,RP0                     ; Set Register Bank 0
    btfsc KBDbitcnt,7                  ; Skip if KBDbitcnt hasn't gone negative
    goto FullKBDbyte
    bcf STATUS,C
    btfsc KBDATA                       ; Skip if KB data line low
    bsf STATUS,C                       ; KB data line was high
    rrf KBDbuff1,F                     ; Roll KB data into buffer
    rrf KBDbuff2,F
    decf KBDbitcnt,F                   ; Decrement KBDbitcnt
FullKBDbyte
    decf TMR0,F                        ; Set TMR0 back to 0xFF
    bcf INTCON,T0IF
    swapf savSTAT_KBD,W
    movwf STATUS                       ; Restore STATUS register
    swapf savW_KBD,F                   ; And, restore W register
    swapf savW_KBD,W                   ; 
    retfie
PokeyScan_ISR
    bcf STATUS,RP0                     ; Set Register Bank 0
    bsf KR1                            ; Set /KR1 high (inactive)
    bsf KR2                            ; Set /KR2 high (inactive)
    incf ScanCount,F                   ; Increase POKEY scan counter
    btfsc K5_prev                      ; Skip if previous /K5 low
    btfsc K5                           ; Skip if /K5 low
    goto _PS
    clrf ScanCount
    btfss Timer,7
    decf Timer,F
_PS
    movf AtariCode,W                   ; Compare key value to send
    xorwf ScanCount,W                  ; With the current POKEY scan count
    btfsc STATUS,Z                     ; Skip if they don't match
    bcf KR1                            ; Set /KR1 low (signal the keystroke)
    movlw   0x0F            ; if bit 5 is 0, must be bit 3,2,1,0
    btfsc   ScanCount,5
    movlw   0xF0            ; if bit 5 is 1, must be bit 7,6,4,5
    btfsc   ScanCount,4
    andlw   0xCC            ; if bit 4 is 1, must be bit 7,6,3,2
    btfss   ScanCount,4
    andlw   0x33            ; if bit 4 is 0  must be bit 4,5,1,0
    btfsc   ScanCount,3
    andlw   0xAA            ; if bit 3 is 1, must be bit 7,5,3,1
    btfss   ScanCount,3
    andlw   0x55            ; if bit 3 is 0  must be bit 6,4,2,0
    andwf POKEY_Meta,W
    btfss STATUS,Z
    bcf KR2                            ; Set /KR2 low
    movf PORTB,W                       ; Read PORTB
    movwf PB_prev                      ; Save the PORTB value
    bcf INTCON,RBIF                    ; Clear PORTB change interrupt flag
    swapf savSTAT_PS,W                 ; Swap saved STATUS, placing result in W
    movwf STATUS                       ; Restore STATUS register
    swapf savW_PS,F                    ; And, restore W register
    swapf savW_PS,W                    ; 
    retfie
Hard_Macro
    movwf PCL
HM1
    retlw 0x7C                         ; Shift-Caps
    retlw 0x25                         ; M
    retlw 0x3C                         ; Caps
    retlw 0x3F                         ; a
    retlw 0x3D                         ; g
    retlw 0x2A                         ; e
    retlw 0x7C                         ; Shift-Caps
    retlw 0x3F                         ; A
    retlw 0x05                         ; K
    retlw 0x0D                         ; I
    retlw 0x21                         ; (Space)
    retlw 0x3C                         ; Caps
    retlw 0x10                         ; V
    retlw 0x3C                         ; Caps
    retlw 0x1F                         ; 1
    retlw 0x22                         ; .
    retlw 0x1F                         ; 0
    retlw 0x21                         ; (Space)
    retlw 0x35                         ; 9
    retlw 0x26                         ; /
    retlw 0x1E                         ; 2
    retlw 0x32                         ; 0
    retlw 0x1F                         ; 1
    retlw 0x1E                         ; 2
    retlw 0xFF                         ; [end macro]
Init
    movlw 0xFC                         ; 
    movwf PORTA                        ; Initialize PORTA I/O directions
    movlw 0xC0
    movwf PORTB                        ; Initialize PORTB I/O directions
    movlw 0xFF                         ; PORTB pullups off
                                       ; Interrupt on rising edge of RB0/INT
                                       ; TMR0 clock on RA4/T0CKI
                                       ; TMR0 increase on high-to-low
                                       ; Prescalar assigned to WDT
                                       ; 1:128 prescale for WDT
    movwf TMR0                         ; Set OPTION_REG
    bsf EEDATA,2                       ; Enable EEPROM writes
    bcf STATUS,RP0                     ; Set Register Bank 0
    clrwdt
    movlw 0x7F                         ; 
    movwf PB_Shadow
    movwf PORTB                        ; Set initial PORTB condition
    movlw 0xFB                         ; 
    movwf PA_Shadow
    movwf PORTA                        ; Set initial PORTA condition
    movlw 0x08
    movwf INTCON                       ; Enable PORTB change interrupt
    clrf ScanCount
    movlw 0xFF
    movwf AtariCode
    movlw 0x00
    movwf POKEY_Meta
    bsf INTCON,GIE                     ; Enable all un-masked interrupts
    call SetKBDvars
    clrf KBDmeta
    clrf Locks
    clrf Macro_Ptr
    clrf Flags
PreMain
    movlw 0x00                         ; 
;   call Read_EE                       ; Read EEPROM address 0x00
;   andlw 0x80                         ; Mask out saved option bit
;   movwf Flags                        ; Left from the German layout support
    btfsc Flags,PauseKey               ; Previously saw E1 prefix?
    iorlw (1<<PauseKey)                ; Preserve PauseKey flag
    movwf Flags                        ; 
Main
    call GetKBDbyte
    xorlw 0xE0
    btfsc STATUS,Z
    goto Set_ExtKey
    movf KBDbyte,W
    xorlw 0xE1
    btfsc STATUS,Z
    goto Set_PauseKey
    movf KBDbyte,W
    xorlw 0xF0
    btfsc STATUS,Z
    goto Set_KeyUp
    movlw 0x90
    subwf KBDbyte,W
    btfsc STATUS,C
    goto Main
    movf KBDbyte,W
    call XL8_SC2                       ; Translate Scan Code to POKEY Code
    movwf FSR
    xorlw 0xFF
    btfsc STATUS,Z
    goto PreMain
    btfsc Flags,Nullify                ; Skip if not a nulled keystroke
    goto PreMain
    movf FSR,W
    btfsc Flags,FixedMeta              ; Skip if meta bits are not preset
    goto _HaveMeta
    andlw 0x3F
    movwf FSR
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    bsf FSR,Shift                      ; Set Shift bit
    btfsc KBDmeta,pcCtrl               ; Skip if pcCtrl inactive
    bsf FSR,Ctrl                       ; Set Control bit
    movf FSR,W
_HaveMeta
    btfss Timer,7
    goto _HaveMeta
    btfsc Flags,KeyUp                  ; Skip if key not being released
    goto AtariKeyUp
    movwf FSR
    btfsc Macro_Ptr,7
    call Record_Key
    bcf POKEY_Meta,_Shift
    bcf POKEY_Meta,_Ctrl
    btfsc FSR,Ctrl
    bsf POKEY_Meta,_Ctrl
    btfsc FSR,Shift
    bsf POKEY_Meta,_Shift
    movf FSR,W
    andlw 0x3F
    xorlw 0x3F
    movwf AtariCode
    movlw 0x03
    movwf Timer
    goto PreMain
AtariKeyUp
    movlw 0xFF
    movwf AtariCode
    clrf POKEY_Meta
    goto PreMain
Set_ExtKey
    bsf Flags,ExtKey                   ; Set extended key (E0 prefix) flag
    goto Main
Set_PauseKey
    bsf Flags,PauseKey                 ; Set Pause Key (E1 prefix) flag
    goto Main
Set_KeyUp
    bsf Flags,KeyUp                    ; Set key release (F0 prefix) flag
    goto Main
Record_Key
    movf Macro_Ptr,W
    andlw 0x0F
    btfsc STATUS,Z
    return
    movf Macro_Ptr,W
    andlw 0x3F
    movwf EEADR                        ; Set EEPROM address to store key
    movf FSR,W
    call Write_EE
    incf Macro_Ptr,F
    return
Read_EE
    movwf EEADR                        ; Set EEPROM address to read from
_RdEE
    bsf STATUS,RP0                     ; Set Register Bank 1
    bsf EEDATA,RD                      ; Initiate EEPROM read
    bcf STATUS,RP0                     ; Set Register Bank 0
    movf EEDATA,W                      ; Read EEPROM byte
    return
Write_EE
    movwf EEDATA                       ; Set data to write in EEPROM
    bcf INTCON,GIE                     ; Disable all interrupts
    bsf STATUS,RP0                     ; Set Register Bank 1
    movlw 0x55
    movwf EEADR                        ; EEPROM Write unlock #1
    movlw 0xAA
    movwf EEADR                        ; EEPROM Write unlock #2
    bsf EEDATA,WR                      ; Start write cycle
    bsf INTCON,GIE                     ; Enable all un-masked interrupts
_WrEE
    btfsc EEDATA,WR                    ; Check busy status
    goto _WrEE
    bcf STATUS,RP0                     ; Set Register Bank 0
    goto _RdEE
NullKey
    bsf Flags,Nullify
    retlw 0x00
FullKey
    bsf Flags,FixedMeta
    return
Proc_Shift
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto NullKey                       ; Ignore extended Shift codes
    bcf KBDmeta,pcShift                ; Clear pcShift flag
    btfss Flags,KeyUp                  ; Skip if key released
    bsf KBDmeta,pcShift                ; Set pcShift flag
    btfsc Flags,KeyUp                  ; Skip if key not being released
    bcf POKEY_Meta,_Shift
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    bsf POKEY_Meta,_Shift
    goto NullKey
Proc_Ctrl
    bcf KBDmeta,pcCtrl                 ; Clear pcCtrl flag
    btfss Flags,KeyUp                  ; Skip if key released
    bsf KBDmeta,pcCtrl                 ; Set pcCtrl flag
    btfsc Flags,KeyUp                  ; Skip if key not being released
    bcf POKEY_Meta,_Ctrl
    btfsc KBDmeta,pcCtrl               ; Skip if pcCtrl inactive
    bsf POKEY_Meta,_Ctrl 
    call Proc_Meta
    goto NullKey
Proc_Alt
    bcf KBDmeta,pcAlt                  ; Clear pcAlt flag
    btfss Flags,KeyUp                  ; Skip if key released
    bsf KBDmeta,pcAlt                  ; Set pcAlt flag
    call Proc_Meta
    goto NullKey
Proc_Meta
    bsf KBDmeta,pcAltCtrl              ; Set pcAltCtrl flag
    btfsc KBDmeta,pcCtrl               ; Skip if pcCtrl inactive
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    bcf KBDmeta,pcAltCtrl              ; Clear pcAltCtrl flag
    return
Proc_NumLock
    btfsc Flags,PauseKey               ; Only the Pause key uses the E1 prefix
    goto _Pause
_NumLck
    bcf Locks,NumLock                  ; Clear NumLock flag
    btfss Flags,KeyUp                  ; Skip if key released
    bsf Locks,NumLock                  ; Set NumLock flag
    btfss Locks,NumLock                ; Skip if NumLock active
    goto NullKey
    movlw (1<<_NumLock)
    xorwf Locks,F
    goto NullKey
_Pause
    btfsc Flags,KeyUp                  ; Skip if key not being released
    bcf Flags,PauseKey
    movlw 0x24
    goto FullKey
Proc_ScrollLock
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto Set_Break
    movlw 0x9F
    goto FullKey
;   bcf Locks,ScrollLck 
;   btfss Flags,KeyUp                  ; Skip if key released
;   bsf Locks,ScrollLck
;   bsf LEDctrl,Scroll
;   btfss Locks,ScrollLck
;   goto NullKey
;   bcf LEDctrl,Scroll
;   goto NullKey
Proc_2
    Do_Key 0x1E, 0x1E, 0x75

Proc_6
    Do_Key 0x1B, 0x1B, 0x47

Proc_7
    Do_Key 0x33, 0x33, 0x5B

Proc_8
    Do_Key 0x35, 0x35, 0x07

Proc_Comma
    Do_Key 0x20, 0x20, 0x36

Proc_Period
    Do_Key 0x22, 0x22, 0x37

Proc_Equal
    Do_Key 0x0F, 0x0F, 0x06

Proc_BackSlash
    Do_Key 0x06, 0x46, 0x4F

Proc_Apostrophe
    AllKey 0x73, 0x5E, 0xF3, 0xDE

Proc_LBracket
    Do_Key 0x20, 0x60, 0x82

Proc_RBracket
    Do_Key 0x22, 0x62, 0xB6

Proc_KPstar
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _PrtScr
    retlw 0x07
_PrtScr
    movlw 0x64
    btfss KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0xA4
    goto FullKey
Proc_KPperiod
    movlw 0xB4
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Del
    btfsc KBDmeta,pcAltCtrl            ; Skip if we don't have Alt+Ctrl
    goto Proc_F8
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x22
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x22
    goto FullKey
_Del
    btfsc KBDmeta,pcAltCtrl            ; Skip if we don't have Alt+Ctrl
    goto Proc_F8
    Do_Key 0x34, 0xB4, 0x74
Proc_KP0
    movlw 0x77
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Ins
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x32
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x32
    goto FullKey
_Ins
    Do_Key 0x04, 0xB7, 0x77
Proc_KP1
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _End
    movlw 0x1F
    btfsc Locks,_NumLock               ; Skip if _NumLock inactive
    goto FullKey
    AllKey 0x54, 0x1F, 0xD4, 0x71
_End
    Do_Key 0x14, 0x54, 0xC4
Proc_KP2
    movlw 0x8F
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Arrow
_KPdown
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x1E
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x1E
    goto FullKey
Proc_KP3
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _PgDn
    movlw 0x1A
    btfsc Locks,_NumLock               ; Skip if _NumLock inactive
    goto FullKey
    AllKey 0x44, 0x1A, 0x9A, 0xDA
_PgDn
    Do_Key 0x04, 0x44, 0x9A
Proc_KP4
    movlw 0x86
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Arrow
_KPleft
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x18
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x18
    goto FullKey
Proc_KP5
    movlw 0x1D
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Omni                         ; Northgate Omni Keyboard (and others?)
    btfsc Locks,_NumLock               ; Skip if _NumLock inactive
    goto FullKey
    btfss KBDmeta,pcShift              ; Skip if pcShift active
    goto NullKey
    goto FullKey
_Omni
    retlw 0x31
Proc_KP6
    movlw 0x87
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Arrow
_KPright
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x1B
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x1B
    goto FullKey
Proc_KP7
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Home
    movlw 0x33
    btfsc Locks,_NumLock               ; Skip if _NumLock inactive
    goto FullKey
    AllKey 0x53, 0x33, 0xB3, 0xF1
_Home
    Do_Key 0x13, 0x53, 0x76
Proc_KP8
    movlw 0x8E
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _Arrow
_KPup
    btfsc Locks,_NumLock               ; Skip if NumLock inactive
    movlw 0x35
    btfsc KBDmeta,pcShift              ; Skip if pcShift inactive
    movlw 0x35
    goto FullKey
Proc_KP9
    btfsc Flags,ExtKey                 ; Skip if not an extended key
    goto _PgUp
    movlw 0x30
    btfsc Locks,_NumLock               ; Skip if _NumLock inactive
    goto FullKey
    AllKey 0x43, 0x30, 0xB0, 0xF0
_PgUp
    Do_Key 0x03, 0x43, 0x03
_Arrow
    btfsc KBDmeta,pcCtrl
    andlw 0x7F
    goto FullKey
Proc_F1
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    retlw 0x03
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    movlw low HM1
    call Play_HardMac
    goto NullKey
Proc_F2                                ; Place holder for possible code
Proc_F3                                ; Place holder for possible code
Proc_F4
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    retlw 0x14
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    movf Macro_Ptr,W
    andlw 0x0F
    btfsc STATUS,Z
    goto Do_Macro4
    movf Macro_Ptr,W
    andlw 0x3F
    movwf EEADR                        ; Set EEPROM address
    movlw 0xFF                         ; Load End of Macro
    call Write_EE
Do_Macro4
    clrf Macro_Ptr
    goto NullKey
Proc_F5
    bsf _Start                         ; Set _Start active
    btfss Flags,KeyUp                  ; Skip if key released
    bcf _Start                         ; Set _Start inactive
    goto NullKey
Proc_F6
    bsf _Select                        ; Set _Select active
    btfss Flags,KeyUp                  ; Skip if key released
    bcf _Select                        ; Set _Select inactive
    goto NullKey
Proc_F7
    bsf _Option                        ; Set _Option active
    btfss Flags,KeyUp                  ; Skip if key released
    bcf _Option                        ; Set _Option inactive
    goto NullKey
Proc_F8
    btfss Flags,KeyUp                  ; Skip if key released
    goto Set_Reset
    bsf _Reset                         ; Set _Reset high (off)
    goto NullKey
Set_Reset
    bcf _Reset                         ; Set _Reset low (on)
    bcf PA_Shadow,RA0
    btfss KBDmeta,pcCtrl
    bsf PA_Shadow,RA0
    movf PA_Shadow,W
    movwf PORTA                        ; Set PORTA
    goto NullKey
Proc_F9
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    retlw 0x29
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    btfsc KBDmeta,pcCtrl
    goto Rec_Macro1
    movlw 0x01
    call Play_Macro
    goto NullKey
Rec_Macro1
    movlw 0x81
    movwf Macro_Ptr
    goto NullKey
Proc_F10
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    retlw 0x11
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    btfsc KBDmeta,pcCtrl
    goto Rec_Macro2
    movlw 0x11
    call Play_Macro
    goto NullKey
Rec_Macro2
    movlw 0x91
    movwf Macro_Ptr
    goto NullKey
Proc_F11
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    retlw 0x27
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    btfsc KBDmeta,pcCtrl
    goto Rec_Macro3
    movlw 0x21
    call Play_Macro
    goto NullKey
Rec_Macro3
    movlw 0xA1
    movwf Macro_Ptr
    goto NullKey
Proc_F12
    btfss KBDmeta,pcAlt                ; Skip if pcAlt active
    goto Set_Break
    btfss Flags,KeyUp                  ; Skip if key released
    goto NullKey
    btfsc KBDmeta,pcCtrl
    goto Rec_Macro4
    movlw 0x31
    call Play_Macro
    goto NullKey
Rec_Macro4
    movlw 0xB1
    movwf Macro_Ptr
    goto NullKey
Set_Break
    bcf POKEY_Meta,_Break
    btfss Flags,KeyUp                  ; Skip if key released
    bsf POKEY_Meta,_Break
    goto NullKey
Proc_SysRq
    movlw 0xE4
    goto FullKey
Set_KBCLKout
    bsf STATUS,RP0                     ; Set Register Bank 1
    bcf KBCLK                          ; Set KBCLK as output
    bcf STATUS,RP0                     ; Set Register Bank 0
    bcf KBCLK                          ; Set KBCLK low
    return
Set_KBCLKin
    bsf STATUS,RP0                     ; Set Register Bank 1
    bsf KBCLK                          ; Set KBCLK as input
    bcf STATUS,RP0                     ; Set Register Bank 0
    bsf KBCLK                          ; 
    goto SetKBDvars
;   return                             ; unreachable
GetKBDbyte
    movlw 0x20
    movwf Temp2
    clrwdt
_Loop
    btfsc KBDbitcnt,7                  ; Skip if KBDbitcnt hasn't gone negative
    goto FixKBDbyte
    decfsz Temp1,F
    goto _Loop
    decfsz Temp2,F
    goto _Loop
    bcf PORTA,RA1                      ; Clock cycle waste?
    bsf PORTA,RA1                      ; Clock cycle waste?
    goto GetKBDbyte
FixKBDbyte
    rlf KBDbuff2,F                     ; Roll the data 2 bits left, to frame
    rlf KBDbuff1,F                     ; the data as a single byte
    rlf KBDbuff2,F
    rlf KBDbuff1,W
    movwf KBDbyte
SetKBDvars
    movlw 0x0A                         ; MF2 clock count - 1
    movwf KBDbitcnt                    ; Set KBD bit count
    movlw 0xFF
    movwf TMR0                         ; Load TMR0 so next tick becomes 0x00
    bcf INTCON,T0IF
    bsf INTCON,T0IE
    movf KBDbyte,W                     ; 
    return
Play_HardMac
    movwf EEADR                        ; Store macro position
    call Set_KBCLKout
Loop_HardMac
    movf EEADR,W                       ; Read macro position
    call Hard_Macro
    movwf FSR
    xorlw 0xFF
    btfsc STATUS,Z
    goto End_HardMac
    movf FSR,W
    xorlw 0xFE
    btfsc STATUS,Z
    goto Delay_HardMac
    call Put_Key
Inc_HMptr
    incf EEADR,F                       ; Next EEPROM address
    goto Loop_HardMac
End_HardMac
    movlw 0xFF
    movwf AtariCode
    bsf POKEY_Meta,_Break
    call Pause
    bcf POKEY_Meta,_Break
    call Set_KBCLKin
    return
Delay_HardMac
    movlw 0x48
    call Delay
    goto Inc_HMptr
Put_Key
    bcf POKEY_Meta,_Shift
    bcf POKEY_Meta,_Ctrl
    btfsc FSR,Ctrl
    bsf POKEY_Meta,_Ctrl
    btfsc FSR,Shift
    bsf POKEY_Meta,_Shift
    movf FSR,W
    andlw 0x3F
    xorlw 0x3F
_Put_Key
    movwf AtariCode
Pause
    movlw 0x03
Delay
    movwf Timer
_Delay
    btfss Timer,7
    goto _Delay
    return
Play_Macro
    movwf Temp1
    movlw 0xFF
    movwf Temp2
    call Set_KBCLKout
MacroLoop
    movf Temp1,W
    call Read_EE
    movwf FSR
    xorlw 0xFF
    btfsc STATUS,Z
    goto End_Macro
    movf FSR,W
    xorwf Temp2,W
    btfss STATUS,Z
    goto _Macro
    movlw 0xFF
    movwf AtariCode
    movlw 0x0D
    call Delay
_Macro
    movf FSR,W
    movwf Temp2
    call Put_Key
    incf Temp1,F
    movf Temp1,W
    andlw 0x0F
    btfss STATUS,Z
    goto MacroLoop
End_Macro
    movlw 0xFF
    movwf AtariCode
    clrf POKEY_Meta
    call Set_KBCLKin
    return

    End
