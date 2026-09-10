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
my_outer_ap       Recruit Stage
ms_lobby          Mission Selector
ms_lobby          Versus Ops
flashdemo         Cutscene / Demonstration
result            Score Screen
epigram           Opening Text "cutscene"

w00s01a           00 - Intro (Base at the beach)
w01s01a           01 - Playa Del Alba
w01s02a           02 - Bosque Del Alba
w01s03a           03 - Puerto Del Alba
w01s03a           03 - Puerto Del Alba
w01s04a           04 - El Cenegal: Jungle ++ El Cenegal: Ravine ++ El Cenegal: Swamp
w01s05a           05 - Río del Jade 
w01s06a           06 - Bananal Fruta de Oro: Sorting Shed 
w01s06a           06 - Bananal Fruta de Oro: Sorting Shed

w04s05n           Underground Passage B (Multiplayer?)

w06s02a           Deck

w07s01a           Isla del Monstruo 
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
    Mission 28 -- Zadornov Search 2
    Mission 29 -- Zadornov Search 3
    Mission 30 -- Zadornov Search 4
    Mission 31 -- Zadornov Search 5
    Mission 32 -- Zadornov Search 6
    Mission 33 -- Zeke Battle
*/

state("METAL GEAR SOLID PEACE WALKER") {}

