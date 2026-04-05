# Detective Game - Project Memory

## Project Type
Godot 4.6 detective investigation game (GDScript). Uses GUT 9.6 for testing.

## Key Architecture
- **Data**: JSON files in `data/cases/riverside_apartment/` (case.json, suspects.json, evidence.json, events.json, locations.json, timeline.json, discovery_rules.json)
- **Data Models**: `scripts/data/*.gd` — Resource classes (EvidenceData, PersonData, StatementData, InterrogationTriggerData, etc.)
- **Managers**: `scripts/managers/*.gd` — Autoload singletons (CaseManager, GameManager, InterrogationManager, LabManager, LocationInvestigationManager, etc.)
- **Systems**: `scripts/systems/*.gd` — DaySystem, EventSystem, ActionSystem
- **UI Screens**: `scripts/ui/screens/*.gd` with matching scenes in `scenes/ui/*.tscn`
- **Tests**: `tests/unit/` and `tests/scenario/` (GUT framework)

## Interrogation System
- Triggers are defined in `events.json` under `interrogation_triggers`
- Each trigger has `person_id`, `evidence_id`, `target_statement_id`, `target_topic_id`, `requires_statement_id`
- `CaseManager.get_trigger_by_evidence_and_focus()` matches on focus type+id
- `present_evidence()` returns reasons: `wrong_evidence`, `wrong_focus`, `prerequisite_not_met`, `already_fired`
- Sarah's progression: camera→stmt_sarah_confronted, shoe_print→stmt_sarah_footsteps, apply_pressure→break→stmt_sarah_saw_woman

## Evidence Lifecycle
- Raw evidence discovered at locations → submitted to lab → upgraded in place to analyzed version
- `GameManager.upgrade_evidence()` replaces raw with analyzed at same array position
- `evidence_upgraded` signal emitted on upgrade
- Location completion counts handle upgraded evidence via lab_request lookup

## Running Tests
```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd
```

## Key Patterns
- Branch: `progress2` is the working branch
- Scenes use `unique_name_in_owner` with `%NodeName` syntax for node references
- UIColors and UIHelper are utility autoloads for consistent styling
