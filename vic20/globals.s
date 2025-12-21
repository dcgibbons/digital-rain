; ---------------------------------------------------------------------------
; globals.s - Global Variables
; Digital Rain on the Commodore VIC-20
;

.include "globals.inc"

.segment "ZEROPAGE"
frame_target:       .res 1  ; our target frame count for updates
ptr_screen:         .res 2  ; pointer to screen memory in this configuration
ptr_color:          .res 2  ; pointer to color memory in this configuration