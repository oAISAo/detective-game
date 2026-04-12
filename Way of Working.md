# Detective Investigation Game — Way of Working

This document defines the development practices, quality standards, and workflows for building a commercial-quality detective investigation game in Godot 4.x.

---

## 1. Development Methodology

### Iterative Feature Development

The game is built phase by phase. Each phase delivers a working, testable system.

**The cycle for every feature:**

```
Design → Implement → Test → Review → Integrate → Commit (done by user)
```

No feature is considered "done" until it has:
- Working implementation
- Automated tests passing
- Manual verification completed
- No regressions in existing systems

### Working in Phases

Each Development Plan phase follows this structure:

1. **Read the phase requirements** from the Development Plan
2. **Break the phase into discrete tasks** (create todo list)
3. **Implement one task at a time** — small, focused changes
4. **Write tests alongside implementation** (not after)
5. **Verify integration** with existing systems
6. **Phase review** — full playthrough of affected systems before moving on

---

## 2. Testing Strategy

Testing is mandatory for a commercial release. Every new feature gets tests. Every bug fix gets a regression test.

### Testing Framework

**Primary:** GUT (Godot Unit Testing) — https://github.com/bitwes/Gut

GUT is the most mature and widely adopted testing framework for GDScript. It provides:
- Unit test runner integrated with Godot
- Assert methods for all common checks
- Setup/teardown lifecycle
- Test doubles (mocks/stubs)
- Signal watching
- Command-line execution for CI

### Test Directory Structure

```
/project
└── /tests
    ├── /unit                — Unit tests for individual classes
    │   ├── /data            — Resource/data model tests
    │   ├── /managers        — Manager singleton tests
    │   ├── /systems         — Game system tests
    │   └── /utils           — Utility function tests
    ├── /integration         — System interaction tests
    │   ├── /evidence_flow   — Evidence discovery → archive → interrogation
    │   ├── /day_system      — Day progression → event triggers → state changes
    │   ├── /warrant_flow    — Evidence → warrant → unlock
    │   └── /case_flow       — Full case progression tests
    ├── /scenario            — Scripted gameplay scenario tests
    │   └── /prototype_case  — The Riverside Apartment Murder scenarios
    └── gut_config.gd        — GUT configuration
```

### Test Categories

#### 2.1 — Unit Tests

Test individual classes and functions in isolation.

**What to unit test:**
- Data model validation (EvidenceData, PersonData, StatementData, EventData, etc.)
- Enum correctness
- Manager query functions (CaseManager lookups, GameState transitions)
- Evidence comparison logic
- Warrant threshold calculations
- Prosecutor confidence score calculations
- Timeline contradiction detection
- Action availability checks
- Lab processing logic
- Interrogation trigger matching

**Naming convention:**
```
test_<system>_<behavior>.gd

Examples:
test_evidence_data_validates_required_fields.gd
test_case_manager_returns_evidence_by_id.gd
test_warrant_system_requires_two_categories.gd
test_confidence_score_weights_evidence_correctly.gd
```

**Example unit test:**
```gdscript
extends GutTest

var case_manager: CaseManager

func before_each():
    case_manager = CaseManager.new()
    case_manager.load_case("test_case")

func test_get_evidence_by_id_returns_correct_evidence():
    var evidence = case_manager.get_evidence("ev_fingerprint_glass")
    assert_not_null(evidence)
    assert_eq(evidence.id, "ev_fingerprint_glass")
    assert_eq(evidence.type, EvidenceType.FORENSIC)

func test_get_evidence_by_invalid_id_returns_null():
    var evidence = case_manager.get_evidence("nonexistent")
    assert_null(evidence)

func test_get_evidence_for_person_returns_related_items():
    var evidence_list = case_manager.get_evidence_for_person("p_julia")
    assert_gt(evidence_list.size(), 0)
    for ev in evidence_list:
        assert_has(ev.related_persons, "p_julia")
```

#### 2.2 — Integration Tests

Test that systems work correctly together.

