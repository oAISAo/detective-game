# Map Tab — TODOs

## DATA CHANGES (Case JSON Files)

### TODO-MAP-01: Remove Neighbor's Apartment Location
**Priority:** Critical
**Files:** `locations.json`, `evidence.json`, `discovery_rules.json`, `events.json`
- Remove `loc_neighbor_apartment` from `locations.json`
- Remove `obj_sarah_interview` investigable object
- Move `ev_sarah_testimony` and `ev_sarah_second_testimony` to the interrogation system (Persons tab)
- Update `evidence.json`: change `location_found` from `"loc_neighbor_apartment"` to empty or remove
- Update `discovery_rules.json`: remove `dr_sarah_second_testimony` (or move to interrogation triggers)
- Update `events.json`: remove `unlock_location:loc_neighbor_apartment` from Day 1 briefing
- Update `events.json`: remove `act_visit_neighbor` action
- **Ref:** caseJsonDataIssues.md Issue #1, personsTabConcept.md

### TODO-MAP-02: Redesign Office Investigable Objects
**Priority:** Critical
**Files:** `locations.json`

**Decision:** Bookshelf is hidden until `ev_accounting_files` is discovered. Desk Drawer is a separate conditional target unlocked by a key found inside the safe.

- Replace `obj_office_safe` ("Hidden Safe") with `obj_bookshelf` ("Bookshelf")
  - Description: "A large bookshelf covering most of the back wall. Books on finance, law, and consulting."
  - evidence_results: `["ev_hidden_safe"]`
  - **Conditional visibility:** Only appears after `ev_accounting_files` is discovered
- Replace `obj_personal_items` ("Personal Items") with `obj_desk_drawer` ("Desk Drawer")
  - Description: "A locked personal drawer in Daniel's desk. Requires a key to open."
  - evidence_results: `["ev_personal_journal"]`
  - **Conditional visibility:** Only appears after `ev_hidden_safe` is discovered (key found inside safe)
- Keep `obj_office_desk` and `obj_file_cabinet` unchanged

**Design note:** The Desk Drawer is kept as a separate target (not a re-examinable phase of the Office Desk) for these reasons:
1. Simpler implementation — no need to support multi-phase objects
2. Clearer player feedback — a new target appearing in the list is an obvious signal
3. Narrative logic — the drawer requires a physical key from the safe, so it's a distinct interaction
4. Consistent pattern — all targets follow the same examine-once flow

- **Ref:** personsTabConcept.md Decision 2

### TODO-MAP-03: Implement Conditional Target Visibility
**Priority:** Critical
**Files:** `locations.json` (schema), `location_investigation_manager.gd`, `location_investigation.gd`
- Add a `discovery_condition` field to InvestigableObjectData (e.g., `"requires_evidence": ["ev_accounting_files"]`)
- `LocationInvestigationManager` must filter investigable objects based on conditions
- `location_investigation.gd` `_populate_objects()` must only show targets whose conditions are met
- **Hidden targets are completely invisible** until their condition is met — no "locked" hints, no greyed-out state
- When a condition is met (e.g., `ev_accounting_files` discovered), a notification fires telling the player to revisit: *"New lead: the accounting irregularities suggest there may be more hidden at Daniel's office."*
- **Evidence count:** The total evidence count on the location card should reflect ALL evidence at the location (including from hidden targets). This way the player sees e.g. "2 / 6" and knows there's more to find, creating motivation to revisit. The game should be hard — the player must figure out what to do to unlock the remaining evidence.

