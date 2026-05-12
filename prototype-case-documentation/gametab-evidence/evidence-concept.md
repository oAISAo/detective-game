# Evidence Tab — Concept & Reference

## Overview

The Evidence Tab is the player's investigation workspace for all collected evidence. Where the Map tab is about *gathering* — going out and finding things — the Evidence tab is about *understanding*: reading, connecting, analyzing, and drawing conclusions from what's been found.

**Core loop:** Discover evidence (via direct inspection / forensic output / warrants / interrogation / briefing) → Review in Evidence Archive → Submit raw items to Lab if needed → Follow explicit evidence lineage where relevant → Classify contradictions → Compare items for insights → Build understanding

**Key principle:** The Evidence tab should not pretend certainty can be measured with fake precision. It presents facts plus authored investigative context, while leaving the final deduction to the player.

---

## Two Panels

```
┌─────────────────────────┬─────────────────────────────────────────────────┐
│  LEFT PANEL             │  RIGHT PANEL                                    │
│  Evidence Archive       │  Evidence Detail                                │
│                         │                                                 │
│  [Search bar]           │  ┌─ Header ──────────────────────────────────┐  │
│  [Type filter]          │  │  Title · Badges · Pin · Board        │  │
│                         │  └────────────────────────────────────────────┘ │
│  Polaroid grid of all   │  ┌─ Main col ─────────┐  ┌─ Side col ───────┐  │
│  discovered evidence    │  │  Image              │  │  Statements      │  │
│                         │  │  Description        │  │  / Contradiction │  │
│  Click → loads detail   │  │  Metadata grid      │  │  Engine          │  │
│                         │  │  Evidentiary Value  │  │  Send to Board   │  │
│                         │  │  Related Persons    │  └──────────────────┘  │
│                         │  │  Legal Categories   │                       │
│                         │  │  Compare button     │                       │
│                         │  └────────────────────────────────────────────┘  │
└─────────────────────────┴─────────────────────────────────────────────────┘
```

---

## Left Panel — Evidence Archive

### Layout
- A scrollable grid of polaroid-style evidence cards (same visual style as the map tab discovery cards)
- Search bar at the top (real-time filter on name/description)
- Type filter dropdown: All Types / Forensic / Document / Photo / Recording / Financial / Digital / Object / Physical / Testimonial

### Evidence Cards (Polaroid Style)
Each card shows:
- Evidence ID code (top, monospace, small)
- Dark image placeholder (or actual evidence image when available)
- Evidence name (bottom caption)
- **State pills** in the top-right corner for NEW/LAB plus a centered top `keep` marker when pinned

### Card Interactions
- **Click** → loads that evidence into the right panel
- **Hover** → subtle scale-up, border highlight
- Cards are always visible — there is no pagination

### Ordering
- Pinned evidence always floats to the top of the currently visible archive results
- Within the pinned and unpinned groups, **NEW** items float to the top until reviewed
- Reviewed items then sort by most recent discovery, with case relevance only acting as a late tie-break

### Evidence Card States
| Marker | Color | Meaning |
|-------|-------|---------|
| **NEW** | Blue | Discovered but not yet opened |
| **LAB** | Amber | Submitted for lab analysis, results pending |
| **keep** icon | Amber | Pinned by player; shown at the top center of the polaroid |
| *(none)* | — | Reviewed, no special status |

The **NEW** badge disappears the moment the player opens the evidence detail for the first time.

---

## Right Panel — Evidence Detail

### Layout
The detail panel is split into a header and three scrollable columns.

