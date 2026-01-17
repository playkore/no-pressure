extends Node2D

@export var initial_powerwasher_anchor := Vector2(0.78, 0.78)

@onready var background: Sprite2D = $Background
@onready var power_washer: Sprite2D = $PowerWasher


func _ready() -> void:
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size == Vector2.ZERO:
		return

	_fit_background(viewport_size)
	power_washer.global_position = viewport_size * initial_powerwasher_anchor
	power_washer.scale = Vector2.ONE
	power_washer.rotation = 0.0


func _fit_background(viewport_size: Vector2) -> void:
	var tex := background.texture
	if tex == null:
		return

	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var scale_factor := maxf(viewport_size.x / tex_size.x, viewport_size.y / tex_size.y)
	background.scale = Vector2.ONE * scale_factor
	background.global_position = viewport_size * 0.5
