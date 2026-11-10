# Out-of-combat sweep feasibility verdict

## Runtime result

The probe was run in Forever **1.60.1, build 70862, interface 16001**. With the addon armed out of combat, ALT held, and the mouse swept over a living hostile, its `UPDATE_MOUSEOVER_UNIT` path reached the direct `SetRaidTarget("mouseover", icon)` call. The probe recorded `mark-attempted-unobserved` for icon 8 and no observed assignment. At the same timestamp, the client raised `ADDON_ACTION_FORBIDDEN` for `MagicMarkerForeverProbe` (`UNKNOWN()`). The `!BugGrabber` stack points to the `pcall(SetRaidTarget, ...)` call in [Probe.lua](../probe/MagicMarkerForeverProbe/Probe.lua), so the block is tied to that call, not merely inferred from the API’s protected label.

**Conclusion:** the direct addon-event implementation of ALT + mouseover sweep does not work on this tested build. This runtime result supersedes the earlier assumption that out-of-combat context might permit the direct call.

## Scope of the result

The probe attempted the mark but did not observe an icon. It did not demonstrate that every secure-action design is impossible. The available API evidence describes raid marking through `SecureActionButtonTemplate`; the probe did not test a secure button or secure mouse-enter handler.

No supported mechanism is currently evidenced that turns each mouseover transition during a held modifier into a secure raid-mark action without another hardware input. A normal mouseover event is the addon callback that was blocked; a secure action button conventionally dispatches its action from a click/key activation. Do not present click-per-mob or a key press per mob as meeting the requested sweep interaction.

## Next step

Do not invest in a broader port around direct `SetRaidTarget`. A narrowly scoped secure-hover spike is justified only if a primary Forever API/source reference or maintainer confirmation identifies a supported secure action triggered by mouse-enter without a click/key press. Otherwise the required interaction remains unsupported by the evidence collected, and the project should report that limitation rather than claim a working fork.

## Supported-path source review

The PM additionally reviewed the Forever branch of Blizzard UI source mirrored by Gethe:

- [SecureTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua): secure actions are dispatched through button activation. A native `SECURE_ACTIONS.raidtarget` exists with marker and action attributes, including `set-unmarked`; marking is not limited to macros. Modifier state selects action attributes, not a new activation for each world mouseover.
- [RestrictedFrames.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua): the exposed frame-handle methods include `SetBindingClick`, which installs a binding, but no direct `Click` method. `CallMethod` deliberately calls `forceinsecure()` before invoking the external method, so it does not provide a secure route back into ordinary addon marking code.
- [RestrictedEnvironment.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua): the restricted snippet API does not expose `SetRaidTarget` or `RunMacroText`. Reading modifier state in a snippet does not by itself grant access to either operation.

These are moving source references, not a binary-level proof about every possible technique. Together with the live failure, they provide no supported same-interaction mechanism to justify another speculative user test. Engineering recommendation: **no-go for the current exact hold-and-sweep requirement on the tested client**. Revisit only with a concrete supported API change or new evidence, or an explicitly agreed product-scope change. No further user action is required now; per-mob click/key marking would be a different interaction and has not been implemented or tested here.
