	; build info
show_build_info:
	bit $2002
	lda #$21
	sta $2006
	lda #$64
	sta $2006
	; filename
	ldy #0
.info0_print_next_char:
	lda build_info0, y
	sta $2007
	iny
	cmp #0
	bne .info0_print_next_char	

	lda #$21
	sta $2006
	lda #$A4
	sta $2006
	; build date
	ldy #0
.info2_print_next_char:
	lda build_info2, y
	sta $2007
	iny
	cmp #0
	bne .info2_print_next_char		
	
	lda #$21
	sta $2006
	lda #$E4
	sta $2006
	; build time
	ldy #0
.info3_print_next_char:
	lda build_info3, y
	sta $2007
	iny
	cmp #0
	bne .info3_print_next_char		

	lda #$22
	sta $2006
	lda #$24
	sta $2006
	; console region/type
	ldy #0
.console_type_print_next_char:
	lda console_type_text, y
	sta $2007
	iny
	cmp #0
	bne .console_type_print_next_char		
	
	lda <CONSOLE_TYPE
	and #$08
	beq .console_type_no_NEW
	ldy #0
.console_type_print_NEW:
	lda console_type_NEW, y
	sta $2007
	iny
	cmp #0
	bne .console_type_print_NEW
.console_type_no_NEW:
	lda <CONSOLE_TYPE
	and #$01
	beq .console_type_no_NTSC
	ldy #0
.console_type_print_NTSC:
	lda console_type_NTSC, y
	sta $2007
	iny
	cmp #0
	bne .console_type_print_NTSC	
.console_type_no_NTSC:
	lda <CONSOLE_TYPE
	and #$02
	beq .console_type_no_PAL
	ldy #0
.console_type_print_PAL:
	lda console_type_PAL, y
	sta $2007
	iny
	cmp #0
	bne .console_type_print_PAL
.console_type_no_PAL:
	lda <CONSOLE_TYPE
	and #$04
	beq .console_type_no_DENDY
	ldy #0
.console_type_print_DENDY:
	lda console_type_DENDY, y
	sta $2007
	iny
	cmp #0
	bne .console_type_print_DENDY
.console_type_no_DENDY:

	lda #$22
	sta $2006
	lda #$64
	sta $2006
	; flash memory type and size
	ldy #0
flash_type_print_next_char:
	lda flash_type, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_next_char
	lda <FLASH_TYPE
	bne flash_type_print_writable
	
	ldy #0
flash_type_print_ro_next_char:
	lda flash_type_read_only, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_ro_next_char	
	jmp flash_type_print_end

flash_type_print_writable:
	ldy #0
flash_type_print_writable_next_char:
	lda flash_type_writable, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_writable_next_char
	
	lda <FLASH_TYPE
	cmp #21
	bne flash_type_not_2mb
	ldy #0
flash_type_print_2mb_next_char:
	lda flash_type_2mb, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_2mb_next_char
flash_type_not_2mb:

	lda <FLASH_TYPE
	cmp #22
	bne flash_type_not_4mb
	ldy #0
flash_type_print_4mb_next_char:
	lda flash_type_4mb, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_4mb_next_char
flash_type_not_4mb:

	lda <FLASH_TYPE
	cmp #23
	bne flash_type_not_8mb
	ldy #0
flash_type_print_8mb_next_char:
	lda flash_type_8mb, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_8mb_next_char
flash_type_not_8mb:

	lda <FLASH_TYPE
	cmp #24
	bne flash_type_not_16mb
	ldy #0
flash_type_print_16mb_next_char:
	lda flash_type_16mb, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_16mb_next_char
flash_type_not_16mb:

	lda <FLASH_TYPE
	cmp #25
	bne flash_type_not_32mb
	ldy #0
flash_type_print_32mb_next_char:
	lda flash_type_32mb, y
	sta $2007
	iny
	cmp #0
	bne flash_type_print_32mb_next_char
flash_type_not_32mb:

flash_type_print_end:

	lda #$23
	sta $2006
	lda #$00
	sta $2006
	jsr draw_footer1
	jsr draw_footer2

	lda #$23
	sta $2006
	lda #$C8
	sta $2006
	lda #$FF
	ldy #$38
build_info_palette:
	sta $2007
	dey
	bne build_info_palette

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
