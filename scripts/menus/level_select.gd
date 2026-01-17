extends Control

var _app: Node


func set_app(app: Node) -> void:
	_app = app
	if is_inside_tree():
		_build_list()


func _ready() -> void:
	_build_list()


func _build_list() -> void:
	var list: VBoxContainer = $Root/VBox/LevelList
	for child in list.get_children():
		child.queue_free()

	var levels: Array = []
	if _app != null and _app.has_method("get_levels"):
		levels = _app.call("get_levels")

	for level in levels:
		var id := String(level.get("id", ""))
		var name := String(level.get("name", id))
		var scene_path := String(level.get("scene", ""))

		var progress := SaveData.get_level_progress(id)
		var stars := int(progress.get("best_stars", 0))
		var best_time_ms := int(progress.get("best_time_ms", 0))

		var button := Button.new()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 72)
		button.text = "%s   %s   %s" % [name, _format_stars(stars), _format_time(best_time_ms)]
		button.pressed.connect(func() -> void:
			if _app != null and _app.has_method("start_level"):
				_app.call("start_level", id, scene_path)
		)
		button.focus_mode = Control.FOCUS_NONE

		list.add_child(button)


func _format_stars(stars: int) -> String:
	stars = clampi(stars, 0, 3)
	return "★".repeat(stars) + "☆".repeat(3 - stars)


func _format_time(ms: int) -> String:
	if ms <= 0:
		return "—"
	var total_seconds := float(ms) / 1000.0
	return "%.2fs" % total_seconds
