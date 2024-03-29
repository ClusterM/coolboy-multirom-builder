; INES header stuff
  .inesprg 8   ; 8 banks of PRG = 128kB
  .ineschr 0   ; no CHR, RAM only
  .inesmir 0   ; mirroring (ignored)
  .inesmap 4   ; MMC3 mapper

  ; default settings
  ; enable main sounds
  .ifndef ENABLE_SOUND
ENABLE_SOUND .equ 1
  .endif
  ; number of stars
  .ifndef STARS
STARS .equ 30
  .endif
  ; stars direction (0 - down to up, 1 - up to down)
  .ifndef STARS_DIRECTION
STARS_DIRECTION .equ 1
  .endif
  ; star spawn interval
  .ifndef STAR_SPAWN_INTERVAL
STAR_SPAWN_INTERVAL .equ 90
  .endif
  ; remember last started game
  .ifndef ENABLE_LAST_GAME_SAVING
ENABLE_LAST_GAME_SAVING .equ 1
  .endif
  ; show right cursor
  .ifndef ENABLE_RIGHT_CURSOR
ENABLE_RIGHT_CURSOR .equ 1
  .endif
  ; game names offset from the left
  .ifndef GAME_NAMES_OFFSET
GAME_NAMES_OFFSET .equ 1
  .endif
  ; time before button autorepeat
  .ifndef BUTTON_REPEAT_FRAMES
BUTTON_REPEAT_FRAMES .equ 30
  .endif
  ; minimum number of games for screen wrap feature
  .ifndef WRAP_GAMES
WRAP_GAMES .equ 30
  .endif
  ; enable dim-in (on startup, etc)
  .ifndef ENABLE_DIM_IN
ENABLE_DIM_IN .equ 1
  .endif
  ; dim-in speed (more - slower)
  .ifndef DIM_IN_DELAY
DIM_IN_DELAY .equ 5
  .endif
  ; enable dim-out (before game launch, etc)
  .ifndef ENABLE_DIM_OUT
ENABLE_DIM_OUT .equ 1
  .endif
  ; dim-out speed (more - slower)
  .ifndef DIM_OUT_DELAY
DIM_OUT_DELAY .equ 1
  .endif
  ; save cursor position immediately
  .ifndef INSTANT_STATE_SAVE
INSTANT_STATE_SAVE .equ 0
  .endif
  .ifndef USE_FLASH_WRITING
USE_FLASH_WRITING .equ 0
  .endif
  .ifndef COOLBOY_SUBMAPPER
COOLBOY_SUBMAPPER .equ 0
  .endif
  .ifndef GAMES_DB
GAMES_DB                        .sequ "games.asm"
  .endif
  .ifndef MENU_HEADER_PATTERN_TABLE_BIN
MENU_HEADER_PATTERN_TABLE_BIN   .sequ "menu_header_pattern_table.bin"
  .endif
  .ifndef MENU_HEADER_NAME_TABLE_BIN
MENU_HEADER_NAME_TABLE_BIN      .sequ "menu_header_name_table.bin"
  .endif
  .ifndef MENU_HEADER_ATTRIBUTE_TABLE_BIN
MENU_HEADER_ATTRIBUTE_TABLE_BIN .sequ "menu_header_attribute_table.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_0
MENU_HEADER_BG_PALETTE_0        .sequ "bg_palette0.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_1
MENU_HEADER_BG_PALETTE_1        .sequ "bg_palette1.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_2
MENU_HEADER_BG_PALETTE_2        .sequ "bg_palette2.bin"
  .endif
  .ifndef GAMES_DB
GAMES_DB                        .sequ "games.asm"
  .endif
  .ifndef MENU_HEADER_PATTERN_TABLE_BIN
MENU_HEADER_PATTERN_TABLE_BIN   .sequ "menu_header_pattern_table.bin"
  .endif
  .ifndef MENU_HEADER_NAME_TABLE_BIN
MENU_HEADER_NAME_TABLE_BIN      .sequ "menu_header_name_table.bin"
  .endif
  .ifndef MENU_HEADER_ATTRIBUTE_TABLE_BIN
MENU_HEADER_ATTRIBUTE_TABLE_BIN .sequ "menu_header_attribute_table.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_0
MENU_HEADER_BG_PALETTE_0        .sequ "bg_palette0.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_1
MENU_HEADER_BG_PALETTE_1        .sequ "bg_palette1.bin"
  .endif
  .ifndef MENU_HEADER_BG_PALETTE_2
MENU_HEADER_BG_PALETTE_2        .sequ "bg_palette2.bin"
  .endif

  .if (COOLBOY_SUBMAPPER = 1) | (COOLBOY_SUBMAPPER = 3) | (COOLBOY_SUBMAPPER = 5) | (COOLBOY_SUBMAPPER = 7)
