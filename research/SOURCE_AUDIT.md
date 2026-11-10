# MagicMarker Forever source audit

Audit date: 2026-11-09

## Pinned source examined

- Official upstream: <https://github.com/Addons-By-Neotron/MagicMarker>
- Clone used for inspection: `/home/tstolswo/projects/magicmarker-forever/upstream/` (ignored from the public repository)
- Branch at inspection: `master`
- Immutable commit: `510b62fb0c11bebeb2ab738830b8624e46e9d027`
- Commit timestamp: `2026-01-18T17:19:38+01:00` (`Add README.md`)
- Clone status at inspection: clean; `master` matched `origin/master`.

Pin any reuse to this commit (or another reviewed SHA), not a moving branch or release label. The source was inspected locally; no upstream files were edited.

## License evidence and remaining ambiguity

The checked out [`LICENSE.txt`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/LICENSE.txt) contains the GNU General Public License, version 3. Core files including [`MagicMarker.lua`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/MagicMarker.lua), [`Config.lua`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/Config.lua), [`MarkTemplates.lua`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/MarkTemplates.lua), and [`Locales/Locale-enUS.lua`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/Locales/Locale-enUS.lua) explicitly state GPL version 3 “or (at your option) any later version.” This is direct source evidence for treating reused core code as GPL-3.0-or-later and retaining the notices and license.

The CurseForge page separately identifies the project as BSD License and gives its project ID as 14363: <https://www.curseforge.com/wow/addons/magic-marker>. That conflicts with the repository's license file and source headers. The public records reviewed here do not explain whether CurseForge's field is stale, erroneous, or reflects a separate grant. This audit therefore does not treat the field as permission to relicense GPL-marked code or reach a legal conclusion about rights in every file. Preserve GPL notices for copied/modified core code; get author clarification before relying on BSD or assigning a different license to reused code.

The README names David Hedbor as author and gives `neotron@gmail.com`; source TOC names NeoTron. A public fork should identify itself as an independent MagicMarker Forever fork, credit David Hedbor/NeoTron, link this upstream and the pinned commit, retain applicable copyright/license notices, and mark its modifications and project identity clearly. Keep the full GPL license alongside any redistributed GPL-covered source/package.

### Recommended repository license statement

For the current feasibility repository, using `GPL-3.0-or-later` as the repository license is a clear compatible choice if the project owner intends original probe code to be reusable under the same terms and expects later integration with this GPL-3.0-or-later source. Copy the GPL text as `LICENSE.txt` and identify the repository's own work as GPL-3.0-or-later in README/metadata. This is a license choice for the project owner's original contributions, not a copyright assignment and not a claim that upstream authors own the probe. Do not invent a copyright holder or year; add contributor-specific copyright notices only when the relevant contributor/owner is known and wishes to assert them. Keep upstream-origin code and its existing notices distinguishable in history/files and acknowledge its source. A later derivative carrying copied upstream code should retain those notices and GPL licensing. If the project does not want to license original probe code under GPL, keep it clearly separate and resolve licensing before combining it with the derivative; do not use CurseForge's BSD metadata as the basis for that choice.

## Marking seams and reuse size

The behavior is coupled to a substantial addon architecture:

