# Purpose

The Cross-Reference system allows the player to connect related evidence items in order to generate new investigative findings.

This mechanic represents:
investigative reasoning
forensic synthesis
evidence correlation

It is not intended to be:
inventory-combining gameplay
trial-and-error puzzle solving
brute-force item comparison

The system should feel grounded, deliberate, and professional.

# Core Design Philosophy

The player is rewarded for:
discovering meaningful evidence
recognizing investigative opportunities
deciding when to spend actions pursuing stronger conclusions

The player is NOT expected to:
manually search through all evidence combinations
guess random item pairings
compare unrelated evidence

The game internally knows which evidence relationships are valid.
The player's role is to identify when it is worth pursuing a forensic connection.

# Resource Economy

The game uses two different investigative costs:
Forensic Analysis -> time (next day result)
Cross-Reference Evidence -> actions (immediate result)

This distinction is intentional.

## Forensic Analysis

Represents:
laboratory processing
external analysis
unavoidable waiting time

The player pays with:
investigation time (days)

## Cross-Reference Evidence

Represents:
investigative focus
detective effort
active case work

The player pays with:
Actions

Cross-referencing always consumes 1 Action, but only when a valid undiscovered connection exists.

# UI Placement

The Cross-Reference section appears in:
COLUMN 1 — Evidence Processing

## Final column structure:

HEADER
Evidence Name
Tags
Buttons:
- Pin
- Send to Board

COLUMN 1
Image
Description
Forensic Analysis
Cross-Reference Evidence
Evidentiary Value

COLUMN 2
Details
Related Persons
Legal Categories

COLUMN 3
Referenced Statements
Player Notes

Column 1 represents evidence processing and investigative progression.

The flow becomes:
discover evidence
↓
analyze evidence
↓
cross-reference evidence
↓
understand evidentiary strength

This creates a natural investigative workflow.

# Cross-Reference Functionality

Basic Rule

A cross-reference opportunity becomes available when:
the current evidence item
AND
at least one compatible evidence item
have both been discovered by the player.

Important Rules
The player never manually selects from all evidence.

The system:
internally determines valid relationships
only exposes meaningful opportunities

This prevents:
brute force gameplay
UI clutter
random experimentation
Cross-Reference States

## STATE A — No Compatible Evidence Available

Shown when:
no discovered evidence can currently be cross-referenced with this item

UI:
CROSS-REFERENCE EVIDENCE
No compatible evidence currently discovered.
Additional evidence may unlock new connections.

Notes:
No button shown
Section still visible
Helps teach the mechanic
Creates anticipation for future discoveries

## STATE B — Compatible Evidence Available

Shown when:
at least one valid undiscovered connection exists

UI:
CROSS-REFERENCE EVIDENCE
A potential evidentiary connection is available.
[Cross-Reference Evidence] (ActionButton)

### Button Behavior

When pressed:
consumes 1 Action
generates a new evidence item immediately
triggers new notification
adds resulting evidence to archive
shows NEW badge in archive

## STATE C — Existing Findings

Shown after:
one or more cross-reference results were already generated

UI:
CROSS-REFERENCE EVIDENCE
Established Findings:
→ Shoe Print Match — Julia Ross
→ Financial Correlation Report

Each finding:
behaves as clickable evidence link
opens generated evidence item

## STATE D — Existing Findings + Additional Opportunity

Shown when:
player already generated one result
AND
another valid undiscovered relationship later becomes available

UI:
CROSS-REFERENCE EVIDENCE
Established Findings:
→ Shoe Print Match — Julia Ross
A new potential evidentiary connection is available.
[Cross-Reference Additional Evidence] (ActionButton)

This allows:
progressive investigative expansion
future scenario scalability
multiple valid relationships per item

# Multiple Possible Comparisons

The prototype may rarely use this, but the system must support it.

Rule
If multiple valid undiscovered relationships exist simultaneously:
pressing the button opens all possible findings (with the evidence that's available in the archive)

The UI should NOT explicitly reveal:
the exact matching evidence item before processing

Avoid:
Compare with Julia's Shoes

Instead use:
A potential evidentiary connection is available.

This preserves:
investigative tension
discovery payoff
player curiosity
Confirmation Flow

When a cross-reference succeeds:

we show Notification
FORENSIC CONNECTION CONFIRMED
The hallway shoe print matches
the sole pattern of Julia Ross's shoes.
New Investigative Finding Added:
"Shoe Print Match — Julia Ross"

action deducted
new evidence added to archive
NEW badge displayed
finding link added to Cross-Reference section

# Generated Evidence

Cross-referencing does NOT simply “unlock text”. It creates a new evidence item.

This is important because:
the connection itself becomes evidence
synthesized findings strengthen the case
derived conclusions can later support statements

Generated Evidence Examples:
Source Evidence	Generated Finding
Shoe Print + Julia's Shoes	Shoe Print Match — Julia Ross
Accounting Files + Bank Transfer	Financial Correlation Report
Elevator Logs + Hallway Camera	Timeline Correlation Report

# Archive Integration

Generated findings behave like normal evidence:
appear in archive
can be pinned
can be sent to board
may link to statements
may contribute to contradictions
may affect case strength

Action Cost Rules:
Cross-referencing costs 1 Action.

Reason:
generates new evidence
advances investigation materially
represents active investigative effort

This creates meaningful prioritization:
pursue map exploration?
interrogate suspect?
cross-reference evidence?
save actions for tomorrow?

# Important Constraint

The Cross-Reference section only appears when the evidence has the Cross-Reference possibility
The button only appears when a valid undiscovered relationship exists

Therefore:
pressing the button should always succeed
no wasted actions
no failure states

Difference Between Lab and Cross-Reference:
Lab Analysis -> delayed scientific processing
Cross-Reference -> active investigative reasoning
Lab -> Player pays with time.
Cross-Reference -> Player pays with actions.

This distinction creates:
strategic pacing
meaningful resource management
stronger investigation identity

# Scalability Goals

The system must support future cases where:
one evidence item can generate multiple findings
new opportunities appear later
relationships become increasingly complex

The UI should therefore:
support multiple findings
support reappearing opportunities
avoid clutter
remain readable
Naming Conventions
Section Title
CROSS-REFERENCE EVIDENCE
Primary Button
[Cross-Reference Evidence]
Secondary Button
[Cross-Reference Additional Evidence]

# Final Design Goals

The Cross-Reference system should feel:
investigative
deliberate
grounded
rewarding
strategic
easy to understand

The player should feel:
“I am building a stronger case by connecting evidence intelligently.”

not:
“I am combining game items.”