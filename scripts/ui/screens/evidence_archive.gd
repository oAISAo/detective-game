## EvidenceArchive.gd
## Screen for viewing and managing collected evidence.
## Phase 4A: Shell screen — full functionality in Phase 5.
extends Control


@onready var title_label: Label = %TitleLabel
@onready var evidence_list: VBoxContainer = %EvidenceList
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var detail_label: RichTextLabel = %DetailLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_populate_evidence_list()


## Populates the evidence list from CaseManager discovered evidence.
func _populate_evidence_list() -> void:
	for child: Node in evidence_list.get_children():
		child.queue_free()

	var evidence_ids: Array[String] = GameManager.discovered_evidence
	if evidence_ids.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No evidence collected yet."
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45))
		evidence_list.add_child(empty_label)
		return

	for eid: String in evidence_ids:
		var evidence: Resource = CaseManager.get_evidence(eid)
		if evidence == null:
			continue
		var btn: Button = Button.new()
		btn.text = evidence.name if evidence.get("name") else eid
		btn.pressed.connect(_on_evidence_selected.bind(eid))
		evidence_list.add_child(btn)


## Handles selecting an evidence item to view details.
func _on_evidence_selected(evidence_id: String) -> void:
	var evidence: Resource = CaseManager.get_evidence(evidence_id)
	if evidence == null:
		detail_label.text = "Evidence not found."
		return
	detail_panel.visible = true
	detail_label.text = "[b]%s[/b]\n%s" % [
		evidence.name if evidence.get("name") else evidence_id,
		evidence.description if evidence.get("description") else "No details available."
	]


## Navigates back to the previous screen.
func _on_back_pressed() -> void:
	ScreenManager.navigate_back()
