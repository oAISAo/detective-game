# Detective Game — Critical Code Review & Improvement Areas

## Scope

Location Investigation system: `location_investigation.gd` (UI screen), `location_investigation_manager.gd` (manager), and `location_investigation.tscn` (scene).

---

## 1. Duplicated Object Lookup Logic

**Files:** `location_investigation.gd:334-340`, `location_investigation_manager.gd:460-469`

Both files implement their own object-by-ID lookup over `_location.investigable_objects`. The screen's `_find_object()` and the manager's `_get_object()` do the same thing — linear scan by ID — but the screen doesn't delegate to the manager.

**Recommendation:** The screen should call `LocationInvestigationManager._get_object()` (or a public wrapper) instead of maintaining its own `_find_object()`. Single source of truth for data access.

---

## 2. Duplicated "Has Evidence Been Found" Logic

**Files:** `location_investigation.gd:352-362`, `location_investigation_manager.gd:388-398`

The pattern "check `GameManager.has_evidence(ev_id)`, else check if a lab request upgraded it" appears in both `_populate_discovered_clues()` and `get_location_completion()`, and again in `get_suspect_relevance_tags()` (lines 343-359). This is a core game rule — "is this evidence discovered, including lab upgrades?" — duplicated across three call sites.

**Recommendation:** Extract a single method on the manager (e.g., `is_evidence_discovered(ev_id: String) -> bool`) that encapsulates the raw-or-upgraded check. All three call sites become one-liners.

---

## 3. Excessive Procedural UI Construction

**File:** `location_investigation.gd` — ~200 lines of manual node creation

The screen builds polaroid cards (`_build_polaroid_card`, 55 lines), placeholder scenes (`_build_scene_placeholder`, 40 lines), clue sections (`_populate_discovered_clues`, 50 lines), and panel styles (`_apply_panel_styles`, 14 lines) entirely in code with raw `StyleBoxFlat` property assignments, `add_theme_*_override` calls, and manual `Control` tree assembly.

This makes the visual design hard to iterate on, brittle to change, and difficult to read.

**Recommendation:**
- Extract the polaroid card into its own `.tscn` scene (like `ActionButton` already is). The card scene handles its own layout; the script just sets `ev.name` and `ev.image`.
- Extract the clue section (header + grid + scroll + empty state) into its own scene or component.
- Move panel border/radius styling into theme type variations (`SurfacePanel` already exists — extend it or create `SurfacePanelBordered`) rather than overriding at runtime.
- The placeholder could also be a scene, but it's lower priority since it's temporary.

---

## 4. Detail Panel State Managed via Layout Toggles

**File:** `location_investigation.gd:260-284`

The detail panel has two visual states (placeholder vs. target-selected), toggled by `_apply_detail_placeholder_layout()` and `_apply_detail_target_layout()`. These methods manually set alignment, visibility, margin overrides, and size flags on individual nodes — 12 property assignments each.

This is fragile: adding a new detail element means updating both methods in lockstep, and the "state" of the panel is implicit across scattered property values.

**Recommendation:** Use two separate containers (or scenes) — one for the placeholder state, one for the detail state — and simply toggle `.visible` between them. This makes each state self-contained and independently editable in the scene tree.

---

## 5. Child Cleanup Pattern is Verbose and Repeated

**File:** `location_investigation.gd:107-109, 171-173, 243-245`

The same 3-line loop (`for child in container.get_children(): remove_child(child); child.queue_free()`) appears three times. It's a common Godot pattern but adds noise.

**Recommendation:** Add a `clear_children(container: Node)` utility to `UIHelper` (which already serves this role). Other screens likely have the same pattern too.

---

## 6. `_remove_clues_section()` Uses Fragile Index-Based Removal

**File:** `location_investigation.gd:252-257`

This method removes all children after `DetailActions` by index. It depends on the clues section and spacer being the only nodes appended after `DetailActions`. If any future change adds another child to `detail_panel`, this silently breaks.

**Recommendation:** Name-based removal is safer — the clues section is already named `"CluesSection"`. Remove by name, and give the spacer a name too (e.g., `"CluesSpacer"`). Or better yet, wrap both in a single container so removal is always one node.

---

## 7. `start_investigation` / `start_map_investigation` Redundancy

**File:** `location_investigation_manager.gd:81-131`

Three entry points exist:
- `start_investigation()` — returns `bool`
- `start_investigation_with_result()` — returns `Dictionary`
- `start_map_investigation()` — just calls `start_investigation_with_result()`

`start_investigation()` wraps `start_investigation_with_result()` and discards the result. `start_map_investigation()` is a pure alias. Meanwhile `_last_start_investigation_result` stores the last result redundantly (and returns a double `.duplicate(true)` via `_record_start_result`).

**Recommendation:** Keep one entry point: `start_investigation(location_id) -> Dictionary`. Callers that only need success can check `result.success`. Remove `start_map_investigation()` (it adds no policy). Remove `_last_start_investigation_result` unless there's a proven consumer that reads it after the fact — if so, document who.

