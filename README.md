# MagicMarker Forever

A project to bring MagicMarker's **hold a modifier and sweep the mouse across a hostile pack** interaction to World of Warcraft: Forever, before combat.

**Status: M0 blocked by the first live test. Not a working gameplay addon.** On Forever build 70862 the direct mouseover `SetRaidTarget` call was forbidden, and the tester saw no icons. See [live evidence](qa/LIVE_RESULT_2026-11-09.md). The exact precombat interaction must pass an in-game test before implementation proceeds. A separate click per mob does not meet the project requirement.

## Scope

The intended MVP provides configurable modifier and icon order, stable assignments, preservation of existing marks, explicit reset, saved settings, and suspension of automatic marking during combat. Combat remarking, CC learning, NPC databases and multiplayer synchronization are deferred.

## Working tree

- `probe/MagicMarkerForeverProbe/`: standalone, opt-in diagnostic addon for live-client testing.
- `qa/`: test procedures and recorded verification evidence.
- `research/`: upstream provenance and dependency/license audit.
- `tools/`: local checks and reproducible probe packaging.

The upstream checkout is kept locally in ignored `upstream/`; its immutable revision is documented in the source audit. This repository currently contains the feasibility work, not an imported or completed MagicMarker fork.

## Delivery

1. Verify modifier-only sweep on an identified live Forever build and review source licensing.
2. Implement the minimal workflow.
3. Validate in game and package an alpha.
4. Publish a CurseForge beta with source and issue links.
5. Resolve beta blockers and release a stable version.

Offline checks cannot establish WoW API permission, secure execution or actual raid-icon behavior. In-game results must record the client build and exact test steps.

## Build the probe

Run `python3 tools/package_probe.py` with Python 3.9 or newer. It validates the TOC file references and produces `dist/MagicMarkerForeverProbe-m0.zip` with deterministic archive timestamps. The source folder inside the ZIP is installed directly under the Forever client's `Interface/AddOns` directory. See the probe README for opt-in commands and diagnostics.

The local upstream baseline is commit [`510b62fb0c11bebeb2ab738830b8624e46e9d027`](https://github.com/Addons-By-Neotron/MagicMarker/tree/510b62fb0c11bebeb2ab738830b8624e46e9d027). The probe ships no upstream library dependencies.

## Attribution

Original project code is licensed under GPL-3.0-or-later; see `LICENSE.txt`. Upstream and dependency notices remain applicable to their respective material.

Inspired by and planned as an independent continuation of [MagicMarker](https://github.com/Addons-By-Neotron/MagicMarker), by David Hedbor / NeoTron. No upstream or Blizzard endorsement is implied. Upstream source headers and licensing are reviewed in `research/SOURCE_AUDIT.md`; preserve applicable notices for any code reused. No upstream marketplace IDs are inherited.

Publication on CurseForge is pending a working-client test, package review and publisher account access. No supported release is currently advertised.
