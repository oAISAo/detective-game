# Persons Tab — Design Concept

## The Idea

Rename the current "Suspects" tab to **"Persons"** and expand it to include **all case-relevant people** — not just suspects. Each person becomes a hub for all person-specific actions: interrogation, autopsy, phone analysis, background checks, surveillance, and warrant-based searches.

---

## Why This Makes Sense

### Current Problems
1. **The victim has no home in the UI.** Daniel Ross is referenced everywhere but the player can't interact with him directly. The autopsy report (currently missing from the data) has no natural place.
2. **Person-specific evidence is scattered across locations.** Daniel's phone is at the apartment. Julia's shoes come from a warrant. Julia's deleted messages come from a warrant. Sarah's testimony comes from a location visit. There's no consistent pattern.
3. **The neighbor apartment exists only for Sarah's testimony.** It's a fake location — there's nothing to physically investigate. Testimony should come from the person, not a place.
4. **Warrants target people, but results appear from nowhere.** When you get a warrant to search Julia's phone, the results just appear. It would feel more natural if warrant results appeared under Julia's person card.

### What the Persons Tab Solves
- Every person-related action has a clear home
- The victim becomes a first-class entity (autopsy, phone, belongings)
- Testimonies come from people, not locations
- Warrant results appear where they logically belong
- Surveillance is requested and tracked per-person
- Removes the need for the neighbor apartment location

---

## Persons and Their Actions