**What to integration test:**
- Evidence discovered at location → appears in archive → usable in interrogation → placeable on board
- Lab request submitted → day advances → results arrive → new evidence created
- Warrant requested → evidence threshold validated → approved/denied → new content unlocked
- Interrogation trigger → statement logged → contradiction detectable → pressure accumulates
- Day transition → delayed actions process → events fire → morning briefing updates
- Timeline event placed → contradiction detected → theory builder flags inconsistency
- Theory submitted → confidence score calculated → prosecutor responds correctly

**Example integration test:**
```gdscript
extends GutTest

var game_state: GameState
var case_manager: CaseManager
var lab_system: LabSystem

func before_each():
    game_state = GameState.new()
    case_manager = CaseManager.new()
    lab_system = LabSystem.new()
    case_manager.load_case("test_case")
    game_state.current_day = 1

func test_lab_request_produces_result_next_day():
    # Submit evidence to lab
    var request = lab_system.submit("ev_wine_glass", "fingerprint_analysis")
    assert_not_null(request)
    assert_eq(request.completion_day, 2)

    # Advance day
    game_state.advance_day()
    lab_system.process_day(game_state.current_day)

    # Verify result
    var result = lab_system.get_result(request.id)
    assert_not_null(result)
    assert_true(game_state.discovered_evidence.has(result.output_evidence_id))
```

#### 2.3 — Scenario Tests

Test complete gameplay sequences that simulate real player behavior.

**What to scenario test:**
- Player solves case via timeline path (camera → elevator → shoe prints)
- Player solves case via physical evidence path (wine glass → fingerprints → lie)
- Player solves case via motive path (embezzlement → confrontation → emotional reaction)
- Player accuses wrong suspect → correct outcome
- Player runs out of time → soft pressure → forced theory
- Player achieves perfect confidence score
- Player achieves weak confidence score

**Example scenario test:**
```gdscript
extends GutTest

func test_timeline_investigation_path_reaches_correct_conclusion():
    var game = create_test_game()

    # Day 1: Visit crime scene, interrogate Sarah
    game.perform_action("visit_crime_scene")
    game.perform_action("interrogate_sarah")
    game.advance_day()

    # Day 2: Review lab results, interrogate Mark with camera evidence
    game.process_morning()
    assert_true(game.state.discovered_evidence.has("ev_fingerprint_glass"))
    game.perform_action("interrogate_mark")
    game.present_evidence("interrogate_mark", "ev_parking_camera")
    # ... continue sequence

    # Verify final state allows correct accusation
    var report = game.build_case_report("p_julia", "financial_dispute", "kitchen_knife")
    assert_gte(report.confidence_score, 70)
```

#### 2.4 — Regression Tests

When a bug is found and fixed, write a test that reproduces the bug.

**Process:**
1. Bug is discovered (during development or playtesting)
2. Write a failing test that reproduces the exact bug
3. Fix the bug
4. Verify the test passes
5. The test remains in the suite permanently

**Naming convention:**
```
test_regression_<bug_description>.gd

Example:
test_regression_evidence_not_appearing_after_lab_result.gd
test_regression_day_advance_skips_mandatory_check.gd
```

### Test Execution Rules

| When                           | What to Run                    |
|--------------------------------|-------------------------------|
| After implementing a feature   | All unit tests for that system |
| After integrating systems      | All integration tests          |
| Before committing              | Full test suite                |
| Before ending a phase          | Full suite + manual playthrough|
| After fixing a bug             | Regression test + full suite   |

### Test Coverage Goals

| System                    | Minimum Coverage |
|---------------------------|-----------------|
| Data models               | 95%             |
| Manager query functions    | 90%             |
| Game logic (warrants, lab) | 90%             |
| Confidence score calc      | 95%             |
| Action availability        | 85%             |
| Timeline contradiction     | 90%             |
| Interrogation triggers     | 95%             |
| UI controllers             | Manual testing  |

UI elements are tested manually because Godot's UI testing is limited. Logic behind UI is unit tested.

### 2.5 — UI Theme Token Workflow

To keep UI colors and font sizes unified and maintainable:

