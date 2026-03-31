## TimelineBoard.gd
## Interactive timeline for reconstructing the sequence of events.
## Phase 9: Vertical timeline with event cards, hypotheses, and overlap warnings.
extends Control


# --- Node References --- #

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %TitleLabel
@onready var day_selector: OptionButton = %DaySelector
@onready var add_hypothesis_button: Button = %AddHypothesisButton
@onready var timeline_scroll: ScrollContainer = %TimelineScroll
@onready var timeline_container: VBoxContainer = %TimelineContainer
@onready var overlap_label: Label = %OverlapLabel
@onready var entry_count_label: Label = %EntryCountLabel


# --- Constants --- #

## Hour range shown on the timeline.
const START_HOUR: int = 6
const END_HOUR: int = 23

## Certainty level visual colors.
const CERTAINTY_COLORS: Dictionary = {
	"CONFIRMED": Color(0.35, 0.65, 0.45),
	"LIKELY": Color(0.45, 0.55, 0.65),
	"CLAIMED": Color(0.7, 0.6, 0.35),
	"UNKNOWN": Color(0.5, 0.48, 0.45, 0.6),
}

## Hypothesis card color.
const HYPOTHESIS_COLOR: Color = Color(0.6, 0.4, 0.65)


# --- State --- #

## Currently selected day (1-based).
var _current_day: int = 1


# --- Lifecycle --- #

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	add_hypothesis_button.pressed.connect(_on_add_hypothesis_pressed)
	day_selector.item_selected.connect(_on_day_selected)

	TimelineManager.entry_placed.connect(_on_timeline_changed)
	TimelineManager.entry_removed.connect(_on_entry_removed)
	TimelineManager.hypothesis_added.connect(_on_timeline_changed)
	TimelineManager.hypothesis_removed.connect(_on_entry_removed)
	TimelineManager.timeline_cleared.connect(_on_timeline_cleared)
	TimelineManager.state_loaded.connect(_rebuild_timeline)

	_setup_day_selector()
	_rebuild_timeline()


func _exit_tree() -> void:
	_safe_disconnect(TimelineManager.entry_placed, _on_timeline_changed)
	_safe_disconnect(TimelineManager.entry_removed, _on_entry_removed)
	_safe_disconnect(TimelineManager.hypothesis_added, _on_timeline_changed)
	_safe_disconnect(TimelineManager.hypothesis_removed, _on_entry_removed)
	_safe_disconnect(TimelineManager.timeline_cleared, _on_timeline_cleared)
	_safe_disconnect(TimelineManager.state_loaded, _rebuild_timeline)


func _safe_disconnect(sig: Signal, callable: Callable) -> void:
	if sig.is_connected(callable):
		sig.disconnect(callable)


# --- Day Selector --- #

func _setup_day_selector() -> void:
	day_selector.clear()
	var max_day: int = GameManager.current_day
	for d: int in range(1, max_day + 1):
		day_selector.add_item("Day %d" % d, d)
	day_selector.selected = 0
	_current_day = 1


func _on_day_selected(index: int) -> void:
	_current_day = index + 1
	_rebuild_timeline()


# --- Timeline Rebuild --- #

func _rebuild_timeline() -> void:
	_clear_timeline_ui()
	_build_hour_markers()
	_place_entry_cards()
	_place_hypothesis_cards()
	_update_overlap_warnings()
	_update_count_label()


func _clear_timeline_ui() -> void:
	for child: Node in timeline_container.get_children():
		child.queue_free()


func _build_hour_markers() -> void:
	for hour: int in range(START_HOUR, END_HOUR + 1):
		var marker: Label = Label.new()
		marker.text = "%02d:00 ────────────────────────────────" % hour
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_color", Color(0.55, 0.52, 0.48))
		timeline_container.add_child(marker)


