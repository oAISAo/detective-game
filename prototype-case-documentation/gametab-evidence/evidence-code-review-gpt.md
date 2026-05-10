# Evidence Tab — Critical Code Review and Improvement Ideas (screen and all used components)

## Scope

Reviewed surface:

- `scenes/ui/evidence_archive.tscn`
- `scripts/ui/screens/evidence_archive.gd`
- `scripts/ui/components/evidence_detail_panel.gd`
- `scripts/ui/components/evidence_polaroid.gd`
- `scripts/ui/components/evidence_pinned_bar.gd`
- `scripts/ui/components/evidence_lab_section.gd`
- `scripts/ui/components/evidence_value_section.gd`
- `scripts/ui/components/evidence_statements_panel.gd`
- `scripts/ui/components/evidence_notes_section.gd`
- `scripts/ui/components/statement_item.gd`
- `scripts/managers/evidence_manager.gd`
- `scripts/managers/lab_manager.gd`
- `scripts/managers/board_manager.gd`
- Existing tests that currently cover this surface

This review focuses on behavior defects, UI/runtime mismatches, brittle architecture, and missing regression coverage that materially affect the Evidence Archive experience.

## Critical Findings

### 1. Live statement verdict changes do not refresh the Evidentiary Value warning

Owner:
`scripts/ui/components/evidence_value_section.gd:9-31`
`scripts/ui/components/evidence_statements_panel.gd:16-21, 57-61`
`scripts/managers/evidence_manager.gd:261-275, 303-313`

Problem:
The contradiction warning in `EvidenceValueSection.populate()` is computed from `EvidenceManager.is_contradicted(ev.id)`, but the value section is only repopulated when `show_evidence()` runs. The only UI subscriber to `EvidenceManager.statement_verdict_changed` is `EvidenceStatementsPanel`, and that callback only updates the matching `StatementItem` verdict pill.

Impact:
The player can mark a statement as `CONTRADICTION` and see the verdict pill update immediately, while the same screen still shows the evidence as uncontested until the detail panel is reopened. That breaks the core evidence-analysis loop in the most important section of the tab.

Fix direction:
Have `EvidenceDetailPanel` subscribe to `statement_verdict_changed` for the currently selected evidence and repopulate the value section when the active evidence changes verdict state.

Missing regression:
There is no UI test that opens evidence, changes a verdict live, and asserts that the contested warning appears or disappears without reopening the panel.

### 2. Submitting evidence to the lab does not refresh the archive card state immediately

Owner:
`scripts/ui/components/evidence_detail_panel.gd:96, 529-535`
`scripts/ui/screens/evidence_archive.gd:50-62, 144-145, 195`
`scripts/ui/components/evidence_polaroid.gd:86-107`

Problem:
The detail panel handles `_on_lab_submitted()` locally by repopulating only the detail-side lab section and metadata. The archive screen does not listen to `LabManager.lab_submitted`, `LabManager.lab_completed`, or any detail-panel event that would refresh the selected `EvidencePolaroid` badges.

Impact:
After the player submits evidence to the lab, the detail panel changes but the grid card does not gain the `LAB` badge until some unrelated refresh happens. The archive therefore shows stale state at exactly the moment the player expects confirmation.

Fix direction:
Propagate lab submission/completion back to `EvidenceArchive` and refresh the affected card, or centralize the refresh through a manager signal that the archive owns.

Missing regression:
Current tests assert lab section text and manager state, but there is no screen-level test that verifies a card badge updates immediately after clicking submit.

### 3. Lab save/load restores request dictionaries but does not rehydrate evidence UI state

Owner:
`scripts/managers/lab_manager.gd:228-231, 302-315`
`scripts/ui/components/evidence_polaroid.gd:98`
`scripts/ui/components/evidence_detail_panel.gd:198-204`

Problem:
`LabManager.deserialize()` restores `_requests` and `_next_id`, but it does not recompute or reapply `EvidenceData.lab_status` for the affected evidence resources. The archive card badge and the detail metadata grid both still depend on `ev.lab_status`, while the lab section depends on `LabManager.is_evidence_submitted()`.

Impact:
After loading a saved game with pending or completed lab work, the forensic section can correctly say the request is pending while the card badge and metadata grid still report the default evidence status. The screen can contradict itself after every load.

Fix direction:
Rebuild evidence `lab_status` from restored requests during `LabManager.deserialize()`, or stop reading mutable UI state from `EvidenceData` and derive it from `LabManager` consistently.

Missing regression:
`tests/unit/test_lab_manager.gd` checks request counts after serialize/deserialize, but nothing asserts archive-visible `lab_status`, metadata, or badge behavior after load.

## High Findings

### 4. Deep-linked navigation opens the detail panel without selecting the matching card in the archive

Owner:
`scripts/ui/screens/evidence_archive.gd:43-44, 65-66, 226-232`
Callers: `scripts/ui/screens/location_investigation.gd:398`, `scripts/ui/components/notification_toast.gd:109`

