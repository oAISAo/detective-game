# Riverside Apartment Murder - Happy Flow (Perfect Game Progression)

> This document traces the ideal player progression through the case.
> It follows all game mechanics: actions, triggers, lab processing, discovery rules, and interrogation chains.
> **4 actions per day, 4 days = 16 total actions.**
> Location entry is free (0 actions). Examining objects and interrogations cost 1 action each.

---

## Hidden Truth (Not visible to player)

| Time  | Event |
|-------|-------|
| 19:30 | Mark visits Daniel |
| 20:15 | Mark and Daniel argue about money/embezzlement |
| 20:40 | Mark leaves the building |
| 20:40 | Julia sends text: "Are you home? We need to talk." |
| 20:48 | Julia's key card used in elevator |
| 20:50 | Julia enters Daniel's apartment |
| 20:55 | Julia and Daniel argue loudly |
| 21:00 | Julia stabs Daniel with kitchen knife |
| 21:05 | Julia leaves quickly, footsteps heard in hallway |

**Murderer:** Julia Ross (wife)
**Motive:** Daniel discovered Mark was embezzling money and planned to expose him. Julia learned about it and feared financial ruin.
**Weapon:** Kitchen knife from Daniel's own kitchen.

---

## DAY 1

### Morning Briefing
**Event trigger:** `trig_morning_briefing_day1`

> "A man has been found dead in his apartment from a knife wound. Victim identified as Daniel Ross, age 42, financial consultant. The crime scene and building are now available for investigation."

**Unlocked locations:**
- Victim's Apartment (`loc_victim_apartment`)
- Building Hallway (`loc_hallway`)
- Parking Lot (`loc_parking_lot`)
- Neighbor's Apartment (`loc_neighbor_apartment`)

**Unlocked interrogations:**
- Sarah Klein (`p_sarah`)
- Mark Bennett (`p_mark`)

---

### Daytime - Player Actions

#### Action 1: Examine Kitchen (at Victim's Apartment)
*Visit Victim's Apartment (free — location entry)*
*Examine investigable object: `obj_kitchen` (1 action)*

**Evidence discovered:**
- `ev_knife` — **Murder Weapon (Kitchen Knife)** — A bloody kitchen knife found in the victim's kitchen sink. Blood matches the victim. *(CRITICAL)*
- `ev_knife_block` — **Knife Block in Kitchen** — A knife block on the counter with one knife missing. The missing knife matches the murder weapon.

**Player learns:** The murder weapon came from the victim's own kitchen. This was not premeditated with a brought weapon.

---

#### Action 2: Examine Living Room (at Victim's Apartment)
*Examine investigable object: `obj_living_room` (1 action)*

**Evidence discovered:**
- `ev_wine_glasses` — **Two Wine Glasses on Table** — Two wine glasses on the living room table. Indicates the victim had company before the murder.
- `ev_broken_picture_frame` — **Broken Picture Frame** — A broken picture frame on the floor. The photo shows Daniel and Julia together. Suggests an argument took place.
- `ev_wine_bottle` — **Wine Bottle** — A recently opened bottle of wine on the table.

**Player learns:** Daniel had a guest. The broken photo of Daniel and Julia hints at relationship trouble.

**Lab submission:** Player sends wine glasses for fingerprint analysis.
→ Lab request `lab_fingerprint_glass`: input `ev_wine_glasses`, results on Day 2.

---

#### Action 3: Examine Victim's Phone (at Victim's Apartment)
*Examine investigable object: `obj_victim_phone` (1 action)*

**Evidence discovered:**
- `ev_victim_phone` — **Victim's Phone** — Daniel's phone found on the table. Contains messages and call history.
- `ev_julia_text_message` — **Text Message From Julia** — Text from Julia at 20:40: "Are you home? We need to talk."
- `ev_mark_call_log` — **Call Log Between Mark and Daniel** — Multiple calls between Mark and Daniel about financial issues in the days before the murder.

**Event trigger:** `trig_unlock_office` fires (condition: `ev_mark_call_log` discovered)
→ Notification: "The call log reveals a business connection. Daniel's office is now available for investigation."
→ `loc_victim_office` unlocked early (would also unlock on Day 2 automatically)

