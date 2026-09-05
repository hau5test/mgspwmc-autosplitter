/*****************************
Autospliter for Metal Gear Solid Peace Walker Master Collection on PC
Original work by https://github.com/hau5test
With help from SnakeSwiss.
******************************/
/**
disp32     = int32 at match+3
global     = match + 7 + disp32          -> 0xEA4860 here
stateBlock = *(uint64_t*)global

Offsets in the state block (types verified in the code that writes them):

+0x84 int32 : total play time in seconds. Written by the play-time routine as totalTicks / 300.
+0x8C int32 : a second play-time accumulator / 300, only advanced while a mode byte != 3 (not confirmed what it excludes).
+0x88 int32, +0x28 int32 : raw copies of two tick counters (see the static timers below).
+0x0C uint32 : progress flag word (bits are set/cleared/tested all over; semantics per bit not mapped).
+0x0A int16 : compared against 6 in ~20 places; likely a chapter/mode value, not confirmed.
+0x98 int32 : compared in 30+ places, zeroed by one reset routine; a "current selection" of some kind, not confirmed.
+0x20, +0x22, +0x24 int16 : event counters (+0x24 capped at 30000). 
+0x1F0..+0x1F6 int16 : more counters. Unlabeled.
+0x524C : table of 37 category descriptors (40 bytes each: +0x18 data ptr, +0x20 element size, +0x30 count) used by the game's own save accessors.
+0xBD38/+0xBD3C R&D weapons (count / array, stride 0x1C), 
+0xE2B8/+0xE2BC items, 
+0x13818 ZEKE parts, +0x18334 titles (384 bytes, 3 = earned).
*/

/*
StageCode Notes:
my_outer          Mother Base
ms_lobby          Mission Selector
flashdemo         Cutscene
result            Score Screen
epigram

w00s01a           00 - Intro (Base at the beach)
w01s01a           01 - Playa Del Alba
w01s02a           02 - Bosque Del Alba
w01s03a           03 - Puerto Del Alba
w01s03a           03 - Puerto Del Alba
w01s04a           04 - El Cenegal: Jungle ++ El Cenegal: Ravine ++ El Cenegal: Swamp
w01s05a           05 - Río del Jade 
w01s06a           06 - Bananal Fruta de Oro: Sorting Shed 
w01s06a           06 - Bananal Fruta de Oro: Sorting Shed 
*/
/*
Mission ID Notes
Chapter 1
    Mission 01 -- Investigate the Supply Facility
    Mission 02 -- Contact the Sandinista Comandante
    Mission 03 -- Pursue Amanda
    Mission 04 -- Armored Vehicle Battle: LAV-Type G
    Mission 05 -- Rescue Chico
    Mission 06 -- Pursue the Jungle Train
    Mission 07 -- Tank Battle: T-72U
    Mission 08 -- Destroy the Barricade
    Mission 09 -- Infiltrate the Crater Base
    Mission 10 -- Pupa Battle


Chapter 2
    Mission 11 -- Travel to the Cloud Forest
    Mission 12 -- Attack Chopper Battle: MI-24A
    Mission 13 -- Head for the Lab
    Mission 14 -- Locate the ID Card
    Mission 15 -- Chrysalis Battle

Chapter 3
    Mission 16 -- Travel to the Mine Base
    Mission 17 -- Eliminate the Guards
    Mission 18 -- Cocoon Battle
    Mission 19 -- Infiltrate the Underground Base
    Mission 20 -- Torture Chamber Escape
    Mission 21 -- Head for Peace Walker's Hangar
    Mission 22 -- Peace Walker Battle

Chapter 4
    Mission 23 -- Infiltrate the U.S. Missile Base
    Mission 24 -- Head to the Control Tower
    Mission 25 -- Peace Walker Battle 2
    Mission 26 -- Peace Walker Battle 3

Chapter 5
            Mission 27 -- Zadornov Search 1
ID 33       Mission 28 -- Zadornov Search 2
    Mission 29 -- Zadornov Search 3
    Mission 30 -- Zadornov Search 4
    Mission 31 -- Zadornov Search 5
    Mission 32 -- Zadornov Search 6
    Mission 33 -- Zeke Battle
*/

state("METAL GEAR SOLID PEACE WALKER") {}