```
┌─ Header ────────────────────────────────────────────────────────────────────┐
│  Parking Lot Camera Footage                         [Pinned] [Compare] [Board] │
│  [REQUIRED] [Recording] [Presence]                                          │
└──────────────────────────────────────────────────────────────────────────────┘
┌─ Column 1: Evidence View ─────┐ ┌─ Column 2: Details ───────────────────┐ ┌─ Column 3: Analysis ─────────────┐
│  [Square Image / Placeholder] │ │  DETAILS                              │ │  REFERENCED STATEMENTS           │
│  Security camera footage...    │ │  Location / Discovery / Day Found    │ │  [stmt item]                     │
│                                │ │  Lab Status / Metadata                │ │  [stmt item]                     │
│  FORENSIC ANALYSIS             │ │  RELATED PERSONS                     │ │  [stmt item]                     │
│  [submit / pending / complete] │ │  LEGAL CATEGORIES                    │ │                                  │
│                                │ │                                      │ │  MY NOTES                        │
│  EVIDENTIARY VALUE             │ │                                      │ │  [always-visible TextEdit]       │
│  Supporting                    │ │                                      │ │                                  │
│  Suggests the victim had       │ │                                      │ └──────────────────────────────────┘
│  company before the murder.    │ │                                      │                                    
│  Contested by a credible       │ │                                      │                                    
│  statement (if applicable)     │ │                                      │                                    
└────────────────────────────────┘ └──────────────────────────────────────┘ └──────────────────────────────────┘
```

### Header
- **Title** — serif large type
- **Badges row** — Case Relevance badge (REQUIRED / MAJOR / MINOR / KEY) + Type badge + Legal Category badge(s)
- **Pin button** — toggles pinned state; purely a player convenience bookmark
- **Compare button** — opens the comparison selector in the right panel header button row
- **Board button** — sends evidence to the Detective Board (see Board tab integration below)

### Image Block
- Shows evidence image if available, filling the first-column width while staying square
- Placeholder pattern (diagonal hatch) with camera icon if no image
- Bottom label bar: evidence ID + day discovered

### Description
- Plain prose. What this item is, where it was found, what it looks like.
- Written in case data — not generated by the player.

### Metadata Grid (dynamic key/value rows)
| Field | Content |
|-------|---------|
| Location | Where it was found |
| Discovery | Original acquisition source (Visual Inspection / Forensic Analysis / Search Warrant / Digital Recovery / Interrogation / Case File) |
| Derived From | Shown when the evidence item explicitly comes from another evidence item |
| Day Found | Investigation day |
| Case Relevance | Case-role materiality from `importance_level` |
| Lab Status | Not required / Pending / Complete |

`discovery_method` is source-only metadata. `importance_level` is separate case-role metadata used for guidance, ordering, and evidence-detail presentation. Pending or completed lab work is represented by `lab_status`, and comparison outcomes are tracked in the insight system rather than becoming a new discovery label.

### Evidence Lineage
- Evidence lineage is explicit in case data through `EvidenceData.derived_from`.
- `derived_from` is a single parent evidence ID, not a list. It expresses authored origin, not player interpretation.
- A child evidence detail can show **Derived From** as a navigation link when the parent is still present in the discovered archive.
- Raw evidence declares forward lab targets through `EvidenceData.lab_analysis_results`.
- The Forensic Analysis block uses `lab_analysis_results` plus matching `LabRequestData` templates to show available analyses, pending submissions, and completed result links.
- For lab requests with `lab_transform: derive`, parent and child can coexist in the archive.
- For lab requests with `lab_transform: upgrade`, the analyzed output still keeps `derived_from`, but the raw parent can be replaced in the discovered archive. In that case the child shows the parent name as plain metadata rather than an active navigation link.
- Lineage is separate from lab state. `derived_from` answers "where did this evidence come from?" while `lab_status` answers "what is happening to this evidence right now?"
- Evidence comparison does not create lineage. Successful comparisons unlock `InsightData`, not child evidence items.

