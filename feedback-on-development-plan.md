Phase 0:
Your setup is already solid. I would add three small but important things.
1. Add a /core scene
Right now you only have scenes for UI and gameplay.
You should also create a root game scene.

/scenes
 ├── /core
 │   └── game_root.tscn
 ├── /ui
 ├── /locations
 └── /interrogation

game_root.tscn will contain:
	•	global UI layer
	•	scene switching
	•	background music
	•	modal dialogs
Think of it as the main application container.

2. Add a /managers folder for scripts
Right now everything system-related is under /scripts/core or /systems.
Better separation:
/scripts
 ├── /managers
 │   ├── GameManager.gd
 │   ├── CaseManager.gd
 │   └── SaveManager.gd
 ├── /systems
 ├── /data
 └── /ui

Managers = global state controllersSystems = gameplay logic
This makes the architecture clearer.

3. Add a Debug Tools folder
Add:
/scripts/debug

You will want debug tools for:
	•	advancing days
	•	unlocking evidence
	•	skipping interrogation
Without this development becomes painful.

-----------------------

Phase 1:
This section is very strong, but there are some improvements.
1. EvidenceData Needs a Few More Fields
Evidence is the central object in your game.
Add:

EvidenceData
-----------
id
name
description
type
location_found
discovered_day

tags[]
related_persons[]

lab_status
lab_result_text

requires_lab_analysis (bool)

image

weight (float)  <-- important later

weight will help with the prosecutor confidence system.
Example:

DNA match = weight 0.9
witness statement = weight 0.3


2. Add Interrogation Data
Right now interrogations are missing.
Add a new resource:

InterrogationTopicData

Example fields:

id
person_id
topic_name

trigger_conditions[]
unlock_evidence[]

statements[]

required_evidence[]

This will allow interrogations to unlock dynamically.

3. LocationData Needs Investigation Objects
Right now you only have evidence pools.
You should explicitly define investigable objects.

LocationData
------------
id
name
searchable

investigable_objects[]

evidence_pool[]

Then create:

InvestigableObjectData

Example:

id
name
description

available_actions[]
evidence_results[]

This supports your evidence discovery system.

4. Add ActionData (VERY important)
Right now your time-slot system has no structure.
Add:

ActionData

Fields:

id
name
type
time_cost
target
requirements[]
results[]

Example:

interrogate_julia
time_cost = 1
requirements = warrant OR suspicion
results = statements unlocked

This allows the investigation economy to work cleanly.

5. GameState Needs One More Critical Field
You should track visited locations.
Add:

visited_locations: Array[String]

This avoids repeated scene initialization bugs.

6. Mandatory Action System Needs Structure
Right now:

mandatory_actions_completed

But you also need:

mandatory_actions_required

Otherwise you cannot verify progress.
Example:

mandatory_actions_required = [
  interrogate_mark,
  visit_crime_scene
]


7. Save System — Improvement
JSON is fine, but save the following separately:

save_data
 ├─ game_state
 ├─ player_board
 ├─ player_timeline
 └─ player_theories

This makes debugging easier.

Missing System (Important)
You are missing EventTriggerData.
Events drive the timeline.
Add:

EventTriggerData

Example:

id
trigger_day
trigger_conditions[]
result_events[]

Example use:

If witness interrogated on Day 1
→ witness dies on Day 2

Without this system, dynamic events become messy.

Final Architecture Suggestion
After adjustments your core resources would be:
CaseData
PersonData
RelationshipData

LocationData
InvestigableObjectData

EvidenceData

StatementData
InterrogationTopicData

EventData
EventTriggerData

ActionData

This is very scalable.

-----------------------

Phase 2:
Adjustment 1 — Morning Should Not Be an Action Slot
Right now you wrote:

Morning → New information arrives
Afternoon → Player action
Evening → Player action

But then you say 3 action slots.
This creates confusion.
Better structure:

Morning  → Automatic events
Afternoon → Player action
Evening   → Player action
Night     → System processing

So the player actually gets 2 major actions per day, not 3.
Example:

Day 1
Morning   → lab results / story events
Afternoon → action
Evening   → action
Night     → delayed systems update

Why this is better:
	•	morning becomes narrative delivery time
	•	pacing becomes clearer
	•	players can't accidentally waste a slot
Total actions:

4 days × 2 actions = 8 major actions

This forces strong investigative choices.

Adjustment 2 — Action System Should Be Data Driven
You already defined ActionData earlier, which is good.
Phase 2 should explicitly say:
All actions are defined via ActionData resources rather than hardcoded logic.
Example action:

