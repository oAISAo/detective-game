# Riverside Apartment Case - Data Issues & Improvement Suggestions

## CRITICAL ISSUES

### 1. Neighbor's Apartment Should Not Be a Visitable Location
**Files:** `locations.json`, `evidence.json`, `discovery_rules.json`, `events.json`

The neighbor's apartment (`loc_neighbor_apartment`) is listed as a location on the map, but there is nothing to investigate there. Sarah's testimonies should come from **interrogation**, not from visiting a location.

**Problems:**
- `ev_sarah_testimony` and `ev_sarah_second_testimony` have `location_found: "loc_neighbor_apartment"` but they are witness statements, not physical evidence
- The location's only investigable object is "Interview Sarah Klein" which is really an interrogation action, not a location investigation
- `discovery_rules.json` references `loc_neighbor_apartment` for Sarah's second testimony
- `searchable: false` already signals this location has no real investigative value

**Suggestion:** Remove `loc_neighbor_apartment` as a location. Sarah's testimony should be obtained purely through the interrogation system. If you want to keep 5 locations, consider adding a relevant one (e.g., Julia's residence, a bar where Julia claims she was, or a shared office).

---

### 2. Sarah's Testimony Time Creates a Timeline Impossibility
**Files:** `evidence.json`, `events.json`, `timeline.json`, `the_riverside_apartment_murder.md`

Three different times for when Sarah heard things:
- `ev_sarah_testimony`: "heard an argument around **20:45**"
- `events.json` (`evt_loud_argument`): argument at **20:55**
- `the_riverside_apartment_murder.md` (Basic Timeline): "**21:10** Sarah hears noise"

**The critical problem:** At 20:45, Mark already left (20:40) and Julia hasn't arrived yet (20:50). There is **nobody arguing** at 20:45. This creates a timeline hole where Sarah hears an argument that couldn't be happening.

**Suggestion:** Align all files. Sarah should hear the argument at ~20:55 (when Julia and Daniel are arguing) and hear footsteps at ~21:05 (Julia leaving). The design doc's "21:10" should also be updated to match.

---

### 3. Wine Glass Fingerprint Plot Hole - When Did Julia Drink Wine?
**Files:** `evidence.json`, `timeline.json`, `events.json`

Julia's fingerprint on a wine glass is CRITICAL evidence, but the timeline doesn't support Julia drinking wine:
- Julia arrives at 20:50
- Loud argument at 20:55
- Murder at 21:00
- Julia leaves at 21:05

In this 10-minute window with a heated argument and murder, it's implausible that Julia sat down and drank wine. And if she did drink wine on a previous visit, her defense claim ("I visited earlier in the day") would actually be plausible, weakening this critical evidence.

**Suggestion:** Either:
- (a) Extend Julia's timeline slightly - she arrives, Daniel offers wine trying to talk calmly, then the argument escalates. This requires adjusting the timeline to give her more time (arrive 20:45, argument at 20:55 still works).
- (b) Make the wine glasses from Mark and Daniel's earlier meeting, and find a different critical forensic link to Julia at the scene (e.g., Julia's hair/DNA, fingerprint on the doorknob, blood on her coat).

---

### 4. No Autopsy/Coroner Report Evidence
**Files:** `evidence.json`

The timeline references "Autopsy" as evidence for the murder time (21:00), and the case description mentions "estimated time of death: 21:00," but there is **no autopsy evidence item** in `evidence.json`. This is a fundamental piece of any murder investigation - establishing cause of death, time of death, and manner of death.

**Suggestion:** Add an autopsy/coroner report as evidence (e.g., `ev_autopsy_report`). It should establish:
- Cause of death: single stab wound
- Estimated time of death: approximately 21:00
- Any defensive wounds or other forensic findings

---

### 5. Desk Fingerprint (`ev_desk_fingerprint_raw`) Has No Discovery Path
**Files:** `evidence.json`, `locations.json`

