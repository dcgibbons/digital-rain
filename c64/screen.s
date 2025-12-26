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
CUSTOM_CHARSET_ADDR := $3000

.segment "CODE"
; ---------------------------------------------------------------------------
; Initializes the video memory and fonts for this application.
;
init_video:
  jsr detect_video_type
  jsr clear_screen
  jsr setup_custom_font

  ; set background & border color
  lda #VIC_BLACK
  sta VIC_BORDERCOLOR
  lda #VIC_BLACK
  sta VIC_BG_COLOR0

  ; set text color
  lda #VIC_GREEN
  sta CHARCOLOR

  ; Configure VIC-II Memory Pointers in $D018
  ; Screen RAM: $0400 (Top 4 bits = 1 -> $10)
  ; Charset: CUSTOM_CHARSET_ADDR ($3000)
  ; Formula: (Screen / $0400) << 4 | (Charset / $0800) << 1
  ;
  ; Calculating Charset part:
  ; $3000 / $0800 = 6. 6 << 1 = 12 ($0C).
  ; $10 | $0C = $1C.
  
  lda #$1C              ; Screen $0400, Charset $3000
  sta VIC_VIDEO_ADR     ; Store in VIC Memory Control Register

  rts

; ---------------------------------------------------------------------------
; Sets up the custom font by copying from RODATA to RAM
;
setup_custom_font:
  ; 1. Clear the font area (2KB) to be safe (blank characters)
  lda #0
  tax
@clear_loop_1:
  sta CUSTOM_CHARSET_ADDR, x
  sta CUSTOM_CHARSET_ADDR + $0100, x
  sta CUSTOM_CHARSET_ADDR + $0200, x
  sta CUSTOM_CHARSET_ADDR + $0300, x
  sta CUSTOM_CHARSET_ADDR + $0400, x
  sta CUSTOM_CHARSET_ADDR + $0500, x
  sta CUSTOM_CHARSET_ADDR + $0600, x
  sta CUSTOM_CHARSET_ADDR + $0700, x
  inx
  bne @clear_loop_1

  ; 2. Copy defined characters
  ldx #0
@copy_loop_1:
  lda character_data, x
  sta CUSTOM_CHARSET_ADDR, x
  lda character_data + 256, x       ; Handle overflow for > 256 bytes
  sta CUSTOM_CHARSET_ADDR + 256, x
  inx
  bne @copy_loop_1 
  
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


