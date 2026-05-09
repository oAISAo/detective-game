# Evidence Tab — Happy Flow Testing Steps

> Step-by-step manual test guide for the Evidence tab in a perfect game progression.
> Follow these steps exactly. Each step describes what to do and what you should see.
> This covers ONLY Evidence tab actions. Map exploration and interrogations are excluded.
> All Evidence tab actions cost 0 actions (passive). No action counter changes on this tab.

---

## Prerequisites
- Map tab happy flow for Days 1–4 has been completed (or is being run in parallel)
- Day 1 morning briefing has been displayed
- `ev_autopsy_report` has been delivered automatically

---

Note:
Statements shown in the Evidence tab originate from interrogations in the Suspects tab.
They only appear here once both the statement and the linked evidence have been discovered.

Discovery method labels describe original acquisition source only. Lab progress is shown through the LAB badge and lab-status metadata, while successful comparisons unlock insights instead of creating new archive evidence cards.

Derived evidence now has explicit lineage. Child evidence can show `Derived From` in metadata, while raw evidence uses `lab_analysis_results` to drive the Forensic Analysis section: available analyses, expected result previews, pending status, and completed result links. Upgrade-style lab outputs still keep lineage even when the raw parent is replaced in the archive.

The header badge and metadata row describe **Case Relevance** from `importance_level`. The **Evidentiary Value** tier comes from `weight`. These systems are independent, so a clue can be case-critical while still having only weak or supporting persuasive strength.

---

## DAY 1 — First Review & Lab Submissions

> These steps happen after map actions on Day 1 are complete (Kitchen, Living Room, Phone, Hallway Floor examined).
> Evidence in archive at this point: ev_autopsy_report + 8 items from map = 9 total NEW items.

---

### Step 1: Open Evidence Tab
**Action:** Click the Evidence tab in the top navigation
**Expected:**
- [ ] Evidence Archive (left panel) shows 9 polaroid cards
- [ ] All 9 cards have a **NEW** badge (blue)
- [ ] Right panel shows placeholder state: *"Select an evidence item to review"*
- [ ] Notification bell counter shows 9 (or matches unreviewed count)
- [ ] Archive is ordered by discovery: ev_autopsy_report at top (discovered Day 0), then Day 1 items in order of discovery. Ordering uses `GameManager.get_evidence_discovery_day(id)` (runtime — recorded when `discover_evidence()` is called); secondary sort by importance.

---

### Step 2: Review Autopsy Report
**Action:** Click `ev_autopsy_report` card in the archive
**Expected:**
- [ ] Right panel loads autopsy detail
- [ ] Header shows: *"Case File"* as discovery method
- [ ] Description: cause of death (knife wound), estimated time of death (~21:00), forensic findings
- [ ] Case Relevance badge: **CRITICAL**
- [ ] **NEW** badge disappears from this card in the archive
- [ ] No statements appear in side column (no interrogations have happened yet)
- [ ] No "Submit to Lab" section (autopsy report does not require further analysis)

---

### Step 3: Review Murder Weapon
**Action:** Click `ev_knife` card
**Expected:**
- [ ] Detail loads: "Murder Weapon (Kitchen Knife)"
- [ ] Lab Status in metadata: *"Not required"*
- [ ] No "Submit to Lab" section
- [ ] Related Persons: none yet (lab result will link to Julia)
- [ ] **NEW** badge clears

---

### Step 4: Review Wine Glasses — Identify Lab Opportunity
**Action:** Click `ev_wine_glasses` card
**Expected:**
- [ ] Detail loads: "Two Wine Glasses on Table"
- [ ] Below the Compare Evidence button, a **Lab Analysis Available** section appears:
  - Text includes: *"Expected result: Julia's Fingerprint on Wine Glass"*
  - Button: **Submit to Lab — Fingerprint Analysis**
- [ ] Lab Status in metadata: *"Not submitted"* (amber)
- [ ] No statements in side column yet

---

