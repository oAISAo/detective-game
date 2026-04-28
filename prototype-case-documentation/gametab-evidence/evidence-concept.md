# Evidence Tab — Concept & Reference

## Overview

The Evidence Tab is the player's investigation workspace for all collected evidence. Where the Map tab is about *gathering* — going out and finding things — the Evidence tab is about *understanding*: reading, connecting, analyzing, and drawing conclusions from what's been found.

**Core loop:** Discover evidence (via Map / Lab / Interrogation) → Review in Evidence Archive → Submit to Lab if raw → Link statements → Classify contradictions → Compare items → Build understanding

**Key principle:** The Evidence tab never interprets evidence for the player. It presents facts. The player decides what they mean. The game's job is to make analysis feel like a detective's workflow, not a database query.

---

## Two Panels

```
┌─────────────────────────┬─────────────────────────────────────────────────┐
│  LEFT PANEL             │  RIGHT PANEL                                    │
│  Evidence Archive       │  Evidence Detail                                │
│                         │                                                 │
│  [Search bar]           │  ┌─ Header ──────────────────────────────────┐  │
│  [Type filter]          │  │  ID · Title · Badges · Pin · Board        │  │
│                         │  └────────────────────────────────────────────┘ │
│  Polaroid grid of all   │  ┌─ Main col ─────────┐  ┌─ Side col ───────┐  │
│  discovered evidence    │  │  Image              │  │  Related Persons │  │
│                         │  │  Description        │  │  Statements /    │  │
│  Click → loads detail   │  │  Metadata grid      │  │  Contradiction   │  │
│                         │  │  Weight bar         │  │  Engine          │  │
│                         │  │  Tags               │  │  Send to Board   │  │
│                         │  │  Compare button     │  └──────────────────┘  │
│                         │  └────────────────────────────────────────────┘  │
└─────────────────────────┴─────────────────────────────────────────────────┘
```

---

## Left Panel — Evidence Archive

### Layout
- A scrollable grid of polaroid-style evidence cards (same visual style as the map tab discovery cards)
- Search bar at the top (real-time filter on name/description)
- Type filter dropdown: All Types / Forensic / Document / Recording / Financial / Digital / Physical / Lab Result

### Evidence Cards (Polaroid Style)
Each card shows:
- Evidence ID code (top, monospace, small)
- Dark image placeholder (or actual evidence image when available)
- Evidence name (bottom caption)
- **State badge** in top-right corner (see Evidence States below)

### Card Interactions
- **Click** → loads that evidence into the right panel
- **Hover** → subtle scale-up, border highlight
- Cards are always visible — there is no pagination

### Ordering
- Default: discovery order (newest at top)
- **NEW** items always float to the top until reviewed
- Within same discovery day: critical evidence before supporting before noise

### Evidence Card States (Badge)
| Badge | Color | Meaning |
|-------|-------|---------|
| **NEW** | Blue | Discovered but not yet opened |
| **LAB** | Amber | Submitted for lab analysis, results pending |
| *(none)* | — | Reviewed, no special status |
| **PINNED** | Amber dot | Pinned by player (small dot, not a full badge) |

The **NEW** badge disappears the moment the player opens the evidence detail for the first time.

---

## Right Panel — Evidence Detail

### Layout
The detail panel is split into a header, a main content column, and a side column.

