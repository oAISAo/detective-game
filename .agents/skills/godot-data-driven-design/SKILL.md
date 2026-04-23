---
name: godot-data-driven-design
description: Master Godot Data-Driven Design
---

# Godot Data-Driven Design Skill

## Principle
Game behavior should be defined by data, not hardcoded logic.

## Data Sources
- JSON files for static data
- Resources for structured data

## Flow
Data → Loaded → Parsed → Used by systems

## Rules
- Do not hardcode:
  - evidence logic
  - location behavior
  - unlock conditions

- Use IDs instead of direct references

## Validation
- Validate data on load
- Fail early on invalid data

## Extensibility
- New content should not require code changes

## Example
- Locations define:
  - targets
  - evidence results
  - conditions

Systems interpret data — they do not define it.