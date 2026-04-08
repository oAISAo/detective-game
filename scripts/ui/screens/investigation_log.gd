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

	# Refresh when new log entries arrive
	if GameManager.has_signal("log_entry_added"):
		GameManager.log_entry_added.connect(_populate_log)
	if GameManager.has_signal("investigation_log_changed"):
		GameManager.investigation_log_changed.connect(_populate_log)

	# Also refresh on common state changes that produce log entries
	if EvidenceManager.has_signal("evidence_discovered"):
		EvidenceManager.evidence_discovered.connect(func(_id: String) -> void: _populate_log())
	if DaySystem.has_signal("day_advanced"):
		DaySystem.day_advanced.connect(func(_day: int) -> void: _populate_log())


func _exit_tree() -> void:
	if GameManager.has_signal("log_entry_added") and GameManager.log_entry_added.is_connected(_populate_log):
		GameManager.log_entry_added.disconnect(_populate_log)
	if GameManager.has_signal("investigation_log_changed") and GameManager.investigation_log_changed.is_connected(_populate_log):
		GameManager.investigation_log_changed.disconnect(_populate_log)


## Populates the investigation log from GameManager.
func _populate_log() -> void:
	for child: Node in log_entries.get_children():
		log_entries.remove_child(child)
		child.queue_free()

	var entries: Array[Dictionary] = GameManager.get_investigation_log()
	if entries.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Investigation log is empty."
		empty_label.add_theme_color_override("font_color", UIColors.MUTED)
		log_entries.add_child(empty_label)
		return

	# Show newest entries first
	var reversed: Array[Dictionary] = entries.duplicate()
	reversed.reverse()

	for entry: Dictionary in reversed:
		var entry_panel: PanelContainer = PanelContainer.new()
		UIHelper.apply_surface_style(entry_panel)
		var entry_label: RichTextLabel = RichTextLabel.new()
		entry_label.bbcode_enabled = true
		entry_label.fit_content = true
		entry_label.custom_minimum_size = Vector2(0, 40)

		var day_text: String = "Day %d" % entry.get("day", 0)
		var slot_text: String = _format_phase(entry.get("phase", 0))
		var description_text: String = entry.get("description", "")

		entry_label.text = "[b]%s — %s[/b]\n%s" % [day_text, slot_text, description_text]
		entry_panel.add_child(entry_label)
		log_entries.add_child(entry_panel)


## Converts a DayPhase enum value to a display string.
func _format_phase(phase_value: Variant) -> String:
	if phase_value is String:
		return phase_value
	var phase_int: int = int(phase_value)
	match phase_int:
		Enums.DayPhase.MORNING:
			return "Morning"
		Enums.DayPhase.DAYTIME:
			return "Daytime"
		Enums.DayPhase.NIGHT:
			return "Night"
	return "Unknown"


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
