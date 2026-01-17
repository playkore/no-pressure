extends Node2D

signal level_completed(time_ms: int, stars: int)

@export var initial_powerwasher_anchor := Vector2(0.78, 0.78)
@export_range(0, 600000, 100, "or_greater") var stars_threshold_3_ms := 25000
@export_range(0, 600000, 100, "or_greater") var stars_threshold_2_ms := 45000

@onready var clean: Sprite2D = $Clean
@onready var dirty: Sprite2D = $Dirty
@onready var power_washer: Node2D = $PowerWasher
@onready var mask_cleaning: Node = $MaskCleaning

var _timer_running := false
var _start_ms := 0


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)
	if mask_cleaning != null:
		mask_cleaning.connect("level_completed", Callable(self, "_on_level_completed"))


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

	var scale_factor := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	clean.scale = Vector2.ONE * scale_factor
	dirty.scale = Vector2.ONE * scale_factor
	clean.global_position = viewport_size * 0.5
	dirty.global_position = viewport_size * 0.5


func _process(_delta: float) -> void:
	if _timer_running:
		return
	if power_washer.has_method("is_spraying") and bool(power_washer.call("is_spraying")):
		_timer_running = true
		_start_ms = Time.get_ticks_msec()


func _on_level_completed() -> void:
	var time_ms := 0
	if _timer_running:
		time_ms = max(0, Time.get_ticks_msec() - _start_ms)
	var stars := _compute_stars(time_ms)
	level_completed.emit(time_ms, stars)


func _compute_stars(time_ms: int) -> int:
	if time_ms <= 0:
		return 1
	if time_ms <= stars_threshold_3_ms:
		return 3
	if time_ms <= stars_threshold_2_ms:
		return 2
	return 1
