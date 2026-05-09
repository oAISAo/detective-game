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

## 7. Missing parent-child relation
Problem: Several evidence items are clearly derived from earlier evidence:

Examples:
wine glasses → fingerprint result
desk fingerprint → identified fingerprint
shoe print → analyzed shoe print

But the data structure does not explicitly represent this relationship.

Right now the relationship only exists:
implicitly
in gameplay logic
in developer knowledge

That is fragile. Without explicit parent-child relations UI becomes harder.

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

This is an architectural issue, not just polish.