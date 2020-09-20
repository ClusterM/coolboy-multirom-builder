using com.clusterrr.Famicom;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.XPath;

namespace Cluster.Famicom
{
    class Program
    {
        static int Main(string[] args)
        {
            const int loaderSize = 128 * 1024;
            const int loaderOffset = 512 * 1024 - 128 * 1024;

            Console.WriteLine("COOLBOY combiner v{0}.{1}",
                Assembly.GetExecutingAssembly().GetName().Version.Major,
                Assembly.GetExecutingAssembly().GetName().Version.Minor);
            Console.WriteLine("  Commit {0} @ https://github.com/ClusterM/coolboy-multirom-builder",
                 Properties.Resources.gitCommit);
            Console.WriteLine("  (c) Alexey 'Cluster' Avdyukhin / https://clusterrr.com / clusterrr@clusterrr.com");
            Console.WriteLine();
            bool needShowHelp = false;

            string command = null;
            string optionGames = null;
            string optionAsm = null;
            string optionOffsets = null;
            string optionReport = null;
            string optionLoader = null;
            string optionUnif = null;
            string optionBin = null;
            string optionLanguage = "eng";
            bool optionNoSort = false;
            int optionMaxSize = 32;
            bool useFlashWriting = true;
            int coolboyVersion = 1;
            List<int> badSectors = new List<int>();
            if (args.Length > 0) command = args[0].ToLower();
            if (command != "prepare" && command != "combine")
            {
                if (!string.IsNullOrEmpty(command))
                    Console.WriteLine("Unknown command: " + command);
                needShowHelp = true;
            }
            for (int i = 1; i < args.Length; i++)
            {
                string param = args[i];
                while (param.StartsWith("-")) param = param.Substring(1);
                string value = i < args.Length - 1 ? args[i + 1] : "";
                switch (param.ToLower())
                {
                    case "games":
                        optionGames = value;
                        i++;
                        break;
                    case "asm":
                        optionAsm = value;
                        i++;
                        break;
                    case "offsets":
                        optionOffsets = value;
                        i++;
                        break;
                    case "report":
                        optionReport = value;
                        i++;
                        break;
                    case "loader":
                        optionLoader = value;
                        i++;
                        break;
                    case "unif":
                        optionUnif = value;
                        i++;
                        break;
                    case "bin":
                        optionBin = value;
                        i++;
                        break;
                    case "nosort":
                        optionNoSort = true;
                        break;
                    case "maxsize":
                        optionMaxSize = int.Parse(value);
                        i++;
                        break;
                    case "language":
                        optionLanguage = value.ToLower();
                        i++;
                        break;
                    case "badsectors":
                        foreach (var v in value.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                            badSectors.Add(int.Parse(v));
                        i++;
                        break;
                    case "no-flash":
                        useFlashWriting = false;
                        break;
                    case "ver":
                        coolboyVersion = int.Parse(value);
                        i++;
                        break;
                    default:
                        Console.WriteLine("Unknown parameter: " + param);
                        needShowHelp = true;
                        break;
                }
            }

            if (command == "prepare")
            {
                if (optionGames == null)
                {
                    Console.WriteLine("Missing required parameter: --games");
                    needShowHelp = true;
                }
                if (optionAsm == null)
                {
                    Console.WriteLine("Missing required parameter: --asm");
                    needShowHelp = true;
                }
                if (optionOffsets == null)
                {
                    Console.WriteLine("Missing required parameter: --offsets");
                    needShowHelp = true;
                }
            }
            else if (command == "combine")
            {
                if (optionLoader == null)
                {
                    Console.WriteLine("Missing required parameter: --loader");
                    needShowHelp = true;
                }
                if (optionUnif == null && optionBin == null)
                {
                    Console.WriteLine("At least one parameter required: --unif or --bin");
                    needShowHelp = true;
                }
            }

            if (needShowHelp)
            {
                Console.WriteLine("--- Usage ---");
                Console.WriteLine("First step:");
                Console.WriteLine(" CoolboyCombiner.exe prepare --games <games.txt> --asm <games.asm> --offsets <offsets.xml> [--version <number>] [--report <report.txt>] [--nosort] [--maxsize sizemb] [--language <language>] [--badsectors <sectors>]");
                Console.WriteLine("  {0,-20}{1}", "--games", "- input plain text file with list of ROM files");
                Console.WriteLine("  {0,-20}{1}", "--asm", "- output file for loader");
                Console.WriteLine("  {0,-20}{1}", "--ver", "- set COOLBOY version: 1 (default) for classic and 2 for new one (aka MINDKIDS)");
                Console.WriteLine("  {0,-20}{1}", "", "  the only difference is registers address");
                Console.WriteLine("  {0,-20}{1}", "", "  version 1 uses registers at $600x");
                Console.WriteLine("  {0,-20}{1}", "", "  version 2 uses registers at $500x");
                Console.WriteLine("  {0,-20}{1}", "--no-flash", "- disable support for writable flash memory (works on some new COOLBOYs");
                Console.WriteLine("  {0,-20}{1}", "", "  writable flash allows to store up to 15 saves of battery backed games,");
                Console.WriteLine("  {0,-20}{1}", "", "  it also allows to remember last menu position,");
                Console.WriteLine("  {0,-20}{1}", "", "  disable it to free additional 256KB of ROM space if you don't need it");
                Console.WriteLine("  {0,-20}{1}", "--offsets", "- output file with offsets for every game");
                Console.WriteLine("  {0,-20}{1}", "--report", "- output report file (human readable)");
                Console.WriteLine("  {0,-20}{1}", "--nosort", "- disable automatic sort by name");
                Console.WriteLine("  {0,-20}{1}", "--maxsize", "- maximum size of the final file (in megabytes)");
                Console.WriteLine("  {0,-20}{1}", "--language", "- language for system messages: \"eng\" (default) or \"rus\"");
                Console.WriteLine("  {0,-20}{1}", "--badsectors", "- comma-separated separated list of bad sectors,");
                Console.WriteLine("  {0,-20}{1}", "", "  if your cartridge has bad sectors for some reason,");
                Console.WriteLine("  {0,-20}{1}", "", "  you can ask this tool to skip them");
                Console.WriteLine("Second step:");
                Console.WriteLine(" CoolboyCombiner.exe combine --loader <menu.nes> --offsets <offsets.xml> [--unif <multirom.unf>] [--bin <multirom.bin>]");
                Console.WriteLine("  {0,-20}{1}", "--ver", "- use version from the first step, sets the propper mapper");
                Console.WriteLine("  {0,-20}{1}", "--loader", "- loader (compiled using asm file generated by first step)");
                Console.WriteLine("  {0,-20}{1}", "--offsets", "- input file with offsets for every game (generated by first step)");
                Console.WriteLine("  {0,-20}{1}", "--unif", "- output UNIF file");
                Console.WriteLine("  {0,-20}{1}", "--bin", "- output raw binary file");
                return 1;
            }

            try
            {
                if (command == "prepare")
                {
                    var lines = File.ReadAllLines(optionGames);
                    var result = new byte?[loaderOffset + loaderSize];
                    var regs = new Dictionary<string, List<String>>();
                    var games = new List<Game>();
                    var namesIncluded = new List<String>();

                    // Reserved for loader
                    for (int a = loaderOffset; a < loaderOffset + loaderSize; a++)
                        result[a] = 0xff;

                    // Bad sectors :(
                    foreach (var bad in badSectors)
                    {
                        for (int a = bad * 4 * 0x8000; a < bad * 4 * 0x8000 + 128 * 1024; a++)
                        {
                            if (a >= result.Length)
                                Array.Resize(ref result, a + 16 * 1024 * 1024);
                            result[a] = 0xff;
                        }
                    }

                    // Building list of ROMs
                    foreach (var line in lines)
                    {
                        if (string.IsNullOrEmpty(line.Trim())) continue;
                        if (line.StartsWith(";")) continue;
                        int sepPos = line.TrimEnd().IndexOf('|');

                        string fileName;
                        string menuName = null;
                        if (sepPos < 0)
                        {
                            fileName = line.Trim();
                        }
                        else
                        {
                            fileName = line.Substring(0, sepPos).Trim();
                            menuName = line.Substring(sepPos + 1).Trim();
                        }

                        if (fileName.EndsWith("/") || fileName.EndsWith("\\"))
                        {
                            Console.WriteLine("Loading directory: {0}", fileName);
                            var files = Directory.GetFiles(fileName, "*.nes");
                            foreach (var file in files)
                            {
                                Game.LoadGames(games, file);
                            }
                        }
                        else
                        {
                            Game.LoadGames(games, fileName, menuName);
                        }
                    }

                    // Removing separators
                    if (!optionNoSort)
                        games = new List<Game>((from game in games where !(string.IsNullOrEmpty(game.FileName) || game.FileName == "-") select game).ToArray());
                    // Sorting
                    if (optionNoSort)
                    {
                        games = new List<Game>((from game in games where !game.ToString().StartsWith("?") select game)
                        .Union(from game in games where game.ToString().StartsWith("?") orderby game.ToString().ToUpper() ascending select game)
                        .ToArray());
                    }
                    else
                    {
                        games = new List<Game>((from game in games where !game.ToString().StartsWith("?") orderby game.ToString().ToUpper() ascending select game)
                            .Union(from game in games where game.ToString().StartsWith("?") orderby game.ToString().ToUpper() ascending select game)
                            .ToArray());
                    }
                    int hiddenCount = games.Where(game => game.ToString().StartsWith("?")).Count();

                    byte saveId = 0;
                    foreach (var game in games)
                    {
                        if (game.Battery)
                        {
                            saveId++;
                            game.SaveId = saveId;
                        }
                    }

                    int usedSpace = 0;
                    var sortedPrgs = from game in games orderby game.PrgSize descending select game;
                    foreach (var game in sortedPrgs)
                    {
                        int prgRoundSize = 1;
                        while (prgRoundSize < game.PrgSize) prgRoundSize *= 2;
                        if (prgRoundSize != game.PrgSize)
                            throw new Exception(string.Format("Invalid ROM size: {0} in {1}", game.PrgSize, game));

                        byte[] originalPrg = game.ROM.PRG;
                        byte?[] prg;

                        // Need to enlarge ROM?
                        if (game.Mapper == 4 && game.PrgSize < 128 * 1024)
                        {
                            if (game.MenuName == null || (!game.MenuName.StartsWith("+") && game.MenuName != "+?"))
                            {
                                // Full-mirror method
                                Console.WriteLine("Enlarging {0}, original size is {1}KB, full mirror method", game, game.PrgSize / 1024);
                                game.EMode = EnlargeMode.FullMirror;
                                prg = EnlargePrgFull(originalPrg);
                                game.PrgSize = prg.Length;
                            }
                            else
                            {
                                // Moving only last bank
                                game.EMode = EnlargeMode.LastBankOnly;
                                Console.WriteLine("Enlarging {0}, original size is {1}KB, last-bank method", game, game.PrgSize / 1024);
                                game.MenuName = game.MenuName.Substring(1);
                                prg = EnlargePrgLastBank(originalPrg);
                                game.PrgSize = prg.Length;
                            }
                        }
                        else
                        {
                            prg = new byte?[originalPrg.Length];
                            for (int i = 0; i < originalPrg.Length; i++)
                                prg[i] = originalPrg[i];
                        }

                        prgRoundSize = prg.Length;

                        Console.WriteLine("Fitting PRG for {0} ({1}kbytes)...", game, prgRoundSize / 1024);
                        for (int pos = 0; pos < optionMaxSize * 1024 * 1024; pos += prgRoundSize)
                        {
                            if (WillFit(result, pos, prgRoundSize, prg))
                            {
                                game.PrgPos = pos;
                                for (var i = 0; i < prgRoundSize; i++)
                                {
                                    if (pos + i >= result.Length)
                                        Array.Resize(ref result, pos + i + 16 * 1024 * 1024);
                                    if (prg[i] != null)
                                        result[pos + i] = prg[i];
                                }
                                usedSpace = Math.Max(usedSpace, pos + prgRoundSize);
                                Console.WriteLine("Address: {0:X8}", pos);
                                break;
                            }
                        }
                        if (game.PrgPos < 0) throw new Exception("Can't fit " + game);
                        GC.Collect();
                    }

                    var sortedChrs = from game in games orderby game.ChrSize descending select game;
                    foreach (var game in sortedChrs)
                    {
                        if (game.ChrSize == 0) continue;
                        var chr = game.ROM.CHR;

                        Console.WriteLine("Fitting CHR for {0} ({1}kbytes)...", game, game.ChrSize / 1024);
                        for (int pos = 0; pos < optionMaxSize * 1024 * 1024; pos += 0x2000)
                        {
                            if (WillFit(result, pos, game.ChrSize, chr))
                            {
                                game.ChrPos = pos;
                                for (var i = 0; i < chr.Length; i++)
                                {
                                    if (pos + i >= result.Length)
                                        Array.Resize(ref result, pos + 16 * 1024 * 1024);
                                    result[pos + i] = chr[i];
                                }
                                usedSpace = Math.Max(usedSpace, pos + game.ChrSize);
                                Console.WriteLine("Address: {0:X8}", pos);
                                break;
                            }
                        }
                        if (game.ChrPos < 0) throw new Exception("Can't fit " + game);
                        GC.Collect();
                    }
                    while (usedSpace % 0x8000 != 0)
                        usedSpace++;
                    usedSpace = Math.Max(usedSpace, loaderOffset + loaderSize); // Target ROM can't be smaller end of loader
                    int romSize = usedSpace;
                    if (useFlashWriting)
                        usedSpace += 128 * 1024 * 2;

                    int totalSize = 0;
                    int maxChrSize = 0;
                    namesIncluded.Add(string.Format("{0,-33} {1,-10} {2,-10} {3,-10} {4,0}", "Game name", "Mapper", "Save ID", "Size", "Total size"));
                    namesIncluded.Add(string.Format("{0,-33} {1,-10} {2,-10} {3,-10} {4,0}", "------------", "-------", "-------", "-------", "--------------"));
                    var mapperStats = new Dictionary<byte, int>();
                    foreach (var game in games)
                    {
                        if (!game.ToString().StartsWith("?"))
                        {
                            totalSize += game.PrgSize;
                            totalSize += game.ChrSize;
                            namesIncluded.Add(string.Format("{0,-33} {1,-10} {2,-10} {3,-10} {4,0}", FirstCharToUpper(game.ToString().Replace("_", " ").Replace("+", "")), game.Mapper, game.SaveId == 0 ? "-" : game.SaveId.ToString(),
                                ((game.PrgSize + game.ChrSize) / 1024) + " KB", (totalSize / 1024) + " KB total"));
                            if (!mapperStats.ContainsKey(game.Mapper)) mapperStats[game.Mapper] = 0;
                            mapperStats[game.Mapper]++;
                        }
                        if (game.ChrSize > maxChrSize)
                            maxChrSize = game.ChrSize;
                    }
                    namesIncluded.Add("");
                    namesIncluded.Add(string.Format("{0,-10} {1,0}", "Mapper", "Count"));
                    namesIncluded.Add(string.Format("{0,-10} {1,0}", "------", "-----"));
                    foreach (var mapper in from m in mapperStats.Keys orderby m ascending select m)
                    {
                        namesIncluded.Add(string.Format("{0,-10} {1,0}", mapper, mapperStats[mapper]));
                    }

                    namesIncluded.Add("");
                    namesIncluded.Add("Total games: " + (games.Count - hiddenCount));
                    namesIncluded.Add("Final ROM size: " + (usedSpace / 1024) + "KB");
                    namesIncluded.Add("Maximum CHR size: " + maxChrSize / 1024 + "KB");
                    namesIncluded.Add("Battery-backed games: " + saveId);

                    Console.WriteLine("Total games: " + (games.Count - hiddenCount));
                    Console.WriteLine("Final ROM size: " + (usedSpace / 1024) + "KB");
                    Console.WriteLine("Maximum CHR size: " + maxChrSize / 1024 + "KB");
                    Console.WriteLine("Battery-backed games: " + saveId);

                    if (optionReport != null)
                        File.WriteAllLines(optionReport, namesIncluded.ToArray());

                    if (games.Count - hiddenCount == 0)
                        throw new Exception("Games list is empty");

                    if (usedSpace > optionMaxSize * 1024 * 1024)
                        throw new Exception(string.Format("ROM is too big: {0} KB", usedSpace / 1024));
                    if (games.Count > 768)
                        throw new Exception("Too many games: " + games.Count);
                    if (saveId > 15)
                        throw new Exception("Too many battery backed games: " + saveId);

                    regs["reg_0"] = new List<String>();
                    regs["reg_1"] = new List<String>();
                    regs["reg_2"] = new List<String>();
                    regs["reg_3"] = new List<String>();
                    regs["chr_start_bank_h"] = new List<String>();
                    regs["chr_start_bank_l"] = new List<String>();
                    regs["chr_start_bank_s"] = new List<String>();
                    regs["chr_size_source"] = new List<String>();
                    regs["chr_size_target"] = new List<String>();
                    regs["mirroring"] = new List<String>();
                    regs["game_save"] = new List<String>();
                    regs["game_type"] = new List<String>();
                    regs["cursor_pos"] = new List<String>();

                    int c = 0;
                    foreach (var game in games)
                    {
                        int prgSize = game.PrgSize;
                        int chrSize = game.ChrSize;
                        int prgPos = game.PrgPos;
                        int chrPos = Math.Max(game.ChrPos, 0);
                        int chrBase = (chrPos / 0x2000) >> 4;
                        int prgBase = (prgPos / 0x2000) >> 4;
                        int prgRoundSize = 1;
                        while (prgRoundSize < prgSize) prgRoundSize *= 2;
                        int chrRoundSize = 1;
                        while (chrRoundSize < chrSize || chrRoundSize < 0x2000) chrRoundSize *= 2;

                        if (game.Mapper != 0 && game.Mapper != 4)
                            throw new Exception(string.Format("Unknowm mapper #{0} for {1} ", game.Mapper, game));
                        if (chrSize > 256 * 1024)
                            throw new Exception(string.Format("CHR is too big in {0} ", game));
                        if (game.Mirroring == NesFile.MirroringType.FourScreenVram)
                            throw new Exception(string.Format("Four-screen is not supported for {0} ", game));

                        // Some unusual games
                        switch (game.CRC32)
                        {
                            case 0x78b657ac: // "Armadillo (J) [!].nes"
                            case 0xb3d92e78: // "Armadillo (J) [T+Eng1.01_Vice Translations].nes" 
                            case 0x0fe6e6a5: // "Armadillo (J) [T+Rus1.00 Chief-Net (23.05.2012)].nes" 
                            case 0xe62e3382: // "MiG 29 - Soviet Fighter (Camerica) [!].nes" 
                            case 0x1bc686a8: // "Fire Hawk (Camerica) [!].nes" 
                                Console.WriteLine("WARNING! {0} is not compatible with Dendy", game);
                                game.Flags |= GameFlags.WillNotWorkOnDendy;
                                break;
                        }
                        if (string.IsNullOrEmpty(game.ToString()))
                            game.Flags = GameFlags.Separator;

                        int bank = game.PrgPos / 0x4000;
                        byte r0 = (byte)(((bank >> 3) & 0x07) // 5, 4, 3 bits
                            | (((bank >> 9) & 0x03) << 4) // 10, 9 bits
                            | ((game.PrgSize > 128 * 1024) ? 0 : (1 << 6)) // PRG mask 256KB
                            | ((game.ChrSize > 128 * 1024) ? 0 : (1 << 7))); // CHR mask 256KB
                        byte r1 = (byte)((((bank >> 7) & 0x03) << 2) // 8, 7
                            | (((bank >> 6) & 1) << 4) // 6
                            | ((game.PrgSize > 0x4000) ? (1 << 1) : 0) // PRG mask 32KB
                            | ((game.PrgSize > 1024 * 1024) ? (1 << 5) : 0) // PRG mask 2048KB
                            | ((game.PrgSize > 512 * 1024) ? (1 << 6) : 0) // PRG mask 1024KB
                            | ((game.PrgSize > 256 * 1024) ? 0 : (1 << 7))); // PRG mask 512KB
                        byte r2 = 0;
                        byte r3 = (byte)(((game.Mapper == 0) ? (1 << 4) : 0) // NROM mode
                            | ((bank & 7) << 1) // 2, 1, 0 bits
                            | 0x80); // lockout
                        regs["reg_0"].Add(string.Format("${0:X2}", r0));
                        regs["reg_1"].Add(string.Format("${0:X2}", r1));
                        regs["reg_2"].Add(string.Format("${0:X2}", r2));
                        regs["reg_3"].Add(string.Format("${0:X2}", r3));
                        regs["chr_start_bank_h"].Add(string.Format("${0:X2}", (game.ChrPos / 0x400000) & 0xFF));
                        regs["chr_start_bank_l"].Add(string.Format("${0:X2}", (game.ChrPos / 0x4000) & 0xFF));
                        regs["chr_start_bank_s"].Add(string.Format("${0:X2}", 0x80 + ((game.ChrPos / 0x2000) % 2) * 0x20));
                        regs["chr_size_source"].Add(string.Format("${0:X2}", game.ChrSize / 0x2000));
                        regs["chr_size_target"].Add(string.Format("${0:X2}", game.Mapper == 0 ? 1 :
                            ((game.ChrSize <= 128 * 1024) ? (byte)(128 * 1024 / 0x2000) : (byte)(256 * 1024 / 0x2000))));
                        regs["mirroring"].Add(string.Format("${0:X2}", game.Mirroring == NesFile.MirroringType.Horizontal ? 0x01 : 0x00));
                        regs["game_save"].Add(string.Format("${0:X2}", !game.Battery ? 0 : game.SaveId));
                        regs["game_type"].Add(string.Format("${0:X2}", (byte)game.Flags));
                        regs["cursor_pos"].Add(string.Format("${0:X2}", game.ToString().Length));
                    }

                    byte baseBank = 0;
                    var asmResult = new StringBuilder();
                    asmResult.AppendLine("; Games database");
                    int regCount = 0;
                    foreach (var reg in regs.Keys)
                    {
                        c = 0;
                        foreach (var r in regs[reg])
                        {
                            if (c % 256 == 0)
                            {
                                asmResult.AppendLine();
                                asmResult.AppendLine("  .bank " + (baseBank + c / 256 * 2));
                                asmResult.AppendLine(string.Format("  .org ${0:X4}", 0x8000 + regCount * 0x100));
                                asmResult.Append("loader_data_" + reg + (c == 0 ? "" : "_" + c.ToString()) + ":");
                            }
                            //asmResult.AppendLine("  .db " + string.Join(", ", regs[reg]));
                            if (c % 16 == 0)
                            {
                                asmResult.AppendLine();
                                asmResult.Append("  .db");
                            }
                            asmResult.AppendFormat(((c % 16 != 0) ? "," : "") + " {0}", r);
                            c++;
                        }
                        asmResult.AppendLine();
                        regCount++;
                    }

                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    //asmResult.Append("  .dw");
                    c = 0;
                    foreach (var game in games)
                    {
                        if (c % 256 == 0)
                        {
                            asmResult.AppendLine();
                            asmResult.AppendLine("  .bank " + (baseBank + c / 256 * 2));
                            asmResult.AppendLine("  .org $9000");
                            //asmResult.AppendLine("game_names_list" + (c == 0 ? "" : "_" + c.ToString()) + ":");
                            //asmResult.AppendLine("  .dw game_names" + (c == 0 ? "" : "_" + c.ToString()));
                            asmResult.AppendLine("game_names" + (c == 0 ? "" : "_" + c.ToString()) + ":");
                        }
                        //asmResult.AppendFormat(((c > 0) ? "," : "") + " game_name_" + c);
                        asmResult.AppendLine("  .dw game_name_" + c);
                        c++;
                    }

                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    asmResult.AppendLine("; Game names");
                    c = 0;
                    foreach (var game in games)
                    {
                        asmResult.AppendLine();
                        if (c % 256 == 0)
                        {
                            asmResult.AppendLine("  .bank " + (baseBank + c / 256 * 2 + 1));
                            if (baseBank + c / 256 * 2 + 1 >= 62) throw new Exception("Bank overflow! Too many games?");
                            asmResult.AppendLine("  .org $A000");
                        }
                        asmResult.AppendLine("; " + game.ToString());
                        asmResult.AppendLine("game_name_" + c + ":");
                        var name = StringToTiles(string.Format(/*"{0}. "+*/"{1}", c + 1, game.ToString()));
                        var asm = BytesToAsm(name);
                        asmResult.Append(asm);
                        c++;
                    }

                    asmResult.AppendLine();
                    asmResult.AppendLine("  .bank 14");
                    asmResult.AppendLine("  .org $C800");
                    asmResult.AppendLine();
                    asmResult.AppendLine("games_count:");
                    asmResult.AppendLine("  .dw " + (games.Count - hiddenCount));
                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    asmResult.AppendLine("saves_count:");
                    asmResult.AppendLine("  .db " + saveId);
                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    asmResult.AppendLine("games_offset:");
                    asmResult.AppendLine("  .db " + ((games.Count - hiddenCount) > 10 ? 0 : 5 - (games.Count - hiddenCount) / 2));
                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    asmResult.AppendLine("maximum_scroll:");
                    asmResult.AppendLine("  .dw " + Math.Max(0, games.Count - 11 - hiddenCount));
                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    asmResult.AppendLine("string_file:");
                    asmResult.Append(BytesToAsm(StringToTiles("FILE: " + Path.GetFileName(optionGames))));
                    asmResult.AppendLine("string_build_date:");
                    asmResult.Append(BytesToAsm(StringToTiles("BUILD DATE: " + DateTime.Now.ToString("yyyy-MM-dd"))));
                    asmResult.AppendLine("string_build_time:");
                    asmResult.Append(BytesToAsm(StringToTiles("BUILD TIME: " + DateTime.Now.ToString("HH:mm:ss"))));
                    asmResult.AppendLine("string_console_type:");
                    asmResult.Append(BytesToAsm(StringToTiles("CONSOLE TYPE:")));
                    asmResult.AppendLine("string_ntsc:");
                    asmResult.Append(BytesToAsm(StringToTiles("NTSC")));
                    asmResult.AppendLine("string_pal:");
                    asmResult.Append(BytesToAsm(StringToTiles("PAL")));
                    asmResult.AppendLine("string_dendy:");
                    asmResult.Append(BytesToAsm(StringToTiles("DENDY")));
                    asmResult.AppendLine("string_new:");
                    asmResult.Append(BytesToAsm(StringToTiles("NEW")));
                    asmResult.AppendLine("string_flash:");
                    asmResult.Append(BytesToAsm(StringToTiles("FLASH:")));
                    asmResult.AppendLine("string_read_only:");
                    asmResult.Append(BytesToAsm(StringToTiles("READ ONLY")));
                    asmResult.AppendLine("string_writable:");
                    asmResult.Append(BytesToAsm(StringToTiles("WRITABLE")));
                    asmResult.AppendLine("flash_sizes:");
                    for (int i = 0; i <= 8; i++)
                        asmResult.AppendLine($"  .dw string_{1 << i}mb");
                    for (int i = 0; i <= 8; i++)
                    {
                        asmResult.AppendLine($"string_{1 << i}mb:");
                        asmResult.Append(BytesToAsm(StringToTiles($"{1 << i}MB")));
                    }
                    asmResult.AppendLine("string_chr_ram:");
                    asmResult.Append(BytesToAsm(StringToTiles("CHR RAM:")));
                    asmResult.AppendLine("chr_ram_sizes:");
                    for (int i = 0; i <= 8; i++)
                        asmResult.AppendLine($"  .dw string_{8 * (1 << i)}kb");
                    for (int i = 0; i <= 8; i++)
                    {
                        asmResult.AppendLine($"string_{8 * (1 << i)}kb:");
                        asmResult.Append(BytesToAsm(StringToTiles($"{8 * (1 << i)}KB")));
                    }
                    asmResult.AppendLine("string_prg_ram:");
                    asmResult.Append(BytesToAsm(StringToTiles("PRG RAM:")));
                    asmResult.AppendLine("string_present:");
                    asmResult.Append(BytesToAsm(StringToTiles("PRESENT")));
                    asmResult.AppendLine("string_not_available:");
                    asmResult.Append(BytesToAsm(StringToTiles("NOT AVAILABLE")));
                    asmResult.AppendLine("string_saving:");
                    if (optionLanguage == "rus")
                        asmResult.Append(BytesToAsm(StringToTiles("  СОХРАНЯЕМСЯ... НЕ ВЫКЛЮЧАЙ!   ")));
                    else
                        asmResult.Append(BytesToAsm(StringToTiles("   SAVING... DON'T TURN OFF!    ")));
                    File.WriteAllText(optionAsm, asmResult.ToString());
                    asmResult.AppendLine("string_incompatible_console:");
                    if (optionLanguage == "rus")
                        asmResult.Append(BytesToAsm(StringToTiles("     ИЗВИНИТЕ,  ДАННАЯ ИГРА       НЕСОВМЕСТИМА С ЭТОЙ КОНСОЛЬЮ                                        НАЖМИТЕ ЛЮБУЮ КНОПКУ      ")));
                    else
                        asmResult.Append(BytesToAsm(StringToTiles("    SORRY,  THIS GAME IS NOT      COMPATIBLE WITH THIS CONSOLE                                          PRESS ANY BUTTON        ")));
                    asmResult.AppendLine("string_prg_ram_test:");
                    asmResult.Append(BytesToAsm(StringToTiles("PRG RAM TEST:")));
                    asmResult.AppendLine("string_chr_ram_test:");
                    asmResult.Append(BytesToAsm(StringToTiles("CHR RAM TEST:")));
                    asmResult.AppendLine("string_passed:");
                    asmResult.Append(BytesToAsm(StringToTiles("PASSED")));
                    asmResult.AppendLine("string_failed:");
                    asmResult.Append(BytesToAsm(StringToTiles("FAILED")));
                    asmResult.AppendLine("string_ok:");
                    asmResult.Append(BytesToAsm(StringToTiles("OK")));
                    asmResult.AppendLine("string_error:");
                    asmResult.Append(BytesToAsm(StringToTiles("ERROR")));

                    asmResult.AppendLine();
                    asmResult.AppendLine();
                    switch (coolboyVersion)
                    {
                        case 1:
                            asmResult.AppendLine("COOLBOY_REG_0 .equ $6000");
                            asmResult.AppendLine("COOLBOY_REG_1 .equ $6001");
                            asmResult.AppendLine("COOLBOY_REG_2 .equ $6002");
                            asmResult.AppendLine("COOLBOY_REG_3 .equ $6003");
                            break;
                        case 2:
                            asmResult.AppendLine("COOLBOY_REG_0 .equ $5000");
                            asmResult.AppendLine("COOLBOY_REG_1 .equ $5001");
                            asmResult.AppendLine("COOLBOY_REG_2 .equ $5002");
                            asmResult.AppendLine("COOLBOY_REG_3 .equ $5003");
                            break;
                        default:
                            throw new Exception($"Unknown version: {coolboyVersion}");
                    }
                    if (useFlashWriting)
                    {
                        asmResult.AppendLine("USE_FLASH_WRITING .equ 1");
                    }
                    else
                    {
                        asmResult.AppendLine("USE_FLASH_WRITING .equ 0");
                    }
                    asmResult.AppendLine("SECRETS .equ " + hiddenCount);

                    File.WriteAllText(optionAsm, asmResult.ToString());

                    XmlWriterSettings xmlSettings = new XmlWriterSettings();
                    xmlSettings.Indent = true;
                    StreamWriter str = new StreamWriter(optionOffsets);
                    XmlWriter offsetsXml = XmlWriter.Create(str, xmlSettings);
                    offsetsXml.WriteStartDocument();
                    offsetsXml.WriteStartElement("Offsets");

                    offsetsXml.WriteStartElement("Info");
                    offsetsXml.WriteElementString("Size", romSize.ToString());
                    offsetsXml.WriteElementString("RomCount", games.Count.ToString());
                    offsetsXml.WriteElementString("GamesFile", Path.GetFileName(optionGames));
                    offsetsXml.WriteEndElement();

                    offsetsXml.WriteStartElement("ROMs");
                    foreach (var game in games)
                    {
                        if (game.FileName == "-") continue;
                        offsetsXml.WriteStartElement("ROM");
                        offsetsXml.WriteElementString("FileName", game.FileName);
                        if (!game.ToString().StartsWith("?"))
                            offsetsXml.WriteElementString("MenuName", game.ToString());
                        offsetsXml.WriteElementString("PrgOffset", string.Format("{0:X8}", game.PrgPos));
                        if (game.ChrSize > 0)
                            offsetsXml.WriteElementString("ChrOffset", string.Format("{0:X8}", game.ChrPos));
                        offsetsXml.WriteElementString("Mapper", game.Mapper.ToString());
                        if (game.SaveId > 0)
                            offsetsXml.WriteElementString("SaveId", game.SaveId.ToString());
                        if (game.EMode > 0)
                            offsetsXml.WriteElementString("EnlargeMode", ((byte)game.EMode).ToString());
                        offsetsXml.WriteEndElement();
                    }
                    offsetsXml.WriteEndElement();

                    offsetsXml.WriteEndElement();
                    offsetsXml.Close();
                }
                else
                {
                    using (var xmlFile = File.OpenRead(optionOffsets))
                    {
                        var offsetsXml = new XPathDocument(xmlFile);
                        XPathNavigator offsetsNavigator = offsetsXml.CreateNavigator();
                        XPathNodeIterator offsetsIterator = offsetsNavigator.Select("/Offsets/Info/Size");
                        int size = -1;
                        while (offsetsIterator.MoveNext())
                        {
                            size = offsetsIterator.Current.ValueAsInt;
                        }

                        if (size < 0) throw new Exception("Invalid offsets file");
                        var result = new byte[size];
                        for (int i = 0; i < size; i++)
                            result[i] = 0xFF;

                        Console.Write("Loading loader... ");
                        var loaderFile = new NesFile(optionLoader);
                        Array.Copy(loaderFile.PRG, 0, result, loaderOffset, loaderSize);
                        Console.WriteLine("OK.");

                        offsetsIterator = offsetsNavigator.Select("/Offsets/ROMs/ROM");
                        while (offsetsIterator.MoveNext())
                        {
                            var currentRom = offsetsIterator.Current;
                            string filename = null;
                            int prgOffset = -1;
                            int chrOffset = -1;
                            EnlargeMode EMode = EnlargeMode.None;
                            var descs = currentRom.SelectDescendants(XPathNodeType.Element, false);
                            while (descs.MoveNext())
                            {
                                var param = descs.Current;
                                switch (param.Name.ToLower())
                                {
                                    case "filename":
                                        filename = param.Value;
                                        break;
                                    case "prgoffset":
                                        prgOffset = int.Parse(param.Value, System.Globalization.NumberStyles.HexNumber);
                                        break;
                                    case "chroffset":
                                        chrOffset = int.Parse(param.Value, System.Globalization.NumberStyles.HexNumber);
                                        break;
                                    case "enlargemode":
                                        EMode = (EnlargeMode)int.Parse(param.Value);
                                        break;
                                }
                            }

                            if (!string.IsNullOrEmpty(filename))
                            {
                                Console.Write("Loading {0}... ", filename);
                                var nesFile = new NesFile(filename);
                                if (prgOffset >= 0)
                                {
                                    switch (EMode)
                                    {
                                        case EnlargeMode.None:
                                            Array.Copy(nesFile.PRG, 0, result, prgOffset, nesFile.PRG.Length);
                                            break;
                                        case EnlargeMode.LastBankOnly:
                                            var prgLast = EnlargePrgLastBank(nesFile.PRG);
                                            for (int i = 0; i < prgLast.Length; i++)
                                                if (prgLast[i] != null)
                                                    result[i + prgOffset] = prgLast[i] ?? 0xFF;
                                            break;
                                        case EnlargeMode.FullMirror:
                                            Console.WriteLine("Full enlarging for " + filename);
                                            var prgFull = EnlargePrgFull(nesFile.PRG);
                                            for (int i = 0; i < prgFull.Length; i++)
                                                if (prgFull[i] != null)
                                                    result[i + prgOffset] = (byte)prgFull[i];
                                            break;
                                    }
                                }
                                if (chrOffset >= 0)
                                    Array.Copy(nesFile.CHR, 0, result, chrOffset, nesFile.CHR.Length);
                                Console.WriteLine("OK.");
                            }
                            GC.Collect();
                        }

                        if (!string.IsNullOrEmpty(optionUnif))
                        {
                            var u = new UnifFile();
                            switch (coolboyVersion)
                            {
                                case 1:
                                    u.Mapper = "COOLBOY";
                                    break;
                                case 2:
                                    u.Mapper = "MINDKIDS";
                                    break;
                                default:
                                    throw new Exception("Unknown version: 2");
                            }

                            u.Fields["MIRR"] = new byte[] { 5 };
                            u.Fields["PRG0"] = result;
                            u.Fields["BATR"] = new byte[] { 1 };
                            u.Version = 5;
                            u.Save(optionUnif);

                            uint sizeFixed = 1;
                            while (sizeFixed < result.Length) sizeFixed <<= 1;
                            var resultSizeFixed = new byte[sizeFixed];
                            Array.Copy(result, 0, resultSizeFixed, 0, result.Length);
                            for (int i = result.Length; i < sizeFixed; i++)
                                resultSizeFixed[i] = 0xFF;
                            var md5 = System.Security.Cryptography.MD5.Create();
                            var md5hash = md5.ComputeHash(resultSizeFixed);
                            Console.Write("ROM MD5: ");
                            foreach (var b in md5hash)
                                Console.Write("{0:x2}", b);
                            Console.WriteLine();
                        }
                        if (!string.IsNullOrEmpty(optionBin))
                        {
                            File.WriteAllBytes(optionBin, result);
                        }
                    }
                }
                Console.WriteLine("Done.");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.Message + ex.StackTrace);
                return 2;
            }
            return 0;
        }

