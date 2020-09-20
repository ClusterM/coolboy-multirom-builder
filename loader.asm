	; settings for loader
LOADER_REG_0 .rs 1
LOADER_REG_1 .rs 1
LOADER_REG_2 .rs 1
LOADER_REG_3 .rs 1
LOADER_CHR_START_H .rs 1
LOADER_CHR_START_L .rs 1
LOADER_CHR_START_S .rs 1
LOADER_CHR_SIZE_SOURCE .rs 1
LOADER_CHR_SIZE_TARGET .rs 1
LOADER_CHR_COUNT .rs 1
LOADER_MIRRORING .rs 1

CHR_BANK8 .rs 1 ; to select CHR bank
NROM_BANK_H .rs 1 ; to select 16K bank
NROM_BANK_L .rs 1 ; to select 16K bank
NROM_BANK_S .rs 1 ; for loader

loader:
	; sets COOLBOY registers
	lda <LOADER_MIRRORING
	sta $A000
	lda <LOADER_REG_0
	sta COOLBOY_REG_0
	lda <LOADER_REG_1
	sta COOLBOY_REG_1
	lda <LOADER_REG_2
	sta COOLBOY_REG_2
	lda <LOADER_REG_3
	sta COOLBOY_REG_3
	
	; PRG RAM fix
	lda #$80
	sta $A001 ; enable PRG-RAM
	lda #$00
	sta <COPY_DEST_ADDR
	ldx #$60
	stx <COPY_DEST_ADDR+1
	ldy #$00
	ldx #$00
.prg_ram_loop:
	iny
	iny
	iny
	lsr PRG_RAM_FIX, x
	bcc .prg_ram_skip
	lda [COPY_DEST_ADDR],y
	ora #$80
	sta [COPY_DEST_ADDR],y
.prg_ram_skip:
	tya
	and #%00011111
	cmp #%00011111
	bne .prg_ram_next
	inx
.prg_ram_next:
	iny
	bne .prg_ram_loop
	inc <COPY_DEST_ADDR+1
	bpl .prg_ram_loop
	sty $A001 ; disable PRG RAM
	ldx #$06
	ldy #$00
	stx $8000 ; init MMC3 (required by some games and ports)
	sty $8001
	inx
	stx $8000
	iny
	sty $8001
  jmp .end_of_memory
  ; dirty trick :)
.end_of_loader:
	.org $07E0
.end_of_memory:
	; clean memory
	lda #$00
	sta <COPY_SOURCE_ADDR
	sta <COPY_SOURCE_ADDR+1
	ldy #$02
	ldx #$07
.loop:
	sta [COPY_SOURCE_ADDR], y
	iny
	bne .loop
	inc <COPY_SOURCE_ADDR+1
	dex
	bne .loop
.loop2:
	sta [COPY_SOURCE_ADDR], y
	iny
	cpy #LOW(.loop2) ; to the very end
	bne .loop2	
	; Start game!
	jmp [$FFFC]
	.org .end_of_loader

	; CHR data loader, only one 8KB bank
load_chr:
	lda #$00
	sta $2006
	sta $2006
	ldy #$00
	ldx #$20
.loop:
	lda [COPY_SOURCE_ADDR], y
	sta $2007
	iny
	bne .loop
	inc COPY_SOURCE_ADDR+1
	dex
	bne .loop
	rts

load_all_chr_banks:
	; Maybe CHR is empty?
	lda <LOADER_CHR_SIZE_TARGET
	beq .end
	; Always starting with zero target CHR bank
	lda #0
	sta <CHR_BANK8
	; Source address (lower byte)
	sta <COPY_SOURCE_ADDR
.reinit:
	; Bank counter
	lda #0
	sta <LOADER_CHR_COUNT
	; Source bank - hi
	ldx <LOADER_CHR_START_H
	stx <NROM_BANK_H
	; Source bank - low
	lda <LOADER_CHR_START_L
	sta <NROM_BANK_L
	; Source address - low - 0x80 or 0xC0
	lda <LOADER_CHR_START_S
	sta <COPY_SOURCE_ADDR+1
.loop:
	jsr select_prg_chr_banks ; selecting source and target banks
	jsr load_chr ; loading CHR data from COPY_SOURCE_ADDR to CHR RAM
	lda <COPY_SOURCE_ADDR+1 ; increamenting source address
	and #$A0 ; or from $A000 to $8000
	sta <COPY_SOURCE_ADDR+1
	cmp #$80
	bne .chr_s_not_inc ; if $8000 need to increament source bank
	lda <NROM_BANK_L	
	clc
	adc #1
	sta <NROM_BANK_L
	lda <NROM_BANK_H
	adc #0
	sta <NROM_BANK_H	
.chr_s_not_inc:
	inc <CHR_BANK8 ; also need to increament target CHR bank
	lda <CHR_BANK8
	cmp <LOADER_CHR_SIZE_TARGET ; was it last TARGET bank?
	beq .end ; ...then end
	inc <LOADER_CHR_COUNT ; increamenting counter
	lda <LOADER_CHR_COUNT
	cmp <LOADER_CHR_SIZE_SOURCE ; was it last SOURCE bank?
	beq .reinit ; need to repeat all data then
	jmp .loop	
.end:
	lda #$00
	sta COOLBOY_REG_0
	sta COOLBOY_REG_1
	sta COOLBOY_REG_2
	sta COOLBOY_REG_3
	rts

	; select 16KB NROM bank from the whole flash memory
  ; and 8KB CHR bank from the whole CHR RAM memory
	; $C000-$FFFF is a mirror for $8000-$BFFF
select_prg_chr_banks:
	lda #$00
	sta $A001 ; PRG-RAM protect
	;<NROM_BANK_L (1-8)	<NROM_BANK_H (9-11)  <CHR_BANK8 (7-3)
	;6000
	lda <NROM_BANK_L
	lsr A
	lsr A
	lsr A
	and #%00000111 ; 6, 5, 4
	sta <TMP
	lda <NROM_BANK_H
	and #%00000110 ; 11, 10
	asl A
	asl A
	asl A
	ora <TMP
	sta <TMP
	lda <CHR_BANK8
	lsr A
	and #%00001000
	ora <TMP
	ora #%11000000 ; reset PRG MASK, CHR control
	sta COOLBOY_REG_0
	;6001
	lda <NROM_BANK_L
	and #%10000000 ; 8
	lsr A
	lsr A
	lsr A
	lsr A
	lsr A
	sta <TMP
	lda <NROM_BANK_L
	and #%01000000 ; 7
	lsr A
	lsr A
	ora <TMP
	sta <TMP
	lda <NROM_BANK_H
	and #%00000001 ; 9
	asl A
	asl A
	asl A
	ora <TMP
	ora #%10000000 ; reset PRG MASK
	sta COOLBOY_REG_1
	;6002
	lda <CHR_BANK8
	and #%00001111
	sta COOLBOY_REG_2
	;6003	
	lda <NROM_BANK_L
	and #%00000111 ; 3, 2, 1
	asl A
	ora #%00010000 ; NROM mode
	sta COOLBOY_REG_3
	rts	