startup {

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
/*
*/
    //This allows is to look through a bitmask in order to get split information
    vars.bitCheck = new Func<int, int, bool>((int val, int b) => (val & (1 << b)) != 0);

    vars.rankCheck = new Func<int, string> ((int rankNum) => {
      switch (rankNum) {
        case -1:
          return "Not Yet Played";
          break;
        case 0:
          return "S-Rank";
          break;
        case 1:
          return "A-Rank";
          break;
        case 2:
          return "B-Rank";
          break;
        case 3:
          return "C-Rank";
          break;
        default:
          return "Not Yet Played"; 
          break;
      }
    });

    vars.timeCheck = new Func<int, string> ((int checkMissionTime) => {
      if(checkMissionTime > 0) {
        print(TimeSpan.FromMilliseconds((int)checkMissionTime * 1000 / 300).ToString(@"mm\:ss\.ms"));
      } else {
        return "Not Played Yet";
      }
    });


    settings.Add("settings", true, "Settings");
    settings.Add("splits", true, "Split Points");

    settings.CurrentDefaultParent = "settings";
    settings.Add("s_rank", true, "Split only on S-Rank");

    settings.CurrentDefaultParent = "splits";
    settings.Add("chapter_1", true, "Chapter 1", "splits");
    settings.CurrentDefaultParent = "chapter_1";
      settings.Add("1_result", false, "Investigate the Supply Facility");
      settings.Add("2_result", false, "Contact the Sandinista Comandante");
      settings.Add("3_result", false, "Pursue Amanda");
      settings.Add("4_result", false, "Armored Vehicle Battle: LAV-Type G");
      settings.Add("5_result", false, "Rescue Chico");
      settings.Add("6_result", false, "Pursue the Jungle Train");
      settings.Add("7_result", false, "Tank Battle: T-72U");
      settings.Add("8_result", false, "Destroy the Barricade");
      settings.Add("9_result", false, "Infiltrate the Crater Base");
      settings.Add("10_result", false, "Pupa Battle");

    settings.CurrentDefaultParent = "chapter_2";
    settings.Add("chapter_2", true, "Chapter 2", "splits");
      settings.Add("11_result", false, "Travel to the Cloud Forest");
      settings.Add("12_result", false, "Attack Chopper Battle: MI-24A");
      settings.Add("13_result", false, "Head for the Lab");
      settings.Add("14_result", false, "Locate the ID Card");
      settings.Add("15_result", false, "Chrysalis Battle");

    settings.CurrentDefaultParent = "chapter_3";
    settings.Add("chapter_3", true, "Chapter 3", "splits");
      settings.Add("16_result", false, "Travel to the Mine Base");
      settings.Add("17_result", false, "Eliminate the Guards");
      settings.Add("18_result", false, "Cocoon Battle");
      settings.Add("19_result", false, "Infiltrate the Underground Base");
      settings.Add("20_result", false, "Torture Chamber Escape");
      settings.Add("21_result", false, "Head for Peace Walker's Hangar");
      settings.Add("22_result", false, "Peace Walker Battle");

    settings.CurrentDefaultParent = "chapter_4";
    settings.Add("chapter_4", true, "Chapter 4", "splits");
      settings.Add("23_result", false, "Infiltrate the U.S. Missile Base");
      settings.Add("24_result", false, "Head to the Control Tower");
      settings.Add("25_result", false, "Peace Walker Battle 2");
      settings.Add("26_flashdemo", false, "Peace Walker Battle 3");

    settings.CurrentDefaultParent = "chapter_5";
    settings.Add("chapter_5", true, "Chapter 5", "splits");
      settings.Add("27_result", false, "Zadornov Search 1");
      settings.Add("28_result", false, "Zadornov Search 2");
      settings.Add("29_result", false, "Zadornov Search 3");
      settings.Add("30_result", false, "Zadornov Search 4");
      settings.Add("31_result", false, "Zadornov Search 5");
      settings.Add("32_result", false, "Zadornov Search 6");
      settings.Add("33_flashdemo", false, "Zeke Battle");

    print("Startup complete");
}