.segment "RODATA"
; ===========================================================================
; Glyph Data
; Style: Mirrored Katakana & Cryptic Glyphs
; Format: 8 bytes per character
; ===========================================================================
character_data:
  ; Char 0: Mirrored TE (テ)
  ; Looks like: Glitchy T
  .byte $7C, $00, $7C, $10, $10, $08, $04, $00

  ; Char 1: Mirrored KU (ク)
  ; Looks like: A cybernetic '7'
  .byte $38, $0C, $04, $04, $06, $0C, $38, $00

  ; Char 2: Mirrored SU (ス)
  ; Looks like: A running man or lightning bolt
  .byte $7E, $02, $04, $08, $10, $24, $18, $00

  ; Char 3: Mirrored MU (ム)
  ; Looks like: A geometric triangle/arrow
  .byte $08, $14, $22, $41, $40, $22, $1C, $00

  ; Char 4: Mirrored KO (コ)
  ; Looks like: A hard bracket or C
  .byte $3E, $20, $20, $20, $20, $20, $3E, $00

  ; Char 5: Mirrored RA (ラ)
  ; Looks like: A top connector with a hanging wire
  .byte $3E, $02, $04, $00, $1C, $04, $04, $00

  ; Char 6: Mirrored ME (メ)
  ; Looks like: A crossed sensor
  .byte $42, $24, $18, $18, $24, $42, $00, $00

  ; Char 7: Mirrored HI (ヒ)
  ; Looks like: A chair or abstract h
  .byte $0E, $04, $04, $7C, $44, $44, $00, $00

  ; Char 8: Mirrored U (ウ)
  ; Looks like: A vertical logic gate
  .byte $08, $3E, $04, $04, $04, $04, $08, $10

  ; Char 9: Mirrored NE (ネ)
  ; Looks like: A heavy anchor or root
  .byte $08, $1C, $08, $3E, $04, $08, $14, $22

  ; Char 10: Mirrored HE (ヘ)
  ; Looks like: A mountain/arrow up
  .byte $00, $08, $14, $22, $41, $00, $00, $00

  ; Char 11: Mirrored KE (ケ)
  ; Looks like: A connector joint
  .byte $18, $24, $42, $42, $7E, $02, $02, $00

  ; Char 12: Mirrored YA (ヤ)
  ; Looks like: A tilted cross-brace
  .byte $0C, $14, $24, $44, $1C, $04, $04, $00

  ; Char 13: Mirrored YO (ヨ)
  ; Looks like: A reverse E / Data stack
  .byte $3E, $20, $20, $3E, $20, $20, $3E, $00

  ; Char 14: GLITCH 1 (Signal Noise)
  ; Looks like: Three horizontal dashes (The classic Matrix "Mi")
  .byte $00, $54, $28, $00, $54, $28, $00, $00

  ; Char 15: GLITCH 2 (Cursor/Block)
  ; Looks like: A hollow data packet
  .byte $00, $3C, $24, $24, $24, $3C, $00, $00

  ; Char 16: 0
  .byte $3C, $42, $42, $42, $42, $42, $3C, $00

  ; Char 17: 1
  .byte $08, $18, $28, $08, $08, $08, $3E, $00

  ; Char 18: 2
  .byte $3C, $42, $02, $0C, $30, $40, $7E, $00

  ; Char 19: 3
  .byte $3C, $42, $02, $1C, $02, $42, $3C, $00

  ; Char 20: 4
  .byte $0C, $14, $24, $44, $7E, $04, $04, $00

  ; Char 21: 5
  .byte $7E, $40, $7C, $02, $02, $42, $3C, $00

  ; Char 22: 6
  .byte $3C, $40, $7C, $42, $42, $42, $3C, $00

  ; Char 23: 7
  .byte $7E, $02, $04, $08, $10, $20, $20, $00

  ; Char 24: 8
  .byte $3C, $42, $42, $3C, $42, $42, $3C, $00

  ; Char 25: 9
  .byte $3C, $42, $42, $42, $3E, $02, $3C, $00

  ; Char 26: +
  .byte $00, $18, $18, $7E, $18, $18, $00, $00

  ; Char 27: -
  .byte $00, $00, $00, $7E, $00, $00, $00, $00

  ; Char 28: =
  .byte $00, $00, $7E, $00, $7E, $00, $00, $00

  ; Char 29: (
  .byte $0C, $18, $30, $30, $30, $18, $0C, $00

  ; Char 30: )
  .byte $30, $18, $0C, $0C, $0C, $18, $30, $00

  ; Char 31: {
  .byte $0C, $18, $18, $30, $18, $18, $0C, $00

  ; Char 32: Space (Replaced } to fix background)
  .byte $00, $00, $00, $00, $00, $00, $00, $00

  ; Char 33: |
  .byte $18, $18, $18, $18, $18, $18, $18, $00

  ; Char 34: <
  .byte $06, $18, $60, $60, $18, $06, $00, $00

  ; Char 35: >
  .byte $60, $18, $06, $06, $18, $60, $00, $00

  ; Char 36: ?
  .byte $3C, $42, $04, $08, $10, $00, $10, $00

  ; Char 37: .
  .byte $00, $00, $00, $00, $00, $18, $18, $00

  ; Char 38: /
  .byte $02, $06, $0C, $18, $30, $60, $40, $00

  ; Char 39: } (Moved from 32)
  .byte $30, $18, $18, $0C, $18, $18, $30, $00