func _place_entry_cards() -> void:
	var entries: Array[Dictionary] = TimelineManager.get_entries_for_day(_current_day)
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["time_minutes"] < b["time_minutes"]
	)
	for entry: Dictionary in entries:
		var card: PanelContainer = _create_entry_card(entry)
		_insert_card_at_time(card, entry["time_minutes"])


func _place_hypothesis_cards() -> void:
	var hypotheses: Array[Dictionary] = TimelineManager.get_all_hypotheses()
	for hyp: Dictionary in hypotheses:
		if hyp["day"] != _current_day:
			continue
		var card: PanelContainer = _create_hypothesis_card(hyp)
		_insert_card_at_time(card, hyp["time_minutes"])


## Inserts a card at the correct position based on time.
## Finds the hour marker for the card's hour and inserts after it and any
## existing cards for earlier times within the same hour bracket.
func _insert_card_at_time(card: PanelContainer, time_minutes: int) -> void:
	var card_hour: int = clampi(time_minutes / 60, START_HOUR, END_HOUR)
	var child_count: int = timeline_container.get_child_count()

	# Find the index of the hour marker for this card's hour
	var marker_index: int = -1
	for i: int in child_count:
		var child: Node = timeline_container.get_child(i)
		if child is Label:
			var label: Label = child as Label
			var label_text: String = label.text.strip_edges()
			if label_text.begins_with("%02d:00" % card_hour):
				marker_index = i
				break

	if marker_index == -1:
		# No matching marker found — append at end
		timeline_container.add_child(card)
		return

	# Find the next hour marker after this one to know our insertion boundary
	var next_marker_index: int = child_count
	for i: int in range(marker_index + 1, child_count):
		var child: Node = timeline_container.get_child(i)
		if child is Label:
			var label: Label = child as Label
			var label_text: String = label.text.strip_edges()
			if label_text.find(":00 ─") >= 0:
				next_marker_index = i
				break

	# Insert right before the next marker (i.e. at the end of this hour's block)
	timeline_container.add_child(card)
	timeline_container.move_child(card, next_marker_index)


# --- Entry Card Creation --- #

func _create_entry_card(entry: Dictionary) -> PanelContainer:
	var event: EventData = CaseManager.get_event(entry.get("event_id", ""))
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)

	var certainty_str: String = "UNKNOWN"
	if event:
		certainty_str = EnumHelper.enum_to_string(Enums.CertaintyLevel, event.certainty_level)
	_apply_certainty_style(panel, certainty_str)

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var time_label: Label = Label.new()
	time_label.text = "[%s] %s" % [
		TimelineManager.format_time(entry["time_minutes"]),
		event.description if event else "Unknown event",
	]
	time_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(time_label)

	var detail_label: Label = Label.new()
	var persons_text: String = _get_persons_text(event.involved_persons if event else [])
	detail_label.text = "Certainty: %s  |  %s" % [certainty_str, persons_text]
	detail_label.add_theme_font_size_override("font_size", 13)
	detail_label.add_theme_color_override("font_color", Color(0.65, 0.62, 0.58))
	vbox.add_child(detail_label)

	var attached: Array[String] = TimelineManager.get_attached_evidence(entry["id"])
	if not attached.is_empty():
		var ev_label: Label = Label.new()
		ev_label.text = "📎 Evidence: %s" % ", ".join(attached)
		ev_label.add_theme_font_size_override("font_size", 12)
		vbox.add_child(ev_label)

	var remove_btn: Button = Button.new()
	remove_btn.text = "✕"
	remove_btn.custom_minimum_size = Vector2(28, 28)
	remove_btn.pressed.connect(func() -> void: TimelineManager.remove_entry(entry["id"]))
	vbox.add_child(remove_btn)

	return panel


