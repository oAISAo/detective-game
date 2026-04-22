# Map Tab — Happy Flow Testing Steps

> Step-by-step manual test guide for the map tab in a perfect game progression.
> Follow these steps exactly. Each step describes what to do and what you should see.
> This covers ONLY map/location actions. Interrogations and other tabs are excluded.

---

## Prerequisites
- Start a new game with the Riverside Apartment case loaded
- Day 1 morning briefing has been displayed
- Autopsy report (`ev_autopsy_report`) delivered automatically during briefing
- 4 actions available

---

## DAY 1 — Crime Scene Investigation

### Step 1: Open Map Tab
**Action:** Click the Map tab
**Expected:**
- [x] Map screen displays with location cards in a grid
- [x] 3 location cards visible: "Victim's Apartment", "Building Hallway", "Parking Lot"
- [x] All cards show status badge: **NEW** (blue)
- [x] All cards show evidence count: **"?"**
- [x] Victim's Office is NOT visible (not yet unlocked)

---

### Step 2: Enter Victim's Apartment
**Action:** Click the "Victim's Apartment" card
**Expected:**
- [x] Location Detail Screen opens
- [x] Header shows: "Victim's Apartment"
- [x] Evidence count shows: "0 / X" (X = total evidence from all targets, including hidden)
- [x] Left panel shows targets: "Kitchen", "Living Room", "Victim's Phone", "Study Desk"
- [x] Center panel shows location image or placeholder
- [x] Right panel shows placeholder: "Select a target to investigate"
- [x] No actions were consumed (entering is free)

---

### Step 3: Select Kitchen Target
**Action:** Click "Kitchen" in the target list
**Expected:**
- [x] Kitchen button is highlighted/selected
- [x] Right panel updates:
  - Title: "Kitchen"
  - Description: mentions knife block, missing knife, murder weapon in sink
  - Status: "Not inspected" (amber)
  - Action button: "Visual Inspection" (enabled, shows cost: 1 action)
  - No discovered clues section (nothing found yet)

---

### Step 4: Examine Kitchen (Action 1 of 4)
**Action:** Click "Visual Inspection" button
**Expected:**
- [x] Actions remaining decreases from 4 to 3
- [x] Notification popup(s): "Murder Weapon (Kitchen Knife)" and "Knife Block in Kitchen"
- [x] Action button changes to "completed" state (greyed out / checkmark)
- [x] Status changes to: "Fully processed" (grey)
- [x] Discovered clues section appears with 2 polaroid cards:
  - ev_knife — "Murder Weapon (Kitchen Knife)"
  - ev_knife_block — "Knife Block in Kitchen"
- [x] Evidence count in header updates (e.g., "2 / X")

---

### Step 5: Select Living Room Target
**Action:** Click "Living Room" in the target list
**Expected:**
- [x] Right panel updates:
  - Title: "Living Room"
  - Description: mentions wine glasses, wine bottle, broken picture frame
  - Status: "Not inspected" (amber)
  - Action button: "Visual Inspection" (enabled, cost: 1)

---

### Step 6: Examine Living Room (Action 2 of 4)
**Action:** Click "Visual Inspection" button
**Expected:**
- [x] Actions remaining decreases from 3 to 2
- [x] Notification popups: "Two Wine Glasses on Table", "Broken Picture Frame", "Wine Bottle"
- [x] 3 polaroid clue cards appear
- [x] Status: "Fully processed" (grey)
- [x] Evidence count updates
- [x] `ev_wine_glasses` is now discovered — this is the input for lab fingerprint analysis

---

### Step 7: Select Victim's Phone Target
**Action:** Click "Victim's Phone" in the target list
**Expected:**
- [x] Right panel updates:
  - Title: "Victim's Phone"
  - Description: "Daniel's phone found on the table. Contains messages and call logs."
  - Status: "Not inspected" (amber)
  - Action button: "Examine" (not "Visual Inspection" — this is a digital object)

---

### Step 8: Examine Victim's Phone (Action 3 of 4)
**Action:** Click "Examine" button
**Expected:**
- [x] Actions remaining decreases from 2 to 1
- [x] Notification popups: "Text Message From Julia", "Call Log Between Mark and Daniel"
- [x] 2 polaroid clue cards appear
- [x] Status: "Fully processed" (grey)
- [x] **Critical trigger:** Discovering `ev_mark_call_log` fires `trig_unlock_office` → Victim's Office becomes available
  - Notification: "New location unlocked: Victim's Office"

