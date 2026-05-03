# Evidence Tab — Right Panel Design Ideas

## Goal

The right panel should feel like the natural companion to the finished Map and Location Investigation screens: elegant, tactile, readable, and clearly part of the same game UI language.

The goal is not to make it flashy. The goal is to make it feel like a curated detective workspace that helps the player read, compare, and classify evidence without turning into a generic data app.

## Shared Requirements

Any final layout should support these elements and states without feeling crowded:

- Evidence title
- Importance badge
- Evidence type badge
- Legal category badges
- Pin toggle
- Board / View on Board button
- Evidence image or placeholder
- Evidence ID + day discovered strip
- Description block
- Metadata grid: Location, Discovery, Day Found, Lab Status
- Evidentiary weight bar + prose label
- Tags section
- Compare Evidence button
- Lab submission section for raw evidence
- Related persons list
- Statements list
- Verdict pill per statement
- Expand / notes area per statement
- Player notes section for the evidence item
- Empty state when nothing is selected
- No-image state
- No-statements state
- No-related-persons state
- Raw evidence pending lab state
- Lab complete state
- Superseded raw evidence state
- Sent to board state
- Compare selector overlay state
- Narrow-width / condensed responsive state

The right panel should not invent new content. It should present the existing evidence data in a cleaner hierarchy.

## Visual Direction To Keep

The finished location screens already suggest a strong language:

- Dark, grounded surfaces
- Cream / paper / dossier accents instead of bright white panels
- Photo-card or file-folder framing
- Strong title hierarchy
- Clear sidebars for supporting information
- Tactile depth with soft shadows and restrained borders
- Functional, not decorative, motion

The Evidence right panel should echo that language, but feel more refined and more “editorial file” than “inspection tool.”

## Variation 1: Classic Dossier Split

This is the safest and most direct evolution of the current layout.

### Structure

- Keep a strong header at the top.
- Keep a large main content column on the left.
- Keep a narrow support column on the right.
- Make the right column feel like a clipped insert or side sleeve in a paper file.

### Main Column

- Large evidence image at the top.
- Thin caption strip under the image with evidence ID and discovery day.
- Description below that in a clean, readable block.
- Metadata grid under the description.
- Weight bar next, with the prose label below it.
- Tags after the weight.
- Compare button and lab section at the bottom as the action zone.
- Player notes tucked into a separated lower card or folded-paper panel so it feels private.

### Side Column

- Related persons at the top.
- Statements below, in a scrollable list.
- Each statement row stays compact and avoids taking over the whole panel.
- Verdict pill remains immediately visible.
- Expanding a statement should reveal the note field inline under that row.

### Why This Works

- Closest to the current implementation.
- Easiest to read on a mid-size desktop viewport.
- Keeps all evidence-reading content visible at once.
- Fits the same “3-column information hierarchy” language already used in the location investigation screen.

### Risks

- Could still feel a little utilitarian if the styling is not elevated.
- Might become dense when there are many statements.
- The bottom action area may start to compete with the weight bar and notes.

### Best Use Case

- If the goal is to preserve the current structure but make it much more elegant.

## Variation 2: Investigation Sheet With Sticky Actions

This version tries to make the panel feel more like a working forensic worksheet.

### Structure

- Header stays sticky.
- Image and core facts appear as the first sheet.
- The main content reads top-to-bottom like a case sheet.
- The support column becomes a persistent evidence analysis rail.

### Main Column

- Image card at the top with a stronger frame, like a pinned exhibit photo.
- Title, badges, and pin/board controls feel anchored to the same top band.
- Description and metadata are grouped as a single “Evidence Facts” sheet.
- Weight bar becomes a prominent horizontal band with a short assessment line.
- Tags are presented as small evidence chips on a textured strip.
- Lab submission, compare evidence, and player notes are each their own distinct section card.

### Side Column

- The related persons list sits in a compact top rail.
- The statements area becomes the main analysis rail.
- Statement cards are slightly more vertical and can open like stacked note slips.
- Verdict controls are treated like analyst stamps or classification chips.

### Why This Works

- Feels more active and more investigative than a plain panel.
- Better for the core fantasy of “analysis workspace.”
- Gives room for visual distinction between case facts and player interpretation.
- Could make lab and compare actions feel like meaningful procedural steps.

### Risks

- More stylized and slightly more complex to design well.
- Needs careful spacing so it does not feel busy.
- If overdone, it could drift away from the more restrained location screen aesthetic.