ActionData
id: interrogate_julia
type: interrogation
time_cost: 1
requirements:
  - suspect_unlocked
results:
  - unlock_statements

This will prevent your codebase from becoming messy.

Adjustment 3 — Mandatory Actions Should Be Event Triggers
Instead of:

mandatory_actions_completed

Better structure:

EventTrigger
conditions:
  action_completed("interrogate_mark")

result:
  enable_event("witness_death")

So mandatory tasks are actually event dependencies.
This avoids a rigid "checklist" feeling.

Missing System 1 — Notification System
You mention notifications but it should be its own system.
Add:

NotificationManager

Examples:

Lab result ready
New statement unlocked
Surveillance update available
New evidence discovered

These should appear in the investigation desk.
Without this, players will get lost.

Missing System 2 — Action Availability System
Not all actions should be visible at all times.
Add:

ActionAvailabilitySystem

Example logic:

If suspect not discovered
→ interrogation unavailable

If warrant not approved
→ search location unavailable

This system checks:

requirements[]
conditions[]
player_state

and decides which actions appear.

Missing System 3 — Investigation Log
Players need a chronological record of what happened.
Add a screen:

Investigation Log

Example entries:

Day 1 — Afternoon
Visited crime scene.

Day 1 — Evening
Interrogated Julia Ross.

Day 2 — Morning
Lab results received: fingerprints on glass.

This becomes extremely useful in complex cases.

-----------------------

Phase 3:
This phase is excellent conceptually.
The only risk here is overbuilding too early.
Right now you listed 10+ screens.
For a prototype this is too much.
We should break Phase 3 into two layers.

Phase 3A — Core Navigation (Prototype)
Only build the screens required for the first case.

Investigation Desk (hub)

Evidence Archive
Detective Board
Timeline Board
Location Map
Interrogation Room

That's it.

Phase 3B — Advanced Systems (Later)
Add later:

Theory Builder
Lab Requests
Surveillance Panel
Warrant Office
Case Report

These can be added once the core gameplay works.
This prevents UI overload early in development.

UI Architecture Suggestion
Your UI scenes should follow this structure:

game_root
 ├── desk_hub
 ├── screen_container
 │    ├── evidence_archive
 │    ├── detective_board
 │    ├── timeline
 │    └── location_map
 └── modal_layer
      ├── interrogation_dialog
      ├── warrant_popup
      └── notifications

So screens are loaded into one container.
This makes navigation clean.

One Critical Feature for Phase 3
Add a Global Command Bar.
Top of screen:

Day 2 — Afternoon | Actions left: 2
-----------------------------------

[Evidence] [Board] [Timeline] [Map] [Interrogate]

This prevents players from getting lost.

-----------------------

Phase 4 and 5 are very good conceptually, but there is one structural issue: the order is slightly wrong. Right now Phase 4 depends on systems that technically belong in Phase 5. If implemented exactly as written, you’ll likely end up rewriting parts of the evidence logic.
The fix is simple: separate the Evidence Data System from the Location Interaction System more clearly.
But overall your thinking is very solid.
Main issues:
	1	Evidence discovery and location interaction are too tightly coupled
	2	Investigation tools need a system layer
	3	Evidence comparison should produce insights, not always new evidence
	4	Prototype scope might slightly explode if not controlled


-----------------------

Phase 4:
This phase is excellent, but it should focus on evidence architecture and archive mechanics, not discovery.
Evidence discovery is actually part of the location system.
So we adjust the focus slightly.

Adjustment 1 — Evidence System Scope
Phase 4 should focus on:

Evidence data
Evidence archive UI
Evidence comparison
Evidence metadata
Evidence notes/tags

NOT location discovery.
Evidence discovery should live in Phase 5.

Evidence Archive UI Feedback
Your archive design is excellent and exactly what a detective game needs.
I would add two extremely valuable features.

Evidence Relationships Panel
Inside evidence detail view:
Show connections like:

Related Persons:
• Julia Ross
• Mark Ross

Referenced In:
• Statement S4
• Event E2

This makes evidence easier to analyze.

Evidence Pinning
Allow players to pin evidence to a quick-access bar.
Example:

Pinned Evidence
[Fingerprint] [Wine Glass] [Elevator Log]

Players will constantly reference the same clues.

Evidence Comparison System Improvement
Right now you wrote:
generates a forensic match result (new evidence)
This can quickly create evidence explosion.
Better approach:
Comparison creates Insights.
Example:

Insight: Shoe print size matches Mark's shoe size.

Insights can:
	•	strengthen theories
	•	unlock interrogation topics
	•	enable warrants
