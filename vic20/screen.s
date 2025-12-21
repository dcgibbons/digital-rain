; ---------------------------------------------------------------------------
; screen.s - Screen Manipulation for the VIC-20 Matrix-like Effect
; Digital Rain on the Commodore VIC-20
;

.export init_video
.export wait_for_frame
; .export init_pointers
; .export detect_video_type
; .export clear_color_ram
; .export clear_screen
; .export copy_chars
; .export patch_char
; .export enable_ram_fonts

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

; ---------------------------------------------------------------------------
; Screen Constants
;
SCREEN_ROWS         = 23        ; Total height
SCREEN_WIDTH        = 22        ; Total width

CHAR_ROM            = $8000     ; Standard Character ROM
CHAR_ROM_LOWER      = $8800     ; Lowercase Chafacter ROM
CHAR_RAM            = $1400     ; Our Safe RAM destination

; ---------------------------------------------------------------------------
; VIC-20 Kernal Memory Locations not defined above
;
SCREEN_PAGE         := $0288    ; Location where the page # of the screen
                                ; memory is stored by the Kerna
                                
; ---------------------------------------------------------------------------
; Additional VIC IC constants not defined above
;
VIC_COLOR_NORMAL    = $08       ; Bitmask for setting standard colors
VIC_BLACK           = $0
VIC_WHITE           = $1
VIC_RED             = $2
VIC_CYAN            = $3
VIC_PURPLE          = $4
VIC_GREEN           = $5
VIC_BLUE            = $6
VIC_YELLOW          = $7
; extended colors for auxiliary and screen
VIC_ORANGE          = $8
VIC_LIGHT_ORANGE    = $9
VIC_PINK            = $A
VIC_LIGHT_CYAN      = $B
VIC_LIGHT_PURPLE    = $C
VIC_LIGHT_GREEN     = $D
VIC_LIGHT_BLUE      = $E
VIC_LIGHT_YELLOW    = $F
VIC_PTR             = VIC_CR5
VIC_RASTER          = VIC_CR4   ; VIC control register for the current raster

.segment "CODE"

init_video:
  pha

  jsr init_pointers
  jsr detect_video_type
  jsr clear_color_ram
  jsr clear_screen
  jsr copy_chars
  jsr patch_char
  jsr enable_ram_fonts

  ; set background & border color
  lda #((VIC_BLACK << 4) | VIC_COLOR_NORMAL | VIC_BLACK)
  sta VIC_COLOR

  ; set text color
  lda #VIC_GREEN
  sta CHARCOLOR

  pla
  rts

; ---------------------------------------------------------------------------
; Clears Screen RAM
;
clear_screen:
  lda ptr_screen + 1        ; save high byte of ptr_screen to restore after
  pha

  lda #32                   ; Space Character
  ldx #2                    ; 2 pages worth
  ldy #0                    ; byte offset within page
@clear_screen_outer:

@clear_screen_inner:
  sta (ptr_screen), y
  iny
  bne @clear_screen_inner

  ; end of page!
  inc ptr_screen + 1
  dex
  bne @clear_screen_outer

  pla                     ; restore high byte of ptr_screen
  sta ptr_screen + 1
  rts

; ---------------------------------------------------------------------------
; Detects Video Type (NTSC or PAL) and updates frame target appropriately
;
detect_video_type:
  pha
  lda VIC_CR2
  and #%10000000          ; bit 7: 0 = NTSC, 1 = PAL
  bne @set_pal
@set_ntsc:
  lda #5
  jmp @set_target
@set_pal:
  lda #4
@set_target:
  sta frame_target
  pla
  rts

; ---------------------------------------------------------------------------
; Clears Color Ram
;
clear_color_ram:
  lda ptr_color + 1       ; save high byte of ptr_color to restore after
  pha

  lda #VIC_BLACK
  ldx #2                  ; 2 pages worth
  ldy #0                  ; byte offset within page
@clear_color_loop_outer:

