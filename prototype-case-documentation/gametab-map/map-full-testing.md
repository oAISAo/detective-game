# Map Tab — Full Test Cases

> Comprehensive test suite for the map tab including edge cases, error states, and unhappy flows.
> Each test has an ID, description, steps, and expected results.

---

## 1. MAP SCREEN — Display & Layout

### T-MAP-001: Map shows only unlocked locations
**Precondition:** New game, Day 1 morning briefing completed
**Steps:**
1. Open Map tab
**Expected:**
- [ ] Only unlocked locations visible (Apartment, Hallway, Parking Lot)
- [ ] Victim's Office NOT visible
- [ ] No empty slots or placeholder cards for locked locations

### T-MAP-002: Map shows empty state when no locations available
**Precondition:** Game state where no locations are unlocked (if possible)
**Steps:**
1. Open Map tab
**Expected:**
- [ ] Message displayed: "No locations available yet."
- [ ] No cards visible

### T-MAP-003: Location cards display correct data
**Precondition:** New game, Day 1
**Steps:**
1. Open Map tab
2. Inspect each location card visually
**Expected for each card:**
- [ ] Location image or placeholder with name initial
- [ ] Location title (uppercase)
- [ ] First sentence of description (truncated at ~120 chars)
- [ ] Evidence count shows "?"
- [ ] Status badge shows "NEW" (blue)

### T-MAP-004: New location appears when unlocked mid-game
**Precondition:** Day 1, office not yet unlocked
**Steps:**
1. Open Map tab — verify office not visible
2. Go to apartment and examine phone (discover ev_mark_call_log)
3. Return to Map tab
**Expected:**
- [ ] "Victim's Office" card now appears
- [ ] Status badge: NEW (blue)
- [ ] Evidence count: "?"
- [ ] Notification about office being available

### T-MAP-005: Card hover effect
**Steps:**
1. Hover over a location card
**Expected:**
- [ ] Card scales up slightly (1.008x)
- [ ] Border color changes to blue
- [ ] Shadow glow appears
- [ ] Cursor changes to pointing hand
2. Move mouse away
**Expected:**
- [ ] Card returns to normal scale
- [ ] Border returns to default
- [ ] Shadow returns to normal

### T-MAP-006: Card hover exits cleanly when moving between cards
**Steps:**
1. Hover over Card A
2. Quickly move mouse to Card B
**Expected:**
- [ ] Card A returns to normal state
- [ ] Card B enters hover state
- [ ] No "stuck hover" glitch on either card

---

## 2. MAP SCREEN — Status Badges

### T-MAP-010: Status badge NEW for unvisited location
**Precondition:** Location exists but never visited
**Steps:** Inspect card
**Expected:**
- [ ] Badge text: "NEW"
- [ ] Badge color: Blue

### T-MAP-011: Status badge OPEN after first visit
**Steps:**
1. Click a NEW location card
2. Immediately click Back (without examining anything)
3. Check map
**Expected:**
- [ ] Badge changes from NEW to "OPEN" (amber)
- [ ] Evidence count changes from "?" to "0 / X"

### T-MAP-012: Status badge OPEN with partial investigation
**Steps:**
1. Enter apartment, examine Kitchen only
2. Return to map
**Expected:**
- [ ] Apartment badge: "OPEN" (amber)
- [ ] Evidence count: "2 / X" (where X is total including hidden targets)

### T-MAP-013: Status badge EXHAUSTED when all visible targets examined
**Steps:**
1. Enter Parking Lot
2. Examine the security camera (only target)
3. Return to map
**Expected:**
- [ ] Parking Lot badge: "EXHAUSTED" (grey)
- [ ] Evidence count: "1 / 1"

### T-MAP-014: EXHAUSTED → NEW transition when conditional target unlocks
**Steps:**
1. Visit office, examine Desk and File Cabinet (all visible targets done)
2. Return to map — office shows EXHAUSTED
3. `ev_accounting_files` was discovered → Bookshelf condition met
**Expected:**
- [ ] Office card transitions from EXHAUSTED to **NEW** (blue)
- [ ] Notification fires: "New lead: the accounting irregularities suggest there may be more hidden at Daniel's office."

### T-MAP-015: Evidence count includes hidden target evidence
**Precondition:** Office visited, only Desk and File Cabinet visible
**Steps:**
1. Enter office
2. Check evidence count in header
**Expected:**
- [ ] Evidence count shows "0 / 6" (not "0 / 3")
- [ ] Total counts evidence from ALL targets (including hidden Bookshelf and Desk Drawer)