But they don't always create new evidence objects.
This keeps the evidence list manageable.

Progressive Discovery Hints
Your idea is good, but implement a Hint Budget System.
Example:

max_hints_per_case = 3

Hints trigger only if:
	•	critical evidence missing
	•	player advanced day
	•	player visited location already
This prevents the system from feeling intrusive.

Evidence Metadata Addition
Add two fields to EvidenceData:

importance_level
discovery_method

Example:

importance_level: CRITICAL / SUPPORTING / OPTIONAL
discovery_method: VISUAL / TOOL / COMPARISON

This helps with:
	•	hint system
	•	prosecutor confidence later

-----------------------

Phase 5:
Adjustment 1 — Introduce InvestigableObject Data
Instead of hardcoding objects in scenes.
Each object should have data:

InvestigableObjectData
id
name
description
available_actions[]
tool_requirements[]
evidence_results[]

Example:

Object: Kitchen Sink

Actions:
• Visual inspection
• Residue test

Evidence:
• Blood residue

Scenes then just reference these objects.

Adjustment 2 — Location Visit System
Your rule:
Visiting a location costs one time slot
Excellent.
But add a small improvement:

First visit → full investigation
Later visits → quick revisit option

Example:

Return to apartment?
• Full investigation
• Quick check

This avoids wasting time slots if the player just wants to verify something.

Adjustment 3 — Investigation Tools System
Tools should not be tied to objects directly.
Create a ToolManager.
Example tools:

Fingerprint Powder
UV Light
Chemical Test

Objects declare supported tool types.
Example:

Object: Wine Glass
Tools allowed:
• Fingerprint Powder

The ToolManager checks:

if tool_used AND object_supports_tool
→ reveal evidence

This keeps it modular.

Adjustment 4 — Object Investigation States
Each object should track:

not_inspected
partially_examined
fully_examined

This allows players to return and continue investigating later.

Adjustment 5 — Visual Investigation Feedback
Very important UX improvement:
When objects are fully investigated:

object_marker → changes color

Example:

Yellow → unexamined
Blue → partially examined
Gray → completed

Players hate guessing what they've already checked.

Prototype Location Scope
Your five locations are perfect for a prototype.
I would slightly improve the object distribution:

Victim Apartment → 6–7 objects
Hallway → 3 objects
Parking Lot → 2 objects
Neighbor Apartment → 3 objects
Office → 5 objects

Total objects ≈ 20
This keeps investigation manageable.

Phase Order Recommendation
Slight adjustment:

Phase 4
Evidence System
Evidence Archive
Evidence Comparison
Evidence Notes / Tags

Phase 5
Location System
Investigable Objects
Investigation Tools
Evidence Discovery

This separation will make implementation much cleaner.

One Feature Missing (Important)
You should add a Location Completion Indicator.
Example on the map:

Victim Apartment (6/8 clues found)

This does not reveal missing clues, but gives players a sense of progress.
Without it, players may feel lost.

-----------------------

Phase 6:
This is one of the best designed parts of your plan so far. The structure is logical, modular, and easy to implement with data-driven triggers.
But a few improvements will make it much stronger and easier to implement.

Major Strength: Evidence Trigger System
Your trigger structure:

evidence_id
reaction_type
dialogue
new_statement
unlocks
pressure_points

This is very good architecture.
However, I strongly recommend adding two more fields.
Missing Field 1 — Required Context
Sometimes evidence should only work after a specific statement.
Example:
Player must first hear the suspect claim:
"I was never in the parking lot."
Then the parking camera evidence becomes powerful.
Add:

requires_statement_id

Example:

requires_statement_id: "S12"

If the player presents the evidence too early → weaker reaction.

Missing Field 2 — Reaction Strength
Not all confrontations should be equal.
Add:

impact_level

Example:

impact_level: MINOR
impact_level: MAJOR
impact_level: BREAKPOINT

This helps control pacing.

Pressure System (Very Important)
You mentioned:
pressure_points: +1
Good idea, but you should formalize it.
Each suspect should have:

pressure_threshold

Example:

Mark Bennett → threshold 3
Julia Ross → threshold 5
Sarah Klein → threshold 2

When reached → break moment.
Break moment triggers:
	•	confession
	•	revealing accomplice
	•	revealing hidden event
This creates interrogation arcs.

Interrogation Replay Control
Add:

interrogation_repeat_limit

Example:

max_interrogations_per_day = 1

Otherwise players might spam interrogations.

Suspect Personality Traits
You mentioned personality traits earlier. They should directly affect interrogation mechanics.
Example:

trait: aggressive
trait: anxious
trait: manipulative
trait: calm