@clear_color_loop_inner:
  sta (ptr_color), y
  iny
  bne @clear_color_loop_inner

  ; end of page!
  inc ptr_color + 1
  dex
  bne @clear_color_loop_outer

  pla                     ; restore high byte of ptr_color
  sta ptr_color + 1
  rts
 
; ---------------------------------------------------------------------------
; Copy Character Set from ROM ($8000 or $8800) to RAM ($1400)
; Copies 8 pages (2048 bytes)
;
copy_chars:
  pha
  txa
  pha
  ldx #0                ; Index

  ; We use self-modifying code or pointers here.
  ; Since we are in 6502, let's use a ZP pointer for the source/dest
  ; to keep it clean, OR just hardcode the base addresses since they are fixed.
  ; Hardcoding is faster here.

@copy_loop_page_1:
  lda CHAR_ROM_LOWER, x
  sta CHAR_RAM, x
  lda CHAR_ROM_LOWER + $100, x
  sta CHAR_RAM + $100, x
  lda CHAR_ROM_LOWER + $200, x
  sta CHAR_RAM + $200, x
  lda CHAR_ROM_LOWER + $300, x
  sta CHAR_RAM + $300, x
  lda CHAR_ROM_LOWER + $400, x
  sta CHAR_RAM + $400, x
  lda CHAR_ROM_LOWER + $500, x
  sta CHAR_RAM + $500, x
  lda CHAR_ROM_LOWER + $600, x
  sta CHAR_RAM + $600, x
  lda CHAR_ROM_LOWER + $700, x
  sta CHAR_RAM + $700, x

  dex
  bne @copy_loop_page_1

  pla
  tax
  pla
  rts
  
; ---------------------------------------------------------------------------
; Patch character map with custom data
; ---------------------------------------------------------------------------
patch_char:
  ldx #0
patch_loop:
  lda character_data, x
  sta CHAR_RAM+$300, x; offset 96*8 = start of PETSCII graphics 
  inx
  cpx #128        ; 16 chars * 8 bytes = 128 bytes
  bne patch_loop
  rts

; ---------------------------------------------------------------------------
; Initialize Zero Page pointers to Screen and Color RAM based upon the
; hardware configuration.
;
init_pointers:
  ; --- 1. SET LOW BYTES ---
  ; On VIC-20, Screen and Color blocks always start at xx00.
  lda #0
  sta ptr_screen
  sta ptr_color

  ; --- 2. CALCULATE SCREEN HIGH BYTE ---
  lda SCREEN_PAGE
  sta ptr_screen + 1

calc_color:
  ; --- 4. CALCULATE COLOR HIGH BYTE ---
  ; Default to $94 (Lower Half)
  lda #$94
  sta ptr_color + 1

  ; Check that same Bit 9 again
  lda VIC_CR2
  bpl @done_init       ; If Bit 7 is 0, Color RAM is $9400. Done.

  ; If Bit 7 is 1, Color RAM must be $9600.
  inc ptr_color + 1   ; $94 -> $95
  inc ptr_color + 1   ; $95 -> $96

@done_init:
  rts
  
enable_ram_fonts:
  pha
  ; Address $0291 (657) controls the charset switching logic.
  ; Setting Bit 7 ($80) tells the OS: "Do not touch the charset pointer."
  lda #$80          ; 128
  sta $0291         ; Lock it!

  ; --- Tell the VIC to use RAM fonts ---
  ; The register VIC_CR5 ($9005) holds:
  ; High Nibble: Screen Address (We must preserve this!)
  ; Low Nibble:  Character Address (We want to set this to 5 for $1400)
  lda VIC_PTR       ; Read current value (e.g., $F0 or $10)
  and #%11110000    ; Mask out the old character pointer (Keep screen bits)
  ora #%1101        ; $D = $1400
  sta VIC_PTR       ; Update hardware
  pla
  rts
  
; ---------------------------------------------------------------------------
; Sync to the Vertical Blank
;
wait_for_frame:
  lda VIC_RASTER
  cmp #130 ; 130 is near the bottom of the screen
  beq wait_for_frame
@wait_step2:
  lda VIC_RASTER
  cmp #130
  bne @wait_step2
  rts

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