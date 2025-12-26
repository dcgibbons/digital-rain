; ---------------------------------------------------------------------------
; trails.s - Trail Management for the Matrix-like Effect
; Digital Rain on the Commodore 64
;

.include "cbm.mac"
.include "cbm_kernal.inc"
.include "c64.inc"

.include "macros.inc"
.include "globals.inc"
.include "rand.inc"
.include "screen.inc"
.include "vic-ii_colors.inc"

SCREEN_RAM := $0400
COLOR_RAM  := $D800

.export init_trails
.export create_trail
.export update_trails

; -- structure to represent a trail:
TRAIL_COLUMN    = 0     ; byte
TRAIL_HEAD      = 1     ; byte
TRAIL_LENGTH    = 2     ; byte
TRAIL_ACTIVE    = 3     ; Byte
TRAIL_SIZE      = 4     ; Bytes per struct

MAX_TRAILS      = XSIZE + 10
DEFAULT_LENGTH  = 13

.segment "DATA"
trails_ram:       .res 256
ptr_trail_offset: .res 2
temp:             .res 2

; ---------------------------------------------------------------------------
; Zeropage storage
;
ptr_trail_screen := $FB     ; unused zero page space
ptr_trail_color  := $FD     ; unused zero page space
ptr_trail        := $02     ; unused zero page space

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
  calc_trail_ptr ptr_trail, trails_ram
  
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
  calc_trail_ptr ptr_trail, trails_ram 
  
  ldy #TRAIL_ACTIVE
  lda (ptr_trail), y
  beq @found_inactive_trail

  ; next X
  inx
  cpx #MAX_TRAILS
  bne @loop 
  beq @done

@found_inactive_trail:
  lda #10               ; Max retries to find a valid column (Reduced to prevent lag)
  sta temp+1

@pick_random:
  dec temp+1
  beq @done             ; Abort if we can't find a spot to prevent hanging

  jsr get_rand
  and #%00111111        ; mask to 0-63
  cmp #XSIZE
  bcs @pick_random      ; try again if out of range

  ; --- Collision Check ---
  sta temp              ; save candidate column
  ; Use ptr_trail_offset to save context instead of stack (prevent corruption)
  sta ptr_trail_offset      ; save A (column)
  stx ptr_trail_offset+1    ; save X (current slot index)

  ldx #0
@collision_loop:
  ; inc $D020             ; Visual Heartbeat REMOVED
  txa
  calc_trail_ptr ptr_trail_color, trails_ram ; Use ptr_trail_color as temp pointer
  
  ldy #TRAIL_ACTIVE
  lda (ptr_trail_color), y
  beq @next_check       ; ignore inactive trails
  
  ldy #TRAIL_COLUMN
  lda (ptr_trail_color), y
  cmp temp
  bne @next_check       ; ignore different columns

  ; Same Column - Check for Overlap
  ldy #TRAIL_HEAD
  lda (ptr_trail_color), y ; Existing Head
  sec
  ldy #TRAIL_LENGTH
  sbc (ptr_trail_color), y ; Existing Length
  
  ; Result = Tail Position (Virtual)
  ; If Tail <= 0, Collision.
  bcc @collision_detected ; Tail < 0

@next_check:
  inx
  cpx #MAX_TRAILS
  bne @collision_loop

  ; Success - No collision
  ldx ptr_trail_offset+1    ; restore X (Target Slot)
  lda ptr_trail_offset      ; restore A (Column)
  
  ldy #TRAIL_COLUMN
  sta (ptr_trail), y ; store confirmed unique column
  jmp @continue_init

@collision_detected:
  ldx ptr_trail_offset+1    ; restore X (Target Slot)
  ; No need to restore A, we are retrying
  jmp @pick_random  ; try againstead of retry to test Exit Path stability

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
  calc_trail_ptr ptr_trail, trails_ram 
  
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
  cmp #YSIZE
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
  cmp #YSIZE
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
  ; and #%00111111        ; mask to 0-63
  ; cmp #39
  cmp #$20
  bcs @get_head_char    ; if Space, retry

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
  cmp #YSIZE
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

  lda #$20              ; Space
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
  ; If Tail >= YSIZE, the trail is finished.
  
  ldy #TRAIL_HEAD
  lda (ptr_trail), y    ; Load Head
  sec
  ldy #TRAIL_LENGTH
  sbc (ptr_trail), y    ; Calculate Tail
  
  bcc @done             ; If borrow (Tail < 0), keep alive
  cmp #YSIZE
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
  add16_const ptr_trail_screen, SCREEN_RAM, ptr_trail_offset
  add16_const ptr_trail_color, COLOR_RAM, ptr_trail_offset
  
  pla
  rts

; --- Read-only DATA ---
.segment "RODATA"

; Lookup table for 40-column screen rows (0 to 24)
; Calculated as RowIndex * 40
RowLo:
    .byte <(0*40),  <(1*40),  <(2*40),  <(3*40),  <(4*40),  <(5*40)
    .byte <(6*40),  <(7*40),  <(8*40),  <(9*40),  <(10*40), <(11*40)
    .byte <(12*40), <(13*40), <(14*40), <(15*40), <(16*40), <(17*40)
    .byte <(18*40), <(19*40), <(20*40), <(21*40), <(22*40), <(23*40)
    .byte <(24*40), <(25*40)

RowHi:
    .byte >(0*40),  >(1*40),  >(2*40),  >(3*40),  >(4*40),  >(5*40)
    .byte >(6*40),  >(7*40),  >(8*40),  >(9*40),  >(10*40), >(11*40)
    .byte >(12*40), >(13*40), >(14*40), >(15*40), >(16*40), >(17*40)
    .byte >(18*40), >(19*40), >(20*40), >(21*40), >(22*40), >(23*40)
    .byte >(24*40), >(25*40)