Effects:

aggressive → anger reactions more common
anxious → panic triggers earlier
manipulative → lies require stronger evidence
calm → higher pressure threshold

This creates variation between suspects.

Reaction System Improvement
Your reaction list is great:

Denial
Admission
Anger
Panic
Silence
Revelation
Partial Confession

Add one extremely useful reaction:

Deflection

Example:
"Why are you asking about me? You should talk to Julia."
This helps introduce new suspects or leads naturally.

Statement Log UX Improvement
Your statement log is good, but add highlighting for contradictions.
Example:

Statement S12:
"I left the office at 19:30."

Later evidence contradicts it → mark:

⚠ Possible contradiction

This helps players without solving the puzzle for them.

Interrogation UI Suggestion
Layout recommendation:

+-----------------------------------+
| Suspect portrait                  |
| Expression animation              |
+-----------------------------------+

Dialogue area

+-----------------------------------+
| Statement log                     |
+-----------------------------------+

Evidence inventory (drag or click)

[Present Evidence]  [End Interrogation]

Very standard structure, very usable.
This phase is very strong,  additions I strongly recommend to add:
requires_statement_id
impact_level
pressure_threshold
personality traits affecting reactions
deflection reaction

With those additions, the system becomes professional level design.

-----------------------

Phase 7: 
Now the honest part.
This system is very cool, but it is also dangerous for development time.
Many investigation games build huge boards that players barely use.
Examples:
	•	many players never touch them
	•	players solve cases mentally
	•	players find manual boards tedious
So the question becomes:
Does the board affect gameplay?
Right now the answer is:
No. It is purely organizational.
That makes it a luxury feature, not a core system.

Key Design Question
Does the board:
A) Help players thinkorB) Unlock gameplay systems?
Right now it only does A.
If it stays like that, development should stay simple.

Recommendation — Reduce Board Complexity
Your current scope:

infinite canvas
zoom
connections
notes
multiple node types
labels
persistence

This is a lot of engineering.
I recommend simplifying.

Simplified Detective Board (Much Better for Prototype)
Canvas:

large but finite board
pan but no zoom initially

Nodes:

Person
Evidence
Event

Statements can be shown inside person nodes.
Locations are not necessary as nodes.

Connection System Simplification
Instead of labeled connections, do this:
Players draw simple connections, then add optional note.
Example:

Julia Ross ---- Wine Glass
note: fingerprint match

No predefined labels required.
This dramatically simplifies UI complexity.

Node Creation Flow
Best UX:
Right-click on canvas:

Add Node
  → Person
  → Evidence
  → Event

Or send from archive:

Send to Board


Board Intelligence (Optional but Powerful)
You can add one small feature that makes the board meaningful.
The system detects clusters.
Example:
If player connects:

Julia Ross
Wine Glass
Elevator Log
Hallway Camera

Game detects a theory cluster.
Later the Theory Builder can use this cluster.
This creates subtle gameplay value.

Performance Consideration
Save data format should look like:

board_nodes[]
board_connections[]

Example node:

{
  id: "node12",
  type: "evidence",
  ref_id: "E14",
  x: 320,
  y: 180,
  note: ""
}

This keeps save files small.

Phase 7 Evaluation
Concept: very good
Scope: too big for prototype
Recommended changes:
Remove:
zoom
connection labels
location nodes
statement nodes

Keep:
person nodes
evidence nodes
event nodes
notes
connections
panning


-----------------------

Phase 8:
Overall: very good system and very appropriate for a detective game.
It reinforces a key detective skill:
reconstructing what happened and when
That’s exactly what investigators do.
But two improvements will make it significantly stronger.

Improvement 1 — Event Certainty Levels
Right now all events are treated the same. In reality:
Some events are confirmed facts, others are suspect claims.
Add a field to EventData:

certainty_level

Example values:

CONFIRMED
LIKELY
CLAIMED
UNKNOWN

Example events:

Event: Elevator used at 20:32
certainty: CONFIRMED (elevator log)

Event: Julia left apartment at 20:30
certainty: CLAIMED (statement)

UI visualization:

CONFIRMED → solid card
LIKELY → normal card
CLAIMED → dashed border
UNKNOWN → faded

This makes the timeline a reasoning tool, not just organization.

Improvement 2 — Overlap Detection
Your contradiction system is good, but one more rule is important:
Impossible overlaps
Example:

Julia Ross in office at 20:15
Julia Ross in hallway at 20:15

The system should mark this as:
⚠ person appears in two places
This is extremely useful for players.

