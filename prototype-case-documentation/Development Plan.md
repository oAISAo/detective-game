# Detective Investigation Game — Development Plan (v2)

## Engine: Godot 4.x (GDScript)

This document outlines every step needed to successfully build a commercial-quality detective investigation game. The plan incorporates all design feedback and is organized into sequential phases, each with clear goals, tasks, deliverables, and testing requirements.

**Key changes from v1:**
- Morning is no longer an action slot (2 actions/day × 4 days = 8 total major actions)
- Story Event System moved earlier (Phase 3, immediately after Day System)
- Phase 4 (UI Shell) split into 4A (core) and 4B (advanced)
- Evidence System and Location System cleanly separated
- Theory Builder redesigned from form → narrative steps
- Detective Board scope reduced for prototype
- Placeholder Asset Phase added before art production
- New data types added: InterrogationTopicData, InvestigableObjectData, ActionData, EventTriggerData, InsightData
- Debug tools, testing, and quality gates integrated into every phase
- All actions are data-driven via ActionData resources

---

## Phase 0 — Project Setup & Foundation

**Duration:** 1–2 weeks
**Goal:** Establish the project structure, tooling, testing framework, and technical foundation.

### Tasks

1. **Install and configure Godot 4.x** (latest stable release)
2. **Create the Godot project** with the following folder structure:
   ```
   /project
   ├── /scenes
   │   ├── /core             — Root game scene, application container
   │   │   └── game_root.tscn
   │   ├── /ui               — UI screens and panels
   │   ├── /locations         — Location investigation scenes
   │   └── /interrogation     — Interrogation scenes
   ├── /scripts
   │   ├── /managers          — Global state controllers (singletons)
   │   │   ├── GameManager.gd
   │   │   ├── CaseManager.gd
   │   │   ├── SaveManager.gd
   │   │   └── NotificationManager.gd
   │   ├── /systems           — Gameplay logic
   │   │   ├── DaySystem.gd
   │   │   ├── ActionSystem.gd
   │   │   ├── LabSystem.gd
   │   │   ├── WarrantSystem.gd
   │   │   ├── SurveillanceSystem.gd
   │   │   └── ToolManager.gd
   │   ├── /data              — Resource class definitions
   │   ├── /ui                — UI controller scripts
   │   └── /debug             — Debug tools (dev builds only)
   │       ├── DebugPanel.gd
   │       └── EvidenceChecklist.gd
   ├── /resources
   │   ├── /case_data         — Case definitions
   │   ├── /evidence          — Evidence resources
   │   ├── /persons           — Person resources
   │   └── /themes            — UI themes
   ├── /assets
   │   ├── /art               — Illustrations, portraits, scenes
   │   ├── /evidence_images   — Evidence photographs
   │   ├── /audio             — Music, SFX, ambience
   │   └── /fonts             — Typography assets
   ├── /data                  — JSON source files for case data
   │   ├── /cases
   │   ├── /persons
   │   ├── /evidence
   │   ├── /interrogations
   │   └── /events
   └── /tests                 — GUT test files
       ├── /unit
       ├── /integration
       └── /scenario
   ```
3. **Set up version control** (Git + GitHub/GitLab)
4. **Install and configure GUT** (Godot Unit Testing framework)
5. **Create game_root.tscn** — the main application container containing:
   - Global UI layer (command bar, notifications)
   - Scene switching container
   - Background music player
   - Modal dialog layer
6. **Define the global UI theme** — fonts, colors, button styles matching the noir visual style
7. **Create the base resolution and scaling settings** (1920×1080 with UI scaling)
8. **Set up autoloads (singletons):** GameManager, CaseManager, SaveManager, NotificationManager
9. **Create basic debug panel** (F1 hotkey) — initially empty, extended in each phase

### Deliverables
- Godot project with organized structure
- Git repository initialized with branching strategy
- GUT testing framework configured and running
- game_root.tscn as application container
- Base UI theme configured (deep charcoal, muted navy, cold gray palette)
- All autoloads registered
- Debug panel scaffold accessible via F1

### Tests
- Verify GUT framework runs and reports results
- Verify autoloads are accessible from any scene
- Verify game_root.tscn loads without errors

---

## Phase 1 — Data Architecture & Core Models

**Duration:** 2–3 weeks
**Goal:** Build the data backbone that every system depends on.

This is the most important technical foundation. Every system reads from these data structures.

### 1.1 — Define Custom Resource Types

| Resource Class            | Key Fields                                                                 |
|---------------------------|---------------------------------------------------------------------------|
| `CaseData`                | id, title, description, start_day, end_day, suspects[], persons[], locations[], evidence[], statements[], events[], event_triggers[] |
| `PersonData`              | id, name, role (enum), personality_traits[], relationships[], pressure_threshold (int) |
| `EvidenceData`            | id, name, description, type (enum), location_found, discovered_day, related_persons[], tags[], lab_status, lab_result_text, requires_lab_analysis (bool), image, weight (float), importance_level (enum), discovery_method (enum), legal_categories[] |
| `StatementData`           | id, person_id, text, day_given, related_evidence[], related_event |
| `EventData`               | id, description, time, day, location, involved_persons[], supporting_evidence[], certainty_level (enum) |
| `LocationData`            | id, name, searchable (bool), investigable_objects[], evidence_pool[] |
| `InvestigableObjectData`  | id, name, description, available_actions[], tool_requirements[], evidence_results[], investigation_state (enum) |
| `RelationshipData`        | person_a, person_b, type (enum) |
| `InterrogationTopicData`  | id, person_id, topic_name, trigger_conditions[], unlock_evidence[], statements[], required_evidence[], requires_statement_id, impact_level (enum) |
| `ActionData`              | id, name, type (enum), time_cost (int), target, requirements[], results[] |
| `EventTriggerData`        | id, trigger_type (enum), trigger_day, conditions[], actions[], result_events[] |
| `InsightData`             | id, description, source_evidence[], strengthens_theory, enables_warrant, unlocks_topic |
| `LabRequestData`          | id, input_evidence_id, analysis_type, day_submitted, completion_day, output_evidence_id |
| `SurveillanceRequestData` | id, target_person, type (enum), day_installed, active_days (int), result_events[] |

### 1.2 — Define Enums

```
EvidenceType: FORENSIC, DOCUMENT, PHOTO, RECORDING, FINANCIAL, DIGITAL, OBJECT
PersonRole: VICTIM, SUSPECT, WITNESS, INVESTIGATOR, TECHNICIAN
RelationshipType: SPOUSE, COWORKER, BUSINESS_PARTNER, FRIEND, ENEMY, FAMILY
LabStatus: NOT_SUBMITTED, PROCESSING, COMPLETED
PersonalityTrait: AGGRESSIVE, ANXIOUS, MANIPULATIVE, CALM
ImportanceLevel: CRITICAL, SUPPORTING, OPTIONAL
DiscoveryMethod: VISUAL, TOOL, COMPARISON, LAB, SURVEILLANCE
CertaintyLevel: CONFIRMED, LIKELY, CLAIMED, UNKNOWN
ImpactLevel: MINOR, MAJOR, BREAKPOINT
InvestigationState: NOT_INSPECTED, PARTIALLY_EXAMINED, FULLY_EXAMINED
ActionType: INTERROGATION, VISIT_LOCATION, SEARCH_LOCATION, EXAMINE_DEVICE, ANALYZE_EVIDENCE
DayPhase: MORNING, DAYTIME, NIGHT
TriggerType: TIMED, CONDITIONAL, DAY_START
LegalCategory: PRESENCE, MOTIVE, OPPORTUNITY, CONNECTION
ReactionType: DENIAL, ADMISSION, ANGER, PANIC, SILENCE, REVELATION, PARTIAL_CONFESSION, DEFLECTION
SurveillanceType: PHONE_TAP, HOME_SURVEILLANCE, FINANCIAL_MONITORING
```