**Player learns:** Julia wanted to talk to Daniel that evening. Mark and Daniel had ongoing financial tensions. There's a business dimension to this case.

---

#### Action 4: Examine Hallway Floor (at Building Hallway)
*Visit Building Hallway (free — location entry)*
*Examine investigable object: `obj_hallway_floor` (1 action, requires forensic_kit)*

**Evidence discovered:**
- `ev_shoe_print_raw` — **Shoe Print in Hallway (Unanalyzed)** — A shoe print found near the victim's apartment. Needs lab analysis.

**Lab submission:** Player sends shoe print for analysis.
→ Lab request `lab_shoe_print`: input `ev_shoe_print_raw`, results on Day 2.

**Player learns:** Someone left a shoe print near the apartment. Could belong to the killer.

---

### Night
Day 1 ends. Lab processing overnight.

**Evidence collected on Day 1 (10 items):**
ev_knife, ev_knife_block, ev_wine_glasses, ev_broken_picture_frame, ev_wine_bottle, ev_victim_phone, ev_julia_text_message, ev_mark_call_log, ev_shoe_print_raw

**Pending lab results:** fingerprint on wine glass, shoe print analysis.

---

## DAY 2

### Morning Briefing
**Event trigger:** `trig_morning_briefing_day2`

> "Lab results are arriving. Mark Bennett, Julia Ross, and Lucas Weber have been identified as additional persons of interest. Daniel's office is now accessible for investigation."

**Unlocked locations:**
- Victim's Office (`loc_victim_office`) *(already unlocked via call log on Day 1)*

**Unlocked interrogations:**
- Julia Ross (`p_julia`)
- Lucas Weber (`p_lucas`)
- Mark Bennett (`p_mark`) *(already unlocked — redundant)*

**Lab results delivered:**

1. **`trig_lab_fingerprints`** fires (condition: `ev_wine_glasses` discovered)
   → Delivers `ev_julia_fingerprint_glass` — **Julia's Fingerprint on Wine Glass** *(CRITICAL)*
   → "Lab results are in — fingerprints from the crime scene have been identified."
   → Fingerprint matched to Julia Ross. **Contradicts her claim she wasn't at the apartment.**

2. **`trig_lab_shoe_print`** fires (condition: `ev_shoe_print_raw` discovered)
   → Delivers `ev_shoe_print` — **Shoe Print in Hallway** *(CRITICAL)*
   → "Lab results are in — the hallway shoe print has been analyzed and matches women's size 38."

**Player learns (morning):** Julia's fingerprint is on a wine glass at the crime scene. The shoe print belongs to a woman. Julia is now a strong person of interest.

---

### Daytime - Player Actions

#### Action 5: Examine Building Security System (at Building Hallway)
*Visit Building Hallway (free — return visit)*
*Examine investigable object: `obj_security_system` (1 action)*

**Evidence discovered:**
- `ev_hallway_camera` — **Hallway Camera (Blurry Figure)** — Someone entering the apartment at ~20:50. Height roughly matches Julia Ross.
- `ev_elevator_logs` — **Elevator Logs** — Julia Ross's key card used at 20:48 on the night of the murder. *(CRITICAL)*

**Player learns:** Julia was in the building at 20:48, just minutes before the murder. Her fingerprint + elevator logs = she was there that night.

---

#### Action 6: Examine Parking Camera (at Parking Lot)
*Visit Parking Lot (free)*
*Examine investigable object: `obj_parking_camera` (1 action)*

**Evidence discovered:**
- `ev_parking_camera` — **Parking Lot Camera Footage** — Mark Bennett leaving the building at 20:40. *(CRITICAL)*

**Player learns:** Mark left at 20:40, not 20:30 as he claimed. He lied about 10 minutes. Also, Mark left BEFORE Julia arrived — he wasn't there during the murder.

---

#### Action 7: Interrogate Mark Bennett (1 action)
*Mark's initial story (from Day 1 or first encounter):*
> "I already told the police what happened. I stopped by to talk to Daniel, we argued a little, and then I left. That's it."

