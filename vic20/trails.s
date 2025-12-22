; ---------------------------------------------------------------------------
; trails.s - Trail Management for the Matrix-like Effect
; Digital Rain on the Commodore VIC-20
;

.include "cbm.mac"
.include "cbm_kernal.inc"
.include "vic20.inc"

.include "macros.inc"
.include "globals.inc"
.include "rand.inc"
.include "vic_colors.inc"

.export init_trails
.export create_trail
.export update_trails

; ---------------------------------------------------------------------------
; Screen Constants
;
SCREEN_ROWS     = 23    ; Total height
SCREEN_WIDTH    = 22    ; Total width

; -- structure to represent a trail:
TRAIL_COLUMN    = 0     ; byte
TRAIL_HEAD      = 1     ; byte
TRAIL_LENGTH    = 2     ; byte
TRAIL_ACTIVE    = 3     ; Byte
TRAIL_SIZE      = 4     ; Bytes per struct

MAX_TRAILS      = SCREEN_WIDTH + 10
DEFAULT_LENGTH  = 13

.segment "TRAIL_DATA"
TRAILS_RAM: .res 256

.segment "ZEROPAGE"
ptr_trail_offset: .res 2  ; 16-bit offset into screen & color ram for trail
ptr_trail_screen: .res 2  ; pointer to current trail drawing location
ptr_trail_color:  .res 2  ; pointer to curent trail color location
ptr_trail:        .res 2  ; pointer to current trail
temp:             .res 2  ; temporary work storage

.segment "CODE"
; ---------------------------------------------------------------------------
; initializes the trails data structures
;
init_trails:
  pha
  txa
  pha
  tya
  pha
  
  ; TODO - replace this with a generic memset-like call to zero out the block?
  ldx #0
@loop:
  txa 
  calc_trail_ptr ptr_trail, TRAILS_RAM
  
  ldy #0
  lda #0
  sta (ptr_trail), y
  iny
  sta (ptr_trail), y
  iny
  sta (ptr_trail), y
  iny
  sta (ptr_trail), y
  
  ; next X
  inx
  cpx #MAX_TRAILS
  bne @loop

  pla
  tay
  pla
  tax
  pla
  rts

; ---------------------------------------------------------------------------
; Spawn a new trail, if there are any slots available
;
create_trail:
  pha
  txa
  pha
  tya
  pha
  
  ldx #0
@loop:
  txa  
  calc_trail_ptr ptr_trail, TRAILS_RAM 
  
  ldy #TRAIL_ACTIVE
  lda (ptr_trail), y
  beq @found_inactive_trail

  ; next X
  inx
  cpx #MAX_TRAILS
  bne @loop 
  beq @done

@found_inactive_trail:
@pick_random:
  jsr get_rand
  and #%00011111        ; mask to 0-31
  cmp #SCREEN_WIDTH
  bcs @pick_random      ; try again if out of range

  ; --- Collision Check ---
  sta temp              ; save candidate column
  pha                   ; save A (column)
  txa
  pha                   ; save X (current slot index)

  ldx #0
@collision_loop:
  txa
  calc_trail_ptr ptr_trail_color, TRAILS_RAM ; Use ptr_trail_color as temp pointer
  
  ldy #TRAIL_ACTIVE
  lda (ptr_trail_color), y
  beq @next_check       ; ignore inactive trails
  
  ldy #TRAIL_COLUMN
  lda (ptr_trail_color), y
  cmp temp
  bne @next_check       ; ignore different columns

  ; Same Column - Check for Overlap
  ; New Trail spawning at Head=0.
  ; Collision if Existing Trail covers Row 0.
  ; Trail covers [Head-Length, Head].
  ; If Tail (Head-Length) <= 0, then it covers Row 0.
  
  ldy #TRAIL_HEAD
  lda (ptr_trail_color), y ; Existing Head
  sec
  ldy #TRAIL_LENGTH
  sbc (ptr_trail_color), y ; Existing Length
  
  ; Result = Tail Position (Virtual)
  ; If Tail <= 0, Collision.
  ; Carry Clear (BCC) -> Borrow occurred -> Tail < 0.
  ; Zero (BEQ) -> Tail == 0.
  
  bcc @collision_detected ; Tail < 0

@next_check:
  inx
  cpx #MAX_TRAILS
  bne @collision_loop

  ; Success - No collision
  pla
  tax               ; restore X
  pla               ; restore A (column)
  
  ldy #TRAIL_COLUMN
  sta (ptr_trail), y ; store confirmed unique column
  jmp @continue_init

@collision_detected:
  pla
  tax               ; restore X
  pla               ; restore A
  jmp @pick_random  ; try again

@continue_init:
  ldy #TRAIL_HEAD
  lda #0
  sta (ptr_trail), y
  
  ldy #TRAIL_LENGTH
  lda #DEFAULT_LENGTH
  sta (ptr_trail), y
  
  ldy #TRAIL_ACTIVE
  lda #1
  sta (ptr_trail), y

@done:
  pla
  tay
  pla
  tax
  pla
  rts
  
; ---------------------------------------------------------------------------
; Animate All Active Trails
;
update_trails:
  pha
  txa
  pha
  tya
  pha
  
  ldx #0
