; ---------------------------------------------------------------------------
; universal.s - Universal Binary Loader Support
; Digital Rain on the Commodore VIC-20
;

.import main

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
.import __STUB_LOAD__
.import __CODE_RUN__
.import __CODE_LOAD__
.import __CODE_SIZE__
.import __RODATA_SIZE__
.import __DATA_SIZE__
  
  ; -------------------------------------------------------------------------
  ; BASIC Line: 10 SYS PEEK(43)+PEEK(44)*256 + [Offset]
  ; Tokens:
  ; SYS  = $9E
  ; PEEK = $C2
  ; +    = $AA
  ; *    = $AC
  ; (    = $28
  ; )    = $29
  ;
  .word @next_line
  .word 10              ; Line Number 10
  .byte $9E             ; SYS Token
  .byte " "             ; Space
  
  ; PEEK(43) +
  .byte $C2,$28,"4","3",$29,$AA
  ; PEEK(44) * 256
  .byte $C2,$28,"4","4",$29,$AC,"2","5","6"
  ; + 27
  .byte $AA, "27", 0
  
@next_line:
  .word 0
  
relocator:
  sei
  
  ; --- Calculate Source Address ---
  ; Source = Start_Of_Basic + (Offset_of_Code_In_File - Offset_of_Stub_In_File)
  ; Start_Of_Basic is at $2B/$2C
  ;
  ; Offset = (__CODE_LOAD__ - __STUB_LOAD__)
  ;
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

  jmp main              ; Jump to main code
.endif
