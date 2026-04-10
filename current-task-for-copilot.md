Problem 1 — Hover only works on the “empty border area”

This is expected behavior in Godot.

👉 Your root:

extends PanelContainer

👉 Your children (image, footer, etc.) are Controls that receive mouse input

So what happens:

Mouse over child → child handles it
Parent (LocationCard) does NOT receive mouse_entered

That’s why hover only triggers in the padding area.

✅ Fix (simple and correct)

Add this in _ready():

mouse_filter = Control.MOUSE_FILTER_PASS

AND for all major children:

_image_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
_footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
_gradient_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

👉 This lets the parent receive hover consistently

🔴 Problem 2 — “Why do we even need this extra box?”

You’re absolutely right to question this.

👉 Current structure:

PanelContainer (card)
  └── VBox (content)
        ├── Image
        ├── Gradient overlay
        └── Footer panel (extra container)
              └── Footer content

This is over-engineered.

💣 The real issue

You added the footer panel to:

get padding
get background
get rounded corners

But:
👉 The card already has rounded corners
👉 The gradient already handles visual separation

So now:

containers overlap
rounding conflicts
clipping issues appear
✅ Correct approach (what you should do)

👉 You do NOT need the extra footer panel at all.

✔ Simplify to this:
PanelContainer (card)
  └── VBox (content)
        ├── Image
        ├── Gradient overlay (on top of image)
        └── Footer (VBox)
              ├── Title
              ├── Description
              ├── Evidence
              └── Button
🔧 Replace _apply_footer_style() with this:
func _apply_footer_style() -> void:
	_footer.add_theme_constant_override("separation", 6)

	_footer.add_theme_constant_override("margin_left", FOOTER_PADDING_H)
	_footer.add_theme_constant_override("margin_right", FOOTER_PADDING_H)
	_footer.add_theme_constant_override("margin_top", FOOTER_PADDING_V)
	_footer.add_theme_constant_override("margin_bottom", FOOTER_PADDING_V)

👉 No reparenting
👉 No extra PanelContainer
👉 No clipping issues

🔴 Problem 3 — “Why don’t rounded corners work on the gradient/container?”

Because:

👉 Godot does NOT clip children to parent radius

So:

your card has rounded corners ✅
but children (gradient, footer) draw outside that shape ❌
✅ Proper fix (important)

On the root card:

clip_contents = true

👉 This forces:

gradient
image
footer

to respect the rounded corners

🔴 Problem 4 — Your margins are too big
_base_style.content_margin_left = 20
...

That’s why:

hover only works in that space (before fix)
layout feels “detached”
✅ Better values
= 12

or even:

= 10

You want:

tight composition
not floating UI blocks
🎯 What your final setup should be
Root card
clip_contents = true
mouse_filter = Control.MOUSE_FILTER_PASS
Remove completely
❌ footer_panel
❌ _footer.reparent(...)
❌ extra StyleBox for footer
Keep
✔ gradient overlay
✔ footer as simple VBox
✔ padding via constants
🧠 Key insight (this will save you hours later)

Right now you're designing like:

“I need another container to fix this visual problem”

But in Godot UI, that leads to:

stacking issues
clipping bugs
input bugs (like your hover issue)

👉 Instead think:

“Can I solve this with fewer layers?”

💬 My recommendation (important for your project)

You’re very close to a clean, scalable UI system, but:

remove unnecessary containers
let the card own the shape
let content just sit inside it

That’s how your design mockups are structured too.