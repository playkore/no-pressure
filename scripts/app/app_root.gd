extends Node

const LEVELS := [
	{
		"id": "demo",
		"name": "Demo",
		"scene": "res://scenes/levels/DemoLevel.tscn",
	},
	{
		"id": "level001",
		"name": "Dirt Bike",
		"scene": "res://scenes/levels/Level001.tscn",
	},
]

@export var level_select_scene: PackedScene
@export var level_complete_overlay_scene: PackedScene
@export var pause_overlay_scene: PackedScene

@export_range(0.0, 2.0, 0.01, "or_greater") var fade_seconds := 0.18

@onready var world: Node = $World
@onready var overlay_layer: CanvasLayer = $Overlay
@onready var fade_rect: ColorRect = $Overlay/Fade

var _current_scene: Node
var _current_level_id := ""
var _current_level_scene_path := ""
var _pause_visible := false


func _ready() -> void:
	if OS.has_feature("headless") or OS.has_feature("server") or DisplayServer.get_name() == "headless":
		return

	if level_select_scene == null:
		level_select_scene = load("res://scenes/menus/LevelSelect.tscn") as PackedScene
	if level_complete_overlay_scene == null:
		level_complete_overlay_scene = load("res://scenes/overlays/LevelCompleteOverlay.tscn") as PackedScene
	if pause_overlay_scene == null:
		pause_overlay_scene = load("res://scenes/overlays/PauseOverlay.tscn") as PackedScene

	_show_level_select()


func get_levels() -> Array:
	return LEVELS


func start_level(level_id: String, scene_path: String) -> void:
	_current_level_id = level_id
	_current_level_scene_path = scene_path
	_change_world_scene(scene_path)


func restart_level() -> void:
	if _current_level_scene_path == "":
		return
	_clear_overlays()
	_change_world_scene(_current_level_scene_path)


func go_to_level_select() -> void:
	_current_level_id = ""
	_current_level_scene_path = ""
	_clear_overlays()
	_show_level_select()


func _show_level_select() -> void:
	_change_world_scene_to_packed(level_select_scene)
	if _current_scene != null and _current_scene.has_method("set_app"):
		_current_scene.call("set_app", self)


func _change_world_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	_change_world_scene_to_packed(packed)


func _change_world_scene_to_packed(packed: PackedScene) -> void:
	if packed == null:
		push_error("AppRoot: failed to load scene.")
		return

	await _fade_to(1.0)

	_clear_world()
	_current_scene = packed.instantiate()
	world.add_child(_current_scene)

	_wire_scene(_current_scene)

	await _fade_to(0.0)


func _wire_scene(scene: Node) -> void:
	if scene == null:
		return

	if scene.has_method("set_app"):
		scene.call("set_app", self)

	if scene.has_signal("level_completed"):
		scene.connect("level_completed", Callable(self, "_on_level_completed"))
	if scene.has_signal("pause_requested"):
		scene.connect("pause_requested", Callable(self, "show_pause_menu"))


func _clear_world() -> void:
	for child in world.get_children():
		child.queue_free()


func _on_level_completed(time_ms: int, stars: int) -> void:
	if _current_level_id != "":
		SaveData.set_level_result(_current_level_id, stars, time_ms)

	_show_level_complete_overlay(time_ms, stars)


func _show_level_complete_overlay(time_ms: int, stars: int) -> void:
	_clear_overlays()

	if _current_scene != null and _current_scene.has_method("set_overlay_active"):
		_current_scene.call("set_overlay_active", true)

	var overlay := level_complete_overlay_scene.instantiate()
	overlay_layer.add_child(overlay)

	if overlay.has_method("setup"):
		overlay.call("setup", time_ms, stars)
	if overlay.has_method("set_app"):
		overlay.call("set_app", self)


func show_pause_menu() -> void:
	if _pause_visible:
		return
	if _has_blocking_overlay():
		return
	if _current_level_scene_path == "":
		return

	_pause_visible = true
	if _current_scene != null and _current_scene.has_method("set_overlay_active"):
		_current_scene.call("set_overlay_active", true)

	var overlay := pause_overlay_scene.instantiate()
	overlay.name = "PauseOverlay"
	overlay_layer.add_child(overlay)
	if overlay.has_method("set_app"):
		overlay.call("set_app", self)


func hide_pause_menu() -> void:
	if not _pause_visible:
		return
	_pause_visible = false

	for child in overlay_layer.get_children():
		if child.name == "PauseOverlay":
			child.queue_free()

	if _current_scene != null and _current_scene.has_method("set_overlay_active"):
		_current_scene.call("set_overlay_active", false)


func _clear_overlays() -> void:
	_pause_visible = false
	for child in overlay_layer.get_children():
		if child != fade_rect:
			child.queue_free()
	if _current_scene != null and _current_scene.has_method("set_overlay_active"):
		_current_scene.call("set_overlay_active", false)


func _has_blocking_overlay() -> bool:
	for child in overlay_layer.get_children():
		if child != fade_rect:
			return true
	return false


func _fade_to(alpha: float) -> void:
	alpha = clampf(alpha, 0.0, 1.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(fade_rect, "color", Color(0, 0, 0, alpha), fade_seconds)
	await tween.finished
