## test_placeholder_generator.gd
## Unit tests for PlaceholderAssetGenerator.
## Verifies correct asset definitions, image sizes, file names, and generation.
extends GutTest

const TEST_OUTPUT_DIR: String = "user://test_placeholders/"


func before_all() -> void:
	_clean_dir(TEST_OUTPUT_DIR)


func after_all() -> void:
	_clean_dir(TEST_OUTPUT_DIR)


# --- Asset Definition Count Tests ---

func test_location_asset_count() -> void:
	var assets := PlaceholderAssetGenerator._location_assets()
	assert_eq(assets.size(), 5, "Should define 5 location backgrounds")


func test_portrait_asset_count() -> void:
	var assets := PlaceholderAssetGenerator._portrait_assets()
	assert_eq(assets.size(), 24, "Should define 24 suspect portraits (4 suspects x 6 expressions)")


func test_evidence_asset_count() -> void:
	var assets := PlaceholderAssetGenerator._evidence_assets()
	assert_eq(assets.size(), 26, "Should define 26 evidence images")


func test_evidence_asset_includes_autopsy_report() -> void:
	var assets := PlaceholderAssetGenerator._evidence_assets()
	var filenames: Array[String] = []
	for asset in assets:
		filenames.append(asset.filename)
	assert_has(filenames, "placeholder_evidence_autopsy_report.png",
		"Evidence placeholders should include the autopsy report")


func test_ui_asset_count() -> void:
	var assets := PlaceholderAssetGenerator._ui_assets()
	assert_eq(assets.size(), 7, "Should define 7 UI textures")


func test_icon_asset_count() -> void:
	var assets := PlaceholderAssetGenerator._icon_assets()
	assert_eq(assets.size(), 3, "Should define 3 board node icons")


func test_total_asset_count() -> void:
	var assets := PlaceholderAssetGenerator.get_all_asset_definitions()
	assert_eq(assets.size(), 65, "Should define 65 total assets (5+24+26+7+3)")


# --- Naming Convention Tests ---

func test_all_filenames_start_with_placeholder() -> void:
	for asset in PlaceholderAssetGenerator.get_all_asset_definitions():
		assert_true(
			asset.filename.begins_with("placeholder_"),
			"Filename should start with 'placeholder_': %s" % asset.filename
		)


func test_all_filenames_end_with_png() -> void:
	for asset in PlaceholderAssetGenerator.get_all_asset_definitions():
		assert_true(
			asset.filename.ends_with(".png"),
			"Filename should end with '.png': %s" % asset.filename
		)


func test_location_filenames_contain_location() -> void:
	for asset in PlaceholderAssetGenerator._location_assets():
		assert_true(
			asset.filename.begins_with("placeholder_location_"),
			"Location filename should contain 'location': %s" % asset.filename
		)


func test_portrait_filenames_contain_portrait() -> void:
	for asset in PlaceholderAssetGenerator._portrait_assets():
		assert_true(
			asset.filename.begins_with("placeholder_portrait_"),
			"Portrait filename should contain 'portrait': %s" % asset.filename
		)


func test_evidence_filenames_contain_evidence() -> void:
	for asset in PlaceholderAssetGenerator._evidence_assets():
		assert_true(
			asset.filename.begins_with("placeholder_evidence_"),
			"Evidence filename should contain 'evidence': %s" % asset.filename
		)


func test_no_duplicate_filenames() -> void:
	var names: Dictionary = {}
	for asset in PlaceholderAssetGenerator.get_all_asset_definitions():
		assert_false(names.has(asset.filename), "Duplicate filename: %s" % asset.filename)
		names[asset.filename] = true


# --- Asset Definition Field Tests ---

func test_all_assets_have_required_fields() -> void:
	for asset in PlaceholderAssetGenerator.get_all_asset_definitions():
		assert_true(asset.has("filename"), "Asset missing 'filename'")
		assert_true(asset.has("label"), "Asset missing 'label'")
		assert_true(asset.has("width"), "Asset missing 'width'")
		assert_true(asset.has("height"), "Asset missing 'height'")
		assert_true(asset.has("color"), "Asset missing 'color'")


