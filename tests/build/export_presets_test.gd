extends GdUnitTestSuite

const PRESETS := "res://export_presets.cfg"


func _presets() -> ConfigFile:
	var cfg := ConfigFile.new()
	assert_int(cfg.load(PRESETS)).is_equal(OK)
	return cfg


func test_macos_preset_exports_universal_zip_to_build() -> void:
	var cfg := _presets()
	assert_str(cfg.get_value("preset.0", "name", "")).is_equal("macOS")
	assert_str(cfg.get_value("preset.0", "platform", "")).is_equal("macOS")
	assert_str(cfg.get_value("preset.0", "export_path", "")).is_equal("build/macos/tide-and-timber.zip")
	assert_str(cfg.get_value("preset.0.options", "binary_format/architecture", "")).is_equal("universal")
	assert_str(cfg.get_value("preset.0.options", "application/bundle_identifier", "")).is_equal("io.github.tideandtimber.game")
	assert_int(cfg.get_value("preset.0.options", "codesign/codesign", -1)).is_equal(1)


func test_windows_preset_embeds_pck_into_build_exe() -> void:
	var cfg := _presets()
	assert_str(cfg.get_value("preset.1", "name", "")).is_equal("Windows")
	assert_str(cfg.get_value("preset.1", "platform", "")).is_equal("Windows Desktop")
	assert_str(cfg.get_value("preset.1", "export_path", "")).is_equal("build/windows/tide-and-timber.exe")
	assert_bool(cfg.get_value("preset.1.options", "binary_format/embed_pck", false)).is_true()
	assert_str(cfg.get_value("preset.1.options", "binary_format/architecture", "")).is_equal("x86_64")
	assert_bool(cfg.get_value("preset.1.options", "application/modify_resources", true)).is_false()


func test_presets_exclude_tests_and_gdunit() -> void:
	var cfg := _presets()
	assert_str(cfg.get_value("preset.0", "exclude_filter", "")).is_equal("tests/*, addons/gdUnit4/*")
	assert_str(cfg.get_value("preset.1", "exclude_filter", "")).is_equal("tests/*, addons/gdUnit4/*")


func test_project_imports_etc2_astc_for_macos_universal() -> void:
	assert_bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)).is_true()
