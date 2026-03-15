## placeholder_asset_generator.gd
## Generates placeholder PNG assets for development using the Godot Image API.
## Each placeholder has correct dimensions, category-colored background, and a centered text label.
class_name PlaceholderAssetGenerator

const OUTPUT_DIR: String = "res://assets/placeholders/"

# Category background colors
const COLOR_LOCATION := Color(0.12, 0.18, 0.32)
const COLOR_PORTRAIT := Color(0.12, 0.28, 0.14)
const COLOR_EVIDENCE := Color(0.30, 0.30, 0.30)
const COLOR_UI := Color(0.35, 0.22, 0.12)
const COLOR_ICON := Color(0.25, 0.18, 0.30)
const COLOR_TEXT := Color(0.85, 0.85, 0.85)
const COLOR_BORDER := Color(0.50, 0.50, 0.50)

# 5x7 bitmap font — each character is an array of 7 ints (5-bit row bitmasks, MSB = left pixel)
const CHAR_W: int = 5
const CHAR_H: int = 7
const CHAR_SPACING: int = 1

const FONT: Dictionary = {
	" ": [0, 0, 0, 0, 0, 0, 0],
	"A": [14, 17, 17, 31, 17, 17, 17],
	"B": [30, 17, 17, 30, 17, 17, 30],
	"C": [14, 17, 16, 16, 16, 17, 14],
	"D": [28, 18, 17, 17, 17, 18, 28],
	"E": [31, 16, 16, 30, 16, 16, 31],
	"F": [31, 16, 16, 30, 16, 16, 16],
	"G": [14, 17, 16, 23, 17, 17, 14],
	"H": [17, 17, 17, 31, 17, 17, 17],
	"I": [14, 4, 4, 4, 4, 4, 14],
	"J": [7, 2, 2, 2, 2, 18, 12],
	"K": [17, 18, 20, 24, 20, 18, 17],
	"L": [16, 16, 16, 16, 16, 16, 31],
	"M": [17, 27, 21, 21, 17, 17, 17],
	"N": [17, 25, 21, 19, 17, 17, 17],
	"O": [14, 17, 17, 17, 17, 17, 14],
	"P": [30, 17, 17, 30, 16, 16, 16],
	"Q": [14, 17, 17, 17, 21, 18, 13],
	"R": [30, 17, 17, 30, 20, 18, 17],
	"S": [14, 17, 16, 14, 1, 17, 14],
	"T": [31, 4, 4, 4, 4, 4, 4],
	"U": [17, 17, 17, 17, 17, 17, 14],
	"V": [17, 17, 17, 17, 10, 10, 4],
	"W": [17, 17, 17, 21, 21, 21, 10],
	"X": [17, 17, 10, 4, 10, 17, 17],
	"Y": [17, 17, 10, 4, 4, 4, 4],
	"Z": [31, 1, 2, 4, 8, 16, 31],
	"0": [14, 17, 17, 17, 17, 17, 14],
	"1": [4, 12, 4, 4, 4, 4, 14],
	"2": [14, 17, 1, 6, 8, 16, 31],
	"3": [14, 17, 1, 6, 1, 17, 14],
	"4": [2, 6, 10, 18, 31, 2, 2],
	"5": [31, 16, 30, 1, 1, 17, 14],
	"6": [14, 17, 16, 30, 17, 17, 14],
	"7": [31, 1, 2, 4, 8, 8, 8],
	"8": [14, 17, 17, 14, 17, 17, 14],
	"9": [14, 17, 17, 15, 1, 17, 14],
	"-": [0, 0, 0, 14, 0, 0, 0],
	".": [0, 0, 0, 0, 0, 4, 0],
	"/": [1, 2, 2, 4, 8, 8, 16],
	":": [0, 4, 4, 0, 4, 4, 0],
}


# --- Asset Definition Lists ---

static func _location_assets() -> Array[Dictionary]:
	return [
		{"filename": "placeholder_location_victim_apartment.png", "label": "Victim Apartment", "width": 1920, "height": 1080, "color": COLOR_LOCATION},
		{"filename": "placeholder_location_building_hallway.png", "label": "Building Hallway", "width": 1920, "height": 1080, "color": COLOR_LOCATION},
		{"filename": "placeholder_location_parking_lot.png", "label": "Parking Lot", "width": 1920, "height": 1080, "color": COLOR_LOCATION},
		{"filename": "placeholder_location_neighbor_apartment.png", "label": "Neighbor Apartment", "width": 1920, "height": 1080, "color": COLOR_LOCATION},
		{"filename": "placeholder_location_victim_office.png", "label": "Victim Office", "width": 1920, "height": 1080, "color": COLOR_LOCATION},
	]


static func _portrait_assets() -> Array[Dictionary]:
	var assets: Array[Dictionary] = []
	var suspects := ["julia", "mark", "sarah", "lucas"]
	var names := {"julia": "Julia Ross", "mark": "Mark Bennett", "sarah": "Sarah Klein", "lucas": "Lucas Weber"}
	var expressions := ["neutral", "nervous", "angry", "defensive", "panicked", "calm"]
	for s in suspects:
		for e in expressions:
			assets.append({
				"filename": "placeholder_portrait_%s_%s.png" % [s, e],
				"label": "%s - %s" % [names[s], e],
				"width": 512, "height": 512, "color": COLOR_PORTRAIT,
			})
	return assets