---

### Step 9: Go Back to Map
**Action:** Click Back button
**Expected:**
- [x] Returns to Map screen
- [x] "Victim's Apartment" card now shows:
  - Status badge: **OPEN** (amber) — visited, Study Desk not yet examined
  - Evidence count: "X / Y" (showing found vs total, not "?" anymore)
- [x] "Victim's Office" card now appears on the map with status **NEW** (blue)
- [x] Other location cards unchanged (still NEW)

---

### Step 10: Enter Building Hallway
**Action:** Click "Building Hallway" card
**Expected:**
- [x] Location Detail Screen opens for hallway
- [x] Left panel shows 3 targets: "Hallway Floor", "Building Security System", "Maintenance Office"
- [x] All targets NOT_INSPECTED

---

### Step 11: Examine Hallway Floor (Action 4 of 4)
**Action:** Click "Hallway Floor" → Click "Visual Inspection"
**Expected:**
- [x] Actions remaining decreases from 1 to 0
- [x] Notification: "Shoe Print in Hallway (Unanalyzed)"
- [x] `ev_shoe_print_raw` discovered — raw evidence for later analysis in Evidence tab
- [x] Status: "Fully processed" (grey)

---

### Step 12: Verify No Actions Remaining
**Action:** Click "Building Security System" in the target list
**Expected:**
- [x] Target detail shows in right panel
- [x] Action button ("Examine") is **disabled** (greyed out)
- [x] Clicking the disabled button does nothing (no action consumed)

---

### Step 13: Go Back to Map
**Action:** Click Back button
**Expected:**
- [x] Map screen shows:
  - "Victim's Apartment" — OPEN (amber)
  - "Building Hallway" — OPEN (amber) — visited but not complete
  - "Parking Lot" — NEW (blue) — not visited
  - "Victim's Office" — NEW (blue) — unlocked via evidence

---

### Step 14: End Day 1
**Action:** Send Evidence to the lab (Wine glasses and Shoe print) and End the day (via End Day button or day progression system)
**Expected:** Day transitions to Day 2.

---

## DAY 2 — Continued Investigation

### Step 15: Morning — Lab Results
**Expected (before player acts):**
- [x] If lab evidence was submitted (e.g., wine glasses for fingerprint analysis):
  - Lab results delivered as new evidence
  - Notifications about lab results arriving

---

### Step 16: Open Map, Enter Building Hallway
**Action:** Map tab → Click "Building Hallway"
**Expected:**
- [x] Hallway Floor shows as "Fully processed"
- [x] Security System and Maintenance Office still NOT_INSPECTED

---

### Step 17: Examine Building Security System (Action 1 of 4)
**Action:** Click "Building Security System" → Click "Examine"
**Expected:**
- [x] Actions: 4 → 3
- [x] Notifications: "Hallway Camera (Blurry Figure)", "Elevator Logs"
- [x] `ev_hallway_camera` and `ev_elevator_logs` discovered
- [x] 2 polaroid clue cards appear
- [x] Status: "Fully processed"

---

### Step 18: Go Back, Enter Parking Lot
**Action:** Back → Click "Parking Lot" card
**Expected:**
- [x] Location Detail Screen opens
- [x] 1 target: "Parking Lot Security Camera"
- [x] Parking Lot card changes from NEW to OPEN status

---

### Step 19: Examine Parking Camera (Action 2 of 4)
**Action:** Click "Parking Lot Security Camera" → Click "Examine"
**Expected:**
- [x] Actions: 3 → 2
- [x] Notification: "Parking Lot Camera Footage"
- [x] `ev_parking_camera` discovered
- [x] Status: "Fully processed"
- [x] Since this is the only target, location should be EXHAUSTED when returning to map

---

### Step 20: Back to Map — Verify Parking Lot Exhausted
**Action:** Back button
**Expected:**
- [x] "Parking Lot" card shows status: **EXHAUSTED** (grey)
- [x] Evidence count shows: "1 / 1"

---

*Remaining 2 actions on Day 2 go to interrogations (not map tab).*

---

## DAY 3 — Office Investigation