### Step 5: Submit Wine Glasses to Lab
**Action:** Click "Submit to Lab — Fingerprint Analysis"
**Expected:**
- [ ] Notification popup: *"Wine glasses submitted for fingerprint analysis. Results expected tomorrow morning."*
- [ ] Lab Status in metadata changes to: *"Pending — results Day 2"* (amber)
- [ ] Submit button changes to status indicator: *"In analysis — results Day 2 morning"* (disabled state)
- [ ] `ev_wine_glasses` card in the archive gains **LAB** badge
- [ ] Action counter is unchanged (submission costs 0 actions)

---

### Step 6: Review Shoe Print — Identify Lab Opportunity
**Action:** Click `ev_shoe_print_raw` card
**Expected:**
- [ ] Detail loads: "Shoe Print in Hallway (Unanalyzed)"
- [ ] Description notes it needs analysis to determine size and pattern
- [ ] **Lab Analysis Available** section appears:
  - Text includes: *"Expected result: Shoe Print in Hallway"*
  - Button: **Submit to Lab — Footwear Analysis**

---

### Step 7: Submit Shoe Print to Lab
**Action:** Click "Submit to Lab — Footwear Analysis"
**Expected:**
- [ ] Notification popup: *"Shoe print submitted for footwear analysis. Results expected tomorrow morning."*
- [ ] Lab Status changes to *"Pending — results Day 2"*
- [ ] `ev_shoe_print_raw` card gains **LAB** badge

---

