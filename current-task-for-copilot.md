Task 1: Add derived investigation status for location objects
Goal

Map object detail panels must accurately reflect clue lifecycle and pending lab state.

Scope
location object detail panel
object list row badge / icon
clue status hint text
regression coverage for lab submission flow
Acceptance criteria
Hallway Floor
After discovering raw shoe print but before lab submission:
Status shows Partially examined
Detail text prompts lab submission
After submitting raw shoe print:
Status shows Awaiting lab results
Prompt changes to “analysis in progress”
After next-morning analyzed result arrives:
Status shows Fully processed
No pending lab prompt remains
Building Hallway overall location
Should still show 4/4 clues found
But if one or more object-level clues are pending lab, optional location-level badge could show:
Scene processed / lab pending
Required tests

You said every fix must be tested — good. This absolutely should be.

Add tests for:
object status after raw clue discovery
object status after lab submission
object status after analyzed evidence delivery
detail hint text changes correctly across those states
location-level clue count remains correct independent of lab state

That’s exactly the kind of bug that comes back later if not covered.


Task 2: Visual redesign for Map tab (Phase 1)
New Map screen structure
Top
Header: Case Map
Subheader:
Track leads, revisit scenes, and inspect active investigation sites.
Main content

Replace the full-width text list with large location cards.

Each location card should include:

Location name
Small generated scene thumbnail
Status badge
Not Visited
Active Leads
Scene Processed
Lab Pending
Clue count
Optional suspect relevance tags
“Mark”
“Julia”
“Sarah”
Example for Building Hallway
Thumbnail: dim apartment corridor
Badge: Lab Pending
Subtext: “Security access and trace evidence recovered.”
Meta: 4/4 clues found

That already feels far more like a commercial detective UI.


Task 3: Redesign for Location Detail screen (Phase 1)

This screen has much better potential than the map list, but it needs a proper layout pass.

Current problem

You have:

object list on left
detail text on right
tools squashed awkwardly at bottom

This creates a lot of dead space and low drama.

Better layout structure
LEFT COLUMN (30–35%)

Scene navigation

object list as investigation targets
each row gets:
icon
status dot
clue count
“new” badge if applicable
CENTER (40–45%)

Main scene panel
This should become the emotional center.

Instead of just text, show:

scene artwork / hallway image
optional subtle hotspot overlay
selected object highlight

This is where Midjourney-generated visuals can start paying off.

RIGHT COLUMN (25–30%)

Investigation panel
For selected object:

object title
status badge
short atmospheric description
clues found
available actions
progress state
BOTTOM or RIGHT-STACK

Investigation tools
Not as giant dead buttons across the bottom.

Better:

compact forensic tool buttons
only show tools relevant to selected object
disabled tools should explain why