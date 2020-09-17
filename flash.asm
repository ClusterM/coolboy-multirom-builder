FLASH_TYPE .rs 1 ; flash memory type
STATE_CELL_NEXT .rs 2 ; address of cell for next state save

flash_detect:
  lda #$F0
  sta $8000
  lda #0
  sta <FLASH_TYPE
  lda #$98
  sta $8AAA
  lda $8020
  cmp #'Q'
  bne .end
  lda $8022
  cmp #'R'
  bne .end
  lda $8024
  cmp #'I'
  bne .end
  lda $804E
  sta <FLASH_TYPE
.end:
  lda #$F0
  sta $8000
  jmp flash_return

  ; NROM_BANK_L, NROM_BANK_H - bank
flash_erase_sector:
  jsr select_16k_bank
  lda #$F0
  sta $8000
  lda #$AA
  sta $8AAA  
  lda #$55
  sta $8555  
  lda #$80
  sta $8AAA  
  lda #$AA
  sta $8AAA  
  lda #$55
  sta $8555  
  lda #$30
  sta $8000  
.wait:
  lda $8000
  cmp #$FF
  bne .wait
  jmp flash_return

  ; NROM_BANK_L, NROM_BANK_H - bank
  ; COPY_DEST_ADDR - dest. address
  ; x - count (bytes)
flash_write:
  jsr select_16k_bank
  lda #$80 ; PRG-RAM unprotect
  sta $A001
  lda #$F0 ; reset flash
  sta $8000
  ldy #$00
.loop:
  lda #$AA
  sta $8AAA
  lda #$55
  sta $8555
  lda #$A0
  sta $8AAA
  lda BUFFER, y
  sta [COPY_DEST_ADDR], y
.wait:
  cmp BUFFER, y
  bne .wait
  cmp BUFFER, y
  bne .wait
  iny  
  dex
  bne .loop
.end:
  jmp flash_return  

  ; read up to 256 bytes from flash to RAM
  ; NROM_BANK_L, NROM_BANK_H - bank
  ; COPY_SOURCE_ADDR - source address
  ; x - count (bytes)
flash_read:
  jsr select_16k_bank
  ldy #$00
.loop:
  lda [COPY_SOURCE_ADDR], y
  sta BUFFER, y
  iny
  dex
  bne .loop  
  jmp flash_return
  
flash_load_prg_ram:
  ldx #$00
  stx COPY_DEST_ADDR
  ldx #$60
  stx COPY_DEST_ADDR+1
  ldx #0
.block_loop:
  txa
  pha
  ; load 256 bytes to buffer
  ldx #0
  jsr flash_read
  pla
  tax
  ldy #0
  lda #$80
  sta $A001 ; PRG-RAM un-protect  
.loop:
  lda BUFFER, y
  pha ; original value to stack
  ; every 4th byte...
  tya
  and #%00000011
  cmp #%00000011
  bne .store
  ; pulling back value
  pla
  ; shifting high bit to C flag
  asl A
  ; storing high bit to RAM
  ror PRG_RAM_FIX, x
  ; shifting value back clearing high bit
  lsr A
  ; back to stack
  pha
  ; chech y again, every 32 byte increase x index
  tya
  and #%00011111
  cmp #%00011111
  bne .store
  inx  
.store:
  ; storing values in cartridge's RAM
  pla
  sta [COPY_DEST_ADDR], y
  iny
  bne .loop
  inc COPY_SOURCE_ADDR+1
  inc COPY_DEST_ADDR+1
  ; if high bit of COPY_DEST_ADDR+1 is set it's $8000
  bpl .block_loop
  jmp flash_return

  ; find non-FF byte with 8-byte step
  ; NROM_BANK_L, NROM_BANK_H - bank
  ; STATE_CELL_NEXT - start address, result
flash_find_empty_cell:
  jsr select_16k_bank
  lda #0
  ldx #0
.prep_loop:
  sta BUFFER, x
  clc
  adc #8
  inx
  bne .prep_loop  
  jsr select_16k_bank
  lda #$80
  sta <STATE_CELL_NEXT+1
  lda #$00
  sta <STATE_CELL_NEXT
  ldx #3
  lda #$FF
.loop:
  inx
  ldy BUFFER, x
  bne .next
  inc <STATE_CELL_NEXT+1
.next:
  cmp [STATE_CELL_NEXT], y
  bne .loop
.end:
  sty <STATE_CELL_NEXT
  jmp flash_return
    
  ; Returh to 0th bank and reinit
flash_return:
  ldx #$00
  ldy #$00
  stx $8000
  sty $8001 ; 0  
  inx
  iny
  iny
  stx $8000
  sty $8001 ; 2
  inx
  iny
  iny
  stx $8000
  sty $8001 ; 4
  inx
  iny
  stx $8000
  sty $8001 ; 5
  inx
  iny
  stx $8000
  sty $8001 ; 6
  inx
  iny
  stx $8000
  sty $8001 ; 7  
  lda #$01
  sta $A000 ; mirroring
  lda #$00
  sta $A001 ; PRG-RAM protect    
  sta COOLBOY_REG_0
  sta COOLBOY_REG_1
  sta COOLBOY_REG_2
  sta COOLBOY_REG_3
  rts
