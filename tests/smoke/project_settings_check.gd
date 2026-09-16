extends SceneTree
# Run: godot --headless --path . --script res://tests/smoke/project_settings_check.gd
# Exits 0 when every expectation holds, 1 otherwise, printing one "FAIL: <key>: expected <e>, got <a>" line per mismatch.

const EXPECTED := {
	"display/window/size/viewport_width": 320,
	"display/window/size/viewport_height": 180,
	"display/window/stretch/mode": "viewport",
	"display/window/stretch/aspect": "keep",
	"display/window/stretch/scale_mode": "integer",
	"rendering/textures/canvas_textures/default_texture_filter": 0,
	"rendering/2d/snap/snap_2d_transforms_to_pixel": true,
	"rendering/2d/snap/snap_2d_vertices_to_pixel": true,
	"rendering/renderer/rendering_method": "gl_compatibility",
	"application/run/main_scene": "res://src/main/main.tscn",
}


func _initialize() -> void:
	var failures: Array[String] = check_settings()
	failures.append_array(check_main_scene())
	for message in failures:
		print(message)
	quit(0 if failures.is_empty() else 1)


func check_settings() -> Array[String]:
	var failures: Array[String] = []
	for key: String in EXPECTED:
		var expected: Variant = EXPECTED[key]
		var actual: Variant = ProjectSettings.get_setting(key)
		if typeof(actual) != typeof(expected) or actual != expected:
			failures.append("FAIL: %s: expected %s, got %s" % [key, expected, actual])
	return failures


func check_main_scene() -> Array[String]:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	if not ResourceLoader.exists(path):
		return ["FAIL: main_scene: %s does not exist" % path]
	var scene := load(path) as PackedScene
	if scene == null:
		return ["FAIL: main_scene: %s is not a PackedScene" % path]
	var instance := scene.instantiate()
	var failures: Array[String] = []
	if not instance is Node2D:
		failures.append("FAIL: main_scene: root is %s, expected Node2D" % instance.get_class())
	if instance.name != &"Main":
		failures.append("FAIL: main_scene: root is named %s, expected Main" % instance.name)
	if instance.get_child_count() != 0:
		failures.append("FAIL: main_scene: root has %d children, expected 0" % instance.get_child_count())
	instance.free()
	return failures
