; ---------------------------------------------------------------------------
; rand.s - Pseudo-Random Number Generator for VIC-20 Matrix-like Effect
; Digital Rain on the Commodore VIC-20
;

.export init_rng
.export get_rand

VIA1_T1_LOW_COUNTER := $9114
DEFAULT_SEED        := 42

.segment "ZEROPAGE"
rng_seed:           .res 1  ; seed for rng

.segment "CODE"

; ---------------------------------------------------------------------------
; initialize the pseudo-random number generator with a seed
;
init_rng:
  pha
  lda VIA1_T1_LOW_COUNTER
  bne @seed_ok      ; if non-zero, go ahead and use it
  lda #DEFAULT_SEED ; fallback if zero
@seed_ok:
  sta rng_seed
  pla
  rts

; ---------------------------------------------------------------------------
; gets next random byte into accumulator using a linear feedback shift
; register prng algorithm
;
get_rand:
  lda rng_seed
  beq @do_eor       ; if zero, force eor
  asl a             ; shift left

  bcc @no_eor       ; no carry? skip eor
@do_eor:
  eor #$1d          ; tap polynomial for maximal 8-bit LSFR (or $B5 / $1B)
@no_eor:
  sta rng_seed      ; update seed
  
  rts