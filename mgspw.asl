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

state("mgspw") {}

startup {

    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
/*
*/
    //This allows is to look through a bitmask in order to get split information
    vars.bitCheck = new Func<int, int, bool>((int val, int b) => (val & (1 << b)) != 0);

    settings.Add("splits", true, "Split Points");

    vars.completedSplits = 0;
    print("Startup complete");
}

init {
  // find linkVarBuf starting point
  IntPtr gameStats = vars.Helper.ScanRel(3, "48 8B 05 ?? ?? ?? ?? 48 05 34 83 01 00 C3");

  vars.Helper["TotalPlaytime"] = vars.Helper.Make<uint>(gameStats, 0x84);

  vars.completedSplits = new HashSet<string>();
}

update {
    vars.Helper.Update();
  	vars.Helper.MapPointers();
}

gameTime
{
	return TimeSpan.FromMilliseconds(current.TotalPlaytime * 1000 / 60);
}

onStart {
  vars.completedSplits.Clear();
}
start {
//  return (current.MapName != "title" && old.MapName == "title");
}

split {
    /*
    if (current.scenarioProgress != old.scenarioProgress) {
        print("reached_" + current.scenarioProgress);
        return (settings.ContainsKey("reached_" + current.scenarioProgress)
                && settings["reached_" + current.scenarioProgress]
                && vars.completedSplits.Add("reached_" + current.scenarioProgress));
    }
    if (current.MapName != old.MapName) {
        print("reached_" + current.MapName);
        return (settings.ContainsKey("reached_" + current.MapName)
                && settings["reached_" + current.MapName]
                && vars.completedSplits.Add("reached_" + current.MapName));
    }
    */
}

reset {
  //return current.MapName == "title";
}

onReset
{
 // vars.completedSplits.Clear();
  return true;
}