### 1.3 — Build the Case Loader

- Create JSON → Resource import pipeline for case data
- CaseManager singleton loads all case data at game start
- Query functions: `get_evidence(id)`, `get_person(id)`, `get_statements_by_person(id)`, `get_events_for_day(day)`, `get_evidence_for_person(id)`, `get_evidence_by_location(id)`

### 1.4 — Build the Game State Manager

Track the dynamic state of the investigation:

```
current_day: int
current_phase: DayPhase
actions_remaining: int
discovered_evidence: Array[String]
discovered_insights: Array[String]
visited_locations: Array[String]
completed_interrogations: Dictionary
interrogation_counts_today: Dictionary
active_lab_requests: Array[LabRequestData]
active_surveillance: Array[SurveillanceRequestData]
mandatory_actions_required: Array[String]
mandatory_actions_completed: Array[String]
warrants_obtained: Array[String]
player_board_state: Dictionary
player_timeline: Array
player_theories: Array
investigation_log: Array[Dictionary]
hints_used: int
```

### 1.5 — Save/Load System

Save data is separated into logical sections for easier debugging:

```
save_data
 ├─ save_version: int
 ├─ game_state
 ├─ player_board
 ├─ player_timeline
 └─ player_theories
```

- Version number on every save file
- On load: check version compatibility, warn player if mismatch
- Support 3 save slots

### 1.6 — Add Debug Tools

Extend the debug panel with:
- Unlock specific evidence by ID
- Unlock all evidence
- Print full game state to console
- Export game state to JSON

### Deliverables
- All Resource classes created and validated
- JSON → Resource import pipeline working
- CaseManager singleton with query functions
- GameState manager tracking all investigation state
- Save/Load system with versioning and 3 slots
- Debug panel: evidence unlock, state export

### Tests
- **Unit:** Each Resource class validates required fields correctly
- **Unit:** CaseManager returns correct data for all query functions
- **Unit:** CaseManager returns null for invalid IDs
- **Unit:** GameState initializes with correct defaults
- **Unit:** Save serialization → deserialization produces identical state
- **Unit:** Save version mismatch is detected
- **Integration:** JSON case data imports into valid Resource objects

---

## Phase 2 — Investigation Day System & Game Loop

**Duration:** 2 weeks
**Goal:** Implement the core time progression and action economy.

### 2.1 — Day Structure

```
Day 1–4
  ├── Morning   → Automatic: narrative delivery, lab results, surveillance, story events
  ├── Afternoon → Player action (1 major action slot)
  ├── Evening   → Player action (1 major action slot)
  └── Night     → System processing: delayed actions advance, timers tick
```

**Morning is NOT an action slot.** It is narrative delivery time.
The player gets **2 major actions per day** → **8 total actions across 4 days.**
This forces strong investigative choices.

### 2.2 — Data-Driven Action System

All actions are defined via `ActionData` resources, not hardcoded logic.

**Major Actions** (cost 1 time slot):
- Interrogate suspect
- Visit location (entry is free; each investigation action performed there costs 1)
- Search location
- Examine digital device
- Analyze evidence group

**Passive Actions** (cost 0 — available anytime):
- Review evidence archive
- Organize detective board
- Build timeline
- Read lab reports
- Review investigation log

**Delayed Actions** (start now, complete later):
- Lab submissions → results arrive in 1+ days
- Surveillance installations → active for multiple days
- Warrant requests → processed same day

### 2.3 — Action Availability System

Not all actions are visible at all times. The `ActionAvailabilitySystem` checks:
- `requirements[]` on the ActionData
- Current player state (discovered evidence, warrants, etc.)
- Whether prerequisites are met (suspect discovered, warrant approved, etc.)

Only available actions are shown to the player.

### 2.4 — Mandatory Actions as Event Dependencies

Instead of a rigid checklist, mandatory tasks are `EventTriggerData` conditions:

```
EventTrigger:
  conditions: action_completed("interrogate_sarah")
  result: enable_event("day_2_morning_briefing")
```

If mandatory conditions are not met, the day cannot advance. The UI clearly shows remaining requirements.

### 2.5 — Day Transition (Night Processing)

When all slots are used (or player chooses to end day):
1. Process delayed actions (advance lab/surveillance timers)
2. Evaluate event triggers for the next day
3. Advance `current_day`
4. Set `current_phase` to MORNING
5. Queue morning briefing content

### 2.6 — Investigation Log

Chronological record of all player actions:

```
Day 1 — Afternoon: Visited crime scene.
Day 1 — Evening: Interrogated Sarah Klein.
Day 2 — Morning: Lab results received: fingerprints on glass.
```

Displayed in a dedicated Investigation Log screen.

### 2.7 — End-of-Game Soft Pressure

On Day 4, if the case is unsolved:
- Chief delivers pressure dialogue
- Player gets one final investigation phase
- Must submit theory

### 2.8 — Debug Tools Extension

- Advance to any day
- Set time slot
- Skip to Night processing
- Force complete mandatory actions

### Deliverables
- Day cycle (Day 1–4) with Morning/Afternoon/Evening/Night
- Data-driven action system via ActionData
- Action availability system with prerequisite checking
- Mandatory action tracking via event dependencies
- Day transition with delayed action processing
- Investigation log system
- End-of-investigation pressure

### Tests
- **Unit:** Day advances correctly through all time slots
- **Unit:** Action costs deducted correctly (major = 1, passive = 0)
- **Unit:** Action availability correctly filters based on requirements
- **Unit:** Mandatory action conditions block day advance when unmet
- **Unit:** Mandatory action conditions allow advance when met
- **Unit:** Night processing advances lab/surveillance timers
- **Unit:** Investigation log records actions in correct order
- **Integration:** Full day cycle from Morning through Night processes correctly
- **Integration:** Delayed actions produce results on the correct day

---

## Phase 3 — Story Event & Notification Systems

**Duration:** 1–2 weeks
**Goal:** Build the event triggering and notification infrastructure that all later systems depend on.

This phase is placed early because almost every system depends on event triggers and notifications. Building it last would require refactoring.

### 3.1 — Unified Event Trigger System

All events use `EventTriggerData` with a consistent structure:

```
EventTrigger:
  trigger_type: TIMED | CONDITIONAL | DAY_START
  conditions: []
  actions: []
```

**Timed events** — fire automatically on a specific day:
```
trigger_type: TIMED
conditions: [day == 2]
actions: [deliver_lab_results, unlock_interrogation_mark]
```

**Conditional events** — fire when player takes specific actions:
```
trigger_type: CONDITIONAL
conditions: [evidence_discovered("ev_financial_records")]
actions: [unlock_event("embezzlement_reveal")]
```

**Day-start events** — fire every morning:
```
trigger_type: DAY_START
conditions: [day == 2]
actions: [show_morning_briefing]
```

### 3.2 — Morning Briefing System

Each morning presents new information as a briefing overlay:

```
Morning Briefing — Day 2

New information:
• Fingerprint analysis completed
• Phone records delivered
• Mark Bennett now available for questioning
```

Player reviews the briefing before starting the day's investigation.

### 3.3 — Notification Manager

A dedicated `NotificationManager` singleton that queues and displays alerts:

```
Lab result ready
New statement unlocked
Surveillance update available
New evidence discovered
Warrant approved
```