**Initial statements recorded:**
- `stmt_mark_visit`: "I stopped by to talk to Daniel."
- `stmt_mark_argument`: "We argued a little."
- `stmt_mark_departure_time`: "I left around 20:30."

**Available topics:**
- "Why were you there?" → "Daniel asked me to come by. It was supposed to be a quick conversation."
- "What time did you leave?" → "Like I said, around 20:30. Maybe a few minutes after." (`stmt_mark_departure_reinforced`)
- "What was your relationship with Daniel?" → "We worked together for years. Things were tense lately, but that's business." (`stmt_mark_argument` reinforced)

**Evidence confrontation — Present parking camera (`ev_parking_camera`):**
→ Trigger `itrig_mark_parking_v1` fires (requires `stmt_mark_departure_time`)
→ Mark reacts (ADMISSION):
> "Alright... maybe it was closer to 20:40. I didn't think ten minutes mattered."
→ New statement: `stmt_mark_corrected_departure`
→ Unlocks topic: `topic_why_lie_about_time`
→ +1 pressure point

**Follow-up topic — "Why did you lie about the time?":**
→ Mark responds:
> "Because it looks bad, alright? We argued. I didn't want to make myself look worse than I already do."
→ Statement: `stmt_mark_lied_to_hide_argument`

**Player learns:** Mark lied about his departure time to hide the fact that he argued with Daniel. He's covering something but may not be the killer (he left before Julia arrived).

---

#### Action 8: Interrogate Sarah Klein (1 action)
*Sarah's initial story:*
> "I already told them what I know... I was in my apartment all evening. I heard some arguing next door, but I didn't see anything."

**Initial statement recorded:**
- `stmt_sarah_initial`: "I heard some arguing, but I didn't see anything."

**Available topics:**
- "What did you hear?" → "There was shouting. A man and... I don't know, maybe another voice." (`stmt_sarah_heard_argument`)
- "Why didn't you look?" → "I don't like getting involved in other people's problems." (`stmt_sarah_didnt_look`)
- "Did Daniel argue like this often?" → "I'd heard raised voices before, but never like that. That night felt different." (`stmt_sarah_not_unusual`)

**Evidence confrontation — Present hallway camera (`ev_hallway_camera`):**
→ Trigger `itrig_sarah_camera` fires (requires `stmt_sarah_initial`)
→ Sarah reacts (ADMISSION):
> "I... maybe I heard a woman's voice too. I wasn't sure. I didn't want to say something if I wasn't certain."
→ New statement: `stmt_sarah_confronted`
→ Unlocks topic: `topic_sarah_why_hide`
→ +1 pressure point

**Follow-up topic — "Why didn't you say that earlier?":**
→ Sarah responds:
> "I wasn't sure what I heard. And I didn't want to get in trouble for saying the wrong thing."

**Evidence confrontation — Present shoe print (`ev_shoe_print`):**
→ Trigger `itrig_sarah_shoe` fires (requires `stmt_sarah_confronted`)
→ Sarah reacts (ADMISSION):
> "I heard footsteps outside my door. Fast ones. Like someone was trying not to stay there long."
→ New statement: `stmt_sarah_footsteps`
→ Unlocks topic: `topic_sarah_footsteps`
→ +1 pressure point (total: 2 — reaches pressure_gate)

**Pressure gate reached (2):**
> Sarah fidgets. "Please... I just want to stay out of this. I'm scared enough already."

**Sarah breaks:**
> "I was scared, alright? I did look. Just for a second. I saw a woman leaving Daniel's apartment. She was moving fast, like she didn't want anyone to see her. I didn't say anything because I didn't want to be dragged into this."
→ New statement: `stmt_sarah_saw_woman`
→ Unlocks topic: `topic_sarah_after_break` — "Can you describe her?"

**Follow-up — "Can you describe her?":**
> "It was dark. I only saw her for a second. She was... average height, maybe? Dark hair. I couldn't tell much more. I'm sorry."

**Player learns:** Sarah saw a woman leaving Daniel's apartment quickly after the murder. The description loosely matches Julia. Combined with elevator logs and fingerprints, the case against Julia is building.

