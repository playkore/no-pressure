extends Node2D

@export_range(1.0, 256.0, 1.0, "or_greater") var contact_radius_px := 20.0:
	set(value):
		contact_radius_px = value
		_apply_contact_radius()

@onready var water_contact: Area2D = $WaterContact
@onready var water_contact_shape: CollisionShape2D = $WaterContact/CollisionShape2D

var has_target := false
var target_point := Vector2.ZERO


func _ready() -> void:
	scale = Vector2.ONE
	rotation = 0.0
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
	var delta := target_point - water_contact.global_position
	global_position += delta


func _apply_contact_radius() -> void:
	if water_contact_shape == null:
		return
	var circle := water_contact_shape.shape as CircleShape2D
	if circle == null:
		circle = CircleShape2D.new()
		water_contact_shape.shape = circle
	circle.radius = contact_radius_px