```
┌─ Header ────────────────────────────────────────────────────────┐
│  [E14 — Parking Lot]  Parking Lot Camera Footage                │
│  [CRITICAL] [Recording] [Presence]          [Pinned] [Board]    │
└─────────────────────────────────────────────────────────────────┘
┌─ Main Column (fills space) ──┐  ┌─ Side Column (220px) ────────┐
│  [ Image / Placeholder ]     │  │  RELATED PERSONS             │
│                               │  │  ○ Mark Bennett · Suspect    │
│  DESCRIPTION                 │  │                              │
│  Security camera footage...  │  │  ──────────────────────────  │
│                               │  │  STATEMENTS                  │
│  DETAILS                     │  │  [stmt item]                 │
│  Location / Discovery /      │  │  [stmt item]                 │
│  Day Found / Lab Status      │  │  [stmt item]                 │
│                               │  │                              │
│  EVIDENTIARY WEIGHT          │  │  [+ Link Statement]          │
│  ████████░░ 70%              │  │  [Send to Board ↗]           │
│  "Strong corroborating..."   │  └──────────────────────────────┘
│                               │
│  TAGS                        │
│  [surveillance] [timeline]   │
│                               │
│  [◎ Compare Evidence]        │
└──────────────────────────────┘
```

### Header
- **Evidence ID** — monospace label above the title (e.g., `E14 — Parking Lot`)
- **Title** — serif large type
- **Badges row** — Importance badge (CRITICAL / SUPPORTING / NOISE) + Type badge + Legal Category badge(s)
- **Pin button** — toggles pinned state; purely a player convenience bookmark
- **Board button** — sends evidence to the Detective Board (see Board tab integration below)

### Image Block
- Shows evidence image if available
- Placeholder pattern (diagonal hatch) with camera icon if no image
- Bottom label bar: evidence ID + day discovered

### Description
- Plain prose. What this item is, where it was found, what it looks like.
- Written in case data — not generated by the player.

### Metadata Grid (2×2 cells)
| Field | Content |
|-------|---------|
| Location | Where it was found |
| Discovery | How it was found (Visual Inspection / Examine / Lab Result / Interrogation) |
| Day Found | Investigation day |
| Lab Status | Not required / Pending / Complete |

### Evidentiary Weight Bar
- Percentage drawn from evidence data (`weight` field)
- Color: amber for most evidence, red if contradicted, teal if supporting a strong theory
- One-sentence prosecutor assessment below the bar

Weight thresholds and their prose labels:
| Weight | Label |
|--------|-------|
| 85–100% | Airtight. Will convict on its own. |
| 65–84% | Strong. Holds up under cross-examination. |
| 40–64% | Corroborating. Strengthens the case when combined with other evidence. |
| 20–39% | Weak. Circumstantial — the defense will challenge this. |
| 1–19% | Marginal. Context only. |

### Tags
- Predefined tags from case data (e.g., `surveillance`, `timeline`, `alibi`, `contradiction`)
- Players can add custom tags (free text, short label)
- Tags are used as a secondary search filter in the left panel

### Compare Evidence Button
See **Evidence Comparison** section below.

---

## Side Column — Related Persons

A compact list of all persons linked to this evidence in the case data.

Each person entry shows:
- Avatar circle with initials (color-coded: red for suspects, blue for witnesses, grey for other)
- Full name
- Role label (Suspect / Witness / Victim / etc.)

Clicking a person navigates to their profile in the Suspects tab.

---

## Side Column — Statements (Contradiction Engine)

This is the most important section of the Evidence Tab. It shows all recorded statements that are linked to this evidence item — and lets the player classify whether each statement **supports**, **contradicts**, or is **unresolved** relative to this evidence.

### Statement Ownership Model
- Statements are created in the Suspects tab during interrogations.
- The Evidence tab does NOT create or own statements.
- The Evidence tab only displays statements that are relevant to the selected evidence item.

A statement appears in the Evidence tab only when:
- The player has unlocked the statement (via interrogation)
- The player has discovered the linked evidence item

The Evidence tab is where the player evaluates statements against facts.

### How Statements Appear
Statements are **data-driven**: the case data pre-defines which statements are potentially relevant to which evidence items. A statement becomes visible on an evidence item only when **both** are in the player's possession — i.e., the player has discovered the evidence AND the interrogation session that produced the statement has occurred.