        static void CopyArray(byte[] source, int sourceIndex, byte[] dest, int destIndex, int length)
        {
            for (int pos = 0; sourceIndex + pos < sourceIndex + length; pos++)
            {
                if (dest[destIndex + pos] != 00)
                    throw new Exception(string.Format("Address {0:X8} already in use", destIndex + pos));
                dest[destIndex + pos] = source[sourceIndex + pos];
            }
        }

        static bool WillFit(byte?[] dest, int pos, int size, byte[] source)
        {
            for (int addr = pos; addr < pos + size; addr++)
            {
                if (addr >= dest.Length) return true;
                if (dest[addr] != null && ((addr - pos >= source.Length) || dest[addr] != source[addr - pos]))
                    return false;
            }
            return true;
        }
        static bool WillFit(byte?[] dest, int pos, int size, byte?[] source)
        {
            for (int addr = pos; addr < pos + size; addr++)
            {
                if (addr >= dest.Length) return true;
                if ((source[addr - pos] != null && dest[addr] != null) && ((addr - pos >= source.Length) || dest[addr] != source[addr - pos]))
                    return false;
            }
            return true;
        }

        static byte[] StringToTiles(string text)
        {
            //text = text.ToUpper();
            var result = new byte[text.Length + 1];
            for (int c = 0; c < result.Length; c++)
            {

                if (c < text.Length)
                {
                    //int charCode = Encoding.GetEncoding(1251).GetBytes(text[c].ToString())[0]; // =Oo=
                    if (text[c] >= 'A' && text[c] <= 'Z')
                        result[c] = (byte)(text[c] - 'A' + 0x01);
                    else if (text[c] >= 'a' && text[c] <= 'z')
                        result[c] = (byte)(text[c].ToString().ToUpper()[0] - 'A' + 0x01);
                    else if (text[c] >= '1' && text[c] <= '9')
                        result[c] = (byte)(text[c] - '1' + 0x1B);
                    else if (text[c] >= 'А' && text[c] <= 'Я')
                        result[c] = (byte)(text[c] - 'А' + 0x31);
                    else if (text[c] >= 'а' && text[c] <= 'я')
                        result[c] = (byte)(text[c] - 'а' + 0x51);
                    else
                        switch (text[c])
                        {
                            case '0':
                                result[c] = 0x0F;
                                break;
                            case '.':
                                result[c] = 0x24;
                                break;
                            case ',':
                                result[c] = 0x25;
                                break;
                            case '?':
                                result[c] = 0x26;
                                break;
                            case ':':
                                result[c] = 0x27;
                                break;
                            case '—':
                            case '-':
                                result[c] = 0x28;
                                break;
                            case '&':
                                result[c] = 0x29;
                                break;
                            case '!':
                                result[c] = 0x2A;
                                break;
                            case '(':
                                result[c] = 0x2B;
                                break;
                            case ')':
                                result[c] = 0x2C;
                                break;
                            case '\'':
                                result[c] = 0x2D;
                                break;
                            case '#':
                            case '+':
                                result[c] = 0x2E;
                                break;
                            case '_':
                                result[c] = 0x2F;
                                break;
                            default:
                                result[c] = 0x30;
                                break;
                        }
                    result[c] += 0x80;
                }
            }
            return result;
        }

