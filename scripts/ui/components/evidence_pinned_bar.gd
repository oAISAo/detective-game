## EvidencePinnedBar
## Manages the pinned evidence quick-access bar.
## Attaches to the existing %PinnedBar HBoxContainer in the scene.
## Self-manages EvidenceManager connections for live updates.
class_name EvidencePinnedBar
extends HBoxContainer


signal evidence_requested(evidence_id: String)

@onready var _pinned_label: Label = $PinnedLabel

var _on_pinned_cb: Callable
var _on_unpinned_cb: Callable
var _on_state_loaded_cb: Callable


func _ready() -> void:
	_on_pinned_cb = func(_id: String) -> void:
		populate()
	_on_unpinned_cb = func(_id: String) -> void:
		populate()
	_on_state_loaded_cb = func() -> void:
		populate()

	EvidenceManager.evidence_pinned.connect(_on_pinned_cb)
	EvidenceManager.evidence_unpinned.connect(_on_unpinned_cb)
	EvidenceManager.state_loaded.connect(_on_state_loaded_cb)

	populate()


func _exit_tree() -> void:
	UIHelper.safe_disconnect(EvidenceManager.evidence_pinned, _on_pinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.evidence_unpinned, _on_unpinned_cb)
	UIHelper.safe_disconnect(EvidenceManager.state_loaded, _on_state_loaded_cb)


func populate() -> void:
	for child: Node in get_children():
		if child == _pinned_label:
			continue
		remove_child(child)
		child.queue_free()

	var pinned: Array[String] = EvidenceManager.get_pinned_evidence()
	visible = not pinned.is_empty()
	if pinned.is_empty():
		return

	for eid: String in pinned:
		var ev: EvidenceData = CaseManager.get_evidence(eid)
		if ev == null:
			continue
		var btn := Button.new()
		btn.text = ev.name
		btn.flat = true
		btn.pressed.connect(
			func() -> void:
				evidence_requested.emit(eid)
		)
		add_child(btn)