Notifications appear in the investigation desk UI. They persist until dismissed.

### 3.4 — Lightweight Dialogue System

Simple dialogue display for story moments (not branching dialogue trees):
- Character portrait + text box + continue button
- Used for: chief communications, technician updates, witness contacts, morning briefings

### 3.5 — Prototype Story Events

| Day | Event                                      | Trigger Type  |
|-----|--------------------------------------------|---------------|
| 1   | Case briefing, crime scene available        | DAY_START     |
| 1   | Sarah available for interrogation           | DAY_START     |
| 2   | Lab results arrive (fingerprints)           | DAY_START     |
| 2   | Phone records delivered                     | DAY_START     |
| 2   | Mark available for interrogation            | DAY_START     |
| 3   | Julia's warrant can be requested            | CONDITIONAL   |
| 3   | Deleted messages recovered                  | CONDITIONAL   |
| 4   | Chief pressure dialogue                     | DAY_START     |
| 4   | Final accusation phase                      | TIMED         |

### 3.6 — Debug Tools Extension

- Trigger any event manually
- List all pending/completed events
- Clear notification queue

### Deliverables
- Event trigger system (timed + conditional + day-start)
- Morning briefing system
- NotificationManager singleton
- Lightweight dialogue display
- All prototype story events defined
- Debug: manual event triggering

### Tests
- **Unit:** Timed events fire on the correct day
- **Unit:** Conditional events fire when conditions are met
- **Unit:** Conditional events do NOT fire when conditions are unmet
- **Unit:** Day-start events fire during morning phase only
- **Unit:** Notifications queue and can be dismissed
- **Integration:** Morning briefing shows correct content for each day
- **Integration:** Day advance → event triggers → notifications appear

---

## Phase 4 — Main UI Shell & Navigation

**Duration:** 2–3 weeks
**Goal:** Build the investigation desk interface the player works from.

Split into two tiers to avoid overbuilding before core gameplay is validated.

### Phase 4A — Core Navigation (Prototype Priority)

Build only the screens required for the first playable case.

**UI Architecture:**

```
game_root
 ├── global_command_bar        — Always visible at top
 ├── desk_hub                  — Investigation desk home screen
 ├── screen_container          — Loaded screens go here
 │    ├── evidence_archive
 │    ├── detective_board
 │    ├── timeline_board
 │    ├── location_map
 │    └── investigation_log
 └── modal_layer               — Overlays on top of everything
      ├── interrogation
      ├── morning_briefing
      └── notifications
```

**Global Command Bar** (always visible at top of screen):

```
Day 2 — Afternoon | Actions left: 1
─────────────────────────────────────
[Evidence] [Board] [Timeline] [Map] [Log] [Interrogate]
```

This prevents players from getting lost.

**Investigation Desk Hub:**
- Day/Time indicator
- Actions remaining counter
- Navigation buttons to all screens
- Notification area (new evidence, lab results, story events)
- Quick-access to pinned evidence

### Phase 4B — Advanced Systems (Added Later)

Added when core gameplay works:
- Theory Builder
- Lab Requests panel
- Surveillance Panel
- Warrant Office
- Case Report submission

### 4.1 — UI Theme Implementation

Apply the visual style guide:
- Dark backgrounds (deep charcoal, muted navy)
- Paper/cardboard textures for panels
- Typewriter/report fonts for official text
- Handwritten font for player annotations
- Subtle film grain overlay
- Warm desk lamp lighting effects on UI panels

### 4.2 — Transition System

- Smooth transitions between screens (fade, slide)
- Screens load into the `screen_container`
- Paper shuffle sound effects on transitions
- Ambient investigation room sounds on desk hub

### Deliverables
- game_root scene with UI architecture
- Global command bar with day/time/actions display
- Investigation desk hub
- Evidence Archive screen (empty shell)
- Detective Board screen (empty shell)
- Timeline Board screen (empty shell)
- Location Map screen (empty shell)
- Investigation Log screen (connected to log data)
- Modal layer for interrogation and briefings
- UI theme applied consistently
- Screen transition system

### Tests
- **Unit:** Navigation correctly loads each screen into container
- **Unit:** Command bar updates when day/time/actions change
- **Unit:** Notification area displays and dismisses correctly
- **Integration:** Screen transitions work without memory leaks
- **Integration:** Modal overlays render above all screens

---

## Phase 5 — Evidence System

**Duration:** 2–3 weeks
**Goal:** Build the evidence data system, archive UI, and comparison mechanics.

This phase focuses on evidence architecture and the archive. Evidence *discovery* is part of Phase 6 (Location System).

### 5.1 — Evidence Archive UI

- Scrollable list/grid of all discovered evidence
- Filter by type (forensic, document, photo, etc.)
- Search by keyword
- Each evidence item shows:
  - Image/photograph
  - Name and description
  - Location found
  - Day discovered
  - Related persons
  - Tags (player-editable)
  - Player notes field
  - Importance indicator (critical/supporting/optional — only visible in debug)

### 5.2 — Evidence Detail View

Full-screen examination of a single evidence item, including:

**Evidence Relationships Panel:**
```
Related Persons:
• Julia Ross
• Mark Bennett

Referenced In:
• Statement S4: "I never entered the kitchen"
• Event E2: Loud argument heard
```

### 5.3 — Evidence Pinning

Quick-access bar for frequently referenced evidence:

```
Pinned Evidence:
[Fingerprint] [Wine Glass] [Elevator Log]
```

Players pin/unpin from the archive or detail view.

### 5.4 — Evidence Comparison System

Player selects two evidence items to compare.

Comparisons produce **Insights**, not always new evidence:
```
Insight: Shoe print size matches Julia's shoe size.
```

Insights can:
- Strengthen theories
- Unlock interrogation topics
- Enable warrant categories
- Be referenced in the Case Report

Valid comparisons are predefined in case data.

### 5.5 — Testimony Section

Statements from interrogations appear in the archive under a "Testimony" tab.

**Contradiction highlighting:**
```
Statement S12: "I left the office at 19:30."
⚠ Possible contradiction — Parking camera shows departure at 20:40
```

The highlight appears when contradicting evidence is discovered. It does not explain the contradiction — the player must interpret it.

### 5.6 — Progressive Discovery Hints

**Hint Budget System:**
```
max_hints_per_case = 3
```

Hints trigger only when:
- Critical evidence is still missing
- Player has advanced at least one day
- Player has already visited the relevant location

Hints are contextual and come from in-world sources:
- Technician: "Did you check the kitchen sink?"
- Chief: "Have you looked closely at the victim's office?"

### 5.7 — Populate Prototype Evidence

Create all 25 evidence items (E1–E25) as JSON data imported into Resources:
- All metadata populated (locations, related persons, weight, importance, legal categories)
- Placeholder evidence images (correct size with text labels)

### 5.8 — Debug Tools Extension

- Unlock specific evidence by ID
- Unlock all evidence
- Evidence checklist view showing discovery status of all 25 items

### Deliverables
- Evidence Archive UI with filtering and search
- Evidence Detail View with relationships panel
- Evidence pinning system
- Evidence comparison → Insight system
- Testimony section with contradiction highlighting
- Progressive discovery hints with budget
- All 25 evidence items populated from JSON
- Debug: evidence checklist