---

### Night
Day 2 ends.

**Evidence collected so far (15 items):**
Day 1 items + ev_julia_fingerprint_glass, ev_shoe_print, ev_hallway_camera, ev_elevator_logs, ev_parking_camera

**Key insights formed:**
- Julia's fingerprint at crime scene contradicts her alibi
- Julia's key card used at 20:48 — she was there
- A woman was seen leaving the apartment after the murder
- Mark left at 20:40 — before the murder, but he lied about the time
- Mark and Daniel had financial tensions

---

## DAY 3

### Morning
No automatic briefing event for Day 3.

**Discovery rules now available:**
- `dr_personal_journal`: available (loc_victim_office visited check — not visited yet, will be available once visited)
- `dr_julia_financial_records`: available (day_gte:3)

---

### Daytime - Player Actions

#### Action 9: Examine Office Desk (at Victim's Office)
*Visit Victim's Office (free — first visit)*
*Examine investigable object: `obj_office_desk` (1 action)*

**Evidence discovered:**
- `ev_daniel_email` — **Email From Daniel to Mark** — Subject: "We need to fix this before tomorrow." References financial irregularities.

**Player learns:** Daniel was pressing Mark about financial problems. The email suggests urgency — Daniel wanted things resolved immediately.

---

#### Action 10: Examine File Cabinet (at Victim's Office)
*Examine investigable object: `obj_file_cabinet` (1 action)*

**Evidence discovered:**
- `ev_bank_transfer` — **Suspicious Bank Transfer** *(CRITICAL)* — Money moved from the company account to an unknown destination. Suggests embezzlement.
- `ev_accounting_files` — **Accounting Files** — Detailed accounting files showing a pattern of embezzlement from the company.

**Discovery rule triggers:** `dr_hidden_safe` (condition: `ev_accounting_files` discovered)
→ Hidden safe becomes discoverable in the office.

**Player learns:** Mark was embezzling money from the company. Daniel knew about it. This is the deeper secret — Layer 4 of the mystery.

---

#### Action 11: Examine Hidden Safe (at Victim's Office)
*Examine investigable object: `obj_office_safe` (1 action)*
*(Now accessible after discovering accounting files)*

**Evidence discovered:**
- `ev_hidden_safe` — **Hidden Safe in Office** *(CRITICAL)* — Documents revealing the full extent of Mark's financial crimes and Daniel's plan to expose him.

**Player learns:** Daniel was going to expose Mark's embezzlement. This is the real motive behind the murder — but who acted on it? Mark had motive to silence Daniel, but Mark left before the murder...

---

#### Action 12: Interrogate Julia Ross (1 action)
*Julia's initial story:*
> Julia sits rigid, arms crossed. "Daniel was my husband. We were separated, but I had nothing to do with this."

**Initial statement recorded:**
- `stmt_julia_initial`: "I wasn't at the apartment that night."

**Available topic — "Julia's Presence at Apartment"** (requires `ev_julia_fingerprint_glass`):
→ This topic is available because we have the fingerprint evidence.

**Evidence confrontation — Present fingerprint on wine glass (`ev_julia_fingerprint_glass`):**
→ Trigger `itrig_julia_fingerprint` fires (requires `stmt_julia_initial`)
→ Julia reacts (DEFLECTION):
> "I visited earlier in the day."
→ New statement: `stmt_julia_fingerprint`
→ +2 pressure points
→ Julia deflects toward Mark: "Maybe you should be looking at his business partner."

**Evidence confrontation — Present elevator logs (`ev_elevator_logs`):**
→ Trigger `itrig_julia_elevator` fires (requires `stmt_julia_fingerprint`)
→ Julia reacts (ADMISSION):
> "Okay... I stopped by briefly. But Daniel was alive when I left."
→ New statement: `stmt_julia_elevator`
→ +2 pressure points (total: 4)

**Player learns:** Julia lied about not being there. First she said she wasn't there, then "earlier in the day," now admits she was there that night. Each lie exposed builds the case. But she maintains Daniel was alive when she left.

