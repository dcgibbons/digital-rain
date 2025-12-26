; ---------------------------------------------------------------------------
; screen.s - Screen Manipulation for the VIC-20 Matrix-like Effect
; Digital Rain on the Commodore 64
;

.export init_video
.export wait_for_frame

; ---------------------------------------------------------------------------
; Includes from the CC65 package
;
.include "cbm.mac"
.include "cbm_kernal.inc"
.include "c64.inc"

; ---------------------------------------------------------------------------
; Local includes
.include "globals.inc"
.include "vic-ii_colors.inc"

DEFAULT_IRQ_HANDLER := $EA31
SCREEN_RAM          := $0400
COLOR_RAM           := $D800

.segment "CODE"
; ---------------------------------------------------------------------------
; Initializes the video memory and fonts for this application.
;
init_video:
  jsr detect_video_type
  jsr clear_color_ram
  jsr clear_screen

  ; set background & border color
  lda #VIC_BLACK
  sta VIC_BORDERCOLOR
  lda #VIC_BLACK
  sta VIC_BG_COLOR0

  ; set text color
  lda #VIC_GREEN
  sta CHARCOLOR

  rts

; ---------------------------------------------------------------------------
; Clears Screen RAM
;
clear_screen:
  pha
  txa
  pha

  ldx #0
  lda #$20
@clear_screen_loop:
  sta SCREEN_RAM, x
  sta SCREEN_RAM + 250, x
  sta SCREEN_RAM + 500, x
  sta SCREEN_RAM + 750, x
  dex
  bne @clear_screen_loop

  pla
  tax
  pla
  rts

; ---------------------------------------------------------------------------
; Clears Color Ram
;
clear_color_ram:
  rts

; ---------------------------------------------------------------------------
; Detects Video Type (NTSC or PAL) and updates frame target appropriately
;
detect_video_type:
  pha
  lda PALFLAG
  bne @set_pal

  ; Aim for 1/12th of a second updates regardless if NTSC or PAL
@set_ntsc:
  lda #5                ; 60 * (1/12) ~= 5
  jmp @set_target
@set_pal:
  lda #4                ; 50 * (1/12) ~= 4

@set_target:
  sta frame_target
  pla
  rts

; ---------------------------------------------------------------------------
; Sync to the Vertical Blank
;
wait_for_frame:
  pha

@wait:
  lda VIC_HLINE
  cmp #250
  bne @wait

  pla
  rts

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

  ;cli
  rts

irq_handler:
  ; acknowledge the interrupt
  lda #$01
  sta VIC_IRR

  jsr animate_frame

  jmp DEFAULT_IRQ_HANDLER

animate_frame:
  ;inc frame_count
  rts

  ; lda #0
  ; ldx #0
  ; ldy scroll_y
  ; clc
  ; jsr PLOT

  ; lda frame_count
  ; jsr CHROUT

  ; ; jsr do_scroll
  ; rts

; do_scroll:
;   inc scroll_y
;   lda scroll_y
;   cmp #8                ; have we shifted 8 pixels?
;   bne @apply_scroll

;   ; reset cycle (course scroll)
;   lda #0
;   sta scroll_y
;   jsr shift_screen_down
;   jsr draw_new_top_row

; @apply_scroll:
;   lda VIC_CTRL1
;   and #%11111000
;   ora scroll_y
;   sta VIC_CTRL1
;   rts

; shift_screen_down:
;   rts

; draw_new_top_row:
; rts