## CaseSelectionScreen.gd
## Displays available cases and lets the player select one to start a new game.
## Scans the data/cases/ directory for case folders with valid case.json files.
extends Control


## Emitted when the player selects a case to play.
signal case_selected(case_folder: String)

## Emitted when the player presses the back button.
signal back_requested


@onready var case_list_container: VBoxContainer = %CaseListContainer
@onready var back_button: Button = %BackButton
@onready var case_title_label: Label = %CaseTitleLabel
@onready var case_description_label: RichTextLabel = %CaseDescriptionLabel
@onready var start_case_button: Button = %StartCaseButton


## Cached case metadata: [{ folder, title, description }]
var _cases: Array[Dictionary] = []

## Currently selected case folder name.
var _selected_case: String = ""


func _ready() -> void:
	back_button.pressed.connect(func() -> void: back_requested.emit())
	start_case_button.pressed.connect(_on_start_case_pressed)
	start_case_button.disabled = true

	_scan_cases()
	_build_case_list()


## Scans res://data/cases/ for folders containing case.json files.
func _scan_cases() -> void:
	_cases.clear()
	var cases_path: String = "res://data/cases/"
	var dir: DirAccess = DirAccess.open(cases_path)

	if dir == null:
		push_error("[CaseSelection] Cannot open cases directory: %s" % cases_path)
		return

	dir.list_dir_begin()
	var folder_name: String = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var case_json_path: String = cases_path + folder_name + "/case.json"
			var metadata: Dictionary = _read_case_metadata(case_json_path)
			if not metadata.is_empty():
				metadata["folder"] = folder_name
				_cases.append(metadata)
		folder_name = dir.get_next()
	dir.list_dir_end()

	_cases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.get("title", "") < b.get("title", "")
	)


## Reads basic metadata from a case.json file.
func _read_case_metadata(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		return {}

	var data: Dictionary = json.data
	return {
		"title": data.get("title", "Unknown Case"),
		"description": data.get("description", "No description available."),
	}


## Creates a button for each discovered case.
func _build_case_list() -> void:
	for child: Node in case_list_container.get_children():
		child.queue_free()

	if _cases.is_empty():
		var label: Label = Label.new()
		label.text = "No cases found."
		case_list_container.add_child(label)
		return

	for case_info: Dictionary in _cases:
		var btn: Button = Button.new()
		btn.text = case_info.get("title", "Unknown")
		btn.custom_minimum_size = Vector2(0, 48)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var folder: String = case_info.get("folder", "")
		btn.pressed.connect(func() -> void: _on_case_button_pressed(folder))
		case_list_container.add_child(btn)

	# Auto-select the first case if only one exists
	if _cases.size() == 1:
		_select_case(_cases[0].get("folder", ""))


func _on_case_button_pressed(folder: String) -> void:
	_select_case(folder)


func _select_case(folder: String) -> void:
	_selected_case = folder

	var case_info: Dictionary = {}
	for c: Dictionary in _cases:
		if c.get("folder", "") == folder:
			case_info = c
			break

	case_title_label.text = case_info.get("title", "Unknown Case")
	case_description_label.text = case_info.get("description", "")
	start_case_button.disabled = false

	# Highlight the selected button
	for child: Node in case_list_container.get_children():
		if child is Button:
			child.disabled = false
	for child: Node in case_list_container.get_children():
		if child is Button and child.text == case_info.get("title", ""):
			child.disabled = true


func _on_start_case_pressed() -> void:
	if _selected_case.is_empty():
		return
	case_selected.emit(_selected_case)
