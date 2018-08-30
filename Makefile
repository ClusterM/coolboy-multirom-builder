NESASM=tools/nesasm.exe
EMU=fceux.exe
SOURCES=menu.asm
MENU=menu.nes
CONVERTER=tools/TilesConverter.exe
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
#NESASM_OPTS+=--symbols=$(UNIF) --symbols-offset=24 -iWss
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

$(EXECUTABLE): $(SOURCES) menu_pattern0.dat menu_nametable0.dat menu_palette0.dat menu_pattern1.dat menu_palette1.dat games.asm
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
	$(DUMPER) write-coolboy --file $(UNIF) --port $(PORT) $(BADS) --sound --check

menu_pattern0.dat: menu_bg
menu_nametable0.dat: menu_bg
menu_palette0.dat: menu_bg

menu_pattern1.dat: menu_sprites
menu_nametable1.dat: menu_sprites
menu_palette1.dat: menu_sprites

menu_bg: $(MENU_IMAGE)
	$(CONVERTER) $(MENU_IMAGE) menu_pattern0.dat menu_nametable0.dat menu_palette0.dat

menu_sprites: menu_sprites.png
	$(CONVERTER) menu_sprites.png menu_pattern1.dat menu_nametable1.dat menu_palette1.dat

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
