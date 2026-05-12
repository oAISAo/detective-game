# Evidence Tab — Code Review

Covers all 15 scripts and 2 scenes (~2,455 lines) across the data, manager, and UI layers. Issues are grouped by severity.

**Files reviewed:**
- `scripts/ui/screens/evidence_archive.gd`
- `scripts/ui/components/evidence_detail_panel.gd`
- `scripts/ui/components/evidence_polaroid.gd`
- `scripts/ui/components/evidence_lab_section.gd`
- `scripts/ui/components/evidence_statements_panel.gd`
- `scripts/ui/components/evidence_pinned_bar.gd`
- `scripts/ui/components/evidence_value_section.gd`
- `scripts/ui/components/evidence_notes_section.gd`
- `scripts/ui/components/statement_item.gd`
- `scripts/managers/evidence_manager.gd`
- `scripts/data/evidence_data.gd`
- `scripts/data/statement_data.gd`
- `data/cases/riverside_apartment/evidence.json`

---

## 🔴 Critical Bugs

### 1. Nav-data evidence card is never selected in the grid
**File:** `evidence_archive.gd:47, 64-66`

```gdscript
_populate_evidence_list()  # runs first; detail_panel.get_selected_id() is "" here

var nav_data: Dictionary = ScreenManager.navigation_data
if nav_data.has("evidence_id"):
    detail_panel.show_evidence(nav_data["evidence_id"])  # sets _selected_id, but grid was already built
```

When the archive is opened with `navigation_data["evidence_id"]` (e.g. from a notification link), the detail panel shows the correct evidence but no card in the grid is highlighted. `_populate_evidence_list()` calls `detail_panel.get_selected_id()` to restore the selected card, but that ID is `""` at that point because `show_evidence()` hasn't been called yet.

**Fix:** Call `show_evidence()` before `_populate_evidence_list()`, or call `_select_card(evidence_id)` after `show_evidence()` in the nav-data block.

---

### 2. Contradictions detected from future-day statements
**File:** `evidence_manager.gd:217-229`

```gdscript
func check_contradictions() -> Array[Dictionary]:
    var all_stmts: Array[StatementData] = CaseManager.get_all_statements()
    for stmt: StatementData in all_stmts:              # ← no day filter
        for ev_id: String in stmt.contradicting_evidence:
            if GameManager.has_evidence(ev_id):
                new_list.append({...})
```

Compare `get_testimony()` which correctly gates on `stmt.day_given > 0 and stmt.day_given <= GameManager.current_day`. As written, discovering a piece of evidence on Day 1 can trigger a contradiction notification for a statement the player won't hear until Day 3.

**Fix:** Add the same day filter as `get_testimony()` inside `check_contradictions()`.

---

### 3. Two evidence IDs referenced in actions but missing from evidence.json
**File:** `data/cases/riverside_apartment/evidence.json` / `timeline.json`

`ev_sarah_testimony` and `ev_victim_phone` appear in `timeline.json` action results but have no corresponding entry in `evidence.json`. When those actions fire, `CaseManager.get_evidence()` returns `null`. The evidence ID is added to `GameManager.discovered_evidence` but any downstream code that calls methods on the returned null `EvidenceData` will crash (e.g., `evidence_polaroid.setup(ev, ...)` where `ev` is null).

**Fix:** Add both evidence definitions to `evidence.json`, or remove their references from the action results.

---

## 🟠 Logic / Behavior Issues

### 4. LAB badge never appears after submission
**File:** `evidence_polaroid.gd:98-99`

```gdscript
if ev != null and ev.lab_status == Enums.LabStatus.PROCESSING:
    _badge_row.add_child(_make_badge_pill("LAB", UIColors.AMBER))
```

`ev.lab_status` is loaded from JSON into a static `EvidenceData` resource and is never mutated at runtime. After the player clicks Submit, the resource still has `lab_status = NOT_SUBMITTED`. The badge will never appear on the polaroid card. Separately, no signal triggers `refresh_badges()` after lab submission — `_on_lab_submitted()` in the detail panel updates the lab section and info grid but does not call `card.refresh_badges()`.

