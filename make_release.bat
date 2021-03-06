make clean
SET OUTDIR=coolboy-multirom-builder
SET OUTFILE=coolboy-multirom-builder.zip
IF EXIST "%OUTDIR%" del /F /S /Q "%OUTDIR%"
IF EXIST "%OUTFILE%" del /F /S /Q "%OUTFILE%"
mkdir "%OUTDIR%"
mkdir "%OUTDIR%\tools"
mkdir "%OUTDIR%\demos"
mkdir "%OUTDIR%\games"
mkdir "%OUTDIR%\spec"
copy LICENSE "%OUTDIR%"
copy *.md "%OUTDIR%"
copy *.asm "%OUTDIR%"
copy Makefile "%OUTDIR%"
copy games.list "%OUTDIR%"
copy *.png "%OUTDIR%"
copy "!build_rom.bat" "%OUTDIR%"
copy "tools\CoolboyCombiner.exe" "%OUTDIR%\tools"
copy "tools\TilesConverter.exe" "%OUTDIR%\tools"
copy "tools\nesasm.exe" "%OUTDIR%\tools"
copy "tools\*.dll" "%OUTDIR%\tools"
copy "spec\*.nes" "%OUTDIR%\spec"

copy "games\*.nes" "%OUTDIR%\games"
copy "demos\Unchained_Nostalgia.nes" "%OUTDIR%\demos"

7z a %OUTFILE% %OUTDIR%