---

## 3. LOCATION DETAIL — Target List

### T-MAP-020: Target list displays all visible investigable targets
**Steps:**
1. Enter Victim's Apartment
**Expected:**
- [ ] Left panel shows: Kitchen, Living Room, Victim's Phone, Study Desk
- [ ] Each has a bullet point "•" prefix
- [ ] No hidden targets visible

### T-MAP-021: Target selection highlights correctly
**Steps:**
1. Click Kitchen — verify highlighted
2. Click Living Room — verify Kitchen deselected, Living Room highlighted
3. Click Kitchen again — verify Kitchen highlighted, Living Room deselected
**Expected:**
- [ ] Only one target highlighted at a time
- [ ] Visual distinction between selected and unselected buttons

### T-MAP-022: Empty target list shows message
**Precondition:** Location with no investigable targets (edge case)
**Expected:**
- [ ] Message: "Nothing to investigate here."

### T-MAP-023: Conditional targets appear after conditions met
**Precondition:** Office visited, File Cabinet examined (ev_accounting_files discovered)
**Steps:**
1. Check target list after examining File Cabinet
**Expected:**
- [ ] "Bookshelf" now appears in the target list
- [ ] Previously was not visible
- [ ] Bookshelf shows as NOT_INSPECTED

### T-MAP-024: Conditional targets remain hidden before conditions met
**Precondition:** Office visited, File Cabinet NOT examined
**Steps:**
1. Check target list
**Expected:**
- [ ] Only "Office Desk" and "File Cabinet" visible
- [ ] "Bookshelf" and "Desk Drawer" NOT visible
- [ ] No greyed-out or locked indicators for hidden targets

---

## 4. LOCATION DETAIL — Right Panel & Actions