- [`MagicMarker.toc`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/MagicMarker.toc) loads `embeds.xml`, locale files, `MagicMarker.lua`, `Config.lua`, `MMRaidIcon.lua`, `MMCCPrio.lua`, `MarkTemplates.lua`, and `MM_LDB.lua`. It declares `MagicMarkerDB` and `MagicMarkerConfigDB` as SavedVariables.
- [`embeds.xml`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/embeds.xml) includes Ace3, LibStub, LibBabble-Zone, LibLogger, MagicComm, LibDropdown, LibDataBroker, and LibQTip.
- [`MagicMarker.lua`](https://github.com/Addons-By-Neotron/MagicMarker/blob/510b62fb0c11bebeb2ab738830b8624e46e9d027/MagicMarker.lua) initializes an AceAddon, uses those libraries, stores priority/assignment state, and implements `SmartMark_MarkUnit`. That method checks eligibility, the modifier, existing raid icons, selected mark assignments, and the combat remark option before calling `SetRaidTarget`.
- `EnableEvents` registers `UPDATE_MOUSEOVER_UNIT` to call `SmartMark_MarkUnit` for `mouseover`; `Bindings.xml` exposes `MAGICMARKRAID`, which invokes `MarkRaidTargets`; `MarkRaidTargets` iterates group members and calls the same marking method for each member's target.
- `SetRaidTarget` wraps the WoW API call in the method near line 1396 of `MagicMarker.lua`. The helper is a thin seam, but the full marking decision is not: it depends on module state and substantial methods elsewhere in the file.

For the stated M0 scope (modifier-based mouseover marking plus a mouseover sweep before combat; no group-target iteration required; combat remark deferred), the smallest feasible reuse is a fresh minimal addon implementation that reproduces the desired behavior using Blizzard APIs and its own small state, informed by the documented behavior and inspection of these seams. Avoid importing the large priority/configuration/network-sync/UI stack, all locales, or all bundled externals. If code from `SmartMark_MarkUnit` or other upstream implementations is copied/adapted, treat that code as GPL-3.0-or-later and keep its attribution/license trail; do not call it a clean-room implementation. A wholly new implementation still needs independent review of any copied non-code assets or text.

This is a source-level seam assessment only. It does not establish which marking calls are permitted in a particular WoW client state or provide runtime testing results.

## Dependency license inventory

M0 shipped dependency inventory: none third-party. The M0 probe is original code and does not import upstream libraries. The external libraries below are dependencies declared by upstream `.pkgmeta`; the clone has no `Libs/` directory, so their actual contents and license notices were not vendored or verified in this audit. Their license audits are pending only if a later implementation imports any of them. Do not ship a dependency merely because it appears in `.pkgmeta`; first establish that it is needed, pin an upstream revision, and inspect that revision's license and notices.

| Dependency declared in `.pkgmeta` | Pinned license status for this audit |
| --- | --- |
| AceAddon-3.0, AceComm-3.0, AceConfig-3.0, AceConsole-3.0, AceDB-3.0, AceDBOptions-3.0, AceEvent-3.0, AceGUI-3.0, AceLocale-3.0, AceSerializer-3.0, AceTimer-3.0 | Pending. `.pkgmeta` points at Ace3 trunk without an immutable revision; individual dependency files were not fetched. |
| CallbackHandler-1.0 | Pending; external trunk reference, no pinned revision/content inspected. |
| LibBabble-Zone-3.0 | Pending; external trunk reference, no pinned revision/content inspected. |
| LibStub | Pending; external trunk reference, no pinned revision/content inspected. |
| LibDataBroker-1.1 | Pending; external Git repository reference, no pinned revision/content inspected. |
| LibQTip-1.0 | Pending; external repository reference, no pinned revision/content inspected. |
| MagicComm | Pending; external Git repository reference, no pinned revision/content inspected. |
| LibLogger | Pending; external Git repository reference, no pinned revision/content inspected. |
| LibDropdown-1.0 | Pending; external Git repository reference, no pinned revision/content inspected. |

No dependency license is assumed from the main addon's GPL header or CurseForge metadata. The preferred narrow implementation should have no third-party libraries, reducing both packaging size and unresolved dependency-license work.

## Public repository and package identity

The upstream TOC declares `X-Curse-Project-ID: 14363`, `X-WoWI-ID: 9110`, and `X-Wago-ID: ZQ6a2AKW`, along with `SavedVariables: MagicMarkerDB, MagicMarkerConfigDB`. A separate Forever project should use its own directory/TOC title and platform project IDs; do not reuse upstream marketplace IDs. Give the new addon unique SavedVariables (for example `MagicMarkerForeverDB`) so the old and new addons cannot collide. Any intentional migration should be explicit, one-way or idempotent, and tested before release.

Package the exact reviewed source and any required pinned dependencies in the release artifact, include license/attribution notices, and check the package's root folder and TOC load list. A source checkout alone is not the upstream installable package: `.pkgmeta` resolves external libraries during packaging. For a new dependency-free implementation, remove that packaging machinery rather than inheriting unrelated externals. Keep project metadata and release workflow distinct from project 14363.

## Files checked

Pinned source links in this audit use the reviewed SHA above. Files checked locally: `LICENSE.txt`, README, `.pkgmeta`, `MagicMarker.toc`, `embeds.xml`, `Bindings.xml`, `MagicMarker.lua`, `MarkTemplates.lua`, `Config.lua`, locale headers, Git status, branch, and commit metadata. Dependency upstream source/license texts were not cloned or examined; their license status remains pending only for possible future use as listed above.
