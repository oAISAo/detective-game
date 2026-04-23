# Map Tab — Concept & Reference

## Overview

The Map tab is the player's gateway to physical investigation. It presents all unlocked locations as cards on a grid. Clicking a card opens the **Location Detail Screen** where the player examines investigable targets and discovers evidence.

**Core loop:** Map → Select Location → Select Target → Examine → Discover Evidence → Return to Map

**Key principle:** The map tab is ONLY for evidence gathering through visual inspection. All forensic analysis (fingerprint matching, shoe print comparison, etc.) happens in the Evidence tab. Evidence found here is always raw/unanalyzed.

---

## Map Screen

### Layout
- A flow grid (`HFlowContainer`) of location cards
- Only **unlocked** locations are displayed (others are hidden, not greyed out)
- Cards refresh automatically when game state changes (evidence discovered, location unlocked, lab completed, conditional target unlocked, etc.)

### Location Cards
Each card is a cinematic photo-card tile showing:
- **Image** — Location photograph (or placeholder with location name initial)
- **Title** — Location name (uppercase)
- **Description** — First sentence of the location description
- **Evidence count** — `"?"` if unvisited, `"X / Total"` if visited
- **Status badge** — One of three states:

| Badge | Color | Meaning |
|-------|-------|---------|
| **NEW** | Blue | Not yet visited, or new content available after exhaustion |
| **OPEN** | Amber | Visited, investigation in progress |
| **EXHAUSTED** | Grey | All currently visible targets examined |

### Evidence Count Display
- **Unvisited location:** Shows `"?"`
- **Visited location:** Shows `"X / Y"` where:
  - X = evidence items discovered so far
  - Y = total evidence from ALL targets (including conditionally hidden ones)
- The total includes hidden target evidence intentionally — this tells the player there's more to find without telling them how. Example: "2 / 6" when only 2 targets are visible means 4 more evidence items exist behind conditional targets.

### Card Interactions
- **Hover** — Subtle scale-up (1.008x), blue border, shadow glow
- **Click** — Navigates to Location Detail Screen via `ScreenManager`
- Entry is **free** (0 actions) — the player can enter and leave locations freely

### Card Refresh Triggers
The map re-renders when any of these signals fire:
- `GameManager.location_unlocked` / `location_visited` / `evidence_discovered` / `evidence_upgraded` / `game_reset`
- `LocationInvestigationManager.object_state_changed` / `location_completed` / `state_loaded`
- `LabManager.lab_submitted` / `lab_completed`

### Status Transitions

| From | To | Trigger |
|------|----|---------|
| (not visible) | NEW | Location unlocked |
| NEW | OPEN | First visit (even without examining anything) |
| OPEN | OPEN | Partial examination |
| OPEN | EXHAUSTED | All currently visible targets examined |
| EXHAUSTED | NEW | New conditional target becomes visible |
| NEW | OPEN | Player revisits (after EXHAUSTED → NEW) |

---

## Location Detail Screen

### Layout (3-Column)
```
┌─────────────┬──────────────────┬─────────────────────┐
│ LEFT PANEL  │  CENTER PANEL    │  RIGHT PANEL        │
│             │                  │                     │
│ Target List │  Scene Image     │  Detail View        │
│             │  (location       │  • Target name      │
│ • Kitchen   │   photo or       │  • Description      │
│ • Living Rm │   placeholder)   │  • Status           │
│ • Phone     │                  │  • Action button    │
│             │                  │  • Discovered clues │
│             │                  │    (polaroid grid)  │
└─────────────┴──────────────────┴─────────────────────┘
Header: Location title + Evidence count (X / Total)
Footer: Back button → returns to map
```

### Left Panel — Target List
- Lists all **currently visible** investigable targets as buttons
- Targets whose `discovery_condition` is not yet met are completely hidden (not greyed out, not locked)
- Each button shows: `"• Target Name"`
- Selected target is visually highlighted
- Clicking a target shows its details in the right panel

### Center Panel — Scene Image
- Shows the location image (or a placeholder with location initial and name)
- Provides visual context for the investigation

### Right Panel — Detail View
When no target is selected: placeholder state ("Select a target to investigate")