### Case Relevance
- Case Relevance appears in the header badge row and the metadata grid.
- It comes from `EvidenceData.importance_level`.
- It answers: **How essential is this evidence to the case's authored guidance role?**
- Current runtime uses are intentionally narrow: progressive hint targeting, archive ordering tie-breaks, and evidence-detail badge/metadata presentation.
- It is not a strength meter. A required clue can still be weak or only supporting in the Evidentiary Value section if its `weight` is low.
- `StatementData.importance` reuses the same enum family for contradiction credibility, but that is a statement-materiality rule, not evidence strength.
- Prosecutor coverage remains a separate case-authored list through `CaseData.critical_evidence_ids`; it is not derived from every evidence item marked `REQUIRED`.

### Evidentiary Value
- This lives in the first column below the description and the forensic-analysis block.
- It is an interpretation, not a measurement.
- The section uses the internal `weight` field only to derive a qualitative tier.
- Case Relevance and Evidentiary Value are independent; they are allowed to disagree.
- The player sees three layers of information:
  - **Qualitative tier** — the primary signal shown in the UI
  - **Case-specific interpretation** — evidence-authored reasoning text
  - **Optional dynamic modifier** — a subtle contested warning when the evidence is challenged by a credible contradiction

Qualitative tiers are derived internally from `weight`, but the number itself is never shown:

| Internal Weight | Player-Facing Label |
|----------------|---------------------|
| 0.85–1.0 | Airtight |
| 0.65–0.84 | Strong |
| 0.40–0.64 | Supporting |
| 0.20–0.39 | Weak |
| 0.01–0.19 | Marginal |

Example presentation:

```text
Evidentiary Value

Supporting
Suggests the victim had company before the murder.
```

If the evidence is contested, the section adds a subtle warning instead of shifting into an aggressive visual alarm state:

```text
Contested by a credible statement
```

The contested modifier uses the existing contradiction check:
```gdscript
# In EvidenceManager:
func is_contradicted(evidence_id: String) -> bool:
    for stmt_id in ev.linked_statements:
        if get_statement_verdict(evidence_id, stmt_id) != "contradiction":
            continue
        var stmt: StatementData = CaseManager.get_statement(stmt_id)
        # REQUIRED (0) and MAJOR (1) are material; MINOR (2) and KEY (3) are not
        if stmt.importance <= Enums.ImportanceLevel.MAJOR:
            return true
    return false
```

      This contested-warning check depends on statement materiality, not evidence `weight`. It sits alongside the other two systems rather than replacing them.

    The section deliberately removes:
    - percentage display
    - progress bars
    - bar-color severity states
    - generic prosecutor-style prose reused across unrelated evidence items

### Compare Evidence Button
The compare button lives in the header button row with Pin and Send to Board. It still opens the comparison selector in the right panel.

See **Evidence Comparison** section below.

---

## Second Column — Related Persons

A compact list of all persons linked to this evidence in the case data. It sits in the second column below the forensic analysis block.

Each person entry shows:
- Avatar circle with initials (color-coded: red for suspects, blue for witnesses, grey for other)
- Full name
- Role label (Suspect / Witness / Victim / etc.)

Clicking a person navigates to their profile in the Suspects tab.

## Second Column — Legal Categories

A compact list of the evidence's legal categories in the case data. It appears directly below Related Persons in the second column.

Each entry shows:
- A bullet label for the legal category
- The same case-data-driven category labels used elsewhere in the UI

---

## Third Column — Referenced Statements (Contradiction Engine)

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

## Third Column — My Notes

The notes section sits directly below Referenced Statements in the third column.

It uses a `My Notes` Section Header, keeps the text field visible at all times, and autosaves the player's writing back into evidence state.

There is no collapse/expand toggle.

### Statement Data Model
Each statement contains:
- id
- person_id
- text
- day_given (int — the investigation day the statement was recorded)
- related_evidence (string[] — evidence IDs this statement relates to)
- related_event (string — event ID this statement relates to, optional)
- contradicting_evidence (string[] — evidence IDs that potentially contradict this statement)

Evidence links to statements via the `linked_statements` field on `EvidenceData` (evidence → statement direction). Statements link back to evidence via `related_evidence` on `StatementData` (statement → evidence direction). Contradictions are detected using `contradicting_evidence` on `StatementData`.

