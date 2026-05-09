# Evidence Tab — Critical Code Review and Improvement Ideas (screen and all used components)

1. discovery_method is inconsistent
Problem

The current discovery_method field mixes together multiple different concepts:

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

Why this becomes a problem later

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

Recommended fix

Redefine discovery_method to mean ONLY:

“How the player originally obtained this evidence.”

Recommended values
Value	Meaning
VISUAL	Found directly in the world
FORENSIC	Produced by forensic analysis
WARRANT	Obtained via legal authorization
DIGITAL	Retrieved from digital systems
TESTIMONY	Unlocked from interrogation
ADMINISTRATIVE	Provided automatically (autopsy, police file, etc.)
Additional recommendation

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
2. Missing parent-child relation (important)
Problem

Several evidence items are clearly derived from earlier evidence:

Examples:

wine glasses → fingerprint result
desk fingerprint → identified fingerprint
shoe print → analyzed shoe print

But the data structure does not explicitly represent this relationship.

Right now the relationship only exists:

implicitly
in gameplay logic
in developer knowledge

That is fragile.

Why this matters

Without explicit parent-child relations:

UI becomes harder

You cannot easily:

show evidence chains
display “derived from”
navigate between related evidence
Logic becomes harder

You cannot easily:

trace evidence origins
disable duplicate submissions
track analysis history
build timelines
Future systems become harder

Especially:

theory systems
evidence graphs
nested analysis
branching forensic results
Recommended fix

Add:

"derived_from": "ev_wine_glasses"

to all evidence created from another evidence item.

Example
{
  "id": "ev_julia_fingerprint_glass",
  "derived_from": "ev_wine_glasses"
}
Benefits

This enables:

Evidence navigation

Example:

“Derived from: Two Wine Glasses”

Evidence trees

Possible future UI:

Wine Glasses
└── Julia Fingerprint
Better compare systems

You can avoid:

circular comparisons
duplicate lab work
invalid submissions
Recommendation priority

👉 HIGH PRIORITY

This is an architectural issue, not just polish.

3. Raw evidence should probably have lab targets
Problem

Currently the forensic relationship is only represented from the result side:

Example:

"derived_from": "ev_wine_glasses"

But the raw evidence itself does not know:

what it can become
what analysis it supports

This creates asymmetry.

Why this becomes a problem

Without forward references:

UI becomes harder

You cannot easily display:

“Available forensic analysis”
expected results
analysis previews
Submission systems become harder

You must hardcode:

mappings
result lookups
analysis logic
Multi-result analysis becomes difficult

Later you may want:

DNA result
fingerprint result
blood trace result

from the same evidence item.

Without explicit targets:
👉 this becomes messy fast.

Recommended fix

Add:

"lab_analysis_results": [
    "ev_julia_fingerprint_glass"
]

to raw evidence items.

Example
{
  "id": "ev_wine_glasses",
  "lab_analysis_results": [
    "ev_julia_fingerprint_glass"
  ]
}
Why array instead of single value?

Because future cases may support:

"lab_analysis_results": [
    "ev_fingerprint",
    "ev_dna_trace",
    "ev_drug_residue"
]
Benefits

This enables:

Better UI

Example:

“Possible forensic analyses available”

Cleaner lab system

No hardcoded switch statements.

Better progression control

You can:

lock/unlock analyses
gate analysis types
support upgraded labs later
Recommendation priority

👉 HIGH PRIORITY

This will significantly simplify your forensic architecture.

4. Inconsistent importance usage
Problem

You currently have two systems that partially overlap:

weight

Represents:

evidentiary strength
legal/prosecutorial value
importance_level

Represents:

narrative significance
progression relevance

But these are not clearly separated.

Why this becomes dangerous

The systems currently look similar, so future content creators (including future you) will unintentionally mix them.

Example confusion:

“This is important, should weight be high?”
“This is weak evidence but plot-critical.”
Current symptom

Example:

"weight": 0.7,
"importance_level": "CRITICAL"

vs

"weight": 0.4,
"importance_level": "SUPPORTING"

The distinction is not obvious enough.

Recommended fix

Document the systems clearly.

Recommended meaning
weight

Answers:

“How persuasive is this evidence?”

Used for:

evidentiary value label
contradiction systems
prosecution strength
theory validation
importance_level

Answers:

“How essential is this evidence to progression?”

Used for:

story progression
unlock conditions
contradiction severity
fail states
case completion
Important rule

These systems MUST remain independent.

Examples:

Situation	Weight	Importance
Weak but plot-critical clue	low	high
Strong optional evidence	high	low
Background flavor item	low	low
Additional recommendation

Consider renaming importance_level.

Current names:

CRITICAL
SUPPORTING
OPTIONAL

feel too similar to evidentiary strength.

Better naming
Current	Better
CRITICAL	REQUIRED
SUPPORTING	MAJOR
OPTIONAL	MINOR

This separates:

narrative importance
from
evidentiary strength

much more clearly.

Recommendation priority

👉 MEDIUM-HIGH PRIORITY

Not urgent technically, but important for long-term content consistency.

7. Legal categories are good, but underused
Problem

The legal categories system is already strong conceptually:

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
Why this matters

This system has the potential to become:
👉 the backbone of your deduction framework.

Right now it is underutilized.

Recommended long-term direction

Legal categories should eventually influence:

theory building
prosecution structure
board organization
evidence filtering
contradiction analysis
Recommended future uses
A. Board grouping

Allow players to group evidence by category:

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

Contradictions against:

PRESENCE evidence
may matter more than:
CONNECTION evidence
E. Theory validation

Example:
A murder accusation may require:

motive
opportunity
presence

before accusation is accepted.

Important note

Do NOT overcomplicate this now.

The system foundation is already good.

The key improvement right now is:
👉 designing future systems around categories intentionally.

Recommendation priority

👉 LOW PRIORITY NOW / VERY HIGH LONG-TERM VALUE

8. Conceptual issue with OPTIONAL evidence
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
