# Evidence Tab — TODOs

This file tracks features that are **designed in `evidence-concept.md` but not yet implemented** in the codebase. Grouped by area. Verified against actual code on 2026-04-28.

Legend: `🚧 not started` · `🔧 partial` · `✅ done`

---

## UI — Evidence Cards (Polaroid)

- 🚧 **NEW badge** (blue) on `EvidencePolaroid` card — requires `reviewed` state tracking; `EvidencePolaroid` currently shows no state badges at all
- 🚧 **LAB badge** (amber) on `EvidencePolaroid` card — `EvidencePolaroid.setup()` does not read `lab_status` or check `LabManager.is_evidence_submitted()`
- 🚧 **PINNED dot** (small amber dot) on `EvidencePolaroid` card — `EvidencePolaroid` does not check `EvidenceManager.is_pinned()`
- 🚧 **Card sort order**: NEW items float to top; within same discovery day, sort by importance (CRITICAL before SUPPORTING before OPTIONAL). Discovery day is now runtime state from `GameManager.get_evidence_discovery_day(id)` — discovery order fallback = insertion order in `GameManager.discovered_evidence`. Currently returns insertion order with no sorting.

---

## UI — Evidence Detail Header

- 🚧 **Evidence ID label** in detail header (e.g., `E-14 · Parking Lot Camera Footage`) — currently only the title (`detail_title`) is shown, no ID prefix
- 🚧 **Importance badge** (`CRITICAL` / `SUPPORTING` / `NOISE`) in the header badges row
- 🚧 **Type badge** in the header badges row
- 🚧 **Legal Category badge(s)** in the header badges row — currently legal categories are rendered in a separate `LegalCategoriesList` section below, not in the header

---

## UI — Evidentiary Weight Bar

- 🚧 **Visual progress bar** for `weight` — currently only shows `"70%"` as plain text inside the `InfoGrid`; no bar, no color
- 🚧 **Color logic**: amber (default) → red if `EvidenceManager.is_contradicted(evidence_id)` → teal (if linked to a strong confirmed theory, not yet implemented). Red rule: at least one linked statement has a player CONTRADICTION verdict AND `statement.importance <= ImportanceLevel.SUPPORTING` (i.e. CRITICAL or SUPPORTING importance, not OPTIONAL). Method is implemented in `EvidenceManager.is_contradicted()`; the weight bar visual itself is still 🚧.
- 🚧 **Prose label** below the bar based on weight threshold:
  | Weight | Prose |
  |--------|-------|
  | 85–100% | Airtight. Will convict on its own. |
  | 65–84% | Strong. Holds up under cross-examination. |
  | 40–64% | Corroborating. Strengthens the case when combined with other evidence. |
  | 20–39% | Weak. Circumstantial — the defense will challenge this. |
  | 1–19% | Marginal. Context only. |

---

## UI — Player Notes & Custom Tags

- 🚧 **Per-evidence notes field**: a toggle icon near the bottom of the detail panel reveals a free-text area styled with the handwriting font (`Caveat-Regular.ttf`). Notes are the player's private thoughts, not surfaced in the Prosecutor evaluation.
- 🚧 **Custom tag input**: a small text input to add player-defined tags per evidence item
- 🚧 **State persistence**: both `player_notes` and `player_tags` need to be stored and serialized in `EvidenceManager`

---

## UI — Statements Panel

- 🚧 **Statement expand toggle**: clicking a statement row reveals a per-statement analysis note text field (`StatementVerdictData.player_note` exists in the data model but has no UI yet)
- 🚧 **Per-statement player note field**: free text tied to `StatementVerdictData.player_note`, displayed on expand
- 🚧 **Pen icon ("player-tagged" indicator)** on manually linked statements — distinguishes player-created links from data-driven links (Decision D2)
- 🚧 **"+ Link Statement" button**: lets the player search all unlocked statements and manually attach one to the current evidence item; stores the link in `EvidenceManager` state
- 🚧 **Verdict dropdown popup**: the concept calls for a small dropdown (Contradiction / Supports / Unresolved / Remove link); currently implemented as a click-to-cycle button on `StatementItem`
- 🚧 **"Remove link" option**: hides a manually linked statement from the evidence item (data-driven links should not be fully removable, only set to `unresolved`)

---

## UI — Evidence States

- 🚧 **`reviewed` state tracking**: mark an evidence item as reviewed the first time its detail panel is opened; this clears the NEW badge and decrements the nav badge count
- 🚧 **`sent_to_board` state tracking per evidence item**: currently the `SendToBoardButton` is disabled and shows "Sent to Board" only for the current session — it resets when the detail panel is reloaded; needs to persist via `EvidenceManager`
- 🚧 **"View on Board" button state**: when `sent_to_board` is true, the button should change to "View on Board" and navigate to the Board tab
- 🚧 **"Superseded by lab result" visual** on raw evidence (Decision D5): once the lab result evidence item is discovered, the raw item (`ev_*_raw`) gets a muted appearance and a "→ See [result name]" link in its detail panel. The item is never removed from the archive.

---

## UI — Navigation & Notifications

- 🚧 **Evidence tab nav icon badge**: shows count of unreviewed (NEW) items — requires `reviewed` tracking to be implemented first (Decision D6)
- 🚧 **Evidence discovery notification popup**: fires when a new evidence item is added to the archive; shows evidence name, one-line description, and a "View" shortcut button that navigates directly to the evidence detail via `ScreenManager.navigate_to("evidence_archive", {evidence_id: id})`
- 🔧 **Lab result notification popup at morning phase**: `LabManager` fires `lab_completed` signal; verify that `NotificationManager` correctly picks this up and fires a player-visible toast with the result evidence name

---

## Data / Logic — EvidenceManager

- 🚧 **`reviewed` per-evidence field**: add to `EvidenceManager` state dict; serialize/deserialize; emit `evidence_reviewed` signal on first open
- 🚧 **`sent_to_board` per-evidence field**: add to `EvidenceManager` state dict; serialize/deserialize; set when `BoardManager.send_to_board()` is called
- 🚧 **`player_notes` per-evidence field**: add to `EvidenceManager` state dict; serialize/deserialize
- 🚧 **`player_tags` per-evidence field**: add to `EvidenceManager` state dict; serialize/deserialize
- 🚧 **`link_statement_manually(evidence_id, statement_id)`**: method on `EvidenceManager` to store a player-created statement link; stored separately from `EvidenceData.linked_statements` (which is read-only case data); the manually linked list also needs to be serialized

---

## Data / Logic — Signals

- 🚧 **`evidence_reviewed` signal** on `EvidenceManager`: emitted the first time a specific evidence item's detail panel is opened
- 🚧 **`evidence_sent_to_board` signal** on `EvidenceManager` (or `BoardManager`): emitted when evidence is sent to the board; currently only `BoardManager.node_added` fires

---

## Data / Logic — Board Integration

- 🚧 **Board inbox zone**: define default `(x, y)` coordinates for auto-placement when `BoardManager.send_to_board("evidence", id)` is called (Decision D3); currently the method places at a hardcoded or zero position

---

