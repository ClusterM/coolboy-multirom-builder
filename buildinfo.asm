	; build info
show_build_info:
	bit $2002
	lda #$21
	sta $2006
	lda #$44
	sta $2006
	; filename
  lda #LOW(build_info0)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(build_info0)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

	lda #$21
	sta $2006
	lda #$84
	sta $2006
	; build date
  lda #LOW(build_info2)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(build_info2)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
	
	lda #$21
	sta $2006
	lda #$C4
	sta $2006
	; build time
  lda #LOW(build_info3)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(build_info3)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

	lda #$22
	sta $2006
	lda #$04
	sta $2006
	; console region/type
  lda #LOW(console_type_text)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(console_type_text)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
	
	lda <CONSOLE_TYPE
	and #$08
	beq .console_type_no_NEW
  lda #LOW(console_type_NEW)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(console_type_NEW)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_NEW:
	lda <CONSOLE_TYPE
	and #$01
	beq .console_type_no_NTSC
  lda #LOW(console_type_NTSC)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(console_type_NTSC)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_NTSC:
	lda <CONSOLE_TYPE
	and #$02
	beq .console_type_no_PAL
  lda #LOW(console_type_PAL)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(console_type_PAL)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_PAL:
	lda <CONSOLE_TYPE
	and #$04
	beq .console_type_no_DENDY
  lda #LOW(console_type_DENDY)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(console_type_DENDY)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_DENDY:

print_flash_type:
	lda #$22
	sta $2006
	lda #$44
	sta $2006
	; flash memory type and size
	ldy #0
.next_char:
	lda flash_type, y
	sta $2007
	iny
	cmp #0
	bne .next_char
	lda <FLASH_TYPE
	bne .writable
	
	ldy #0
.ro_next_char:
	lda flash_type_read_only, y
	sta $2007
	iny
	cmp #0
	bne .ro_next_char	
	jmp .end

.writable:
	ldy #0
.writable_next_char:
	lda flash_type_writable, y
	sta $2007
	iny
	cmp #0
	bne .writable_next_char
	
	lda <FLASH_TYPE
	cmp #21
	bne .not_2mb
	ldy #0
.2mb_next_char:
	lda flash_type_2mb, y
	sta $2007
	iny
	cmp #0
	bne .2mb_next_char
.not_2mb:

	lda <FLASH_TYPE
	cmp #22
	bne .not_4mb
	ldy #0
.4mb_next_char:
	lda flash_type_4mb, y
	sta $2007
	iny
	cmp #0
	bne .4mb_next_char
.not_4mb:

	lda <FLASH_TYPE
	cmp #23
	bne .not_8mb
	ldy #0
.8mb_next_char:
	lda flash_type_8mb, y
	sta $2007
	iny
	cmp #0
	bne .8mb_next_char
.not_8mb:

	lda <FLASH_TYPE
	cmp #24
	bne .not_16mb
	ldy #0
.16mb_next_char:
	lda flash_type_16mb, y
	sta $2007
	iny
	cmp #0
	bne .16mb_next_char
.not_16mb:

	lda <FLASH_TYPE
	cmp #25
	bne .not_32mb
	ldy #0
.32mb_next_char:
	lda flash_type_32mb, y
	sta $2007
	iny
	cmp #0
	bne .32mb_next_char
.not_32mb:

.end:
	lda #$23
	sta $2006
	lda #$00
	sta $2006
	jsr draw_footer1
	jsr draw_footer2
  jsr load_text_palette

	lda #$FF
	sta <SPRITE_1_Y_TARGET
	sta <SPRITE_1_Y_TARGET
	sta SPRITE_0_Y
	sta SPRITE_1_Y
	jsr sprite_dma_copy

	lda #0
	sta <SCROLL_LINES_TARGET
	sta <SCROLL_LINES_TARGET+1
	sta <SCROLL_LINES
	sta <SCROLL_LINES+1
	sta <SELECTED_GAME
	sta <SELECTED_GAME+1	
	sta <SCROLL_LINES_MODULO

show_build_info_infin:
	jsr waitblank
	lda #%00011110
	sta $2001
	jmp show_build_info_infin