Problem:
When `ScreenManager.navigation_data` contains `evidence_id`, `_ready()` calls `detail_panel.show_evidence(...)` directly instead of going through `_on_evidence_requested(...)`, which is the only path that also updates `_selected_card` and the left-grid highlight.

Impact:
Using a `View` shortcut from a discovery notification or location investigation can land the player on the right evidence detail while the left archive has no visible selected card. That loses context and makes the browse/detail relationship feel broken.

Fix direction:
Route startup deep-links through a single select-and-show helper that updates both grid state and detail state.

Missing regression:
There is no navigation test that opens `evidence_archive` with `navigation_data.evidence_id` and asserts both the detail panel and the corresponding card selection state.

### 5. The grid card and the detail panel use different image fallback rules

Owner:
`scripts/ui/components/evidence_polaroid.gd:44-52`
`scripts/ui/components/evidence_detail_panel.gd:142-144`

Problem:
`EvidencePolaroid` only shows an image when `ev.image` is non-empty and exists exactly at that path. `EvidenceDetailPanel`, by contrast, falls back to `res://assets/evidence_images/<id>.png` and resolves through `AssetFallback.get_texture(...)`.

Impact:
The same evidence can appear as a blank placeholder in the archive grid and as a resolved image in the detail panel. That inconsistency is especially likely to surface when authored data relies on fallback conventions or generated placeholder assets.

Fix direction:
Centralize evidence image resolution in one helper and use the same logic in both the card and the detail panel.

Missing regression:
There is no test that covers the empty-image-path fallback path across both surfaces.

### 6. Multi-template lab evidence collapses into a single pending state and hides remaining valid analyses

Owner:
`scripts/ui/components/evidence_lab_section.gd:30-39, 98-105, 140-147`
`scripts/managers/lab_manager.gd:123-126, 228-231`

Problem:
`EvidenceLabSection.populate()` computes all completed and available requests, but if `LabManager.is_evidence_submitted(_evidence_id)` is true it shows a generic pending state and returns before rendering any remaining `available_requests`. The manager enforces the same coarse rule by rejecting any further request once one pending request exists for that input evidence.

Impact:
Any evidence item with multiple authored lab templates becomes partially unusable. After submitting one analysis, the archive can no longer expose or submit the others even though the case data still defines them. That conflicts with the concept's per-analysis UI contract and makes multi-template evidence brittle.

Fix direction:
Track submission state per template or per output evidence, then render completed, pending, and available rows independently for each authored lab request.

Missing regression:
`tests/unit/test_lab_manager.gd` validates template selection and multi-template rejection in the manager, but there is no archive UI test that proves multiple authored analyses remain visible and usable.

### 7. Wrapping lineage links accumulate permanent resize listeners every time the row is rebuilt

Owner:
`scripts/ui/components/evidence_detail_panel.gd:263-281`

Problem:
Every call to `_make_wrapping_link_button()` connects `_info_grid.resized` and `_main_scroll.resized` to `_refresh_wrapping_link_text.bind(link_button, ...)`. Those connections are owned by the long-lived detail panel, not by the transient link button, so clearing the info grid does not disconnect them.

Impact:
Repeatedly opening evidence with lineage rows or rebuilding the panel leaves dead bound call sites behind. Over time this creates avoidable resize work, hidden lifetime complexity, and a hard-to-debug source of UI drift if the wrapping logic ever gains side effects.

Fix direction:
Own these connections explicitly and disconnect them on rebuild, or move the wrapping behavior into a dedicated control that manages its own subscriptions.

Missing regression:
The current tests verify wrapping behavior, but they do not exercise repeated rebuilds or detect accumulating signal connections.

### 8. Related-person entries are rendered as inert labels instead of navigation affordances

Owner:
`scripts/ui/components/evidence_detail_panel.gd:389-404`

Problem:
The detail panel renders related persons as bullet labels only. There is no signal, button, or navigation path for the concept's intended “click person to jump to profile” workflow.

Impact:
The archive exposes cross-case context but stops short of letting the player act on it. That forces manual tab-switch hunting for suspect profiles and weakens one of the intended connections between Evidence and Suspects.

Fix direction:
Replace the labels with small row buttons or dedicated person chips that emit a typed selection signal upward.

Missing regression:
There is no test coverage for related-person navigation because the feature is not wired at all.

## Medium Findings

### 9. The pinned bar has no overflow strategy and will degrade quickly with long evidence names

Owner:
`scripts/ui/components/evidence_pinned_bar.gd:39-59`

Problem:
Pinned evidence is rendered as a plain row of flat buttons using the full evidence name, with no clipping, max width, scrolling, or overflow summary.

Impact:
Several real evidence names in the Riverside case are long enough to dominate the entire row. On narrower widths, a few pinned items will produce an unbalanced toolbar and poor scanability.

Fix direction:
Add truncation/ellipsis, width constraints, or an overflow pattern such as a secondary popup list.