Improvement 3 — Event Creation
Right now players only place predefined events.
Better design:
Allow players to create hypothesis events.
Example:

[ + Add Hypothesis Event ]

Example entry:

Mark enters apartment
20:40

These events are visually marked as player theories.
This allows real detective reasoning.

Timeline UI Recommendation
Best layout:

18:00 ────────────────
19:00 ────────────────
20:00 ────────────────
21:00 ────────────────
22:00 ────────────────

Event card example:

[20:32] Elevator Log
Julia Ross enters building
Evidence: Elevator Record

Keep it clean and readable.

Timeline Complexity Warning
Do not allow minute-level precision.
Use 5 or 10 minute snapping.
Example:

20:30
20:40
20:50

Otherwise the system becomes tedious.

Phase 8 Evaluation
Very strong feature.
Add:

certainty levels
overlap detection
player hypothesis events
time snapping

Then it becomes a great deduction tool.


-----------------------

Phase 9:
Phase 9 is the weakest design in the whole plan.
Not because the idea is bad — the idea is necessary. Every investigation game needs a formal solution system. The problem is how it’s implemented. Right now Phase 9 risks becoming a shallow form UI instead of the intellectual climax of the game.
The good news: the structure you already built in earlier phases (evidence, events, statements, timeline) gives you everything needed to make this very powerful with only a few adjustments.
This is the one phase I would seriously redesign.
Right now you wrote:

Suspect
Motive
Weapon
Time of death
Access method

This is logically correct.
But from a gameplay perspective it feels like filling out a police report, not solving a mystery.
Detective games need a moment of intellectual synthesis.

Problem with Current Design
Your current theory builder:

form fields
dropdowns
text fields
attach evidence

This is mechanically simple but emotionally weak.
Players don't feel like they're building a theory, just filling blanks.

Better Structure — Theory Graph
Instead of a form, use a structured explanation model.
Example theory:

Julia Ross killed Victor Ross.

She entered the apartment at 20:32.

They argued about the inheritance.

She grabbed the kitchen knife.

She left at 20:47.

Each sentence must be supported by evidence.
This creates a story of the crime.

Suggested Theory Structure
Instead of 5 fields, use 5 narrative steps.

1. Who committed the crime?
2. Why did they do it?
3. When did the crime occur?
4. How was the victim killed?
5. What sequence of events happened?

Step 5 links directly to the timeline system.

Evidence Support Mechanic
Each claim must attach 1–3 supporting evidence items.
Example:

Claim:
Julia entered the building at 20:32

Evidence:
• Elevator Log
• Hallway Camera

Strength indicator:

Weak → 1 evidence
Moderate → 2 evidence
Strong → 3 evidence

This part of your design is good.

Multiple Theories Feature
This is excellent and should absolutely stay.
Example:

Theory A → Julia Ross
Theory B → Mark Bennett

Players compare them.
This is great for investigation games.

Evaluation Logic (Important)
When the player submits a theory, the system should score:

Suspect correct?
Motive plausible?
Timeline consistent?
Method supported?
Evidence coverage?

Possible outcomes:

Perfect case
Mostly correct
Weak case
Incorrect accusation

This gives meaningful endings.

One Feature Missing (Very Important)
You still need the Final Case Resolution System.
After the player submits a theory, the game should move to a final stage:
Possible options:

Courtroom presentation
Chief review meeting
Arrest decision

Example flow:

Submit theory
↓
Chief asks questions
↓
Player defends evidence
↓
Final verdict

This creates dramatic payoff.

Timeline + Theory Integration
These two phases should interact.
Example:

Theory claims:
Julia killed Victor at 20:40

But timeline shows:

Julia seen leaving building at 20:30

System flags inconsistency.
This creates true deduction gameplay.

-----------------------

Phase 10:
Overall: very solid design. These systems are exactly what makes a detective game feel like real investigative work.
But there are three improvements that will make them much cleaner technically.

Lab Processing System
Your design:
	•	submit evidence
	•	processing time
	•	results arrive next morning
This is good and fits perfectly with your day system.
However you should treat lab results as transformations, not just new evidence.
Example:

Input Evidence → Lab Process → Output Evidence

Example flow:

Wine Glass
↓ fingerprint analysis
Fingerprint Result

So each lab request should contain:

lab_request
  input_evidence_id
  analysis_type
  completion_day
  output_evidence_id

This makes the system deterministic and easy to debug.

Lab Queue UI Suggestion
Players should see something like:

Lab Requests
--------------------------------
Fingerprint analysis — Wine Glass
Result: Tomorrow morning

DNA analysis — Hair sample
Result: Day 3 morning

Transparency helps players plan actions.