**Fix:** Track lab submission state in `EvidenceManager` (or `LabManager`) and check that at badge-render time instead of `ev.lab_status`. Emit a signal from `EvidenceManager` after lab submission so `EvidenceArchive` can call `_refresh_card_badges()`.

---

### 5. "No new insights" shown when insight already discovered
**Files:** `evidence_manager.gd:176-178`, `evidence_detail_panel.gd:510-514`

```gdscript
# manager:
if insight.id in GameManager.discovered_insights:
    return null  # Already known

# detail panel:
else:
    result_label.text = "No new insights from this comparison."
```

`compare_evidence()` returns `null` both when no insight exists and when the insight was already discovered. The UI conflates these two cases under the same message. A player who compares two evidence items a second time sees "No new insights" and has no way to know they already discovered it.

**Fix:** Return a distinct value (e.g., a typed result enum or a two-value tuple) so the caller can show "Already discovered: [insight name]" vs. "No connection found."

---

### 6. Hint budget refunded by direct counter mutation
**File:** `evidence_manager.gd:352-359`

```gdscript
if not GameManager.use_hint():
    return {}
var hint: Dictionary = _find_best_hint()
if hint.is_empty():
    GameManager.hints_used -= 1  # fragile refund
    return {}
```

`use_hint()` presumably validates and increments a counter. Refunding by doing `hints_used -= 1` bypasses that API — if `use_hint()` ever becomes a property, has side effects, or is clamped, this refund will silently corrupt state.

**Fix:** Check `_find_best_hint()` first; only call `use_hint()` if a hint is ready to deliver. Or add a `refund_hint()` method to `GameManager`.

---

### 7. `ev_julia_shoes` has wrong discovery method
**File:** `data/cases/riverside_apartment/evidence.json`

```json
{ "id": "ev_julia_shoes", "discovery_method": "VISUAL", ... }
```

According to the narrative flow, these shoes are obtained via a search warrant, not direct visual inspection. The `VISUAL` label is displayed in the details grid and would affect any future logic gated on discovery method (warrant validation, filtering, etc.).

**Fix:** Change to `"WARRANT"`.

---

### 8. Undiscovered parent evidence name shown in "Derived From" row
**File:** `evidence_detail_panel.gd:251-260`

```gdscript
func _build_lineage_value(target_ev: EvidenceData, is_navigable: bool) -> Control:
    if is_navigable:
        return _make_wrapping_link_button(...)
    return _make_info_value_label(target_ev.name)   # shows name even when undiscovered
```

When a derived evidence item's parent has not been discovered yet (possible with lab "derive" transforms where the input stays and the output is added separately), the parent's name is shown as plain text in the info grid. This can spoil evidence names before the player finds them.

**Fix:** Show `"Unknown source"` or omit the row entirely when `is_navigable` is false.

---

## 🟡 Signal / Memory Management

### 9. `resized` connections accumulate on `_info_grid` and `_main_scroll`
**File:** `evidence_detail_panel.gd:277-281`

```gdscript
func _make_wrapping_link_button(...) -> LinkButton:
    link_button.resized.connect(_refresh_wrapping_link_text.bind(link_button, ...))
    if wrap_width_provider.is_valid():
        _info_grid.resized.connect(_refresh_wrapping_link_text.bind(link_button, ...))
        _main_scroll.resized.connect(_refresh_wrapping_link_text.bind(link_button, ...))
```

Each time a new evidence item with lineage is selected, `_populate_info_grid` → `_populate_lineage_rows` → `_make_wrapping_link_button` runs and adds new connections to `_info_grid.resized` and `_main_scroll.resized`. The old `LinkButton` nodes are freed by `UIHelper.clear_children()`, but Godot only auto-disconnects signal connections when the *emitting* node is freed — not when a bound callable's captured argument becomes invalid. The dead connections accumulate silently.

`_refresh_wrapping_link_text` guards with `if not is_instance_valid(link_button): return`, which prevents crashes, but every resize event on `_info_grid` still invokes all accumulated callbacks.

