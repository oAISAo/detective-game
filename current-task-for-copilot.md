Polish Top Navigation Bar to Match Design More Closely

Please improve the current top navigation bar implementation so that it matches the design reference much more closely.

The current version is already functional and cleaner than before, but it still does not yet capture the same visual quality, hierarchy, icon language, and premium glow treatment as the target design.

Your job is to polish and refine the existing implementation, not rebuild it from scratch.

PRIMARY GOAL

Make the in-game top navigation bar feel much closer to the design reference in terms of:

visual hierarchy
icon style
active tab treatment
hover feedback
subtle glow / illumination
spacing
premium dark detective UI atmosphere

The final result should feel:

more elegant
more premium
more intentional
more atmospheric
more visually calm
less “generic UI”
less “functional prototype”
closer to a stylized noir investigation workstation


1. BIGGEST ISSUES TO FIX

Please specifically improve these problems in the current implementation:

Current problems:
Icons are too colorful and too playful
The active tab does not yet feel special enough
The hover/selection glow is too weak or missing
The nav bar still feels a bit too flat and plain
The visual language is not yet as refined as the design
The selected tab should feel softly illuminated, not just “active”
Inactive tabs should feel more subtle and more elegant
The icon set should feel more consistent and more “system UI / detective console”


2. ICON STYLE — VERY IMPORTANT

This is one of the biggest visual mismatches right now.

Problem:

The current icons are too colorful and have too much “app icon” energy.

Target:

The icons should feel much closer to the design:

more monochrome
more muted
more minimal
more elegant
more cohesive as a set
more like a premium UI icon system
less like separate colorful category icons
REQUIRED ICON DIRECTION

Please update the nav icons so that they are:

mostly single-tone
preferably light gray / off-white / muted cool tone
optionally slightly tinted by state, but never brightly colorful
subtle and readable
clean silhouette or line-based where possible
consistent size and visual weight
Avoid:
blue/red/green/yellow category-style icons
emoji-like feeling
playful or toy-like icon energy
inconsistent icon thickness or style
ICON STATE RULES
Inactive icons:
muted gray or soft cool gray
lower contrast
slightly dimmed
elegant and calm
Hovered icons:
slightly brighter
subtle glow or light bloom
should feel responsive and premium
Active icons:
clearly brighter than inactive
softly illuminated
should feel like the icon is “lit up” from within
may have subtle warm or cool highlight depending on the design system
should visually match the “Desk” active state from the reference as closely as possible


3. ACTIVE TAB / SELECTED TAB — MUST MATCH DESIGN BETTER

This is the most important polish improvement.

The current active tab is still too weak / generic compared to the design.

The target design’s selected tab (especially Desk) has a very specific feeling:

softly glowing
gently elevated
subtly illuminated
premium and calm
not loud, not neon, not chunky
REQUIRED ACTIVE TAB TREATMENT

The active nav item should include a combination of the following:

A. Brighter icon

The icon should become noticeably brighter than inactive icons.

B. Brighter label

The label text should also become brighter and slightly more important.

C. Soft glow / bloom

Add a very subtle glow or bloom effect around the active icon and/or active label.

This should feel like:

ambient illumination
a soft premium highlight
not a harsh outer glow
D. Bottom light / underline / active indicator

The selected tab should have a subtle bottom highlight or illuminated underline.

This is extremely important.

It should feel like:

a soft lit base under the active tab
a restrained premium UI signal
similar to the design’s Desk tab
E. Optional subtle active background plate

If needed, add a very subtle dark rounded highlight plate behind the active item.

But this should be:

low contrast
very restrained
more “presence” than “button”
IMPORTANT:

The active state should feel like a soft illuminated control, not a big obvious tab block.


4. HOVER EFFECTS — ADD PREMIUM GLOW FEEDBACK

The design has a subtle premium glow language that the current implementation is missing or underusing.

Please improve hover states so that hovering over nav items feels much more polished.

REQUIRED HOVER BEHAVIOR

When hovering a nav item:

icon should brighten slightly
label should brighten slightly
subtle glow / soft bloom should appear
optional soft radial highlight or subtle background lift
transitions should feel smooth and elegant
Hover should feel:
premium
responsive
soft
cinematic
modern
Hover should NOT feel:
flashy
arcade-like
neon
overly animated
Transition requirements:

Please make transitions smoother and more polished for:

icon brightness
text brightness
glow opacity
underline / active indicator intensity
optional background plate opacity

