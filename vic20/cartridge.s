; ---------------------------------------------------------------------------
; cart.s - Cartridge Binary Support
; Digital Rain on the Commodore VIC-20
;

; ---------------------------------------------------------------------------
; Includes from the CC65 package
;
.include "cbm.mac"
.include "cbm_kernal.inc"
.include "vic20.inc"

.import main

.ifdef CART_BUILD
; ---------------------------------------------------------------------------
; Cartridge Header - VIC-20 Kernal looks at $A000 for this signature. If
; found, control is transferred directly to the cold start vector address
; instead of BASIC.
;
.segment "CARTHDR"
cartridge_header:
  .word cold_start            ; Cold start vector (2 bytes, little-endian)
  .word warm_start            ; Warm start vector (2 bytes, little-endian)
  .byte $41,$30,$C3,$C2,$CD   ; "A0" + reversed "CBM" signature (5 bytes)

.segment "CODE"
cold_start:
warm_start:
  sei                   ; Disable interrupts
  cld                   ; Clear decimal mode

  ldx #$FF              ; Set stack pointer to $01FF
  txs

  jsr RAMTAS            ; RAMTAS: Initialize RAM, test memory, set pointers
  jsr RESTOR            ; RESTOR: Restore default KERNAL vectors
  jsr IOINIT            ; IOINIT: Initialize I/O devices (CIA, VIA, etc.)
  jsr CINT              ; CINT: Initialize screen editor and VIC chip

  cli                   ; Re-enable interrupts

  jmp main            ; Jump to main code
.endif