startup {
  vars.D = new ExpandoObject();
  var D = vars.D;

  D.inMission = false;

  Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
/*
*/
  //This allows is to look through a bitmask in order to get split information
  D.bitCheck = new Func<int, int, bool>((int val, int b) => (val & (1 << b)) != 0);

  D.Ranks = new Dictionary<string, string>() {
    { "-1",  "Not Played Yet" },
    { "0",  "S-Rank" },
    { "1",  "A-Rank" },
    { "2",  "B-Rank" },
    { "3",  "C-Rank" }
  };

  D.Missions = new Dictionary<uint, string>() {
    { 1,  "Investigate the Supply Facility" },
    { 2,  "Contact the Sandinista Comandante" },
    { 3,  "Pursue Amanda" },
    { 4,  "Armored Vehicle Battle: LAV-Type G" },
    { 5,  "Rescue Chico" },
    { 6,  "Pursue the Jungle Train" },
    { 7,  "Tank Battle: T-72U" },
    { 8,  "Destroy the Barricade" },
    { 9,  "Infiltrate the Crater Base" },
    { 10,  "Pupa Battle" },
    { 11,  "Travel to the Cloud Forest" },
    { 12,  "Attack Chopper Battle: MI-24A" },
    { 13,  "Head for the Lab" },
    { 14,  "Locate the ID Card" },
    { 15,  "Chrysalis Battle" },
    { 16,  "Travel to the Mine Base" },
    { 17,  "Eliminate the Guards" },
    { 18,  "Cocoon Battle" },
    { 19,  "Infiltrate the Underground Base" },
    { 20,  "Torture Chamber Escape" },
    { 21,  "Head for Peace Walker's Hangar" },
    { 22,  "Peace Walker Battle" },
    { 23,  "" },
    { 24,  "Infiltrate the U.S. Missile Base" },
    { 25,  "Head to the Control Tower" },
    { 26,  "Peace Walker Battle 2" },
    { 27,  "Peace Walker Battle 3" },
    { 28,  "Zadornov Search 1" },
    { 29,  "Zadornov Search 3" },
    { 30,  "Zadornov Search 4" },
    { 31,  "Zadornov Search 6" },
    { 32,  "Zadornov Search 5" },
    { 33,  "Zadornov Search 2" },
    { 34,  "Zeke Battle" },
    { 35,  "" },
    { 36,  "[005] Marksmanship Challenge" },
    { 37,  "[006] Marksmanship Challenge" },
    { 38,  "[007] Marksmanship Challenge" },
    { 39,  "" },
    { 40,  "[009] Marksmanship Challenge" },
    { 41,  "[028] Item Capture" },
    { 42,  "[029] Item Capture" },
    { 43,  "[032] Classified Document Retrieval" },
    { 44,  "[030] Classified Document Retrieval" },
    { 45,  "[031] Classified Document Retrieval" },
    { 46,  "[062] Dead Man's Treasure" },
    { 47,  "[060] Dead Man's Treasure" },
    { 48,  "[061] Dead Man's Treasure" },
    { 49,  "[034] Claymore Disarmament" },
    { 50,  "[033] Claymore Disarmament" },
    { 51,  "" },
    { 52,  "[010] Fulton Recovery" },
    { 53,  "[011] Fulton Recovery" },
    { 54,  "[014] Fulton Recovery" },
    { 55,  "[016] Fulton Recovery" },
    { 56,  "[013] Fulton Recovery" },
    { 57,  "[012] Fulton Recovery" },
    { 58,  "" },
    { 59,  "[015] Fulton Recovery" },
    { 60,  "" },
    { 61,  "[017] Fulton Recovery" },
    { 62,  "" },
    { 63,  "" },
    { 64,  "" },
    { 65,  "[044] Defend Key Supplies" },
    { 66,  "" },
    { 67,  "[039] Base Defense" },
    { 68,  "[041] Base Defense" },
    { 69,  "" },
    { 70,  "" },
    { 71,  "[043] Defend Key Supplies" },
    { 72,  "[042] POW Defense" },
    { 73,  "[038] Base Defense" },
    { 74,  "" },
    { 75,  "" },
    { 76,  "" },
    { 77,  "[018] Target Demolition" },
    { 78,  "[019] Target Demolition" },
    { 79,  "" },
    { 80,  "" },
    { 81,  "[020] Target Demolition" },
    { 82,  "" },
    { 83,  "[021] Cargo Truck Demolition" },
    { 84,  "[026] Eliminate Enemy Soldiers" },
    { 85,  "[023] Eliminate Enemy Soldiers" },
    { 86,  "[024] Eliminate Enemy Soldiers" },
    { 87,  "" },
    { 88,  "[022] Eliminate Enemy Soldiers" },
    { 89,  "[052] Eliminate the Kidnappers" },
    { 90,  "" },
    { 91,  "" },
    { 92,  "[035] Hold Up" },
    { 93,  "[037] Hold Up" },
    { 94,  "" },
    { 95,  "" },
    { 96,  "" },
    { 97,  "" },
    { 98,  "" },
    { 99,  "[056] One Shot" },
    { 100,  "" },
    { 101,  "" },
    { 102,  "" },
    { 103,  "[059] Ghost Photography" },
    { 104,  "" },
    { 105,  "[066] Missile Intercept Mission" },
    { 106,  "" },
    { 107,  "" },
    { 108,  "[036] Hold Up" },
    { 109,  "[063] Pooyan Mission" },
    { 110,  "[065] Pooyan Mission" },
    { 111,  "[064] Pooyan Mission" },
    { 112,  "[053] Clearing Escape" },
    { 113,  "" },
    { 114,  "" },
    { 115,  "[051] Obstacle Demolition" },
    { 116,  "" },
    { 117,  "" },
    { 118,  "[054] Snake Gear Retrieval" },
    { 119,  "" },
    { 120,  "" },
    { 121,  "" },
    { 122,  "" },
    { 123,  "" },
    { 124,  "" },
    { 125,  "" },
    { 126,  "" },
    { 127,  "" },
    { 128,  "[045] Perfect Stealth" },
    { 129,  "[050] Perfect Stealth" },
    { 130,  "[046] Perfect Stealth" },
    { 131,  "[047] Perfect Stealth" },
    { 132,  "[048] Perfect Stealth" },
    { 133,  "[048] Perfect Stealth" },
    { 134,  "" },
    { 135,  "" },
    { 136,  "" },
    { 137,  "" },
    { 138,  "[057] Paparazzi" },
    { 139,  "" },
    { 140,  "[058] Paparazzi" },
    { 141,  "" },
    { 142,  "" },
    { 143,  "" },
    { 144,  "" },
    { 145,  "" },
    { 146,  "" },
    { 147,  "[025] Eliminate Enemy Soldiers" },
    { 148,  "[008] Marksmanship Challenge" },
    { 149,  "" },
    { 150,  "" },
    { 151,  "" },
    { 152,  "" },
    { 153,  "[040] Base Defense" },
    { 154,  "" },
    { 155,  "[027] Eliminate Enemy Soldiers" },
    { 156,  "[056] U.S. Soldier Rescue" },
    { 157,  "[067] Date with Paz" },
    { 158,  "[068] Date with Kaz" },
    { 159,  "[002] Target Practice: No Limit" },
    { 160,  "[004] Target Practice: Time Attack" },
    { 161,  "[001] Target Practice: No Limit" },
    { 162,  "[003] Target Practice: Score Attack" },
    { 163,  "[069] Armored Vehicle Battle: BTR-60 PA" },
    { 164,  "[070] Armored Vehicle Battle: BTR-60 PA Custom" },
    { 165,  "[071] Armored Vehicle Battle: BTR-60 PB" },
    { 166,  "[072] Armored Vehicle Battle: BTR-60 PB Custom" },
    { 167,  "[073] Armored Vehicle Battle: LAV Type-G Custom" },
    { 168,  "[074] Armored Vehicle Battle: LAV Type-C" },
    { 169,  "[075] Armored Vehicle Battle: LAV Type-C Custom" },
    { 170,  "[076] Tank Battle: T-72U" },
    { 171,  "[077] Tank Battle: T-72U Custom" },
    { 172,  "[078] Tank Battle: T-72A" },
    { 173,  "[079] Tank Battle: T-72A Custom" },
    { 174,  "[080] Tank Battle: KPz 70" },
    { 175,  "[081] Tank Battle: KPz 70 Custom" },
    { 176,  "[082] Tank Battle: MBTk-70" },
    { 177,  "[083] Tank Battle: MBTk-70 Custom" },
    { 178,  "[084] Attack Chopper Battle: Mi-24A" },
    { 179,  "[085] Attack Chopper Battle: Mi-24A Custom" },
    { 180,  "[086] Attack Chopper Battle: Mi-24D" },
    { 181,  "[087] Attack Chopper Battle: Mi-24D Custom" },
    { 182,  "[088] Attack Chopper Battle: AH56A-Bomber" },
    { 183,  "[089] Attack Chopper Battle: AH56A-Bomber Custom" },
    { 184,  "[090] Attack Chopper Battle: AH56A-Raider" },
    { 185,  "[091] Attack Chopper Battle: AH56A-Raider Custom" },
    { 186,  "[092] Tank Battle: T-72U Custom" },
    { 187,  "[093] Tank Battle: T-72A" },
    { 188,  "[094] Tank Battle: T-72A Custom" },
    { 189,  "[095] Tank Battle: KPz 70" },
    { 190,  "[096] Tank Battle: KPz 70 Custom" },
    { 191,  "[097] Tank Battle: MBTk-70" },
    { 192,  "[098] Tank Battle: MBTk-70 Custom" },
    { 193,  "[099] Armored Vehicle Battle: BTR-60 PA" },
    { 194,  "[100] Armored Vehicle Battle: BTR-60 PA Custom" },
    { 195,  "[101] Armored Vehicle Battle: BTR-60 PB" },
    { 196,  "[102] Armored Vehicle Battle: BTR-60 PB Custom" },
    { 197,  "[103] Armored Vehicle Battle: LAV-Type G" },
    { 198,  "[104] Armored Vehicle Battle: LAV-Type G Custom" },
    { 199,  "" },
    { 200,  "" },
    { 201,  "[105] Attack Chopper Battle: Mi-24A Custom" },
    { 202,  "[106] Attack Chopper Battle: Mi-24D" },
    { 203,  "[107] Attack Chopper Battle: Mi-24D Custom" },
    { 204,  "[108] Attack Chopper Battle: AH56A-Bomber" },
    { 205,  "[109] Attack Chopper Battle: AH56A-Bomber Custom" },
    { 206,  "[110] Attack Chopper Battle: AH56A-Raider" },
    { 207,  "[111] Attack Chopper Battle: AH56A-Raider Custom" },
    { 208,  "[112] AI Weapon Battle: Pupa Type II" },
    { 209,  "[114] AI Weapon Battle: Chrysalis Type II" },
    { 210,  "[116] AI Weapon Battle: Cocoon Type II" },
    { 211,  "" },
    { 212,  "[118] AI Weapon Battle: Peace Walker Type II" },
    { 217,  "[113] AI Weapon Battle: Pupa Custom" },
    { 218,  "[115] AI Weapon Battle: Chrysalis Custom" },
    { 219,  "[117] AI Weapon Battle: Cocoon Custom" },
    { 220,  "" },
    { 221,  "[119] AI Weapon Battle: Peace Walker Custom" },
    { 222,  "[120] Metal Gear ZEKE: Mock Battle" },
    { 223,  "" },
    { 224,  "" },
    { 225,  "[121] <<Hunting Quest: Rathalos>>" },
    { 226,  "[122] <<Hunting Quest: Rathalos / Twilight>>" },
    { 227,  "[123] <<Hunting Quest: Tigrex>>" },
    { 228,  "[124] <<Hunting Quest: Tigrex / Twilight>>" },
    { 229,  "[125] <<Hunting Quest: Gear REX>>" },
    { 230,  "[126] <<Hunting Quest: Gear REX / Twilight>>" },
    { 231,  "[127] Gear REX: Showdown at Crater Base" },
    { 232,  "[128] Gear REX Strikes Back" },
  };

  D.timeCheck = new Func<int, string> ((int checkMissionTime) => TimeSpan.FromMilliseconds((int)checkMissionTime * 1000 / 300).ToString(@"mm\:ss\.ms"));


    settings.Add("settings", true, "Settings");
    settings.Add("splits", true, "Split Points");

    settings.CurrentDefaultParent = "settings";
    settings.Add("s_rank", true, "Split only on S-Rank");

    settings.CurrentDefaultParent = "splits";
    settings.Add("main_ops", true, "Main Ops");
    settings.CurrentDefaultParent = "main_ops";
    settings.Add("chapter_1", true, "Chapter 1", "main_ops");
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
    settings.Add("chapter_2", true, "Chapter 2", "main_ops");
      settings.Add("11_result", false, "Travel to the Cloud Forest");
      settings.Add("12_result", false, "Attack Chopper Battle: MI-24A");
      settings.Add("13_result", false, "Head for the Lab");
      settings.Add("14_result", false, "Locate the ID Card");
      settings.Add("15_result", false, "Chrysalis Battle");

    settings.CurrentDefaultParent = "chapter_3";
    settings.Add("chapter_3", true, "Chapter 3", "main_ops");
      settings.Add("16_result", false, "Travel to the Mine Base");
      settings.Add("17_result", false, "Eliminate the Guards");
      settings.Add("18_result", false, "Cocoon Battle");
      settings.Add("19_result", false, "Infiltrate the Underground Base");
      settings.Add("20_result", false, "Torture Chamber Escape");
      settings.Add("21_result", false, "Head for Peace Walker's Hangar");
      settings.Add("22_result", false, "Peace Walker Battle");

    settings.CurrentDefaultParent = "chapter_4";
    settings.Add("chapter_4", true, "Chapter 4", "main_ops");
      settings.Add("24_result", false, "Infiltrate the U.S. Missile Base");
      settings.Add("25_result", false, "Head to the Control Tower");
      settings.Add("26_result", false, "Peace Walker Battle 2");
      settings.Add("27_ending_flow", false, "Peace Walker Battle 3");

    settings.CurrentDefaultParent = "chapter_5";
    settings.Add("chapter_5", true, "Chapter 5", "main_ops");
      settings.Add("28_result", false, "Zadornov Search 1");
      settings.Add("33_result", false, "Zadornov Search 2");
      settings.Add("29_result", false, "Zadornov Search 3");
      settings.Add("30_result", false, "Zadornov Search 4");
      settings.Add("32_result", false, "Zadornov Search 5");
      settings.Add("31_result", false, "Zadornov Search 6");
      settings.Add("34_result", false, "Zeke Battle");

    settings.CurrentDefaultParent = "extra_ops";
    settings.Add("extra_ops", true, "Extra OPs", "splits");
      settings.Add("161_result", false, "[001] Target Practice: No Limit");
      settings.Add("159_result", false, "[002] Target Practice: No Limit");
      settings.Add("162_result", false, "[003] Target Practice: Score Attack");
      settings.Add("160_result", false, "[004] Target Practice: Time Attack");
      settings.Add("36_result", false, "[005] Marksmanship Challenge");
      settings.Add("37_result", false, "[006] Marksmanship Challenge");
      settings.Add("38_result", false, "[007] Marksmanship Challenge");
      settings.Add("148_result", false, "[008] Marksmanship Challenge");
      settings.Add("40_result", false, "[009] Marksmanship Challenge");
      settings.Add("52_result", false, "[010] Fulton Recovery");
      settings.Add("53_result", false, "[011] Fulton Recovery");
      settings.Add("57_result", false, "[012] Fulton Recovery");
      settings.Add("56_result", false, "[013] Fulton Recovery");
      settings.Add("54_result", false, "[014] Fulton Recovery");
      settings.Add("59_result", false, "[015] Fulton Recovery");
      settings.Add("55_result", false, "[016] Fulton Recovery");
      settings.Add("61_result", false, "[017] Fulton Recovery");
      settings.Add("77_result", false, "[018] Target Demolition");
      settings.Add("78_result", false, "[019] Target Demolition");
      settings.Add("81_result", false, "[020] Target Demolition");
      settings.Add("83_result", false, "[021] Cargo Truck Demolition");
      settings.Add("88_result", false, "[022] Eliminate Enemy Soldiers");
      settings.Add("85_result", false, "[023] Eliminate Enemy Soldiers");
      settings.Add("86_result", false, "[024] Eliminate Enemy Soldiers");
      settings.Add("147_result", false, "[025] Eliminate Enemy Soldiers");
      settings.Add("84_result", false, "[026] Eliminate Enemy Soldiers");
      settings.Add("155_result", false, "[027] Eliminate Enemy Soldiers");
      settings.Add("41_result", false, "[028] Item Capture");
      settings.Add("42_result", false, "[029] Item Capture");
      settings.Add("44_result", false, "[030] Classified Document Retrieval");
      settings.Add("45_result", false, "[031] Classified Document Retrieval");
      settings.Add("43_result", false, "[032] Classified Document Retrieval");
      settings.Add("50_result", false, "[033] Claymore Disarmament");
      settings.Add("49_result", false, "[034] Claymore Disarmament");
      settings.Add("92_result", false, "[035] Hold Up");
      settings.Add("108_result", false, "[036] Hold Up");
      settings.Add("93_result", false, "[037] Hold Up");
      settings.Add("73_result", false, "[038] Base Defense");
      settings.Add("67_result", false, "[039] Base Defense");
      settings.Add("153_result", false, "[040] Base Defense");
      settings.Add("68_result", false, "[041] Base Defense");
      settings.Add("72_result", false, "[042] POW Defense");
      settings.Add("71_result", false, "[043] Defend Key Supplies");
      settings.Add("65_result", false, "[044] Defend Key Supplies");
      settings.Add("128_result", false, "[045] Perfect Stealth");
      settings.Add("130_result", false, "[046] Perfect Stealth");
      settings.Add("131_result", false, "[047] Perfect Stealth");
      settings.Add("133_result", false, "[048] Perfect Stealth");
      settings.Add("132_result", false, "[049] Perfect Stealth");
      settings.Add("129_result", false, "[050] Perfect Stealth");
      settings.Add("115_result", false, "[051] Obstacle Demolition");
      settings.Add("89_result", false, "[052] Eliminate the Kidnappers");
      settings.Add("112_result", false, "[053] Clearing Escape");
      settings.Add("118_result", false, "[054] Snake Gear Retrieval");
      settings.Add("156_result", false, "[055] U.S. Soldier Rescue");
      settings.Add("99_result", false, "[056] One Shot");
      settings.Add("138_result", false, "[057] Paparazzi");
      settings.Add("140_result", false, "[058] Paparazzi");
      settings.Add("103_result", false, "[059] Ghost Photography");
      settings.Add("47_result", false, "[060] Dead Man's Treasure");
      settings.Add("48_result", false, "[061] Dead Man's Treasure");
      settings.Add("46_result", false, "[062] Dead Man's Treasure");
      settings.Add("109_result", false, "[063] Pooyan Mission");
      settings.Add("111_result", false, "[064] Pooyan Mission");
      settings.Add("110_result", false, "[065] Pooyan Mission");
      settings.Add("105_result", false, "[066] Missile Intercept Mission");
      settings.Add("157_result", false, "[067] Date with Paz");
      settings.Add("158_result", false, "[068] Date with Kaz");
      settings.Add("163_result", false, "[069] Armored Vehicle Battle: BTR-60 PA");
      settings.Add("164_result", false, "[070] Armored Vehicle Battle: BTR-60 PA Custom");
      settings.Add("165_result", false, "[071] Armored Vehicle Battle: BTR-60 PB");
      settings.Add("166_result", false, "[072] Armored Vehicle Battle: BTR-60 PB Custom");
      settings.Add("167_result", false, "[073] Armored Vehicle Battle: LAV Type-G Custom");
      settings.Add("168_result", false, "[074] Armored Vehicle Battle: LAV Type-C");
      settings.Add("169_result", false, "[075] Armored Vehicle Battle: LAV Type-C Custom");
      settings.Add("170_result", false, "[076] Tank Battle: T-72U");
      settings.Add("171_result", false, "[077] Tank Battle: T-72U Custom");
      settings.Add("172_result", false, "[078] Tank Battle: T-72A");
      settings.Add("173_result", false, "[079] Tank Battle: T-72A Custom");
      settings.Add("174_result", false, "[080] Tank Battle: KPz 70");
      settings.Add("175_result", false, "[081] Tank Battle: KPz 70 Custom");
      settings.Add("176_result", false, "[082] Tank Battle: MBTk-70");
      settings.Add("177_result", false, "[083] Tank Battle: MBTk-70 Custom");
      settings.Add("178_result", false, "[084] Attack Chopper Battle: Mi-24A");
      settings.Add("179_result", false, "[085] Attack Chopper Battle: Mi-24A Custom");
      settings.Add("180_result", false, "[086] Attack Chopper Battle: Mi-24D");
      settings.Add("181_result", false, "[087] Attack Chopper Battle: Mi-24D Custom");
      settings.Add("182_result", false, "[088] Attack Chopper Battle: AH56A-Bomber");
      settings.Add("183_result", false, "[089] Attack Chopper Battle: AH56A-Bomber Custom");
      settings.Add("184_result", false, "[090] Attack Chopper Battle: AH56A-Raider");
      settings.Add("185_result", false, "[091] Attack Chopper Battle: AH56A-Raider Custom");
      settings.Add("186_result", false, "[092] Tank Battle: T-72U Custom");
      settings.Add("187_result", false, "[093] Tank Battle: T-72A");
      settings.Add("188_result", false, "[094] Tank Battle: T-72A Custom");
      settings.Add("189_result", false, "[095] Tank Battle: KPz 70");
      settings.Add("190_result", false, "[096] Tank Battle: KPz 70 Custom");
      settings.Add("191_result", false, "[097] Tank Battle: MBTk-70");
      settings.Add("192_result", false, "[098] Tank Battle: MBTk-70 Custom");
      settings.Add("193_result", false, "[099] Armored Vehicle Battle: BTR-60 PA");
      settings.Add("194_result", false, "[100] Armored Vehicle Battle: BTR-60 PA Custom");
      settings.Add("195_result", false, "[101] Armored Vehicle Battle: BTR-60 PB");
      settings.Add("196_result", false, "[102] Armored Vehicle Battle: BTR-60 PB Custom");
      settings.Add("197_result", false, "[103] Armored Vehicle Battle: LAV-Type G");
      settings.Add("198_result", false, "[104] Armored Vehicle Battle: LAV-Type G Custom");
      settings.Add("201_result", false, "[105] Attack Chopper Battle: Mi-24A Custom");
      settings.Add("202_result", false, "[106] Attack Chopper Battle: Mi-24D");
      settings.Add("203_result", false, "[107] Attack Chopper Battle: Mi-24D Custom");
      settings.Add("204_result", false, "[108] Attack Chopper Battle: AH56A-Bomber");
      settings.Add("205_result", false, "[109] Attack Chopper Battle: AH56A-Bomber Custom");
      settings.Add("206_result", false, "[110] Attack Chopper Battle: AH56A-Raider");
      settings.Add("207_result", false, "[111] Attack Chopper Battle: AH56A-Raider Custom");
      settings.Add("208_result", false, "[112] AI Weapon Battle: Pupa Type II");
      settings.Add("217_result", false, "[113] AI Weapon Battle: Pupa Custom");
      settings.Add("209_result", false, "[114] AI Weapon Battle: Chrysalis Type II");
      settings.Add("218_result", false, "[115] AI Weapon Battle: Chrysalis Custom");
      settings.Add("210_result", false, "[116] AI Weapon Battle: Cocoon Type II");
      settings.Add("219_result", false, "[117] AI Weapon Battle: Cocoon Custom");
      settings.Add("212_result", false, "[118] AI Weapon Battle: Peace Walker Type II");
      settings.Add("221_result", false, "[119] AI Weapon Battle: Peace Walker Custom");
      settings.Add("222_result", false, "[120] Metal Gear ZEKE: Mock Battle");
      settings.Add("225_result", false, "[121] <<Hunting Quest: Rathalos>>");
      settings.Add("226_result", false, "[122] <<Hunting Quest: Rathalos / Twilight>>");
      settings.Add("227_result", false, "[123] <<Hunting Quest: Tigrex>>");
      settings.Add("228_result", false, "[124] <<Hunting Quest: Tigrex / Twilight>>");
      settings.Add("229_result", false, "[125] <<Hunting Quest: Gear REX>>");
      settings.Add("230_result", false, "[126] <<Hunting Quest: Gear REX / Twilight>>");
      settings.Add("231_result", false, "[127] Gear REX: Showdown at Crater Base");
      settings.Add("232_result", false, "[128] Gear REX Strikes Back");

    print("Startup complete");
}