### T-MAP-030: Placeholder state when no target selected
**Steps:**
1. Enter a location (don't select any target)
**Expected:**
- [ ] Right panel shows placeholder/empty state
- [ ] No action button visible
- [ ] No clue cards visible

### T-MAP-031: Target detail shows correct information
**Steps:**
1. Select a target (e.g., Kitchen)
**Expected:**
- [ ] Title matches target name
- [ ] Description matches target description
- [ ] Status: "Not inspected" (amber)
- [ ] Single action button visible

### T-MAP-032: Visual Inspection button consumes 1 action
**Steps:**
1. Note current actions remaining (e.g., 4)
2. Click "Visual Inspection" on an uninspected target
3. Note actions remaining
**Expected:**
- [ ] Actions decreased by exactly 1 (e.g., 4 → 3)

### T-MAP-033: Examine button works for digital targets
**Steps:**
1. Select Victim's Phone (digital object)
**Expected:**
- [ ] Button text shows "Examine" (not "Visual Inspection")
- [ ] Clicking it consumes 1 action and discovers evidence

### T-MAP-034: Action button shows completed state after use
**Steps:**
1. Examine Kitchen
2. Select Kitchen again
**Expected:**
- [ ] Action button shows completed/checkmark state
- [ ] Button is not clickable
- [ ] No duplicate action possible

### T-MAP-035: Cannot examine same target twice
**Steps:**
1. Examine Kitchen
2. Select Kitchen, try clicking action button again
**Expected:**
- [ ] No action consumed
- [ ] No duplicate evidence notifications
- [ ] Button remains in completed state

### T-MAP-036: Discovery notification shows for each evidence item
**Steps:**
1. Examine Living Room (produces 3 evidence items)
**Expected:**
- [ ] 3 separate notification popups
- [ ] Each shows the evidence name
- [ ] Notifications appear sequentially or stacked

### T-MAP-037: Polaroid clue cards appear after discovery
**Steps:**
1. Examine a target with evidence
2. Check below action button
**Expected:**
- [ ] Clues section visible with polaroid-style cards
- [ ] Each card shows evidence image + name
- [ ] Number of cards matches number of evidence items found

### T-MAP-038: No clues section when nothing found
**Steps:**
1. Select a target that hasn't been examined
**Expected:**
- [ ] No clues section visible below action button

---

## 5. NO ACTIONS REMAINING

### T-MAP-040: Action button disabled when no actions left
**Precondition:** 0 actions remaining
**Steps:**
1. Enter a location
2. Select an uninspected target
**Expected:**
- [ ] Action button is disabled/greyed out
- [ ] Clicking the button does nothing

### T-MAP-041: Can still browse locations with 0 actions
**Steps:**
1. With 0 actions, navigate to different locations
2. Select different targets, view their details
**Expected:**
- [ ] Navigation works (entering locations is free)
- [ ] Target details display correctly
- [ ] Previously discovered clues still visible
- [ ] Only action buttons are disabled

### T-MAP-042: Last action is consumed correctly
**Steps:**
1. With exactly 1 action remaining
2. Examine an uninspected target
**Expected:**
- [ ] Action consumed: 1 → 0
- [ ] Evidence discovered normally
- [ ] After discovery, remaining targets' action buttons become disabled

---

## 6. LOCATION REVISIT

### T-MAP-050: Revisiting a location is free
**Steps:**
1. Visit and examine apartment (Day 1)
2. Return to map
3. Visit apartment again
**Expected:**
- [ ] No action consumed for entry
- [ ] Location shows correctly as visited
- [ ] Previously examined targets show completed state

### T-MAP-051: Previously discovered clues persist on revisit
**Steps:**
1. Examine Kitchen → see polaroid cards
2. Leave and return to apartment
3. Select Kitchen
**Expected:**
- [ ] Polaroid clue cards still visible
- [ ] Evidence count unchanged
- [ ] Action button still shows completed

### T-MAP-052: Uninspected targets remain available on revisit
**Steps:**
1. Examine Kitchen only (not Living Room or Phone)
2. Leave and return next day
3. Check target list
**Expected:**
- [ ] Kitchen shows as examined
- [ ] Living Room and Phone show as NOT_INSPECTED
- [ ] Action buttons for uninspected targets are enabled (if actions available)

### T-MAP-053: Conditional targets appear on revisit if conditions now met
**Steps:**
1. Visit office, examine Desk and File Cabinet
2. Leave office (ev_accounting_files discovered → Bookshelf condition met)
3. Revisit office
**Expected:**
- [ ] Bookshelf now appears in target list
- [ ] Desk and File Cabinet still show as examined
- [ ] Bookshelf shows as NOT_INSPECTED

### T-MAP-054: Chained conditional targets unlock sequentially
**Steps:**
1. Visit office → examine File Cabinet → Bookshelf appears
2. Examine Bookshelf (ev_hidden_safe discovered) → Desk Drawer appears
3. Examine Desk Drawer
**Expected:**
- [ ] Each conditional target appears only after its specific condition is met
- [ ] Chain: File Cabinet → Bookshelf → Desk Drawer
- [ ] Evidence count progresses: "1/6" → "3/6" → "4/6" → "5/6"

---

## 7. EVIDENCE-DRIVEN LOCATION UNLOCKING

### T-MAP-060: Office unlocks when call log discovered
**Steps:**
1. Examine Victim's Phone (discover ev_mark_call_log)
2. Return to map
**Expected:**
- [ ] "Victim's Office" card appears on map
- [ ] Status: NEW (blue)

### T-MAP-061: Office does NOT appear before trigger evidence
**Steps:**
1. Examine Kitchen and Living Room only (no phone)
2. Return to map
**Expected:**
- [ ] Only 3 location cards visible
- [ ] "Victim's Office" NOT present

### T-MAP-062: Multiple evidence can trigger same unlock
**Precondition:** Office unlock accepts ev_mark_call_log OR ev_daniel_email OR ev_bank_transfer
**Steps:**
1. Find any one of the qualifying evidence items
2. Check map
**Expected:**
- [ ] Office appears if any qualifying evidence is found
- [ ] Unlock only fires once even if multiple triggers satisfied later

---

## 8. EDGE CASES & ERROR HANDLING

### T-MAP-070: Navigate to invalid location ID
**Precondition:** Simulate navigation with empty/invalid location_id
**Expected:**
- [ ] Error state displayed: "Location Not Found"
- [ ] No crash
- [ ] Back button still works

### T-MAP-071: Location with no image resource
**Precondition:** Location image path is empty or file doesn't exist
**Expected:**
- [ ] Placeholder displayed (large initial letter + location name)
- [ ] "Scene preview unavailable" text
- [ ] No crash or broken texture

### T-MAP-072: Evidence with missing data
**Precondition:** evidence.json has an evidence item with empty fields
**Expected:**
- [ ] Notification still fires (may show fallback text)
- [ ] Polaroid card handles missing image gracefully
- [ ] No crash

### T-MAP-073: Rapid clicking action button
**Steps:**
1. Select an uninspected target
2. Click the action button rapidly 5 times
**Expected:**
- [ ] Only 1 action consumed
- [ ] Evidence discovered only once
- [ ] No duplicate notifications
- [ ] No duplicate polaroid cards

### T-MAP-074: Switching targets while notification is showing
**Steps:**
1. Examine Kitchen (notifications appear)
2. Immediately click Living Room before notifications clear
**Expected:**
- [ ] Right panel updates to Living Room details
- [ ] Kitchen notifications complete normally
- [ ] No UI state corruption

### T-MAP-075: Back button during active state
**Steps:**
1. Select a target, view its details
2. Click Back without examining
**Expected:**
- [ ] Returns to map screen cleanly
- [ ] No partial state saved
- [ ] Location card shows correct status (OPEN if visited, evidence count reflects actual found count)

---

## 9. STATUS TRANSITION MATRIX

### T-MAP-080: Verify all valid status transitions

| From | To | Trigger | Test |
|------|----|---------|------|
| (not visible) | NEW | Location unlocked | T-MAP-004, T-MAP-060 |
| NEW | OPEN | First visit (even without examining) | T-MAP-011 |
| OPEN | OPEN | Partial examination | T-MAP-012 |
| OPEN | EXHAUSTED | All visible targets examined | T-MAP-013 |
| EXHAUSTED | NEW | Conditional target becomes visible | T-MAP-014 |
| NEW | OPEN | Revisit after EXHAUSTED → NEW | T-MAP-053 |

### T-MAP-081: Full office status progression
**Steps:**
1. Visit office → status: NEW → OPEN (on entry)
2. Examine Desk only → OPEN
3. Examine File Cabinet → accounting files discovered → Bookshelf appears → still OPEN
4. Examine Bookshelf → safe discovered → Desk Drawer appears → still OPEN
5. Examine Desk Drawer → all done → EXHAUSTED
**Expected:**
- [ ] Status progresses: NEW → OPEN → OPEN → OPEN → EXHAUSTED
- [ ] Evidence counter updates at each step

### T-MAP-082: EXHAUSTED → NEW when player leaves and returns
**Steps:**
1. Visit office, examine Desk and File Cabinet only → all visible targets done → EXHAUSTED
2. Leave office → map shows EXHAUSTED
3. ev_accounting_files triggers Bookshelf condition → status → NEW
4. Return to map
**Expected:**
- [ ] Office card now shows NEW (blue)
- [ ] Notification about new lead fired
5. Enter office
**Expected:**
- [ ] Status transitions to OPEN
- [ ] Bookshelf now in target list

---

## 10. INVESTIGATION STATE PERSISTENCE

### T-MAP-090: State survives tab switching
**Steps:**
1. Examine Kitchen (action consumed, evidence found)
2. Switch to another tab (e.g., Evidence tab)
3. Switch back to Map tab
4. Enter apartment, select Kitchen
**Expected:**
- [ ] Kitchen shows as examined
- [ ] Action button in completed state
- [ ] Polaroid clues visible
- [ ] Action count reflects the consumed action

### T-MAP-091: State survives day transition
**Steps:**
1. Day 1: Examine Kitchen and Living Room
2. End Day 1 → Day 2
3. Enter apartment on Day 2
**Expected:**
- [ ] Kitchen and Living Room show as examined
- [ ] Phone and Study Desk show as NOT_INSPECTED
- [ ] Action count reset to 4 (new day)

### T-MAP-092: Save/load preserves investigation state
**Steps:**
1. Examine several targets
2. Save game
3. Load game
4. Check map and location states
**Expected:**
- [ ] All examined targets still show as examined
- [ ] All discovered evidence still present
- [ ] Action count correct for current day
- [ ] Location card statuses correct
- [ ] Conditional target visibility correct (based on discovered evidence)

---

## 11. AUTOPSY REPORT

### T-MAP-100: Autopsy report delivered in Day 1 briefing
**Precondition:** New game
**Steps:**
1. Complete Day 1 morning briefing
**Expected:**
- [ ] `ev_autopsy_report` appears in evidence list
- [ ] Notification: "Coroner's report received: preliminary autopsy results"
- [ ] No action consumed (delivered for free)
- [ ] Evidence contains: cause of death, time of death (~21:00), forensic findings

### T-MAP-101: Autopsy report not tied to any location
**Steps:**
1. Check all location cards after receiving autopsy report
**Expected:**
- [ ] Autopsy report does NOT appear in any location's evidence count
- [ ] No location's target list includes autopsy-related targets
