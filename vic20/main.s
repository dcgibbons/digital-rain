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
; ---------------------------------------------------------------------------
; Universal Relocatable PRG Header
; ---------------------------------------------------------------------------
; Supported Configurations (Load Address via ",8"):
; - Unexpanded: Loads at $1001
; - +3K:        Loads at $0401
; - +8K/+16K:   Loads at $1201
;
; Strategy:
; 1. BASIC Stub calculates current load address.
; 2. Stub jumps to 'relocator'.
; 3. Relocator copies CODE section to $1300 (Safe on all configs).
; 4. Relocator jumps to $1300.
; ---------------------------------------------------------------------------
.segment "LOADADDR"
  .word $1001           ; Default Load Address (Ignored if loaded with ",8")

.segment "STUB"
  ; -------------------------------------------------------------------------
  ; BASIC Line: 10 SYS PEEK(43)+PEEK(44)*256 + [Offset]
  ; -------------------------------------------------------------------------
  ; Tokens:
  ; SYS  = $9E
  ; PEEK = $C2
  ; +    = $AA
  ; *    = $AC
  ; (    = $28
  ; )    = $29
  ; -------------------------------------------------------------------------
  .import __STUB_LOAD__
  .import __CODE_RUN__
  .import __CODE_LOAD__
  .import __CODE_SIZE__
  .import __RODATA_SIZE__
  .import __DATA_SIZE__
  
  ; Link to next line (placeholder, will be calculated by assembler if we were clever, 
  ; but here we just rely on standard VIC layout or just put a dummy link).
  ; Actually, standard BASIC loader re-calculates links ONLY if you LOAD...
  ; But if we load absolute? No we load relative.
  ; The LOAD command re-links the chain? No, only on C64 usually. VIC-20?
  ; Safest is to just have a valid link relative to start.
  
  .word @next_line
  .word 10        ; Line Number 10
  .byte $9E       ; SYS Token
  .byte " "       ; Space
  
  ; PEEK(43)
  .byte $C2, $28, "4", "3", $29
  
  ; +
  .byte $AA
  
  ; PEEK(44)
  .byte $C2, $28, "4", "4", $29
  
  ; * 256
  .byte $AC, "2", "5", "6"
  
  ; + Offset
  .byte $AA
  
  ; The Offset is the distance from Start-of-Basic (Pointer 43/44) to 'relocator'.
  ; Our file structure is:
  ; [Load Addr 2 bytes] [Line Link 2] [Line Num 2] [SYS 1] [Space 1] [Expr...] [Null 1] [Next Line 2 (0)] [Relocator...]
  ; The "Start of Basic" points to the [Line Link].
  ; So Offset = Address(Relocator) - Address(Line Link).
  ; We can calculate this difference using labels in the assembly!
  
  ; We need to output the offset as ASCII digits.
  ; Since we can't easily convert label arithmetic to ASCII string in assembler macros without complexity...
  ; Let's count bytes manually or use a fixed safe guess (like 40 or 50) and pad to it.
  ;
  ; Bytes so far used in the line:
  ; SYS(1)+Sp(1)+PEEK(1)+((1)+4(1)+3(1)+)(1) = 7
  ; + (1) = 8
  ; PEEK(1)+((1)+4(1)+4(1)+)(1) = 12
  ; * (1) = 13
  ; 2(1)+5(1)+6(1) = 16
  ; + (1) = 17
  ; Digits (2) = 19
  ; Null (1) = 20
  ;
  ; Total Payload in BASIC Line = 20 bytes.
  ; Header (Link+Line) = 4 bytes.
  ; Next Line Link (End) = 2 bytes.
  ; Total size from Start to Relocator = 4 + 20 + 2 = 26 bytes.
  ; So the offset is roughly 26.
  ; Update: User found it should be 27.
  .byte "2", "7"
  .byte 0

@next_line:
  .word 0
  
relocator:
  sei
  
  ; --- Calculate Source Address ---
  ; Source = Start_Of_Basic + (Offset_of_Code_In_File - Offset_of_Stub_In_File)
  ; Start_Of_Basic is at $2B/$2C
  
  ; Offset = (__CODE_LOAD__ - __STUB_LOAD__)
  ; Since linker gives absolute addresses based on a dummy start, the difference is correct.
  OFFSET = __CODE_LOAD__ - __STUB_LOAD__
  
  clc
  lda $2B           ; Start of Basic Low
  adc #<OFFSET
  sta $FB           ; ZP Pointer Low (Source)
  
  lda $2C           ; Start of Basic High
  adc #>OFFSET
  sta $FC           ; ZP Pointer High (Source)
  
  ; --- Calculate Destination Address ---
  ; Dest = $1300 (__CODE_RUN__)
  lda #<__CODE_RUN__
  sta $FD
  lda #>__CODE_RUN__
  sta $FE
  
  ; --- Calculate Size to Copy ---
  ; Size = CODE + RODATA + DATA
  ; We use a constant derived from linker symbols
  TOTAL_SIZE = __CODE_SIZE__ + __RODATA_SIZE__ + __DATA_SIZE__
  
  ; --- Prepare Copy (High-to-Low) ---
  ; To handle overlaps safely (e.g. Unexpanded $1000 -> $1300 or Backwards),
  ; we should analyze overlap.
  ; Unexpanded: Src $10xx, Dest $1300. Dest > Src. Copy High-to-Low (Backwards).
  ; +8K:        Src $12xx, Dest $1300. Dest > Src. Copy High-to-Low.
  ; +3K:        Src $04xx, Dest $1300. Dest > Src. Copy High-to-Low.
  ; In all our cases, Dest > Src. So we must copy starting from the END.
  
  ; Adjust pointers to End of Block
  clc
  lda $FB
  adc #<TOTAL_SIZE
  sta $FB
  lda $FC
  adc #>TOTAL_SIZE
  sta $FC
  
  clc
  lda $FD
  adc #<TOTAL_SIZE
  sta $FD
  lda $FE
  adc #>TOTAL_SIZE
  sta $FE
  
  ; Setup counters
  ldx #>TOTAL_SIZE
  ldy #<TOTAL_SIZE
  
  ; If low byte is 0, we need to handle the decrements carefully.
  ; Actually, simpler loop:
  ; Loop Y from Low to 0. Then Dec X. Loop from 255 to 0. etc.
  ; Or just generic block copy.
  
  ; Let's use Y as index? No, total size > 256.
  ; Using two ZP pointers ($FB source, $FD dest).
  
@copy_loop:
  ; Check if done (Total Size down to 0)
  ; We use X (high) and Y (low) as countdown.
  
  ; Decrement pointers first (because they point to End)
  lda $FB
  bne @skip_dec_src_hi
  dec $FC
@skip_dec_src_hi:
  dec $FB
  
  lda $FD
  bne @skip_dec_dest_hi
  dec $FE
@skip_dec_dest_hi:
  dec $FD
  
  ; Copy byte
  ldx #0
  lda ($FB,x)
  sta ($FD,x)
  
  ; Decrement Counter (TOTAL_SIZE)
  ; Actually we can just compare Pointers against Start?
  ; Check if $FD == <__CODE_RUN__ && $FE == >__CODE_RUN__
  lda $FD
  cmp #<__CODE_RUN__
  bne @copy_loop
  lda $FE
  cmp #>__CODE_RUN__
  bne @copy_loop
  
  ; --- Jump to Real Code ---
  jmp __CODE_RUN__

.segment "CODE"
prg_start:
  sei                   ; Disable interrupts
  cld                   ; Clear decimal mode
    
  ldx #$FF              ; Set stack pointer to $01FF
  txs

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