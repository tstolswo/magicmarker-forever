# Out-of-combat sweep feasibility verdict

## Runtime result

The probe was run in Forever **1.60.1, build 70862, interface 16001**. With the addon armed out of combat, ALT held, and the mouse swept over a living hostile, its `UPDATE_MOUSEOVER_UNIT` path reached the direct `SetRaidTarget("mouseover", icon)` call. The probe recorded `mark-attempted-unobserved` for icon 8 and no observed assignment. At the same timestamp, the client raised `ADDON_ACTION_FORBIDDEN` for `MagicMarkerForeverProbe` (`UNKNOWN()`). The `!BugGrabber` stack points to the `pcall(SetRaidTarget, ...)` call in [Probe.lua](../probe/MagicMarkerForeverProbe/Probe.lua), so the block is tied to that call, not merely inferred from the API’s protected label.

**Conclusion:** the direct addon-event implementation of ALT + mouseover sweep does not work on this tested build. This runtime result supersedes the earlier assumption that out-of-combat context might permit the direct call.

## Scope of the result

The probe attempted the mark but did not observe an icon. It did not demonstrate that every secure-action design is impossible. The available API evidence describes raid marking through `SecureActionButtonTemplate`; the probe did not test a secure button or secure mouse-enter handler.

No supported mechanism is currently evidenced that turns each mouseover transition during a held modifier into a secure raid-mark action without another hardware input. A normal mouseover event is the addon callback that was blocked; a secure action button conventionally dispatches its action from a click/key activation. Do not present click-per-mob or a key press per mob as meeting the requested sweep interaction.

## Next step

Do not invest in a broader port around direct `SetRaidTarget`. A narrowly scoped secure-hover spike is justified only if a primary Forever API/source reference or maintainer confirmation identifies a supported secure action triggered by mouse-enter without a click/key press. Otherwise the required interaction remains unsupported by the evidence collected, and the project should report that limitation rather than claim a working fork.
