## TitleScreen.gd
## Main menu screen with New Game, Continue, Settings, and Quit buttons.
## Displayed when the game starts. Manages navigation to case selection or save loading.
extends Control


## Emitted when the player requests to start a new game (case selection).
signal new_game_requested

## Emitted when the player selects continue with a specific save slot.
signal continue_requested(slot: int)

## Emitted when the player requests a debug game with a preset file.
signal debug_game_requested(preset_filename: String)


@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var debug_game_button: Button = %DebugGameButton
@onready var save_slots_container: VBoxContainer = %SaveSlotsContainer


var _showing_save_slots: bool = false


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	debug_game_button.pressed.connect(_on_debug_game_pressed)

	save_slots_container.visible = false
	_update_continue_button()
	_update_debug_button()


## Checks whether any save slot has data and enables/disables Continue.
func _update_continue_button() -> void:
	var has_any_save: bool = false
	for slot: int in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		if SaveManager.has_save(slot):
			has_any_save = true
			break
	continue_button.disabled = not has_any_save


func _on_new_game_pressed() -> void:
	_hide_save_slots()
	new_game_requested.emit()


func _on_continue_pressed() -> void:
	if _showing_save_slots:
		_hide_save_slots()
	else:
		_show_save_slots()


func _on_settings_pressed() -> void:
	_hide_save_slots()
	_show_settings_dialog()


## Shows a settings dialog with window mode options.
func _show_settings_dialog() -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "Settings"

	var vbox: VBoxContainer = VBoxContainer.new()
	dialog.add_child(vbox)

	var header: Label = Label.new()
	header.text = "Window Mode"
	header.add_theme_font_size_override("font_size", 16)
	vbox.add_child(header)

	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()

	var windowed_btn: Button = Button.new()
	windowed_btn.text = "Windowed"
	windowed_btn.disabled = current_mode == DisplayServer.WINDOW_MODE_WINDOWED
	windowed_btn.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_update_settings_buttons(vbox)
	)
	vbox.add_child(windowed_btn)

	var maximized_btn: Button = Button.new()
	maximized_btn.text = "Maximized"
	maximized_btn.disabled = current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED
	maximized_btn.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		_update_settings_buttons(vbox)
	)
	vbox.add_child(maximized_btn)

	var fullscreen_btn: Button = Button.new()
	fullscreen_btn.text = "Fullscreen"
	fullscreen_btn.disabled = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_btn.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_update_settings_buttons(vbox)
	)
	vbox.add_child(fullscreen_btn)

	dialog.confirmed.connect(func() -> void: dialog.queue_free())
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(300, 200))


## Updates settings button disabled states after a mode change.
func _update_settings_buttons(vbox: VBoxContainer) -> void:
	var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	for child: Node in vbox.get_children():
		if child is Button:
			match child.text:
				"Windowed":
					child.disabled = current_mode == DisplayServer.WINDOW_MODE_WINDOWED
				"Maximized":
					child.disabled = current_mode == DisplayServer.WINDOW_MODE_MAXIMIZED
				"Fullscreen":
					child.disabled = current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN


func _on_quit_pressed() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Quit the game?"
	dialog.confirmed.connect(func() -> void:
		dialog.queue_free()
		get_tree().quit()
	)
	dialog.canceled.connect(func() -> void: dialog.queue_free())
	dialog.close_requested.connect(func() -> void: dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


## Displays the save slot selection underneath Continue.
func _show_save_slots() -> void:
	_showing_save_slots = true

	# Clear and rebuild slot buttons
	for child: Node in save_slots_container.get_children():
		save_slots_container.remove_child(child)
		child.queue_free()

	for slot: int in range(1, SaveManager.MAX_SAVE_SLOTS + 1):
		var info: Dictionary = SaveManager.get_save_info(slot)
		var btn: Button = Button.new()

		if info.get("exists", false):
			var day: int = info.get("current_day", 1)
			var evidence_count: int = info.get("evidence_count", 0)
			var timestamp: String = info.get("save_timestamp", "")
			btn.text = "Slot %d — Day %d | Evidence: %d | %s" % [slot, day, evidence_count, timestamp]
		else:
			btn.text = "Slot %d — Empty" % slot
			btn.disabled = true

		btn.custom_minimum_size.y = 40
		var captured_slot: int = slot
		btn.pressed.connect(func() -> void: _on_save_slot_selected(captured_slot))
		save_slots_container.add_child(btn)

	save_slots_container.visible = true


func _hide_save_slots() -> void:
	_showing_save_slots = false
	save_slots_container.visible = false


func _on_save_slot_selected(slot: int) -> void:
	continue_requested.emit(slot)


func _on_debug_game_pressed() -> void:
	_hide_save_slots()
	# Default debug preset — can be extended with a selector later
	debug_game_requested.emit("debug_mark_interrogation.json")


## Shows or hides the Debug Game button based on available presets.
func _update_debug_button() -> void:
	var presets: Array[String] = DebugStateLoader.list_presets()
	debug_game_button.visible = not presets.is_empty()
