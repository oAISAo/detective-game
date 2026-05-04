# Evidence Tab — Critical Code Review and Improvement Ideas

Files reviewed:
- `scripts/ui/screens/evidence_archive.gd` (~800 lines)
- `scripts/ui/components/evidence_polaroid.gd`
- `scripts/ui/components/evidence_statements_panel.gd`
- `scripts/ui/components/statement_item.gd`
- `scripts/managers/evidence_manager.gd`
- `scripts/data/evidence_data.gd`
- `tests/unit/test_evidence_archive_ui.gd`

---

## 🟠 Architecture & Design Issues

### 6. God class — 800-line screen script doing too much
`evidence_archive.gd` currently handles: filtering, searching, detail panel population, lab UI construction, weight bar construction, notes UI construction, comparison UI construction, pinning UI, badge label helpers, and enum-to-string formatters. This violates both the single-responsibility principle and the project's own ≤300-line class guideline.

**Recommended split:**
| New class | Responsibility |
|---|---|
| `EvidenceDetailPanel` | Owns the right panel — title, badges, image, description, info grid |
| `EvidenceWeightSection` | Evidentiary weight bar + prose label |
| `EvidenceLabSection` | Forensic analysis block + submit button |
| `EvidenceNotesSection` | Player notes TextEdit |
| `EvidencePinnedBar` | Pinned bar at the top |
| `evidence_archive.gd` (trimmed) | Grid, filtering, search, card selection |

---

### 7. Fragile dynamic node insertion via `move_child`
Both `_populate_weight_section()` and `_populate_lab_section()` use:
```gdscript
_detail_column1_content.add_child(_weight_section)
_detail_column1_content.move_child(_weight_section, description_label.get_index() + 1)
```
This relies on knowing the live index of `description_label` in the column. If another node is inserted in the scene file between the description and the weight section, the index shifts and ordering breaks silently. Same problem exists in `_populate_notes_section()` where it navigates via `get_parent()` chaining:
```gdscript
var statements_section: VBoxContainer = related_statements_list.get_parent() as VBoxContainer
var relationships_content: VBoxContainer = statements_section.get_parent() as VBoxContainer
relationships_content.add_child(_notes_section)
relationships_content.move_child(_notes_section, statements_section.get_index() + 1)
```
Three levels of `.get_parent()` navigation + `get_index()` is very brittle. Any scene refactor silently breaks the insertion logic.

**Fix:** Use named placeholder nodes in the scene (e.g., `%WeightSectionAnchor`, `%NotesSectionAnchor`) and simply `add_child` to those anchors instead of splicing into a live index.

---

### 8. Hardcoded full node paths in `_ready()`
Lines 60–63 use raw path strings:
```gdscript
$MarginContainer/VBoxContainer/MainColumns/LeftPanel/LeftVBox/EvidenceContent/CardScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
$MarginContainer/VBoxContainer/MainColumns/RightPanel/RightVBox/DetailPanel/DetailColumns/MainScroll.get_v_scroll_bar().modulate = Color.TRANSPARENT
```
These will crash silently if the scene hierarchy changes. The other scroll bars in the same block already use `@onready` + unique names correctly.

**Fix:** Give `CardScroll`, `MainScroll`, and `RelationshipsScroll` unique names in the scene and access them with `%`.

---

### 9. Weak type annotations on dynamic sections
```gdscript
var _lab_section: VBoxContainer = null
var _weight_section: Node = null   # ← should be VBoxContainer
var _notes_section: Node = null    # ← should be VBoxContainer
var _statements_panel: Node = null # ← should be EvidenceStatementsPanel
```
Three of the four dynamic section variables are typed as `Node`, losing compile-time type checking. GDScript's static analysis can catch null-access errors and wrong method calls when types are declared correctly.

---

## 🟡 Code Quality Issues

### 10. Multi-statement lambdas on single lines (readability)
```gdscript
_on_evidence_pinned_cb = func(id: String) -> void: _populate_pinned_bar(); _update_pin_button(); _refresh_card_badges(id)
```
Three side effects squeezed onto one line. Impossible to set a breakpoint on any individual call, and easy to miss one of them during a code review. The `_on_evidence_sent_to_board_cb` lambda correctly spans multiple lines.

**Fix:** Expand all multi-statement lambdas to multi-line blocks.

---

### 11. `_get_importance_label` missing `KEY` case
`_get_importance_badge_color()` explicitly handles `Enums.ImportanceLevel.KEY` with `UIColors.AMBER`. But `_get_importance_label()` falls through to `"Unknown"` for `KEY`. The importance metadata grid row and header badge will show "Unknown" for any KEY-importance evidence.

---

