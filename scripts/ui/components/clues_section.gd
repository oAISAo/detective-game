## CluesSection.gd
## Displays discovered clues for an investigable object as a grid of polaroid cards.
## Shows a header, then either an empty-state message or a scrollable grid of polaroids.
class_name CluesSection
extends VBoxContainer


const _GRID_COLUMNS: int = 3
const _GRID_SEPARATION: int = 10
const _HEADER_BOTTOM_MARGIN: int = 8
const POLAROID_SCENE: PackedScene = preload("res://scenes/ui/components/evidence_polaroid.tscn")

@onready var _empty_label: Label = %EmptyLabel
@onready var _scroll: ScrollContainer = %ClueScroll
@onready var _grid: GridContainer = %ClueGrid


func _ready() -> void:
	_empty_label.add_theme_color_override("font_color", UIColors.TEXT_GREY)
	_empty_label.add_theme_font_size_override("font_size", UIFonts.SIZE_METADATA)


## Populates the section with discovered clues.
func populate(clues: Array[EvidenceData], handwriting_font: Font = null) -> void:
	UIHelper.clear_children(_grid)

	if clues.is_empty():
		_empty_label.visible = true
		_scroll.visible = false
		return

	_empty_label.visible = false
	_scroll.visible = true

	for ev: EvidenceData in clues:
		var card: EvidencePolaroid = POLAROID_SCENE.instantiate() as EvidencePolaroid
		_grid.add_child(card)
		card.setup(ev, handwriting_font)
