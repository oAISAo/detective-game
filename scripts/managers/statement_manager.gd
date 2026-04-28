## statement_manager.gd
## Tracks which statements the player has unlocked during interrogations.
## Statements are unlocked once and persist globally across sessions.
extends BaseSubsystem


# --- Signals --- #

## Emitted when a statement is unlocked for the first time.
signal statement_unlocked(statement_id: String)


# --- State --- #

## Set of unlocked statement IDs.
var _unlocked_statements: Dictionary = {}


# --- Public API --- #

## Unlocks a statement. Does nothing if already unlocked.
func unlock_statement(statement_id: String) -> void:
	if statement_id.is_empty():
		return
	if _unlocked_statements.has(statement_id):
		return
	_unlocked_statements[statement_id] = true
	statement_unlocked.emit(statement_id)


## Returns true if the given statement has been unlocked.
func is_statement_unlocked(statement_id: String) -> bool:
	return _unlocked_statements.has(statement_id)


## Returns all unlocked statement IDs as an Array.
func get_all_unlocked_statements() -> Array:
	return _unlocked_statements.keys()


# --- Serialization --- #

func serialize() -> Dictionary:
	return {
		"unlocked_statements": _unlocked_statements.keys(),
	}


func deserialize(data: Dictionary) -> void:
	_unlocked_statements.clear()
	for id: Variant in data.get("unlocked_statements", []):
		if id is String:
			_unlocked_statements[id] = true


func reset() -> void:
	_unlocked_statements.clear()