### TODO-MAP-04: Remove ev_victim_phone as Evidence
**Priority:** High
**Files:** `evidence.json`, `locations.json`
- Remove `ev_victim_phone` from `evidence.json` (it's a target/object, not evidence)
- Remove `ev_victim_phone` from `loc_victim_apartment` evidence_pool
- Update `obj_victim_phone` evidence_results to only `["ev_julia_text_message", "ev_mark_call_log"]`
- **Ref:** personsTabConcept.md Decision 1

### TODO-MAP-05: Fix Desk Fingerprint Discovery Path
**Priority:** Critical
**Files:** `locations.json`, `evidence.json`

**Decision:** No forensic tools in the map tab. The map tab is ONLY for evidence gathering through visual inspection. All evidence discovered in the map tab uses the VISUAL discovery method.

- `ev_desk_fingerprint_raw` is in the evidence_pool but NOT in any investigable object's evidence_results
- **Solution:** Add a "Study Desk" or "Writing Desk" investigable object to the apartment
  - evidence_results: `["ev_desk_fingerprint_raw"]`
  - The player finds raw/unanalyzed fingerprints through visual inspection (they see smudges/prints on the desk)
  - discovery_method for `ev_desk_fingerprint_raw` should be `VISUAL` (not `TOOL`)
  - Later analysis (matching the fingerprints) happens in the Evidence tab, not the map tab
- This follows the same pattern as `ev_shoe_print_raw`: find unanalyzed evidence visually → analyze later in Evidence tab
- **Ref:** caseJsonDataIssues.md Issue #5

### TODO-MAP-06: Add Autopsy Report Evidence
**Priority:** High
**Files:** `evidence.json`, `events.json`

**Decision:** The autopsy report is delivered automatically and for free as part of the Day 1 morning briefing. It's standard police procedure — the coroner's report arrives before the detective begins investigation.

- Add `ev_autopsy_report` to evidence.json
  - Type: DOCUMENT, importance_level: CRITICAL
  - discovery_method: `VISUAL` (delivered, not discovered at a location)
  - Description: establishes cause of death (stab wound), estimated time of death (~21:00), relevant forensic findings
- Add `ev_autopsy_report` to the Day 1 morning briefing event in `events.json`
  - Delivered alongside the case introduction — no action cost
  - Notification: "Coroner's report received: preliminary autopsy results"
- This evidence should NOT be tied to any location or investigable object
- **Ref:** caseJsonDataIssues.md Issue #4

### TODO-MAP-07: Fix Evidence Descriptions with Wrong Times
**Priority:** High
**Files:** `evidence.json`
- `ev_sarah_testimony`: says "heard an argument around 20:45" but nobody is arguing at 20:45 (Mark left at 20:40, Julia arrives at 20:50). Change to ~20:55
- Align with `events.json` evt_loud_argument time (20:55)
- **Ref:** caseJsonDataIssues.md Issue #2

### TODO-MAP-08: Fix Empty location_found Fields
**Priority:** Low
**Files:** `evidence.json`
- `ev_deleted_messages`, `ev_julia_shoes`, `ev_julia_financial_records` have empty `location_found`
- Set to `"warrant_obtained"` or `"person_action"` for clarity
- Or add a dedicated field to indicate these are person-level evidence (not location-found)

### TODO-MAP-09: Remove evidence_pool from locations.json
**Priority:** High
**Files:** `locations.json`

**Decision:** Remove evidence_pool entirely. It's redundant and creates confusion.

- Evidence discovery is tracked purely through `investigable_object.evidence_results`
- Lab results are delivered through the lab system, not through location investigation
- The completion system already uses object-level evidence_results for counting
- Removing evidence_pool eliminates the discrepancy between pool-level and object-level evidence

---

## CODE CHANGES (Implementation)

### TODO-MAP-10: Implement Evidence-Driven Location Unlocking
**Priority:** Critical
**Files:** `game_manager.gd`, `events.json`
- Replace day-based unlocking with evidence-driven unlocking
- Remove unconditional `unlock_location:loc_victim_office` from Day 2 briefing
- Keep the conditional trigger `trig_unlock_office` (fires when `ev_mark_call_log` discovered)
- Consider adding more trigger conditions for office unlock (e.g., `ev_daniel_email` or `ev_bank_transfer`)
- Day 1 crime scene locations (apartment, hallway, parking lot) stay as auto-unlock — they're the crime scene
- **Ref:** caseJsonDataIssues.md "Evidence-Driven Unlocking" section

### TODO-MAP-11: Simplify Action Buttons to Single Button
**Priority:** Medium
**Files:** `location_investigation.gd`

**Decision:** No forensic tools in the map tab. Each target has exactly one action button.

- `_populate_action_buttons()` should render a single button per target:
  - Label: "Visual Inspection" for physical objects, "Examine" for digital objects (devices)
  - Cost: 1 action
  - States: enabled (can inspect) → completed (already inspected) → disabled (no actions remaining)
- Remove all tool-related button logic from the investigation screen
- Remove references to `tool_requirements`, `use_tool_on_object()`, forensic tools from the map tab UI
- Tool-based analysis moves to the Evidence tab

### TODO-MAP-12: Evidence Count Display on Location Cards
**Priority:** Medium
**Files:** `location_card.gd`, `location_investigation_manager.gd`

**Decision:** Show `discovered / total` format. Total includes ALL evidence (including from hidden targets).

- When unvisited: show `"?"`
- When visited: show `"X / Y"` where Y = total evidence from all objects (including conditionally hidden ones)
- This means the player might see "2 / 6" even though only 2 targets are visible — they must figure out how to find the rest
- The total count being visible makes the game challenging but fair: the player knows something is missing

**Evidence evolution pattern:** Raw evidence items (e.g., `ev_shoe_print_raw`) and their analyzed versions (e.g., `ev_shoe_print`) are separate evidence items. The raw version is discovered in the map tab. The analyzed version is created in the Evidence tab through analysis. Both exist in the evidence list. The map tab only counts evidence it can discover (raw items from investigable objects).

### TODO-MAP-13: Status Transitions for Conditional Content
**Priority:** High
**Files:** `location_investigation_manager.gd`, `location_card.gd`

**Decision:** When new conditional targets become available at an EXHAUSTED location, the status transitions back to NEW (not OPEN).

- EXHAUSTED → NEW: Triggered when a hidden target's condition is met at a location the player has already exhausted
- The NEW badge signals clearly that there's something genuinely new to discover
- The notification system (TODO-MAP-03) tells the player *where* to go; the NEW badge confirms it on the map
- Status calculation must check: are there any visible, uninspected targets? If yes and location was EXHAUSTED → set to NEW

**Full status transition table:**
| From | To | Trigger |
|------|----|---------|
| (not visible) | NEW | Location unlocked |
| NEW | OPEN | First visit (even without examining anything) |
| OPEN | OPEN | Partial examination |
| OPEN | EXHAUSTED | All *currently visible* targets examined |
| EXHAUSTED | NEW | New conditional target becomes visible |
| NEW | OPEN | Player revisits (after EXHAUSTED → NEW transition) |

---

## RESOLVED DESIGN DECISIONS

### D1: Conditional Targets — How They Appear
**Decision:** Hidden + notification (Option A + C from original Q1)
- Targets are completely invisible until their condition is met
- When unlocked, a notification fires telling the player to revisit the location
- The evidence count total already hints that more exists (e.g., "2 / 6")

### D2: evidence_pool Removal
**Decision:** Remove evidence_pool from locations.json
- Evidence discovery tracked through `investigable_object.evidence_results` only
- Lab results delivered through lab system
- Eliminates confusion between pool-level and object-level evidence

### D3: EXHAUSTED → NEW Transition
**Decision:** Yes — when new conditional content becomes available, status goes back to NEW
- Provides clear signal that something genuinely new is available
- Combined with notification for explicit guidance

### D4: No Tools in Map Tab
**Decision:** Map tab is evidence gathering only. One button per target (Visual Inspection / Examine).
- All forensic analysis (fingerprint matching, shoe print analysis, etc.) happens in the Evidence tab
- Evidence found in map tab is always VISUAL discovery method
- Raw/unanalyzed evidence is found visually (player sees smudges, prints, patterns)
- `tool_requirements` field removed from map tab data/UI

### D5: Revisit Behavior
**Decision:** Nothing new happens on revisit, unless conditional targets have been unlocked
- Already-examined targets show completed state
- Discovered clues remain visible
- If conditional targets are now unlocked, they appear in the list as new targets