**Fix:** Disconnect from `_info_grid.resized` and `_main_scroll.resized` explicitly before clearing children, or use `CONNECT_ONE_SHOT` if a single refresh is sufficient after layout, or use `_info_grid.resized.connect(..., CONNECT_REFERENCE_COUNTED)` with explicit disconnect tracking.

---

### 10. `EvidenceStatementsPanel` uses manual disconnect instead of `UIHelper.safe_disconnect`
**File:** `evidence_statements_panel.gd:19-21`

```gdscript
func _exit_tree() -> void:
    if EvidenceManager.statement_verdict_changed.is_connected(_on_verdict_changed):
        EvidenceManager.statement_verdict_changed.disconnect(_on_verdict_changed)
```

Every other component in this system uses `UIHelper.safe_disconnect()`. This works correctly but is inconsistent. When `UIHelper.safe_disconnect()` is updated (e.g., to add logging or error handling), this component won't benefit.

**Fix:** Replace with `UIHelper.safe_disconnect(EvidenceManager.statement_verdict_changed, _on_verdict_changed)`.

---

### 11. `state_loaded` connected with direct method reference; all others use stored lambdas
**File:** `evidence_archive.gd:62, 74`

```gdscript
# Lines 49–61: all signals use stored lambdas
_on_evidence_discovered_cb = func(_id: String) -> void: _refresh()
GameManager.evidence_discovered.connect(_on_evidence_discovered_cb)

# Line 62: state_loaded breaks the pattern
EvidenceManager.state_loaded.connect(_refresh)
# Line 74: disconnect works but is inconsistent
UIHelper.safe_disconnect(EvidenceManager.state_loaded, _refresh)
```

Not a bug, but violates the file's own established pattern. When auditing signal cleanup, a reviewer must know that `_refresh` (a method) and `_on_evidence_discovered_cb` (a lambda) are both valid callables but are managed differently.

**Fix:** Store a callable for `state_loaded` as well:
```gdscript
_on_state_loaded_cb = func() -> void: _refresh()
EvidenceManager.state_loaded.connect(_on_state_loaded_cb)
```

---

## 🟡 Code Quality / Duplication

### 12. `_on_card_pressed` and `_on_evidence_requested` are identical
**File:** `evidence_archive.gd:213-232`

```gdscript
func _on_card_pressed(evidence_id: String) -> void:
    if _selected_card != null and is_instance_valid(_selected_card):
        _selected_card.set_selected(false)
    _selected_card = _card_nodes.get(evidence_id) as EvidencePolaroid
    if _selected_card != null:
        _selected_card.set_selected(true)
    detail_panel.show_evidence(evidence_id)

func _on_evidence_requested(evidence_id: String) -> void:
    # identical body
```

These four operations are duplicated verbatim. Any future change (e.g., adding scroll-to-card) must be made in both places.

**Fix:** Extract to `_select_evidence(evidence_id: String)` and have both callbacks delegate to it.

---

### 13. `EvidenceValueSection.clear()` never called from the parent
**Files:** `evidence_detail_panel.gd`, `evidence_value_section.gd:43-44`

`EvidenceDetailPanel.clear()` hides `_detail_panel` (which contains `_value_section`) but never calls `_value_section.clear()`. The value section retains stale label nodes. The visual result is correct because the parent container is hidden, but `clear()` on a sub-component implies a clean reset and should be honored.

**Fix:** Call `_value_section.clear()` inside `EvidenceDetailPanel.clear()`.

---

### 14. `separation` theme override applied on every `populate()` call
**File:** `evidence_lab_section.gd:22`

```gdscript
func populate(evidence_id: String) -> void:
    _evidence_id = evidence_id
    UIHelper.clear_children(self)
    ...
    add_theme_constant_override("separation", 8)  # same value every time
```

This override is unconditional and always sets the same value. It should be a one-time setup in `_init()` or `_ready()`.

**Fix:** Move the override to `_ready()`.

---

