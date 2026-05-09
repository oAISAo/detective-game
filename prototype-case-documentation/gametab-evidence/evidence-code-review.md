# Evidence Tab — Critical Code Review and Improvement Ideas (screen and all used components)



1. Inconsistent importance usage
   
Problem: We currently have two systems that partially overlap:
1. weight
Represents evidentiary strength and legal/prosecutorial value
2. importance_level
Represents narrative significance and progression relevance

But these are not clearly separated. The systems currently look similar, so future content creators (including future you) will unintentionally mix them.

Example confusion:
“This is important, should weight be high?”
“This is weak evidence but plot-critical.”

Current symptom Example:
"weight": 0.7,
"importance_level": "CRITICAL"
vs
"weight": 0.4,
"importance_level": "SUPPORTING"

The distinction is not obvious enough.

### Recommended fix: Document the systems clearly.

Recommended meaning:

1. weight
Answers “How persuasive is this evidence?”
Used for:
- evidentiary value label
- contradiction systems
- prosecution strength
- theory validation

2. importance_level
Answers “How essential is this evidence to progression?”
Used for:
- story progression
- unlock conditions
- contradiction severity
- fail states
- case completion

### Important rule

These systems MUST remain independent.

Examples (Situation, Weight, Importance):
Situation: Weak but plot-critical clue, Weight: low, Importance: high
Situation: Strong optional evidence, Weight: high, Importance: low
Situation: Background flavor item, Weight: low, Importance: low

### Additional recommendation: Consider renaming importance_level.

Current names:
CRITICAL
SUPPORTING
OPTIONAL

feel too similar to evidentiary strength.

Better naming:
CRITICAL -> REQUIRED
SUPPORTING -> MAJOR
OPTIONAL -> MINOR

This separates narrative importance from evidentiary strength much more clearly.

Not urgent technically, but important for long-term content consistency.

------------------------------

1. Legal categories are good, but underused
   
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

1. Conceptual issue with OPTIONAL evidence
Problem

The term OPTIONAL unintentionally communicates:

“This evidence does not matter.”

But many OPTIONAL items still:

enrich deductions
strengthen theories
support conclusions

So the naming creates the wrong mental model.

Example
"importance_level": "OPTIONAL"

for:

wine bottle
contextual clues

These still matter psychologically and deductively.

Why this is dangerous

Players may:

ignore OPTIONAL evidence completely
misunderstand case depth
assume low design importance

This is especially risky in a deduction-heavy game.

Recommended fix

Rename the progression tiers.

Recommended replacement
Current	Recommended
CRITICAL	REQUIRED
SUPPORTING	MAJOR
OPTIONAL	MINOR
Why this works better
MINOR

Means:

smaller role
lower relevance

BUT:

still meaningful
OPTIONAL

Feels like:

“safe to ignore”

That is not what you want.

Additional recommendation

Consider future hidden depth:

Some MINOR evidence may:

unlock alternate theories
improve endings
reveal lies earlier
reduce uncertainty

This makes exploration rewarding.
