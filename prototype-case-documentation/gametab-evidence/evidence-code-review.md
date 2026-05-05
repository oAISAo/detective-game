# Evidence Tab — Critical Code Review and Improvement Ideas

Files reviewed:
- `scripts/ui/screens/evidence_archive.gd`
- `scripts/ui/components/evidence_detail_panel.gd`
- `scripts/ui/components/evidence_pinned_bar.gd`
- `scripts/ui/components/evidence_weight_section.gd`
- `scripts/ui/components/evidence_lab_section.gd`
- `scripts/ui/components/evidence_notes_section.gd`
- `scripts/ui/components/evidence_polaroid.gd`
- `scripts/ui/components/evidence_statements_panel.gd`
- `scripts/ui/components/statement_item.gd`
- `scripts/managers/evidence_manager.gd`
- `scripts/data/evidence_data.gd`
- `tests/unit/test_evidence_archive_ui.gd`

---

## 🔵 EvidenceManager-Specific Issues

### 22. `is_contradicted()` relies on implicit enum integer ordering
```gdscript
if stmt.importance <= Enums.ImportanceLevel.SUPPORTING:
```
This works correctly today because CRITICAL=0 and SUPPORTING=1. But the comment above says "OPTIONAL (2) and KEY (3) are not". If the enum is ever reordered, the logic breaks silently.

**Fix:** Use explicit membership check:
```gdscript
if stmt.importance in [Enums.ImportanceLevel.CRITICAL, Enums.ImportanceLevel.SUPPORTING]:
```

### 23. `compare_evidence()` returns `null` for two different cases
The function returns `null` when no matching insight exists *and* when the insight was already discovered. The caller in `evidence_archive.gd` treats both the same (shows "No new insights"), which is correct for now but limits future improvements (e.g. showing "You already discovered this insight").

---

## 🔵 Test Coverage Gaps

### 24. UI test doesn't cover behavioral state
`test_evidence_archive_ui.gd` tests layout structure but not behavioral state:
- No test for `_comparing` flag not being reset when switching evidence
- No test for card badge refresh after pin/unpin
- No test for filter + search interaction
- No test for notes persistence across evidence switches
- No test for the pinned bar reconstruction

---

## Summary

| Severity | Count | Items |
|---|---|---|
| 🔵 Manager Issues | 2 | #22 #23 |
| 🔵 Test Gaps | 1 | #24 |

**Resolved and removed:**
- #7 Fragile `move_child` → anchor nodes (`%WeightSectionAnchor`, `%LabSectionAnchor`, `%NotesSectionAnchor`)
- #8 Hardcoded node paths → all scroll bars use unique names with `%`
- #9 Weak type annotations → all dynamic section vars properly typed in `EvidenceDetailPanel`
- #10 Multi-statement lambdas → all lambdas expanded to multi-line blocks
- #11 Missing `KEY` case in `get_importance_label` → added to `UIHelper`
- #12 Emoji in button labels → replaced with plain text / unicode
- #13 Full panel rebuild on lab submit → `_on_lab_submitted` now does targeted refresh
- #14 Font null-check in `EvidencePolaroid.setup()` → guarded with `if font else 20.0`
- #15 Manual `queue_free()` loop in `_update_badges()` → replaced with `UIHelper.clear_children()`
- #16 No selected state on polaroid card → `set_selected()` + AMBER border; `evidence_archive.gd` tracks `_selected_card`
- #17 Font loaded per `StatementItem` → `EvidenceStatementsPanel` receives pre-loaded font, passes to each item
- #18 `HANDWRITING_FONT_PATH` in three places → centralized in `UIFonts.HANDWRITING_FONT_PATH`
- #19 `setup()` was ~106 lines → split into `_build_header()`, `_build_verdict_popup()`, `_build_quote()`, `_build_note_body()`
- #20 Verdict popup magic IDs → `enum _VerdictId` + `const _VERDICT_STRINGS` array
- #21 `is_connected` guard in `EvidenceStatementsPanel._exit_tree` → guard was already present