### 12. Emoji used in button labels (inconsistency)
```gdscript
pin_button.text = "📌 Unpin"
send_to_board_button.text = "📋 Send to Board"
```
The evidence TODO list already tracks replacing these with Material Icons. More critically, emoji rendering is platform-dependent and emoji don't respect the game's theme/color. The search icon is already correctly implemented using the Material Symbols font — pin and board buttons should follow the same pattern.

---

### 13. `_on_submit_to_lab` calls `_show_evidence_detail` on success
```gdscript
func _on_submit_to_lab() -> void:
    ...
    UIHelper.confirmation_flash("Submitted to Lab", self)
    _show_evidence_detail(_selected_evidence_id)
```
`_show_evidence_detail` rebuilds the entire right panel from scratch (clears/re-creates info grid, badges, weight bar, lab section, notes, etc.) just to refresh the lab button state. This is expensive and also loses the scroll position.

**Fix:** Add a targeted `_refresh_lab_section()` method that only rebuilds the lab block, similar to how `_refresh_card_badges()` does targeted updates on the left panel.

---

## 🔵 EvidencePolaroid-Specific Issues

### 14. `setup()` reads theme font without null-checking
```gdscript
var line_height: float = _name_label.get_theme_font("font").get_height(UIFonts.SIZE_TITLE)
```
`get_theme_font("font")` can return null if the label has no font set in the current theme. Calling `.get_height()` on null will crash.

**Fix:**
```gdscript
var font: Font = _name_label.get_theme_font("font")
var line_height: float = font.get_height(UIFonts.SIZE_TITLE) if font else 20.0
```

### 15. `_update_badges()` uses individual `queue_free()` calls instead of `UIHelper.clear_children()`
The rest of the codebase uses `UIHelper.clear_children()` for consistency. `_update_badges()` iterates and queues individually. This is fine functionally but inconsistent with the established pattern.

### 16. No visual "selected" state on the polaroid card
The TODO file already tracks this, but it's worth noting in the review. Currently there is no way to tell which card is selected without looking at the right panel. The `_on_card_pressed` callback in `evidence_archive.gd` should set a `selected` property on the card and clear it from the previously selected card.

---

## 🔵 StatementItem-Specific Issues

### 17. Handwriting font loaded from disk on every instantiation
```gdscript
# statement_item.gd
if ResourceLoader.exists(HANDWRITING_FONT_PATH):
    var hw_font: Font = ResourceLoader.load(HANDWRITING_FONT_PATH)
```
This path is also loaded in `evidence_archive.gd` and cached in `_handwriting_font`. When multiple statements are displayed, each `StatementItem` makes a separate `ResourceLoader.load()` call.

**Fix:** Have `EvidenceStatementsPanel` receive the pre-loaded font and pass it into each `StatementItem.setup()`, matching the pattern already used in `EvidencePolaroid.setup(evidence, handwriting_font)`.

### 18. `HANDWRITING_FONT_PATH` defined in two places
`StatementItem` and `evidence_archive.gd` both define the same constant pointing to the same font path. DRY violation. This should live in a shared constants file (e.g. `UIFonts` or a new `UIConstants`).

### 19. `setup()` is ~80 lines — over the 50-line hard limit
The `setup()` function builds the entire widget: header row, toggle, name, day, spacer, verdict button, popup, quote, collapsible body, note edit, separator, and initial state. Split into private builder helpers.

### 20. Verdict popup uses magic integer IDs
```gdscript
_verdict_popup.add_item("Contradiction", 0)
...
_verdict_popup.id_pressed.connect(_on_verdict_popup_id_pressed)
...
func _on_verdict_popup_id_pressed(id: int) -> void:
    match id:
        0: EvidenceManager.set_statement_verdict(...)
```
If the popup items are reordered, the `match` IDs must be manually updated. Use named constants or an inline enum.

---

## 🔵 EvidenceStatementsPanel-Specific Issues

### 21. Missing `is_connected` guard in `_exit_tree`
```gdscript
func _exit_tree() -> void:
    if EvidenceManager.statement_verdict_changed.is_connected(_on_verdict_changed):
        EvidenceManager.statement_verdict_changed.disconnect(_on_verdict_changed)
```
This is actually guarded — good. But see issue #3: the guard pattern is inconsistent across the codebase.

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

### 24. UI test doesn't cover comparison panel state
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
| 🔴 Bug | 5 | #1 #2 #3 #4 #5 |
| 🟠 Architecture | 4 | #6 #7 #8 #9 |
| 🟡 Code Quality | 4 | #10 #11 #12 #13 |
| 🔵 Component Issues | 10 | #14–23 |
| 🔵 Test Gaps | 1 | #24 |

**The three highest-priority fixes right now:**
1. **#1** — Debug text is player-visible immediately.
2. **#2** — Comparison panel stale state is a real gameplay bug.
3. **#6** — The god class is the root cause of most of the other issues; splitting it will surface and prevent future bugs.