- `scripts/ui/ui_colors.gd` and `scripts/ui/ui_fonts.gd` are the source of truth.
- `resources/themes/main_theme.tres` remains a serialized Godot resource with concrete values.
- Never write `UIColors.*` or `UIFonts.*` references directly in `.tres` files.

After updating tokens, sync the theme with:

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "/Users/aisa/DetectiveGame/detective-game" -s tools/run_theme_token_sync.gd
```

Then run the related unit test(s) before integrating changes.

---

## 3. Git Workflow

Don't do any git operations. The user will do all commiting, pulling and pushing.

---

## 4. Code Standards (GDScript)

### File Organization

```gdscript
# 1. Class documentation comment
## Brief description of what this class does.

# 2. Class name (if applicable)
class_name EvidenceData

# 3. Extends
extends Resource

# 4. Signals
signal evidence_discovered(evidence_id: String)

# 5. Enums
enum EvidenceType { FORENSIC, DOCUMENT, PHOTO, RECORDING, FINANCIAL, DIGITAL, OBJECT }

# 6. Constants
const MAX_TAGS := 10

# 7. Exported variables (inspector-editable)
@export var id: String = ""
@export var name: String = ""

# 8. Public variables
var is_discovered: bool = false

# 9. Private variables (prefix with _)
var _internal_state: int = 0

# 10. Built-in virtual methods (_ready, _process, etc.)
func _ready() -> void:
    pass

# 11. Public methods
func discover() -> void:
    is_discovered = true
    evidence_discovered.emit(id)

# 12. Private methods (prefix with _)
func _validate() -> bool:
    return id != "" and name != ""
```

### Naming Conventions

| Element          | Convention          | Example                    |
|------------------|--------------------|-----------------------------|
| Files            | snake_case         | `evidence_data.gd`          |
| Classes          | PascalCase         | `EvidenceData`              |
| Functions        | snake_case         | `get_evidence_by_id()`      |
| Variables        | snake_case         | `current_day`               |
| Constants        | UPPER_SNAKE_CASE   | `MAX_INVESTIGATION_DAYS`    |
| Signals          | snake_case (past)  | `evidence_discovered`       |
| Enums            | PascalCase         | `EvidenceType`              |
| Enum values      | UPPER_SNAKE_CASE   | `EvidenceType.FORENSIC`     |
| Private members  | _prefix            | `_internal_cache`           |
| Nodes            | PascalCase         | `EvidenceArchivePanel`      |
| Scenes           | snake_case         | `evidence_archive.tscn`     |
| Resources        | snake_case         | `ev_fingerprint_glass.tres` |

### Type Hints

Always use type hints. No exceptions for a commercial project.

```gdscript
# Good
func get_evidence(id: String) -> EvidenceData:
    return _evidence_cache.get(id, null)

# Bad
func get_evidence(id):
    return _evidence_cache.get(id, null)
```

### Documentation

All public functions must have doc comments:

```gdscript
## Returns the evidence item with the given ID.
## Returns null if no evidence with that ID exists.
func get_evidence(id: String) -> EvidenceData:
    return _evidence_cache.get(id, null)
```

### Error Handling

- Use `assert()` in debug builds for development-time checks
- Use explicit null checks and return values for runtime safety
- Log warnings with `push_warning()` for recoverable issues
- Log errors with `push_error()` for serious problems
- Never silently swallow errors

```gdscript
func present_evidence(suspect_id: String, evidence_id: String) -> InterrogationReaction:
    var suspect = _case_manager.get_person(suspect_id)
    if suspect == null:
        push_error("Suspect not found: %s" % suspect_id)
        return null

    var evidence = _game_state.get_discovered_evidence(evidence_id)
    if evidence == null:
        push_warning("Evidence not discovered yet: %s" % evidence_id)
        return null

    return _find_matching_trigger(suspect, evidence)