### Step 8: Review Julia's Text Message
**Action:** Click `ev_julia_text_message` card
**Expected:**
- [ ] Detail loads: "Text Message From Julia"
- [ ] Description: Julia texted Daniel at 20:40: "Are you home? We need to talk."
- [ ] Related Persons: Julia Ross (Suspect)
- [ ] No statements yet (Julia hasn't been interrogated)
- [ ] No lab analysis required

---

### Step 9: Review Mark's Call Log
**Action:** Click `ev_mark_call_log` card
**Expected:**
- [ ] Detail loads: "Call Log Between Mark and Daniel"
- [ ] Related Persons: Mark Bennett (Suspect)
- [ ] No statements yet
- [ ] Note: this evidence is what triggered the Victim's Office unlock on the Map tab

---

### Step 10: End Day 1
**Action:** Return to day progression (End Day button or equivalent)
**Expected:**
- [ ] 2 lab requests are queued (wine glasses, shoe print)
- [ ] At least 7 of 9 evidence items have been reviewed (NEW badges cleared)

---

## DAY 2 — Lab Results & First Contradictions

### Step 11: Morning — Lab Results Delivered
**Expected (automatic, before player acts):**
- [ ] Notification popup fires: *"Lab results in: Julia's Fingerprint on Wine Glass"*
- [ ] `ev_julia_fingerprint_glass` appears in the archive with **NEW** badge
- [ ] Notification fires: *"Lab results in: Shoe Print in Hallway"*
- [ ] `ev_shoe_print` appears in the archive with **NEW** badge
- [ ] `ev_wine_glasses` card: **LAB** badge is removed. Lab Status in its detail panel: *"Complete — see: Julia's Fingerprint on Wine Glass"* with a link to the result
- [ ] `ev_wine_glasses` detail now shows the completed result link **→ Julia's Fingerprint on Wine Glass** in the Forensic Analysis section
- [ ] `ev_shoe_print_raw` is replaced in the discovered archive by `ev_shoe_print` (upgrade flow). The analyzed result still keeps lineage back to the raw input internally.
- [ ] Archive now has 10 visible items total (9 original cards, plus the fingerprint result, with the raw shoe print upgraded in place)
- [ ] Notification bell counter: 2 new unreviewed items

---

### Step 12: Review Julia's Fingerprint — Critical Evidence
**Action:** Click `ev_julia_fingerprint_glass` card
**Expected:**
- [ ] Detail loads: "Julia's Fingerprint on Wine Glass"
- [ ] Case Relevance badge: **CRITICAL**
- [ ] Discovery method: *"Forensic Analysis"*
- [ ] Metadata shows **Derived From: Two Wine Glasses on Table** as a navigation link
- [ ] Related Persons: Julia Ross (Suspect)
- [ ] Evidentiary Value shows **Airtight** with case-authored interpretation text
- [ ] The CRITICAL badge and the Airtight value are separate systems: case relevance versus persuasive strength
- [ ] Side column — Statements: **no statements yet** (Julia hasn't been interrogated on Day 2)
- [ ] No "Submit to Lab" section

> Note: Julia's statements will appear here AFTER interrogation (Day 2, Actions 5–8 in the combined flow). See Step 16.

---

### Step 13: Review Analyzed Shoe Print
**Action:** Click `ev_shoe_print` card
**Expected:**
- [ ] Detail loads: "Shoe Print in Hallway"
- [ ] Description: Women's shoe, size 38, distinctive sole pattern
- [ ] Discovery method: *"Forensic Analysis"*
- [ ] Metadata shows **Derived From: Shoe Print in Hallway (Unanalyzed)** as plain text, not a navigation link, because the raw archive card was replaced by the upgraded result
- [ ] **Compare Evidence** button is available — but no valid comparison exists yet (Julia's shoes not in evidence)
- [ ] Compare attempt with any current evidence produces: *"No forensic connection found between these items."*

---

### Step 14: Review Elevator Logs — Strong Presence Evidence
**Action:** Click `ev_elevator_logs` card (discovered via Map tab Day 2, Action 5)
**Expected:**
- [ ] Detail loads: "Elevator Logs"
- [ ] Description: Julia Ross's key card used at 20:48 on the night of the murder
- [ ] Case Relevance: **CRITICAL**
- [ ] Related Persons: Julia Ross (Suspect)
- [ ] Legal Categories badge: **Presence**, **Opportunity**
- [ ] No statements yet (Julia hasn't been interrogated yet at this point)

---

### Step 15: Review Parking Camera
**Action:** Click `ev_parking_camera` card
**Expected:**
- [ ] Detail loads: "Parking Lot Camera Footage"
- [ ] Description: Mark Bennett leaving the building at 20:40
- [ ] No statements yet if Mark hasn't been interrogated yet
- [ ] After Mark's Day 2 interrogation (Action 7 in overall flow), return here — see Step 16

---

### Step 16: Classify Mark's Contradiction on Parking Camera
> **Prerequisite:** Mark Bennett has been interrogated (Day 2, Interrogation Action). His statements are now in the system.

**Action:** Click `ev_parking_camera` card
**Expected:**
- [ ] Side column — Statements shows 3 linked items:
  - `stmt_mark_departure_time`: *"I left around 20:30."* — verdict: **UNCLASSIFIED** (amber)
  - `stmt_mark_corrected_departure`: *"Fine. I left closer to 20:40."* — verdict: **UNCLASSIFIED** (amber)
  - `stmt_mark_lied_to_hide_argument`: *"I lied because we argued..."* — verdict: **UNCLASSIFIED** (amber)

**Action:** Click the verdict pill on `stmt_mark_departure_time` → select **Contradiction**
**Expected:**
- [ ] Pill changes to red: **CONTRADICTION**
- [ ] Expand the statement → Analysis notes field is available for player to type observations
- [ ] No action consumed

**Action:** Click verdict pill on `stmt_mark_corrected_departure` → select **Supports**
**Expected:**
- [ ] Pill changes to teal: **SUPPORTS**
- [ ] Verdict change is saved in player state
- [ ] Evidentiary Value adds *"Contested by a credible statement"* — `stmt_mark_departure_time` has a CONTRADICTION verdict and `statement importance = CRITICAL`, satisfying `EvidenceManager.is_contradicted()`

**Action:** Click verdict pill on `stmt_mark_lied_to_hide_argument` → select **Unresolved**
**Expected:**
- [ ] Pill stays amber but changes label to **UNRESOLVED** (distinct from default UNCLASSIFIED)

---

### Step 17: Classify Julia's Contradiction on Fingerprint Evidence
> **Prerequisite:** Julia Ross has been interrogated at least once (her initial statement is recorded).

**Action:** Click `ev_julia_fingerprint_glass` card
**Expected:**
- [ ] Side column — Statements shows at least 1 linked item:
  - `stmt_julia_initial`: *"I wasn't at the apartment that night."* — verdict: **UNCLASSIFIED**

**Action:** Click verdict pill → select **Contradiction**
**Expected:**
- [ ] Pill turns red: **CONTRADICTION**
- [ ] A key contradiction is now logged: Julia denied being there, but her fingerprint was on the wine glass
- [ ] Evidentiary Value adds *"Contested by a credible statement"* (`stmt_julia_initial` has statement importance CRITICAL, satisfying `is_contradicted()`)

---

### Step 18: Review Sarah's Statements on Hallway Camera
> **Prerequisite:** Sarah Klein has been interrogated (Day 2 interrogation).

**Action:** Click `ev_hallway_camera` card
**Expected:**
- [ ] Side column — Statements:
  - `stmt_sarah_confronted`: *"I... maybe I heard a woman's voice too."* — UNCLASSIFIED
  - `stmt_sarah_saw_woman`: *"I saw a woman leaving Daniel's apartment."* — UNCLASSIFIED

**Action:** Set both to **Supports**
**Expected:**
- [ ] Both pills turn teal
- [ ] Sarah's testimony corroborates what the camera shows

---

### Step 19: Classify Julia's Contradiction on Elevator Logs
> **Prerequisite:** Julia has been interrogated — first confrontation produced `stmt_julia_fingerprint` ("I visited earlier in the day").

**Action:** Click `ev_elevator_logs`
**Expected:**
- [ ] Side column — Statements:
  - `stmt_julia_fingerprint`: *"I visited earlier in the day."* — UNCLASSIFIED
- [ ] The elevator log shows 20:48 — the night of the murder. "Earlier in the day" is false.

**Action:** Set verdict to **Contradiction**
**Expected:**
- [ ] Pill turns red: **CONTRADICTION**
- [ ] Second Julia contradiction now logged

---

## DAY 3 — Financial Evidence & Comparisons

> At this point the Victim's Office has been investigated (Day 3, Map Actions 9–11).
> New evidence in archive: ev_daniel_email, ev_bank_transfer, ev_accounting_files, ev_hidden_safe

---

### Step 20: Review Daniel's Email
**Action:** Click `ev_daniel_email` card
**Expected:**
- [ ] Detail loads: "Email From Daniel to Mark"
- [ ] Subject line visible in description: "We need to fix this before tomorrow."
- [ ] Related Persons: Mark Bennett

---

### Step 21: Review Bank Transfer
**Action:** Click `ev_bank_transfer` card
**Expected:**
- [ ] Detail loads: "Suspicious Bank Transfer"
- [ ] Case Relevance: **CRITICAL**
- [ ] Description: money moved from company account, destination unknown
- [ ] **Compare Evidence** button available
- [ ] Side column — Statements: Mark's `stmt_mark_argument` may appear ("we argued a little") — if so, set to UNRESOLVED

---

### Step 22: Compare Bank Transfer with Accounting Files
**Action:** With `ev_bank_transfer` open, click **Compare Evidence**
**Expected:**
- [ ] Comparison selector panel slides in over the right panel
- [ ] All discovered evidence shown as a scrollable list
- [ ] `ev_accounting_files` is visible in the list

**Action:** Select `ev_accounting_files` from the comparison selector
**Expected:**
- [ ] System checks for a valid comparison pair
- [ ] Valid pair found: discovers insight `ins_embezzlement_scheme`
- [ ] Notification popup: *"New insight: Mark was embezzling money from the company. Daniel discovered the missing funds and planned to expose him."*
- [ ] No new evidence card is added to the archive
- [ ] Comparison selector closes

---

### Step 23: Confirm Comparison Does Not Add Archive Evidence
**Action:** Stay in the Evidence tab after the comparison resolves
**Expected:**
- [ ] No `ev_financial_link` card appears in the archive
- [ ] `ev_bank_transfer` and `ev_accounting_files` retain their original discovery labels
- [ ] The comparison outcome is treated as an insight for downstream systems, not as new archive evidence

---

### Step 24: Review Hidden Safe Evidence
**Action:** Click `ev_hidden_safe` card
**Expected:**
- [ ] Detail loads: "Hidden Safe in Office"
- [ ] Description: documents revealing the full extent of Mark's financial crimes and Daniel's plan to expose him
- [ ] Case Relevance: **CRITICAL**
- [ ] Related Persons: Mark Bennett (and potentially Julia Ross, as her financial situation is referenced)

---

### Step 25: Review Julia's Updated Statements on Elevator Logs
> **Prerequisite:** Julia's first interrogation (Day 3, Action 12) produced `stmt_julia_elevator` ("I stopped by briefly. But Daniel was alive when I left.")

**Action:** Click `ev_elevator_logs`
**Expected:**
- [ ] A new statement has appeared: `stmt_julia_elevator` — *"Okay... I stopped by briefly. But Daniel was alive when I left."*
- [ ] Verdict: UNCLASSIFIED

**Action:** Classify `stmt_julia_elevator` as **Unresolved**
**Expected:**
- [ ] Pill updates
- [ ] Player note: she admits being there — the earlier lie is now a confirmed contradiction, this new admission shifts focus to what happened inside

---

## DAY 4 — Final Analysis & Case Preparation

> Day 4 map action (Personal Items / Journal) and final interrogations happen before or alongside these steps.
> New evidence: ev_personal_journal (map), ev_julia_shoes (search warrant)

---

### Step 26: Morning — Check Warrant Results
> **Prerequisite:** Search warrant for Julia's apartment was submitted (recommended: Day 2 after getting fingerprint + elevator logs). Results arrive next morning.

**Expected (if warrant was submitted Day 2 or 3):**
- [ ] Notification: *"Search warrant executed: Julia Ross's apartment. New evidence collected."*
- [ ] `ev_julia_shoes` appears in archive with **NEW** badge

---

### Step 27: Review Julia's Shoes
**Action:** Click `ev_julia_shoes` card
**Expected:**
- [ ] Detail loads: "Julia Ross's Shoes (Women's, Size 38)"
- [ ] Discovery method: *"Search Warrant"*
- [ ] Description: sole pattern noted, matches analyzed shoe print from hallway
- [ ] **Compare Evidence** button available

---

### Step 28: Compare Shoe Print with Julia's Shoes
**Action:** With `ev_julia_shoes` open, click **Compare Evidence** → select `ev_shoe_print`
**Expected:**
- [ ] No valid comparison insight is authored for this pair in the current slice
- [ ] UI shows the standard no-match response: *"No forensic connection found between these items."*
- [ ] No new evidence card is added to the archive

---

### Step 29: Confirm Archive Is Unchanged After Shoe Comparison
**Action:** Review the archive after the no-match response
**Expected:**
- [ ] No `ev_shoe_match` card exists in the archive
- [ ] `ev_shoe_print` still shows *"Forensic Analysis"* and `ev_julia_shoes` still shows *"Search Warrant"*
- [ ] The pair remains usable as separate evidence in contradiction and case-building flows

---

### Step 30: Review Daniel's Personal Journal
**Action:** Click `ev_personal_journal` card
**Expected:**
- [ ] Detail loads: "Daniel's Personal Journal"
- [ ] Discovery method: *"Visual Inspection"*
- [ ] Description: recent entries mention confronting both Mark (embezzlement) and Julia (marriage). Last entry: "I have to tell Julia everything tomorrow."
- [ ] Case Relevance: **CRITICAL**
- [ ] Related Persons: Daniel Ross, Mark Bennett, Julia Ross

---

### Step 31: Classify Statements on Journal — Confession Link
> **Prerequisite:** Julia's final interrogation (Day 4, Action 15) has produced `stmt_julia_confession`.

**Action:** Click `ev_personal_journal`
**Expected:**
- [ ] Side column — Statements shows:
  - `stmt_julia_confession`: *"He threatened to ruin everything. I just lost control."* — UNCLASSIFIED

**Action:** Set verdict to **Supports**
**Expected:**
- [ ] Pill turns teal: **SUPPORTS**
- [ ] The journal's last entry ("I have to tell Julia everything tomorrow") provides direct context for why the confrontation happened — this statement supports that reading

---

### Step 32: Classify Mark's Final Admissions
> **Prerequisite:** Mark's second interrogation (Day 4, Action 14) has produced `stmt_mark_deeper_admission` and `stmt_mark_final_lock`.

**Action:** Click `ev_hidden_safe`
**Expected:**
- [ ] Statements now include:
  - `stmt_mark_deeper_admission`: *"Daniel found out about the money. He said he was going to expose everything."* — UNCLASSIFIED
  - `stmt_mark_final_lock`: *"Alright. That's everything. Daniel had the records. He was going to destroy me."* — UNCLASSIFIED
  - `stmt_mark_julia_knew`: *"Julia had been asking Daniel strange questions lately."* — UNCLASSIFIED

**Action:** Set `stmt_mark_deeper_admission` → **Supports**
**Action:** Set `stmt_mark_final_lock` → **Supports**
**Action:** Set `stmt_mark_julia_knew` → **Unresolved**
**Expected:**
- [ ] Mark's admissions now corroborate the safe documents

---

### Step 33: Final Archive Check
**Action:** Scroll through the full Evidence Archive
**Expected:**
- [ ] No items have **NEW** badge remaining (all reviewed)
- [ ] Archive shows approximately 19 visible items:
  - 1 autopsy report (Day 0)
  - 8 from map Day 1 (knife, knife block, wine glasses, broken frame, wine bottle, julia text, mark call log, shoe print raw)
  - 2 lab results Day 2 (julia fingerprint, analyzed shoe print)
  - 3 from map Day 2 (hallway camera, elevator logs, parking camera)
  - 4 from map Day 3 (daniel email, bank transfer, accounting files, hidden safe)
  - 1 from map Day 4 (personal journal)
  - 1 from warrant (julia shoes)
- [ ] `ev_shoe_print_raw` is no longer visible in the archive because the upgrade flow replaced it with `ev_shoe_print`
- [ ] All major contradictions classified:
  - ev_parking_camera: Mark's "20:30" statement → CONTRADICTION ✓
  - ev_julia_fingerprint_glass: Julia's "wasn't there" statement → CONTRADICTION ✓
  - ev_elevator_logs: Julia's "visited earlier in the day" statement → CONTRADICTION ✓
- [ ] Key supports classified:
  - ev_personal_journal: Julia's confession statement → SUPPORTS ✓
  - ev_hallway_camera: Sarah's testimony → SUPPORTS ✓

---

## Evidence Tab Summary — Items Discovered & Processed

| Day | Source | Evidence Item | Lab? | Compared? |
|-----|--------|---------------|------|-----------|
| 0 | Briefing | ev_autopsy_report | — | — |
| 1 | Map — Kitchen | ev_knife | — | — |
| 1 | Map — Kitchen | ev_knife_block | — | — |
| 1 | Map — Living Room | ev_wine_glasses | Submitted Day 1 | — |
| 1 | Map — Living Room | ev_broken_picture_frame | — | — |
| 1 | Map — Living Room | ev_wine_bottle | — | — |
| 1 | Map — Phone | ev_julia_text_message | — | — |
| 1 | Map — Phone | ev_mark_call_log | — | — |
| 1 | Map — Hallway | ev_shoe_print_raw | Submitted Day 1 | — |
| 2 | Forensic Analysis | ev_julia_fingerprint_glass | — | Compared separately for insight only |
| 2 | Forensic Analysis | ev_shoe_print | — | Comparison attempt Day 4, no archive result |
| 2 | Map — Security | ev_hallway_camera | — | — |
| 2 | Map — Security | ev_elevator_logs | — | — |
| 2 | Map — Parking | ev_parking_camera | — | — |
| 3 | Map — Office Desk | ev_daniel_email | — | — |
| 3 | Map — File Cabinet | ev_bank_transfer | — | Compared Day 3 for insight |
| 3 | Map — File Cabinet | ev_accounting_files | — | Compared Day 3 for insight |
| 3 | Map — Bookshelf | ev_hidden_safe | — | — |
| 4 | Map — Personal Items | ev_personal_journal | — | — |
| 4 | Search Warrant | ev_julia_shoes | — | Comparison attempt Day 4, no archive result |

**Total evidence entries encountered during flow: 20**
**End-state archive cards visible: 19** (`ev_shoe_print_raw` is replaced by `ev_shoe_print`)
**Lab submissions: 2** (wine glasses → fingerprint, shoe print raw → footwear)
**Comparison attempts: 2** (bank transfer + accounting files, shoe print + julia shoes)
**Contradictions classified: 3** (mark departure, julia presence ×2)
**Supports classified: 4** (mark corrected, sarah testimony ×2, julia confession)

---

## Key Contradiction Map (End State)

| Evidence | Statement | Person | Verdict |
|----------|-----------|--------|---------|
| ev_parking_camera | "I left around 20:30." | Mark Bennett | CONTRADICTION |
| ev_parking_camera | "Fine. I left closer to 20:40." | Mark Bennett | SUPPORTS |
| ev_julia_fingerprint_glass | "I wasn't at the apartment that night." | Julia Ross | CONTRADICTION |
| ev_elevator_logs | "I visited earlier in the day." | Julia Ross | CONTRADICTION |
| ev_elevator_logs | "Okay... I stopped by briefly." | Julia Ross | UNRESOLVED |
| ev_hallway_camera | "I... maybe I heard a woman's voice too." | Sarah Klein | SUPPORTS |
| ev_hallway_camera | "I saw a woman leaving." | Sarah Klein | SUPPORTS |
| ev_hidden_safe | "Daniel found out about the money." | Mark Bennett | SUPPORTS |
| ev_personal_journal | "He threatened to ruin everything." | Julia Ross | SUPPORTS |

---

## Open Questions for Implementation

1. **Warrant submission location:** Is the Search Warrant for Julia's apartment submitted from the Evidence tab, or a separate Warrant screen (Desk tab)? The happy flow assumes it can be triggered from the Evidence tab when sufficient evidence is present, but this needs a defined UI home.

2. **Statement appearance timing:** Statements currently become visible on evidence items as soon as both are in the player's possession. Should there be a small delay or an explicit "link activated" notification to draw the player's attention to new statement links they haven't noticed?

3. **`stmt_julia_elevator` classification:** In Step 25, Julia's updated statement "I stopped by briefly, but Daniel was alive when I left" is classified as UNRESOLVED. An argument could be made for CONTRADICTION (she still lied about when she was there) or SUPPORTS (she admits being there, which the logs confirm). Left as UNRESOLVED in this flow to represent genuine investigative ambiguity. This is a good teaching moment for the player — not every statement fits cleanly into one category.

4. **ev_desk_fingerprint_raw:** The Study Desk in the apartment yields `ev_desk_fingerprint_raw` (Mark's desk fingerprint). If the player examines it, a lab submission flow should occur here too. Not included in the happy flow since the study desk examination is optional, but the lab submission steps would be identical to Steps 4–7.
