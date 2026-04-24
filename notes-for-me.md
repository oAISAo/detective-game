Please use relevant skill files located in: .agents/skills
Codex will review your output once you are done.


Copy output of tests:

/Applications/Godot.app/Contents/MacOS/Godot \
  --path "/Users/aisa/DetectiveGame/detective-game" \
  -s addons/gut/gut_cmdln.gd \
  > gut_test_log.txt 2>&1


  Workflow A — New feature / phase

Example: interrogation, story system, warrants

Step 1

Ask in Plan mode:

Inspect the current implementation first.
Compare it against the development plan and identify what is missing, incorrect, fragile, or non-production-ready.
Then propose the implementation plan before editing files.

Step 2

Review plan

Step 3

Then tell it:

Implement the plan now. Keep it data-driven and production-ready. Add/update tests for all changed behavior.

This prevents “YOLO coding.”

Workflow B — Bugfix

Example: pressure button not enabling

Prompt pattern:

Reproduce the bug from the current code.
Find the root cause, not just the symptom.
Fix it in the cleanest architecture-safe way.
Add a regression test.

That phrase “root cause, not symptom” matters a lot.

Workflow C — UI polish

Example: focus highlights, layout fixes

Prompt pattern:

Improve this UI to production quality.
Do not change underlying game logic unless necessary.
Focus on clarity, hierarchy, interaction feedback, and consistency.

Workflow D — Big content import

Example: story JSON, evidence, suspects, triggers

Best move:

Ask it to first generate:

JSON/data resources

validation tests

debug scenario

before it tries to wire everything into gameplay.

That keeps the project stable.


# TEMPLATE FOR BUGFIX:

We need to fix a bug in the project.

IMPORTANT:
This project is commercial / production-ready.
Do not patch symptoms or add brittle special cases.
Think before coding.
Inspect the current implementation first and identify the root cause.
All bug fixes must include tests.

## Context
[Describe where the bug happens]
Example:
The bug happens in the interrogation screen for Mark Bennett.

## Expected behavior
[Describe exactly what should happen]
Example:
When the player presents Parking Lot Camera Footage against Mark’s departure statement, pressure should increase by +1, the corrected statement should be added, and the topic "Why did you lie about the time?" should unlock.

## Actual behavior
[Describe exactly what currently happens]
Example:
Pressure increases, but Apply Pressure never becomes enabled later even after the threshold is reached.

## Reproduction steps
1. [Step 1]
2. [Step 2]
3. [Step 3]

Example:
1. Start debug scenario `debug_mark_interrogation_full`
2. Open Suspects → Mark Bennett
3. Ask “What time did you leave?”
4. Present `ev_parking_camera`
5. Ask “Why did you lie about the time?”
6. Present `ev_bank_transfer`
7. Observe that Apply Pressure is still disabled

## What I want you to do
1. Inspect the relevant code and data files first
2. Find the root cause
3. Fix it in the cleanest architecture-safe way
4. Preserve the data-driven design
5. Add/update automated tests so this bug cannot regress
6. If UI is involved, improve the UX if needed, but do not introduce hacks

## Constraints
- Do not hardcode this fix only for one suspect unless absolutely necessary
- Keep the implementation reusable for future cases/suspects
- Do not break save compatibility unless unavoidable
- Do not introduce temporary debug-only logic into production systems

## Deliverable
After implementing, summarize:
1. Root cause
2. Files changed
3. What was fixed
4. Tests added/updated
5. How I should manually verify the fix



# TEMPLATE FOR FEATURE

We need to implement a new feature/system in the project.

IMPORTANT:
This project is commercial / production-ready.
Do not take the quickest or easiest shortcut.
Think before coding.
Inspect the current implementation first and compare it against the development plan before editing.
All new behavior must be backed by automated tests.

## Feature to implement
[Name of feature/system]
Example:
Debug Game Start + Configurable Debug Scenario System

## Goal
[What the feature should accomplish]
Example:
Allow starting the game from a deterministic debug state so systems like interrogation, warrants, timeline, and evidence progression can be tested without replaying the full case every time.

## Current project context
[Describe what already exists]
Example:
The game already has:
- a main menu
- a day/time system
- evidence inventory
- suspects/interrogation screen
- story events
- JSON-driven content

The project already includes placeholder assets and the general architecture should remain reusable for future cases.

## Required behavior
[Describe exact expected behavior]

Example:
1. Main menu should include a "Debug Game" button
2. Clicking it should load a debug scenario from JSON
3. A debug scenario should be able to specify:
   - current day
   - current time phase
   - available locations
   - unlocked interrogations
   - discovered evidence
   - completed story events
   - mandatory tasks
   - optional timeline/testimony state if needed
4. The debug state should cleanly initialize the game as if the player had legitimately reached that point

## Data / Architecture requirements
[How it should be structured]
Example:
- Keep this data-driven
- Add or extend JSON/config resources instead of hardcoding state
- The system must support future debug scenarios for other suspects and future cases
- Validate debug scenario IDs and fail gracefully if invalid

## UI / UX requirements
[Optional]
Example:
- "Debug Game" should only appear in development/debug builds, not release builds
- If no debug scenarios exist, disable the button or show a clear message
- Avoid cluttering the main menu in release mode

## Technical requirements
[Optional but useful]
Example:
- Keep save system compatibility intact
- Reuse existing game state initialization if possible
- Avoid duplicating case bootstrapping logic
- Prefer a clean entry point for state injection

## Tests required
At minimum, add/update tests for:
1. [Test 1]
2. [Test 2]
3. [Test 3]

Example:
1. Loading a valid debug scenario correctly sets day/time
2. Debug scenario correctly grants evidence and unlocks suspect interrogations
3. Invalid debug scenario ID fails gracefully
4. Debug start initializes the same systems as a normal start

## Deliverable
After implementing, summarize:
1. What you added
2. Files changed
3. Tests added/updated
4. How I should manually test it