```

---

## 5. Data Management

### Case Data Pipeline

Case narrative data (evidence descriptions, dialogue, statements, triggers) should be authored in JSON and imported into Godot Resources.

**Why:** Writing narrative content in Godot's inspector is slow and error-prone. JSON allows rapid iteration, version control diffs, and potential external editor tools.

**Pipeline:**
```
JSON files (authored) → Import script → Godot Resources (.tres)
```

**JSON location:**
```
/data
├── /cases
│   └── riverside_murder.json
├── /persons
│   └── persons.json
├── /evidence
│   └── evidence.json
├── /interrogations
│   └── interrogations.json
└── /events
    └── events.json
```

### Resource Naming

```
<type>_<identifier>.tres

Examples:
ev_fingerprint_glass.tres
person_julia_ross.tres
stmt_mark_left_early.tres
loc_victim_apartment.tres
```

---

## 6. Debug Tools

Debug tools are essential for efficient development and testing. Build them early (Phase 0) and extend them as systems are added.

### Debug Panel (F1 Hotkey)

Accessible in development builds only. Features:

| Category        | Actions                                    |
|-----------------|--------------------------------------------|
| Time            | Advance day, set time slot, skip to Day X  |
| Evidence        | Unlock specific evidence, unlock all        |
| Interrogation   | Reset interrogation, skip to trigger        |
| Lab             | Complete all requests instantly             |
| Warrants        | Grant any warrant                           |
| Events          | Trigger specific event, list pending events |
| State           | Print full game state, export to JSON       |

### Evidence Checklist (Developer View)

A panel showing all 25 evidence items with discovery status:

```
E1  ✓ Murder Weapon (Kitchen Knife)
E2  ✓ Two Wine Glasses
E3  ✗ Julia's Fingerprint on Wine Glass
E4  ✓ Mark's Fingerprint on Desk
...
```

This verifies that all evidence items are discoverable through normal gameplay.

### Console Logging

Use structured logging for debugging:

```gdscript
func _log(system: String, message: String) -> void:
    print("[%s] %s: %s" % [Time.get_time_string_from_system(), system, message])