COOLBOY_REG_0 .equ $5000
COOLBOY_REG_1 .equ $5001
COOLBOY_REG_2 .equ $5002
COOLBOY_REG_3 .equ $5003
  .endif
  .if (COOLBOY_SUBMAPPER = 0) | (COOLBOY_SUBMAPPER = 4) | (COOLBOY_SUBMAPPER = 6)
COOLBOY_REG_0 .equ $6000
COOLBOY_REG_1 .equ $6001
COOLBOY_REG_2 .equ $6002
COOLBOY_REG_3 .equ $6003
  .endif
  .if COOLBOY_SUBMAPPER = 2
COOLBOY_REG_0 .equ $7000
COOLBOY_REG_1 .equ $7001
COOLBOY_REG_2 .equ $7002
COOLBOY_REG_3 .equ $7003
  .endif

  .include GAMES_DB

  .rsset $0200
BUFFER .rs 256 ; buffer for all I/O operations
  .rsset $0300
PRG_RAM_FIX .rs 256 ; buffer for COOLBOY's PRG RAM highest bit

  ; sprites data
  .rsset $0400
SPRITES .rs 256

  .rsset $0000
  ; zero page variables
  ; some common variables
COPY_SOURCE_ADDR .rs 2
COPY_DEST_ADDR .rs 2
TMP .rs 2
  ; selected game
SELECTED_GAME .rs 2

  .bank 15   ; last bank
  .org $FFFA ; vectors
  .dw NMI    ; NMI vector
  .dw Start  ; reset vector
  .dw IRQ    ; interrupts

  .org $E000

Start:
  sei ; no interrupts

  ; reset stack
  ldx #$ff
  txs

  ; disable and reset sound
  jsr reset_sound

  ; disable PPU
  lda #%00000000
  sta PPUCTRL
  sta PPUMASK
  ; warm-up
  jsr waitblank_simple
  jsr waitblank_simple
  ; load black screen
  jsr load_black

  ; clean memory
  lda #$00
  sta <COPY_SOURCE_ADDR
  sta <COPY_SOURCE_ADDR+1
  ldy #$02
  ldx #$08
.loop:
  sta [COPY_SOURCE_ADDR], y
  iny
  bne .loop
  inc COPY_SOURCE_ADDR+1
  dex
  bne .loop

  ; loading loader and other RAM routines
  ldx #$00
.load_ram_routines:
  lda ram_routines+$C000, x
  sta ram_routines, x
  lda ram_routines+$C100, x
  sta ram_routines+$100, x
  lda ram_routines+$C200, x
  sta ram_routines+$200, x
  inx
  bne .load_ram_routines

  ; init banks and other cart stuff
  jsr banking_init
  ; detect console type
  jsr console_detect
  ; clean nametables
  jsr clear_screen
  ; load CHR data
  jsr load_base_chr
  ; clear all sprites data
  jsr clear_sprites
  ; load this empty sprites data
  jsr sprite_dma_copy
  ; read buttons
  jsr read_controller 
  ; loading saved cursor position and other data
  jsr load_state
  ; skip separator if any
  jsr check_separator_down

  ; init variables
  lda <SCROLL_LINES_TARGET
  sta <SCROLL_LINES
  sta <LAST_LINE_GAME
  sta <TMP
  lda <SCROLL_LINES_TARGET+1
  sta <SCROLL_LINES+1
  sta <LAST_LINE_GAME+1
  sta <TMP+1

  ; calculate modulo
.init_modulo:
  lda <TMP+1
  bne .do_init_modulo
  lda <TMP
  cmp #LINES_PER_SCREEN * 2
  bcs .do_init_modulo
  jmp .init_modulo_end
.do_init_modulo:
  lda <TMP
  sec
  sbc #LINES_PER_SCREEN * 2
  sta <TMP
  lda <TMP+1
  sbc #0
  sta <TMP+1
  jmp .init_modulo
.init_modulo_end:
  lda <TMP
  sta <SCROLL_LINES_MODULO
  sta <LAST_LINE_MODULO

  jsr set_scroll_targets

  ; sprites init
  lda <SPRITE_0_X_TARGET
  sta SPRITE_0_X
  lda <SPRITE_1_X_TARGET
  sta SPRITE_1_X
  lda <SPRITE_Y_TARGET
  sta SPRITE_0_Y
  sta SPRITE_1_Y
  lda #$00
  sta SPRITE_0_TILE
  .if ENABLE_RIGHT_CURSOR=0
  lda #$FF ;hide right cursor
  .endif
  sta SPRITE_1_TILE
  lda #%00000000
  sta SPRITE_0_ATTR
  lda #%01000000
  sta SPRITE_1_ATTR

  ; prevent first attributes load skip
  lda #1
  sta LAST_ATTRIBUTE_ADDRESS

  ; reser stars spawn timer
  lda #0
  sta <STAR_SPAWN_TIMER
  ; init random number generator
  jsr random_init

  lda #%00000100
  cmp <BUTTONS
  bne .skip_build_info
  ; build and hardware info
  jmp show_build_info