### Best Use Case

- If the right panel should feel more like a detective’s desk than a dossier page.

## Variation 3: Editorial Evidence Page

This option leans most strongly into elegance and cohesion.

### Structure

- The panel reads like a premium magazine spread or archival report page.
- Strong top title band.
- Image, description, and facts are arranged in clear visual chapters.
- The side content is treated as a narrow editorial sidebar.

### Main Column

- Large hero image or placeholder at the top with generous breathing room.
- The title and badges sit above or slightly overlapping the hero area in a refined header cluster.
- Description is presented like an evidence summary paragraph.
- Metadata becomes a two-column fact table with more whitespace and stronger typography.
- Weight bar is visually elegant, almost like a meter in a report.
- Tags look like labeled archival tabs.
- Compare and lab actions are treated as prominent call-to-action buttons rather than utility buttons.
- Notes feel like margin annotations or handwritten addenda.

### Side Column

- Related persons are small identity chips or portrait circles with role labels.
- Statements are arranged like cited quotes in an article.
- Verdict pills are restrained but clear, like editorial markers.

### Why This Works

- Most elegant option.
- Likely the best match if the finished Map and Location Investigation screens already feel polished and cinematic.
- Strongest opportunity to make the Evidence tab feel premium rather than purely functional.

### Risks

- Requires discipline so it does not become too pretty and lose clarity.
- Could underplay the “tool” aspect of statement classification if the analysis controls are not strong enough.
- Needs a very clear responsive fallback for narrow widths.

### Best Use Case

- If we want the Evidence panel to feel like the most polished screen in the game.

## Variation 4: Hybrid With Strong Information Blocks

This is a compromise between the dossier layout and the editorial layout.

### Structure

- Header band at the top.
- Hero image card under the header.
- Then a strong “facts” block, a “analysis” block, and a “player actions” block.
- The side column remains present, but each section gets clear borders and breathing room.

### Section Order

1. Header and controls
2. Hero image / placeholder
3. Description
4. Facts grid
5. Weight bar
6. Tags
7. Lab / compare / board actions
8. Evidence notes
9. Related persons
10. Statements

### Why This Works

- Very easy to scan.
- Each subsection has a clear purpose.
- Lets the design team tune visual weight without changing the information model.
- Good choice if the team wants the most implementation-safe version.

### Risks

- Can become boxy if every section gets the same visual treatment.
- Needs careful typographic hierarchy to avoid looking like a form.

### Best Use Case

- If we want a balanced and pragmatic layout with strong readability.

## Recommended Design Principles

No matter which variation we choose, the final layout should probably follow these principles:

- The image area should feel like the hero of the panel.
- The title and classification badges should be immediately readable.
- Case facts should be visually distinct from player notes.
- Statements should be easy to scan line by line.
- Verdict controls should feel like deliberate analytical actions.
- The lab and compare actions should be prominent but not overpower the panel.
- Related persons should act as supporting context, not compete with the statements.
- The panel should remain elegant even when the content is long.
- The responsive version should preserve the hierarchy, not just shrink everything.

## Unclear Or Open Questions

- Should the right panel have a truly sticky header, or should only the title/badges remain sticky while the rest scrolls?
- Should the image area always be visible, or should it collapse on shorter screens?
- Do we want the side column to remain fixed width, or should it flex more aggressively with the viewport?
- Should player notes live at the bottom of the main column, or be separated into a dedicated lower sheet?
- Should the lab section appear above the compare button, below it, or replace part of the lower action zone when raw evidence is selected?
- Should statements be grouped by person or shown in strict data order?
- Should the verdict pill be a compact label, a colored chip, or a stronger button-like control?
- How visual should the “sent to board” state be? A simple button change, or a more obvious status banner?
- Should superseded raw evidence get a muted banner in the right panel, or should that be handled only in the archive card?
- Do we want the compare selector to slide over the panel, or to replace the panel content temporarily?
- On narrow screens, should the side column stack under the main content, or should it become tabs/accordion sections?

## Decision Notes For The AI

If the design AI can only produce one concept, the safest target is Variation 1 with the elegance cues from Variation 3.

If the design AI can produce several, the most useful set would be:

- Version A: Classic Dossier Split
- Version B: Editorial Evidence Page
- Version C: Hybrid With Strong Information Blocks

That gives us one conservative option, one premium option, and one practical middle-ground option.
