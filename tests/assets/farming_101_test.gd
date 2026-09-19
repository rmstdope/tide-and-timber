extends GdUnitTestSuite

const ZIP := "res://assets/vendor/pixel_echoes/Farming 101.zip"
const ZIP_SHA256 := "ed7b321ec358fa841b5735d7bd0e598f58b2b9ae8b28e1f99bb3fc04d724cb31"
const ZIP_ROOT := "Farming 101/"
const UNPACKED := "res://assets/farming_101/"
const LEDGER := "res://assets/VENDORED.md"
const PNG_COUNT := 88
const LEDGER_ROW := "| Farming 101 | undated | assets/vendor/pixel_echoes/Farming 101.zip, downloaded from Pixel Echoes (https://pixelechoes.itch.io/) | ed7b321ec358fa841b5735d7bd0e598f58b2b9ae8b28e1f99bb3fc04d724cb31 | Pixel Echoes' terms: commercial use and alteration allowed, credit not required, not to be redistributed or resold as assets (assets/vendor/pixel_echoes/LICENSE) |"


# The res:// path of every .png entry in the zip, with ZIP_ROOT replaced by UNPACKED.
func _zip_pngs() -> PackedStringArray:
	var out := PackedStringArray()
	var zip := ZIPReader.new()
	assert_int(zip.open(ZIP)).is_equal(OK)
	for name in zip.get_files():
		if name.ends_with(".png") and name.begins_with(ZIP_ROOT):
			out.append(UNPACKED + name.substr(ZIP_ROOT.length()))
	zip.close()
	return out


# Every file under UNPACKED, recursively, as res:// paths.
func _unpacked_files(dir: String = UNPACKED) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		out.append(dir + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_unpacked_files(dir + d + "/"))
	return out


func test_zip_matches_the_ledger_hash() -> void:
	assert_str(FileAccess.get_sha256(ZIP)).is_equal(ZIP_SHA256)


func test_ledger_lists_the_farming_101_pack() -> void:
	var ledger := FileAccess.get_file_as_string(LEDGER)
	assert_str(ledger).contains(LEDGER_ROW)
	assert_str(ledger).contains(ZIP_SHA256)


func test_every_png_in_the_zip_is_unpacked_as_a_texture() -> void:
	var pngs := _zip_pngs()
	assert_int(pngs.size()).is_equal(PNG_COUNT)
	for path in pngs:
		assert_bool(ResourceLoader.exists(path)).override_failure_message("missing: " + path).is_true()
		assert_bool(load(path) is Texture2D).override_failure_message("not a texture: " + path).is_true()


func test_only_the_zips_pngs_are_unpacked() -> void:
	var pngs := _zip_pngs()
	var imports := 0
	for path in _unpacked_files():
		if path.ends_with(".png.import"):
			imports += 1
			assert_bool(pngs.has(path.trim_suffix(".import"))).override_failure_message("stray import: " + path).is_true()
		else:
			assert_bool(path.ends_with(".png") and pngs.has(path)).override_failure_message("stray file: " + path).is_true()
	assert_int(imports).is_equal(PNG_COUNT)


func test_textures_import_lossless_without_mipmaps() -> void:
	for path in _zip_pngs():
		var cfg := ConfigFile.new()
		assert_int(cfg.load(path + ".import")).override_failure_message("no import: " + path).is_equal(OK)
		assert_int(cfg.get_value("params", "compress/mode", -1)).override_failure_message("compress: " + path).is_equal(0)
		assert_bool(cfg.get_value("params", "mipmaps/generate", true)).override_failure_message("mipmaps: " + path).is_false()