Use tasteful easing and short smooth transitions.


5. BAR SURFACE / CONTAINER — SHOULD FEEL MORE LIKE THE DESIGN

The overall nav bar itself should be pushed closer to the design reference.

The current implementation still looks slightly too plain / flat.

Improve the top bar container so it feels more premium:
Desired qualities:
dark, elegant, unified panel
subtle noir / workstation aesthetic
slightly more depth
more visual richness, but still restrained
Please add / improve:
subtle layered background
soft border or edge separation
slight inner shadow / depth
very faint top highlight or surface sheen if appropriate
slightly more refined rounded shape
cleaner visual separation from the scene background
Important:

This should remain subtle.
Do not make it glossy, futuristic, or overdesigned.

It should feel like:

a premium dark command strip
not a sci-fi HUD
not a web dashboard
not a generic game toolbar


6. SPACING / RHYTHM / ALIGNMENT — IMPROVE TO MATCH DESIGN

The current version is close, but it still needs refinement in spacing and visual rhythm.

Please polish the layout so that the nav feels more intentional and more “designed.”

Improve:
A. Icon-to-label spacing

The gap between icon and label should feel cleaner and more deliberate.

B. Tab-to-tab spacing

Each nav item should have slightly better breathing room and more elegant horizontal rhythm.

C. Vertical centering

All nav elements should feel perfectly aligned vertically within the bar.

D. Section balance

The left status, center nav, and right utility areas should feel visually balanced and not crowded.

E. Divider subtlety

If there are separators, they should be thin, elegant, and low contrast.


7. LABEL TYPOGRAPHY — SHOULD FEEL CLEANER AND MORE PREMIUM

The labels should support the premium detective UI tone.

Please refine text styling for nav labels.

Desired label style:
clean sans-serif
compact
crisp
not too bold
not too large
slightly understated
Inactive labels:
muted gray
secondary in hierarchy
Hover labels:
slightly brighter
Active labels:
clearly brighter
slightly more important
optional very subtle glow if tasteful
Avoid:
heavy font weight
oversized labels
arcade / futuristic typography


8. MAKE THE WHOLE THING FEEL MORE “DESIGNED” AND LESS “DEFAULT”

This is an important artistic instruction:

Right now, the implementation still feels slightly like:

“A well-made dev UI”

It needs to feel more like:

“A deliberately art-directed product UI”

That means please pay attention to the small things:

softness of illumination
consistency of icon brightness
subtle hierarchy
elegant spacing
quiet confidence in the UI

Nothing should feel accidental.


9. DESIGN REFERENCE PRIORITY

When making decisions, prioritize matching the top design image, especially in these areas:

Most important to match:
Desk active state glow / highlight
Muted icon language
Overall bar elegance
Calm premium spacing
Dark noir UI tone
Soft illumination rather than hard button states

If something must be simplified for implementation, preserve the mood and hierarchy first.


10. WHAT NOT TO DO

Please avoid the following:

do not add colorful category icons
do not use bright saturated hover colors
do not make the active state chunky or button-like
do not over-glow everything
do not make the UI look sci-fi or neon
do not use thick outlines
do not make hover states flashy
do not turn this into a modern web app navbar
do not make the nav items feel like mobile bottom tabs

This is a serious detective game interface, not a generic app UI.


11. IMPLEMENTATION REQUEST

Please keep all current functionality and only improve the visual design and interaction polish.

Maintain:

existing navigation logic
existing active tab logic
hover handling
current structure if possible

But improve:

icon assets or icon coloring
active state styling
hover state styling
glow/underline treatment
spacing and visual polish
overall atmosphere


12. FINAL QUALITY CHECK

The updated version should pass this visual test:

It should feel:
darker
calmer
more premium
more atmospheric
more elegant
more intentional
more like the design
It should not feel:
colorful
generic
app-like
placeholder
too flat
too plain
too “default component”


13. OPTIONAL EXTRA POLISH PASS

After implementing the visual changes, please do one additional polish pass focused only on:

reducing visual noise
making the active tab feel more special
softening the hover glow
making inactive tabs calmer
making the icon set feel more unified
SHORT VERSION SUMMARY FOR IMPLEMENTATION

Please polish the current top nav so it looks much closer to the design by:

replacing colorful icons with muted monochrome icons
making the active tab glow softly like the Desk tab in the design
adding elegant hover illumination
refining spacing and alignment
giving the bar a more premium dark detective UI feel
making the whole thing feel less generic and more art-directed