**Note:** Player doesn't yet have enough to break Julia. The journal entry (trigger 4) and Julia's shoes are needed for the final confrontation. Player wisely saves the remaining evidence for Day 4.

---

### Night
Day 3 ends.

**Discovery rules now satisfied:**
- `dr_personal_journal`: location visited + day_gte:3 ✓ → `ev_personal_journal` now discoverable

**Evidence collected so far (20 items):**
Previous + ev_daniel_email, ev_bank_transfer, ev_accounting_files, ev_hidden_safe

---

## DAY 4

### Morning Briefing
**Event trigger:** `trig_final_day_pressure`

> "Final day of investigation. You must submit your case report to the prosecutor before end of day."

**Mandatory action added:** `submit_case_report`

---

### Daytime - Player Actions

#### Action 13: Examine Personal Items (at Victim's Office)
*Visit Victim's Office (free — return visit)*
*Examine investigable object: `obj_personal_items` (1 action)*

**Evidence discovered:**
- `ev_personal_journal` — **Daniel's Personal Journal** *(CRITICAL)* — Recent entries mention confronting both Mark about the embezzlement and Julia about their marriage. The last entry reads: "I have to tell Julia everything tomorrow."

**Player learns:** Daniel was about to tell Julia about the embezzlement. This connects Julia to the financial motive — if Julia already knew (or found out that evening), she had reason to fear Daniel would expose everything.

---

#### Action 14: Interrogate Mark Bennett — Second Session (1 action)
*Return interrogation with new financial evidence.*

**Evidence confrontation — Present bank transfer (`ev_bank_transfer`):**
→ Trigger `itrig_mark_bank_v1` fires
→ Mark reacts (DENIAL):
> "This has nothing to do with Daniel's murder. You don't understand how messy business accounting can get."
→ New statement: `stmt_mark_denies_financial`
→ Unlocks topic: `topic_missing_money`
→ +1 pressure point

**Topic — "What happened to the missing money?":**
→ Requires `stmt_mark_denies_financial` (just obtained)
→ Mark responds:
> "I made some transfers I shouldn't have. I was going to fix it before Daniel found out."
→ Statement: `stmt_mark_money_admission`

**Pressure gate reached (2):**
> "You're trying to pin this on me because I lied. That doesn't make me a murderer."

**Mark breaks:**
> "Fine. Daniel found out about the money. He said he was going to expose everything the next morning. I panicked, alright? But when I left, he was still alive."
→ Statement: `stmt_mark_deeper_admission`
→ Unlocks topic: `topic_who_else_knew`

**Evidence confrontation — Present hidden safe (`ev_hidden_safe`):**
→ Trigger `itrig_mark_safe_v1` fires (requires `stmt_mark_deeper_admission`)
→ Mark reacts (ADMISSION):
> "Alright. That's everything. Daniel had the records. He was going to destroy me."
→ Statement: `stmt_mark_final_lock`

**Topic — "Who else knew?":**
→ Requires `stmt_mark_deeper_admission` (obtained)
→ Mark responds:
> "I don't know for sure... but Julia had been asking Daniel strange questions lately."
→ Statement: `stmt_mark_julia_knew`

**Player learns:** Mark confirms the full embezzlement scheme. Daniel was going to expose him. Critically, Mark hints that **Julia may have known** about the financial situation. This connects Julia's motive: she feared financial ruin if Daniel went public.

---

#### Action 15: Interrogate Julia Ross — Final Confrontation (1 action)
*Return interrogation with all remaining evidence.*

*Julia's current statement: `stmt_julia_elevator` — "I stopped by briefly. Daniel was alive when I left."*

**Evidence confrontation — Present Julia's shoes (`ev_julia_shoes`):**
*(Requires warrant: `warrant_julia_search` — assumed obtained based on evidence of presence + connection)*
→ Trigger `itrig_julia_shoes` fires (requires `stmt_julia_elevator`)
→ Julia reacts (PANIC):
> "That... that doesn't prove anything! I told you I stopped by briefly!"
→ +3 pressure points (total: 7 — well above pressure_gate of 2)

