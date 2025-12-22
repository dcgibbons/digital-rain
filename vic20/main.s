; ---------------------------------------------------------------------------
; main.s - main program logic
; Digital Rain on the Commodore VIC-20
;

; ---------------------------------------------------------------------------
; Includes from the CC65 package
;
.include "cbm.mac"
.include "cbm_kernal.inc"
.include "vic20.inc"

; ---------------------------------------------------------------------------
; Local includes
;
.include "macros.inc"
.include "globals.inc"
.include "rand.inc"
.include "screen.inc"
.include "trails.inc"
.include "vic_colors.inc"

; ---------------------------------------------------------------------------
; Zero Page Variable Allocations
;
.segment "ZEROPAGE"
frame_count: .res 1     ; current frame count for updates

.segment "CODE"
; ---------------------------------------------------------------------------
; Main Program
;
.export main
main:
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

  ; create any new trails if needed
  jsr create_trail

@do_updates:
  ; animate all existing trails
  jsr update_trails
@no_update:
  jmp @main_loop