`ev_desk_fingerprint_raw` is in the `evidence_pool` of `loc_victim_apartment`, but it is NOT in any `investigable_object`'s `evidence_results`. No investigable object in the apartment produces this evidence, so the player can never discover it.

**Suggestion:** Add the desk as an investigable object in the apartment, or add `ev_desk_fingerprint_raw` to an existing object's `evidence_results` (e.g., create an "Office Desk" or "Study Area" object in the apartment with fingerprint_analysis as an available action).

---

### 6. Julia's Motive Connection Is Weak/Unclear
**Files:** `case.json`, `evidence.json`, `events.json`

The solution says: "Julia learned about it and feared financial ruin." But the evidence chain doesn't clearly establish **why** Mark's embezzlement exposure would ruin Julia:
- Julia has personal debts (`ev_julia_financial_records`) - but that's her own problem, unrelated to Mark
- Julia and Mark are listed as "FRIEND" in `suspects.json` - but friendship alone doesn't explain shared financial ruin
- The journal says Daniel was going to "tell Julia everything tomorrow" - implying Julia didn't know yet? But the motive says she already knew

**Questions the player would ask:**
- Was Julia benefiting from the embezzlement?
- Was Julia involved in the scheme with Mark?
- Or did Julia kill Daniel over marital issues and the financial angle is separate?

