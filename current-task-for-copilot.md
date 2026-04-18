Copilot Prompt — New Action Button Redesign (Godot)

You are creating a new styling for the Action Button to match a new design. Apply this styling to

🎯 Goal

Transform the current button into a cinematic investigation action button with:

blue glowing border + shadow
split background with diagonal separator
left: action label
right: cost (“1 Action”) with hourglass icon
no old icons
clean, reusable structure


🔧 1. Base Structure (IMPORTANT — do NOT hack StyleBox for everything)

Refactor the button into layered structure:

ActionButton (PanelContainer or Button root)
├── Background (Control)  <-- custom drawing happens here
├── Content (HBoxContainer)
│   ├── Label_ActionText
│   ├── Spacer
│   ├── HBox_Right
│       ├── TextureRect_Hourglass
│       ├── Label_Cost
Use PanelContainer as root for styling flexibility
Do NOT rely only on StyleBoxFlat → we need custom drawing


🎨 2. Border + Glow (Blue Outline)

Replace existing style with:

StyleBoxFlat:
border_color: blue (we have it in ui_colors)
border_width: 1px
corner_radius: 14
bg_color: transparent or very dark

Add glow effect:
add a shadow (same as for selected List Button styling)


✂️ 3. Diagonal Split Background (KEY FEATURE)

Implement this using custom drawing in _draw() on the Background node.

Behavior:
Left side: slightly brighter blue/teal
Right side: darker desaturated blue
Diagonal cut from top middle → bottom right
Example logic:
func _draw():
    var w = size.x
    var h = size.y

    var left_color = Color(0.1, 0.25, 0.3)
    var right_color = Color(0.05, 0.1, 0.15)

    # Left polygon
    draw_polygon([
        Vector2(0, 0),
        Vector2(w * 0.6, 0),
        Vector2(w * 0.4, h),
        Vector2(0, h)
    ], [left_color])

    # Right polygon
    draw_polygon([
        Vector2(w * 0.6, 0),
        Vector2(w, 0),
        Vector2(w, h),
        Vector2(w * 0.4, h)
    ], [right_color])

Optional:
add subtle gradient or noise texture overlay for polish


⏳ 4. Hourglass Icon (Replace Dot)
Remove old dot icon completely
Add TextureRect before cost label
Use a simple minimal hourglass icon:
Size: ~14–18px
Add slight separation (margin_right: 6)


📝 5. Text Layout

Left:

"Visual Inspection" (unchanged)
aligned left
medium weight

Right:
"1 Action"
slightly dimmer color than main text
inline with icon

Spacing:
use HBoxContainer with size_flags_horizontal = EXPAND
push right content using spacer


🖱️ 6. Hover + Interaction

Hover state should:
slightly increase brightness of left background
slightly intensify border glow
optional: subtle upward lift (translate Y -1px)

DO NOT:
change layout
move text
add heavy animations


🎯 7. Reusability

Expose variables:

@export var action_text: String
@export var action_cost: int

Auto-update label:

Label_ActionText.text = action_text
Label_Cost.text = str(action_cost) + " Action"


⚠️ 8. Important Constraints
Must scale cleanly for different widths
No hardcoded pixel positioning
No clipping issues with rounded corners
Diagonal must adapt to size dynamically
Keep performance lightweight (no heavy shaders)


🎨 Design Intent Reminder

This button should feel:

investigative
cinematic
clean but slightly stylized
part of a serious detective interface, not a gamey UI