init {
  // find linkVarBuf starting point - provided by SnakeSwiss
  IntPtr gameStats = vars.Helper.ScanRel(3, "48 8B 05 ?? ?? ?? ?? 48 05 34 83 01 00 C3");
  vars.Helper["missionTimerTicks"] = vars.Helper.Make<uint>(gameStats, 0x22);
  vars.Helper["stageCode"] = vars.Helper.MakeString(gameStats, 0x54);
  vars.Helper["playtimeSec"] = vars.Helper.Make<uint>(gameStats, 0x84);
  vars.Helper["playtimeTick"] = vars.Helper.Make<uint>(gameStats, 0x88);
  vars.Helper["heroism"] = vars.Helper.Make<uint>(gameStats, 0x64F4);
  vars.Helper["missionTicks"] = vars.Helper.Make<uint>(gameStats, 0x3C980);
  vars.Helper["missionBestTicks"] = vars.Helper.Make<uint>(gameStats, 0x3CA20);
  vars.Helper["missionScore"] = vars.Helper.Make<uint>(gameStats, 0x3C9A8);
  vars.Helper["missionId"] = vars.Helper.Make<uint>(gameStats, 0x5244);
  vars.Helper["missiontimer1"] = vars.Helper.Make<uint>(gameStats, 0x586C);
  vars.Helper["missiontimer2"] = vars.Helper.Make<uint>(gameStats, 0x5874);
  vars.Helper["missionId"] = vars.Helper.Make<uint>(gameStats, 0x5244);
  vars.Helper["missionReplays"] = vars.Helper.Make<uint>(gameStats, 0x656C);
  vars.Helper["heroismDelta"] = vars.Helper.Make<uint>(gameStats, 0x64EC);
  vars.Helper["heroism"] = vars.Helper.Make<uint>(gameStats, 0x64F4);
  vars.Helper["gmp"] = vars.Helper.Make<uint>(gameStats, 0xB52C);
  vars.Helper["characterUsed"] = vars.Helper.MakeString(gameStats, 0x1C098);

// best time records
  vars.Helper["stageBestTimeM_1"] = vars.Helper.Make<short>(gameStats, 0x29B8);
  vars.Helper["stageBestTimeM_2"] = vars.Helper.Make<short>(gameStats, 0x29BC);
  vars.Helper["stageBestTimeM_3"] = vars.Helper.Make<short>(gameStats, 0x29C0);
  vars.Helper["stageBestTimeM_4"] = vars.Helper.Make<short>(gameStats, 0x29C4);
  vars.Helper["stageBestTimeM_5"] = vars.Helper.Make<short>(gameStats, 0x29C8);
  vars.Helper["stageBestTimeM_6"] = vars.Helper.Make<short>(gameStats, 0x29CC);
  vars.Helper["stageBestTimeM_7"] = vars.Helper.Make<short>(gameStats, 0x29D0);
  vars.Helper["stageBestTimeM_8"] = vars.Helper.Make<short>(gameStats, 0x29D4);
  vars.Helper["stageBestTimeM_9"] = vars.Helper.Make<short>(gameStats, 0x29D8);
  vars.Helper["stageBestTimeM_10"] = vars.Helper.Make<short>(gameStats, 0x29DC);
  vars.Helper["stageBestTimeM_11"] = vars.Helper.Make<short>(gameStats, 0x29E0);
  vars.Helper["stageBestTimeM_12"] = vars.Helper.Make<short>(gameStats, 0x29E4);
  vars.Helper["stageBestTimeM_13"] = vars.Helper.Make<short>(gameStats, 0x29E8);
  vars.Helper["stageBestTimeM_14"] = vars.Helper.Make<short>(gameStats, 0x29EC);
  vars.Helper["stageBestTimeM_15"] = vars.Helper.Make<short>(gameStats, 0x29F0);
  vars.Helper["stageBestTimeM_16"] = vars.Helper.Make<short>(gameStats, 0x29F4);
  vars.Helper["stageBestTimeM_17"] = vars.Helper.Make<short>(gameStats, 0x29F8);
  vars.Helper["stageBestTimeM_18"] = vars.Helper.Make<short>(gameStats, 0x29FC);
  vars.Helper["stageBestTimeM_19"] = vars.Helper.Make<short>(gameStats, 0x2A00);
  vars.Helper["stageBestTimeM_20"] = vars.Helper.Make<short>(gameStats, 0x2A04);
  vars.Helper["stageBestTimeM_21"] = vars.Helper.Make<short>(gameStats, 0x2A08);
  vars.Helper["stageBestTimeM_22"] = vars.Helper.Make<short>(gameStats, 0x2A0C);
  vars.Helper["stageBestTimeM_23"] = vars.Helper.Make<short>(gameStats, 0x2A10);
  vars.Helper["stageBestTimeM_24"] = vars.Helper.Make<short>(gameStats, 0x2A14);
  vars.Helper["stageBestTimeM_25"] = vars.Helper.Make<short>(gameStats, 0x2A18);
  vars.Helper["stageBestTimeM_26"] = vars.Helper.Make<short>(gameStats, 0x2A1C);
  vars.Helper["stageBestTimeM_27"] = vars.Helper.Make<short>(gameStats, 0x2A20);
  vars.Helper["stageBestTimeM_28"] = vars.Helper.Make<short>(gameStats, 0x2A24);
  vars.Helper["stageBestTimeM_29"] = vars.Helper.Make<short>(gameStats, 0x2A28);
  vars.Helper["stageBestTimeM_30"] = vars.Helper.Make<short>(gameStats, 0x2A2C);
  vars.Helper["stageBestTimeM_31"] = vars.Helper.Make<short>(gameStats, 0x2A30);
  vars.Helper["stageBestTimeM_32"] = vars.Helper.Make<short>(gameStats, 0x2A34);
  vars.Helper["stageBestTimeM_33"] = vars.Helper.Make<short>(gameStats, 0x2A38);

// best rank records
  vars.Helper["stageClearCodeM_1"] = vars.Helper.Make<short>(gameStats, 0x32B6);
  vars.Helper["stageClearCodeM_2"] = vars.Helper.Make<short>(gameStats, 0x32B8);
  vars.Helper["stageClearCodeM_3"] = vars.Helper.Make<short>(gameStats, 0x32BA);
  vars.Helper["stageClearCodeM_4"] = vars.Helper.Make<short>(gameStats, 0x32BC);
  vars.Helper["stageClearCodeM_5"] = vars.Helper.Make<short>(gameStats, 0x32BE);
  vars.Helper["stageClearCodeM_6"] = vars.Helper.Make<short>(gameStats, 0x32C0);
  vars.Helper["stageClearCodeM_7"] = vars.Helper.Make<short>(gameStats, 0x32C2);
  vars.Helper["stageClearCodeM_8"] = vars.Helper.Make<short>(gameStats, 0x32C4);
  vars.Helper["stageClearCodeM_9"] = vars.Helper.Make<short>(gameStats, 0x32C6);
  vars.Helper["stageClearCodeM_10"] = vars.Helper.Make<short>(gameStats, 0x32C8);
  vars.Helper["stageClearCodeM_11"] = vars.Helper.Make<short>(gameStats, 0x32CA);
  vars.Helper["stageClearCodeM_12"] = vars.Helper.Make<short>(gameStats, 0x32CC);
  vars.Helper["stageClearCodeM_13"] = vars.Helper.Make<short>(gameStats, 0x32CE);
  vars.Helper["stageClearCodeM_14"] = vars.Helper.Make<short>(gameStats, 0x32D0);
  vars.Helper["stageClearCodeM_15"] = vars.Helper.Make<short>(gameStats, 0x32D2);
  vars.Helper["stageClearCodeM_16"] = vars.Helper.Make<short>(gameStats, 0x32D4);
  vars.Helper["stageClearCodeM_17"] = vars.Helper.Make<short>(gameStats, 0x32D6);
  vars.Helper["stageClearCodeM_18"] = vars.Helper.Make<short>(gameStats, 0x32D8);
  vars.Helper["stageClearCodeM_19"] = vars.Helper.Make<short>(gameStats, 0x32DA);
  vars.Helper["stageClearCodeM_20"] = vars.Helper.Make<short>(gameStats, 0x32DC);
  vars.Helper["stageClearCodeM_21"] = vars.Helper.Make<short>(gameStats, 0x32DE);
  vars.Helper["stageClearCodeM_22"] = vars.Helper.Make<short>(gameStats, 0x32E0);
  vars.Helper["stageClearCodeM_23"] = vars.Helper.Make<short>(gameStats, 0x32E2);
  vars.Helper["stageClearCodeM_24"] = vars.Helper.Make<short>(gameStats, 0x32E4);
  vars.Helper["stageClearCodeM_25"] = vars.Helper.Make<short>(gameStats, 0x32E6);
  vars.Helper["stageClearCodeM_26"] = vars.Helper.Make<short>(gameStats, 0x32E8);
  vars.Helper["stageClearCodeM_27"] = vars.Helper.Make<short>(gameStats, 0x32EA);
  vars.Helper["stageClearCodeM_28"] = vars.Helper.Make<short>(gameStats, 0x32EC);
  vars.Helper["stageClearCodeM_29"] = vars.Helper.Make<short>(gameStats, 0x32EE);
  vars.Helper["stageClearCodeM_30"] = vars.Helper.Make<short>(gameStats, 0x32F0);
  vars.Helper["stageClearCodeM_31"] = vars.Helper.Make<short>(gameStats, 0x32F2);
  vars.Helper["stageClearCodeM_32"] = vars.Helper.Make<short>(gameStats, 0x32F4);
  vars.Helper["stageClearCodeM_33"] = vars.Helper.Make<short>(gameStats, 0x32F6);

  // more pointers - provided by Zexk https://github.com/zexk/bbtracker/blob/mgspw-foxhound-probe/docs/mgspw_research.md
  // should be same as "gameStats" by SnakeSwiss
  // IntPtr saveRoot = vars.Helper.ScanRel(3, "48 8B 05 ?? ?? ?? ?? 48 05 3C BD 00 00 C3");


  IntPtr missionTime = vars.Helper.ScanRel(3, "48 89 05 ?? ?? ?? ?? 41 0F BA E1 19");
  vars.Helper["highrestimer"] = vars.Helper.Make<uint>(missionTime);
  vars.Helper["timer1"] = vars.Helper.Make<uint>(missionTime, 0x08);
  vars.Helper["timer2"] = vars.Helper.Make<uint>(missionTime, 0x10);
  vars.Helper["timer3"] = vars.Helper.Make<uint>(missionTime, 0x14);

  IntPtr missionId = vars.Helper.ScanRel(3, "33 DB BE FF FF FF FF B9 FF FF FF 00 48 89 1D ?? ?? ?? ?? 8B EB 89 35 ?? ?? ?? ??");

  IntPtr statArray = vars.Helper.ScanRel(3, "48 83 EC 58 48 0F BF C1 48 8D 0C 80 48 8B 05 ?? ?? ?? ?? 0F 10 44 C8 10");

  IntPtr regionObject = vars.Helper.ScanRel(3, "8B 05 ?? ?? ?? ?? 48 8B 1D ?? ?? ?? ?? 85 C0 75 09 48 85 DB 0F 84 19 01 00 00 39 43 28");


  vars.completedSplits = new HashSet<string>();
  
  vars.missionTimer = "00:00:00";
  vars.missionTime =  "00:00:00";
  vars.missionBestTime =  "00:00:00";
  vars.playtimeTimer =  "00:00:00";
  vars.currentClearCode = "Not Played"; 
  vars.runStartFrames = 0;
}