func _create_hypothesis_card(hyp: Dictionary) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 60)
	_apply_hypothesis_style(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	var time_label: Label = Label.new()
	time_label.text = "[%s] 💡 %s" % [
		TimelineManager.format_time(hyp["time_minutes"]),
		hyp.get("description", ""),
	]
	time_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(time_label)

	var persons_text: String = _get_persons_text(hyp.get("involved_persons", []))
	if not persons_text.is_empty():
		var detail_label: Label = Label.new()
		detail_label.text = "Hypothesis  |  %s" % persons_text
		detail_label.add_theme_font_size_override("font_size", 13)
		detail_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.75))
		vbox.add_child(detail_label)

	var remove_btn: Button = Button.new()
	remove_btn.text = "✕"
	remove_btn.custom_minimum_size = Vector2(28, 28)
	remove_btn.pressed.connect(func() -> void: TimelineManager.remove_hypothesis(hyp["id"]))
	vbox.add_child(remove_btn)

	return panel


# --- Card Styling --- #

func _apply_certainty_style(panel: PanelContainer, certainty: String) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = CERTAINTY_COLORS.get(certainty, CERTAINTY_COLORS["UNKNOWN"])
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	if certainty == "CLAIMED":
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.7, 0.6, 0.35)
	panel.add_theme_stylebox_override("panel", style)


func _apply_hypothesis_style(panel: PanelContainer) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = HYPOTHESIS_COLOR
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.3, 0.55)
	panel.add_theme_stylebox_override("panel", style)


# --- Helpers --- #

func _get_persons_text(person_ids: Array) -> String:
	var names: Array[String] = []
	for pid in person_ids:
		var person: PersonData = CaseManager.get_person(pid as String)
		if person:
			names.append(person.name)
		else:
			names.append(pid as String)
	return ", ".join(names) if not names.is_empty() else ""


# --- Overlap Warnings --- #

func _update_overlap_warnings() -> void:
	var overlaps: Array[Dictionary] = TimelineManager.get_overlaps(_current_day)
	if overlaps.is_empty():
		overlap_label.text = ""
		overlap_label.visible = false
		return

	overlap_label.visible = true
	var warnings: Array[String] = []
	for overlap: Dictionary in overlaps:
		var person: PersonData = CaseManager.get_person(overlap["person_id"])
		var name_str: String = person.name if person else overlap["person_id"]
		var time_str: String = TimelineManager.format_time(overlap["time_minutes"])
		warnings.append("⚠ %s appears in two places at %s" % [name_str, time_str])
	overlap_label.text = "\n".join(warnings)


func _update_count_label() -> void:
	entry_count_label.text = "%d entries · %d hypotheses" % [
		TimelineManager.get_entry_count(), TimelineManager.get_hypothesis_count()
	]


# --- Hypothesis Dialog --- #

func _on_add_hypothesis_pressed() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Add Hypothesis Event"

	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var desc_edit: LineEdit = LineEdit.new()
	desc_edit.placeholder_text = "What happened?"
	vbox.add_child(desc_edit)

	var time_edit: LineEdit = LineEdit.new()
	time_edit.placeholder_text = "Time (e.g. 20:30)"
	vbox.add_child(time_edit)

	var loc_edit: LineEdit = LineEdit.new()
	loc_edit.placeholder_text = "Location ID (optional)"
	vbox.add_child(loc_edit)

	var persons_edit: LineEdit = LineEdit.new()
	persons_edit.placeholder_text = "Person IDs (comma separated)"
	vbox.add_child(persons_edit)

	dialog.confirmed.connect(func() -> void:
		var time_min: int = TimelineManager.parse_time_string(time_edit.text)
		var persons: Array[String] = []
		for p: String in persons_edit.text.split(","):
			var trimmed: String = p.strip_edges()
			if not trimmed.is_empty():
				persons.append(trimmed)
		TimelineManager.add_hypothesis(desc_edit.text, time_min, _current_day, loc_edit.text, persons)
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())

	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 200))


# --- Signal Handlers --- #

func _on_timeline_changed(_data: Variant) -> void:
	_rebuild_timeline()


func _on_entry_removed(_id: String) -> void:
	_rebuild_timeline()


func _on_timeline_cleared() -> void:
	_rebuild_timeline()


func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
