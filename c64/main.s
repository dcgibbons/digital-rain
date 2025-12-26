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

; ---------------------------------------------------------------------------
; Local Includes
;
.include "globals.inc"
.include "rand.inc"
.include "screen.inc"
.include "trails.inc"
.include "vic-ii_colors.inc"

SCREEN_RAM          := $0400
COLOR_RAM           := $D800

.segment  "CODE"
.org      $080E
main:
  sei                   ; disable interrupts to prevent ZP corruption
  jsr init_rng          ; initialize random number generator
  jsr init_trails       ; setup trails
  jsr init_video        ; setup video

  ; The main loop waits for the vertical raster (either 60 / 50 Hz) and then
  ; increments a frame counter. If the frame counter is equal to our frame
  ; target - a global set by screen.s - then we do a trails update.
  lda #0
  sta frame_count
@main_loop:
  jsr wait_for_frame
  inc frame_count
  lda frame_count
  cmp frame_target
  bne @no_update

  ; reset the frame counter 
  lda #0
  sta frame_count

  jsr create_trail
  jsr update_trails

@no_update:
  jmp @main_loop

.segment "DATA"
frame_count: .byte $00