init {
  // find linkVarBuf starting point - provided by SnakeSwiss
  IntPtr gameStats = vars.Helper.ScanRel(3, "48 8B 05 ?? ?? ?? ?? 48 05 34 83 01 00 C3");
  // vars.Helper["missionTimerTicks"] = vars.Helper.Make<uint>(gameStats, 0x22);
  vars.Helper["stageCode"] = vars.Helper.MakeString(gameStats, 0x54);
  vars.Helper["playtimeSec"] = vars.Helper.Make<uint>(gameStats, 0x84);
  vars.Helper["missionId"] = vars.Helper.Make<uint>(gameStats, 0x5244);
  vars.Helper["curMissionLiveTimeTicks"] = vars.Helper.Make<uint>(gameStats, 0x28);
  vars.Helper["missionClearTimeTicks"] = vars.Helper.Make<uint>(gameStats, 0x3C980);
  vars.Helper["missionClearBestTimeTicks"] = vars.Helper.Make<uint>(gameStats, 0x3CA20);
  vars.Helper["missionClearScore"] = vars.Helper.Make<uint>(gameStats, 0x3C9A8);
  vars.Helper["missionTakedownCount"] = vars.Helper.Make<uint>(gameStats, 0x3CA00);
  vars.Helper["missionCQCCount"] = vars.Helper.Make<uint>(gameStats, 0x3CA08);
  vars.Helper["profileUserName"] = vars.Helper.MakeString(gameStats, 0x144);
  vars.Helper["profileGmp"] = vars.Helper.Make<uint>(gameStats, 0xB52C);
  vars.Helper["profileHeroism"] = vars.Helper.Make<uint>(gameStats, 0x64F4);
  vars.Helper["heroismDelta"] = vars.Helper.Make<uint>(gameStats, 0x64EC);
  vars.Helper["profileMissionsCleared"] = vars.Helper.Make<uint>(gameStats, 0x656C);
  vars.Helper["lastCharacterUsed"] = vars.Helper.MakeString(gameStats, 0x1C098);
  vars.Helper["fultons"] = vars.Helper.MakeString(gameStats, 0x130);

// best time records
for (int i = 0x01; i < 0xE9; i++)
  {
  // best time records
  vars.Helper["stageBestTimeM_" + i] = vars.Helper.Make<short>(gameStats, 0x29B4 + (4 * i));
  // best rank records
  vars.Helper["stageClearCodeM_" + i] = vars.Helper.Make<short>(gameStats, 0x32B4 + (2 * i));
  }

  // more pointers - provided by Zexk https://github.com/zexk/bbtracker/blob/mgspw-foxhound-probe/docs/mgspw_research.md
  // should be same as "gameStats" by SnakeSwiss
  // IntPtr saveRoot = vars.Helper.ScanRel(3, "48 8B 05 ?? ?? ?? ?? 48 05 3C BD 00 00 C3");


  IntPtr missionTime = vars.Helper.ScanRel(3, "48 89 05 ?? ?? ?? ?? 41 0F BA E1 19");
  vars.Helper["highrestimer"] = vars.Helper.Make<uint>(missionTime);

  IntPtr missionId = vars.Helper.ScanRel(3, "33 DB BE FF FF FF FF B9 FF FF FF 00 48 89 1D ?? ?? ?? ?? 8B EB 89 35 ?? ?? ?? ??");

  IntPtr statArray = vars.Helper.ScanRel(15, "48 83 EC 58 48 0F BF C1 48 8D 0C 80 48 8B 05 ?? ?? ?? ?? 0F 10 44 C8 10");
  vars.Helper["curMissionFinalTimeTicks"] = vars.Helper.Make<uint>(statArray, 0x620);
  vars.Helper["curMissionHoldUps"] = vars.Helper.Make<uint>(statArray, 0x788);
  vars.Helper["curMissionHeadshots"] = vars.Helper.Make<uint>(statArray, 0x7B0);
  vars.Helper["curMissionAlerts"] = vars.Helper.Make<uint>(statArray, 0x58);

  IntPtr regionObject = vars.Helper.ScanRel(9, "8B 05 ?? ?? ?? ?? 48 8B 1D ?? ?? ?? ?? 85 C0 75 09 48 85 DB 0F 84 19 01 00 00 39 43 28");

  IntPtr charArray = vars.Helper.ScanRel(8, "53 48 83 EC 20 48 8B 05 ?? ?? ?? ?? 48 63 D1 48 8B 0C D0");
  vars.Helper["health"] = vars.Helper.Make<uint>(charArray, 0x11BE);


  vars.completedSplits = new HashSet<string>();
  
  vars.missionName = "";
  vars.missionTime =  "00:00:00";
  vars.missionBestTime =  "00:00:00";
  vars.missionBestRank = "Not Played Yet";
  vars.totalPlaytime =  "00:00:00";
  vars.runStartFrames = 0;
}