Surveillance System
Conceptually strong.
But right now it produces:
new events or evidence
Better structure:
Surveillance should produce Observation Events.
Example:

Event:
Mark Bennett leaves apartment at 21:15
source: surveillance
certainty: CONFIRMED

These events feed directly into your timeline system.
This integration is extremely valuable.

Surveillance Duration (Important)
Surveillance should last multiple days, not just produce one result.
Example:

Phone tap
active_days: 2

Possible outputs:

Day 3: suspicious call
Day 4: meeting arranged

This creates dynamic investigation progression.

Warrant System — Excellent Idea
Your Evidence Threshold Mechanic is one of the best mechanics in your design.

Presence
Motive
Opportunity
Connection

This mirrors real legal standards (probable cause).
However there is one thing missing.

Evidence Category Tag
Each evidence item should contain:

legal_categories[]

Example:

Elevator Log
categories: Presence


Financial Records
categories: Motive


Fingerprint on knife
categories: Presence, Connection

Then warrant validation becomes simple:

count unique categories


Judge Feedback Improvement
Instead of generic rejection, give category hints.
Example:

Judge: "You haven't shown motive yet."

or

Judge: "This evidence doesn't place the suspect at the scene."

This helps players without solving the puzzle.

Arrest Warrant Design
Your design says:
arrest does not end case
Excellent decision.
But add a mechanic:

Arrest reduces interrogation opportunities

Once arrested, suspects may:

refuse further questioning
lawyer up

This makes arrest strategic.

Phase 10 Evaluation
Very strong phase.
Add:

lab transformations
surveillance event generation
multi-day surveillance
evidence legal categories
judge feedback hints


-----------------------

Phase 11:
This is the most important emotional moment of the game.
Your structure is already strong.
But a few tweaks will make it significantly better.

Prosecutor Confidence Score
Your scoring criteria are excellent:

Evidence strength
Timeline consistency
Motive proof
Alternative suspects eliminated
Contradiction count

This is a very professional evaluation model.
However you should add one more factor:

Evidence coverage

Example:

How many critical evidence items discovered?

Players should be rewarded for thorough investigation.

Score Weight Example
Example weighting:

Evidence strength → 30%
Timeline accuracy → 25%
Motive proof → 20%
Alternative suspects eliminated → 15%
Contradictions → -10%
Coverage bonus → +10%

You don't need to show this to the player.

Prosecutor Dialogue
Great idea.
Example:

Weak:
"This theory has serious holes."

Moderate:
"You might convince a jury, but the defense will push hard."

Strong:
"This case is ready for court."

Perfect:
"This is airtight."

This adds emotional feedback.

Case Outcomes
Your three outcomes are good:

Perfect solution
Correct but incomplete
Incorrect theory

But add a fourth:

Wrong suspect but plausible theory

This is very interesting narratively.
Example:
Player accuses Mark.
Evidence seems convincing.
But epilogue reveals Julia did it.
This creates memorable endings.

Ending Epilogue Structure
Your idea is excellent.
Example format:

What you discovered:
✓ Elevator log
✓ Knife fingerprints

What you missed:
✗ Hidden bank transfer
✗ Deleted messages

Players love this kind of reveal.

Phase 11 Evaluation
Very strong endgame structure.
Add:

coverage scoring
wrong suspect plausible ending


-----------------------

Phase 12:
Phase 12 should actually come much earlier in implementation. Right now your plan puts narrative last, but almost every system you built depends on story triggers. If you implement story events only at the end, you will have to refactor many systems.

Almost every system depends on:

event triggers
story state
dialogue moments

So technically this should exist much earlier.

Recommended Phase Order
You should implement the event system right after Phase 2.
Revised order:

Phase 2 → Day System
Phase 3 → Story Event System
Phase 4+ → Other systems use events

Otherwise systems will require rewiring later.

Event System Architecture
Your trigger model is good:

timed events
conditional events
day-start events

But I recommend a unified structure.
Example:

EventTrigger
  trigger_type
  conditions[]
  actions[]

Example event:

Trigger:
day == 2

Action:
deliver lab results
unlock interrogation


Morning Briefing System
This is excellent design.
Example morning briefing:

Morning Briefing — Day 2

New information:

• Fingerprint analysis completed
• Phone records delivered
• Mark Bennett now available for questioning

This provides a clear start-of-day loop.

Dialogue System
Your lightweight dialogue approach is perfect.
You do NOT need:

branching dialogue trees

Simple structure:

portrait
text
continue button

Keep it minimal.

Phase 12 Evaluation
Good design, but should be implemented earlier.
Move it closer to the day system.