@loop:
  txa  
  calc_trail_ptr ptr_trail, TRAILS_RAM 
  
  ldy #TRAIL_ACTIVE
  lda (ptr_trail), y
  beq @check_next_trail

  jsr update_current_trail

@check_next_trail:
  ; next X
  inx
  cpx #MAX_TRAILS
  bne @loop 

@done_updating:
  pla
  tay
  pla
  tax
  pla
  rts
  
; ---------------------------------------------------------------------------
; updates the current trail pointed to by ptr_trail
;
update_current_trail:
  pha
  txa
  pha
  tya
  pha
  
  ; --- step 1 - turn previous head green ---
  ldy #TRAIL_HEAD
  lda (ptr_trail), y
  beq @skip_green_body  ; if head is 0, no previous head yet!

  sec
  sbc #1
  cmp #SCREEN_ROWS
  bcs @skip_green_body  ; if target off-screen (rolled off bottom), skip!
  
  tay
  pha                   ; save row
  ldy #TRAIL_COLUMN
  lda (ptr_trail), y 
  tax
  pla
  tay
  
  jsr calc_trail_ptrs
  
  lda #VIC_GREEN
  ldy #0
  sta (ptr_trail_color), y  ; turn previous head green

@skip_green_body:
  ; draw new head white
  ldy #TRAIL_HEAD
  lda (ptr_trail), y 
  cmp #SCREEN_ROWS
  bcs @skip_draw_head

  ; setup y=row x=column
  tay
  pha
  ldy #TRAIL_COLUMN
  lda (ptr_trail), y 
  tax
  pla
  tay
  jsr calc_trail_ptrs

@get_head_char:
  jsr get_rand
  and #%00111111        ; mask to 0-63
  cmp #39
  bcs @get_head_char    ; if >= 39, retry

  ldy #0
  sta (ptr_trail_screen),y
  lda #VIC_WHITE
  sta (ptr_trail_color),y 
  
@skip_draw_head:
@erase_old_tail:
  ldy #TRAIL_HEAD
  lda (ptr_trail), y
  sec
  ldy #TRAIL_LENGTH
  sbc (ptr_trail), y    ; A = Head - Length

  ; Bounds check the tail
  bmi @skip_erase       ; If Tail < 0 (Underflow), it's not on screen yet
  cmp #SCREEN_ROWS
  bcs @skip_erase       ; If Tail >= 23, it's already off screen

  ; Setup Y=Row, X=Column
  tay                   ; Y = Tail Row
  pha
  ldy #TRAIL_COLUMN
  lda (ptr_trail), y
  tax                   ; X = Column
  pla
  tay

  jsr calc_trail_ptrs

  lda #63               ; Blank (Micro Font)
  ldy #0
  sta (ptr_trail_screen),y  ; Erase

@skip_erase:

@move_trail_downward:
  ldy #TRAIL_HEAD
  lda (ptr_trail), y
  clc
  adc #1
  sta (ptr_trail), y

@deactivate_if_off_screen:
  ; Check if the TAIL is fully off screen
  ; Tail = Head - Length
  ; If Tail >= SCREEN_ROWS, the trail is finished.
  
  ldy #TRAIL_HEAD
  lda (ptr_trail), y    ; Load Head
  sec
  ldy #TRAIL_LENGTH
  sbc (ptr_trail), y    ; Calculate Tail
  
  bcc @done             ; If borrow (Tail < 0), keep alive
  cmp #SCREEN_ROWS
  bcc @done             ; If Tail < 23, keep alive

  ; Kill the trail
  ldy #TRAIL_ACTIVE
  lda #0
  sta (ptr_trail), y

@done:
  pla
  tay
  pla
  tax
  pla
  rts

; ---------------------------------------------------------------------------
; Calculates the current offset to screen & color RAM based on the given trail
; position (Y = row, X = column).
; Offset will be stored ptr_trail_offset. Uses temp.
;
calc_trail_ptrs:
  pha
  
  save_yx temp
  calc_lut_offset ptr_trail_offset, temp, temp + 1
  add16_ptr ptr_trail_screen, ptr_screen, ptr_trail_offset
  add16_ptr ptr_trail_color, ptr_color, ptr_trail_offset
  
  pla
  rts

; --- Read-only DATA ---
.segment "RODATA"

; Look-Up Tables: Pre-calculated start address for each row 
; Formula: Row * 22
RowLo:
    .byte <(0*22), <(1*22), <(2*22), <(3*22), <(4*22), <(5*22)
    .byte <(6*22), <(7*22), <(8*22), <(9*22), <(10*22), <(11*22)
    .byte <(12*22), <(13*22), <(14*22), <(15*22), <(16*22), <(17*22)
    .byte <(18*22), <(19*22), <(20*22), <(21*22), <(22*22)

RowHi:
    .byte >(0*22), >(1*22), >(2*22), >(3*22), >(4*22), >(5*22)
    .byte >(6*22), >(7*22), >(8*22), >(9*22), >(10*22), >(11*22)
    .byte >(12*22), >(13*22), >(14*22), >(15*22), >(16*22), >(17*22)
    .byte >(18*22), >(19*22), >(20*22), >(21*22), >(22*22)