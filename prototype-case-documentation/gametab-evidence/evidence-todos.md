# Evidence Tab — TODOs

## 1. Pin Functionality Redesign
I would like to change how we handle pinning and unpinning of evidence. the PINNED section above the list of evidence should be completely removed. Instead I would like the pinned evidence to be imediately placed at the top of the list. Currently the pinned evidence gets the PINNED tag. I would prefer if it would get the "keep" icon placed at the top in the center of the polaroid. Can we please implement that in an elegant and cohesive way? Please also update any relevand documentation files accordingly.


## 4. Remove Lab Status from details
In Details metadata we get Lab Status: Processing... we should remove that

## 5. Test Coverage
Improve test coverage.
`test_evidence_archive_ui.gd` tests layout structure but not behavioral state:
- No test for `_comparing` flag not being reset when switching evidence
- No test for card badge refresh after pin/unpin
- No test for filter + search interaction
- No test for notes persistence across evidence switches
- No test for the pinned bar reconstruction

## 6. Legal categories are good, but underused
   
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