This means:
- On Day 1, the wine glasses evidence has no statements yet (interrogations haven't happened)
- After Day 1 interrogations, Mark's "I left at 20:30" statement appears on the parking camera evidence
- The player sees the link because they now have both pieces of information

Statements are **never automatically classified**. Showing up in the list is neutral — the player decides what the relationship means.

### Statement Data Model
Each statement contains:
- id
- person_id
- text
- day_recorded
- source_interrogation_id

Statements are linked to evidence via `linked_statements` in evidence data.

Player decisions are stored separately:
- evidence_id
- statement_id
- verdict (contradiction / supports / unresolved)
- player_note (optional)

### Statement Item Anatomy
Each statement shows:
1. **Person avatar** (color-coded by role) + name + day given
2. **Quote** (italic serif — reads like real testimony)
3. **Verdict pill** — the player's classification:
   - `UNCLASSIFIED` (default, amber) — not yet analyzed
   - `CONTRADICTION` (red) — this evidence contradicts the statement
   - `SUPPORTS` (teal) — this evidence supports / confirms the statement
   - `UNRESOLVED` (amber) — the player acknowledges it but can't determine the relationship yet
4. **Expand toggle** — clicking the statement reveals an analysis note field where the player can type their own interpretation

### Verdict Classification
Verdict classifications are stored in player state and must persist across sessions.
Changing a verdict updates the UI immediately and emits a signal for downstream systems (e.g. case evaluation).

The player sets the verdict by clicking the current verdict pill and selecting from a small dropdown:
- Contradiction
- Supports
- Unresolved
- (Remove link — hides the statement from this evidence item)

**Design principle:** Classifying a contradiction is a meaningful investigative action. The game tracks which contradictions have been identified — this feeds into the Prosecutor Confidence evaluation at case submission.

### "+ Link Statement" Button
If the player wants to manually link a statement that wasn't pre-linked in the data, they can use this button to search for statements and attach them. This supports player-driven connections the data didn't anticipate.

> **Open question:** Should manually linked statements be treated differently from data-driven ones? One option: manually linked statements show a small "player-tagged" indicator so it's clear the connection is the player's interpretation, not a data fact.

---

## Lab Submission Flow

### Overview
Some evidence discovered on the Map tab is raw and requires forensic laboratory analysis before it yields useful information. Lab submission happens from the Evidence tab.

**Lab submission costs 0 actions** (passive activity). It represents the detective packaging up the sample and sending it off — a routine administrative step, not an investigation decision. The meaningful decision is *which evidence* to submit and *when* — submitting something wastes nothing, so the player is always incentivized to submit promptly.

### Raw Evidence
Evidence with `requires_lab_analysis: true` in its data displays a **Submit to Lab** section in the detail panel instead of (or below) the Compare Evidence button:

```
┌─────────────────────────────────────────┐
│  LAB ANALYSIS AVAILABLE                 │
│  Fingerprint analysis can be performed  │
│  on this item. Results return next day. │
│                                         │
│  [Submit to Lab — Fingerprint Analysis] │
└─────────────────────────────────────────┘
```

### Submission Steps
1. Player opens raw evidence (e.g., `ev_wine_glasses`)
2. "Submit to Lab" section appears with the analysis type pre-populated from data
3. Player clicks "Submit to Lab"
4. Notification: *"Wine glasses submitted for fingerprint analysis. Results expected tomorrow morning."*
5. Evidence card in the archive gains **LAB** badge
6. The "Submit to Lab" button changes to a status indicator: *"In analysis — Day 2 morning"*

### Lab Results Delivery
- Results are delivered automatically at the **start of the next day's morning phase** (no player action needed)
- A notification fires: *"Lab results in: [result evidence name]"*
- The result is a **new, separate evidence item** that appears in the archive with a **NEW** badge
- The original raw evidence item remains in the archive unchanged — it is not replaced

### Lab Requests in the Riverside Apartment Case
| Lab Request | Input Evidence | Output Evidence | Analysis Type |
|------------|---------------|-----------------|---------------|
| `lab_fingerprint_glass` | `ev_wine_glasses` | `ev_julia_fingerprint_glass` | Fingerprint Analysis |
| `lab_fingerprint_desk` | `ev_desk_fingerprint_raw` | `ev_mark_fingerprint_desk` | Fingerprint Analysis |
| `lab_shoe_print` | `ev_shoe_print_raw` | `ev_shoe_print` | Footwear Analysis |

---

## Evidence Comparison

### Overview
Some evidence items can be compared against each other to generate a **forensic match result** — a new evidence item confirming or denying a connection between two pieces of evidence.

Comparison is a passive action (0 action cost). It represents the detective placing two items side by side and drawing a conclusion.

### How It Works
1. Player opens evidence item A (e.g., `ev_shoe_print`)
2. Clicks "Compare Evidence"
3. A comparison selector appears over the right panel showing all other discovered evidence as a scrollable list
4. Player selects evidence item B (e.g., `ev_julia_shoes`)
5. The system checks whether a valid comparison pair exists in the case data
   - **Valid pair:** A new evidence item is generated and added to the archive. Notification fires.
   - **Invalid pair:** A brief message: *"No forensic connection found between these items."* Nothing is generated.
6. The comparison selector closes

### Comparison Result
A forensic match result is a new evidence item with:
- Type: `forensic_match`
- Description: e.g., *"The hallway shoe print matches the sole pattern of Julia Ross's left shoe (size 38)."*
- Importance: typically Critical
- Linked to both source evidence items

### Comparisons in the Riverside Apartment Case
| Evidence A | Evidence B | Output | Result |
|------------|------------|--------|--------|
| `ev_shoe_print` | `ev_julia_shoes` | `ev_shoe_match` | Match confirmed |
| `ev_julia_fingerprint_glass` | `ev_wine_glasses` | *(no new item — fingerprint already is the result)* | — |
| `ev_bank_transfer` | `ev_accounting_files` | `ev_financial_link` | Financial connection confirmed |

> **Open question:** Should invalid comparisons ever generate anything? For example, comparing the parking camera with the kitchen knife — obviously unrelated. One option: all comparisons produce *something* (even just a "no connection" note) so the player feels their effort was acknowledged. Another option: silent no-op, which is cleaner.

---

## Evidence States

Each evidence item tracks the following state:

| State Field | Values | Notes |
|-------------|--------|-------|
| `reviewed` | bool | True once player has opened the detail panel for this item |
| `pinned` | bool | Player bookmark — UI convenience only |
| `lab_status` | `none` / `submitted` / `complete` | For raw evidence only |
| `sent_to_board` | bool | Whether "Send to Board" has been clicked |
| `player_notes` | string | Free-text notes written by the player |
| `player_tags` | string[] | Custom tags added by the player |

### State Transitions
| From | To | Trigger |
|------|----|---------|
| (not in archive) | NEW | Evidence discovered (map, lab, interrogation, briefing) |
| NEW | Reviewed | Player opens the evidence detail panel |
| Raw | LAB | Player submits to lab |
| LAB | (normal, result is separate item) | Lab completes overnight |

---

## "Send to Board" Integration

When the player clicks **Send to Board**:
1. A confirmation notification appears: *"Parking Lot Camera Footage added to the Detective Board."*
2. The evidence is flagged as `sent_to_board: true`
3. The Board button on the evidence detail changes to a "View on Board" state
4. In the Board tab, the card becomes available as a draggable node

**Design principle:** Sending to the board is a gesture of intent — the player is saying "this matters, I want to think about it visually." It does not cost an action. Players can send as many or as few items as they want. The board doesn't need to contain everything.

> **Open question:** Should "Send to Board" auto-place the card, or should the player manually drag it onto the board canvas? Auto-placement risks a cluttered board. Manual drag gives control but requires the player to go to the Board tab. Suggested answer: auto-place in an "inbox" zone at the edge of the board, player then positions it.

---

## Player Notes

The statement expansion section includes a **free-text notes field** per statement link. The main evidence detail panel also has a **notes area** accessible via a small notes toggle icon near the bottom.

Player notes are:
- Stored per evidence item in game state
- Visible only to the player (not surfaced in the Prosecutor evaluation)
- Persisted across sessions
- Displayed as "handwritten"-style text (distinct visual treatment from case data text)

Notes are a cognitive offloading tool — let the player think out loud without the game judging them.

---

## Action Economy

All Evidence Tab activities are **passive (0 action cost)** unless otherwise noted.

| Activity | Action Cost |
|----------|-------------|
| Opening evidence detail | 0 |
| Reviewing evidence | 0 |
| Submitting to lab | 0 |
| Comparing evidence | 0 |
| Classifying statement verdict | 0 |
| Writing notes | 0 |
| Adding tags | 0 |
| Pinning | 0 |
| Sending to Board | 0 |

**Rationale:** Analysis is the reward, not the action cost. Making evidence review cost actions would punish careful players and discourage the kind of deep engagement the game is built on. Time pressure comes from the limited actions available for *active* work (interrogations, location examination) — the Evidence tab is the thinking space between those decisions.

---

## Evidence Discovery Sources

Evidence can arrive in the archive from multiple sources. Each source is tracked in the `discovery_method` field:

| Source | Method Label | Examples |
|--------|-------------|---------|
| Map tab target examination | Visual Inspection / Examine | ev_knife, ev_wine_glasses |
| Lab analysis result | Lab Result | ev_julia_fingerprint_glass |
| Morning briefing (automatic) | Case File | ev_autopsy_report |
| Interrogation (statement-driven) | Interrogation | *(future: evidence surfaced through questioning)* |
| Warrant execution | Search Warrant | ev_julia_shoes, ev_deleted_messages |
| Surveillance result | Surveillance | *(optional: phone tap recordings)* |

---

## Evidence Notifications

Whenever new evidence arrives in the archive, a notification popup fires. The notification format follows the same pattern as the map tab:

- Evidence discovered from a target: immediate popup per item
- Lab results: morning phase popup *"Lab results in: [name]"*
- Warrant results: popup *"Search complete: [name] discovered"*

Evidence notifications always show:
- Evidence name
- Brief one-line description
- A "View" shortcut button that opens the evidence detail directly

---

## New Evidence Badge Lifecycle

1. Evidence is discovered → **NEW** badge appears on card in archive
2. Player opens the detail panel → **NEW** badge disappears
3. If player hasn't opened it by end of day → badge persists into next day
4. Notification bell counter (top-right nav) counts all unreviewed NEW items

---

## Signal Architecture

```
Lab submission
  → EvidenceManager.submit_to_lab(evidence_id)
  → LabManager.create_request(evidence_id, analysis_type)
     → lab_submitted signal
  → Evidence card gains LAB badge
  → Notification: "Submitted for analysis"

Next morning
  → DayManager.morning_phase()
  → LabManager.process_overnight()
     → For each completed request:
        → GameManager.discover_evidence(result_evidence_id)
           → evidence_discovered signal
        → NotificationManager.notify_evidence(result)
        → lab_completed signal

Evidence comparison
  → EvidenceManager.compare(evidence_id_a, evidence_id_b)
  → Checks ComparisonsData for valid pair
     → If valid: GameManager.discover_evidence(result_id)
     → If invalid: comparison_no_match signal → UI message

Statement verdict classification
  → EvidenceManager.set_statement_verdict(evidence_id, statement_id, verdict)
  → Stores in player state
  → Updates verdict pill in UI
  → contradiction_identified signal (if verdict = CONTRADICTION)
     → Feeds into ProximityConfidenceSystem for case evaluation

Send to board
  → EvidenceManager.send_to_board(evidence_id)
  → BoardManager.add_evidence_node(evidence_id)
  → NotificationManager: "Added to board"
  → evidence_sent_to_board signal
```

---

## Data Model Notes

### Evidence Data Fields (from `evidence.json`)
```json
{
  "id": "ev_parking_camera",
  "name": "Parking Lot Camera Footage",
  "description": "Security camera footage showing Mark Bennett leaving the building at 20:40.",
  "type": "recording",
  "importance": "critical",
  "weight": 70,
  "location_found": "loc_parking_lot",
  "day_available": 2,
  "requires_lab_analysis": false,
  "related_persons": ["p_mark"],
  "legal_categories": ["presence"],
  "linked_statements": ["stmt_mark_departure_time", "stmt_mark_corrected_departure", "stmt_mark_lied_to_hide_argument"],
  "linked_comparisons": [],
  "tags": ["surveillance", "timeline", "alibi", "contradiction"]
}
```

### Player Evidence State (runtime, persisted)
```json
{
  "ev_parking_camera": {
    "reviewed": true,
    "pinned": false,
    "sent_to_board": true,
    "lab_status": "none",
    "player_notes": "",
    "player_tags": [],
    "statement_verdicts": {
      "stmt_mark_departure_time": "contradiction",
      "stmt_mark_corrected_departure": "supports",
      "stmt_mark_lied_to_hide_argument": "unresolved"
    }
  }
}
```

---

## Open Questions

These are design decisions that need to be made before implementation. Recommendations are provided.

**Q1: Should invalid evidence comparisons produce any output?**
Recommendation: Silent no-op with a brief inline message. Don't generate junk evidence items — they pollute the archive.

**Q2: Should manually linked statements be visually distinguished from data-linked ones?**
Recommendation: Yes. A small "player-tagged" indicator (e.g., a pen icon) on manually linked statements makes clear to the player what's game-verified vs. their own inference.

**Q3: Auto-place or manual drag for "Send to Board"?**
Recommendation: Auto-place in an inbox area on the board. Forcing the player to drag from scratch every time adds friction without adding value.

**Q4: Should comparison be available from both evidence items in a pair, or only from one?**
Recommendation: Available from either item. If the player has both and opens either one, they should be able to trigger the comparison from whichever they're viewing.

**Q5: What happens to lab evidence cards after submission — does the original raw item become less prominent?**
Recommendation: The raw item (`ev_shoe_print_raw`) stays in the archive but gets a "Superseded by lab result" visual treatment once the result arrives — muted appearance, with a link to the processed result. It's not removed (it's still evidence of what was found and where) but the processed result takes precedence for case building.