update {
  vars.Helper.Update();
  vars.Helper.MapPointers();
    
  vars.missionTimer = TimeSpan.FromMilliseconds(current.missionTimerTicks * 1000 / 300 );
  vars.missionTime = TimeSpan.FromMilliseconds(current.missionTicks * 1000 / 300).ToString(@"mm\:ss\.ms");
  vars.missionBestTime = TimeSpan.FromMilliseconds(current.missionBestTicks * 1000 / 300).ToString(@"mm\:ss\.ms");
  vars.playtimeTimer = TimeSpan.FromSeconds(current.playtimeSec );

  if(current.missionId != old.missionId) {
    print("new mission started: mission id: " + current.missionId);
  }

  // for debugging
  if(current.stageCode != old.stageCode && current.stageCode == "result" && current.missionId > 0) {
    print("Current clear code for current mission " + current.missionId + ": " + ((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId]);
  }
  if(current.stageCode != old.stageCode && current.missionId > 0) {
    print("Current clear code for current mission " + current.missionId + ": " + ((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId]);
    vars.currentClearCode = vars.rankCheck((int)((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId]);
  }
}

gameTime
{
	return TimeSpan.FromMilliseconds((current.highrestimer - vars.runStartFrames) * 1000 / 300 );
}

onStart {
  vars.runStartFrames = current.highrestimer;
  vars.completedSplits.Clear();
  print("current total playtime at start of run: " + TimeSpan.FromMilliseconds((current.highrestimer) * 1000 / 300 ));
  print("starting run now!");

  print("Found PB data:");
  for (int i = 1; i < 34; i++) 
  {
    // print("Mission " + i + " best time: " + vars.timeCheck(i) + " best rank: " + vars.rankCheck(i));
    print("Mission " + i);
    print("best time: " + vars.timeCheck(Convert.ToInt32(((IDictionary<String, Object>)current)["stageBestTimeM_" + i])));
    print("best rank: " + vars.rankCheck(Convert.ToInt32(((IDictionary<String, Object>)current)["stageClearCodeM_" + i])));
  }
}
start {
  // for new game
  if ((old.stageCode != current.stageCode && current.stageCode == "epigram") || (old.stageCode == "ms_lobby" && current.stageCode != "ms_lobby")) return true;
}

split {
    if (current.stageCode != old.stageCode) {
        return (settings.ContainsKey(current.missionId + "_" + current.stageCode)
                && settings[current.missionId + "_" + current.stageCode]
                && vars.completedSplits.Add(current.missionId + "_" + current.stageCode)
                && ((settings["s_rank"] && ((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId] == 0) || !settings["s_rank"])
                );
    }
}

reset {
  return current.stageCode == "title";
}

onReset
{
  vars.completedSplits.Clear();

  vars.missionTimer = "00:00:00";
  vars.missionTime =  "00:00:00";
  vars.missionBestTime =  "00:00:00";
  vars.playtimeTimer =  "00:00:00";
  vars.currentClearCode = "Not Played"; 
  return true;
}