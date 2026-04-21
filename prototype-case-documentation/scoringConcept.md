# Case Scoring & Ranking System — Design Concept

## Core Idea

The player's goal is to **solve the case correctly in the fewest days possible**. Every action matters. Efficient investigators who plan well, follow the right leads, and avoid dead ends are rewarded with higher ranks.

This creates the central tension of the game:
> *"Do I have enough to solve this now, or do I need another day?"*

---

## Two Dimensions of Performance

A great detective isn't just fast — they also build a strong case. The scoring system evaluates **two things**:

### 1. Speed — How many days did you need?
Each case has a **par** — the minimum number of days a perfect investigation requires. This is constrained by lab processing times, evidence chains, and interrogation dependencies. You can't skip waiting for lab results.

### 2. Case Strength — How solid is your case report?
This is the existing **Prosecutor Confidence System** from the design doc. It evaluates:
- Evidence strength and completeness
- Timeline accuracy
- Motive proof
- Elimination of alternative suspects
- Absence of contradictions

Both dimensions combine into a single rank.

---

## How It Works

### Submitting the Case
The player can **submit their case report at any time** — they don't have to wait until Day 4. The "End Investigation" button is always available from Day 1 onward.

When they submit:
1. The Prosecutor evaluates the case (confidence score)
2. If the case is **too weak** (below minimum threshold), the prosecutor rejects it: *"I can't take this to court. You need more evidence."* The player continues investigating.
3. If the case meets the minimum threshold, it's **accepted**. The day count is locked. The game evaluates the final rank.

### The Minimum Threshold
To prevent random guessing on Day 1, the prosecutor requires at minimum:
- Correct suspect identified
- At least 1 piece of critical evidence linking suspect to the crime
- At least 1 piece of evidence establishing motive
- A plausible timeline (key events in roughly correct order)

This is deliberately low — the player CAN submit a weak-but-correct case early for speed. But their case strength score will suffer.

---

## Scoring Formula

```
Final Score = Speed Score + Case Strength Score
```

### Speed Score (0-50 points)

Each case defines a par (minimum days). Points decrease for each day over par.

| Days | Points | Description |
|------|--------|-------------|
| Par (minimum) | 50 | Perfect speed — impossible to go faster |
| Par + 1 | 40 | Very efficient |
| Par + 2 | 30 | Good |
| Par + 3 | 20 | Average |
| Par + 4 | 10 | Slow |
| Par + 5+ | 0 | No speed bonus |

For the Riverside Apartment case, par would likely be **3 days** (Day 1: collect + lab submit, Day 2: lab results + investigate office + interrogate, Day 3: confront Julia with full evidence chain).

### Case Strength Score (0-50 points)

Based on the prosecutor confidence evaluation:

| Category | Max Points | What's Evaluated |
|----------|-----------|-----------------|
| **Critical evidence** | 15 | How many of the critical evidence items were linked to the case report |
| **Timeline accuracy** | 15 | How closely the submitted timeline matches the true timeline |
| **Motive proof** | 10 | Evidence attached to support the claimed motive |
| **Suspect elimination** | 10 | Were alternative suspects addressed/eliminated with evidence |

**Critical evidence scoring example (Riverside Apartment):**
- 10 critical evidence items exist (per `case.json`)
- Each linked to the case report = 1.5 points
- Finding and linking all 10 = 15 points

**Timeline scoring:**
- 8 timeline events exist
- Each correctly placed = ~1.9 points
- All correct = 15 points

---

## Rank Titles

Ranks are thematic detective titles, not generic stars. They reflect both competence and reputation.

| Score | Rank | Description |
|-------|------|-------------|
| 90-100 | **Chief Inspector** | Flawless. Fast and thorough. The case is airtight. |
| 75-89 | **Senior Detective** | Excellent work. Minor gaps but a strong conviction. |
| 60-74 | **Detective** | Solid investigation. Some inefficiencies or missed evidence. |
| 45-59 | **Junior Detective** | The case holds, but the defense will have openings. |
| 30-44 | **Cadet** | Barely enough. The trial could go either way. |
| 0-29 | **Rookie** | The suspect might walk free. Back to the academy. |

### What the Player Sees

After submitting the case report and the prosecutor accepts it:

```
═══════════════════════════════════════
         CASE CLOSED

    The Riverside Apartment Murder
═══════════════════════════════════════

    Investigation completed in 3 days

    Prosecutor Confidence: 87%

         ★ SENIOR DETECTIVE ★

    Speed:          40/50
    Case Strength:  42/50
    ─────────────────────
    Total Score:    82/100

    "Excellent work, detective. The
     evidence against Julia Ross is
     compelling. The jury won't need
     long to deliberate."

═══════════════════════════════════════
    [Review Case Details]
    [Return to Menu]
═══════════════════════════════════════
```

---

## The Speed vs Thoroughness Tension

This is what makes the system interesting. Consider two players:

