SAVES_BANK .rs 1 ; bank with saves
LAST_STARTED_SAVE .rs 1 ; last used save ID

	; saving last selected game
save_state:
	.if USE_FLASH_WRITING=0
	rts
	.endif
	lda <FLASH_TYPE
	beq .end
	lda <SAVES_BANK
	bne .bank_already_formatted
	lda #($100 - 8) ; last bank - 8*16kb
	sta <SAVES_BANK
	jsr flash_format_sector
.bank_already_formatted:
	jsr write_state
.end:
	rts

write_state:
	lda #0
	sta BUFFER ; marker
	; last started game
	lda <SELECTED_GAME
	sta BUFFER+1
	lda <SELECTED_GAME+1
	sta BUFFER+2
	; line
	lda <SCROLL_LINES_TARGET
	sta BUFFER+3
	lda <SCROLL_LINES_TARGET+1
	sta BUFFER+4
	lda <LAST_STARTED_SAVE
	sta BUFFER+5
	lda <STATE_CELL_NEXT
	sta COPY_DEST_ADDR
	clc
	adc #8
	sta <STATE_CELL_NEXT
	lda <STATE_CELL_NEXT+1
	sta COPY_DEST_ADDR+1
	adc #0
	sta <STATE_CELL_NEXT+1
	lda <SAVES_BANK
	sta <NROM_BANK_L ; storing saves bank number
	lda #$FF
	sta <NROM_BANK_H ; at the very end of flash memory	
	ldx #6; 6 bytes
	jsr flash_write
	rts
	
load_state:
	.if USE_FLASH_WRITING=0
	rts
	.endif
	lda <FLASH_TYPE
	beq .end
	lda BUTTONS
	cmp #$5C ; Up+Left+Select+Start = full erase
	bne .no_force_erase	
	jsr flash_force_erase
	rts
.no_force_erase:
	jsr find_saves_bank ; checks for saves bank
	beq .end ; no saves bank?
	sta <NROM_BANK_L ; storing saves bank number
	lda #$FF
	sta <NROM_BANK_H ; at the very end of flash memory
	jsr flash_find_empty_cell ; searching for first empty cell
	lda <STATE_CELL_NEXT+1
	cmp #$80
	bne .state_exists
	lda <STATE_CELL_NEXT
	cmp #$20
	bne .state_exists
	jmp .end ; if it's at the very beginning ($8020), there is no saved status
.state_exists:
	lda <STATE_CELL_NEXT
	sec
	sbc #8
	sta COPY_SOURCE_ADDR
	lda <STATE_CELL_NEXT+1
	sbc #0
	sta COPY_SOURCE_ADDR+1
	ldx #8
	jsr flash_read ; loading 8 bytes of data	
	; loading last started game
	lda BUFFER+1
	sta <SELECTED_GAME
	lda BUFFER+2
	sta <SELECTED_GAME+1
	; check for overflow
	lda <SELECTED_GAME
	sec
	sbc games_count
	lda <SELECTED_GAME+1
	sbc games_count+1	
	bcs .ovf	
	lda BUFFER+3
	sta <SCROLL_LINES_TARGET
	lda BUFFER+4
	sta <SCROLL_LINES_TARGET+1
	lda BUFFER+5
	sta <LAST_STARTED_SAVE
	beq .end
	; maybe it's time to clean flash?
	lda <STATE_CELL_NEXT+1
	cmp #$1F
	bne .clean_not_required
	jsr saving_warning_show
	jsr flash_cleanup
	jsr saving_warning_hide
.clean_not_required:
	jsr save_last_game
.end:
	rts	
.ovf:
	; the very first game
	lda #0
	sta <SELECTED_GAME
	sta <SELECTED_GAME+1
	rts

save_last_game:
	jsr saving_warning_show
.save_last_game_again:
	lda <SAVES_BANK
	sta <NROM_BANK_L ; storing saves bank number
	lda #$FF
	sta <NROM_BANK_H ; at the very end of flash memory
	lda #$10
	sta COPY_SOURCE_ADDR ;$8010
	lda #$80
	sta COPY_SOURCE_ADDR+1
	ldx #16
	jsr flash_read ; reading 16 bytes to buffer
	; searching for free slot
	lda #$FF
	ldx #1
.loop:
	cmp BUFFER, x
	beq .found
	inx
	cpx #16
	bne .loop
	jsr flash_cleanup  ; not found, cleanup
	jmp .save_last_game_again ; repeast
.found:
	txa
	pha  ; storing save slot number
	clc
	adc #$10
	sta COPY_DEST_ADDR
	lda #$80
	sta COPY_DEST_ADDR+1
	lda <LAST_STARTED_SAVE
  sta BUFFER
  ldx #1
  jsr flash_write
  pla
  tax
  lsr A
  clc
  adc <SAVES_BANK
  sta <NROM_BANK_L
  lda #$00
  sta COPY_DEST_ADDR
  txa
  and #1
  bne .subbankA0
  lda #$80
  bmi .subbank
.subbankA0:
  lda #$A0
.subbank:
  sta COPY_DEST_ADDR+1
  jsr flash_write_prg_ram
  lda #0
  sta <LAST_STARTED_SAVE
  jsr write_state
  jsr saving_warning_hide
  rts

find_saves_bank:
  lda #$00
  sta COPY_SOURCE_ADDR
  lda #$80
  sta COPY_SOURCE_ADDR+1  
  lda #$FF
  sta <NROM_BANK_H
  lda #($100 - 8 * 2) ; last - 8 (8 banks*16kb = sector size) * 2
.bloop:
  sta <NROM_BANK_L
  ldx #8
  jsr flash_read
  ldx #0
