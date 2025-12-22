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
; Zero Page Variable Allocations - Since we aren't using BASIC at all we can
; take over most of the zeropage storage for our own needs.
;
.segment "ZEROPAGE"
frame_count: .res 1     ; current frame count for updates

; ---------------------------------------------------------------------------
; Header and Startup
;
.ifdef PRG_BUILD
; BASIC Stub for PRG
; 10 SYS 4109  (4109 = $100D)
.segment "LOADADDR"
  .word $1001           ; Load Address

.segment "STARTUP"
  .word @next_line      ; Next line link
  .word 10              ; Line number
  .byte $9E, "4109", 0  ; SYS 4109
@next_line:
  .word 0               ; End of BASIC program

.segment "CODE"
prg_start:
  sei                   ; Disable interrupts
  cld                   ; Clear decimal mode
    
  ldx #$FF              ; Set stack pointer to $01FF
  txs

  ; For PRG, we assume the system is already initialized by BASIC.
  ; We skip RAMTAS/RESTOR to avoid memory clearing.
  ; We proceed directly to main initialization.

  ; fall-through to the main code
  ; jmp main            ; Jump to main code

.else
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

  ; fall-through to the main code
  ; jmp main            ; Jump to main code
.endif

; ---------------------------------------------------------------------------
; Main Program
;
main:
  jsr init_rng      ; initialize random number generator
  jsr init_trails   ; setup trails
  jsr init_video    ; setup video

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

  lda #0
  sta frame_count

  ; create any new trails if needed
  jsr create_trail

@do_updates:
  ; animate all existing trails
  jsr update_trails
@no_update:
  jmp @main_loop