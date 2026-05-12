# Evidence Tab — TODOs

## 1. Pin Functionality Redesign
Implemented.

- The separate pinned section above the archive list has been removed.
- Pinned evidence now sorts to the top of the currently visible archive results.
- Pinned cards use a centered `keep` icon at the top of the polaroid instead of the old PINNED tag.
- The behavior is covered by focused archive and card regressions.


## 4. Remove Lab Status from details
In Details metadata we get Lab Status: Processing... we should remove that

## 5. Test Coverage
Improve test coverage.
`test_evidence_archive_ui.gd` tests layout structure but not behavioral state:
- No test for `_comparing` flag not being reset when switching evidence
- No test for the keep marker coexisting with NEW/LAB markers on the same card
- No test for filter + search interaction
- No test for notes persistence across evidence switches

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