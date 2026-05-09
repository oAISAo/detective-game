# Evidence Tab — TODOs

## 1. Button Icons
Replace current text icons with out material icons:
- pin
- send to board
- compare evidence
- submit to lab

## 2. Submit To Lab button -> WaitButton
WaitButton should look similar to ActionButton. Color should be Amber, icon should be hourglass. ActionButton icon should be changed to thunder.

## 3. Lab Tag
The Lab Tag should appear immediately on the evidence polaroid as soon as the player clicks "Submit to Lab"

## 4. Selected Evidence
the evidence polaroid needs a blue border when it's selected (same as location card hover)

## 5. Remove Lab Status from details
In Details metadata we get Lab Status: Processing... we should remove that

## 6. Test Coverage
Improve test coverage.
`test_evidence_archive_ui.gd` tests layout structure but not behavioral state:
- No test for `_comparing` flag not being reset when switching evidence
- No test for card badge refresh after pin/unpin
- No test for filter + search interaction
- No test for notes persistence across evidence switches
- No test for the pinned bar reconstruction

## 7. discovery_method is inconsistent
Problem: The current discovery_method field mixes together multiple different concepts:

A. How the evidence was originally found
Example:
visual inspection
warrant
interrogation
digital recovery

B. How the evidence was processed
Example:
lab analysis

C. How the evidence became available
Example:
tool unlock
derived evidence

These are fundamentally different systems.

Why this becomes a problem later:
Right now the field still works because the game is small.
But later this will create problems in:
filtering
UI labels
timeline logic
evidence sorting
save migration
analytics/debugging
future case design

Example problem:
"discovery_method": "LAB"
This incorrectly implies:
“the lab discovered this evidence”
But the lab did not discover it.

The player:
discovered the wine glasses
submitted them for analysis
received a forensic result

That is a transformation pipeline, not a discovery source.

### Recommended fix

Redefine discovery_method to mean ONLY:

“How the player originally obtained this evidence.”

Recommended values (Value	Meaning):
VISUAL	Found directly in the world
FORENSIC	Produced by forensic analysis
WARRANT	Obtained via legal authorization
DIGITAL	Retrieved from digital systems
TESTIMONY	Unlocked from interrogation
ADMINISTRATIVE	Provided automatically (autopsy, police file, etc.)

### Additional recommendation

Do NOT use this field for:
progression state
analysis state
unlock conditions

Those should be separate systems.

Example
Before
"discovery_method": "LAB"
After
"discovery_method": "FORENSIC"