---
name: godot-architecture
description: Master Godot Architecture
---

# Godot Architecture Skill

## Core Principles
- Strict separation: Data / Game Logic / UI
- UI never contains game logic
- Game logic never depends on UI

## Managers
- Use dedicated managers for core systems:
  - GameManager
  - LocationInvestigationManager
  - EvidenceManager
- Managers coordinate logic and state

## Communication
- Use signals for cross-system communication
- Avoid direct coupling between systems

## Scenes
- Each scene has a single responsibility
- Scenes should not contain complex logic

## Data-Driven Design
- Use JSON or Resources for data definitions
- Avoid hardcoding gameplay logic

## Anti-Patterns
- No god classes
- No UI-driven logic
- No hidden side effects