### Daniel Ross (Victim)
**Available from:** Day 1 (always — he's the victim)

| Action | Type | Cost | Requirements | Evidence Produced |
|--------|------|------|-------------|-------------------|
| Request Autopsy | Person Action | 1 action | None | `ev_autopsy_report` (delivered next day via lab) |
| Examine Phone | Person Action | 1 action | Phone found at apartment (`ev_victim_phone`) | `ev_julia_text_message`, `ev_mark_call_log` |
| Review Background | Passive | 0 actions | None | Basic profile: age, profession, relationships |

**Design notes:**
- The physical phone is still **found** at the apartment as a physical object. But once found, detailed examination (reading messages, call logs) happens under Daniel's person card.
- The autopsy fills the gap of the currently missing autopsy evidence.
- This feels natural: "I want to learn more about the victim" → go to Daniel's card.

### Mark Bennett (Suspect)
**Available from:** Evidence-driven (see unlock proposal in caseJsonDataIssues.md)

| Action | Type | Cost | Requirements | Evidence Produced |
|--------|------|------|-------------|-------------------|
| Interrogate | Interrogation | 1 action | Unlocked | Statements (existing system) |
| Request Financial Check | Person Action | 1 action | `ev_bank_transfer` discovered | `ev_accounting_files` (or move to office?) |
| Request Surveillance | Person Action | 1 action | Warrant required | `evt_surv_mark_transfer` (next day) |

### Sarah Klein (Witness)
**Available from:** Day 1 (neighbor at the scene)

| Action | Type | Cost | Requirements | Evidence Produced |
|--------|------|------|-------------|-------------------|
| Interrogate | Interrogation | 1 action | Unlocked | Statements (existing system) |

**Design notes:**
- Sarah is simple — she's a witness. Her only real action is interrogation.
- Her testimony (`ev_sarah_testimony`, `ev_sarah_second_testimony`) is produced through interrogation, not by visiting her apartment.
- This completely removes the need for `loc_neighbor_apartment`.

### Julia Ross (Suspect)
**Available from:** Evidence-driven

| Action | Type | Cost | Requirements | Evidence Produced |
|--------|------|------|-------------|-------------------|
| Interrogate | Interrogation | 1 action | Unlocked | Statements (existing system) |
| Search Phone | Person Action | 1 action | Warrant (`warrant_julia_phone`) | `ev_deleted_messages` |
| Search Residence | Person Action | 1 action | Warrant (`warrant_julia_search`) | `ev_julia_shoes` |
| Request Financial Records | Person Action | 1 action | `ev_bank_transfer` discovered | `ev_julia_financial_records` |
| Request Surveillance | Person Action | 1 action | Warrant required | `evt_surv_julia_call` (next day) |

**Design notes:**
- Warrant-based actions are the big win here. "Search Julia's phone" and "Search Julia's residence" are clearly person-level actions, not location actions.
- Financial records request makes more sense as something you do regarding a person than something you find at a location.

### Lucas Weber (Suspect / Red Herring)
**Available from:** Evidence-driven

| Action | Type | Cost | Requirements | Evidence Produced |
|--------|------|------|-------------|-------------------|
| Interrogate | Interrogation | 1 action | Unlocked | Statements (existing system) |
| Request Key Access Logs | Person Action | 0 actions | `ev_lucas_work_log` discovered | Proof he didn't enter apartment (clears him) |

---

## How It Changes the Game Flow

### Before (Current)
```
Player finds phone at apartment → immediately reads messages (location action)
Player visits neighbor apartment → gets Sarah's testimony (location action)
Player obtains warrant for Julia → deleted messages appear from nowhere
```

### After (Persons Tab)
```
Player finds phone at apartment → picks it up as evidence
Player goes to Daniel's person card → "Examine Phone" → reads messages (person action)
Player goes to Sarah's person card → "Interrogate" → gets testimony (person action)
Player obtains warrant → goes to Julia's person card → "Search Phone" → deleted messages (person action)
```

The flow becomes: **discover connection → go to person → take action**. This mirrors how real investigations work.

---

## What Stays at Locations vs What Moves to Persons

### Stays at Locations (Physical Investigation)
These are things you find BY searching a physical place:
- Murder weapon in the kitchen sink
- Wine glasses on the table
- Broken picture frame on the floor
- Shoe print in the hallway
- Security camera footage (building system)
- Elevator logs (building system)
- Wine bottle, knife block
- Victim's phone (the physical object)
- Documents in the office (email printouts, file cabinet contents)
- Hidden safe

### Moves to Persons (Person-Specific Actions)
These are things you learn FROM or ABOUT a person:
- Autopsy report → Daniel
- Phone content analysis (messages, call logs) → Daniel (or suspect if warrant)
- Deleted messages recovery → Julia (warrant)
- Shoes seizure → Julia (warrant)
- Financial records → Julia, Mark
- Testimonies → Sarah (interrogation)
- Surveillance results → Julia, Mark
- Background checks → any person

### The Rule of Thumb
> **If you need the PLACE to find it → Location.**
> **If you need the PERSON to get it → Persons tab.**

A shoe print is on the floor — you need the hallway to find it.
A testimony is in someone's head — you need the person to get it.
Deleted messages are on someone's phone — you need access to their device.

---

## UI Concept

### Person Card Layout
```
┌─────────────────────────────────────────┐
│  [Portrait]   JULIA ROSS                │
│               Role: Suspect             │
│               Relation: Victim's Wife   │
│               Status: Person of Interest│
├─────────────────────────────────────────┤
│  AVAILABLE ACTIONS                      │
│  ┌─────────────┐  ┌──────────────────┐  │
│  │ Interrogate │  │ Search Phone 🔒  │  │
│  │             │  │ (requires warrant)│  │
│  └─────────────┘  └──────────────────┘  │
│  ┌─────────────────┐  ┌──────────────┐  │
│  │ Search Residence │  │ Request      │  │
│  │ 🔒 (warrant)    │  │ Surveillance │  │
│  └─────────────────┘  └──────────────┘  │
├─────────────────────────────────────────┤
│  KNOWN STATEMENTS                       │
│  • "I wasn't at the apartment that      │
│     night." (Day 1)                     │
│  • "I visited earlier in the day."      │
│     (Day 2 — contradicted)              │
├─────────────────────────────────────────┤
│  RELATED EVIDENCE                       │
│  • Julia's Fingerprint on Wine Glass    │
│  • Elevator Logs (key card at 20:48)    │
│  • Text Message to Daniel (20:40)       │
└─────────────────────────────────────────┘
```

### Victim Card (Daniel) — Different Layout
```
┌─────────────────────────────────────────┐
│  [Portrait]   DANIEL ROSS              │
│               Role: Victim              │
│               Age: 42                   │
│               Profession: Financial     │
│               Consultant                │
├─────────────────────────────────────────┤
│  AVAILABLE ACTIONS                      │
│  ┌─────────────────┐  ┌──────────────┐ │
│  │ Request Autopsy  │  │ Examine      │ │
│  │ (sends to lab)   │  │ Phone 🔒     │ │
│  │                  │  │ (phone found)│ │
│  └─────────────────┘  └──────────────┘ │
│  ┌─────────────────┐                    │
│  │ Review Profile   │                   │
│  │ (free action)    │                   │
│  └─────────────────┘                    │
├─────────────────────────────────────────┤
│  AUTOPSY RESULTS (when available)       │
│  • Cause of death: single stab wound   │
│  • Time of death: ~21:00               │
│  • No defensive wounds                 │
├─────────────────────────────────────────┤
│  RELATIONSHIPS                          │
│  • Julia Ross (Wife — separated)        │
│  • Mark Bennett (Business Partner)      │
└─────────────────────────────────────────┘
```

---

## Unlocking Persons (Progressive Discovery)

Not all persons are visible from the start. They appear as the player discovers connections:

| Person | Initially Visible? | Unlock Condition |
|--------|-------------------|------------------|
| Daniel Ross | Yes | Always (he's the victim) |
| Sarah Klein | Yes | Always (neighbor/witness at scene) |
| Mark Bennett | No | Discover `ev_mark_call_log` OR `ev_desk_fingerprint_raw` OR `ev_daniel_email` |
| Julia Ross | No | Discover `ev_julia_text_message` OR `ev_broken_picture_frame` OR `ev_julia_fingerprint_glass` |
| Lucas Weber | No | Discover `ev_lucas_work_log` OR examine maintenance office in hallway |

This creates a natural feeling: "Who is this Mark Bennett who's been calling Daniel?" → Mark appears as a person of interest → player can now interrogate him.

---

## Impact on Existing Systems

### Evidence that Changes Location
| Evidence | Current `location_found` | New Home |
|----------|------------------------|----------|
| `ev_sarah_testimony` | `loc_neighbor_apartment` | Person action: Sarah interrogation |
| `ev_sarah_second_testimony` | `loc_neighbor_apartment` | Person action: Sarah interrogation (pressure) |
| `ev_deleted_messages` | empty | Person action: Julia → Search Phone |
| `ev_julia_shoes` | empty | Person action: Julia → Search Residence |
| `ev_julia_financial_records` | empty | Person action: Julia → Request Financial Records |
| `ev_julia_text_message` | `loc_victim_apartment` | Person action: Daniel → Examine Phone |
| `ev_mark_call_log` | `loc_victim_apartment` | Person action: Daniel → Examine Phone |
| NEW: `ev_autopsy_report` | n/a | Person action: Daniel → Request Autopsy |

### What Gets Removed
- `loc_neighbor_apartment` — fully replaced by Sarah's person card
- `obj_sarah_interview` investigable object — replaced by interrogation

### What Gets Added
- Victim person card with autopsy + phone examination
- Person-level actions: Search Phone, Search Residence, Request Financial Records, Request Surveillance
- Lock indicators for warrant-required actions

---

## Resolved Design Decisions

### Decision 1: Victim's Phone Stays at Apartment

The phone is a **physical object** at the crime scene. It stays as an investigable target in the apartment.

**How it works:**
- `obj_victim_phone` remains an investigable target in the apartment's living room
- Examining it (1 action) produces `ev_julia_text_message` and `ev_mark_call_log`
- **Remove `ev_victim_phone` as a standalone evidence item** — the phone is a target/object, not evidence. The evidence is what's ON the phone (the text message and call log)

**Why this is the right call:**
- No extra steps or clicks — player examines the phone at the crime scene, gets the evidence
- Physically logical — the phone is on the table, you pick it up and read it right there
- The person-level phone actions are reserved for **warrant-based access** to other people's phones (e.g., "Search Julia's Phone" after obtaining a warrant)

**Data changes:**
- Remove `ev_victim_phone` from `evidence.json`
- Remove `ev_victim_phone` from `loc_victim_apartment` evidence_pool
- Keep `obj_victim_phone` in `locations.json` but update its `evidence_results` to only `["ev_julia_text_message", "ev_mark_call_log"]`

---

### Decision 2: Office Targets Redesign

**Problem:** The hidden safe is listed as an investigable target, which makes it obviously visible. "Personal Items" is too vague as a target. Evidence shouldn't also be targets.

**New office targets (replaces current 4 targets):**

| Target | What It Represents | Evidence Produced | Discovery Condition |
|--------|--------------------|-------------------|-------------------|
| **Office Desk** | Daniel's work desk with computer and papers | `ev_daniel_email` | Always available |
| **File Cabinet** | Locked cabinet with financial documents | `ev_bank_transfer`, `ev_accounting_files` | Always available |
| **Bookshelf** | Large bookshelf against the wall | `ev_hidden_safe` (safe found behind books) | Only after `ev_accounting_files` discovered |
| **Desk Drawer** | Locked personal drawer in the desk | `ev_personal_journal` | Only after `ev_hidden_safe` discovered |

**The investigation chain:**
```
Office Desk → email reveals financial tension
    ↓
File Cabinet → bank transfers + accounting files reveal embezzlement
    ↓
Bookshelf → accounting irregularities motivate a deeper search →
            player finds hidden safe behind books → full scheme revealed
    ↓
Desk Drawer → knowing Daniel was documenting everything motivates
              checking his personal drawer → journal found
```

**Why this works:**
- The safe is genuinely hidden — the player doesn't see "Hidden Safe" as a clickable target. They see a bookshelf. The safe is the EVIDENCE found by examining the bookshelf.
- The journal is found in a specific place (desk drawer), not vague "personal items"
- Each discovery motivates the next: financial docs → deeper search → safe → personal notes
- Targets that appear only after conditions are met create a sense of progressive discovery
- The player uses 4 actions to fully investigate the office, but the first two are always available and the last two unlock through evidence chains

**Data changes:**
- Replace `obj_office_safe` with `obj_bookshelf` — description: "A large bookshelf covering most of the back wall. Books on finance, law, and consulting."
- Replace `obj_personal_items` with `obj_desk_drawer` — description: "A locked personal drawer in Daniel's desk."
- `obj_bookshelf` only appears as investigable after `ev_accounting_files` discovered
- `obj_desk_drawer` only appears as investigable after `ev_hidden_safe` discovered
- `ev_hidden_safe` description updated: "A hidden safe found behind the bookshelf in Daniel's office. Contains documents..."

---

### Decision 3: Background Info on Person Cards (Free, No Action Cost)

Basic profile information is available on each person's card as soon as they are unlocked. No action required — this is what the police would have from standard records.

**What's included (free):**
- Full name, age, photo
- Profession / occupation
- Relationship to victim
- Known address
- Reason they're a person of interest (e.g., "Business partner of victim" or "Neighbor — reported hearing disturbance")

**What requires actions:**
- Interrogation (1 action)
- Warrant-based searches (1 action)
- Surveillance requests (1 action)

This gives the player context before committing an action to interrogate someone.

---

### Decision 4: Action Economy (Unchanged)

With the phone staying at the apartment, the action count remains the same as before. The office redesign also keeps 4 targets (desk, file cabinet, bookshelf, desk drawer), so no change there.

The current 16-action budget (4 actions x 4 days) works with this design. See `wholeStoryHappyFlow.md` for the full breakdown, noting that the actual day count may vary since we're moving to evidence-driven unlocking (see scoring concept).

---

### Decision 5: Surveillance — Warrant + Action with Lock UI

**How surveillance works:**

1. **Locked by default.** Each person card can show surveillance options (Phone Tap, Financial Monitoring) but they appear **locked** with a lock icon and muted/red styling.

2. **Unlock via evidence threshold.** The lock opens when the player has gathered sufficient evidence meeting the warrant categories (PRESENCE, MOTIVE, CONNECTION, OPPORTUNITY — need 2+ categories, same as the warrant system).

3. **Activate via action.** Once unlocked, the player spends **1 action** to activate the surveillance. Results arrive the next day.

4. **Visual feedback:**
```
┌──────────────────────────┐
│  📞 Phone Tap            │
│  ══════════════════      │
│  Status: LOCKED 🔒       │
│  Need: 2 evidence        │
│  categories to unlock    │
│                          │
│  Current evidence:       │
│  ✓ PRESENCE (fingerprint)│
│  ✗ MOTIVE               │
│  ✗ CONNECTION            │
└──────────────────────────┘

       ↓ (after gathering more evidence)

┌──────────────────────────┐
│  📞 Phone Tap            │
│  ══════════════════      │
│  Status: AVAILABLE 🔓    │
│  [Activate - 1 action]   │
│                          │
│  Results arrive tomorrow │
└──────────────────────────┘
```

5. **This pattern extends to all warrant-like actions:**
   - Phone Tap → person card
   - Financial Monitoring → person card
   - Search Phone → person card
   - Search Residence → person card
   
   All use the same lock/unlock mechanic: gather enough evidence categories → unlock → spend action → get results.

**Note:** This concept needs a full detailed design document covering edge cases, UI states, and the exact evidence-to-category mapping. This is the directional decision.
