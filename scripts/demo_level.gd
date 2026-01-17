extends Node2D

@export var initial_powerwasher_anchor := Vector2(0.78, 0.78)

@onready var clean: Sprite2D = $Clean
@onready var dirty: Sprite2D = $Dirty
@onready var power_washer: Node2D = $PowerWasher


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)


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