static func _evidence_assets() -> Array[Dictionary]:
	var items: Array[Array] = [
		["kitchen_knife", "E1 - Kitchen Knife"],
		["wine_glasses", "E2 - Wine Glasses"],
		["fingerprint_wine_glass", "E3 - Fingerprint Glass"],
		["fingerprint_desk", "E4 - Fingerprint Desk"],
		["broken_picture_frame", "E5 - Broken Frame"],
		["victim_phone", "E6 - Victim Phone"],
		["text_message_julia", "E7 - Text Message Julia"],
		["deleted_messages", "E8 - Deleted Messages"],
		["call_log", "E9 - Call Log"],
		["email_daniel_mark", "E10 - Email Daniel Mark"],
		["bank_transfer", "E11 - Bank Transfer"],
		["accounting_files", "E12 - Accounting Files"],
		["financial_records_julia", "E13 - Financial Records"],
		["parking_camera", "E14 - Parking Camera"],
		["hallway_camera", "E15 - Hallway Camera"],
		["elevator_logs", "E16 - Elevator Logs"],
		["sarah_testimony", "E17 - Sarah Testimony"],
		["sarah_testimony_2", "E18 - Sarah Testimony 2"],
		["lucas_work_log", "E19 - Lucas Work Log"],
		["shoe_print", "E20 - Shoe Print"],
		["julia_shoes", "E21 - Julia Shoes"],
		["wine_bottle", "E22 - Wine Bottle"],
		["knife_block", "E23 - Knife Block"],
		["hidden_safe", "E24 - Hidden Safe"],
		["personal_journal", "E25 - Personal Journal"],
	]
	var assets: Array[Dictionary] = []
	for item in items:
		assets.append({
			"filename": "placeholder_evidence_%s.png" % item[0],
			"label": item[1],
			"width": 512, "height": 512, "color": COLOR_EVIDENCE,
		})
	return assets


static func _ui_assets() -> Array[Dictionary]:
	return [
		{"filename": "placeholder_ui_corkboard.png", "label": "UI - Corkboard", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_paper.png", "label": "UI - Paper", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_tape.png", "label": "UI - Tape", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_folder_frame.png", "label": "UI - Folder Frame", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_sticky_note.png", "label": "UI - Sticky Note", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_pin.png", "label": "UI - Pin", "width": 1024, "height": 1024, "color": COLOR_UI},
		{"filename": "placeholder_ui_thread.png", "label": "UI - Thread", "width": 1024, "height": 1024, "color": COLOR_UI},
	]


static func _icon_assets() -> Array[Dictionary]:
	return [
		{"filename": "placeholder_icon_node_person.png", "label": "Person", "width": 128, "height": 128, "color": COLOR_ICON},
		{"filename": "placeholder_icon_node_evidence.png", "label": "Evidence", "width": 128, "height": 128, "color": COLOR_ICON},
		{"filename": "placeholder_icon_node_event.png", "label": "Event", "width": 128, "height": 128, "color": COLOR_ICON},
	]


static func get_all_asset_definitions() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(_location_assets())
	all.append_array(_portrait_assets())
	all.append_array(_evidence_assets())
	all.append_array(_ui_assets())
	all.append_array(_icon_assets())
	return all


# --- Generation ---

static func generate_all_placeholders(output_dir: String = OUTPUT_DIR) -> Dictionary:
	var results := {"generated": 0, "failed": 0, "total": 0}
	DirAccess.make_dir_recursive_absolute(output_dir)
	for asset in get_all_asset_definitions():
		results.total += 1
		var path: String = output_dir + asset.filename
		if generate_placeholder(asset.width, asset.height, asset.color, asset.label, path):
			results.generated += 1
		else:
			results.failed += 1
	return results


static func generate_placeholder(width: int, height: int, bg_color: Color, label: String, path: String) -> bool:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(bg_color)
	_draw_border(image, COLOR_BORDER, 2)
	_draw_text_centered(image, label.to_upper(), COLOR_TEXT)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return image.save_png(path) == OK


# --- Drawing Helpers ---

static func _draw_border(image: Image, color: Color, thickness: int) -> void:
	var w := image.get_width()
	var h := image.get_height()
	for t in range(thickness):
		for x in range(w):
			image.set_pixel(x, t, color)
			image.set_pixel(x, h - 1 - t, color)
		for y in range(h):
			image.set_pixel(t, y, color)
			image.set_pixel(w - 1 - t, y, color)


static func _draw_text_centered(image: Image, text: String, color: Color) -> void:
	if text.is_empty():
		return
	var text_pixel_w := text.length() * (CHAR_W + CHAR_SPACING) - CHAR_SPACING
	var iw := image.get_width()
	var ih := image.get_height()
	var scale_x := int(float(iw) * 0.85 / max(text_pixel_w, 1))
	var scale_y := int(float(ih) * 0.3 / CHAR_H)
	var scale := maxi(mini(scale_x, scale_y), 1)
	var total_w := text_pixel_w * scale
	var total_h := CHAR_H * scale
	var start_x := (iw - total_w) / 2
	var start_y := (ih - total_h) / 2
	var cursor_x := start_x
	for i in range(text.length()):
		var c := text[i]
		if c in FONT:
			_draw_char(image, FONT[c], cursor_x, start_y, scale, color)
		cursor_x += (CHAR_W + CHAR_SPACING) * scale


static func _draw_char(image: Image, rows: Array, x: int, y: int, scale: int, color: Color) -> void:
	var iw := image.get_width()
	var ih := image.get_height()
	for row_idx in range(CHAR_H):
		var row_bits: int = rows[row_idx]
		for col in range(CHAR_W):
			if row_bits & (1 << (CHAR_W - 1 - col)):
				for sy in range(scale):
					for sx in range(scale):
						var px := x + col * scale + sx
						var py := y + row_idx * scale + sy
						if px >= 0 and px < iw and py >= 0 and py < ih:
							image.set_pixel(px, py, color)
