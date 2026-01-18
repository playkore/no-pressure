extends Node2D

signal level_completed(time_ms: int, stars: int)
signal pause_requested

@export var initial_powerwasher_anchor := Vector2(0.78, 0.78)
@export_range(0.0, 3600.0, 0.1, "or_greater") var star_time_1_seconds := 90.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var star_time_2_seconds := 60.0
@export_range(0.0, 3600.0, 0.1, "or_greater") var star_time_3_seconds := 35.0

@onready var clean: Sprite2D = $Clean
@onready var dirty: Sprite2D = $Dirty
@onready var power_washer: Node2D = $PowerWasher
@onready var mask_cleaning: Node = $MaskCleaning
@onready var water_vfx: Node2D = $WaterVfx
@onready var top_hud: CanvasLayer = $TopHud

var _timer_running := false
var _start_ms := 0
var _elapsed_ms := 0
var _timer_paused := false
var _level_finished := false
var _overlay_active := false


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)
	if mask_cleaning != null:
		mask_cleaning.connect("level_completed", Callable(self, "_on_level_completed"))
	if top_hud != null and top_hud.has_signal("pause_pressed"):
		top_hud.connect("pause_pressed", Callable(self, "_on_pause_pressed"))


func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return

	_fit_level_art(viewport_size)
	power_washer.global_position = viewport_size * initial_powerwasher_anchor


func _fit_level_art(viewport_size: Vector2) -> void:
	var tex := dirty.texture
	if tex == null or clean.texture == null:
		return

	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	# Fit the full image on screen without horizontal cropping.
	# This makes the image width fit the viewport; height may letterbox.
	var scale_factor := minf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	clean.scale = Vector2.ONE * scale_factor
	dirty.scale = Vector2.ONE * scale_factor
	clean.global_position = viewport_size * 0.5
	dirty.global_position = viewport_size * 0.5


func _process(_delta: float) -> void:
	if _overlay_active:
		return
	if _level_finished:
		return
	if _timer_running:
		_elapsed_ms = max(0, Time.get_ticks_msec() - _start_ms)
		return
	if power_washer.has_method("is_spraying") and bool(power_washer.call("is_spraying")):
		_timer_running = true
		_start_ms = Time.get_ticks_msec()
		_elapsed_ms = 0
		_timer_paused = false


func _on_level_completed() -> void:
	var time_ms := _elapsed_ms
	if _timer_running:
		time_ms = max(0, Time.get_ticks_msec() - _start_ms)
		_elapsed_ms = time_ms
	_timer_running = false
	_level_finished = true
	set_overlay_active(true)
	var stars := _compute_stars(time_ms)
	level_completed.emit(time_ms, stars)


func _compute_stars(time_ms: int) -> int:
	var seconds := float(time_ms) / 1000.0
	if star_time_3_seconds > 0.0 and seconds <= star_time_3_seconds:
		return 3
	if star_time_2_seconds > 0.0 and seconds <= star_time_2_seconds:
		return 2
	if star_time_1_seconds > 0.0 and seconds <= star_time_1_seconds:
		return 1
	return 0


func get_elapsed_seconds() -> float:
	if _timer_running:
		return float(maxi(0, Time.get_ticks_msec() - _start_ms)) / 1000.0
	return float(_elapsed_ms) / 1000.0


func set_overlay_active(active: bool) -> void:
	_overlay_active = active

	if active and _timer_running:
		_elapsed_ms = max(0, Time.get_ticks_msec() - _start_ms)
		_timer_running = false
		_timer_paused = true
	elif (not active) and _timer_paused and (not _level_finished):
		_timer_running = true
		_start_ms = Time.get_ticks_msec() - _elapsed_ms
		_timer_paused = false

	if power_washer != null:
		power_washer.visible = not active
		if power_washer.has_method("stop_spraying"):
			power_washer.call("stop_spraying")

	if water_vfx != null:
		if active:
			if water_vfx.has_method("stop_and_hide"):
				water_vfx.call("stop_and_hide")
			else:
				water_vfx.visible = false
				water_vfx.set_process(false)
		else:
			water_vfx.visible = true
			water_vfx.set_process(true)

	if mask_cleaning != null:
		mask_cleaning.set_process(not active)


func _on_pause_pressed() -> void:
	if _level_finished:
		return
	pause_requested.emit()
