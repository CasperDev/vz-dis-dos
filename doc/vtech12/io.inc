/***********************************************************
 * 
 *  Laser 210/VZ210 ROM 1+2
 *  -----------------------
 *  Input/Output Interface
 *
 *  Various Sources
 ***********************************************************/

; Hardware Output Register for Gfx Mode, Speaker and Cassette Out
; bit 5 - Speaker Out (-)
; bit 4 - MC6847 CSS pin - COLOR 0 (Green) or 1 (Orange)
; bit 3 - MC6847 AG pin - MODE 0 or 1
; bit 2 - Cassette Out (-) N/C
; bit 1 - Cassette Out (+)
; bit 0 - Speaker Out (+)
IO_LATCH      equ $6800   ; (byte) write only, used bits 5-0 

CassIn       equ $6800   ; (bit 6) read only [shared with Keyboard Matrix]
INTLineIn    equ $6800   ; (bit 7) read only [shared with Keyboard Matrix]
    
