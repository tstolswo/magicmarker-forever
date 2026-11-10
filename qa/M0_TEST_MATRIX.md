# M0 precombat sweep test matrix

## Scope and evidence status

M0 is a manual, precombat **ALT + mouseover** sweep probe for the WoW Forever client. This matrix is specific to the WoW Forever service and its actual client build; it does not claim compatibility with Vanilla private clients, Blizzard Classic, or Retail.

The probe and its behavior have not yet been verified in game. **All cases below are NOT RUN.** Offline Lua mock results, if added, are code-level checks only and do not count as in-game evidence.

Run the focused offline mock checks from the repository root with:

```sh
lua qa/mock_probe.lua probe/MagicMarkerForeverProbe/Probe.lua
```

These exercise the probe through mocked addon events and WoW API calls. They cannot establish protected-action permissions, real unit tokens, server group authority, or marker appearance.

## Record before testing

| Field | Value |
|---|---|
| Tester / date / timezone | NOT RECORDED |
| WoW Forever realm | NOT RECORDED |
| Client executable version (Windows VersionInfo) | 1.60.1.70862 (reported by project lead; not independently rechecked here) |
| Runtime build/version from `GetBuildInfo()` / interface number | NOT RECORDED — capture in game; executable metadata is not a substitute |
| OS / locale | NOT RECORDED |
| Probe commit or source revision | NOT RECORDED |
| Probe folder installed under `Interface/AddOns` | NOT RECORDED |
| Addon enabled at character select; reload performed | NOT RECORDED |
| Group type and marking authority (solo/party/raid; leader/assistant/member) | NOT RECORDED |
| Enabled Lua errors / other addons | NOT RECORDED |
| Test area and NPC names | NOT RECORDED |

Record the exact client build shown by the game, not a generic “Vanilla” label. Use `/console scriptErrors 1` if supported by this client, and capture full error text and the action immediately before it. Do not infer behavior from modern-client documentation.

## Preconditions

1. Install the probe as its own addon directory, enable it, and `/reload` (or log out/in if required). Verify it appears in the AddOns list and loads without Lua errors.
2. Use accessible **hostile mobs** that are still out of combat. Do not pull them to make them markable. Confirm every test target is valid for raid marking and that the tester has the group authority required by the server.
3. Record the current eight icon order/configuration. For clean-slate tests, start with no raid icons on test targets and no probe-held marks. Never reset icons placed by other players without their agreement.
4. Configure the intended tank icon sequence if the probe exposes this setting. Keep the initial configuration fixed through allocation cases.
5. Make a screen recording or capture before/after icon state where possible. Note each mouseover target sequence and modifier state.

## Manual acceptance cases

Status values: `NOT RUN`, `PASS`, `FAIL`, or `BLOCKED`. Do not mark PASS without client/build evidence and observations.

| ID | Scenario / steps | Expected result | Status / evidence |
|---|---|---|---|
| M0-01 | Fresh start: install/enable, reload, run `/mmf status`, then `/mmf start`. Approach at least four valid unmarked hostile mobs while not holding ALT; move the cursor across them. | Probe starts armed, reports the runtime build, and assigns no icon while ALT is up. No load or runtime error. | NOT RUN — |
| M0-02 | Hold ALT and sweep four distinct valid unmarked mobs once, in a recorded order. | Each successfully markable mob receives one icon following the configured tank order; no target receives conflicting or duplicate icons. | NOT RUN — |
| M0-03 | While ALT remains held, repeat mouseovers on already swept mobs, including rapid back-and-forth passes. | Existing assignments remain stable; no icon clear/reapply churn, reassignment, or extra allocation. | NOT RUN — |
| M0-04 | Sweep two mobs, move cursor off targets, release ALT, then mouseover several previously untouched mobs. | Releasing ALT stops further automatic marks immediately. Prior assignments stay intact. | NOT RUN — |
| M0-05 | Fill all eight raid icon slots using the configured order, then ALT-sweep one additional valid unmarked mob. | All eight icons remain assigned once each; the extra mob is left unchanged. No wraparound, overwrite, churn, or error. | NOT RUN — |
| M0-06 | Begin with one test mob carrying an icon assigned manually by a player. ALT-sweep it, then sweep a distinct unmarked mob. | An observed pre-existing icon is not silently overwritten or claimed as a probe success; new allocation does not duplicate/steal it. Record that a mob never yet seen by the probe may be unknowable to an in-memory-only probe. | NOT RUN — |
| M0-07 | Begin with another player’s icon on a non-test target. Run `/mmf reset`, then `/mmf status`; verify world icons and reservations before continuing. | `/mmf reset` clears diagnostic history only. It does not clear in-world marks or GUID/icon reservations. Existing icons remain untouched. | NOT RUN — |
| M0-08 | In a party and, if available, a raid, repeat one fresh-target mark test as leader/assistant and as ordinary member. | Authorized roles mark successfully. Unauthorized-role attempt fails safely: no false success/reservation, no repeated calls or Lua error. Record the server’s actual role rules. | NOT RUN — |
| M0-09 | Start precombat with ALT held and sweep one valid target; engage combat, continue moving mouse over fresh targets while still holding ALT. | Combat entry suspends automatic marking; no new target is marked during combat. No protected-action or taint error. | NOT RUN — |
| M0-10 | After a partial sweep, `/reload` (or relog). Run `/mmf status` and verify inactive; explicitly run `/mmf start`, then revisit the same mobs and sweep fresh mobs. | Assignments/reservations persist in SavedVariables, while automation defaults OFF after reload. Existing icons are protected when observed; record any limit for mobs the probe has never seen. Failed or unobserved calls are never reported as observed success. | NOT RUN — |
| M0-11 | With no suitable valid target under cursor, hold ALT and move across world/environment/UI, then onto a valid fresh mob. | Invalid/no-unit mouseovers cause no allocation; next valid target still receives the next available configured icon. | NOT RUN — |
| M0-12 | Optional future MVP check only: configure a non-default tank icon order (e.g. Circle, Skull, Star), reload if needed, sweep fresh mobs. | Custom icon order is beyond M0. Fixed order (Skull through Star) is expected for this probe. When configuration is implemented later, allocation must follow that exact order after reload. | DEFERRED — not an M0 gate |
| M0-13 | With a fresh, verified unmarked pack and no unrelated group marks, run `/mmf newtest`, then `/mmf status`. | Probe clears diagnostic history and saved reservations only. It does not clear in-world marks. Start a new test only after confirming the pack really is unmarked. | NOT RUN — |

## Defect and evidence recording

For every failure or unexpected result, include case ID, exact ordered mouseover targets, ALT state, group/authority, current icons before and after, combat state, client build, probe revision, and full Lua/server error text. Attach a short recording or screenshots when available. Separate client/API errors from server permission rejection and from intended “no icon available” behavior.

Any icon churn, reassignment of another player's marks, marking after ALT release, new marking in combat, false success after a failed API/permission call, or overwrite after the eight-icon pool is full is a release-blocking defect. Repeat a failing case once from a clean test state and record both results; do not erase evidence or reset other players’ icons to reproduce.

## Sign-off

| Gate | Result | Evidence / owner |
|---|---|---|
| Manual M0 cases completed on named WoW Forever build | NOT RUN | — |
| No unresolved release-blocking defects | NOT RUN | — |
| Tester sign-off / date | NOT RUN | — |