---

## 8. String-Keyed Action Tracking is Error-Prone

**File:** `location_investigation_manager.gd:157-180`

Actions are tracked with composite string keys (`"location_id:object_id"`) and magic string values (`"visual_inspection"`, `"examine_device"`, `"tool:fingerprint_kit"`). These strings are scattered across `inspect_object()`, `use_tool_on_object()`, `_update_object_state()`, and the UI's `_populate_action_buttons()`.

A typo in any of these strings silently breaks state tracking with no compiler or runtime warning.

**Recommendation:**
- Define action type constants (e.g., `const ACTION_VISUAL_INSPECTION = "visual_inspection"`) on the manager and reference them everywhere.
- Consider a small `ActionRecord` resource or typed dictionary instead of raw string arrays, but at minimum, centralise the string definitions.

---

## 9. `_build_start_result` / `_record_start_result` Ceremony

**File:** `location_investigation_manager.gd:546-567`

Building the result dictionary through a 6-parameter factory method and then recording it through a separate method that duplicates twice adds ceremony without safety. The dictionary shape isn't enforced — callers access keys by string (`result.get("success", false)`).

**Recommendation:** Define a simple inner class or typed dictionary pattern:

```gdscript
class StartResult:
    var success: bool
    var error_code: String
    var location_id: String
    var is_first_visit: bool
    var action_cost: int
```

This gives autocompletion, type checking, and makes the API self-documenting. If a full class feels heavy, at minimum inline the dictionary construction at the two call sites — the factory method obscures more than it helps.

---

## 10. `_get_visit_action_cost()` Always Returns 0

**File:** `location_investigation_manager.gd:525-526`

This method exists to "calculate" the visit cost but unconditionally returns 0. The call chain (`_get_visit_action_cost` -> `_apply_visit_cost` -> conditional `use_action`) is dead logic — the action cost branch in `_apply_visit_cost` can never execute.

**Recommendation:** If visit costs are planned for the future, leave a clear `# TODO` and remove the dead branch in `_apply_visit_cost`. If they're not planned, remove both methods entirely and simplify `start_investigation_with_result` accordingly. Dead code that looks alive is worse than no code.

---

## 11. Manager Couples to `CaseManager` as Global State

**File:** `location_investigation_manager.gd` — 15+ calls to `CaseManager.get_location()`, `CaseManager.get_evidence()`, etc.

Every method that needs location or evidence data reaches directly into the `CaseManager` singleton. This makes the manager impossible to unit test in isolation and creates a hidden dependency web.

**Recommendation:** This is a broader architectural concern, not a quick fix. For now, document the dependency. Longer term, consider passing `LocationData` / `EvidenceData` into methods that need them, or injecting a data-access interface. The manager's `_get_object()` method (which already takes `location_id` and calls `CaseManager`) is a natural seam for this.

---

## 12. Screen Doesn't Disconnect Signals or Clean Up

**File:** `location_investigation.gd`

The screen connects `back_button.pressed` and dynamically created button signals, but never implements `_exit_tree()` to clean up. While Godot auto-disconnects signals when nodes are freed, dynamically created buttons with `Callable(self, "_on_inspect_pressed").bind(obj.id)` can cause issues if the screen is removed from the tree but not immediately freed.

Other screens in the project (e.g., `EvidenceArchive`) implement `_exit_tree()` for cleanup — this one should follow the same pattern for consistency.

---

## 13. `inspect_object` Silently Records `examine_device` as Done

**File:** `location_investigation_manager.gd:178-180`

When `inspect_object()` is called, it records `"visual_inspection"` as performed. But it also unconditionally records `"examine_device"` if that action exists on the object — even though no examine-specific logic runs. This means visual inspection and device examination are invisibly merged into one action.

If this is intentional (they're the same action with different labels), the two action types should be consolidated into one. If they're meant to be distinct actions, this is a bug — examining a device should be its own action with its own cost and discovery logic.

---

## Summary Table

| # | Area | Severity | Effort |
|---|------|----------|--------|
| 1 | Duplicated object lookup | Low | Low |
| 2 | Duplicated evidence-discovered check | Medium | Low |
| 3 | Excessive procedural UI | Medium | Medium |
| 4 | Detail panel dual-state via property toggling | Medium | Medium |
| 5 | Repeated child-cleanup loop | Low | Low |
| 6 | Index-based clue section removal | Medium | Low |
| 7 | Redundant start_investigation variants | Low | Low |
| 8 | String-keyed action tracking | Medium | Low |
| 9 | Over-engineered result builder | Low | Low |
| 10 | Dead visit-cost code | Low | Low |
| 11 | Hard coupling to CaseManager | Low | High |
| 12 | Missing signal cleanup | Low | Low |
| 13 | Silent examine_device recording | Medium | Low |
