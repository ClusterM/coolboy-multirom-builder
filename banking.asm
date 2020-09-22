PRG_RAM_BANKS .equ 1 ; number of PRG RAM banks

banking_init:
  ; CHR at $0000-$07FF
  lda #$00
  sta $8000
  lda #$00
  sta $8001
  ; CHR at $0800-$0FFF
  lda #$01
  sta $8000
  lda #$02
  sta $8001
  ; CHR at $1000-$13FF
  lda #$02
  sta $8000
  lda #$04
  sta $8001
  ; CHR at $1400-$17FF
  lda #$03
  sta $8000
  lda #$05
  sta $8001
  ; CHR at $1800-$1BFF  
  lda #$04
  sta $8000
  lda #$06
  sta $8001
  ; CHR at $1C00-$1FFF
  lda #$05
  sta $8000
  lda #$07
  sta $8001
  ; mirroring
  lda #$01
  sta $A000
  ; PRG-RAM protect
  lda #$00
  sta $A001
  rts

enable_prg_ram:
  lda #$80
  sta $A001
  rts

disable_prg_ram:
  lda #$00
  sta $A001
  rts

enable_chr_write:
  ; not supported on COOLBOY :(
  rts

disable_chr_write:
  ; not supported on COOLBOY :(
  rts

  ; select 16KB bank at $8000-$BFFF
select_prg_bank:
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

  ; select 8KB bank
select_chr_bank:
  asl A
  asl A
  asl A
  pha
  lda #0
  sta $8000
  pla
  pha
  sta $8001
  lda #1
  sta $8000
  pla
  pha
  ora #%00000010
  sta $8001
  lda #2
  sta $8000
  pla
  pha
  ora #%00000100
  sta $8001
  lda #3
  sta $8000
  pla
  pha
  ora #%00000101
  sta $8001
  lda #4
  sta $8000
  pla
  pha
  ora #%00000110
  sta $8001
  lda #5
  sta $8000
  pla
  ora #%00000111
  sta $8001
	rts	

  ; COOLBOY has not any PRG RAM banking
select_prg_ram_bank:
  rts