When a target is selected:
1. **Target name** (title)
2. **Description** (what the player observes)
3. **Status indicator** with color:
   - "Not inspected" (amber) — `NOT_INSPECTED`
   - "Fully processed" (grey) — `FULLY_PROCESSED`
4. **Action button** — One button per target:
   - "Visual Inspection" for physical objects, or "Examine" for digital objects
   - Costs 1 action
   - Shows "completed" state (greyed/checkmark) if already examined
   - Shows "disabled" if no actions remaining
   - When disabled, a hint text reads *"No actions remaining. End the day to continue."* in italic
5. **Discovered clues** — Polaroid-style grid of evidence found from this target
   - Each polaroid card is **clickable** — clicking navigates to the evidence detail screen for that piece of evidence
   - Polaroid hover: subtle dim effect on mouse-over to signal interactivity
   - All polaroids in a row are the same size regardless of whether the evidence name is one or two lines; the name area is always sized for two lines with the text centered vertically

---

## Investigation Flow

### Step-by-Step
1. Player enters location (free, 0 actions)
2. Location is marked as "visited" on first entry
3. Player selects an investigable target from the left panel
4. Right panel shows target details and the action button
5. Player clicks the action button (costs 1 action)
6. `LocationInvestigationManager.inspect_object()` is called
7. Evidence matching the target's `evidence_results` is discovered
8. Notification popup shows each discovered evidence item **first**
9. Any conditional triggers (e.g. new location unlocked) fire their notifications **after** the evidence notification — ensuring evidence is always acknowledged before follow-up events
10. Target state updates: NOT_INSPECTED → FULLY_PROCESSED
11. Discovered clues appear as polaroids below the action button
12. Player can select another target or go back to the map

### Action Button
Each target has exactly one action button:

| Label | Used For | Cost |
|-------|----------|------|
| Visual Inspection | Physical objects (kitchen, furniture, etc.) | 1 action |
| Examine | Digital objects (phones, security systems, devices) | 1 action |

Both labels map to the same internal action (`inspect_object()`). The label difference is purely for narrative flavor.

### Evidence Discovery
All evidence in the map tab is discovered through **visual inspection**. The player sees, observes, and collects — but does not analyze.

| What the player finds | What happens next |
|----------------------|-------------------|
| Raw fingerprints (smudges on a desk) | Found as `ev_desk_fingerprint_raw`. Analysis happens in Evidence tab |
| Shoe print in hallway | Found as `ev_shoe_print_raw`. Analysis happens in Evidence tab |
| Documents, photos, objects | Found as-is. May provide leads to other locations/targets |
| Digital evidence (messages, logs) | Found as-is via Examine action |

---

## Conditional Target Visibility

Some targets only become visible after specific evidence is discovered elsewhere.

### How It Works
- Targets can have a `discovery_condition` field: `{ "requires_evidence": ["ev_some_evidence"] }`
- Targets with unmet conditions are **completely hidden** — not shown in the target list, not greyed out, no hints
- When the condition is met, the target appears in the list with a **brief reveal animation**: it slides down and fades in (0.35s), then pulses with a soft blue highlight (0.4s) to draw the player's attention
- A notification fires: *"New lead: [contextual message suggesting the player revisit the location]"*
- The location card status transitions from EXHAUSTED → NEW if applicable

### Evidence Count and Hidden Targets
The total evidence count on the location card includes evidence from ALL targets (visible and hidden). This means:
- Player visits office, sees 2 targets, examines both → card shows "3 / 6"
- Player knows 3 more evidence items exist but doesn't know how to find them
- This creates the challenge: figure out what unlocks the remaining targets

### Office Example (Riverside Apartment Case)
| Target | Evidence | Condition |
|--------|----------|-----------|
| Office Desk | ev_daniel_email | Always visible |
| File Cabinet | ev_bank_transfer, ev_accounting_files | Always visible |
| Bookshelf | ev_hidden_safe | Visible after `ev_accounting_files` discovered |
| Desk Drawer | ev_personal_journal | Visible after `ev_hidden_safe` discovered (key from safe) |

**Progression:** Examine File Cabinet → discover accounting files → Bookshelf appears → Examine Bookshelf → find safe with key → Desk Drawer appears → Examine Desk Drawer → find journal

---

## Locations — Riverside Apartment Case

### Currently in Data (to become 4 locations after cleanup)