Player decisions are stored separately in `StatementVerdictData` (key: `"evidence_id:statement_id"`):
- evidence_id
- statement_id
- verdict (unclassified / contradiction / supports / unresolved)
- player_note (optional free text)

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

**Design principle:** Classifying a contradiction is a meaningful investigative action. The game tracks which contradictions have been identified — this feeds into the Prosecutor Confidence evaluation at case submission.

---

## Lab Submission Flow

### Overview
Some evidence discovered on the Map tab is raw and requires forensic laboratory analysis before it yields useful information. Lab submission happens from the Evidence tab.

**Lab submission costs 0 actions** (passive activity). It represents the detective packaging up the sample and sending it off — a routine administrative step, not an investigation decision. The meaningful decision is *which evidence* to submit and *when* — submitting something wastes nothing, so the player is always incentivized to submit promptly.

### Raw Evidence
Evidence with non-empty `lab_analysis_results` in its data displays a **Forensic Analysis** block in the first column, between the Description and Evidentiary Value sections:

```
┌─────────────────────────────────────────┐
│  FORENSIC ANALYSIS                      │
│  Possible forensic analyses are         │
│  available.                             │
│                                         │
│  [Submit to Lab — Fingerprint Analysis] │
└─────────────────────────────────────────┘
```

`lab_analysis_results` is the forward source of truth for lab-capable evidence. Each listed output ID must match a `LabRequestData` template for the same input evidence. The template still owns the per-analysis metadata such as `analysis_type`, `lab_transform`, `pending_status_text`, and `completed_status_text`.

### Submission Steps
1. Player opens raw evidence (e.g., `ev_wine_glasses`)
2. The Forensic Analysis block appears in the first column with one entry per currently available lab target
3. Each entry shows a submit button labeled from the matching `LabRequestData.analysis_type`
4. Player clicks "Submit to Lab"
5. The Forensic Analysis banner switches to the pending status copy from `LabRequestData.pending_status_text`, for example: *"Wine glasses submitted for fingerprint analysis. Results expected tomorrow morning."*
6. Evidence card in the archive gains **LAB** badge
7. The lab action remains visible as a submitted wait button until the result arrives the next morning

### Lab Results Delivery
- Results are delivered automatically at the **start of the next day's morning phase** (no player action needed)
- A notification fires: *"Lab results in: [result evidence name]"*
- The result always carries explicit lineage through `derived_from`
- For `derive` requests, the result is a **new, separate evidence item** that appears in the archive with a **NEW** badge while the parent remains discoverable
- For `upgrade` requests, the analyzed output replaces the raw evidence in the discovered archive, but still points back to the raw input via `derived_from`
- When both items remain discoverable, the detail panel can navigate between parent and child directly from the metadata grid

### Lab Requests in the Riverside Apartment Case
| Lab Request | Input Evidence | Output Evidence | Analysis Type |
|------------|---------------|-----------------|---------------|
| `lab_fingerprint_glass` | `ev_wine_glasses` | `ev_julia_fingerprint_glass` | Fingerprint Analysis |
| `lab_fingerprint_desk` | `ev_desk_fingerprint_raw` | `ev_mark_fingerprint_desk` | Fingerprint Analysis |
| `lab_shoe_print` | `ev_shoe_print_raw` | `ev_shoe_print` | Footwear Analysis |

---

## Evidence Comparison

### Overview
Some evidence items can be compared against each other to generate an **insight** — not a new evidence item in the archive.

Comparison is a passive action (0 action cost). It represents the detective placing two items side by side and drawing a conclusion.

### How It Works
1. Player opens evidence item A (e.g., `ev_shoe_print`)
2. Clicks "Compare Evidence"
3. A comparison selector appears over the right panel showing all other discovered evidence as a scrollable list
4. Player selects evidence item B (e.g., `ev_julia_shoes`)
5. The system checks whether both selected items belong to the same authored `InsightData.source_evidence` set in the case data
  - **Valid pair:** The matching insight is discovered. Notification fires.
   - **Invalid pair:** A brief message: *"No forensic connection found between these items."* Nothing is generated.