**Player A — The Speedrunner (Day 3 submit)**
- Finds minimum evidence, gets Julia's confession fast
- Skips Mark's embezzlement deep dive, skips Lucas entirely
- Speed: 50/50, Case Strength: 28/50
- Total: 78 → **Senior Detective**

**Player B — The Perfectionist (Day 5 submit)**
- Finds every piece of evidence, eliminates all suspects, perfect timeline
- Speed: 20/50, Case Strength: 50/50
- Total: 70 → **Detective**

**Player C — The Balanced Investigator (Day 4 submit)**
- Efficient but thorough, finds most critical evidence
- Speed: 40/50, Case Strength: 45/50
- Total: 85 → **Senior Detective**

Player C scores highest — balancing speed and thoroughness is the optimal strategy. But Players A and B both have valid approaches, which supports replayability.

---

## Case Par Calculation

Each case defines its par based on hard constraints:

1. **Lab processing** — If evidence must go to the lab and results come back next day, that's a minimum 2-day span
2. **Evidence chains** — If Evidence B requires Evidence A first, each link adds potential time
3. **Interrogation dependencies** — If Julia's confession requires the journal, which requires the safe, which requires accounting files... each step might need a separate action

**Riverside Apartment par analysis:**

Day 1 (minimum actions needed):
- Examine living room → wine glasses → submit to lab (1 action)
- Examine victim's phone → text message unlocks Julia (1 action)
- Examine hallway floor → shoe print → submit to lab (1 action)
- Examine hallway security → elevator logs + camera (1 action)

Day 2 (lab results arrive):
- Visit parking lot → parking camera (1 action)
- Visit office → file cabinet → accounting files (1 action)
- Examine bookshelf → hidden safe (1 action, unlocked by accounting files)
- Interrogate Mark → pressure break with bank transfer + safe (1 action)

Day 3:
- Examine desk drawer → journal (1 action, unlocked by safe)
- Interrogate Julia → fingerprint → elevator → shoes → journal → confession (1 action)
- Submit case report (1 action)

**Par = 3 days** (11 actions minimum, fits in 3 days of 4 actions each)

This par value would be stored in `case.json`:
```json
{
  "scoring": {
    "par_days": 3,
    "max_days": 8,
    "critical_evidence_count": 10,
    "timeline_events_count": 8
  }
}
```

---

## Maximum Days (Soft Limit)

There's no hard fail, but the investigation has a **soft deadline**:

- **On the par day:** No pressure. Business as usual.
- **On par + 2:** Chief calls: *"The media is asking questions. We need progress."*
- **On par + 4:** Chief calls: *"The mayor is breathing down my neck. Wrap this up."*
- **On par + 5 (max_days):** *"Detective, I'm reassigning this case. Submit what you have — now."* Player must submit. This is the hard deadline.

The escalating pressure is narrative, not mechanical. The player always has freedom to choose when to submit (until the hard deadline).

---

## Replayability

The scoring system naturally encourages replaying cases:

1. **"I got Detective rank — can I get Senior Detective?"** Players replay to optimize their route.
2. **Different strategies.** Speed-focused vs evidence-focused vs balanced — each valid.
3. **Discovery.** On replay, players may find evidence they missed entirely the first time.
4. **Community.** Players compare ranks and strategies. "How did you get Chief Inspector on Day 3?"

### Replay Safeguards
- The game should track best rank per case
- Optional: show which evidence was missed in the case review screen (after submission)
- Optional: "detective notebook" that persists across plays, showing what the player has and hasn't found across all attempts

---

## Integration with Existing Systems

| Existing System | How Scoring Integrates |
|----------------|----------------------|
| **Prosecutor Confidence** | Becomes the Case Strength Score (0-50 points) |
| **Day System** | Days still structure the game, but the player can submit early |
| **Evidence System** | Critical evidence items contribute to case strength |
| **Timeline Reconstruction** | Timeline accuracy contributes to case strength |
| **Interrogation System** | Breaking suspects can unlock evidence faster (speed improvement) |
| **Warrant System** | Efficient warrant use saves actions/days |
| **Lab System** | Lab turnaround time is a hard constraint on par |

---

## Data Model Addition

Add to `case.json`:
```json
{
  "scoring": {
    "par_days": 3,
    "max_days": 8,
    "ranks": [
      { "name": "Chief Inspector", "min_score": 90, "description": "Flawless investigation" },
      { "name": "Senior Detective", "min_score": 75, "description": "Excellent work" },
      { "name": "Detective", "min_score": 60, "description": "Solid investigation" },
      { "name": "Junior Detective", "min_score": 45, "description": "Room for improvement" },
      { "name": "Cadet", "min_score": 30, "description": "The trial could go either way" },
      { "name": "Rookie", "min_score": 0, "description": "Back to the academy" }
    ],
    "speed_points_max": 50,
    "strength_points_max": 50,
    "minimum_submit_threshold": {
      "correct_suspect": true,
      "min_critical_evidence": 1,
      "min_motive_evidence": 1,
      "min_timeline_events": 3
    }
  }
}
```
