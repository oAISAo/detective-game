# Detective Game — Critical Code Review & Improvement Areas

> Generated from a thorough audit of every script, scene, data file, and test in the project.
> Organized by severity: Critical → High → Medium → Low.

---

## Table of Contents

1. [Critical Bugs (Crash / Data Loss / Broken Features)](#1-critical-bugs)
2. [High-Severity Bugs (Incorrect Gameplay / Logic Errors)](#2-high-severity-bugs)
3. [Architectural Issues](#3-architectural-issues)
4. [Data Layer Problems](#4-data-layer-problems)
5. [UI / Scene Issues](#5-ui--scene-issues)
6. [Test Suite Gaps](#6-test-suite-gaps)
7. [Debug & Production Safety](#7-debug--production-safety)
8. [Theme & Accessibility](#8-theme--accessibility)
9. [Code Quality & Maintenance Debt](#9-code-quality--maintenance-debt)

---

## 1. Critical Bugs

### 1.1 Signal Leak Crash — desk_hub.gd & evidence_archive.gd

**Files:** `scripts/ui/screens/desk_hub.gd:29-34`, `scripts/ui/screens/evidence_archive.gd:41-43`

Lambda callbacks connected to autoload signals (GameManager, NotificationManager, EvidenceManager) capture `self`. When the screen is freed (player navigates away), the autoload signals still hold references to callables bound to the freed instance. Next signal emission → **runtime crash**.

There is **no `_exit_tree()`** method to disconnect these in either file. Connections accumulate on every visit.

**Fix:** Add `_exit_tree()` that disconnects each signal, or store callable references for disconnection.

---

### 1.2 Alternatives Score Always Returns 0.0 — conclusion_manager.gd

**File:** `scripts/managers/conclusion_manager.gd:252-263`

`_calculate_alternatives_score()` checks `GameManager.completed_interrogations`, but this Dictionary is **never populated anywhere in the codebase**. InterrogationManager tracks this internally in `_fired_triggers` but never writes to GameManager's dictionary.

Result: alternatives score is always 0.0, making the effective max base score 0.75 instead of 0.90. The prosecutor confidence scoring is fundamentally broken.

---

### 1.3 Statement Intake Phase Never Entered — interrogation_manager.gd

**File:** `scripts/managers/interrogation_manager.gd:78`

`start_interrogation()` sets `_current_phase = Enums.InterrogationPhase.INTERROGATION` directly, skipping `STATEMENT_INTAKE`. The `advance_to_interrogation()` method (lines 120-129) is unreachable. The entire "suspect tells their story" opening phase described in the design is **unimplemented**.

---

### 1.4 Shared-Reference Bug on Deserialization — game_manager.gd

**File:** `scripts/managers/game_manager.gd:536-539`

```gdscript
completed_interrogations = data.get("completed_interrogations", {})
interrogation_counts_today = data.get("interrogation_counts_today", {})
active_lab_requests = data.get("active_lab_requests", [])
active_surveillance = data.get("active_surveillance", [])
```

These are assigned by direct reference from the save data dictionary (unlike other fields which use `.assign()`). Subsequent mutations also mutate the original save data, corrupting future save operations.

---

### 1.5 No Signal Re-emission After Deserialization — ALL Managers

**Systemic across:** BoardManager, TimelineManager, TheoryManager, InterrogationManager, LocationInvestigationManager, NotificationManager.

`deserialize()` restores all state but **never emits** domain signals (`node_added`, `evidence_found`, `overlap_detected`, etc.). After loading a save, every UI shows stale data until the next user interaction triggers a refresh.

---

### 1.6 Case ID Not In Save File — case_manager.gd

CaseManager has no `serialize()`/`deserialize()`. The save file does not record which case was loaded. Loading a save from Case A while Case B is active produces silently corrupted state.

---

### 1.7 CaseData.to_dict() Drops Solution Data — case_data.gd

**File:** `scripts/data/case_data.gd:230-311`

`from_dict()` reads `solution_suspect`, `solution_motive`, `solution_weapon`, `solution_time_minutes`, `solution_time_day`, `solution_access`, and `critical_evidence_ids`. But `to_dict()` **never writes any of these fields**. Serialization permanently loses solution data.

---

### 1.8 Case Outcome Screen Is a Dead End

**File:** `scripts/ui/screens/case_outcome.gd`

No back button, no "Return to Title" button, no navigation of any kind. Once the player reaches this screen, they are **permanently stuck**. The only escape is Alt+F4.

---

### 1.9 Save File Write Is Not Atomic — save_manager.gd

**File:** `scripts/managers/save_manager.gd:56-69`

Writes directly to the target file. If the game crashes during `file.store_string()`, the save is partially written and **permanently corrupted**. Should write to a temp file then atomic-rename.

---

## 2. High-Severity Bugs

### 2.1 Contradiction Check Leaks Future Statements — evidence_manager.gd

**File:** `scripts/managers/evidence_manager.gd:200-213`

`check_contradictions()` scans ALL statements in the case, but `get_testimony()` correctly filters by `day_given <= current_day`. Every time evidence is found, contradictions for statements the player hasn't encountered yet are revealed.

---

### 2.2 Sibling Trigger Suppression — interrogation_manager.gd

**File:** `scripts/managers/interrogation_manager.gd:195-197`

When a trigger fires, ALL sibling triggers for the same `evidence_id` are marked as fired. If the same evidence has different triggers for different focus targets, only the first-reached trigger ever fires.

---

### 2.3 False Contradiction Inflation — interrogation_manager.gd

**File:** `scripts/managers/interrogation_manager.gd:211-213`

A contradiction is logged for ANY successful trigger when focus is a statement, even if the result is `ADMISSION` or `REVELATION`. This inflates `_session_contradictions`, which gates the pressure system.

---

### 2.4 Signal Handlers Get Empty State — interrogation_manager.gd

**File:** `scripts/managers/interrogation_manager.gd:104-117`

`end_interrogation()` emits `interrogation_ended(person_id)`, then immediately clears session state. Any handler querying session state gets empty results.

---

### 2.5 Dual-Ownership State Divergence — Lab & Surveillance

**Files:** `scripts/managers/lab_manager.gd:90-93`, `scripts/managers/surveillance_manager.gd:99`

Both managers `.append()` a `.duplicate()` to `GameManager.active_lab_requests` / `GameManager.active_surveillance`. When requests are completed/expired internally, the GameManager copies are never updated. DaySystem reads from GameManager's stale copies.

---

### 2.6 EventSystem Double-Dispatches Actions — event_system.gd

**File:** `scripts/systems/event_system.gd:94-99`

For DAY_START triggers, `_dispatch_action()` emits `action_dispatched` internally, and then line 99 emits it **again**. Every action fires twice. Listeners counting dispatched actions will double-count.

---

### 2.7 `action_completed` Condition Checks Wrong List — event_system.gd

**File:** `scripts/systems/event_system.gd:251`

Checks `GameManager.mandatory_actions_completed` instead of ActionSystem's `executed_actions`. A condition like `action_completed:visit_crime_scene` fails even if the player did it, unless it was mandatory.

---

### 2.8 `lab_complete` Condition Logic Is Inverted — event_system.gd

**File:** `scripts/systems/event_system.gd:262-269`

A lab request that was **never submitted** also passes the `lab_complete` condition check because it's not in `active_lab_requests`. Should verify the request existed AND completed.

---

### 2.9 Malformed Conditions Silently Pass — event_system.gd

**File:** `scripts/systems/event_system.gd:236-239`

If a condition string has no colon (malformed), it's silently skipped with `continue`. Since the function only returns false on explicit failures, malformed conditions are treated as "met".

---

### 2.10 Timeline Cards Not Placed Under Correct Hours — timeline_board.gd

**File:** `scripts/ui/screens/timeline_board.gd:134`

`_insert_card_at_time()` **completely ignores its time parameter** and just appends to the container. Result: all hour markers appear first, then all event cards in a block. The timeline is visually meaningless.

---

### 2.11 TheoryBuilder PanelContainer Has Two Children — theory_builder.gd

**File:** `scripts/ui/screens/theory_builder.gd:326-333, 160-163`

PanelContainer only supports one child. `_create_step_panel` adds a Label, then callers add a VBox as a second child. This causes undefined layout — the title and content overlap. Affects all 5 theory steps.

---

### 2.12 CaseReport Submits Empty Evidence Arrays

**File:** `scripts/ui/screens/case_report.gd:53-59`

Every report section's `"evidence"` array is hardcoded to `[]`. The theory's attached evidence is never included, making the prosecutor's confidence score artificially low.

---

### 2.13 CaseReport Uses Non-Existent Theory Field

**File:** `scripts/ui/screens/case_report.gd:58`

`theory.get("access", "Unknown")` — TheoryManager has no `"access"` field. Always evaluates to "Unknown".

---

### 2.14 Surveillance "Past Operations" Section Always Empty

**File:** `scripts/ui/screens/surveillance_panel.gd:56-62`

`_get_all_operation_ids()` only returns active operation IDs. The "Past Operations" section filters for `status != "active"`. Result: past operations never appear.

---

### 2.15 Note Dialog Leaks on Confirm — detective_board.gd

**File:** `scripts/ui/screens/detective_board.gd:293-311`

The `confirmed` handler never calls `dialog.queue_free()`. Each "Edit Note" action leaks an orphan dialog node.

---

### 2.16 DaySystem Legacy Fallback Fires Triggers Repeatedly

**File:** `scripts/systems/day_system.gd:250-264`

The legacy `_evaluate_day_start_triggers` has no `_fired_triggers` tracking. All DAY_START triggers fire every morning. The EventSystem version correctly prevents this, but the fallback exists and can diverge.

---

### 2.17 `_advance_lab_timers()` Is a No-Op — day_system.gd

**File:** `scripts/systems/day_system.gd:211-212`

Called during night processing but contains only `pass`. Dead code since Phase 2.

---

### 2.18 No Duplicate Warrant Prevention — warrant_manager.gd

**File:** `scripts/managers/warrant_manager.gd:70-113`

No check for existing approved warrants of the same type+target. Players can file unlimited redundant warrants.

---

### 2.19 No Duplicate Board Connection Check — board_manager.gd

**File:** `scripts/managers/board_manager.gd:156-179`

Unlimited duplicate connections allowed between the same node pair.

---

### 2.20 LocationInvestigation Reveals All Evidence at Once

**File:** `scripts/managers/location_investigation_manager.gd:122-126`

ALL `evidence_results` on an object are discovered regardless of which action/tool was used. A single visual inspection reveals everything.

---

### 2.21 "Investigate" and "Review" Choices Are Dead Ends

**File:** `scripts/managers/conclusion_manager.gd:346-356`

`make_choice()` only acts on "charge". Selecting "investigate" or "review" emits a signal but has no handler, no state change, no follow-up flow.

---

### 2.22 Report Cannot Be Revised — conclusion_manager.gd

**File:** `scripts/managers/conclusion_manager.gd:91-93`

`submit_report()` rejects if `has_report()` is true. No `retract_report()` or `revise_report()` method.

---

## 3. Architectural Issues

### 3.1 GameManager Is a God Object

**File:** `scripts/managers/game_manager.gd`

Holds state for evidence, locations, interrogations, lab requests, surveillance, warrants, board, timeline, theories, investigation log, and hints. Also orchestrates reset/serialize/deserialize of 12+ other systems. Textbook god object.

`new_game()`, `serialize()`, and `deserialize()` contain nearly identical blocks for every subsystem. Adding any new system requires updating all three methods.

**Fix:** Registry pattern (`var _subsystems: Array[Node]`) where each subsystem auto-registers.

---

### 3.2 Five Managers Call Private `_log_action`

**Files:** LabManager:98, SurveillanceManager:102, WarrantManager:97/105/223, ConclusionManager:380, ActionSystem:151, SuspectList:99

All call `GameManager._log_action()` (underscore-prefixed = private by convention). Should be a public API.

---

### 3.3 Stale Legacy State Variables — game_manager.gd

**File:** `scripts/managers/game_manager.gd:107-113`

`player_board_state`, `player_timeline`, `player_theories` are never written to during gameplay. BoardManager, TimelineManager, and TheoryManager own this data now. SaveManager still saves/loads these empty dictionaries.

---

### 3.4 Hardcoded `TOTAL_DAYS = 4` Conflicts With CaseData

**File:** `scripts/managers/game_manager.gd:48`

CaseData has `start_day`/`end_day` but GameManager ignores them. Nothing enforces consistency.

---

### 3.5 DaySystem Directly Mutates GameManager State

**File:** `scripts/systems/day_system.gd:129-177`

DaySystem writes to `GameManager.current_phase`, `GameManager.actions_remaining`, `GameManager.current_day`, and emits GameManager's own signals. Neither object truly owns the state.

---

### 3.6 No Shared Interface for Subsystems

All systems independently implement `serialize()`, `deserialize()`, and `reset()` with no base class. GameManager discovers them via `has_method()` checks. Renaming a method silently breaks serialization.

---

### 3.7 String-Based Action/Condition Parsing Is Error-Prone

ActionSystem, EventSystem, and DaySystem all parse colon-delimited strings like `"evidence:knife"`. No shared parser, no constants, no compile-time checking. A typo silently fails differently in each system.

---

### 3.8 NotificationManager Missing Reset and Serialization

- No reset method → notifications from previous game persist into new game
- No serialize/deserialize → notification queue lost on save/load
- `get_all()` returns internal reference, allowing external mutation

---

### 3.9 Mid-Interrogation Save Not Supported

**File:** `scripts/managers/interrogation_manager.gd:624-637`

`serialize()` only saves persistent cross-session state. In-progress session (current phase, focus, contradictions, unlocked topics) is lost on save/load.

---

### 3.10 Action Consumed Before Session Established

**File:** `scripts/managers/interrogation_manager.gd:85`

`GameManager.record_interrogation(person_id)` increments the daily counter before the session is established. If the session fails, the counter is consumed but nothing happened.

---

## 4. Data Layer Problems

### 4.1 Case Loader Never Calls validate()

**File:** `scripts/loaders/case_loader.gd:60-62`

CaseData has a `validate()` method but the loader never calls it. Corrupted/incomplete JSON silently produces invalid game objects.

---

### 4.2 All Action Requirements and Results Are Empty

**File:** `data/cases/riverside_apartment/timeline.json` (Actions section)

All 9 ActionData entries have `requirements: []` and `results: []`. The action availability system cannot function as designed with no prerequisites defined.

---

### 4.3 Lab Requests Have Same Input and Output ID

**File:** `data/cases/riverside_apartment/timeline.json`

- `lab_fingerprint_desk`: input=`ev_mark_fingerprint_desk`, output=`ev_mark_fingerprint_desk`
- `lab_shoe_print`: input=`ev_shoe_print`, output=`ev_shoe_print`

Lab requests are supposed to be "evidence transformations" per the design. These transform evidence into themselves.

---

### 4.4 Surveillance Requests Produce No Events

Both surveillance requests have `result_events: []`. The design states surveillance should produce observation events for the timeline.

---

### 4.5 critical_evidence_ids Only Lists 4 of 10 CRITICAL Items

**File:** `data/cases/riverside_apartment/case.json:15-20`

Only 4 items in `critical_evidence_ids`, but 10 evidence items have `importance_level: "CRITICAL"`. This directly impacts the prosecutor confidence scoring.

---

### 4.6 Sarah and Lucas Missing Interrogation Break Content

Sarah's and Lucas's interrogation sessions are missing `pressure_dialogue`, `break_dialogue`, `break_statement_ids`, and `break_unlocks`. When pressure reaches their thresholds, the system finds nothing.

---

### 4.7 Mark Unlocked on Day 1 Instead of Day 2

**File:** `data/cases/riverside_apartment/events.json:3-17`

`trig_morning_briefing_day1` includes `unlock_interrogation:p_mark`. The design says Mark should be available on Day 2.

---

### 4.8 Discovery Rules Point to Wrong Locations

- `dr_julia_shoes`: `location_id: "loc_victim_apartment"` — Julia's shoes should come from Julia's residence via warrant
- `dr_deleted_messages`: `location_id: "loc_victim_apartment"` — deleted messages recovered from Julia's phone via warrant

---

### 4.9 Debug State File Uses Wrong Location IDs

**File:** `data/debug/debug_mark_interrogation.json`

Uses `"victim_apartment"`, `"building_hallway"` etc. instead of `"loc_victim_apartment"`, `"loc_hallway"`. None of these match the case data IDs.

---

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

### 5.1 queue_free() Followed by Immediate add_child — Ghost Children

**Affects nearly every screen.** `queue_free()` defers deletion to end-of-frame. New children coexist with dying children for one frame, causing layout flicker and potential interaction with nearly-freed nodes.

**Fix:** Use `remove_child(child); child.queue_free()` or `child.free()` for immediate removal.

---

### 5.2 debug_panel.tscn ScrollContainer Is Broken

**File:** `scenes/core/debug_panel.tscn:47-57`

`ScrollContainer` and `ContentLabel` are siblings, not parent-child. The ScrollContainer is empty. Debug text is unscrollable and clips.

---

### 5.3 case_report, prosecutor_review, case_outcome Scenes Are Skeletal

- Missing margins on MarginContainers
- Plain Labels instead of RichTextLabels (no autowrap)
- No ScrollContainers for long content
- No evidence attachment UI in case_report (design requires 5 evidence-supported sections)
- These are the climax of the game

---

### 5.4 LocationMap First-Visit vs Return-Visit Is Dead Code

**File:** `scripts/ui/screens/location_map.gd:77-98`

Both branches of the `is_first_visit` conditional do **exactly the same thing**.

---

### 5.5 Lab, Warrant, and Surveillance Screens Are Display-Only

- `lab_queue.gd`: `submit_section` never populated
- `warrant_office.gd`: no warrant request UI
- `surveillance_panel.gd`: no surveillance installation UI

Players can view existing items but cannot create new ones from these screens.

---

### 5.6 No Confirmation Dialogs for Destructive Actions

- `BoardManager.clear_board()` — clears entire board, no confirmation
- `TheoryManager.remove_theory()` — deletes theory, no confirmation
- "Charge" choice in prosecutor_review — irreversible, no confirmation
- `get_tree().quit()` in title_screen — immediate quit, no save prompt

---

### 5.7 Investigation Log Is Static

**File:** `scripts/ui/screens/investigation_log.gd`

Populated once in `_ready()`, never refreshes. Becomes stale if kept open.

---

### 5.8 Text/Button Matching by Display Text Instead of ID

- `case_selection_screen.gd:130-135`: Matches buttons by `.text` — two same-titled cases disable both buttons
- `interrogation.gd:390-396`: Matches evidence buttons by `.text` — same-named evidence highlights wrong button

**Fix:** Use `set_meta()` / `get_meta()` for ID matching.

---

### 5.9 Inconsistent Autoload Access Patterns

Some files use direct autoload names (`GameManager.current_day`), others use `get_node_or_null("/root/...")` repeatedly instead of caching.

---

### 5.10 BoardConnectionDrawer Has O(N*M) Performance

**File:** `scripts/ui/screens/board_connection_drawer.gd:52-60`

`_find_node_control()` does a linear scan of all children for each connection endpoint during `_draw()`. Should use a dictionary lookup.

---

### 5.11 Hardcoded Colors Repeated Dozens of Times

`Color(0.5, 0.48, 0.45)` appears 20+ times across files. `Color(0.6, 0.55, 0.4)` appears 5+ times. `Color(0.7, 0.68, 0.65)` appears 6+ times.

**Fix:** Define in a shared constants file or theme.

---

### 5.12 Empty States Not Handled

- `evidence_detail.gd`: If evidence_id is missing, buttons remain visible and may crash
- `interrogation.gd`: If person_id is empty, UI elements remain visible but unpopulated
- `location_investigation.gd`: If location not found, panels remain visible in default state

---

## 6. Test Suite Gaps

### 6.1 test_conclusion_scenarios.gd Is Never Run

**File:** `tests/scenarios/test_conclusion_scenarios.gd`

Located in `tests/scenarios/` (with 's') but `.gutconfig.json` lists `tests/scenario` (no 's'). GUT never discovers or runs this file. Contains all four ending scenario tests.

**Fix:** Move to `tests/scenario/` or update `.gutconfig.json`.

---

### 6.2 No CI/CD Configuration

No `.github/workflows/`, no `.gitlab-ci.yml`, no `Makefile`. Tests only run when someone manually executes them. No regression protection.

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

### 9.1 Massive Code Duplication Across UI Files

- `_get_type_label()` — identical in evidence_archive.gd and evidence_detail.gd
- `_get_location_name()` — identical in evidence_archive.gd and evidence_detail.gd
- `_safe_disconnect()` — identical in detective_board.gd, timeline_board.gd, theory_builder.gd
- `_add_section_header()` — nearly identical in lab_queue.gd, warrant_office.gd, surveillance_panel.gd
- `_get_category_name()` — duplicated in warrant_office.gd and evidence_detail.gd

**Fix:** Extract to a shared UIHelper autoload or base class.

---

### 9.2 `print()` Statements in Production Code

Every system's `_ready()` prints initialization messages. ActionSystem, DialogueSystem, DaySystem, EventSystem, ToolManager all have bare `print()` calls.

---

### 9.3 21 Autoloads — Heavy Initialization

`project.godot` registers 21 autoload singletons. Candidates for consolidation:
- LabManager + SurveillanceManager + WarrantManager → InvestigationToolsManager
- TimelineManager + TheoryManager + BoardManager → PlayerWorkspaceManager

---

### 9.4 No Audio Bus Configuration

No `[audio]` section in project.godot. The design specifies 70% ambient / 20% music / 10% UI sounds requiring separate audio buses. `BGMPlayer` uses `bus = &"Master"`.

---

### 9.5 No Input Actions Beyond F1

Only `toggle_debug_panel` is defined. No `ui_back` / `escape` for screen navigation. No gamepad mappings.

---

### 9.6 ToolManager Initialization Duplicates Registry

`_ready()` and `reset()` hardcode the same three tool IDs. Adding a tool to `TOOL_REGISTRY` requires remembering to also add it to initialization.

**Fix:** Initialize `available_tools` from `TOOL_REGISTRY.keys()`.

---

### 9.7 AssetFallback Cache Has No Eviction

`_cache` stores every loaded texture forever with no LRU eviction or size limit. `clear_cache()` exists but is never called automatically.

---

### 9.8 Dialogue System Potential Infinite Recursion

**File:** `scripts/systems/dialogue_system.gd:231, 244`

If multiple zero-line dialogues are queued, `_start_next_dialogue -> advance -> _end_current_dialogue -> _start_next_dialogue` creates unbounded recursion.

---

### 9.9 No Autoload Order Protection

EvidenceManager connects to `GameManager.evidence_discovered` in `_ready()` without checking if GameManager exists. If autoload ordering changes, this crashes.

---

### 9.10 Window Mode Hardcoded to Maximized

`project.godot:51` — `window/size/mode=2`. No settings screen exists to change this at runtime despite the title screen having a "Settings" button.

---

## Priority Order for Fixes

### Immediate (Blocking Gameplay)
1. Signal leak crashes in desk_hub.gd and evidence_archive.gd (§1.1)
2. Conclusion scoring always 0 for alternatives (§1.2)
3. Case outcome dead-end screen (§1.8)
4. Timeline cards not placed at correct times (§2.10)
5. Case ID not in save file (§1.6)

### High Priority (Broken Features)
6. Statement intake phase never entered (§1.3)
7. CaseReport submits empty evidence (§2.12)
8. Deserialization signals not re-emitted (§1.5)
9. Event double-dispatch (§2.6)
10. Shared-reference deserialization bug (§1.4)

### Medium Priority (Data Correctness)
11. Case loader should call validate() (§4.1)
12. Fix empty action requirements/results (§4.2)
13. Fix lab request input=output IDs (§4.3)
14. Fix critical_evidence_ids count (§4.5)
15. Fix discovery rule wrong locations (§4.8)

### Lower Priority (Quality of Life)
16. Debug panel production safety (§7.1)
17. Test suite directory mismatch (§6.1)
18. UI code deduplication (§9.1)
19. Theme completeness (§8.3)
20. Keyboard/accessibility (§8.1)