6. The comparison selector closes

### Comparison Result
A successful comparison yields an `InsightData` result with:
- A story description tied to the selected evidence set
- Links back to the source evidence items
- Optional downstream effects such as strengthening a theory, enabling a warrant, or unlocking an interrogation topic
- No new `EvidenceData` item and therefore no new `discovery_method` label in the archive

### Comparisons in the Riverside Apartment Case
| Source Evidence Set | Insight | Outcome |
|---------------------|---------|---------|
| `ev_bank_transfer` + `ev_accounting_files` (+ broader money trail context) | `ins_embezzlement_scheme` | Unlocks the missing-money thread |
| `ev_julia_fingerprint_glass` + `ev_elevator_logs` | `ins_julia_presence` | Supports Julia-presence reasoning and enables the Julia warrant |
| `ev_hidden_safe` + `ev_personal_journal` | `ins_hidden_relationships` | Connects Julia and Mark's shared motive |

> **Decided (D1):** Invalid comparisons produce a brief inline message only — no junk evidence is generated. This is already implemented in `EvidenceManager.compare_evidence()`.
>
> **Implementation note:** Comparisons are defined as `InsightData` objects stored in `data/cases/riverside_apartment/timeline.json` under the `"insights"` key. There is no separate `comparisons.json` file. Each `InsightData` specifies `source_evidence`, `description`, and optionally `strengthens_theory`, `enables_warrant`, or `unlocks_topic`.

---

## Evidence States

Each evidence item tracks the following state:

| State Field | Values | Notes |
|-------------|--------|-------|
| `reviewed` | bool | True once player has opened the detail panel for this item |
| `pinned` | bool | Player bookmark — UI convenience only |
| `lab_status` | `none` / `submitted` / `complete` | Runtime status for evidence currently participating in the lab flow |
| `sent_to_board` | bool | Whether "Send to Board" has been clicked |
| `player_notes` | string | Free-text notes written by the player |

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

> **Decided (D3):** "Send to Board" auto-places the node in an inbox zone at a predefined position on the board canvas. The player then repositions it manually in the Board tab. `BoardManager.send_to_board()` is already called from `evidence_archive.gd` — the inbox zone coordinates need to be finalized. 🚧

---

## Player Notes

The statement expansion section includes a **free-text notes field** per statement link. The main evidence detail panel also includes the always-open `My Notes` section in the third column, directly below Referenced Statements.

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
| Pinning | 0 |
| Sending to Board | 0 |

**Rationale:** Analysis is the reward, not the action cost. Making evidence review cost actions would punish careful players and discourage the kind of deep engagement the game is built on. Time pressure comes from the limited actions available for *active* work (interrogations, location examination) — the Evidence tab is the thinking space between those decisions.

---

## Evidence Discovery Sources

Evidence can arrive in the archive from multiple sources. `discovery_method` records the evidence's original acquisition source only.

Lab processing state is tracked separately in `lab_status`, and comparison outcomes belong to the insight system rather than the evidence archive.

| Source | Method Label | Examples |
|--------|-------------|---------|
| Direct location examination | Visual Inspection | ev_knife, ev_wine_glasses |
| Forensic output evidence | Forensic Analysis | ev_julia_fingerprint_glass, ev_shoe_print |
| Morning briefing / case paperwork | Case File | ev_autopsy_report |
| Interrogation-surfaced evidence | Interrogation | *(future: evidence surfaced through questioning)* |
| Warrant execution | Search Warrant | ev_julia_shoes, ev_deleted_messages |
| Digital extraction / recovery | Digital Recovery | *(future device extraction outputs)* |

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
  → EvidenceManager.compare_evidence(evidence_id_a, evidence_id_b)
  → Checks CaseManager.get_all_insights() for a matching source_evidence set
    → If valid: GameManager.discover_insight(insight_id)
      → insight_generated signal
      → NotificationManager.notify_story("New insight: ...")
    → If invalid: returns null → UI message

