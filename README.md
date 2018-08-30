# Coolboy Multirom Builder

It's a toolset that allows you to create multirom images for cheap COOLBOY (and clones) Famicom cartridges. Which can be writed with my other tool: https://github.com/ClusterM/famicom-dumper-client

Features:
* It can combine up to 768 games into single binary which can be writed to cheap COOLBOY cartridge
* Create menu where you can easily select game
* Can alphabetically sort games in menu if you need it
* Allows to use your own image for menu header
* On new versions of cartridges it can remember last played game and keep up to 15 game saves into flash memory
* Supports many different versions of cartridges
* Has built-in hardware tests
* Can show build info if user holding select on startup
* Can add up to three hidden ROMs for Up+A+B, Down+A+B and Konami Code combinations

How it works (for advanced users):
1. You need to create a text file with list of files and/or directories with ROMs, optionally you can specify game name for menu entry.
2. Run **CoolboyCombiner.exe** with "**prepare**" option, it will automatically use best way to fit game's data in the target ROM and create "**games.asm**" and offsets files. First one contains game names and commands for cartridge's chip to start them. Second file will contain info with address of data for every game in the final ROM.
3. Compile "**menu.asm**" using **nesasm** option. I'm using my own modification: https://github.com/ClusterM/nesasm. It will create .nes file with games menu.
4. After it you need to combine menu and games into one file. Run **CoolboyCombiner.exe** with "**combine**" option.
5. Done.

It sounds a bit complicated but this toolset is bundled with Makefile for **Make** tool to automatize the whole process. Windows users can use "**!build_rom.bat**" batch file. Default games list file is "**games.list**".

Now let me talk you much more info.


## Step by step

### Which cartridges are supported, how to select which cartridge to buy

There are many versions of COOLBOY cartridges and clones. Actually most of them are not "COOLBOY", it's just a name of the first cartridges with this chip.

You can find modifications:
* **With a different CHR size**. Some cartridges has only 128KB of RAM for CHR data and some 256KB. So 128KB version can't run many cool games with CHR size >128KB. You can easily detect amount of CHR RAM after looking at games list. If it has at least one game with large CHR, cartridge has 256KB. Example games: Megaman/Rockman 5, Earthbound Zero, Kirby's Adventure
* **With a different flash size**. Most cartridges has 32MBytes of flash memory but it's possible to find much more rare cartridges with less memory size. 32MBytes is maximum available size.
* **With a additional PRG RAM chip**. It's required by some games like The Legend of Zelda, Jurassic Park, etc. So if cartridge contains those games, it has PRG RAM chip. Also in case when you seller shows images of cartridge's board you can check presense of chip on the back side of it. Also it's possible to solder this chip manually.
* **With and without battery**. Battery is used to keep data in PRG RAM chip even after console is turned off. It's used to save games progress. So if cartridge has battery, it also has PRG-RAM chip. There is no way to detect present of battery but usually seller can say it, also check product description in shop.
* **With a directly writable and non-writable flash memory**. Some new cartridges can be rewrited directly without additional soldering and some not. Direct rewrite will allow you not only rewrite cartridge's flash memory using very simple way but it will also allow to keep many game saves in cartridge's memory (if PRG RAM chip exists). Originally game's progress will be erased if any other game started that uses PRG RAM even if battery present. There is no way to know which cartridge has this feature but seems like it's all cartridges produced by "MINDKIDS". So if you can look at cartridge's board, check it for "MINDKIDS" label.
* **With a different register addresses**. Most cartridges has registers at $600x addresses but some cartridges has them at $500x. This toolset supports both versions, so just don't need to care about it.

So it's recommended to search for MINDKIDS cartridges with battery.

### Which games are supported

