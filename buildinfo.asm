PRG_RAM_PRESENT .rs 1 ; PRG RAM present flag

  ; build info
show_build_info:
  ; detect flash memory type
  jsr flash_detect
  ; detect CHR RAM size
  jsr detect_chr_ram_size
  ; check presense of PRG RAM
  jsr prg_ram_detect

  ; clear screen
  jsr clear_screen

print_version:
  lda #$20
  sta PPUADDR
  lda #$E4
  sta PPUADDR
  ; filename
  lda #LOW(string_version)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_version)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_commit:
  lda #$21
  sta PPUADDR
  lda #$24
  sta PPUADDR
  ; filename
  lda #LOW(string_commit)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_commit)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_filename:
  bit PPUSTATUS
  lda #$21
  sta PPUADDR
  lda #$64
  sta PPUADDR
  ; filename
  lda #LOW(string_file)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_file)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_build_date:
  lda #$21
  sta PPUADDR
  lda #$A4
  sta PPUADDR
  ; build date
  lda #LOW(string_build_date)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_build_date)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_build_time:
  lda #$21
  sta PPUADDR
  lda #$E4
  sta PPUADDR
  ; build time
  lda #LOW(string_build_time)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_build_time)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

  lda #$22
  sta PPUADDR
  lda #$24
  sta PPUADDR
  ; console region/type
  lda #LOW(string_console_type)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_console_type)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

  lda <CONSOLE_TYPE
  and #$08
  beq .console_type_no_NEW
  lda #LOW(string_new)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_new)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_NEW:
  lda <CONSOLE_TYPE
  and #$01
  beq .console_type_no_NTSC
  lda #LOW(string_ntsc)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_ntsc)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_NTSC:
  lda <CONSOLE_TYPE
  and #$02
  beq .console_type_no_PAL
  lda #LOW(string_pal)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_pal)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_PAL:
  lda <CONSOLE_TYPE
  and #$04
  beq .console_type_no_DENDY
  lda #LOW(string_dendy)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_dendy)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
.console_type_no_DENDY:

  ; flash memory type and size
print_flash_type:
  lda #$22
  sta PPUADDR
  lda #$64
  sta PPUADDR
  lda #LOW(string_flash)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_flash)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

  ; is it writable?
  lda <FLASH_TYPE
  bne .writable
  lda #LOW(string_read_only)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_read_only)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
  jmp print_chr_size
  ; yes, it's writable
.writable:
  lda #LOW(string_writable)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_writable)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
  ; how many memory?
  lda <FLASH_TYPE
  sec
  sbc #20
  asl A
  tay
  lda flash_sizes, y
  sta <COPY_SOURCE_ADDR
  lda flash_sizes+1, y
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_chr_size:
  lda #$22
  sta PPUADDR
  lda #$A4
  sta PPUADDR
  lda #LOW(string_chr_ram)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_chr_ram)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
  lda <CHR_RAM_SIZE
  asl A
  tay
  lda chr_ram_sizes, y
  sta <COPY_SOURCE_ADDR
  lda chr_ram_sizes+1, y
  sta <COPY_SOURCE_ADDR+1
  jsr print_text

print_prg_ram:
  lda #$22
  sta PPUADDR
  lda #$E4
  sta PPUADDR
  lda #LOW(string_prg_ram)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_prg_ram)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
  lda PRG_RAM_PRESENT
  beq .not_present
  lda #LOW(string_present)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_present)
  sta <COPY_SOURCE_ADDR+1
  jmp .end
.not_present:
  lda #LOW(string_not_available)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_not_available)
  sta <COPY_SOURCE_ADDR+1
.end:
  jsr print_text

  ; draw header
  lda #$20
  sta PPUADDR
  lda #$00
  sta PPUADDR
  jsr draw_header1
  jsr draw_header2

  ; draw footer
  lda #$23
  sta PPUADDR
  lda #$40
  sta PPUADDR
  jsr draw_footer1
  jsr draw_footer2

  jsr load_text_attributes

  ; disable arraows
  lda #$FF
  sta <SPRITE_Y_TARGET
  sta SPRITE_0_Y
  sta SPRITE_1_Y

  ; disable scrolling
  inc SCROLL_LOCK

  ; enable PPU
  jsr waitblank_simple
  lda #%00001000 ; first nametable
  sta PPUCTRL
  lda #%00011110 ; enable sprites
  sta PPUMASK

  ; start dimming
  jsr dim_base_palette_in

show_build_info_infin:
  jsr waitblank
  lda BUTTONS
  and #%00000011
  beq show_build_info_infin
  jsr dim_base_palette_out
  jmp Start

prg_ram_detect:
  lda #0
  sta PRG_RAM_PRESENT
  jsr enable_prg_ram
  lda #$AA
  .if (COOLBOY_SUBMAPPER != 2)
  sta $7000
  cmp $7000
  bne .end
  lda #$55
  sta $7000
  cmp $7000
  .else
  sta $6000
  cmp $6000
  bne .end
  lda #$55
  sta $6000
  cmp $6000
  .endif
  bne .end
  lda #1
  sta PRG_RAM_PRESENT
.end:
  jsr disable_prg_ram
  rts
