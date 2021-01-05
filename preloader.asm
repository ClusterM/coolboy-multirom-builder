  ; starting game!
start_game:
  ; disable PPU
  lda #%00000000
  sta PPUCTRL
  lda #%00000000
  sta PPUMASK
  ; wait for v-blank
  jsr waitblank_simple

  .if SECRETS>=3
  ; check for konami code
  lda <KONAMI_CODE_STATE
  cmp konami_code_length
  bne .no_konami_code
  lda games_count
  clc
  adc #2
  sta <SELECTED_GAME
  lda games_count+1
  adc #0
  sta <SELECTED_GAME+1
.no_konami_code:
  .endif

  ; loading game settings
  lda <SELECTED_GAME+1
  jsr select_prg_bank
  ldx <SELECTED_GAME
  lda loader_data_reg_0, x
  sta <LOADER_REG_0
  lda loader_data_reg_1, x
  sta <LOADER_REG_1
  lda loader_data_reg_2, x
  sta <LOADER_REG_2
  lda loader_data_reg_3, x
  sta <LOADER_REG_3
  lda loader_data_chr_start_bank_h, x
  sta <LOADER_CHR_START_H
  lda loader_data_chr_start_bank_l, x
  sta <LOADER_CHR_START_L
  lda loader_data_chr_start_bank_s, x
  sta <LOADER_CHR_START_S
  lda loader_data_chr_size_source, x
  sta <LOADER_CHR_SIZE_SOURCE
  lda loader_data_chr_size_target, x
  sta <LOADER_CHR_SIZE_TARGET
  lda loader_data_mirroring, x
  sta <LOADER_MIRRORING
  lda loader_data_game_save, x
  sta <LAST_STARTED_SAVE
  lda loader_data_game_flags, x
  and <CONSOLE_TYPE
  beq .compatible_console

  ; not compatible console!
  ; save state, without game save
  lda #0
  sta <LAST_STARTED_SAVE
  jsr save_state
  jsr load_text_palette
  lda #$21
  sta PPUADDR
  lda #$A0
  sta PPUADDR
  lda #LOW(string_incompatible_console)
  sta <COPY_SOURCE_ADDR
  lda #HIGH(string_incompatible_console)
  sta <COPY_SOURCE_ADDR+1
  jsr print_text
  bit PPUSTATUS
  lda #0
  sta PPUSCROLL
  sta PPUSCROLL
  lda #%00001000
  sta PPUCTRL
  lda #%00001010
  sta PPUMASK
  jsr waitblank_simple
.incompatible_print_wait_no_button:
  jsr read_controller
  lda <BUTTONS
  bne .incompatible_print_wait_no_button
.incompatible_print_wait_button:
  jsr read_controller
  lda <BUTTONS
  beq .incompatible_print_wait_button
  jmp Start

.compatible_console:
  jsr clear_screen
  ; clear sprite data
  jsr clear_sprites
  ; load this empty data
  jsr sprite_dma_copy
  ; load black palette
  jsr load_black
  ; loading game settings
  jsr save_state
  jsr load_all_chr_banks

  lda <LAST_STARTED_SAVE
  jsr find_save_slot
  cpy #0
  beq .no_save
  tya
  lsr A
  clc
  adc <SAVES_BANK
  sta <NROM_BANK_L
  lda #$00
  sta <COPY_SOURCE_ADDR
  tya
  and #1
  bne .subbankA0
  lda #$80
  bmi .subbank
.subbankA0:
  lda #$A0
.subbank:
  sta <COPY_SOURCE_ADDR+1
  jsr flash_load_prg_ram
.no_save:
  ; wait for sound end and reset sound registers
  jsr wait_sound_end
  jsr reset_sound
  ; start loader stored into RAM
  jmp loader
