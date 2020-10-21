NESASM=tools/nesasm.exe
EMU=/D/Emulators/fceux/fceux.exe
SOURCES=menu.asm
MENU=menu.nes
TILER=tools/NesTiler.exe
COMBINER=tools/CoolboyCombiner.exe
DUMPER=tools/famicom-dumper.exe 
PORT?=auto
MENU_IMAGE?=menu.png
NOSORT?=0
SORT?=
GAMES?=games.list
SIZE?=32
OFFSETS?=offsets_$(GAMES).xml
REPORT?=report_$(GAMES).txt
EXECUTABLE?=menu_$(GAMES).nes
UNIF?=multirom_$(GAMES).unf
LANGUAGE?=eng
COOLBOY_VERSION?=1
NESASM_OPTS+=--symbols=$(UNIF) --symbols-offset=24 -iWss
COMBINER_OPTS+=--ver $(COOLBOY_VERSION)

ifneq ($(NOSORT),0)
SORT=--nosort
endif

ifdef BADSECTORS
BADS := --badsectors $(BADSECTORS)
endif

all: $(UNIF)
build: $(UNIF)
unif: $(UNIF)

$(EXECUTABLE): $(SOURCES) games.asm header footer symbols sprites
	$(NESASM) $(SOURCES) --output=$(EXECUTABLE) $(NESASM_OPTS)

games.asm $(OFFSETS): $(GAMES)
	$(COMBINER) prepare --games $(GAMES) --asm games.asm --maxsize $(SIZE) --offsets $(OFFSETS) --report $(REPORT) $(SORT) --language $(LANGUAGE) $(BADS) $(COMBINER_OPTS)

$(UNIF): $(EXECUTABLE) $(OFFSETS)
	$(COMBINER) combine --loader $(EXECUTABLE) --offsets $(OFFSETS) --unif $(UNIF) $(COMBINER_OPTS)

bin: $(EXECUTABLE) $(OFFSETS)
	$(COMBINER) combine --loader $(EXECUTABLE) --offsets $(OFFSETS) --bin $(UNIF).bin $(COMBINER_OPTS)

clean:
	rm -f *.dat *.nl *.lst stdout.txt games.asm menu.bin $(MENU) $(UNIF) $(EXECUTABLE) $(REPORT) $(OFFSETS)

run: $(UNIF)
	$(EMU) $(UNIF)

upload: $(UNIF)
	upload.bat $(UNIF)

runmenu: $(EXECUTABLE)
	$(EMU) $(EXECUTABLE)

flash: clean $(UNIF)
	$(DUMPER) write-coolboy --file $(UNIF) --port $(PORT) $(BADS) --sound --check --lock

header: menu_header.png
	$(TILER) --i0 menu_header.png --enable-palettes 0,1,2 --out-pattern-table0 menu_header_pattern_table.bin --out-name-table0 menu_header_name_table.bin --out-attribute-table0 menu_header_attribute_table.bin --out-palette0 bg_palette0.bin --out-palette1 bg_palette1.bin --out-palette2 bg_palette2.bin --bgcolor #000000

menu_header_pattern_table.bin: header
menu_header_name_table.bin: header
menu_header_attribute_table.bin: header
bg_palette0.bin: header
bg_palette1.bin: header
bg_palette2.bin: header

footer_symbols: menu_symbols.png menu_footer.png
	$(TILER) -i0 menu_symbols.png -i1 menu_footer.png --enable-palettes 3 --pattern-offset0 128 --pattern-offset1 90 --out-pattern-table0 menu_symbols.bin --out-pattern-table1 menu_footer_pattern_table.bin --out-name-table1 menu_footer_name_table.bin --out-palette3 bg_palette3.bin --bgcolor #000000

footer: footer_symbols
symbols: footer_symbols

sprites: menu_sprites.png
	$(TILER) --mode sprites -i0 menu_sprites.png --enable-palettes 0 --out-pattern-table0 menu_sprites.bin --out-palette0 sprites_palette.bin --bgcolor #000000

menu_sprites.bin: sprites
sprites_palette.bin: sprites

menu_symbols.bin: footer_symbols
menu_footer_pattern_table.bin: footer_symbols
menu_footer_name_table.bin: footer_symbols
bg_palette3.bin: footer_symbols

badstest:
	$(DUMPER) test-bads-coolboy --port $(PORT) --sound

sramtest:
	$(DUMPER) test-prg-ram -p $(PORT) --mapper coolboy --sound

batterytest:
	$(DUMPER) test-battery --port $(PORT) --mapper coolboy --sound

chrtest:
	$(DUMPER) test-chr-coolboy --port $(PORT) --sound

info:
	$(DUMPER) info-coolboy --port $(PORT)