Statement verdict classification
  → EvidenceManager.set_statement_verdict(evidence_id, statement_id, verdict)
  → Stores in EvidenceManager._statement_verdicts
  → Updates verdict pill in UI via statement_verdict_changed signal
  → EvidenceManager.contradiction_detected signal (if verdict = CONTRADICTION)
     → Feeds into case evaluation system (ConclusionManager)

Send to board
  → BoardManager.send_to_board("evidence", evidence_id)
  → BoardManager.node_added signal
  → NotificationManager: "Added to board"
  → [🚧 evidence_sent_to_board signal — planned, not yet implemented]
```

---

## Data Model Notes

### Evidence Data Fields (from `evidence.json`)

> **Note:** `weight` is stored as a float from 0.0–1.0 and is used internally for qualitative tiering and prosecutor scoring. `importance_level` is separate case-role metadata used for guidance and evidence-detail presentation. Prosecutor coverage remains separately authored through `CaseData.critical_evidence_ids`. `evidentiary_value_text` stores the evidence-specific reasoning sentence shown to the player. All enum strings (`type`, `importance_level`, `discovery_method`, `legal_categories`) are upper-case. `discovered_day` has been removed from the data model — the day evidence was found is derived at runtime: `GameManager.get_evidence_discovery_day(id)` stores `current_day` when `discover_evidence()` is called. Discovery order is implicit in the insertion order of `GameManager.discovered_evidence`.

```json
{
  "id": "ev_parking_camera",
  "name": "Parking Lot Camera Footage",
  "description": "Security camera footage from the parking lot showing Mark Bennett leaving the building at 20:40.",
  "type": "RECORDING",
  "importance_level": "REQUIRED",
  "weight": 0.7,
  "evidentiary_value_text": "Fixes Mark's departure time and tests whether his timeline is truthful.",
  "location_found": "loc_parking_lot",
  "lab_analysis_results": [],
  "discovery_method": "VISUAL",
  "related_persons": ["p_mark"],
  "legal_categories": ["PRESENCE"],
  "linked_statements": ["stmt_mark_departure_time", "stmt_mark_corrected_departure", "stmt_mark_lied_to_hide_argument"],
  "hint_text": "Check the security camera in the parking lot.",
}
```

### Player Evidence State (runtime, persisted)

State is split across multiple systems. Fields below show what IS currently tracked (✅) vs. what is planned but not yet implemented (🚧).

**`GameManager.discovered_evidence`** (Array[String]):
- ✅ Discovery order is implicit in the array insertion order (newest = last appended)

**`EvidenceManager.pinned_evidence`** (Array[String]):
- ✅ Pinned evidence IDs; players can pin any discovered evidence item

**`EvidenceManager._statement_verdicts`** (Dictionary, key: `"evidence_id:statement_id"`):
```json
{
  "ev_parking_camera:stmt_mark_departure_time": {
    "evidence_id": "ev_parking_camera",
    "statement_id": "stmt_mark_departure_time",
    "verdict": "contradiction",
    "player_note": ""
  }
}
```

**Per-evidence extended state (🚧 planned — not yet implemented in `EvidenceManager`):**
```json
{
  "ev_parking_camera": {
    "reviewed": true,
    "sent_to_board": true,
    "player_notes": "",
  }
}
```

> **Note:** `lab_status` is stored on the `EvidenceData` resource itself (`Enums.LabStatus`), not in a separate player state dictionary.

---

## Design Decisions

All design questions have been resolved. Decisions are final.

**D1 — Invalid evidence comparisons:** Silent inline message only — no junk evidence items are generated. ✅ *Already implemented in `EvidenceManager.compare_evidence()`.*

**D3 — "Send to Board" placement:** Auto-place in an inbox zone at a predefined position on the board canvas. The player repositions it in the Board tab. `BoardManager.send_to_board()` is already called from `evidence_archive.gd` — the inbox zone coordinates need to be finalized. 🚧 *Inbox zone position not yet finalized.*

**D4 — Comparison from either item:** Available from either evidence item in a pair. ✅ *Already implemented — `EvidenceManager.compare_evidence(a, b)` works symmetrically.*

**D5 — Raw evidence after lab result arrives:** `derive` results keep the raw evidence discoverable and the Forensic Analysis block links to the completed result. `upgrade` results replace the raw evidence in the discovered archive, while the analyzed child still keeps `derived_from` metadata pointing back to the raw input. ✅ *Matches current runtime behavior.*

**D6 — Nav badge count for unreviewed evidence:** Removed — the Evidence tab nav icon does not show an unreviewed-items counter. The NEW badge on individual evidence cards in the archive is sufficient.

---

## Code Reference

### UI — Screens & Components

| File | Purpose |
|------|---------|
| `scripts/ui/screens/evidence_archive.gd` | **Main evidence screen** — owns the archive grid shell and wires the evidence detail panel |
| `scenes/ui/evidence_archive.tscn` | Scene for the evidence screen |
| `scripts/ui/components/evidence_detail_panel.gd` | Right-panel coordinator for the selected evidence item |
| `scripts/ui/components/evidence_lab_section.gd` | Forensic analysis block for available / pending / completed analyses, driven by `lab_analysis_results` plus `LabRequestData` |
| `scripts/ui/components/evidence_value_section.gd` | Evidentiary Value component showing qualitative tier, case-authored interpretation, and contested warning |
| `scripts/ui/components/evidence_polaroid.gd` | Polaroid card used in the evidence grid (`EvidencePolaroid` class) |
| `scripts/ui/components/evidence_statements_panel.gd` | Container component that renders all statement items for the selected evidence (`EvidenceStatementsPanel` class) |
| `scripts/ui/components/statement_item.gd` | Single statement row with verdict cycle button (`StatementItem` class) |

> **Note:** There are no separate `evidence_tab.gd`, `evidence_archive.gd` (component), `lab_submit_section.gd`, or `compare_selector.gd` files. `scripts/ui/components/evidence_card.gd` has been **deleted** — `EvidencePolaroid` (`scripts/ui/components/evidence_polaroid.gd`) is the canonical evidence card component.

### Managers

| File | Purpose |
|------|---------|
| `scripts/managers/evidence_manager.gd` | Evidence state: filtering, pinning, comparisons, verdicts, lab submission proxy, contradiction detection |
| `scripts/managers/lab_manager.gd` | Lab request creation, submission, overnight processing |
| `scripts/managers/board_manager.gd` | Board node management; `send_to_board("evidence", id)` |
| `scripts/managers/game_manager.gd` | `discovered_evidence` array; `evidence_discovered` signal |
| `scripts/managers/case_manager.gd` | Case data access: `get_evidence()`, `get_all_statements()`, `get_all_insights()` |

### Data Classes

| File | Purpose |
|------|---------|
| `scripts/data/evidence_data.gd` | `EvidenceData` resource class |
| `scripts/data/statement_data.gd` | `StatementData` resource class |
| `scripts/data/statement_verdict_data.gd` | `StatementVerdictData` — player verdict per statement-evidence pair |
| `scripts/data/insight_data.gd` | `InsightData` — what this concept calls "comparison pairs"; `source_evidence` holds the two evidence IDs |

### Case Data Files

| File | Purpose |
|------|---------|
| `data/cases/riverside_apartment/evidence.json` | All evidence items and metadata |
| `data/cases/riverside_apartment/timeline.json` | `"statements"` array (all statements) + `"insights"` array (comparison pairs / InsightData) |
| `data/cases/riverside_apartment/suspects.json` | Persons data |

> **Note:** There is no separate `comparisons.json` or `statements.json`. Both live inside `timeline.json`.
