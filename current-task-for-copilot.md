We completed and manually tested the happy path for Mark Bennett’s interrogation, and I’ve now done a targeted QA pass.

Please do a **stability + persistence + automated test pass** on the interrogation system using Mark Bennett as the reference implementation.

This is a production-quality detective game, so I want this system hardened before we move on to other suspects.

## Important

Do **not** redesign the interrogation flow.
Do **not** simplify the system.
Do **not** add shortcuts or auto-solve behavior.

Keep the intended Mark Bennett flow exactly as designed and make it robust.

---

# QA Findings From Manual Testing

## 1) Bank transfer contradiction behavior appears correct

I tested this flow:

* Focused statement: **"We argued a little."**
* Presented evidence: **Suspicious Bank Transfer**
* Result:

  * pressure increased by +1
  * new topic unlocked: **"What happened to the missing money?"**
  * statement got marked as **CONTRADICTED**

This behavior is **correct and should be preserved**.

That statement is a minimization, and the financial evidence appropriately contradicts it.

---

## 2) Debug-style inline status text should only appear in Debug mode

I currently see dialogue/system text like this after successful confrontations:

`[Pressure Increased (+1) | New statement recorded | New topic: What happened to the missing money?]`

This is useful for development/debugging, but it should **not appear in normal gameplay**.

### Requirement:

* Keep this kind of detailed status text only in:

  * debug mode
  * debug presets / developer testing mode
* Hide it in normal player-facing mode

Please implement a clean gating mechanism for this.

---

## 3) Repeating already-used evidence should have better feedback

Current behavior:

* If I present the same valid evidence again after it already succeeded,
* it does **not** duplicate anything (good),
* but it shows a random generic rejection line like:

  * "He barely reacts to that."
  * "That doesn't seem to shake his story."

This is not ideal UX.

### Required fix:

If the player repeats an evidence confrontation that has **already been resolved**, show a specific resolved-state response instead, for example:

* **"He already addressed that."**

Use a distinct response path for:

* already-fired triggers
* already-resolved contradictions

This should be different from:

* wrong evidence
* wrong focus
* not enough progression

---

## 4) Apply Pressure tooltip behavior is fine

Current behavior:

* Apply Pressure is disabled at 0/2 and 1/2
* hover tooltip shows e.g.:

  * **"Need more pressure (1/2)"**

This is **good and should remain as-is**.

### Requirement:

* keep disabled hover tooltip behavior
* no need to add click feedback on disabled button

---

## 5) Correct evidence too early should NOT hint too much

I tested Hidden Safe too early:

* I had unlocked **"What happened to the missing money?"**
* pressure was only 1/2
* I challenged with Hidden Safe too early
* result was a generic rejection like:

  * "He barely reacts to that."

This behavior is **acceptable and should remain subtle**.

### Requirement:

Do not add overly explicit “almost there” hints.
Players should still have to reason about sequence and pressure.

You may improve wording slightly if needed, but do **not** make it easier or more explicit.

---

## 6) Save / Continue is broken and must be fixed

I tested persistence by:

* closing the game
* reopening it
* clicking **Continue**

Current result:

* 3 slots appeared
* slot 1 showed something like:

  * **"Day 1, 0 Evidence"**
* slots 2 and 3 were empty
* my actual progression was **not restored**

This is a major bug.

### Required fix:

Implement and verify proper persistence for at least:

* current day / time phase
* discovered evidence
* unlocked interrogations
* interrogation session progress
* unlocked topics
* statements
* pressure values
* used/fired interrogation triggers
* contradiction state
* story progression relevant to interrogation

### Also:

Please clearly define how **Continue** is supposed to work:

* if this is autosave, make it behave like autosave
* if this is save-slot based, make it consistent and fully functional

The current behavior is incomplete/broken.

---

## 7) Interrogation sometimes opens empty on first attempt after day progression

Bug found:

* I end the day
* next day I go to **Suspects**
* I click **Interrogate** next to Mark
* interrogation screen opens, but data is missing:

  * no suspect name
  * no topics
  * no statements
  * no evidence
  * only empty labels

If I go back and click **Interrogate** again, it works correctly.

This is a real initialization bug.

### Required fix:

Please investigate and fix the first-load initialization / binding issue so interrogation always opens correctly on first attempt.

Likely causes may include:

* scene initialization order
* state hydration timing
* selected suspect not bound before UI render
* deferred loading issue

Fix it properly, not with a hacky retry.

---

# Required Hardening Tasks

Please do all of the following:

## A) Interrogation behavior hardening

Verify/fix:

* wrong evidence does not fire
* correct evidence with wrong focus does not fire
* repeated valid evidence does not duplicate
* repeated valid evidence gives resolved-state feedback
* pressure increments only when intended
* Apply Pressure enables exactly at threshold
* Apply Pressure only works once
* final evidence cannot skip progression
* debug-only status text is hidden in normal gameplay

## B) Persistence hardening

Verify/fix:

* interrogation state saves correctly
* Continue restores actual progression
* save/load preserves:

  * statements
  * unlocked topics
  * pressure
  * fired triggers
  * contradiction markers
  * break state
  * suspect session progression

## C) UI initialization hardening

Verify/fix:

* interrogation screen always loads fully on first entry
* no empty-first-load bug after day transitions

---

# Automated GUT Tests Required

Please add or verify automated tests for at least the following:

## Interrogation core tests

* session initializes with correct initial dialogue, statements, and topics
* topic questioning adds expected follow-up statements
* wrong evidence does not fire trigger
* correct evidence with wrong focus does not fire trigger
* correct evidence with correct focus fires trigger
* each trigger fires only once
* repeated valid evidence uses resolved-state path
* pressure increments correctly
* Apply Pressure enables only at threshold
* Apply Pressure works only once
* final Hidden Safe evidence only works after correct progression

## Persistence tests

* save/load restores Mark interrogation session correctly
* Continue restores expected game progression state
* contradiction markers and unlocked topics persist

## Initialization tests

* interrogation screen/session data initializes correctly on first open
* opening after day progression still loads correct suspect/session data

---

# Deliverable

When complete, tell me:

1. what bugs were fixed
2. what persistence behavior was implemented/fixed
3. what automated tests were added
4. how I should manually verify the updated version

Do not move on to Sarah, Julia, or Lucas yet.
Stabilize Mark first and make this the gold-standard interrogation implementation.
