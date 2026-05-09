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

## 7. Legal categories are good, but underused
   
Problem: The legal categories system is already strong conceptually:

Examples:
MOTIVE
PRESENCE
OPPORTUNITY
CONNECTION

But currently they function mostly as passive metadata.

The player:
rarely interacts with them
does not build reasoning around them
does not feel their systemic importance

This system has the potential to become the backbone of your deduction framework. Right now it is underutilized.

### Recommended long-term direction

Legal categories should eventually influence:
theory building
prosecution structure
board organization
evidence filtering
contradiction analysis

### Recommended future uses

A. Board grouping: Allow players to group evidence by category.
Example:
all MOTIVE evidence
all PRESENCE evidence

B. Case completeness checks
Example:
“Your theory lacks strong opportunity evidence.”
This creates structured reasoning.

C. Warrant systems
Example:
judge requires enough CONNECTION evidence before approving warrant
Very immersive.

D. Contradiction weighting
Contradictions against PRESENCE evidencemmay matter more than CONNECTION evidence.

E. Theory validation
Example:
A murder accusation may require motive, opportunity and/or presence before accusation is accepted.

### Important note

Do NOT overcomplicate this now. The system foundation is already good.

The key improvement right now is designing future systems around categories intentionally.

-------------------------------------------