#### 1. Victim's Apartment (`loc_victim_apartment`)
The crime scene. Always available from Day 1.

**Investigable Targets:**
| Target | Action | Evidence Produced |
|--------|--------|-------------------|
| Kitchen | Visual Inspection | ev_knife, ev_knife_block |
| Living Room | Visual Inspection | ev_wine_glasses, ev_broken_picture_frame, ev_wine_bottle |
| Victim's Phone | Examine | ev_julia_text_message, ev_mark_call_log |
| Study Desk (NEW) | Visual Inspection | ev_desk_fingerprint_raw |

#### 2. Building Hallway (`loc_hallway`)
Security systems and maintenance. Always available from Day 1.

**Investigable Targets:**
| Target | Action | Evidence Produced |
|--------|--------|-------------------|
| Hallway Floor | Visual Inspection | ev_shoe_print_raw |
| Building Security System | Examine | ev_hallway_camera, ev_elevator_logs |
| Maintenance Office | Visual Inspection | ev_lucas_work_log |

#### 3. Parking Lot (`loc_parking_lot`)
Security camera covering building entrance. Always available from Day 1.

**Investigable Targets:**
| Target | Action | Evidence Produced |
|--------|--------|-------------------|
| Parking Lot Security Camera | Examine | ev_parking_camera |

#### 4. Victim's Office (`loc_victim_office`)
Daniel's financial consulting firm. **Unlocked by evidence** (discovering `ev_mark_call_log` or `ev_daniel_email` or `ev_bank_transfer`).

**Investigable Targets:**
| Target | Action | Evidence Produced | Condition |
|--------|--------|-------------------|-----------|
| Office Desk | Visual Inspection / Examine | ev_daniel_email | Always visible |
| File Cabinet | Visual Inspection | ev_bank_transfer, ev_accounting_files | Always visible |
| Bookshelf | Visual Inspection | ev_hidden_safe | After `ev_accounting_files` |
| Desk Drawer | Visual Inspection | ev_personal_journal | After `ev_hidden_safe` (key from safe) |

### Removed
- **Neighbor's Apartment** (`loc_neighbor_apartment`) — Removed. Sarah's testimony moves to Persons tab.

---

## Location Unlocking (Evidence-Driven)

| Location | Unlock Condition |
|----------|-----------------|
| Victim's Apartment | Always (crime scene) |
| Building Hallway | Always (part of crime scene building) |
| Parking Lot | Always (building premises) |
| Victim's Office | Discover `ev_mark_call_log` OR `ev_daniel_email` OR `ev_bank_transfer` |

The office unlocks when the player discovers evidence of Daniel's business connections, making it a natural investigative step.

---

## Action Economy (Map Tab)

| Action Type | Cost | Examples |
|-------------|------|---------|
| Enter/leave location | 0 | Opening any location card on the map |
| Examine target | 1 | Visual inspection, examine device |

**Budget:** 4 actions per day, 4 days = 16 total actions. Map tab actions compete with interrogations for the daily budget.

**When actions run out:**
- Action button shows as disabled (greyed out)
- Player can still browse locations and review discovered evidence (free)
- Actions reset at the start of each new day

---

## Object Investigation States

### States (tracked by LocationInvestigationManager)
| State | Meaning |
|-------|---------|
| `NOT_INSPECTED` | Target has not been examined |
| `FULLY_PROCESSED` | Target has been examined, all evidence discovered |

**Note:** With no tools in the map tab, there is no PARTIALLY_EXAMINED state. Each target has exactly one action — once examined, it's fully processed.

### Display States (UI)
| Display State | Label | Color |
|---------------|-------|-------|
| `NOT_INSPECTED` | "Not inspected" | Amber |
| `FULLY_PROCESSED` | "Fully processed" | Grey |
**Lab submission does not affect map-tab status.** Once a target is examined (FULLY_EXAMINED), its display status is always FULLY_PROCESSED — even if the player has submitted the raw evidence to the lab. Lab submission is an Evidence-tab concern. `AWAITING_LAB_RESULTS` is reserved for hypothetical future multi-step objects.
---

## Lab Integration

The map tab discovers raw evidence. Lab processing happens separately.

