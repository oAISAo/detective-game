# Detective Game — Critical Code Review & Improvement Areas


## 1. Critical Bugs

### ALL FIXED!

## 2. High-Severity Bugs

### ALL FIXED!

## 3. Architectural Issues

### ALL FIXED!

## 4. Data Layer Problems

### 4.10 Asymmetric Relationships in Suspect Data

Julia has a relationship `{person_b: "p_mark", type: "FRIEND"}` but Mark has NO corresponding relationship back to Julia. Querying "who is related to Mark" from Mark's data won't return Julia.

---

### 4.11 Pressure Thresholds Differ From Design

Mark (2 vs design 3) and Sarah (3 vs design 2) have swapped values. Julia is 6 instead of 5. Undocumented changes.

---

### 4.12 Redundant Gating Between Discovery Rules and Event Triggers

Both `discovery_rules.json` and `events.json` gate the same evidence with overlapping conditions. It's unclear which system controls availability, and evidence might be "delivered" twice.

---

### 4.13 No WarrantData Resource Class

Warrants are referenced throughout event triggers and insights, but there is no `WarrantData` class defining what each warrant requires, judge feedback, or meta information.

---

### 4.14 No Cross-Reference Validation Anywhere

No validation that:
- `evidence.related_persons` reference valid person IDs
- `statement.person_id` references a valid person
- `trigger.evidence_id` references valid evidence
- `insight.source_evidence` references valid evidence

---

## 5. UI / Scene Issues

### ALL FIXED!

## 6. Test Suite Gaps

### 6.1 test_conclusion_scenarios.gd Is Never Run

**File:** `tests/scenarios/test_conclusion_scenarios.gd`

Located in `tests/scenarios/` (with 's') but `.gutconfig.json` lists `tests/scenario` (no 's'). GUT never discovers or runs this file. Contains all four ending scenario tests.

**Fix:** Move to `tests/scenario/` or update `.gutconfig.json`.

---

### 6.3 No Tests for ANY UI Screen Script

Zero tests exist for: desk_hub.gd, detective_board.gd, evidence_archive.gd, evidence_detail.gd, interrogation.gd, location_investigation.gd, location_map.gd, lab_queue.gd, warrant_office.gd, surveillance_panel.gd, theory_builder.gd, timeline_board.gd, case_report.gd, prosecutor_review.gd, case_outcome.gd, title_screen.gd, case_selection_screen.gd, suspect_list.gd, investigation_log.gd, morning_briefing (UI).

---

### 6.4 All Tests Use Real Singletons — No Mocking

Every test operates on real autoload singletons. Creates order-dependent execution risk. If any test crashes before `after_each`, the next test inherits dirty state.

---

### 6.5 Hardcoded Screen Counts Will Break

Multiple tests assert exactly `17` screens (e.g., `test_screen_scenes_registry_has_all_screens`). Will break whenever a screen is added/removed.

---

### 6.6 Integration Test for Autoloads Only Checks 9 of 21

**File:** `tests/integration/test_autoloads_accessible.gd`

Missing: BoardManager, TimelineManager, TheoryManager, LabManager, SurveillanceManager, WarrantManager, ConclusionManager, EvidenceManager, InterrogationManager, ScreenManager, DaySystem, ActionSystem.

---

### 6.7 Misleading Test Names

`test_screen_manager_has_thirteen_screens` asserts `17`. `test_screen_count_is_thirteen` asserts `17`. Names never updated.

---

### 6.8 Missing Negative/Error Tests

- No test for malformed JSON input through the loader
- No test for `deserialize()` with wrong dictionary structure
- No test for `start_interrogation()` on a VICTIM/WITNESS
- No test for null/empty string inputs to manager functions
- No test for corrupted save files

---

### 6.9 Private Member Access in Tests

Tests directly access `ScreenManager._nav_history`, `ScreenManager._transitioning`, `EventSystem._fired_triggers`, `DialogueSystem._dialogue_history`, etc. Will break if internals change.

---

### 6.10 Missing System Chain Integration Tests

- Interrogation → Board (results placed on board)
- Location Investigation → Lab (evidence submitted immediately)
- Surveillance → Interrogation (results unlock topics)
- Event System → Location Unlock (events unlock investigable locations)

