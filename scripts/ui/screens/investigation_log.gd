## InvestigationLog.gd
## Scrollable log of all investigation actions taken by the player.
## Phase 4A: Shell screen — shows log from GameManager.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var log_scroll: ScrollContainer = %LogScroll
@onready var log_entries: VBoxContainer = %LogEntries
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_log()


## Populates the investigation log from GameManager.
func _populate_log() -> void:
	for child: Node in log_entries.get_children():
		child.queue_free()

	var entries: Array[Dictionary] = GameManager.get_investigation_log()
	if entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Investigation log is empty."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		log_entries.add_child(empty_label)
		return

	for entry: Dictionary in entries:
		var entry_panel: PanelContainer = PanelContainer.new()
		var entry_label: RichTextLabel = RichTextLabel.new()
		entry_label.bbcode_enabled = true
		entry_label.fit_content = true
		entry_label.custom_minimum_size = Vector2(0, 40)

		var day_text: String = "Day %d" % entry.get("day", 0)
		var slot_text: String = entry.get("time_slot", "")
		var action_text: String = entry.get("action", "")
		var detail_text: String = entry.get("detail", "")

		entry_label.text = "[b]%s — %s[/b]\n%s: %s" % [day_text, slot_text, action_text, detail_text]
		entry_panel.add_child(entry_label)
		log_entries.add_child(entry_panel)


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