-----------------------

NEW PHASE:
Add a new phase before Phase 13:
I will be working with Midjourney to get nice and high quality image resources. I don’t want to create images one by one, but rather work with placeholders of correct size with text written on it about what it represents. And then when we know exactly about which resources we need and the desired sizes, I would generate them with Midjourney.

Placeholder Asset Pass Phase
Duration: 1 weekGoal: Create placeholder assets so development can proceed without final art.
Placeholder Types
Create simple assets with:

correct size
neutral color
text label

Example placeholder:

[ Victim Apartment Background ]
1920x1080

or

[ Evidence Photo: Wine Glass ]
512x512

These can be made in minutes using any editor.

Placeholder Categories

Location backgrounds
Suspect portraits
Evidence images
UI icons
Board nodes
Buttons

Example evidence placeholder:

512x512
gray background
text: "E14 Parking Camera Footage"


Benefits
This allows you to:

build UI
test gameplay
adjust layout

without worrying about art.
Once systems stabilize → replace placeholders with final Midjourney images.

Revised Art Pipeline
Here is a much safer pipeline.

Phase 12.5
Placeholder assets

Phase 13
Art generation batches

Phase 14
Audio design


Recommended Midjourney Workflow
Do NOT generate all assets at once.
Generate them in batches by system.
Example order:

Batch 1 — Suspect Portraits
You need these early for interrogation.
Generate:

4 suspects
6 expressions each

Total:

24 portraits


Batch 2 — Evidence Images
Generate evidence images per location.
Example:

Victim Apartment Evidence
E1–E6

Then later:

Office evidence
Hallway evidence

This keeps prompts consistent.

Batch 3 — Location Backgrounds
Generate:

5 large backgrounds

Size:

1920x1080

These should match your lighting style guide.

Batch 4 — UI Elements

paper textures
case file textures
cork board
pins
threads

These are reusable across the entire UI.

Midjourney Style Consistency Trick
One big problem with AI art is style drift.
Fix this by defining a base prompt style.
Example base style:

semi-realistic detective game art
modern noir atmosphere
soft cinematic lighting
cool desaturated colors
high detail illustration
grainy film texture

Then reuse it in every prompt.

Evidence Image Style
Evidence photos should look like:

forensic photograph
evidence marker
measurement scale
police evidence label
dim investigation lighting

Example evidence prompt concept:

forensic evidence photo of wine glass on kitchen table,
evidence marker number tag,
measurement ruler,
cool desaturated lighting,
modern noir detective game style


UI Art Feedback
Your UI art list is very good.
But you can simplify it.
You only really need:

paper texture
cork board
tape texture
folder UI frame
sticky note
pin icon
thread line

Many elements can be reused everywhere.

Location Illustration Advice
Locations should not be hyper-detailed.
Reason:
Players need to see interactive objects clearly.
Good structure:

clean composition
focus on key objects
soft background blur

Objects should visually stand out.

Suspect Portrait Advice
Portraits should be consistent camera framing.
Example:

chest-up
neutral background
same lighting
same camera angle

This avoids weird interrogation scenes.
 
 -----------------------------

Phase 14:
Your audio plan is very good.
But keep music minimal.
Detective games benefit from silence and ambience.
Recommended balance:

70% ambient
20% music
10% UI sounds

Too much music ruins tension.

Music Style Recommendation
Music should be:

slow
minimal
piano
soft jazz elements
low synth drones

Think:
late-night investigation atmosphere.

UI Sound Design Tip
Small sounds matter a lot:

paper slide
folder open
pin click
pen scribble
camera shutter

These create immersion.

Final Evaluation of Phases 13–14
Your asset plan is very solid, but the critical improvement is:
Add:

Placeholder Asset Phase

before generating Midjourney assets.
Your revised asset pipeline becomes:

Phase 12.5 — Placeholder Assets (should be phase 13)
Phase 13 — Art Production (Midjourney batches) (should be phase 14)
Phase 14 — Audio Design (should be phase 15)

-----------------------

Phase 15:
This phase is excellent and exactly what should happen before playtesting.
Your integration checks are very good:

evidence → interrogation
lab → results
warrant → unlock
timeline → story events
case report → outcome

That’s exactly the right mindset: system interaction validation.
But two developer tools will save you massive time.

Add 15.0 — Developer Debug Tools
Detective games have many branching states, so debugging without tools becomes painful.
Add a debug panel accessible with a hotkey (e.g., F1).
Example debug features:

Unlock all evidence
Jump to Day X
Trigger event
Complete lab request instantly
Grant warrant
Reveal timeline events

