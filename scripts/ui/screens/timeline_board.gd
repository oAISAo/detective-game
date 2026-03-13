## TimelineBoard.gd
## Visual timeline of events, alibis, and key moments in the case.
## Phase 4A: Shell screen — full timeline interaction in later phases.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var timeline_scroll: ScrollContainer = %TimelineScroll
@onready var timeline_entries: VBoxContainer = %TimelineEntries
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_timeline()


## Populates the timeline from investigation log entries.
func _populate_timeline() -> void:
	for child: Node in timeline_entries.get_children():
		child.queue_free()

	var log_entries: Array[Dictionary] = GameManager.get_investigation_log()
	if log_entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No timeline events recorded yet."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		timeline_entries.add_child(empty_label)
		return

	for entry: Dictionary in log_entries:
		var entry_label: Label = Label.new()
		var day_text: String = "Day %d" % entry.get("day", 0)
		var action_text: String = entry.get("action", "Unknown")
		var detail_text: String = entry.get("detail", "")
		entry_label.text = "%s — %s: %s" % [day_text, action_text, detail_text]
		entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		timeline_entries.add_child(entry_label)


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