---

### 6.11 Placeholder Generator Tests Don't Clean Up

`test_placeholder_generator.gd` generates image files during testing but has no `after_all()` to delete them.

---

## 7. Debug & Production Safety

### 7.1 Debug Panel Leaks to Production Builds

**File:** `scripts/debug/debug_panel.gd`

705 lines with **zero** calls to `OS.is_debug_build()`. The F1 hotkey, all debug actions (unlock evidence, advance day, set pressure, grant warrants, force outcomes), and 30+ `print()` statements are all available in release builds.

---

### 7.2 Title Screen Debug Button Always Visible

**File:** `scenes/ui/title_screen.tscn:83-90`

`DebugGameButton` has no mechanism to hide in release builds.

---

### 7.3 DebugStateLoader Is Globally Accessible

**File:** `scripts/debug/debug_state_loader.gd:4`

`class_name DebugStateLoader` — any script can call `DebugStateLoader.load_debug_state()` in production.

---

### 7.4 Debug Panel Accesses Private Members

**File:** `scripts/debug/debug_panel.gd:472-474, 485-488, 701-703`

Directly accesses `_fired_triggers`, `_accumulated_pressure`, `_current_pressure`, `_outcome`, `_evaluated`. Will crash silently if these private fields are renamed.

---

### 7.5 12+ Debug Functions Have No UI Buttons

Functions exist for: teleport to location, mark objects examined, reveal location evidence, reset interrogation, skip to trigger, set pressure, view triggers, clear board, auto-populate board, complete lab requests, grant warrants, install surveillance — but **none have corresponding buttons** in the debug panel scene.

---

### 7.6 Only One Debug Preset File

`data/debug/` contains only `debug_mark_interrogation.json`. Missing presets for: day 2 with evidence, day 3 mid-investigation, pre-accusation state, each suspect interrogation, etc.

---

## 8. Theme & Accessibility

### 8.1 Zero Keyboard/Controller Navigation

No scene sets `focus_mode`, `focus_neighbor`, `tab_index`, or `tab_stop`. The game is **mouse-only**. No keyboard or gamepad support.

---

### 8.2 No Custom Fonts

The Development Plan requires "typewriter/report fonts for official text" and "handwritten font for player annotations." No font resources exist. All text uses Godot's default font.

---

### 8.3 Theme Doesn't Cover All Control Types

Only 8 control types are styled. Missing: OptionButton, PopupMenu, SpinBox, TooltipLabel, TooltipPanel, TabBar, CheckBox. OptionButton dropdowns appear with Godot's default bright-gray theme.

---

### 8.4 No Focus Styles in Theme

Button has `normal`, `hover`, `pressed`, `disabled` — but no `focus` style. Keyboard focus shows Godot's default white rectangle, clashing with the dark theme.

---

### 8.5 No Accent/Warning Colors

No defined colors for error, warning, success, or active/selected states. The noir aesthetic needs a gold/amber accent.

---

### 8.6 Missing UIDs on 19 of 23 Scenes

Only 4 scenes have `uid` declarations. Missing UIDs cause breakage when files are moved/renamed in Godot 4.x.

---

### 8.7 Hardcoded Sizes Rather Than Anchors

| File | Issue |
|------|-------|
| game_root.tscn | CommandBar height hardcoded 48px, ScreenContainer offset_top 48 |
| detective_board.tscn | BoardCanvas hardcoded 3840×2160 |
| morning_briefing.tscn | Panel hardcoded 700×500 |
| desk_hub.tscn | 6 nav buttons hardcoded 200×50 |

---

## 9. Code Quality & Maintenance Debt

### 9.4 No Audio Bus Configuration

No `[audio]` section in project.godot. The design specifies 70% ambient / 20% music / 10% UI sounds requiring separate audio buses. `BGMPlayer` uses `bus = &"Master"`.

---

## Priority Order for Fixes

### Lower Priority (Quality of Life)
16. Debug panel production safety (§7.1)
17. Test suite directory mismatch (§6.1)
18. Theme completeness (§8.3)
19. Keyboard/accessibility (§8.1)