### Tests
- **Unit:** Evidence archive filters correctly by type
- **Unit:** Evidence search returns matching items
- **Unit:** Evidence comparison produces correct Insights
- **Unit:** Invalid comparisons produce no result
- **Unit:** Contradiction highlighting activates when matching evidence is discovered
- **Unit:** Hint budget prevents more than max_hints_per_case hints
- **Unit:** Hint triggers only when conditions are met
- **Unit:** Evidence weight values are within valid range
- **Integration:** Evidence discovered → appears in archive with correct metadata
- **Integration:** Statement added → appears in testimony tab → contradiction check runs

---

## Phase 6 — Location Investigation System

**Duration:** 2–3 weeks
**Goal:** Build the five prototype locations with the evidence discovery pipeline.

### 6.1 — Location Scene Template

Reusable scene structure:
- Background illustration (placeholder initially)
- Interactive object hotspots (clearly indicated, no pixel-hunting)
- Investigation action menu per object
- Location investigation board (tracks what's been found here)
- "Return to desk" navigation
- Location completion indicator on the map

### 6.2 — InvestigableObject System

Each object is data-driven via `InvestigableObjectData`:

```
Object: Kitchen Sink
  available_actions: [visual_inspection, residue_test]
  tool_requirements: [chemical_test]
  evidence_results: [ev_blood_residue]
  investigation_state: NOT_INSPECTED
```

Scenes reference object data rather than hardcoding logic.

### 6.3 — Object Investigation States

Each object tracks its state:

| State                | Marker Color | Meaning                  |
|----------------------|-------------|--------------------------|
| NOT_INSPECTED        | Yellow      | Not yet examined          |
| PARTIALLY_EXAMINED   | Blue        | Some actions performed    |
| FULLY_EXAMINED       | Gray        | All actions completed     |

Visual markers update as the player investigates.

### 6.4 — Investigation Tools (ToolManager)

Tools are managed by a `ToolManager` system, not hardcoded per object.

Available tools:
- Fingerprint Powder
- UV Light
- Chemical Residue Test

Objects declare `tool_requirements[]`. The ToolManager checks:
```
if tool_used AND object_supports_tool → reveal evidence
```

### 6.5 — Location Visit System

- Every visit → free entry to the location investigation screen
- Each inspect/examine/tool investigation action at the location costs 1 action slot

```
Return to Victim's Apartment?
• Enter location (free)
```

### 6.6 — Location Completion Indicator

On the location map:

```
Victim Apartment (6/8 clues found)
```

Does not reveal what's missing — gives progress sense only.

### 6.7 — Build the Five Prototype Locations

| Location            | Objects (≈count) | Key Evidence                    |
|---------------------|------------------|---------------------------------|
| Victim's Apartment  | 6–7              | E1–E6, E22, E23                 |
| Building Hallway    | 3                | E15, E16, E20                   |
| Parking Lot         | 2                | E14                             |
| Neighbor's Apartment| 3                | E17, E18                        |
| Victim's Office     | 5                | E10, E12, E24, E25              |

Total investigable objects: ≈20

### 6.8 — Evidence Discovery Flow

```
Arrive at location → See objects → Select object → Choose action → Evidence generated (if correct)
```

Observation → Question → Examination → Evidence

Multi-layer investigation: initial inspection reveals basic observations, deeper analysis (with tools) uncovers meaningful clues.

### 6.9 — Debug Tools Extension

- Teleport to any location
- Mark all objects as examined
- Reveal all evidence at location

### Deliverables
- Location scene template with all systems
- InvestigableObject data-driven system
- Object investigation states with visual feedback
- ToolManager with three tools
- Location revisit system (free entry, paid investigation actions)
- Location completion indicators
- Five prototype locations built
- Evidence discovery flow working

### Tests
- **Unit:** InvestigableObject returns correct evidence for valid actions
- **Unit:** InvestigableObject returns nothing for invalid actions
- **Unit:** Object state transitions correctly (not_inspected → partial → full)
- **Unit:** ToolManager correctly validates tool+object compatibility
- **Unit:** Location completion count matches discovered evidence
- **Unit:** Revisit remains free while each investigate action costs 1
- **Integration:** Visit location → examine object → evidence appears in archive
- **Integration:** Tool used on object → hidden evidence revealed
- **Integration:** All 25 evidence items discoverable through location investigation
- **Scenario:** Full investigation of Victim's Apartment yields E1–E6, E22, E23

---

## Phase 7 — Interrogation System

**Duration:** 3–4 weeks
**Goal:** Build the evidence-confrontation interrogation mechanic.

### 7.1 — Interrogation Scene Layout

```
+-----------------------------------+
| Suspect portrait                  |
| (dynamic expressions)             |
+-----------------------------------+
|                                   |
| Dialogue area                     |
|                                   |
+-----------------------------------+
| Statement log                     |
| ⚠ contradiction markers          |
+-----------------------------------+
| Evidence inventory (drag/click)   |
|                                   |
| [Present Evidence] [End Session]  |
+-----------------------------------+
```

### 7.2 — Three-Phase Interrogation Flow

**Phase 1 — Open Conversation**
- Suspect delivers initial story
- Statements automatically logged
- Player identifies potential lies

**Phase 2 — Evidence Confrontation**
- Player selects and presents evidence
- System checks for matching triggers
- Suspect reacts based on evidence + context

**Phase 3 — Psychological Pressure**
- Contradictions accumulate as pressure points
- When pressure reaches suspect's `pressure_threshold` → break moment
- Break moment triggers: confession, accomplice reveal, or hidden event exposure

### 7.3 — Evidence Trigger System (Enhanced)

```
InterrogationTrigger:
  evidence_id: "E14"           (parking camera)
  requires_statement_id: "S12" (optional: must hear this statement first)
  impact_level: MAJOR
  reaction_type: ADMISSION
  dialogue: "Alright… maybe it was closer to 20:40."
  new_statement: StatementData
  unlocks: []
  pressure_points: +1
```

**requires_statement_id** — if the player presents evidence before hearing the relevant claim, the reaction is weaker.

**impact_level** — controls pacing:
- `MINOR` — suspect adjusts small detail
- `MAJOR` — significant admission or behavioral change
- `BREAKPOINT` — potential confession trigger

### 7.4 — Suspect Reaction System

Reactions (expanded from v1):
- **Denial** — suspect denies and maintains story
- **Admission** — suspect adjusts their story
- **Anger** — suspect becomes hostile
- **Panic** — suspect shows visible stress
- **Silence** — suspect refuses to answer
- **Revelation** — suspect reveals new information
- **Partial Confession** — suspect admits partial involvement
- **Deflection** — suspect redirects suspicion ("You should talk to Julia.")

Each reaction includes:
- Portrait expression change
- Dialogue text
- New statement logged
- Possible new evidence or topics unlocked

### 7.5 — Personality Traits Affecting Mechanics

| Trait        | Effect                                     |
|-------------|---------------------------------------------|
| Aggressive  | Anger reactions more frequent               |
| Anxious     | Panic triggers at lower pressure            |
| Manipulative| Lies require stronger evidence to expose    |
| Calm        | Higher pressure threshold                   |

### 7.6 — Pressure System

Each suspect has a `pressure_threshold`:

| Suspect       | Threshold | Break Result                     |
|---------------|-----------|----------------------------------|
| Mark Bennett  | 3         | Admits embezzlement              |
| Sarah Klein   | 2         | Reveals hearing female voice     |
| Julia Ross    | 5         | Partial confession               |
| Lucas Weber   | 2         | Confirms innocence (red herring) |

### 7.7 — Interrogation Controls

- `max_interrogations_per_day = 1` per suspect (follow-ups within session are free)
- Presenting evidence during a session is free
- Ending the session uses no additional action slot

### 7.8 — Build Four Suspect Interrogations

- **Mark Bennett** — 3 triggers (parking camera, financial records, office safe)
- **Sarah Klein** — 2 triggers (hallway camera, shoe print)
- **Julia Ross** — 4 triggers (fingerprint, elevator log, shoe print, journal)
- **Lucas Weber** — 2 triggers (maintenance logs, key access) — red herring

### 7.9 — Statement Contradiction Highlighting

```
Statement S12: "I left the house at 20:30."
⚠ Possible contradiction
```

Appears when contradicting evidence exists. Does not explain the contradiction.

### 7.10 — Debug Tools Extension

- Reset interrogation state for any suspect
- Skip to specific trigger
- Set pressure points manually
- View all triggers and their status

### Deliverables
- Interrogation scene with full UI
- Three-phase flow (conversation → confrontation → pressure)
- Enhanced trigger system with context requirements and impact levels
- Pressure system with per-suspect thresholds
- Personality traits affecting reactions
- Deflection reaction type
- Statement contradiction highlighting
- All four suspect interrogations complete
- Interrogation repeat limit

### Tests
- **Unit:** Trigger fires when matching evidence is presented
- **Unit:** Trigger does NOT fire when evidence doesn't match
- **Unit:** requires_statement_id blocks trigger until statement heard
- **Unit:** Pressure points accumulate correctly
- **Unit:** Break moment fires when threshold is reached
- **Unit:** Personality traits modify reaction probabilities
- **Unit:** max_interrogations_per_day enforced correctly
- **Unit:** Deflection reaction correctly references another suspect
- **Integration:** Evidence presented → trigger fires → statement logged → contradiction detected
- **Integration:** Full interrogation arc: open conversation → confrontation → pressure → break
- **Scenario:** Mark interrogation with all three triggers in sequence
- **Scenario:** Julia interrogation reaching break point

---

## Phase 8 — Detective Board System

**Duration:** 2–3 weeks
**Goal:** Build a simplified but functional investigation workspace.

The board is an organizational tool for the prototype. Scope is intentionally reduced to avoid overengineering a feature that must be validated through playtesting.

### 8.1 — Board Canvas

- Large but finite board (not infinite)
- Pannable (drag to scroll)
- No zoom for prototype
- Dark cork-board texture background

### 8.2 — Board Nodes (Simplified)

Three node types only:
- **Person** — suspect/witness photo + name
- **Evidence** — evidence photo + name
- **Event** — event description + time

Statements are shown inside Person nodes when expanded.
Locations are not separate nodes.

Implementation:
- Nodes are draggable UI elements
- Right-click to add notes to any node
- Same item can be placed multiple times
- Visual distinction via color coding

### 8.3 — Connection System (Simplified)

- Draw simple lines between nodes by clicking and dragging
- Add optional text note to any connection
- No predefined label categories

```
Julia Ross ---- Wine Glass
note: fingerprint match
```

Connections use a string/thread visual aesthetic.

### 8.4 — Board Data & Persistence

Board state saves as:

```json
{
  "board_nodes": [
    { "id": "node12", "type": "evidence", "ref_id": "E14", "x": 320, "y": 180, "note": "" }
  ],
  "board_connections": [
    { "from": "node12", "to": "node7", "note": "fingerprint match" }
  ]
}
```

### 8.5 — Send to Board

From the evidence archive, any item can be sent to the board:
- "Send to Board" button in evidence detail view
- Appears as a new node at center of viewport

### 8.6 — Cluster Detection (Optional Enhancement)

If time permits: when the player connects 3+ related nodes, the system detects a "theory cluster" that can later seed the Theory Builder.

### 8.7 — Debug Tools Extension

- Clear board
- Auto-populate board with all discovered items

### Deliverables
- Pannable board canvas
- Three node types (person, evidence, event)
- Simple connection system with notes
- Board persistence (save/load)
- "Send to Board" from evidence archive

### Tests
- **Unit:** Node creation with correct type and reference ID
- **Unit:** Node position persists after save/load
- **Unit:** Connection stores correct from/to/note
- **Unit:** Duplicate nodes allowed for same reference
- **Integration:** Evidence discovered → send to board → node appears → save → load → node persists
- **Integration:** Board with 20+ nodes remains responsive

---

## Phase 9 — Timeline Reconstruction System

**Duration:** 2 weeks
**Goal:** Build the timeline board for reconstructing events.

### 9.1 — Timeline UI

- Vertical timeline axis with time markers
- **5-minute snapping** (not minute-level precision — avoids tedium)

```
18:00 ────────────────
19:00 ────────────────
20:00 ────────────────
  20:30 ─────────────
  20:40 ─────────────
  20:50 ─────────────
21:00 ────────────────
22:00 ────────────────
```

### 9.2 — Event Cards

Event cards display:
```
[20:32] Elevator Log
Julia Ross enters building
Certainty: CONFIRMED
Evidence: Elevator Record
```

### 9.3 — Event Certainty Levels

Visual styling based on certainty:

| Certainty   | Visual Style     |
|-------------|------------------|
| CONFIRMED   | Solid card       |
| LIKELY      | Normal card      |
| CLAIMED     | Dashed border    |
| UNKNOWN     | Faded/translucent|

### 9.4 — Player Hypothesis Events

Players can create their own hypothesis events:

```
[+ Add Hypothesis Event]
→ "Mark enters apartment"
→ Time: 20:40
```

Hypothesis events are visually distinct (different color/icon) from discovered events.

### 9.5 — Contradiction & Overlap Detection

**Contradictions:** Visual indicator when events conflict with evidence.

**Overlap detection:** If the same person appears in two places at the same time:
```
⚠ Julia Ross appears in two places at 20:15
```

No explicit explanation — the player must interpret the conflict.

### 9.6 — Evidence Attachment

Evidence can be attached to events as supporting proof. Attached evidence strengthens the event's certainty.

### 9.7 — Timeline Persistence

Timeline state saves with the game and is used in the final Case Report evaluation.

### Deliverables
- Timeline UI with 5-minute snapping
- Event cards with certainty levels
- Player hypothesis event creation
- Overlap detection for same-person conflicts
- Contradiction highlighting
- Evidence attachment to events
- Timeline persistence

### Tests
- **Unit:** Event snaps to nearest 5-minute increment
- **Unit:** Certainty level renders correct visual style
- **Unit:** Overlap detection fires when same person at two locations at same time
- **Unit:** Overlap detection does NOT fire for different persons
- **Unit:** Hypothesis events are visually distinct from discovered events
- **Unit:** Timeline state serializes and deserializes correctly
- **Integration:** Event placed → evidence attached → contradiction detected → visual updated

---

## Phase 10 — Theory Builder (Redesigned)

**Duration:** 2 weeks
**Goal:** Let players construct narrative crime theories, not fill out forms.

### 10.1 — Theory as Narrative Steps

Instead of a flat form, the theory is a structured story of the crime:

**Step 1 — Who committed the crime?**
Select suspect. Attach evidence (1–3 items).

**Step 2 — Why did they do it?**
Describe motive. Attach evidence (1–3 items).

**Step 3 — When did the crime occur?**
Select time. Attach evidence (1–3 items).

**Step 4 — How was the victim killed?**
Select method/weapon. Attach evidence (1–3 items).

**Step 5 — What sequence of events happened?**
Link directly to the player's timeline reconstruction.

Each claim must be supported by evidence.

### 10.2 — Evidence Strength Indicator

Per step:

| Evidence Count | Strength   |
|----------------|-----------|
| 1              | Weak       |
| 2              | Moderate   |
| 3              | Strong     |

The game shows strength but does **not** confirm correctness.

### 10.3 — Multiple Theories

Players can maintain multiple theories simultaneously and compare side-by-side:

```
Theory A → Julia Ross
Theory B → Mark Bennett
```

### 10.4 — Timeline + Theory Integration

If the theory claims "Julia killed Daniel at 20:40" but the timeline shows "Julia seen leaving building at 20:30," the system flags the inconsistency.

### Deliverables
- Theory Builder with 5 narrative steps
- Evidence attachment per step with strength indicators
- Multiple theory support with comparison
- Timeline integration and consistency checking

### Tests
- **Unit:** Theory requires all 5 steps to be considered complete
- **Unit:** Strength indicator reflects correct evidence count
- **Unit:** Timeline inconsistency detected when theory and timeline conflict
- **Unit:** Multiple theories stored independently
- **Integration:** Theory references timeline → inconsistency flagged → visual indicator shown

---

## Phase 11 — Lab, Surveillance & Warrant Systems

**Duration:** 2–3 weeks
**Goal:** Implement the three supporting investigation systems.

### 11.1 — Lab Processing System

Lab requests are **evidence transformations**:

```
Input: Wine Glass (ev_wine_glass)
  ↓ fingerprint_analysis
Output: Fingerprint Result (ev_fingerprint_glass)
```

Each request stores:
```
LabRequest:
  input_evidence_id
  analysis_type
  day_submitted
  completion_day
  output_evidence_id
```

Results arrive during the morning briefing of the completion day.

**Lab Queue UI:**
```
Lab Requests
────────────────────────────────
Fingerprint analysis — Wine Glass
Result: Tomorrow morning

DNA analysis — Hair sample
Result: Day 3 morning
```

### 11.2 — Surveillance System

Surveillance produces **Observation Events** that feed into the timeline:

```
Event:
  Mark Bennett leaves apartment at 21:15
  source: surveillance
  certainty: CONFIRMED
```

Surveillance lasts **multiple days**:
```
SurveillanceRequest:
  target_person: p_mark
  type: PHONE_TAP
  day_installed: 2
  active_days: 2
  result_events: [day_3_suspicious_call, day_4_meeting]
```

### 11.3 — Warrant System

**Evidence Category Tags:**

Each evidence item has `legal_categories[]`:
```
Elevator Log → [PRESENCE]
Financial Records → [MOTIVE]
Fingerprint on knife → [PRESENCE, CONNECTION]
```

**Warrant threshold validation:**
```
count unique legal categories from attached evidence
```

| Warrant     | Requires           | Unlocks                                    |
|-------------|--------------------|--------------------------------------------|
| Search      | 2 categories       | New location evidence pools                 |
| Surveillance| 2 categories       | Phone taps, cameras, financial monitoring   |
| Digital     | 2 categories       | Phone data, email access, data recovery     |
| Arrest      | 3+ categories      | Arrest suspect (does not end case)          |

**Judge Feedback (on rejection):**

Instead of generic rejection, category-specific hints:
```
Judge: "You haven't demonstrated motive yet."
Judge: "This evidence doesn't place the suspect at the scene."
```

**Arrest Mechanics:**

Arrest does not end the case. Post-arrest:
- Suspect may refuse further questioning
- Suspect may lawyer up (higher evidence threshold for new admissions)
- Player still must prove the theory

### 11.4 — Phase 4B UI Addition

Add the remaining screens to the UI shell:
- Lab Requests panel
- Surveillance Panel
- Warrant Office

### 11.5 — Debug Tools Extension

- Complete all lab requests instantly
- Grant any warrant
- Install surveillance immediately
- List all active surveillance results

### Deliverables
- Lab processing system with transformation model
- Lab queue UI with transparency
- Surveillance system with multi-day events
- Warrant system with legal category validation
- Judge feedback with category hints
- Arrest mechanic (reduces interrogation options)
- Lab, Surveillance, Warrant UI screens

### Tests
- **Unit:** Lab request produces correct output evidence on completion day
- **Unit:** Lab request does NOT produce output before completion day
- **Unit:** Surveillance generates events on correct days
- **Unit:** Multi-day surveillance produces multiple results
- **Unit:** Warrant approval with 2 unique categories
- **Unit:** Warrant denial with only 1 category
- **Unit:** Arrest warrant requires 3+ categories
- **Unit:** Judge feedback references the missing category
- **Unit:** Post-arrest interrogation has higher threshold
- **Integration:** Lab submitted → day advances → morning briefing shows result → evidence appears in archive
- **Integration:** Surveillance installed → events appear in timeline → evidence discoverable
- **Integration:** Warrant approved → new evidence pool unlocked at location

---

## Phase 12 — Case Conclusion & Prosecutor System

**Duration:** 2–3 weeks
**Goal:** Build the endgame systems — the most important emotional moment of the game.

### 12.1 — Case Report Submission

Player submits a full case report with evidence-supported answers:
1. Who committed the murder? + evidence
2. What was the motive? + evidence
3. What was the weapon? + evidence
4. When did the murder occur? + evidence
5. How did the suspect access the location? + evidence

Timeline reconstruction is submitted as part of the report.

### 12.2 — Prosecutor Confidence Score

**Scoring factors:**

| Factor                          | Weight |
|---------------------------------|--------|
| Evidence strength (weights)     | 30%    |
| Timeline accuracy               | 25%    |
| Motive proof                    | 20%    |
| Alternative suspects eliminated | 15%    |
| Contradictions penalty          | −10%   |
| Evidence coverage bonus         | +10%   |

Coverage = percentage of critical evidence items discovered.

**Confidence Levels:**

| Level    | Score Range | Prosecutor Response                                     |
|----------|-------------|--------------------------------------------------------|
| Weak     | 0–39%       | "This theory has serious holes."                        |
| Moderate | 40–69%      | "You might convince a jury, but the defense will push." |
| Strong   | 70–89%      | "This case is ready for court."                         |
| Perfect  | 90–100%     | "This is airtight."                                     |

### 12.3 — Player Choice

After seeing the confidence score:
- **Charge suspect** — proceed to final outcome
- **Gather more evidence** — return to investigation (if time remains)
- **Review case** — revise theory

### 12.4 — Case Outcomes (Four Endings)

| Outcome                        | Condition                                |
|--------------------------------|------------------------------------------|
| Perfect Solution               | Correct suspect + high confidence + deep secrets found |
| Correct But Incomplete         | Correct suspect + moderate confidence    |
| Wrong Suspect, Plausible Theory| Wrong suspect + evidence seemed convincing|
| Incorrect Theory               | Evidence contradicts conclusion           |

### 12.5 — Ending Epilogue

Narrative epilogue revealing what really happened, followed by:

```
What you discovered:
✓ Elevator log
✓ Knife fingerprints
✓ Financial records

What you missed:
✗ Hidden bank transfer
✗ Deleted messages
✗ Daniel's personal journal
```

### 12.6 — Final Case Resolution Flow

```
Submit theory
  ↓
Prosecutor reviews and responds
  ↓
Player chooses: Charge / Investigate more / Review
  ↓
If charge: Outcome determined
  ↓
Epilogue and score summary
```

### 12.7 — Phase 4B UI Addition

Add the remaining screens:
- Theory Builder (Phase 10 design)
- Case Report submission

### Deliverables
- Case Report submission UI
- Prosecutor confidence score engine
- Prosecutor dialogue (4 confidence levels)
- Player choice (charge / investigate / review)
- Four case outcomes
- Ending epilogue with discovery summary
- Final case resolution flow

### Tests
- **Unit:** Confidence score calculation with known inputs produces expected output
- **Unit:** Evidence weight correctly influences score
- **Unit:** Timeline accuracy calculation matches against true timeline
- **Unit:** Coverage bonus correctly reflects critical evidence discovered
- **Unit:** Contradictions correctly reduce score
- **Unit:** Correct suspect identified → correct outcome
- **Unit:** Wrong suspect with plausible evidence → "wrong but plausible" outcome
- **Integration:** Full case report → confidence calculated → prosecutor responds → outcome determined
- **Scenario:** Perfect playthrough produces Perfect Solution ending
- **Scenario:** Incomplete playthrough produces Correct But Incomplete ending
- **Scenario:** Wrong accusation produces appropriate outcome

---

## Phase 13 — Placeholder Asset Pass

**Duration:** 1 week
**Goal:** Create placeholder assets at correct sizes so all UI and gameplay can be tested without final art.

### 13.1 — Placeholder Types

Simple assets with:
- Correct dimensions for target use
- Neutral gray background
- Clear text label describing the asset

### 13.2 — Placeholder Categories

| Category              | Size       | Count  | Example Label                          |
|-----------------------|-----------|--------|----------------------------------------|
| Location backgrounds  | 1920×1080 | 5      | "Victim Apartment — Kitchen"           |
| Suspect portraits     | 512×512   | 24     | "Julia Ross — Nervous"                 |
| Evidence images       | 512×512   | 25     | "E14 — Parking Camera Footage"         |
| UI textures           | Tiling    | 7      | "Cork Board Texture"                   |
| Board node icons      | 128×128   | 3      | "Person Node"                          |

### 13.3 — Naming Convention

```
placeholder_portrait_julia_neutral.png
placeholder_evidence_wine_glass.png
placeholder_location_apartment.png
placeholder_ui_corkboard.png
```

Later replaced with:
```
portrait_julia_neutral.png
evidence_wine_glass.png
location_apartment.png
ui_corkboard.png
```

### Deliverables
- All placeholder assets created at correct sizes
- All assets integrated into existing scenes
- UI layouts verified with placeholder dimensions

---

## Phase 14 — Art Production (Midjourney Batches)

**Duration:** 4–6 weeks (can overlap with later phases)
**Goal:** Generate final art assets following the Visual Style Guide.

### 14.1 — Batch Workflow

Generate assets in system-specific batches for style consistency:

**Batch 1 — Suspect Portraits (Priority: High)**
- 4 suspects + 1 victim
- 6 expressions each: neutral, nervous, angry, defensive, panicked, calm
- Consistent framing: chest-up, neutral background, same lighting angle
- Total: ≈30 portraits

**Batch 2 — Evidence Images (Priority: High)**
- 25 evidence photographs
- Forensic photo style: evidence markers, measurement rulers, timestamps
- Grouped by location for prompt consistency

**Batch 3 — Location Backgrounds (Priority: Medium)**
- 5 scenes at 1920×1080
- Clean composition, key objects visually prominent, soft background blur

**Batch 4 — UI Elements (Priority: Medium)**
- Paper texture, cork board, tape texture, folder frame, sticky note, pin icon, thread line
- Reusable across entire UI

### 14.2 — Base Prompt Style (Every Prompt)

```
semi-realistic detective game art,
modern noir atmosphere,
soft cinematic lighting,
cool desaturated colors,
high detail illustration,
grainy film texture
```

### 14.3 — Post-Processing Pipeline

1. Generate in Midjourney
2. Review for style consistency
3. Refine in Krita/Photoshop (color grading, cropping)
4. Apply consistent film grain
5. Replace placeholder files (keep identical names)
6. Verify in-game appearance

### Deliverables
- All location illustrations (5)
- All suspect portraits (≈30)
- All evidence photographs (25)
- All UI textures and elements
- Consistent visual style verified

---

## Phase 15 — Audio Design

**Duration:** 2–3 weeks (can overlap with art production)
**Goal:** Create the audio atmosphere.

### Audio Balance

```
70% ambient
20% music
10% UI sounds
```

Detective games benefit from silence and ambience. Too much music ruins tension.

### 15.1 — Ambient Audio

- Investigation desk: clock ticking, rain, distant traffic
- Location-specific ambiance per scene
- Interrogation room: fluorescent hum, tense silence

### 15.2 — UI Sound Effects

Small sounds create immersion:
- Paper slide (screen transitions)
- Folder open
- Pin click (board)
- Pen scribble (notes)
- Camera shutter (evidence)
- Typewriter key (button clicks)
- Phone buzz (notifications)

### 15.3 — Music

Minimal, atmospheric:
- Investigation theme (slow, minimal piano, low synth drones)
- Tension theme (interrogation pressure)
- Discovery theme (evidence breakthrough)
- Accusation theme (final case report)

Style: late-night investigation atmosphere, soft jazz elements.

### 15.4 — Audio Sources

- Royalty-free libraries (Freesound, Artlist)
- AI-generated music (verify commercial licensing)
- Custom composition if budget allows

### Deliverables
- Ambient audio for all scenes
- Complete UI sound effect set
- 4+ music tracks
- Audio integrated and balanced

---

## Phase 16 — Integration & Polish

**Duration:** 3–4 weeks
**Goal:** Connect all systems, fix bugs, and polish the experience.

### 16.0 — Developer Debug Tools (Final)

Ensure the debug panel covers all systems:

```
DEBUG MENU (F1)
─────────────────────────
[Unlock all evidence]
[Advance day]
[Set time slot]
[Trigger event]
[Complete lab queue]
[Grant warrant]
[Reset interrogation]
[Export game state]
─────────────────────────
Evidence Checklist:
E1 ✓  E2 ✓  E3 ✗  E4 ✓ ...
```

### 16.1 — System Integration Testing

Verify all system chains work end-to-end:
- Evidence discovered → archive → interrogation → board
- Lab submitted → day advances → results arrive → new evidence
- Warrant requested → threshold checked → approved/denied → content unlocked
- Timeline events → triggers fire → story progresses
- Case report → confidence calculated → outcome determined
- Surveillance installed → multi-day events → timeline populated

### 16.2 — Full Playthrough Testing

- Complete playthrough from Day 1 to all four endings
- Test all three investigation paths:
  - Timeline path (camera → elevator → shoe prints)
  - Physical evidence path (wine glass → fingerprints → lie)
  - Motive path (embezzlement → confrontation → emotional reaction)
- Verify all 25 evidence items are discoverable
- Verify all interrogation triggers fire correctly
- Test all warrant scenarios
- Test all confidence score outcomes

### 16.3 — Edge Case Testing

- Player skips evidence → hint system activates appropriately
- Mandatory actions not completed → day blocked correctly
- Player accuses wrong suspect → appropriate outcome
- Warrants denied → judge feedback is helpful
- Player runs out of time → soft pressure → forced theory
- Save/load mid-investigation → all state restored correctly

### 16.4 — UI/UX Polish

- All text readable at target resolution
- Navigation is intuitive
- Tooltips and help text where needed
- Smooth animations and transitions
- Consistent visual styling

### 16.5 — Performance

- Scene load times < 1 second
- Board with 20+ nodes at 60 FPS
- Evidence archive scrolling at 60 FPS
- Memory usage < 500 MB with all art loaded
- Compressed textures for evidence images and portraits

### 16.6 — Save/Load Versioning

```
save_version: 1
```

On load: if version mismatch → warn player. Prevents mysterious bugs from data structure changes.

### Deliverables
- All systems integrated end-to-end
- Multiple complete playthroughs verified
- Edge cases handled
- UI polished and consistent
- Performance acceptable
- Save versioning implemented

---

## Phase 17 — Playtesting & Iteration

**Duration:** 2–4 weeks
**Goal:** Validate the game with real players.

### 17.1 — Internal Playtesting

- Play the game multiple times with fresh eyes
- Document every friction point, confusion, or bug
- Evaluate: Is the investigation fun? Too hard? Too easy? Too obvious?

### 17.2 — External Playtesting (5–10 testers)

- Recruit playtesters who enjoy detective/puzzle games
- Provide the game with minimal instructions
- **Silent observation rule:** Do not explain the game. Only give the introduction text. If players get confused, that is valuable feedback.
- Observe silently for the first 30 minutes
- Write down: where they hesitate, what they misunderstand, what they ignore

### 17.3 — Key Metrics to Track

| Metric                                          | Target                          |
|-------------------------------------------------|----------------------------------|
| Time to first meaningful deduction              | Within first 30 minutes          |
| Do players perform their own deduction?         | Yes — reasoning, not the game    |
| Is evidence confrontation satisfying?           | "Gotcha" moments feel earned     |
| Does the detective board get used?              | Used voluntarily (not forced)    |
| Is timeline reconstruction engaging?            | Players find contradictions      |
| Does the final accusation feel meaningful?      | Not just clicking a button       |
| Is the case challenging but fair?               | Solvable through reasoning       |

### 17.4 — Detective Board Validation

Watch what players do with the board:
- **Players use it heavily** → success, keep current scope
- **Players ignore it** → reduce scope or make optional
- **Players feel forced** → redesign

Be prepared to simplify the board based on feedback.

### 17.5 — Iteration

Based on playtesting:
- Adjust difficulty (add/remove hints, adjust evidence clarity)
- Fix UX problems
- Rebalance investigation economy (2 actions/day may need adjustment)
- Revise interrogation dialogue if reactions feel unnatural
- Polish endings based on player satisfaction
- Address all Major+ bugs before release

### Deliverables
- Playtesting completed (5–10 external testers)
- Feedback documented
- Critical and major issues resolved
- Game difficulty balanced
- All regression tests added for fixed bugs

---

## Phase 18 — Release Preparation

**Duration:** 1–2 weeks
**Goal:** Prepare for commercial release.

### Tasks

1. **Title screen:** New Game, Continue, Settings, Quit
2. **Settings menu:** volume controls, text size, fullscreen toggle
3. **Save system:** 3 save slots
4. **Quick Restart Case:** replay without deleting other saves
5. **Credits screen**
6. **Guided first day tutorial** (not a complex tutorial — chief directs player to crime scene, then freedom):
   ```
   Chief: "Start by reviewing the crime scene."
   ```
7. **Build exports** for Windows, macOS, Linux
8. **Final testing pass** — full test suite + manual playthrough
9. **Create store page** (itch.io for prototype → Steam for commercial)
10. **Write store description** focusing on: player-driven deduction, evidence confrontation, investigation realism
11. **Capture screenshots and trailer**
12. **Upload builds**

### Deliverables
- Exported builds for all target platforms
- Title screen, settings, 3 save slots, credits
- Quick Restart Case feature
- Guided first-day experience
- Store page live
- Game released

---

## Revised Timeline Summary

| Phase | Name                          | Duration    | Dependencies         |
|-------|-------------------------------|-------------|----------------------|
| 0     | Project Setup & Foundation    | 1–2 weeks   | None                 |
| 1     | Data Architecture             | 2–3 weeks   | Phase 0              |
| 2     | Day System & Game Loop        | 2 weeks     | Phase 1              |
| 3     | Story Event & Notifications   | 1–2 weeks   | Phase 2              |
| 4     | Main UI Shell & Navigation    | 2–3 weeks   | Phase 0              |
| 5     | Evidence System               | 2–3 weeks   | Phases 1, 4          |
| 6     | Location Investigation        | 2–3 weeks   | Phase 5              |
| 7     | Interrogation System          | 3–4 weeks   | Phases 1, 4, 5       |
| 8     | Detective Board               | 2–3 weeks   | Phase 4              |
| 9     | Timeline Reconstruction       | 2 weeks     | Phases 1, 4          |
| 10    | Theory Builder                | 2 weeks     | Phases 5, 9          |
| 11    | Lab, Surveillance, Warrants   | 2–3 weeks   | Phases 2, 3, 5       |
| 12    | Case Conclusion & Prosecutor  | 2–3 weeks   | Phases 10, 11        |
| 13    | Placeholder Asset Pass        | 1 week      | Phase 4              |
| 14    | Art Production (Midjourney)   | 4–6 weeks   | Phase 13, parallel   |
| 15    | Audio Design                  | 2–3 weeks   | Parallel             |
| 16    | Integration & Polish          | 3–4 weeks   | All above            |
| 17    | Playtesting & Iteration       | 2–4 weeks   | Phase 16             |
| 18    | Release Preparation           | 1–2 weeks   | Phase 17             |

**Estimated total duration: 7–10 months** (solo developer, working consistently)

**Critical path:**
```
0 → 1 → 2 → 3 → 4 → 5 → 6/7 → 8/9 → 10 → 11 → 12 → 16 → 17 → 18
                               ↘ 13 → 14 (parallel with 7–12)
                               ↘ 15 (parallel)
```

---

## Technology Stack Summary

| Component         | Tool/Technology                              |
|-------------------|----------------------------------------------|
| Game Engine       | Godot 4.x                                    |
| Scripting         | GDScript (primary)                           |
| Testing           | GUT (Godot Unit Testing)                     |
| Data Authoring    | JSON → imported → Godot Resources            |
| Data Storage      | Godot Resources (.tres) + JSON               |
| Version Control   | Git + GitHub/GitLab                          |
| Art Production    | Midjourney + Krita/Photoshop refinement       |
| Audio             | Royalty-free libraries + optional AI music    |
| Distribution      | itch.io (prototype) → Steam (commercial)     |

---

## Risk Assessment

| Risk                                       | Mitigation                                              |
|--------------------------------------------|---------------------------------------------------------|
| Detective board is overengineered          | Simplified scope; validate with playtesting first        |
| Art consistency with Midjourney            | Base prompt style; batch by system; post-process all     |
| Investigation too hard for players         | Hint budget system; playtest early; adjust difficulty    |
| Scope creep beyond prototype               | Strict limits: 4 suspects, 5 locations, 25 evidence     |
| Interrogation dialogue feels unnatural     | Write dialogue carefully; playtest reactions             |
| Save system breaks during development      | Version numbers; test with every new system; 3 slots     |
| Phase 12 (events) needed earlier           | Moved to Phase 3 in this plan                            |
| Data entry in Godot inspector is painful   | JSON authoring pipeline from Phase 1                     |
| Theory builder feels like filling a form   | Redesigned as narrative steps with evidence attachment   |

---

## Success Criteria for Prototype

The prototype is successful if:

1. ✅ A player can investigate the crime scene and discover evidence
2. ✅ Interrogations produce "aha" moments through evidence confrontation
3. ✅ The detective board is used voluntarily to organize thinking
4. ✅ Timeline reconstruction reveals contradictions
5. ✅ The final accusation feels like the player solved it, not the game
6. ✅ The case is solvable through multiple investigation paths
7. ✅ Players want to replay to find evidence they missed
8. ✅ All automated tests pass
9. ✅ No critical or major bugs in the final build

If these criteria are met, the foundation is validated and development can proceed to additional cases, expanded systems, and commercial distribution.