Example UI:

DEBUG MENU
--------------------------------
[Unlock all evidence]
[Advance day]
[Trigger event]
[Reset interrogation]
[Complete lab queue]

This allows you to test systems in seconds instead of hours.

Evidence Tracking Tool (Very Useful)
Add a developer view:

Evidence Checklist

E1 ✓
E2 ✓
E3 ✗
E4 ✓

This helps verify:
"Are all 25 evidence items discoverable?"

Save/Load Versioning (Important)
When you change data structures during development, old save files break.
Add a version number to save files:

save_version: 1

Then on load:

if version mismatch → warn player

This prevents mysterious bugs later.

Performance Section
Your performance concerns are good, but realistically this type of game is very light technically.
The only thing that might matter is:

image memory usage

Evidence photos and portraits should use:

compressed textures

Godot handles this well.

Phase 15 Evaluation
Very strong phase.
Add:

debug tools
evidence checklist
save versioning


 -----------------------------

Phase 16:
This phase is excellent and extremely important for detective games.
Investigation games fail or succeed almost entirely based on playtesting.
Your test questions are exactly the right ones.

Add One Key Observation Rule
When playtesting:
Do not explain the game.
Only give the introduction text.
If players get confused, that is valuable design feedback.
Example rule:

Observe silently for first 30 minutes

Write down:

where they hesitate
what they misunderstand
what they ignore


Critical Playtest Metric
Track this:

Time to first meaningful deduction

Example:

Player connects evidence → "oh wait..."

If that moment happens too late, the game may feel slow.

Detective Board Validation
Your question:
Does the detective board help organize thinking?
Watch what players do.
Possible outcomes:

Players use it heavily → success
Players ignore it → reduce scope
Players feel forced to use it → redesign

Be prepared to simplify the board if needed.

Interrogation Satisfaction
Watch for this moment:

Player presents correct evidence
suspect cracks
player reacts: "YES!"

If players feel that moment, your interrogation system works.

Playtest Number Recommendation
You wrote:

5–10 playtesters

Perfect.
Typical pattern:

3 players → find biggest problems
next 5 → balance difficulty

You rarely need more.

Phase 16 Evaluation
Excellent phase.
Add:

silent observation rule
time-to-deduction metric
detective board usage evaluation

 -----------------------------

Phase 17:
This phase is very clean and practical.
Your list is good:

title screen
settings
credits
tutorial
build exports
store page

Two small additions will help.

Add 17.1 — Save Slots
Even for a prototype:

3 save slots

Players like experimenting with different theories.

Add 17.2 — Quick Restart Case
Very useful feature:

Restart Case

Players can replay without deleting saves.

Tutorial Advice
Do not build a complex tutorial.
Instead use:

guided first day

Example:

Chief: "Start by reviewing the crime scene."

Then allow freedom.
Detective games should teach by investigation, not instruction.

Store Page Advice
Your store description should focus on:

player-driven deduction
evidence confrontation
investigation realism

Those are your strongest features.

Integrating Your Placeholder → Midjourney Workflow
Let's integrate it into the final development timeline.

Updated Asset Plan
Add the placeholder phase we discussed earlier.

Phase 12.5
Placeholder assets

Phase 13
Final art generation

Workflow becomes:

Build UI with placeholders
Test gameplay
Lock layouts
Generate Midjourney assets
Replace placeholders

This prevents asset rework.

Example Placeholder Naming
Use consistent naming:

placeholder_location_apartment.png
placeholder_evidence_wineglass.png
placeholder_portrait_julia.png

Then later replace with:

location_apartment_final.png
evidence_wineglass_final.png
portrait_julia_neutral.png

This keeps the pipeline clean.

Final Phase Structure
Your project now looks like this:

0 Project setup
1 Data architecture
2 Day system
3 UI shell
4 Evidence system
5 Location investigation
6 Interrogation
7 Detective board
8 Timeline
9 Theory builder
10 Lab / surveillance / warrants
11 Case conclusion
12 Story events
13 Placeholder assets
14 Art production
15 Audio
16 Integration & polish
17 Playtesting
18 Release

This is a full professional development roadmap.

One Final Missing Piece (Small but Important)
You still need a Hint System.
Players will get stuck.
Hints could come from:

technician comments
chief suggestions
prosecutor advice

Example:

Chief: "Have you looked closely at the victim's office yet?"

This prevents frustration without breaking immersion.


One Very Important Development Tip
When you build the prototype case:
Do not enter all data manually in Godot inspectors.
Instead use:

JSON → imported → Resource objects

Because writing narrative data inside Godot is painful.