COOLBOY supports games with **NROM** (mapper #0) and **MMC3** (mapper #4) mappers only. NROM is used by games without any mapper and MMC3 is most popular mapper, so games support is good but not perfect. Also most non-MMC3 games can be patched to run on MMC3 without any problem. Also make sure that PRG RAM and CHR size requirements are met.

And one more thing with some weird buggy games. COOLBOY always uses writable CHR RAM even original game uses CHR ROM and it has not 'read-only' mode. So if game with CHR ROM writes to ROM for some weird reason, CHR data will be corrupted. It can be fixed using patches for ROMs. Example game: Cowboy Kid.

Also please note that PRG RAM is not working correctly on *original* Famicoms and AV Famicoms without additional hardware modification of cartridge.

### Games list format

It's just a text file. Lines started with semicolon are comments. Other lines has format:

    <path_to_filename> [| <menu name>]
    
So each line is a path to a ROM with optional name which will be used in menu. Example:

    roms/Adventure Island (U) [!].nes | ADVENTURE ISLAND
    roms/Adventure Island II (U) [!].nes | ADVENTURE ISLAND 2
    roms/Adventure Island III (U) [!].nes | ADVENTURE ISLAND 3

Use tailing "/" to add whole directory:

    roms/
    
If menu name is not specified it will be based on filename. Maximum length for menu entry is 29 symbols.

You can use "?" symbol as menu name to add hidden ROMs:

    spec/sram.nes | ? 
    spec/controller.nes | ? 

First hidden ROM will be started while holding Up+A+B at start. Second one will be started while holding Down+A+B at start. I'm using it to add some hardware tests. Also you can add third hidden ROM, it will be started using Konami Code in the menu :)

All games are alphabetically sorted by default so you don't need to care about games order. But if you are using custom order (--nosort option), you can use "-" symbol to add separators between games:

    roms/filename1.nes
    roms/filename2.nes
    -
    roms/filename3.nes
    roms/filename4.nes

Also there is one very advanced option used to specify enlarge method. Minimum PRG size for MMC3 games to run on COOLBOY is 128KBytes, so small games will be automatically enlarged. Default enlarge method is full mirroring, e.g. PRG data will be repeated multiple times until 128KBytes are reached. It's 100% compartible method but it's huge waste of ROM space. You can enable "last bank only" mirroring when only last bank will be copied to the end of 128KB are. Just put "+" sign before game's menu name:

    Adventure Island (U) [!].nes | +Adventure Island

Usually it's good for non-MMC3 games ported to MMC3.

### Using CoolboyCombiner, first step

CoolboyCombiner will create assembly file with all data required for menu and XML file required for second step. Usage:

     CoolboyCombiner.exe prepare --games <games.txt> --asm <games.asm> --offsets <offsets.xml> [--version <number>] [--report <report.txt>] [--nosort] [--maxsize sizemb] [--language <language>] [--badsectors <sectors>]
      --games             - input plain text file with list of ROM files
      --asm               - output file for loader
      --ver               - set COOLBOY version: 1 (default) for classic and 2 for new one
                            the only difference is registers address
                            version 1 uses registers at $600x
                            version 2 uses registers at $500x
      --no-flash          - disable support for writable flash memory (works on some new COOLBOYs
                            writable flash allows to store up to 15 saves of battery backed games,
                            it also allows to remember last menu position,
                            disable it to free additional 256KB of ROM space if you don't need it
      --offsets           - output file with offsets for every game
      --report            - output report file (human readable)
      --nosort            - disable automatic sort by name
      --maxsize           - maximum size of the final file (in megabytes)
      --language          - language for system messages: "eng" (default) or "rus"
      --badsectors        - comma-separated separated list of bad sectors,
                            if your cartridge has bad sectors for some reason,
                            you can ask this tool to skip them

Example:

    CoolboyCombiner.exe prepare --games games.txt --asm games.asm --offsets offsets.xml
    
It will create "**games.asm**" and "**offsets.xml**" files based on games list stored in "**games.txt**".

### Compiling games menu

Optionally you can edit "**menu.png**" file to create custom header image in menu. You can edit only top 32 lines. Please note that top 8 lines are hidden on NTSC consoles. Of course you can use only colors limited to NES hardware. Then run:

    TilesConverter.exe menu.png menu_pattern0.dat menu_nametable0.dat menu_palette0.dat
    TilesConverter.exe menu_sprites.png menu_pattern1.dat menu_nametable1.dat menu_palette1.dat
    
It will create bunch of binary .dat files with images data. Now compile menu using nesasm:

    nesasm.exe menu.asm
    
It will create "**menu.nes**" file. It's only menu. You can run it but it has not games in it until next step.

### Using CoolboyCombiner, second step
    
It's time to combile our menu and games. Using CoolboyCombiner second time:
    
    CoolboyCombiner.exe combine --loader <menu.nes> --offsets <offsets.xml> [--unif <multirom.unf>] [--bin <multirom.bin>]
      --ver               - use version from the first step, sets the propper mapper
      --loader            - loader (compiled using asm file generated by first step)
      --offsets           - input file with offsets for every game (generated by first step)
      --unif              - output UNIF file
      --bin               - output raw binary file
      
Example:
    
    CoolboyCombiner.exe combine --loader menu.nes --offsets offsets.xml --unif multirom.unf
    
It will use "**menu.nes**" and "**offsets.xml**" files from previous steps to create "**multirom.unf**" file. Done!


## Using menu

Buttons:
* **Up** - move to previous game
* **Down** - move to next game
* **Right** - jump 10 games forward
* **Left** - jump 10 games backward
* **Start** - start selected game
* **A** - same, start selected game
* **B** - not used

Special combinations:
* Hold **Select** on start to show some build and hardware info
* Hold **Select**+**A**+**B** on start RAM tests, it will test PRG RAM and 256KB of CHR data
* Hold **Left**+**Up**+**Select**+**Start** on start to erase all saved data
* Hold **Up**+**A**+**B** on start to start first hidden ROM
* Hold **Down**+**A**+**B** on start to start second hidden ROM
* Press **Up**, **Up**, **Down**, **Down**, **Left**, **Right**, **Left**, **Right**, **B**, **A** to start third hidden ROM


## About flash saving system

When cartridge with a directly writable flash memory used (/WE and /OE pins are connected to mapper), it's possible to use this memory as additional storage. If "--no-flash" option is not specified last two sectors of flash memory (256KBytes) will be reserved for it. This memory will be used to store cursor position and progress of battery-backed games (even if cartridge has not battery but you'll need to press reset to save the progress in this case). Please note that flash memory is not rewrited every time. New data will be writed to free space on active sector marked by signature. When active sector is full, all actual data will be moved to second sector. User will be warned to keep power on.


## Donation

PayPal: clusterrr@clusterrr.com