Missing regression:
There are currently no tests at all for `EvidencePinnedBar` behavior or layout.

### 10. The detail panel clear path hides the surface but leaves dynamic child state mounted underneath it

Owner:
`scripts/ui/components/evidence_detail_panel.gd:149-163`

Problem:
`clear()` hides the detail panel and resets a few top-level fields, but it does not clear the info grid, related-person list, legal-category list, comparison list, lab section, value section, statements panel, or notes section.

Impact:
The panel violates the project’s own placeholder/content reset pattern. Hidden stale state is easy to overlook in manual testing and increases the chance that future partial refresh changes accidentally expose outdated data.

Fix direction:
Clear owned dynamic sections when returning to placeholder mode, either directly in `clear()` or through child `clear()` APIs.

Missing regression:
Tests cover layout and populated content, but not repeated clear/show cycles or state-loaded resets.

### 11. The pending lab state is too generic for the authored workflow

Owner:
`scripts/ui/components/evidence_lab_section.gd:98-102`

Problem:
Pending lab work is reduced to a single generic label: `Submitted to Lab — Results pending.` The code does not show the expected completion day or the pending analysis type even though the authored requests and concept support both.

Impact:
The archive loses useful player guidance exactly when the evidence has moved into an asynchronous workflow. The player has less information than the model already knows.

Fix direction:
Include per-request context in the pending rows, at minimum the analysis type and expected completion day.

Missing regression:
There is no UI test that checks pending-state copy beyond the existence of the section.

### 12. Statement presentation remains under-specified and unprotected despite being a core workflow

Owner:
`scripts/ui/components/statement_item.gd:24-172`

Problem:
`StatementItem` owns verdict selection, expand/collapse state, and note editing, but the component has no direct tests. The current implementation is also visually thinner than the concept: it omits role/avatar treatment and relies on a very small set of plain controls for the most important evidence-analysis surface.

Impact:
The archive’s central contradiction workflow depends on an untested component whose UX affordances are still sparse. That is a bad place to accept regressions, especially because verdicts and notes are persisted player decisions.

Fix direction:
Add dedicated tests for `StatementItem` and `EvidenceStatementsPanel`, then tighten the row contract around verdict popup behavior, note persistence, and visibility state.

Missing regression:
No dedicated tests exist for `StatementItem`, `EvidenceStatementsPanel`, or the live interaction between them and the detail panel.

## Coverage Gaps

These are not secondary details. Several important behaviors are simply unprotected today.

### 13. The test suite is layout-heavy and interaction-light for the Evidence Archive screen

Evidence:
`tests/unit/test_evidence_archive_ui.gd` validates layout order, text placement, wrapping, and static section structure.

Gap:
There are no screen-level tests for:

- filter dropdown interaction
- search box interaction
- empty-state rendering behavior
- deep-link selection via `navigation_data.evidence_id`
- live card badge refresh after pin/unpin/lab submission
- live contradiction warning refresh after verdict changes
- compare-panel open/close state across evidence switches

Impact:
The current tests protect the shell’s shape more than its behavior. The highest-risk regressions in this screen are therefore still easy to ship.

### 14. Several owned components have no direct test coverage at all

Uncovered or effectively uncovered components:

- `scripts/ui/components/evidence_pinned_bar.gd`
- `scripts/ui/components/evidence_statements_panel.gd`
- `scripts/ui/components/evidence_notes_section.gd`
- `scripts/ui/components/statement_item.gd`

Impact:
The Evidence Archive coordinator depends on multiple programmatically-built child controls whose behavior can change without any targeted test failing.

### 15. Save/load tests stop at manager internals instead of validating visible archive behavior

Evidence:
`tests/unit/test_lab_manager.gd:467-491`
`tests/unit/test_evidence_manager.gd:894-996`
`tests/unit/test_board_manager.gd:449-459`

Gap:
The suite proves that dictionaries and counters survive serialization, but it does not validate the user-visible Evidence Archive outcomes after load:

- pending/completed lab badges and metadata
- send-to-board button label state
- pinned bar rebuild
- evidence notes and statement rows after state restoration

Impact:
This is exactly where hidden integration drift slips through: the data is restored, but the screen can still lie.

## Areas Reviewed With No Standalone Defect Found

- `EvidencePolaroid` mouse-filter routing and click ownership are sound and match the archive card interaction model.
- `EvidenceManager` reviewed-state, player-notes, and sent-to-board state each have basic manager-level serialization coverage.
- `BoardManager.send_to_board()` inbox placement logic is internally consistent and already covered by direct unit tests. The weak point is the Evidence Archive integration around it, not the placement math itself.

## Recommended Priority Order

1. Fix live contradiction reactivity in the detail panel.
2. Fix lab submission/load-state synchronization so the archive stops lying about lab work.
3. Unify deep-link selection and image resolution paths.
4. Redesign multi-template lab handling before authoring more evidence that depends on it.
5. Add missing interaction and save/load regression tests for the uncovered components.

