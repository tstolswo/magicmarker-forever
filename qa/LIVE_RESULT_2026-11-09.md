# M0 live result — direct mouseover marking blocked

## Verdict

**FAIL for the tested implementation.** On Forever 1.60.1 build 70862 (interface 16001), the probe's direct `SetRaidTarget("mouseover", 8)` call from the ALT-held mouseover event was forbidden. No mark was observed by the probe, and the tester confirmed that no icons appeared.

This establishes failure of the tested direct event-driven path. It does not prove every conceivable implementation impossible. No supported alternative preserving modifier-only sweep has been validated. Production MVP implementation and supported release publication remain gated.

## Evidence

- Source: initial commit `8c7b7ec7a3b6725ea2b27606e8aa30772f740aa5`.
- Installed package SHA-256: `bfe3fc9036f4b88d3aaec72f5177c14c28d6bf7c1e4e84f6b5f67c90d47ddd64`.
- Runtime `GetBuildInfo`: version `1.60.1`, build `70862`, interface `16001`, build date `Nov 6 2026`.
- Probe loaded at 20:53:08, started at 20:53:23, attempted marking at 20:53:26 on 2026-11-09 (local recorded time).
- The pre-call player combat checks passed. An earlier dead-unit mouseover was skipped.
- Probe recorded `addon_action_forbidden` for `MagicMarkerForeverProbe`, action `UNKNOWN()`.
- Probe recorded `mark-attempted-unobserved` for icon 8; confirmed assignments remained empty. A pending reservation is not a successful mark.
- BugGrabber independently captured `ADDON_ACTION_FORBIDDEN` with stack through `Probe.lua:14` (`pcall` wrapper), `Probe.lua:275` (the direct `SetRaidTarget` invocation), and `Probe.lua:394` (the event handler).
- Tester confirmed: **No icons appeared.**

This is a sanitized summary. Account paths, unit GUIDs, unrelated addon errors and raw SavedVariables are not published.

## Scope of validation

| Check | Result |
| --- | --- |
| Probe loads and records runtime build | PASS |
| Out-of-combat start command accepted | PASS |
| Exact ALT + mouseover direct marking | FAIL — protected call forbidden |
| Icons visible to tester | FAIL — none appeared |
| Complete manual QA matrix / group-role coverage | NOT RUN |
| Lua syntax, offline state tests, ZIP build | PASS; not runtime permission evidence |

The probe disarms on its forbidden-action event and starts disabled after reload. There is no reason to repeatedly run this same failing path without a changed hypothesis. A per-mob click or keypress is a product-scope change, not acceptance of the requested workflow.
