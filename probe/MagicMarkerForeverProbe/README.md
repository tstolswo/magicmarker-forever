# MagicMarker Forever feasibility probe

This standalone addon tests one question: while the player is out of combat, does holding **ALT** and sweeping the mouse over hostile units let an `UPDATE_MOUSEOVER_UNIT` handler call `SetRaidTarget` directly? It intentionally does not use a per-mob click or secure-button substitute. It never attempts a mark while `InCombatLockdown()` or `UnitAffectingCombat("player")` is true, and disarms when combat starts.

This is an experiment, not a working MagicMarker port. A `pcall` that returns successfully is recorded as an attempt only. The probe records a separate `mark-observed` result only when `GetRaidTargetIndex` subsequently reports the assigned icon for the same GUID. An absent observation is not proof that the action failed; inspect the client and error records.

## Install

Copy this entire folder to the installed Forever client’s AddOns directory:

`/mnt/c/Program Files (x86)/World of Warcraft/_forever_/Interface/AddOns/MagicMarkerForeverProbe/`

The folder must directly contain `MagicMarkerForeverProbe.toc`, `Probe.lua`, and this README. Restart the client or run `/reload`, then confirm the addon is enabled on the character selection AddOns screen. The TOC targets interface `16001`; the addon records the actual `GetBuildInfo()` result at load and at each start.

## Test steps

1. Use a disposable character or a safe area with a small hostile pack. Do not start combat. Ensure the player has permission to set raid target icons if the client requires a group role.
2. Run `/mmf status` and note the recorded build/interface and current reservations.
3. Run `/mmf start`. The probe refuses to arm if it detects combat or cannot read the combat state.
4. Hold **ALT** and sweep over each living hostile mob. Do not click while sweeping. The addon reacts only to mouseover identity changes and attempts each accessible GUID once; existing marks are left alone. It allocates the first unoccupied icon from skull through star, accounting for its own confirmed/pending reservations and marks observed on readable target/nameplate/group unit tokens.
5. Run `/mmf status`. `mark-observed` indicates the client exposed the assigned icon after the direct call; `mark-attempted-unobserved`, `setraidtarget-error-disarmed`, `skipped-*`, and `addon_action_*` distinguish other outcomes. Check whether the actual world markers appeared and whether the client displayed a blocked-action error.
6. Run `/mmf stop` before leaving the test area. If combat starts unexpectedly, the probe disarms and records that event without attempting any combat mark.
7. For a persistent record, use `/reload` or log out normally, then inspect `WTF/Account/<account>/SavedVariables/MagicMarkerForeverProbe.lua`. The record list is bounded to 300 entries. Send the exact client build, visible result, status output, and any blocked-action/error records with the test report.

## Commands

- `/mmf start` — arm out-of-combat ALT + mouseover sweep.
- `/mmf stop` — disarm.
- `/mmf status` — print build, tracked GUID-to-icon reservations, currently observable assignments, and recent records.
- `/mmf reset` — clear diagnostic records while retaining GUID reservations. This does not clear any in-world marks.
- `/mmf newtest` — disarm and clear GUID/icon reservations. Use only after verifying a fresh, unmarked test pack; this does not clear in-world marks.

## Limits and safety

- No runtime result has been established by shipping this source; run it in the exact Forever client build under review.
- The occupancy scan only covers unit tokens the client exposes to this addon. Raid icons on inaccessible or distant units may not be discovered. Do the test with a clean, controlled pack and inspect all existing marks first.
- Confirmed, pending, and observed icon reservations are bounded to the eight raid icons and persist in SavedVariables. `reset` keeps reservations. `newtest` clears them, so use only with a fresh unmarked pack.
- The probe guards nil/inaccessible GUIDs, unreadable icon state, failed combat-state queries, and protected-call errors. It does not clear marks, remark in combat, or send messages.