update {
  var D = vars.D;
  vars.Helper.Update();
  vars.Helper.MapPointers();

  
  if(current.stageCode == "result" && old.stageCode != "result") {
    print("currently not in mission");
    D.inMission = false;
  } else if (old.stageCode == "ms_lobby" && current.stageCode != "ms_lobby") {
    print("currently in mission");
    D.inMission = true;
  }

  if(D.inMission) {
    vars.missionTime = TimeSpan.FromMilliseconds(current.curMissionLiveTimeTicks * 10 / 3).ToString(@"mm\:ss\.ff");
  } else {
    vars.missionTime = TimeSpan.FromMilliseconds(current.curMissionFinalTimeTicks * 10 / 3).ToString(@"mm\:ss\.ff");
  }

  vars.totalPlaytime = TimeSpan.FromSeconds(current.playtimeSec );
  if(
      (
        (current.stageCode == "result" && old.stageCode != "result") 
        ||
        (old.stageCode == "ms_lobby" && current.stageCode != "ms_lobby") 
        ||
        (current.missionId != old.missionId)
        ||
        (current.curMissionLiveTimeTicks > 0 && old.curMissionLiveTimeTicks == 0)
      )
      && current.missionId > 0 && current.missionId < 233) {
    print("potential split point: " + current.missionId + "_" + current.stageCode);
    string bestRank ="";
    D.Ranks.TryGetValue(Convert.ToString(((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId]), out bestRank);
    vars.missionBestRank =  bestRank;
    string currentMissionName = "";
    D.Missions.TryGetValue(Convert.ToUInt16(current.missionId), out currentMissionName);
    vars.missionName = currentMissionName;
    vars.missionBestTime = TimeSpan.FromMilliseconds(((IDictionary<String, Object>)current)["stageBestTimeM_" + current.missionId] * 10 / 3).ToString(@"mm\:ss\.ff");
  }

  if(((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId] != ((IDictionary<String, Object>)old)["stageClearCodeM_" + current.missionId]) {
    var newRank = "";
    D.Ranks.TryGetValue(Convert.ToString(((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId]), out newRank);
    vars.missionBestRank =  newRank;
    print("a clear code has changed! the clear code is: " + newRank + " on stage " + current.stageCode);
    vars.missionBestTime = TimeSpan.FromMilliseconds(((IDictionary<String, Object>)current)["stageBestTimeM_" + current.missionId] * 10 / 3).ToString(@"mm\:ss\.ff");
  }
  
}

gameTime
{
	return TimeSpan.FromMilliseconds((current.highrestimer - vars.runStartFrames) * 1000 / 300 );
}

onStart {
  var D = vars.D;
  D.inMission = true;
  vars.runStartFrames = current.highrestimer;
  vars.completedSplits.Clear();
  print("current total playtime at start of run: " + TimeSpan.FromMilliseconds((current.highrestimer) * 1000 / 300 ));
  print("starting run now!");
}

start {
  // for new game
  if ((old.stageCode != current.stageCode && current.stageCode == "epigram") || (old.stageCode == "ms_lobby" && current.stageCode != "ms_lobby")) return true;
}

split {
    if (
        current.stageCode != old.stageCode // on stage change
        && !settings["s_rank"]             // and not needing to check against S-Rank status
       ) { return (
                    settings.ContainsKey(current.missionId + "_" + current.stageCode)       // check if combination of mission ID + stageCode are present in settings set
                  && settings[current.missionId + "_" + current.stageCode]                  // if present, check if the toggle is active for the setting
                  && vars.completedSplits.Add(current.missionId + "_" + current.stageCode)  // finally, add the setting to the completedLists set, if already present, fail -> no split
                  );
    } else if (
                (settings["s_rank"]) // if needing to check against S-Rank when reaching result screen
                && ((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId] != ((IDictionary<String, Object>)old)["stageClearCodeM_" + current.missionId] // current and old rank in save are different
                && ((IDictionary<String, Object>)current)["stageClearCodeM_" + current.missionId] == 0 // and current rank in memory is S-Rank (value of 0)
              ) {
                return (
                    settings.ContainsKey(current.missionId + "_" + current.stageCode)       // check if combination of mission ID + stageCode are present in settings set
                  && settings[current.missionId + "_" + current.stageCode]                  // if present, check if the toggle is active for the setting
                  && vars.completedSplits.Add(current.missionId + "_" + current.stageCode)  // finally, add the setting to the completedLists set, if already present, fail -> no split
                  );
              }
}

reset {
  return current.stageCode == "title";
}

onReset
{
  vars.completedSplits.Clear();

  vars.missionName = "";
  vars.missionTime =  "00:00:00";
  vars.missionBestTime =  "00:00:00";
  vars.missionBestRank = "Not Played Yet";
  vars.totalPlaytime =  "00:00:00";
  return true;
}