        static string BytesToAsm(byte[] name)
        {
            var asmResult = new StringBuilder();
            for (int ch = 0; ch < name.Length; ch++)
            {
                if (ch % 15 == 0)
                {
                    if (ch > 0) asmResult.AppendLine();
                    asmResult.Append("  .db");
                }
                asmResult.AppendFormat(((ch % 15 > 0) ? "," : "") + " ${0:X2}", name[ch]);
            }
            asmResult.AppendLine();
            return asmResult.ToString();
        }

        static string FirstCharToUpper(string input)
        {
            if (String.IsNullOrEmpty(input)) return "";
            return input.First().ToString().ToUpper() + input.Substring(1);
        }

        static byte?[] EnlargePrgFull(byte[] originalPrg)
        {
            var prg = new byte?[128 * 1024];
            for (int i = 0; i < prg.Length; i++)
                prg[i] = originalPrg[i % originalPrg.Length];
            return prg;
        }
        static byte?[] EnlargePrgLastBank(byte[] originalPrg)
        {
            var prg = new byte?[128 * 1024];
            for (int i = 0; i < originalPrg.Length; i++)
                prg[i] = originalPrg[i];
            for (int i = originalPrg.Length - 0x4000; i < originalPrg.Length; i++)
                prg[prg.Length - (originalPrg.Length - i)] = originalPrg[i];
            return prg;
        }

