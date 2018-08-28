# coolboy-multirom-builder
Toolset that allows you to create multirom images for cheap COOLBOY (and clones) Famicom cartridges. Which can be writed with my other tool: https://github.com/ClusterM/famicom-dumper-client

Features:
* Combines up to 768 games into single binary which can be writed to cheap COOLBOY cartridge
* Creates menu where you can easily select game
* Can alphabetically sort games in menu if you need it
* Allows to use your own image as menu header
* On new versions of cartridges it can remember last played game and keep up to 15 game saves into flash memory
* Supports many different versions of cartridges
* Has built-in hardware tests
* Can show build info if user holding select on startup
* Can add up to three hidden ROMs for Up+A+B, Down+A+B and Konami Code combinations

How it works (for advanced users):
1. You need to create text file with list of files and/or directories with ROMs, optionally you can specify game name for menu entry.
2. Run **CoolboyCombiner.exe** with "**prepare**" command, it will automatically use best way to fit game's data in the target ROM and create "**games.asm**" and offsets files. First one contains game names and commands for cartridge's chip to start them. Second file will contain info with address of data for every game in the final ROM.
3. Compile "**menu.asm**" using **nesasm** compiler. I'm using my own modification: https://github.com/ClusterM/nesasm. It will create .nes file with games menu.
4. After it you need to combine menu and games into one file. Run **CoolboyCombiner.exe** with "**combine**" command
5. Done.

It sounds a bit complicated but you can use **Make** tool or just run "**!build_rom.bat**" (for Windows users).

Now let me talk you much more info about every step.

## Which cartridges are supported, how to select which cartridge to buy

There are many versions of COOLBOY cartridges and clones. Actually most of them are not "COOLBOY", it's just a name of the first cartridges with this chip.

You can find modifications:
* **With different CHR size**. Some cartridges has only 128KB of RAM for CHR data and some 256KB. So 128KB version can't run many cool games with CHR size >128KB. You can easily detect amount of CHR RAM after looking at games list. If it has at least one game with large CHR, cartridge has 256KB. Example games: Megaman/Rockman 5, Earthbound Zero, Kirby's Adventure
* **With different flash size**. Most cartridges has 32MBytes of flash memory but it's possible to find much more rare cartridges with less memory size. 32MBytes is maximum available size.
* **With additional PRG RAM chip**. It's required by some games like The Legend of Zelda, Jurassic Park, etc. So if hardridge has those games, it has PRG RAM chip. Also in case when you seller shows images of cartridge's board you can check presense of chip on the back side of it. Also it's possible to solder this chip manually.
* **With and without battery**. Battery is used to keep data in PRG RAM chip even after console is turned off. It's used to save games progress. So if cartridge has battery, it also has PRG-RAM chip. There is no way to detect present of battery but usually seller can say it, also check product description in shop.
* **With directly writable and non-writable flash memory**. Some new cartridges can be rewrited directly without additional soldering and some not. Direct rewrite will allow you not only rewrite cartridge's flash memory using very simple way but it will also allow to keep many game saves in cartridge's memory (if PRG RAM chip exists). Originally game's progress will be erased if any other game started that uses PRG RAM even if battery present. There is no way to know which cartridge has this feature but seems like it's all cartridges produced by "MINDKIDS". So if you can look at cartridge's board, check it for "MINDKIDS" label.
* **With different register addresses**. Most cartridges has registers at $600x addresses but some cartridges has them at $500x. This toolset supports both versions, so just don't care.

So it's recommended to search for MINDKIDS cartridges with battery.