**Q6: Should the Evidence Tab show a notification badge count in the top nav?**
Recommendation: Yes. The bell icon already shows a counter. The Evidence tab icon in the nav bar should also show a small count of unreviewed NEW items — makes it clear when the player should visit.

---

## Code Reference (Suggested)

| File | Purpose |
|------|---------|
| `scripts/ui/screens/evidence_tab.gd` | Main evidence tab screen |
| `scripts/ui/components/evidence_archive.gd` | Left panel — archive grid |
| `scripts/ui/components/evidence_detail.gd` | Right panel — detail view |
| `scripts/ui/components/evidence_card.gd` | Individual polaroid card |
| `scripts/ui/components/statement_item.gd` | Statement row in side column |
| `scripts/ui/components/lab_submit_section.gd` | Lab submission UI block |
| `scripts/ui/components/compare_selector.gd` | Evidence comparison overlay |
| `scripts/managers/evidence_manager.gd` | Evidence state, filtering, verdicts, comparisons |
| `scripts/managers/lab_manager.gd` | Lab request creation and overnight processing |
| `data/cases/riverside_apartment/evidence.json` | All evidence items and metadata |
| `data/cases/riverside_apartment/comparisons.json` | Valid comparison pairs and results |
| `data/cases/riverside_apartment/statements.json` | All statements with evidence links |