### Step 21: Enter Victim's Office
**Action:** Map tab → Click "Victim's Office"
**Expected:**
- [x] Location Detail Screen opens for the office
- [x] Targets visible: "Office Desk", "File Cabinet" (only 2 — Bookshelf and Desk Drawer are hidden)
- [x] All targets NOT_INSPECTED
- [x] Evidence count shows: "0 / 5" — total includes hidden targets' evidence (1 desk + 2 cabinet + 1 bookshelf + 1 drawer = 5)
- [x] Status badge transitions from NEW to OPEN on entry

---

### Step 22: Examine Office Desk (Action 1 of 4)
**Action:** Click "Office Desk" → Click action button
**Expected:**
- [x] Actions: 4 → 3
- [x] Notification: "Email From Daniel to Mark"
- [x] `ev_daniel_email` discovered
- [x] Polaroid clue card appears
- [x] Evidence count: "1 / 5"

---

### Step 23: Examine File Cabinet (Action 2 of 4)
**Action:** Click "File Cabinet" → Click "Visual Inspection"
**Expected:**
- [x] Actions: 3 → 2
- [x] Notifications: "Suspicious Bank Transfer", "Accounting Files"
- [x] `ev_bank_transfer` and `ev_accounting_files` discovered
- [x] 2 polaroid clue cards appear
- [x] Evidence count: "3 / 5"
- [x] **Conditional trigger:** Discovering `ev_accounting_files` makes the Bookshelf target visible
  - [x] "Bookshelf" now appears in the target list
  - [x] Notification: "New lead: the accounting irregularities suggest there may be more hidden at Daniel's office."

---

### Step 24: Examine Bookshelf (Action 3 of 4)
**Action:** Click "Bookshelf" → Click "Visual Inspection"
**Expected:**
- [x] Actions: 2 → 1
- [x] Notification: "Hidden Safe in Office"
- [x] `ev_hidden_safe` discovered — description mentions a key found inside the safe
- [x] Evidence count: "4 / 5"
- [x] **Conditional trigger:** Discovering `ev_hidden_safe` makes the Desk Drawer target visible
  - [x] "Desk Drawer" now appears in the target list

---

### Step 25: Examine Desk Drawer (Action 4 of 4)
**Action:** Click "Desk Drawer" → Click "Visual Inspection"
**Expected:**
- [x] Actions: 1 → 0
- [x] Notification: "Daniel's Personal Journal"
- [x] `ev_personal_journal` discovered
- [x] Status: "Fully processed"
- [x] Evidence count: "5 / 5"
- [x] All 4 office targets now examined — location should be EXHAUSTED

---

### Step 26: Back to Map — Verify Final State
**Action:** Back button
**Expected:**
- [x] Map shows all locations with final statuses:
  - "Victim's Apartment" — OPEN (Study Desk not examined) or EXHAUSTED (if all done)
  - "Building Hallway" — OPEN (Maintenance Office not examined) or EXHAUSTED if all done
  - "Parking Lot" — EXHAUSTED (grey)
  - "Victim's Office" — EXHAUSTED (grey) — all 4 targets done

---

## Day 4: No new map actions needed

All location-based evidence has been gathered. Day 4 actions go to interrogations and case report submission.

---

## Evidence Summary After All Map Actions

| Day | Location | Target | Evidence Discovered |
|-----|----------|--------|-------------------|
| 0 | (Briefing) | — | ev_autopsy_report (free) |
| 1 | Apartment | Kitchen | ev_knife, ev_knife_block |
| 1 | Apartment | Living Room | ev_wine_glasses, ev_broken_picture_frame, ev_wine_bottle |
| 1 | Apartment | Victim's Phone | ev_julia_text_message, ev_mark_call_log |
| 1 | Hallway | Hallway Floor | ev_shoe_print_raw |
| 2 | Hallway | Security System | ev_hallway_camera, ev_elevator_logs |
| 2 | Parking Lot | Security Camera | ev_parking_camera |
| 3 | Office | Desk | ev_daniel_email |
| 3 | Office | File Cabinet | ev_bank_transfer, ev_accounting_files |
| 3 | Office | Bookshelf | ev_hidden_safe |
| 3 | Office | Desk Drawer | ev_personal_journal |

**Note:** Study Desk (`ev_desk_fingerprint_raw`) and Maintenance Office (`ev_lucas_work_log`) not shown — they can be examined on any day with remaining actions.

**Total map actions used: 10 out of 16** (remaining 6 go to interrogations)