**Suggestion:** Add evidence that clearly connects Julia to the financial scheme (e.g., transfers to Julia's account from Mark, or evidence that Julia was complicit). Alternatively, make the motive purely marital/emotional: Daniel was going to divorce Julia and expose the finances, leaving her with nothing.

---

## STRUCTURAL ISSUES

### 7. Discovery Rules vs Event Triggers - Duplicate Systems
**Files:** `discovery_rules.json`, `events.json`

The same evidence unlocking is handled by two different systems:
- `dr_julia_fingerprint_glass` (discovery_rules) AND `trig_lab_fingerprints` (event_triggers) both handle `ev_julia_fingerprint_glass`
- `dr_shoe_print` (discovery_rules) AND `trig_lab_shoe_print` (event_triggers) both handle `ev_shoe_print`
- `dr_deleted_messages` (discovery_rules) AND `trig_warrant_julia_phone` (event_triggers) both handle `ev_deleted_messages`
- `dr_julia_shoes` (discovery_rules) AND `trig_warrant_julia_search` (event_triggers) both handle `ev_julia_shoes`

This creates potential for duplicate processing or conflicting unlock conditions.

**Suggestion:** Decide which system is authoritative. Discovery rules seem designed for conditional evidence discovery, while event triggers handle narrative/scripted moments. Lab results and warrant results should probably be in only one system.

---

### 8. Julia's Interrogation Session Is Incomplete
**Files:** `events.json`

Julia's interrogation session is missing fields that all other suspects have:
- No `pressure_dialogue`
- No `break_dialogue`
- No `break_statement_ids`
- No `break_unlocks`

The other three suspects (Mark, Sarah, Lucas) all have these fields. Julia has only evidence-based triggers, with no pressure break mechanic.

**Suggestion:** Add pressure_dialogue and break_dialogue for Julia. Her break could be a more complete confession or revelation about her relationship with Mark and the financial scheme.

---

### 9. `discovered_day: 0` for All Evidence
**Files:** `evidence.json`

Every single evidence item has `discovered_day: 0`. This appears to be a placeholder value. The design doc clearly states different evidence appears on different days (lab results on Day 2, warrant evidence on Day 3, etc.).

**Suggestion:** Either:
- Set correct initial values based on when evidence can first be discovered
- Or if 0 means "not yet discovered" as a runtime default, document this clearly in the data schema

---

### 10. Surveillance Requests Have `day_installed: 0`
**Files:** `events.json`

Both surveillance requests (`surv_julia_phone` and `surv_mark_financial`) have `day_installed: 0`, meaning they're active before the game starts. There's no mechanism for the player to actually request surveillance - it's pre-installed.

**Suggestion:** Surveillance should be a player action. The player should need to request it (possibly requiring a warrant), and it should activate the day after installation. Set `day_installed` to a proper value or make it dynamic.

---

### 11. Office Unlocks Redundantly
**Files:** `events.json`

Two triggers unlock the office:
- `trig_morning_briefing_day2`: unconditionally unlocks `loc_victim_office` on Day 2
- `trig_unlock_office`: conditionally unlocks it when `ev_mark_call_log` is discovered

Since Day 2 always happens, the conditional trigger is meaningless. If the call log is discovered on Day 1, the player gets the office early, but Day 2 unlocks it regardless.

**Suggestion:** Either:
- Remove the unconditional Day 2 unlock and make the office accessible only through evidence discovery
- Or remove the conditional trigger and keep only the Day 2 unlock

---

### 12. Mark Unlocked for Interrogation Twice
**Files:** `events.json`

`trig_morning_briefing_day1` unlocks `p_mark` for interrogation on Day 1. `trig_morning_briefing_day2` also includes `unlock_interrogation:p_mark`. The Day 2 unlock is redundant.

**Suggestion:** Remove `unlock_interrogation:p_mark` from the Day 2 briefing.

---

## NARRATIVE/LOGIC ISSUES

### 13. Sarah's Role: WITNESS vs Suspect
**Files:** `suspects.json`, `the_riverside_apartment_murder.md`

Sarah is listed as "WITNESS" in `suspects.json` but the design doc lists her as "Suspect 2 - Sarah Klein." The game is designed for 4 suspects, but with Sarah as a witness, there are only 3 suspects.

**Suggestion:** Consider whether Sarah should be a suspect or witness. For the game to have 4 suspects (as per design constraints), she should probably be a suspect with `role: "SUSPECT"`, even though she ultimately turns out to be innocent. Being a suspect makes the investigation more interesting.

---

### 14. Sarah's Relationship Listed as "FRIEND" with Victim
**Files:** `suspects.json`

Sarah is listed with relationship type "FRIEND" to the victim, but the design doc and story only describe her as a neighbor. Being a friend implies a closer relationship and possible motive, which is never explored.

**Suggestion:** Change the relationship type to "NEIGHBOR" (add this type) or "ACQUAINTANCE," which is more consistent with the story.

---

### 15. Elevator Log Time Inconsistency
**Files:** `evidence.json`, `timeline.json`

- `ev_elevator_logs`: Julia's key card used at **20:48**
- `events.json` (`evt_julia_arrives`): Julia arrives at **20:50**

2-minute discrepancy. Minor but should be consistent.

**Suggestion:** Align both to the same time (20:48 or 20:50).

---

### 16. Julia's Separation Status vs Access
**Files:** `events.json`, `case.json`

Julia's interrogation says: "We were separated." But:
- She has a key card for the elevator (how? if she moved out)
- The solution says "Julia was Daniel's wife and had access to the apartment"
- If separated, why does she still have elevator access?

**Suggestion:** Either:
- Establish that they were recently separated and Julia hadn't returned her key card yet
- Or change "separated" to "having problems" - still living together but relationship strained

---

### 17. Daniel's Journal Contradicts the Motive
**Files:** `evidence.json`, `case.json`

The journal's last entry reads: "I have to tell Julia everything tomorrow." This implies Julia **didn't know** about the embezzlement yet. But the case solution says: "Julia learned about it and feared financial ruin. She killed Daniel during a confrontation."

If Julia didn't know yet (Daniel planned to tell her tomorrow), how could she have killed him over it? Did she learn about it independently? This needs to be made explicit.

**Suggestion:** Either:
- Change the journal to say something like "Julia found out about everything. She's furious." (establishing she already knew)
- Or add evidence showing Julia discovered the information independently (e.g., she found documents, or Mark told her)

---

### 18. `ev_hallway_camera` Doesn't Actually Contradict Sarah's Statement
**Files:** `events.json`, `evidence.json`

`stmt_sarah_initial` has `contradicting_evidence: ["ev_hallway_camera"]`. Sarah's statement is "I heard some arguing, but I didn't see anything." The hallway camera shows someone entering the apartment - but this doesn't prove Sarah saw anything. The camera footage doesn't contradict Sarah's claim; it only suggests she MIGHT have seen something if she looked.

**Suggestion:** This is more of a pressure point than a true contradiction. Either:
- Reframe the evidence relationship as "pressure evidence" rather than "contradicting evidence"
- Or change Sarah's initial statement to something the camera directly contradicts (e.g., "Nobody came or went that night")

---

### 19. `stmt_sarah_confronted` Has Contradicting Evidence `ev_shoe_print`
**Files:** `events.json`

Sarah saying "I may have heard a woman's voice..." is listed as contradicted by `ev_shoe_print`. A shoe print in the hallway doesn't contradict hearing a voice. These are unrelated facts.

**Suggestion:** Remove `ev_shoe_print` from the contradicting_evidence of `stmt_sarah_confronted`. The shoe print is used as a pressure trigger (`itrig_sarah_shoe`), which is correct, but it doesn't contradict the voice statement.

---

### 20. Two Wine Glasses - Who Was the Second Person?
**Files:** `evidence.json`, `timeline.json`

Two wine glasses on the table suggest Daniel had company. Based on the timeline:
- Mark visited from 19:30-20:40 (could have been drinking wine with Daniel)
- Julia arrived at 20:50 and killed Daniel by 21:00

If both glasses were from Daniel and Mark's visit, Julia's fingerprint on a glass could mean:
- She used the same glass Mark used (unlikely, no fingerprint powder would show both)
- She used it during a daytime visit (supporting her defense)
- She drank wine in the 10 minutes before killing Daniel (implausible given the argument)

**Suggestion:** Clarify in the narrative that there were actually THREE drinking vessels, or that Mark didn't drink wine (he had water/nothing), and the second glass was definitively from the evening confrontation. Or simplify: Julia arrived, Daniel poured wine to calm the situation, but the conversation escalated.

---

## MINOR ISSUES

### 21. Empty `location_found` Fields
**Files:** `evidence.json`

Several evidence items have empty `location_found`:
- `ev_deleted_messages` (warrant-obtained from Julia's phone)
- `ev_julia_shoes` (obtained via search warrant)
- `ev_julia_financial_records` (obtained through investigation)

**Suggestion:** Use a value like `"warrant_obtained"` or `"external"` instead of empty string, for clarity and to avoid null-related issues in code.

---

### 22. `ev_julia_financial_records` Has No Clear Discovery Path
**Files:** `evidence.json`, `discovery_rules.json`, `locations.json`

This evidence has:
- Empty `location_found`
- Discovery rule `dr_julia_financial_records` points to `loc_victim_office` with condition `day_gte:3`
- But it's not in the office's `evidence_pool` or any `investigable_object`

The evidence is unreachable through location investigation and only available through the discovery rule system.

**Suggestion:** Either add it to the office's evidence pool and investigable objects, or make it obtained through a warrant/interrogation instead.

---

### 23. Actions Have `time_cost: 0` for Location Visits
**Files:** `events.json`

All VISIT_LOCATION actions have `time_cost: 0`, which is correct per the game design (location entry is free, examining objects costs actions). However, `act_visit_office` has `requirements: ["day:2"]` and its results list includes ALL office evidence (`ev_hidden_safe`, `ev_personal_journal`), suggesting a single visit dumps everything. But the discovery rules add conditions (accounting files needed first for safe, Day 3 for journal).

**Suggestion:** The actions' results should only list immediately available evidence, not evidence gated by discovery rules. Or clarify that the results represent the maximum possible evidence pool, not what's immediately given.

---

### 24. `itrig_mark_safe_v1` Requires `stmt_mark_deeper_admission` Which Comes from Break
**Files:** `events.json`

The trigger `itrig_mark_safe_v1` requires `stmt_mark_deeper_admission`, which is only obtained after Mark breaks (pressure_gate reached). But the trigger also presents evidence at `topic_missing_money`. This means the hidden safe evidence can only be used on Mark AFTER he already broke, which seems redundant since the break already reveals most of the embezzlement truth.

**Suggestion:** Consider allowing the safe evidence to be presented to Mark before the break point, as an alternative path to get him to confess.

---

### 25. No Evidence Linking Julia and Mark's Secret Meetings
**Files:** `evidence.json`, `the_riverside_apartment_murder.md`

The design doc says (Layer 3): "Julia and Mark secretly met before." But there is NO evidence in `evidence.json` that establishes this connection. The only link is:
- Mark's statement `stmt_mark_julia_knew`: "Julia may have known Daniel discovered the missing money"
- Their "FRIEND" relationship in `suspects.json`

**Suggestion:** Add evidence of Julia-Mark contact (e.g., phone records between them, a hotel receipt, witness spotting them together, messages between them found on the deleted phone data). This is crucial for Layer 3 of the mystery structure.

---

### 26. Case Solution `time_minutes: 1260` and `time_day: 1`
**Files:** `case.json`

The time format `time_minutes: 1260` is unusual. 1260 minutes = 21 hours, representing 21:00. It works but is an unconventional way to represent time of death and could cause confusion.

**Suggestion:** Consider using a clearer format like `"time_of_death": "21:00"` or `"time_hours": 21`.

---

## DESIGN CHANGE: Evidence-Driven Unlocking (Replace Day-Based Unlocking)

### Current Problem
Locations and suspects currently unlock based on **which day it is**, not based on what the player has discovered. This feels artificial and breaks immersion — why would Julia suddenly become available for interrogation on Day 2 if the player hasn't found anything connecting her to the case?

**Current day-based unlocks in `events.json`:**
- `trig_morning_briefing_day1`: Unconditionally unlocks apartment, hallway, parking lot, neighbor apartment + Sarah and Mark for interrogation
- `trig_morning_briefing_day2`: Unconditionally unlocks office + Julia, Lucas, Mark (redundant) for interrogation
- Various `discovery_rules.json` entries use `day_gte:2` or `day_gte:3` conditions

**Current conditional unlocks (already exist, good pattern):**
- `trig_unlock_office`: Unlocks office when `ev_mark_call_log` is discovered (but overridden by Day 2 unconditional unlock)

### Proposed Change
**All unlocks should be driven by evidence discovery or player actions, not by day number.**

The day system should only control:
- Lab processing time (submit Day 1 → results Day 2 — this is realistic)
- Story events that happen overnight (e.g., surveillance results)
- The final deadline (Day 4 = must submit case report)

Everything else should unlock through the investigation itself.

### Proposed Unlock Chains

#### Locations

| Location | Current Unlock | Proposed Unlock |
|----------|---------------|-----------------|
| Victim's Apartment | Day 1 (auto) | Day 1 (auto) — this is the crime scene, always available |
| Building Hallway | Day 1 (auto) | Day 1 (auto) — part of the crime scene building, always available |
| Parking Lot | Day 1 (auto) | Day 1 (auto) — part of the building premises, always available |
| Neighbor's Apartment | Day 1 (auto) | **REMOVE** as location (see issue #1) |
| Victim's Office | Day 2 (auto) | **Evidence-driven:** Discover `ev_mark_call_log` (business calls) OR `ev_daniel_email` reference OR `ev_bank_transfer` — any evidence revealing Daniel's business life |

#### Suspects / Persons for Interrogation

| Person | Current Unlock | Proposed Unlock |
|--------|---------------|-----------------|
| Sarah Klein | Day 1 (auto) | Day 1 (auto) — she's the neighbor who called it in / was at the scene. Police would talk to her immediately. |
| Mark Bennett | Day 1 (auto) | **Evidence-driven:** Discover `ev_mark_call_log` (recent calls with victim) OR `ev_desk_fingerprint_raw` (fingerprint at scene). Finding evidence of Mark's connection to Daniel makes him a person of interest. |
| Julia Ross | Day 2 (auto) | **Evidence-driven:** Discover `ev_julia_text_message` (text to Daniel that night) OR `ev_broken_picture_frame` (photo of Daniel and Julia) OR `ev_julia_fingerprint_glass`. Any evidence linking Julia to Daniel makes her a person of interest. |
| Lucas Weber | Day 2 (auto) | **Evidence-driven:** Discover `ev_lucas_work_log` (maintenance logs) OR investigate the hallway maintenance office. Building staff become relevant when the player explores the building. |

#### Evidence with Day Gates

| Evidence | Current Condition | Proposed Condition |
|----------|------------------|-------------------|
| `ev_personal_journal` | `day_gte:3` + office visited | `ev_accounting_files` discovered + office visited (finding financial irregularities motivates a deeper search) OR second visit to office |
| `ev_julia_financial_records` | `day_gte:3` | Warrant obtained OR `ev_bank_transfer` + `ev_julia_text_message` discovered (connecting Julia to the financial angle) |
| `ev_shoe_print` (lab result) | `day_gte:2` + hallway visited | `ev_shoe_print_raw` submitted to lab + 1 day processing (keep time-based for lab, remove arbitrary day gate) |
| `ev_julia_fingerprint_glass` (lab) | `day_gte:2` + wine glasses found | `ev_wine_glasses` submitted to lab + 1 day processing |
| `ev_mark_fingerprint_desk` (lab) | `day_gte:2` | `ev_desk_fingerprint_raw` submitted to lab + 1 day processing |

### Benefits
1. **Player agency** — The player's choices drive the investigation, not the calendar
2. **Multiple paths** — Different players unlock content in different orders based on what they investigate first
3. **Logical progression** — "I found Julia's text to Daniel, now I want to talk to her" feels natural
4. **No wasted days** — A thorough Day 1 could unlock Julia for interrogation on Day 1, rewarding good investigation
5. **Lab time still creates pacing** — Results arriving "next day" naturally creates the day rhythm without arbitrary gates

### Impact on Data Files
- `events.json`: Rewrite `trig_morning_briefing_day2` to remove unconditional unlocks. Keep Day 1 briefing for crime scene locations + Sarah.
- `events.json`: Add new CONDITIONAL triggers for Mark, Julia, Lucas, and office
- `discovery_rules.json`: Replace all `day_gte` conditions with evidence-based conditions
- `events.json`: Keep lab triggers as TIMED (next-day delivery is fine)

---

## SUMMARY OF PRIORITIES

| Priority | Issue # | Description |
|----------|---------|-------------|
| CRITICAL | NEW | Replace day-based unlocking with evidence-driven unlocking |
| CRITICAL | 1 | Remove neighbor apartment as a location |
| CRITICAL | 2 | Fix Sarah's testimony timeline (20:45 is impossible) |
| CRITICAL | 3 | Fix wine glass/Julia fingerprint plot hole |
| CRITICAL | 4 | Add autopsy report evidence |
| CRITICAL | 5 | Fix desk fingerprint discovery path |
| CRITICAL | 6 | Clarify Julia's motive connection to embezzlement |
| HIGH | 7 | Resolve discovery rules vs event triggers duplication |
| HIGH | 8 | Complete Julia's interrogation session |
| HIGH | 17 | Fix journal contradiction with motive |
| HIGH | 20 | Clarify wine glass ownership |
| HIGH | 25 | Add evidence for Julia-Mark secret meetings |
| MEDIUM | 9 | Fix discovered_day placeholders |
| MEDIUM | 10 | Fix surveillance request day_installed |
| MEDIUM | 11-12 | Fix redundant unlocks |
| MEDIUM | 13-14 | Fix Sarah's role and relationship |
| MEDIUM | 15-16 | Fix minor time and access inconsistencies |
| LOW | 18-19 | Fix contradicting_evidence misuse |
| LOW | 21-26 | Minor data quality issues |
