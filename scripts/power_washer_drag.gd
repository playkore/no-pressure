extends Sprite2D

@export var nozzle_offset_px := Vector2(70, 160)
@export var nozzle_to_target_offset := Vector2(260, 340)
@export var right_edge_margin_px := 0.0

var has_target := false
var target_point := Vector2.ZERO


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


func _ready() -> void:
	scale = Vector2.ONE
	rotation = 0.0
	centered = false


func _set_target(pos: Vector2) -> void:
	var viewport_rect := get_viewport().get_visible_rect()
	target_point = Vector2(
		clampf(pos.x, viewport_rect.position.x, viewport_rect.end.x),
		clampf(pos.y, viewport_rect.position.y, viewport_rect.end.y)
	)
	_apply_translation_only_placement(viewport_rect)


func _apply_translation_only_placement(viewport_rect: Rect2) -> void:
	var desired_nozzle := target_point + nozzle_to_target_offset
	global_position = desired_nozzle - nozzle_offset_px

	if texture == null:
		return
	var tex_size := texture.get_size() * global_scale.abs()
	var right_edge_x := global_position.x + tex_size.x
	var min_right_edge_x := viewport_rect.end.x + right_edge_margin_px
	if right_edge_x < min_right_edge_x:
		global_position.x += min_right_edge_x - right_edge_x