func test_location_dimensions() -> void:
	for asset in PlaceholderAssetGenerator._location_assets():
		assert_eq(asset.width, 1920, "Location width should be 1920")
		assert_eq(asset.height, 1080, "Location height should be 1080")


func test_portrait_dimensions() -> void:
	for asset in PlaceholderAssetGenerator._portrait_assets():
		assert_eq(asset.width, 512, "Portrait width should be 512")
		assert_eq(asset.height, 512, "Portrait height should be 512")


func test_evidence_dimensions() -> void:
	for asset in PlaceholderAssetGenerator._evidence_assets():
		assert_eq(asset.width, 512, "Evidence width should be 512")
		assert_eq(asset.height, 512, "Evidence height should be 512")


func test_ui_dimensions() -> void:
	for asset in PlaceholderAssetGenerator._ui_assets():
		assert_eq(asset.width, 1024, "UI width should be 1024")
		assert_eq(asset.height, 1024, "UI height should be 1024")


func test_icon_dimensions() -> void:
	for asset in PlaceholderAssetGenerator._icon_assets():
		assert_eq(asset.width, 128, "Icon width should be 128")
		assert_eq(asset.height, 128, "Icon height should be 128")


# --- Image Generation Tests ---

func test_generate_placeholder_creates_file() -> void:
	var path := TEST_OUTPUT_DIR + "test_gen.png"
	var ok := PlaceholderAssetGenerator.generate_placeholder(64, 64, Color.GRAY, "TEST", path)
	assert_true(ok, "generate_placeholder should return true")
	assert_true(FileAccess.file_exists(path), "Generated file should exist")


func test_generated_image_has_correct_dimensions_small() -> void:
	var path := TEST_OUTPUT_DIR + "test_dim_small.png"
	PlaceholderAssetGenerator.generate_placeholder(128, 128, Color.GRAY, "TEST", path)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert_not_null(image, "Should load generated image")
	assert_eq(image.get_width(), 128)
	assert_eq(image.get_height(), 128)


func test_generated_image_has_correct_dimensions_medium() -> void:
	var path := TEST_OUTPUT_DIR + "test_dim_med.png"
	PlaceholderAssetGenerator.generate_placeholder(512, 512, Color.GRAY, "TEST", path)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert_not_null(image, "Should load generated image")
	assert_eq(image.get_width(), 512)
	assert_eq(image.get_height(), 512)


func test_generated_image_has_correct_dimensions_large() -> void:
	var path := TEST_OUTPUT_DIR + "test_dim_large.png"
	PlaceholderAssetGenerator.generate_placeholder(1920, 1080, Color.GRAY, "TEST", path)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert_not_null(image, "Should load generated image")
	assert_eq(image.get_width(), 1920)
	assert_eq(image.get_height(), 1080)


func test_generated_image_has_correct_dimensions_ui() -> void:
	var path := TEST_OUTPUT_DIR + "test_dim_ui.png"
	PlaceholderAssetGenerator.generate_placeholder(1024, 1024, Color.GRAY, "TEST", path)
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	assert_not_null(image, "Should load generated image")
	assert_eq(image.get_width(), 1024)
	assert_eq(image.get_height(), 1024)


func test_generate_with_empty_label_succeeds() -> void:
	var path := TEST_OUTPUT_DIR + "test_empty_label.png"
	var ok := PlaceholderAssetGenerator.generate_placeholder(64, 64, Color.GRAY, "", path)
	assert_true(ok, "Empty label should still succeed")


# --- Full Generation Tests ---

func test_generate_all_returns_correct_totals() -> void:
	var results := PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	assert_eq(results.total, 65, "Should attempt 65 assets")
	assert_eq(results.generated, 65, "Should generate 65 assets")
	assert_eq(results.failed, 0, "Should have 0 failures")


func test_generate_all_creates_all_files() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator.get_all_asset_definitions():
		var path: String = TEST_OUTPUT_DIR + str(asset.filename)
		assert_true(FileAccess.file_exists(path), "Missing file: %s" % str(asset.filename))


func test_generate_all_location_image_sizes() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator._location_assets():
		var path: String = ProjectSettings.globalize_path(TEST_OUTPUT_DIR + str(asset.filename))
		var image := Image.load_from_file(path)
		assert_not_null(image, "Should load: %s" % str(asset.filename))
		assert_eq(image.get_width(), 1920, "Width for %s" % str(asset.filename))
		assert_eq(image.get_height(), 1080, "Height for %s" % str(asset.filename))


