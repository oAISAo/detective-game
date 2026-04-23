---
name: godot-testing-gut
description: Master Godot Testing (GUT)
---

# Godot Testing (GUT) Skill

## Framework
- Use GUT for all tests
- Tests live in /tests

## Structure
- One test file per system
- Name: test_<system_name>.gd

## Rules
- Test behavior, not implementation
- Avoid testing private methods directly

## Common Patterns
- Use setup() for initialization
- Use doubles/mocks for dependencies
- Test signals using yield/await patterns

## Coverage
- Normal cases
- Edge cases
- Invalid input

## Bug Fixes
- Always write a failing test first
- Then implement the fix

## Anti-Patterns
- No reliance on real scene tree when avoidable
- No flaky async tests