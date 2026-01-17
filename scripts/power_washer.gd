extends Node2D

@export var nozzle_to_target_offset := Vector2(260, 340)
@export var right_edge_margin_px := 0.0

@export_range(1.0, 256.0, 1.0, "or_greater") var contact_radius_px := 20.0:
	set(value):
		contact_radius_px = value
		_apply_contact_radius()

@onready var sprite: Sprite2D = $Sprite
@onready var nozzle: Marker2D = $Nozzle
@onready var water_contact: Area2D = $WaterContact
@onready var water_contact_shape: CollisionShape2D = $WaterContact/CollisionShape2D

var has_target := false
var target_point := Vector2.ZERO


func _ready() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	sprite.scale = Vector2.ONE
	sprite.rotation = 0.0
	_apply_contact_radius()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
		return


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		has_target = true
		_set_target(event.position)
		return

	if has_target:
		has_target = false


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not has_target:
		return
	_set_target(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		has_target = true
		_set_target(event.position)
	else:
		has_target = false


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not has_target or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	_set_target(event.position)


func set_target_point(pos: Vector2) -> void:
	has_target = true
	_set_target(pos)


func _set_target(pos: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	target_point = Vector2(
		clampf(pos.x, viewport_rect.position.x, viewport_rect.end.x),
		clampf(pos.y, viewport_rect.position.y, viewport_rect.end.y)
	)

	_apply_translation_only_placement(viewport_rect)


func _apply_translation_only_placement(viewport_rect: Rect2) -> void:
	var desired_nozzle := target_point + nozzle_to_target_offset
	global_position = desired_nozzle - nozzle.position

	if sprite.texture == null:
		return
	var tex_size := sprite.texture.get_size() * sprite.global_scale.abs()
	var right_edge_x := global_position.x + tex_size.x
	var min_right_edge_x := viewport_rect.end.x + right_edge_margin_px
	if right_edge_x < min_right_edge_x:
		global_position.x += min_right_edge_x - right_edge_x


func _apply_contact_radius() -> void:
	if water_contact_shape == null:
		return
	var circle := water_contact_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		water_contact_shape.shape = circle
	circle.radius = contact_radius_px
