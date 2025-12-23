; ---------------------------------------------------------------------------
; basic_stub.s - BASIC Stub Loader
; Digital Rain on the Commodore 64
;

.segment "EXEHDR"
  ; BASIC Line: 10 SYS 2061
  .word @next_line
  .word 10              ; Line Number 10
  .byte $9E," 2062",$00 ; SYS 2062
@next_line:
  .word 0               ; End of BASIC program