        enum GameFlags
        {
            Separator = 0x80,
            WillNotWorkOnNtsc = 0x01,
            WillNotWorkOnPal = 0x02,
            WillNotWorkOnDendy = 0x04,
            WillNotWorkOnNewDendy = 0x08
        };

        enum EnlargeMode
        {
            None = 0x00,
            LastBankOnly = 0x01,
            FullMirror = 0x02
        };

        class Game
        {
            public string FileName;
            public string MenuName;
            public int PrgSize;
            public int ChrSize;
            public int PrgPos;
            public int ChrPos;
            public byte SaveId;
            public GameFlags Flags;
            public EnlargeMode EMode;
            public bool Battery;
            public byte Mapper;
            public NesFile.MirroringType Mirroring;
            public uint CRC32;

            public static void LoadGames(List<Game> games, string fileName, string menuName = null)
            {
                var game = new Game(fileName, menuName);
                games.Add(game);
                GC.Collect();
            }

            public Game(string fileName, string menuName = null)
            {
                PrgPos = -1;
                ChrPos = -1;
                // Separators
                if (fileName == "-")
                {
                    MenuName = "";
                    FileName = "";
                    PrgSize = 0;
                    ChrSize = 0;
                    Flags |= GameFlags.Separator;
                }
                else
                {

                    Console.WriteLine("Loading {0}...", Path.GetFileName(fileName));
                    FileName = fileName;
                    var nesFile = new NesFile(fileName);
                    var fix = nesFile.CorrectRom();
                    if (fix != 0)
                        Console.WriteLine(" Invalid header. Fix: " + fix);
                    PrgSize = nesFile.PRG.Length;
                    ChrSize = nesFile.CHR.Length;
                    Battery = nesFile.Battery;
                    Mapper = nesFile.Mapper;
                    Mirroring = nesFile.Mirroring;
                    CRC32 = nesFile.CRC32;
                    if (nesFile.Trainer != null && nesFile.Trainer.Length > 0)
                        throw new Exception(string.Format("{0} - trained games are not supported yet", Path.GetFileName(fileName)));
                    MenuName = menuName;
                }
            }

            public NesFile ROM
            {
                get
                {
                    if (string.IsNullOrEmpty(FileName))
                    {
                        var nesFile = new NesFile();
                        nesFile.PRG = new byte[0];
                        nesFile.CHR = new byte[0];
                        return nesFile;
                    }
                    else
                    {
                        var nesFile = new NesFile(FileName);
                        var fix = nesFile.CorrectRom();
                        return nesFile;
                    }
                }
            }

            public override string ToString()
            {
                string name;
                if (MenuName != null)
                {
                    if (MenuName.StartsWith("+"))
                        name = MenuName.Substring(1).Trim();
                    else
                        name = MenuName.Trim();
                }
                else
                {
                    name = Regex.Replace(Regex.Replace(Path.GetFileNameWithoutExtension(FileName), @" ?\(.{1,3}[0-9]?\)", string.Empty), @" ?\[.*?\]", string.Empty).Trim().Replace("_", " ").Replace(", The", "");
                }
                name = name.Trim();
                if (name.Length > 28) name = name.Substring(0, 25).Trim() + "...";
                return name.Trim();
            }
        }
    }
}