### 15. `_format_analysis_type` capitalization rule is inconsistent
**File:** `evidence_lab_section.gd:124-129`

```gdscript
func _format_analysis_type(analysis_type: String) -> String:
    var words: PackedStringArray = analysis_type.replace("_", " ").split(" ", false)
    var formatted_words: Array[String] = []
    for word: String in words:
        formatted_words.append(word.to_upper() if word.length() <= 3 else word.capitalize())
    return " ".join(formatted_words)
```

Words of 3 or fewer characters become ALL CAPS; longer words become Title Case. `"fingerprint_analysis"` → `"Fingerprint Analysis"`, but `"pcr_dna_analysis"` → `"PCR DNA Analysis"` while `"and"` becomes `"AND"`. The rule is arbitrary and produces inconsistent output.

**Fix:** Use a single consistent casing strategy — title case for all words is likely sufficient.

---

## 🟡 Missing Test Coverage

These gaps are documented in `evidence-todos.md` and confirmed unaddressed in the current test suite (`tests/unit/test_evidence_archive_ui.gd`, `tests/unit/test_evidence_manager.gd`, `tests/integration/test_evidence_system_integration.gd`).

**16.** No test for `_comparing` flag reset when switching from one evidence item to another. If the comparison panel is open and the player navigates away, the flag must reset to `false`. The reset happens in `show_evidence()` at line 115, but no test verifies it.

**17.** No test for polaroid badge refresh after pin/unpin. `_on_detail_pin_toggled()` calls `_refresh_card_badges()`, which calls `card.refresh_badges()`, but the interaction is untested.

**18.** No test for simultaneous filter + search. Both operate independently but are applied together in `_get_filtered_evidence()`. The combination (e.g., "Forensic" filter + "glass" query) has no test case.

**19.** No test for notes text persisting when switching between evidence items and returning. The notes text edit is rebuilt on each `populate()` call and reads from `EvidenceManager.get_player_notes()`. That round-trip is untested.

**20.** No test for pinned bar reconstruction after `state_loaded`. After `deserialize()` → `state_loaded` signal, `EvidencePinnedBar.populate()` should rebuild its buttons. This deserialization path is untested.

---

## ⚪ Data / Content Issues

### 21. Eleven evidence items have no discoverable action source
**File:** `data/cases/riverside_apartment/evidence.json`

The following items exist in `evidence.json` but do not appear in any `timeline.json` action's results array, meaning the player cannot acquire them through gameplay:

| ID | Importance | Note |
|---|---|---|
| `ev_autopsy_report` | REQUIRED | Appears to be a case briefing item |
| `ev_deleted_messages` | REQUIRED | Should come from a WARRANT result |
| `ev_desk_fingerprint_raw` | MAJOR | Should come from a forensic action |
| `ev_julia_financial_records` | MAJOR | No action source |
| `ev_julia_shoes` | REQUIRED | Should come from a warrant |
| `ev_julia_text_message` | MAJOR | No action source |
| `ev_mark_call_log` | MAJOR | No action source |
| `ev_wine_bottle` | MINOR | No action source |
| `ev_knife_block` | MAJOR | No action source |

Lab outputs (`ev_julia_fingerprint_glass`, `ev_mark_fingerprint_desk`, `ev_shoe_print`) are intentionally acquired via lab requests — those are correctly excluded from this list.

**Fix:** Either add the missing items to action results, or document which are granted as case-file briefing items at game start.

---

### 22. `day_given = 0` sentinel is undocumented
**File:** `scripts/data/statement_data.gd:17`

```gdscript
@export var day_given: int = 0
```

`get_testimony()` in `EvidenceManager` filters with `stmt.day_given > 0`, treating `0` as "never given." This same sentinel is used in `check_contradictions()` (issue #2 above). The `0` value is a magic number — nothing in `StatementData`, its JSON schema, or its validation documents this convention.

**Fix:** Add a constant or a comment documenting that `day_given = 0` means "not accessible." Alternatively, use `-1` or a nullable int pattern to distinguish "not set" from "Day 0."
