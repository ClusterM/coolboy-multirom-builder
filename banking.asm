banking_init:
  lda #$00
  sta $8000
  lda #$00
  sta $8001
  
  lda #$01
  sta $8000
  lda #$02
  sta $8001
  
  lda #$02
  sta $8000
  lda #$04
  sta $8001
  
  lda #$03
  sta $8000
  lda #$05
  sta $8001
  
  lda #$04
  sta $8000
  lda #$06
  sta $8001

  lda #$05
  sta $8000
  lda #$07
  sta $8001

  lda #$01
  sta $A000 ; mirroring

  lda #$00
  sta $A001 ; PRG-RAM protect

  rts

  ; select 16KB bank at $8000-$BFFF
select_bank:
  clc  
  adc #$18 ; start of ROM (+368K)
  ldx #6
  stx $8000
  asl A
  sta $8001  
  inx
  stx $8000
  ora #1
  sta $8001
  rts
