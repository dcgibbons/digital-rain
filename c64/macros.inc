; ---------------------------------------------------------------------------
; macros.inc - Useful macros
; Digital Rain on the Commodore 64
;

.ifndef ::MACROS_INC_
::MACROS_INC_ = 1

; ---------------------------------------------------------------------------
; calc_lut_offset
; Calculates 16-bit offset
; Uses RowLo/RowHi lookup tables.
;
; Arguments:
;   Dest      : Variable to store the 16-bit offset (e.g., ptr_offset)
;   RowIndex  : Memory address holding the Row
;   ColIndex  : Memory address holding the Column
; ---------------------------------------------------------------------------
.macro calc_lut_offset Dest, RowIndex, ColIndex
    ldx RowIndex        ; Load Row into X for indexing
    
    lda RowLo, x        ; Get Base Row Address (Low)
    clc
    adc ColIndex        ; Add Column index
    sta Dest            ; Store result in Dest (Low)

    lda RowHi, x        ; Get Base Row Address (High)
    adc #0              ; Add Carry from the previous addition
    sta Dest+1          ; Store result in Dest+1 (High)
.endmacro

; ---------------------------------------------------------------------------
; add16_ptr
; Calculates: Destination = Base + Offset
; Arguments:
;   Dest   : The variable to store the result
;   Base   : The starting pointer address
;   Offset : The value to add to the base
; ---------------------------------------------------------------------------
.macro add16_ptr Dest, Base, Offset
  lda Offset        ; Load Low Byte of Offset
  clc               ; Clear Carry for new math
  adc Base          ; Add Low Byte of Base
  sta Dest          ; Store in Destination Low

  lda Offset+1      ; Load High Byte of Offset
  adc Base+1        ; Add High Byte of Base + Carry
  sta Dest+1        ; Store in Destination High
.endmacro

; ---------------------------------------------------------------------------
; add16_const
; Calculates: Destination = ConstantBase + VariableOffset
; Arguments:
;   Dest           : The variable to store the result
;   ConstantBase   : The starting address (Immediate value)
;   VariableOffset : The variable adding to the base
; ---------------------------------------------------------------------------
.macro add16_const Dest, ConstantBase, VariableOffset
  lda VariableOffset        ; Load Low Byte of Offset
  clc                       ; Clear Carry
  adc #<ConstantBase        ; Add Low Byte of Constant Base
  sta Dest                  ; Store in Destination Low

  lda VariableOffset+1      ; Load High Byte of Offset
  adc #>ConstantBase        ; Add High Byte of Constant Base + Carry
  sta Dest+1                ; Store in Destination High
.endmacro

; ---------------------------------------------------------------------------
; save_yx
; Saves Y and X register to a 16-bit value at Dest. Y is stored in the low
; byte and X is stord in the high byte.
; Arguments:
;   Dest : The variable to store the result
; Input:
;   Y and X registers.
; ---------------------------------------------------------------------------
.macro save_yx Dest
  tya
  sta Dest
  txa
  sta Dest+1
.endmacro

; ---------------------------------------------------------------------------
; calc_trail_ptr
; Calculates a pointer to a struct in an array (assuming struct size = 4).
;
; Arguments:
;   DestPtr : The Zero Page variable to store the result (e.g., ptr_trail)
;   BaseAddr: The starting address of the array (e.g., TRAILS_RAM)
;
; Input:
;   Accumulator (A) must hold the Index (0-63).
; ---------------------------------------------------------------------------
.macro calc_trail_ptr DestPtr, BaseAddr
    asl                 ; A *= 2
    asl                 ; A *= 4 (Shift twice for size 4)
    
    clc
    adc #<BaseAddr      ; Add Base Address Low Byte
    sta DestPtr         ; Store in Pointer Low
    
    lda #>BaseAddr      ; Load Base Address High Byte
    adc #0              ; Add Carry from the Low Byte addition
    sta DestPtr+1       ; Store in Pointer High
.endmacro

.endif