func test_generate_all_portrait_image_sizes() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator._portrait_assets():
		var path: String = ProjectSettings.globalize_path(TEST_OUTPUT_DIR + str(asset.filename))
		var image := Image.load_from_file(path)
		assert_not_null(image, "Should load: %s" % str(asset.filename))
		assert_eq(image.get_width(), 512, "Width for %s" % str(asset.filename))
		assert_eq(image.get_height(), 512, "Height for %s" % str(asset.filename))


func test_generate_all_evidence_image_sizes() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator._evidence_assets():
		var path: String = ProjectSettings.globalize_path(TEST_OUTPUT_DIR + str(asset.filename))
		var image := Image.load_from_file(path)
		assert_not_null(image, "Should load: %s" % str(asset.filename))
		assert_eq(image.get_width(), 512, "Width for %s" % str(asset.filename))
		assert_eq(image.get_height(), 512, "Height for %s" % str(asset.filename))


func test_generate_all_ui_image_sizes() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator._ui_assets():
		var path: String = ProjectSettings.globalize_path(TEST_OUTPUT_DIR + str(asset.filename))
		var image := Image.load_from_file(path)
		assert_not_null(image, "Should load: %s" % str(asset.filename))
		assert_eq(image.get_width(), 1024, "Width for %s" % str(asset.filename))
		assert_eq(image.get_height(), 1024, "Height for %s" % str(asset.filename))


func test_generate_all_icon_image_sizes() -> void:
	PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	for asset in PlaceholderAssetGenerator._icon_assets():
		var path: String = ProjectSettings.globalize_path(TEST_OUTPUT_DIR + str(asset.filename))
		var image := Image.load_from_file(path)
		assert_not_null(image, "Should load: %s" % str(asset.filename))
		assert_eq(image.get_width(), 128, "Width for %s" % str(asset.filename))
		assert_eq(image.get_height(), 128, "Height for %s" % str(asset.filename))


# --- Idempotency Test ---

func test_generate_twice_produces_same_results() -> void:
	var r1 := PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	var r2 := PlaceholderAssetGenerator.generate_all_placeholders(TEST_OUTPUT_DIR)
	assert_eq(r1.total, r2.total, "Total should match on re-run")
	assert_eq(r1.generated, r2.generated, "Generated should match on re-run")
	assert_eq(r1.failed, r2.failed, "Failed should match on re-run")


# --- Specific Named Asset Tests ---

func test_specific_location_filenames_exist() -> void:
	var expected := [
		"placeholder_location_victim_apartment.png",
		"placeholder_location_building_hallway.png",
		"placeholder_location_parking_lot.png",
		"placeholder_location_neighbor_apartment.png",
		"placeholder_location_victim_office.png",
	]
	var actual_names: Array[String] = []
	for asset in PlaceholderAssetGenerator._location_assets():
		actual_names.append(asset.filename)
	for name in expected:
		assert_true(name in actual_names, "Should include location: %s" % name)


func test_specific_portrait_filenames_exist() -> void:
	var expected := [
		"placeholder_portrait_julia_neutral.png",
		"placeholder_portrait_mark_angry.png",
		"placeholder_portrait_sarah_nervous.png",
		"placeholder_portrait_lucas_calm.png",
	]
	var actual_names: Array[String] = []
	for asset in PlaceholderAssetGenerator._portrait_assets():
		actual_names.append(asset.filename)
	for name in expected:
		assert_true(name in actual_names, "Should include portrait: %s" % name)


func test_specific_evidence_filenames_exist() -> void:
	var expected := [
		"placeholder_evidence_kitchen_knife.png",
		"placeholder_evidence_wine_glasses.png",
		"placeholder_evidence_parking_camera.png",
		"placeholder_evidence_personal_journal.png",
	]
	var actual_names: Array[String] = []
	for asset in PlaceholderAssetGenerator._evidence_assets():
		actual_names.append(asset.filename)
	for name in expected:
		assert_true(name in actual_names, "Should include evidence: %s" % name)


# --- Helper ---

func _clean_dir(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)