.skip_build_info:
  ldx #LOW(GAMES_COUNT)
  dex
  bne .not_single_game
  ldx #HIGH(GAMES_COUNT)
  bne .not_single_game
  stx <SELECTED_GAME
  stx <SELECTED_GAME+1
  jmp start_game
.not_single_game:
  .if SECRETS>=1
  lda #%00010011
  cmp <BUTTONS
  bne .not_hidden_rom_1
  lda #LOW(GAMES_COUNT)
  sta <SELECTED_GAME
  lda #HIGH(GAMES_COUNT)
  sta <SELECTED_GAME+1
  jmp start_game
.not_hidden_rom_1:
  .endif
  .if SECRETS>=2
  lda #%00100011
  cmp <BUTTONS
  bne .not_hidden_rom_2
  lda #LOW(GAMES_COUNT)
  clc
  adc #1
  sta <SELECTED_GAME
  lda #HIGH(GAMES_COUNT)
  adc #0
  sta <SELECTED_GAME+1
  jmp start_game
.not_hidden_rom_2:
  .endif
  lda #%00000111
  cmp <BUTTONS
  bne .not_tests
  ; lockout to disable COOLBOY registers
  lda #$80
  sta COOLBOY_REG_3
  jmp do_tests
.not_tests:

  ; printing game names
  ldx #LINES_PER_SCREEN
  jsr print_last_name
.print_next_game_at_start:
  inc <LAST_LINE_GAME
  lda <LAST_LINE_GAME
  bne .last_line_ok
  inc <LAST_LINE_GAME+1
.last_line_ok:
  inc <LAST_LINE_MODULO
  lda <LAST_LINE_MODULO
  cmp #LINES_PER_SCREEN * 2
  bne .modulo_ok
  lda #0
  sta <LAST_LINE_MODULO
.modulo_ok:
  jsr print_last_name
  dex
  bne .print_next_game_at_start

  jsr waitblank_simple
  lda #%00001010 ; second nametable
  sta PPUCTRL
  lda #%00001010 ; disabled sprites
  sta PPUMASK

  ; enable PPU
  lda #%00001000 ; first nametable
  sta PPUCTRL
  lda #%00011110 ; enable sprites
  sta PPUMASK

  ; start dimming
  jsr dim_base_palette_in

  ; do not hold buttons!
  jsr wait_buttons_really_not_pressed

  ; main loop
infin:
  jsr waitblank
  jsr buttons_check
  jmp infin

NMI: ; not used
  rti

IRQ: ; not used
  rti

  .include "banking.asm"
  .include "misc.asm"
  .include "buttons.asm"
  .include "video.asm"
  .include "sounds.asm"
  .include "tests.asm"
  .include "buildinfo.asm"
  .include "saves.asm"
  .include "preloader.asm"

  ; patterns
  .bank 12
  .org $8000
chr_data:
  .incbin MENU_HEADER_PATTERN_TABLE_BIN
  .org $8000 + 224 * 16
  .incbin "footer.pt"
  .org $8800
  .incbin "menu_symbols.bin"
  .org $9000
  .incbin "menu_sprites.bin"

  .bank 13
  .org $A000
  ; background
nametable_header:
  .incbin MENU_HEADER_NAME_TABLE_BIN
nametable_footer:
  .incbin "footer.nt"
tilepal:
  ; palette for background
  .incbin MENU_HEADER_BG_PALETTE_0
  .incbin MENU_HEADER_BG_PALETTE_1
  .incbin MENU_HEADER_BG_PALETTE_2
  .incbin "bg_palette3.bin"
  .org tilepal+$0F ; footer color
  .db $21
  .incbin "sprites_palette.bin" ; palette for sprites
  .org tilepal+$14 ; custom palette for stars
  .db $00, $22, $00, $00
  .db $00, $14, $00, $00
  .db $00, $05, $00, $00

header_attribute_table:
  .incbin MENU_HEADER_ATTRIBUTE_TABLE_BIN

  ; routines to be executed from RAM
  .bank 14
  .org $0500 ; actually it's $C500 in cartridge memory
ram_routines:
  .include "flash.asm"
  .include "loader.asm"