# Usage:
_log("LAB", "Processing request: %s" % request.id)
_log("INTERROGATION", "Trigger fired: %s for %s" % [trigger.id, suspect.name])
```

---

## 7. Quality Gates

### Per-Feature Gate (before committing)

- [ ] Feature works as described in the Development Plan
- [ ] Unit tests written and passing
- [ ] Integration tests written (if system interacts with others)
- [ ] No regressions in existing tests
- [ ] Code follows naming conventions and style guide
- [ ] Public functions have doc comments
- [ ] Debug tools updated if needed

### Per-Phase Gate (before moving to next phase)

- [ ] All features in the phase are complete
- [ ] All phase tests pass (unit + integration)
- [ ] Manual playthrough of affected systems succeeds
- [ ] Save/load works with new data
- [ ] No known critical bugs remain
- [ ] Phase deliverables documented as complete

### Pre-Release Gate (before any public build)

- [ ] Full test suite passes
- [ ] Complete playthrough from Day 1 to all four endings
- [ ] All 25 evidence items discoverable
- [ ] All interrogation triggers functional
- [ ] All warrant scenarios tested
- [ ] Save/load across all states
- [ ] Performance acceptable on target platforms
- [ ] No placeholder assets remaining
- [ ] Build exports work on Windows, macOS, Linux

---

## 8. Bug Tracking

### Bug Report Format

```
Title: [System] Short description
Severity: Critical / Major / Minor / Cosmetic
Steps to Reproduce:
1. ...
2. ...
3. ...
Expected: What should happen
Actual: What actually happens
Day/State: In-game day and time slot when bug occurs
Save File: Attached if available
```

### Severity Definitions

| Severity | Definition                                          | Response Time |
|----------|-----------------------------------------------------|---------------|
| Critical | Game crashes, data loss, save corruption             | Fix immediately|
| Major    | Core system broken, blocks progression               | Fix before next phase |
| Minor    | Feature works incorrectly but has workaround         | Fix before playtesting |
| Cosmetic | Visual glitch, typo, minor UI issue                  | Fix before release |

### Bug Fix Process

1. Reproduce the bug
2. Write a failing test that captures the bug
3. Fix the bug
4. Verify the test passes
5. Run full test suite to check for regressions

---

## 9. Asset Workflow (Midjourney Integration)

### Placeholder-First Pipeline

All development uses placeholder assets until systems are stable.

**Placeholder creation:**
- Correct dimensions for the target use
- Solid neutral color background
- Clear text label describing the asset
- Consistent naming convention

**Example:**
```
placeholder_portrait_julia_neutral.png     → 512x512, gray, "Julia Ross — Neutral"
placeholder_evidence_wine_glass.png        → 512x512, gray, "E2 — Wine Glasses on Table"
placeholder_location_apartment.png         → 1920x1080, gray, "Victim Apartment — Kitchen"
```

### Midjourney Batch Workflow

Generate art in system-specific batches:

| Batch | Assets                  | Priority | Needed For      |
|-------|-------------------------|----------|-----------------|
| 1     | Suspect portraits       | High     | Interrogation    |
| 2     | Evidence photographs    | High     | Evidence archive  |
| 3     | Location backgrounds    | Medium   | Location scenes   |
| 4     | UI textures             | Medium   | All screens       |

### Style Consistency

Every Midjourney prompt includes the base style suffix:

```
semi-realistic detective game art,
modern noir atmosphere,
soft cinematic lighting,
cool desaturated colors,
high detail illustration,
grainy film texture
```

### Asset Replacement Process

1. Develop with placeholders
2. Lock UI layouts and sizes
3. Generate Midjourney batch
4. Review for style consistency
5. Post-process in Krita/Photoshop (color grading, grain)
6. Replace placeholder files (keep identical filenames)
7. Verify in-game appearance

---

## 10. Documentation Practices

### Living Documents

These documents are updated continuously:

| Document                           | Purpose                                        |
|------------------------------------|------------------------------------------------|
| Detective Investigation Game.md    | Game design document (source of truth)          |
| Development Plan.md                | Phase-by-phase implementation plan              |
| Way of Working.md                  | This document — development practices           |

### Phase Completion Notes

After completing each phase, add a brief completion note:

```
Phase X completed: [date]
Notes: [any deviations, decisions, or lessons learned]
```

### Decision Log

When making a design or technical decision that deviates from the plan, document it:

```
Decision: [what was decided]
Reason: [why]
Impact: [what systems are affected]
Date: [when]
```

---

## 11. Session Workflow

### Starting a Development Session

1. Pull latest from `develop`
2. Check todo list — what's the current task?
3. Run the full test suite — everything should be green
4. Begin work on the current task

### During Development

1. Work on one task at a time
2. Write tests alongside code (not after)
3. Run relevant tests frequently
4. Update todo list as tasks complete

### Ending a Development Session

1. Run full test suite
2. Update todo list with current status
3. Note any blockers or open questions

---

## 12. Performance Monitoring

### Key Metrics to Watch

| Metric                    | Target         | Check When           |
|---------------------------|----------------|----------------------|
| Scene load time           | < 1 second     | Adding new scenes    |
| Evidence archive scroll   | 60 FPS         | Adding evidence      |
| Board with 20+ nodes      | 60 FPS         | Board development    |
| Save file size            | < 1 MB         | Adding save data     |
| Memory usage              | < 500 MB       | Adding art assets    |

### Image Asset Guidelines

| Asset Type          | Resolution  | Format       |
|---------------------|-------------|-------------- |
| Location background | 1920×1080   | PNG/WebP      |
| Suspect portrait    | 512×512     | PNG/WebP      |
| Evidence photo      | 512×512     | PNG/WebP      |
| UI texture          | Tiling      | PNG           |
| Board node icon     | 128×128     | PNG           |

Use Godot's import compression settings to manage memory.

---

## Summary

This Way of Working ensures:

- **Quality** — automated tests catch regressions before they reach players
- **Consistency** — code standards and naming conventions keep the codebase clean
- **Traceability** — every bug fix has a test, every decision is documented
- **Efficiency** — debug tools and structured workflows reduce wasted time
- **Commercial readiness** — quality gates ensure nothing ships broken
