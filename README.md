# Detective Investigation Game — Prototype

## Overview

This project is a prototype for a narrative-driven detective investigation game built with **Godot 4.x**.
The player takes the role of a detective solving a murder case through evidence collection, interrogation, timeline reconstruction, and logical deduction.

The core design philosophy is **player-driven reasoning**. The game does not solve the case for the player — instead it provides tools to organize evidence and test theories.

Players investigate locations, interrogate suspects, request forensic analysis, and eventually submit a full case report to the prosecutor.

---

## Current Development Status

The project is being developed in structured phases following a detailed development roadmap.

**Phase 0 — Project Setup** has been completed.

The project currently includes:

* Godot 4.x project structure
* Integrated unit testing using the GUT framework
* Initial repository structure
* Development environment configured for VSCode

Next phase: **Phase 1 — Data Architecture**

---

## Project Structure

```
project/
│
├── project.godot
├── README.md
│
├── scenes/        # Godot scenes (UI, locations, systems)
├── scripts/       # Game logic and systems
├── assets/        # Art, audio, and other media
├── data/          # Case data, evidence definitions, story configuration
├── tests/         # Unit tests using GUT
│
└── addons/
    └── gut/       # Godot Unit Test framework
```

---

## Development Environment

Recommended setup:

* **Godot 4.x**
* **VSCode** for script editing
* **GUT (Godot Unit Test)** for automated testing

Typical workflow:

1. Write scripts in VSCode
2. Open the project in Godot
3. Run the game or test suite
4. Debug and iterate

---

## Running the Project

1. Open **Godot 4.x**
2. In the Project Manager click **Import**
3. Select the project folder containing `project.godot`
4. Click **Import & Edit**

Once the project loads you can run the game using:

```
F5
```

---

## Running Tests

This project uses **GUT (Godot Unit Test)**.

To run tests:

1. Open the project in Godot
2. Open the **GUT Test Runner**
3. Execute the test suite

Command line execution may also be supported depending on configuration.

---

## Art & Asset Pipeline

During development the project uses **placeholder assets**.

Final visual assets will be generated later using AI tools such as Midjourney and then refined to ensure consistent style.

Asset creation will follow the project's **Visual Style Guide** to maintain a coherent detective / modern noir aesthetic.

---

## Planned Game Systems

Major gameplay systems include:

* Evidence discovery and management
* Suspect interrogation and evidence confrontation
* Detective board for organizing clues
* Timeline reconstruction
* Forensic lab analysis
* Surveillance and warrant mechanics
* Case report submission and prosecutor evaluation

---

## Project Goal

The goal of this prototype is to demonstrate a **deep investigative gameplay loop** where players solve a complex case through deduction rather than scripted choices.

The finished prototype will include:

* One fully playable murder case
* Multiple investigation paths
* Evidence-driven interrogation
* A final accusation and case evaluation system

---

## License

This project is currently a prototype and not yet licensed for distribution.

Further licensing information will be added before public release.
