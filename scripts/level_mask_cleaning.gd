extends Node

signal level_completed
signal progress_changed(ratio: float)

@export_range(0.0, 1.0, 0.001) var completion_ratio := 0.95
@export_range(0.0, 5000.0, 1.0, "or_greater") var water_strength_grades_per_second := 1000.0

@export var dirty_sprite_path: NodePath
@export var clean_sprite_path: NodePath

@export var power_washer_path: NodePath
@export var water_contact_path: NodePath

var level_complete := false

var _mask_image: Image
var _mask_texture: ImageTexture
var _total_pixels := 0
var _clean_pixels := 0
var _progress_ratio := 0.0

@onready var _dirty_sprite: Sprite2D = get_node(dirty_sprite_path)
@onready var _clean_sprite: Sprite2D = get_node(clean_sprite_path)
@onready var _power_washer: Node = get_node(power_washer_path)
@onready var _water_contact: Node2D = get_node(water_contact_path)


func _ready() -> void:
	_setup_mask()
	_setup_material()


func _process(delta: float) -> void:
	if level_complete:
		return
	if not _is_spraying():
		return
	if delta <= 0.0:
		return

	var changed := _apply_water(delta)
	if changed:
		_mask_texture.update(_mask_image)
		_update_progress()
		_check_completion()


func _setup_mask() -> void:
	if _dirty_sprite.texture == null:
		push_error("Dirty sprite has no texture.")
		return

	var size := _dirty_sprite.texture.get_size()
	_mask_image = Image.create(size.x, size.y, false, Image.FORMAT_L8)
	_mask_image.fill(Color(0, 0, 0))
	_mask_texture = ImageTexture.create_from_image(_mask_image)
	_total_pixels = int(size.x * size.y)
	_clean_pixels = 0


func _setup_material() -> void:
	var mat := _dirty_sprite.material as ShaderMaterial
	if mat == null:
		push_error("Dirty sprite material must be a ShaderMaterial (dirty_reveal.gdshader).")
		return

	mat.set_shader_parameter("clean_tex", _clean_sprite.texture)
	mat.set_shader_parameter("mask_tex", _mask_texture)


func _apply_water(delta: float) -> bool:
	if _mask_image == null or _dirty_sprite.texture == null:
		return false

	var contact_screen := _water_contact.global_position

	var contact_local := _dirty_sprite.to_local(contact_screen)
	var tex_size := _dirty_sprite.texture.get_size()
	var contact_tex := contact_local + tex_size * 0.5

	if contact_tex.x < 0.0 or contact_tex.y < 0.0 or contact_tex.x >= tex_size.x or contact_tex.y >= tex_size.y:
		return false

	var scale_x := absf(_dirty_sprite.global_scale.x)
	if scale_x <= 0.0001:
		return false

	var contact_radius_screen := _get_contact_radius_screen()
	var radius_tex := contact_radius_screen / scale_x
	if radius_tex <= 0.0:
		return false

	var center_x: int = int(contact_tex.x)
	var center_y: int = int(contact_tex.y)
	var r: int = ceili(radius_tex)
	var min_x: int = maxi(0, center_x - r)
	var max_x: int = mini(tex_size.x - 1, center_x + r)
	var min_y: int = maxi(0, center_y - r)
	var max_y: int = mini(tex_size.y - 1, center_y + r)

	var max_dist := radius_tex
	var base_add := water_strength_grades_per_second * delta
	var changed := false

	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx := float(x) - contact_tex.x
			var dy := float(y) - contact_tex.y
			var dist := sqrt(dx * dx + dy * dy)
			if dist > max_dist:
				continue

			var t := clampf(dist / max_dist, 0.0, 1.0)
			var influence := pow(1.0 - t, 2.0)
			var add_f := base_add * influence
			var add := int(add_f + 0.5)
			if add <= 0:
				continue

			var old_v := int(_mask_image.get_pixel(x, y).r * 255.0 + 0.5)
			if old_v >= 255:
				continue

			var new_v: int = mini(255, old_v + add)
			if new_v == old_v:
				continue

			_mask_image.set_pixel(x, y, Color(new_v / 255.0, 0, 0))
			if old_v < 255 and new_v >= 255:
				_clean_pixels += 1
			changed = true

	return changed


func _check_completion() -> void:
	if _total_pixels <= 0:
		return
	var ratio := float(_clean_pixels) / float(_total_pixels)
	if ratio >= completion_ratio:
		level_complete = true
		level_completed.emit()


func _update_progress() -> void:
	if _total_pixels <= 0:
		return
	var ratio := float(_clean_pixels) / float(_total_pixels)
	if absf(ratio - _progress_ratio) < 0.0001:
		return
	_progress_ratio = ratio
	progress_changed.emit(_progress_ratio)


func get_progress_ratio() -> float:
	return _progress_ratio


func _is_spraying() -> bool:
	if _power_washer.has_method("is_spraying"):
		return _power_washer.call("is_spraying")
	return false


func _get_contact_radius_screen() -> float:
	if _power_washer.has_method("get_contact_radius_px"):
		return float(_power_washer.call("get_contact_radius_px"))
	return 20.0
