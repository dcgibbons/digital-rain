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

DEFAULT_IRQ_HANDLER := $EA31

.segment  "CODE"
.org      $080E
main:
  jsr init_raster

  ; PRINT "HELLO WORLD" (Just to prove it works!)
  ldy #0
@print_msg:
  lda msg_hello, y
  beq @done
  jsr CHROUT
  iny
  jmp @print_msg

@done:

main_loop:
  jmp main_loop

init_raster:
  sei                   ; disable interrupts

  ldy #%01111111
  sta CIA1_ICR          ; turn off CIA 1 interrupts
  sta CIA2_ICR          ; turn off CIA 2 interrupts
  lda CIA1_ICR          ; acknowledge any pending CIA 1 interrupts
  lda CIA2_ICR          ; acknowledge any pending CIA 2 interrupts

  lda #$01
  sta VIC_IMR           ; enable raster interrupt signals from VIC-II

  lda #$fa              ; set trigger line to 250 (bottom of screen)
  sta VIC_HLINE

  lda VIC_CTRL1         ; clear the high bit of the raster line
  ldy #%01111111
  sta VIC_CTRL1 

  ; set IRQ handler address
  lda #<irq_handler
  sta IRQVec
  lda #>irq_handler
  sta IRQVec+1

  cli
  rts

irq_handler:
  ; acknowledge the interrupt
  lda #$01
  sta VIC_IRR

  jsr animate_frame

  jmp DEFAULT_IRQ_HANDLER

animate_frame:
  inc frame_count

  lda #0
  ldx #0
  ldy #0
  clc
  jsr PLOT

  lda frame_count
  jsr CHROUT

  rts

.segment "ZEROPAGE"
  frame_count: .res 1

; --- Read-only DATA ---
.segment "RODATA"

msg_hello:
  scrcode "hello world!!1! aaaa"
  .byte 0