When raw evidence has `requires_lab_analysis: true`:
1. The raw evidence is discovered at the location (e.g., `ev_shoe_print_raw`)
2. Player submits it to the lab (via Evidence tab or lab request system)
3. Lab processes it overnight (completion on the next day)
4. Results arrive the next morning as new evidence (e.g., `ev_shoe_print`)

**Lab requests defined in data:**
| Lab Request | Input Evidence | Output Evidence | Analysis Type |
|------------|---------------|-----------------|---------------|
| `lab_fingerprint_glass` | `ev_wine_glasses` | `ev_julia_fingerprint_glass` | fingerprint_analysis |
| `lab_fingerprint_desk` | `ev_desk_fingerprint_raw` | `ev_mark_fingerprint_desk` | fingerprint_analysis |
| `lab_shoe_print` | `ev_shoe_print_raw` | `ev_shoe_print` | footwear_analysis |

**Note:** Lab results are separate evidence items from the raw evidence. The map tab only counts evidence it discovers directly (raw items from investigable targets). Lab results are tracked separately.

---

## Autopsy Report

The autopsy report (`ev_autopsy_report`) is delivered automatically and for free as part of the Day 1 morning briefing. It's standard police procedure — the coroner's report arrives before the detective begins active investigation.

- Delivered alongside the case introduction
- No action cost
- Notification: "Coroner's report received: preliminary autopsy results"
- Establishes: cause of death (stab wound), estimated time of death (~21:00), relevant forensic findings

---

## State Persistence

`LocationInvestigationManager` tracks:
- `_object_states`: `{ location_id: { object_id: InvestigationState } }` — which targets have been examined
- `_performed_actions`: `{ "location_id:object_id": ["action1"] }` — which actions performed
- `current_location_id`: which location the player is currently at

This state is serializable for save/load support.

---

## Signal Architecture

```
Player clicks location card
  → LocationCard.card_pressed(location_id)
  → LocationMap._on_location_pressed()
  → LocationInvestigationManager.start_investigation()
     → GameManager.visit_location() (if first visit)
     → investigation_started signal
  → ScreenManager.navigate_to("location_investigation")

Player clicks action button
  → LocationInvestigation._on_inspect_pressed()
  → LocationInvestigationManager.inspect_object()
     → GameManager.use_action() (consumes 1 action)
     → GameManager.discover_evidence() (for each found)
        → evidence_discovered signal
     → evidence_found signal
     → object_state_changed signal
     → location_completed signal (if all visible targets done)
  → NotificationManager.notify_evidence() (popup)
  → UI refresh

Player clicks back button
  → LocationInvestigationManager.leave_location()
  → ScreenManager.navigate_back()
  → LocationMap refreshes (via signals)

Conditional target unlocked (via evidence_discovered signal)
  → LocationInvestigationManager checks discovery_conditions
  → If target becomes visible at an EXHAUSTED location → status → NEW
  → NotificationManager fires "New lead" notification
  → LocationMap refreshes → card shows NEW badge
```

---

## Code Reference

| File | Purpose |
|------|---------|
| `scripts/ui/screens/location_map.gd` | Map screen with location card grid |
| `scripts/ui/screens/location_investigation.gd` | Location detail/investigation screen |
| `scripts/ui/components/location_card.gd` | Individual location card component |
| `scripts/ui/components/clues_section.gd` | Polaroid grid for discovered evidence |
| `scripts/ui/components/evidence_polaroid.gd` | Individual evidence polaroid card |
| `scripts/ui/components/action_button.gd` | Investigation action button |
| `scripts/managers/location_investigation_manager.gd` | Investigation state and evidence discovery logic |
| `scripts/managers/evidence_manager.gd` | Evidence filtering, contradictions, hints |
| `scripts/managers/game_manager.gd` | Global state: actions, locations, evidence |
| `scripts/data/location_data.gd` | LocationData class |
| `scripts/data/investigable_object_data.gd` | InvestigableObjectData class |
| `scripts/data/evidence_data.gd` | EvidenceData class |
| `scenes/ui/location_map.tscn` | Map screen scene |
| `scenes/ui/location_investigation.tscn` | Investigation screen scene |
| `scenes/ui/components/location_card.tscn` | Location card scene |
| `data/cases/riverside_apartment/locations.json` | Location data |
| `data/cases/riverside_apartment/evidence.json` | Evidence data |
