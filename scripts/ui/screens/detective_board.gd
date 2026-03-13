## DetectiveBoard.gd
## The detective's cork board for pinning evidence, notes, and connections.
## Phase 4A: Shell screen — full Theory Builder in Phase 4B.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var board_area: Control = %BoardArea
@onready var back_button: Button = %BackButton
@onready var placeholder_label: Label = %PlaceholderLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_refresh()


## Refreshes the board display.
func _refresh() -> void:
	# Phase 4A: Show placeholder
	placeholder_label.text = "Pin evidence and draw connections.\nFull board features coming in Phase 4B."


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