.loop:
  lda saves_signature, x
  cmp BUFFER, x
  bne .failed
  inx
  cpx #8
  bne .loop
  lda <NROM_BANK_L
  jmp .end
.failed:
  lda <NROM_BANK_L
  clc
  adc #8 ; +128kb, next sector
  bne .bloop
.end:
  sta <SAVES_BANK
  rts

; A - game save number
; Returns Y - slot number (or zero if no save)
find_save_slot:
  cmp #0
  bne .savable_game
  tay
  rts
.savable_game:
  ldx <SAVES_BANK
  stx <NROM_BANK_L ; storing saves bank number
  ldx #$FF
  stx <NROM_BANK_H ; at the very end of flash memory
  ldx #$10
  stx COPY_SOURCE_ADDR ;$8010
  ldx #$80
  stx COPY_SOURCE_ADDR+1
  ldx #16
  pha
  jsr flash_read
  pla
  ; searching for last save slot
  ldy #0
  ldx #1
.save_search_loop:
  cmp BUFFER, x
  bne .save_search_next
  pha ; copy X to Y, keep A
  txa
  tay
  pla
.save_search_next:
  inx
  cpx #16
  bne .save_search_loop  
  ; Y contains slot number... or zero
  rts

flash_write_prg_ram:
  lda #$00
  sta COPY_SOURCE_ADDR
  lda #$60
  sta COPY_SOURCE_ADDR+1
.loop:
  lda #$80
  sta $A001
  ldy #0
.read_loop:
  lda [COPY_SOURCE_ADDR], y
  sta BUFFER, y
  iny
  bne .read_loop
  ldx #0
  jsr flash_write  
  inc COPY_DEST_ADDR+1
  inc COPY_SOURCE_ADDR+1
  bpl .loop
  rts

flash_force_erase:
  jsr error_sound
  jsr saving_warning_show
  lda #$F0
  sta NROM_BANK_L
  lda #$FF
  sta NROM_BANK_H
  jsr flash_erase_sector
  jsr switch_sector
  jsr flash_erase_sector
  lda #0
  sta SAVES_BANK
  jsr saving_warning_hide
  rts

flash_format_sector:
  ldx <SAVES_BANK
  stx <NROM_BANK_L ; storing saves bank number
  ldx #$FF
  stx <NROM_BANK_H ; at the very end of flash memory
  jsr flash_erase_sector
  ldy #8
.load:
  lda saves_signature, y
  sta BUFFER, y
  dey
  bpl .load
  lda #$00
  sta COPY_DEST_ADDR
  lda #$80
  sta COPY_DEST_ADDR+1  
  ldx #8
  jsr flash_write
  lda #$20
  sta <STATE_CELL_NEXT
  lda #$80
  sta <STATE_CELL_NEXT+1
  rts

flash_cleanup:
  lda saves_count
  beq flash_format_sector ; no games with saves
  ; format other sector (erase, write signature)
  ; go to dest bank
  jsr switch_sector ; dest
  jsr flash_format_sector ; write signature
  jsr switch_sector ; source
  lda #0
.save_id_loop:
  cmp saves_count
  beq .end
  clc
  adc #1 ; next
  cmp <LAST_STARTED_SAVE
  beq .save_id_loop ; skip actual save
  jsr find_save_slot
  cpy #0 ; if save slop is 0...
  beq .save_id_loop ; not found, next
  pha ; save current save id  
  sta BUFFER
  tya
  pha ; save slot id
  clc
  adc #$10
  sta COPY_DEST_ADDR
  lda #$80
  sta COPY_DEST_ADDR+1
  jsr switch_sector ; dest
  ldx #1
  jsr flash_write  
  jsr switch_sector ; source
  pla ; load slot id
  pha ; but still keep it in stack
  lsr A
  clc
  adc <SAVES_BANK
  sta <NROM_BANK_L
  lda #$FF
  sta <NROM_BANK_H
  lda #$00
  sta COPY_SOURCE_ADDR
  sta COPY_DEST_ADDR
  pla ; load slot id
  and #1
  bne .subbankA0
  lda #$80
  bmi .subbank
.subbankA0:
  lda #$A0
.subbank:
  sta COPY_SOURCE_ADDR+1
  sta COPY_DEST_ADDR+1
.copy_loop:
  ldx #0
  jsr flash_read ; read 256 bytes to buffer
  jsr switch_sector ; dest sector
  ldx #0
  jsr flash_write ; write 256 bytes from buffer
  jsr switch_sector ; source sector
  inc COPY_SOURCE_ADDR+1 ; +256 of source address
  inc COPY_DEST_ADDR+1 ; +256 of dest address
  lda COPY_DEST_ADDR+1 ; load high byte of dest address and check it
  cmp #$A0 ; $A0? it's end of data
  beq .copy_end ; go to end
  cmp #$C0 ; $C0? it's end too... 
  bne .copy_loop ; continue copying otherwise
.copy_end:  
  pla ; restore save id from stack
  jmp .save_id_loop ; repeat with next game
.end:
  ldx <SAVES_BANK
  stx <NROM_BANK_L ; storing saves bank number
  ldx #$FF
  stx <NROM_BANK_H ; at the very end of flash memory
  jsr flash_erase_sector ; erasing source sector
  jsr switch_sector ; finally switching to new sector
  rts

switch_sector:
  pha
  lda <SAVES_BANK
  eor #8 ; 8 banks*16kb = sector size
  sta <SAVES_BANK  
  lda <NROM_BANK_L
  eor #8 ; 8 banks*16kb = sector size
  sta <NROM_BANK_L
  pla
  rts

saves_signature:
  .db 'C','O','O','L','S','A','V','E'  
