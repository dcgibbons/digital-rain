; ---------------------------------------------------------------------------
; main.s - Main Program
; Digital Rain on the Commodore 64
;

; ---------------------------------------------------------------------------
; Includes from the CC65 package
;
.include "cbm.mac"
.include "cbm_kernal.inc"
.include "c64.inc"

.segment  "CODE"
.org      $080E
main:
  rts