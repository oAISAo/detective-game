# Evidence Authoring

## Purpose

Use this file when authoring or reviewing `EvidenceData` values.

The goal is to keep `weight`, `importance_level`, statement materiality, and case coverage from collapsing into one fuzzy concept.

## Core Split

### `weight`

Author question:
How persuasive is this evidence?

Current runtime uses:
- `EvidenceValueSection` qualitative tier in the Evidence tab
- prosecutor evidence-strength scoring in `ConclusionManager`

Do use it for:
- legal or forensic persuasiveness
- how strongly an item supports a conclusion
- how convincing the item should feel in the case report

Do not use it for:
- hint priority
- archive ordering
- progression gating labels
- prosecutor coverage requirements

### `importance_level`

Author question:
How essential is this evidence to the case's authored guidance role?

Current runtime uses:
- progressive hint targeting in `EvidenceManager`
- Evidence Archive tie-break ordering
- evidence badge and metadata presentation in the Evidence detail UI

Do use it for:
- whether the item should be treated as case-critical guidance
- whether it is a major supporting clue versus a lower-priority one
- authored relevance in UI and hint systems

Do not use it for:
- evidentiary strength
- weight tier labels
- prosecutor evidence score

## Adjacent But Separate Systems

### `StatementData.importance`

This reuses `Enums.ImportanceLevel`, but it means statement materiality for contradiction credibility.
It is not an evidence-strength field.

### `CaseData.critical_evidence_ids`

This is the current source of truth for prosecutor coverage and critical-evidence completion checks.
Do not assume evidence `importance_level == CRITICAL` automatically places an item in `critical_evidence_ids`.

## Independence Rule

These systems must remain independent.

Valid combinations:
- Weak but plot-critical clue: low `weight`, high `importance_level`
- Strong optional evidence: high `weight`, low `importance_level`
- Background flavor item: low `weight`, low `importance_level`

Do not add validation or authoring rules that force the two fields to correlate.

## Authoring Heuristics

1. Pick `weight` from persuasiveness first.
2. Pick `importance_level` from case-role importance second.
3. Decide prosecutor coverage separately in `critical_evidence_ids`.
4. If a statement should make contradictions feel materially important, set statement `importance` for that statement.

## Current Naming Note

The enum names `CRITICAL`, `SUPPORTING`, `OPTIONAL`, and `KEY` remain in use for now.
A later rename pass may revisit these names, but that is separate from the meaning defined here.