**Evidence confrontation — Present personal journal (`ev_personal_journal`):**
→ Trigger `itrig_julia_journal` fires (requires `stmt_julia_elevator`) — BREAKPOINT
→ Julia reacts (PARTIAL_CONFESSION):
> "He threatened to ruin everything. I just lost control."
→ Statement: `stmt_julia_confession`
→ +4 pressure points

**THE BREAKTHROUGH MOMENT.** Julia partially confesses to the murder. The case is essentially solved.

**Player learns:** Julia killed Daniel because he was going to expose the financial scheme. She went to confront him about it, the argument escalated, and she stabbed him with his own kitchen knife in a moment of rage.

---

#### Action 16: Submit Case Report (1 action)
*Player submits final theory to the prosecutor.*

**Case Report:**

| Field | Answer | Supporting Evidence |
|-------|--------|-------------------|
| **Murderer** | Julia Ross | ev_julia_fingerprint_glass, ev_elevator_logs, ev_shoe_print, ev_julia_shoes, ev_personal_journal, stmt_julia_confession |
| **Motive** | Daniel discovered Mark's embezzlement and planned to expose it. Julia feared financial ruin. | ev_bank_transfer, ev_hidden_safe, ev_personal_journal, ev_deleted_messages |
| **Weapon** | Kitchen knife (from victim's kitchen) | ev_knife, ev_knife_block |
| **Time of Death** | 21:00 | ev_sarah_testimony, stmt_sarah_saw_woman, ev_parking_camera (Mark left at 20:40, before the murder) |
| **Access** | Julia was Daniel's wife and had a key card to the building | ev_elevator_logs |

**Reconstructed Timeline:**

| Time | Event | Evidence |
|------|-------|----------|
| 19:30 | Mark arrives at Daniel's apartment | stmt_mark_visit, ev_mark_call_log |
| 20:15 | Daniel confronts Mark about embezzlement | ev_daniel_email, ev_bank_transfer |
| 20:40 | Mark leaves the building | ev_parking_camera |
| 20:40 | Julia sends text: "Are you home?" | ev_julia_text_message |
| 20:48 | Julia uses key card in elevator | ev_elevator_logs |
| 20:50 | Julia enters apartment (blurry figure on camera) | ev_hallway_camera |
| 20:55 | Loud argument heard (male and female voices) | ev_sarah_testimony, stmt_sarah_confronted, stmt_lucas_heard_argument |
| 21:00 | Daniel stabbed with kitchen knife | ev_knife |
| 21:05 | Julia leaves quickly (footsteps heard, shoe print left) | ev_shoe_print, ev_julia_shoes, stmt_sarah_footsteps, stmt_sarah_saw_woman |

**Prosecutor Confidence: STRONG / PERFECT CASE**

---

## Action Summary

| Day | Action # | Action | Key Result |
|-----|----------|--------|------------|
| 1 | 1 | Examine Kitchen | Murder weapon found |
| 1 | 2 | Examine Living Room | Wine glasses, broken picture frame |
| 1 | 3 | Examine Victim's Phone | Julia's text, Mark's calls → office unlocked |
| 1 | 4 | Examine Hallway Floor | Shoe print found → sent to lab |
| 2 | 5 | Examine Security System | Hallway camera + elevator logs (Julia at 20:48) |
| 2 | 6 | Examine Parking Camera | Mark leaving at 20:40 |
| 2 | 7 | Interrogate Mark (1st) | Exposes departure time lie |
| 2 | 8 | Interrogate Sarah | Breaks — saw woman leaving apartment |
| 3 | 9 | Examine Office Desk | Daniel's email to Mark about finances |
| 3 | 10 | Examine File Cabinet | Bank transfer + accounting files → safe unlocked |
| 3 | 11 | Examine Hidden Safe | Full embezzlement documentation |
| 3 | 12 | Interrogate Julia (1st) | Exposes presence lies (fingerprint → elevator) |
| 4 | 13 | Examine Personal Items | Daniel's journal — "tell Julia everything tomorrow" |
| 4 | 14 | Interrogate Mark (2nd) | Full embezzlement confession, hints Julia knew |
| 4 | 15 | Interrogate Julia (final) | **CONFESSION** — "He threatened to ruin everything. I just lost control." |
| 4 | 16 | Submit Case Report | Case closed |

---

## Evidence Not Collected in Happy Flow

The following evidence exists in the data but is **not discovered** in this happy flow:

| Evidence | Reason Not Found |
|----------|-----------------|
| `ev_desk_fingerprint_raw` / `ev_mark_fingerprint_desk` | No investigable object produces desk fingerprint (data issue #5) |
| `ev_lucas_work_log` | Player skipped Maintenance Office (optional — Lucas is a red herring) |
| `ev_deleted_messages` | Requires warrant for Julia's phone (`warrant_julia_phone`); not strictly needed for conviction |
| `ev_julia_financial_records` | Discovery rule makes it available Day 3 but no clear investigable object path |
| `ev_sarah_testimony` / `ev_sarah_second_testimony` | These are location-based evidence at neighbor's apartment, but Sarah's info comes through interrogation instead (data issue #1) |

---

## Warrants Required

For this happy flow to work, the player needs to obtain at least one warrant:

1. **Search Warrant for Julia's Residence** (`warrant_julia_search`)
   - Required to obtain: `ev_julia_shoes`
   - Supporting evidence for warrant: `ev_julia_fingerprint_glass` (PRESENCE) + `ev_elevator_logs` (OPPORTUNITY)
   - **When:** Can be requested on Day 2 after receiving lab results and discovering elevator logs

2. **Phone Warrant for Julia** (`warrant_julia_phone`) *(optional for perfect case)*
   - Required to obtain: `ev_deleted_messages`
   - Supporting evidence: `ev_julia_text_message` (CONNECTION) + `ev_julia_fingerprint_glass` (PRESENCE)
   - **When:** Can be requested on Day 2+

---

## Surveillance (Optional)

If the player sets up surveillance:

- **Phone tap on Julia** (`surv_julia_phone`): Day 2 intercepts Julia calling about "getting rid of evidence" (`evt_surv_julia_call` at 14:30)
- **Financial monitoring on Mark** (`surv_mark_financial`): Day 2 detects Mark attempting offshore transfer (`evt_surv_mark_transfer` at 11:15)

These provide additional context but are not required for the core case.

---

## Interrogation Not Covered: Lucas Weber

Lucas is a red herring. In the happy flow, the player may optionally interrogate him:

**Initial story:**
> "I'm the building maintenance guy. I was in the basement working all evening."
→ Statement: `stmt_lucas_initial`: "I finished work at 19:00."

**Present work log (`ev_lucas_work_log`):**
> "Fine, I was working until 20:00, not 19:00. But I was in the basement the whole time, nowhere near his apartment."

**Present elevator logs (`ev_elevator_logs`):**
> "See? My key card wasn't used for the elevator. I took the stairs to the basement. I never went to his floor."

**Lucas breaks (pressure gate: 1):**
> "Alright, fine. I wasn't in the basement the whole time. I came up to grab a tool from the supply closet on the third floor around 20:45. I heard yelling from the apartment — a man and a woman going at it. I didn't see anything, but the voice... it wasn't the neighbor lady."
→ Statement: `stmt_lucas_heard_argument` — corroborates the argument and the female voice (Julia).

**Lucas is eliminated as a suspect.** His testimony actually strengthens the case against Julia.

---

## Story Layers Uncovered

| Layer | Description | When Discovered |
|-------|-------------|-----------------|
| **Layer 1 — The Crime** | Daniel Ross stabbed in his apartment at 21:00 | Day 1 |
| **Layer 2 — The Lies** | Mark lied about departure time. Julia lied about being there. Sarah hid what she saw. Lucas lied about work time. | Day 2 |
| **Layer 3 — Hidden Relationships** | Mark and Daniel had a business conflict beyond normal tensions. Julia may have known Mark. | Day 2-3 |
| **Layer 4 — The Secret** | Mark was embezzling money. Daniel discovered it and planned to expose him. | Day 3 |
| **Layer 5 — The Truth** | Julia killed Daniel to prevent the financial exposure that would ruin her. The murder was an emotional reaction during confrontation. | Day 4 |
