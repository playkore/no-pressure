extends Node2D

@export var power_washer_path: NodePath
@export var nozzle_path: NodePath
@export var water_contact_path: NodePath

@export_range(0.0, 64.0, 1.0, "or_greater") var main_width_px := 18.0
@export_range(0.0, 64.0, 1.0, "or_greater") var glow_width_px := 34.0
@export_range(0.0, 64.0, 1.0, "or_greater") var jet_width_px := 6.0
@export_range(0, 8, 1) var jet_count := 4
@export_range(0.0, 64.0, 1.0, "or_greater") var jet_jitter_px := 10.0

@export_range(0.0, 128.0, 1.0, "or_greater") var impact_radius_px := 22.0
@export_range(0.0, 512.0, 1.0, "or_greater") var droplet_spawn_per_second := 120.0
@export_range(0.0, 1024.0, 1.0, "or_greater") var droplet_speed_min := 80.0
@export_range(0.0, 2048.0, 1.0, "or_greater") var droplet_speed_max := 240.0
@export_range(0.05, 2.0, 0.01) var droplet_life_min := 0.18
@export_range(0.05, 3.0, 0.01) var droplet_life_max := 0.45
@export_range(0.0, 128.0, 1.0, "or_greater") var droplet_radius_min := 2.0
@export_range(0.0, 128.0, 1.0, "or_greater") var droplet_radius_max := 5.0
@export_range(0, 512, 1) var max_droplets := 140
@export_range(0.0, 3.14159, 0.01) var emit_cone_radians := 0.8

var _rng := RandomNumberGenerator.new()
var _spawn_accum := 0.0
var _jet_offsets: PackedFloat32Array = PackedFloat32Array()

var _power_washer: Node
var _nozzle: Node2D
var _water_contact: Node2D


class Droplet:
	var pos: Vector2
	var vel: Vector2
	var age: float
	var life: float
	var radius: float


var _droplets: Array[Droplet] = []


func _ready() -> void:
	_rng.randomize()
	_power_washer = get_node_or_null(power_washer_path)
	_nozzle = get_node_or_null(nozzle_path) as Node2D
	_water_contact = get_node_or_null(water_contact_path) as Node2D

	visible = false
	_sync_jet_offsets()


func _process(delta: float) -> void:
	if delta <= 0.0:
		return

	_sync_jet_offsets()
	_update_jet_offsets(delta)
	_update_droplets(delta)
	_spawn_droplets(delta)

	visible = _is_spraying() or not _droplets.is_empty()
	if visible:
		queue_redraw()


func _draw() -> void:
	if _nozzle == null or _water_contact == null:
		return

	var nozzle_pos := to_local(_nozzle.global_position)
	var contact_pos := to_local(_water_contact.global_position)
	var v := contact_pos - nozzle_pos
	var len := v.length()
	if len < 2.0:
		return

	var dir := v / len
	var perp := Vector2(-dir.y, dir.x)

	var glow_col := Color(0.60, 0.85, 1.0, 0.22)
	var main_col := Color(0.92, 0.97, 1.0, 0.55)
	var jet_col := Color(1.0, 1.0, 1.0, 0.45)

	draw_line(nozzle_pos, contact_pos, glow_col, glow_width_px, true)
	draw_line(nozzle_pos, contact_pos, main_col, main_width_px, true)

	for i in range(_jet_offsets.size()):
		var o := _jet_offsets[i]
		var from := nozzle_pos + perp * (o * 0.2)
		var to := contact_pos + perp * o
		draw_line(from, to, jet_col, jet_width_px, true)

	draw_circle(contact_pos, impact_radius_px, Color(0.92, 0.97, 1.0, 0.10))
	draw_arc(contact_pos, impact_radius_px + 7.0, 0.0, TAU, 28, Color(0.92, 0.97, 1.0, 0.20), 4.0, true)

	for d in _droplets:
		var t := clampf(d.age / d.life, 0.0, 1.0)
		var a := (1.0 - t)
		var col := Color(0.90, 0.97, 1.0, a * 0.55)
		draw_circle(to_local(d.pos), d.radius, col)


func _sync_jet_offsets() -> void:
	var desired := maxi(0, jet_count)
	if _jet_offsets.size() == desired:
		return

	_jet_offsets = PackedFloat32Array()
	_jet_offsets.resize(desired)
	for i in range(desired):
		_jet_offsets[i] = _rng.randf_range(-jet_jitter_px, jet_jitter_px)


func _update_jet_offsets(delta: float) -> void:
	if _jet_offsets.is_empty():
		return

	var lerp_t := clampf(delta * 10.0, 0.0, 1.0)
	for i in range(_jet_offsets.size()):
		var target := _rng.randf_range(-jet_jitter_px, jet_jitter_px)
		_jet_offsets[i] = lerpf(_jet_offsets[i], target, lerp_t)


func _spawn_droplets(delta: float) -> void:
	if not _is_spraying():
		return
	if _nozzle == null or _water_contact == null:
		return
	if droplet_spawn_per_second <= 0.0:
		return

	_spawn_accum += droplet_spawn_per_second * delta
	var count := int(_spawn_accum)
	if count <= 0:
		return
	_spawn_accum -= float(count)

	var nozzle_pos := _nozzle.global_position
	var contact_pos := _water_contact.global_position
	var stream_v := contact_pos - nozzle_pos
	var stream_len := stream_v.length()
	if stream_len < 2.0:
		return

	var stream_dir := stream_v / stream_len
	var base_dir := -stream_dir

	for _i in range(count):
		if _droplets.size() >= max_droplets:
			break

		var d := Droplet.new()
		var ang := _rng.randf_range(-emit_cone_radians, emit_cone_radians)
		var dir := base_dir.rotated(ang)
		var speed := _rng.randf_range(droplet_speed_min, droplet_speed_max)

		d.pos = contact_pos + Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-6.0, 6.0))
		d.vel = dir * speed
		d.age = 0.0
		d.life = _rng.randf_range(droplet_life_min, droplet_life_max)
		d.radius = _rng.randf_range(droplet_radius_min, droplet_radius_max)
		_droplets.append(d)


func _update_droplets(delta: float) -> void:
	if _droplets.is_empty():
		return

	var damping := pow(0.08, delta)
	for i in range(_droplets.size() - 1, -1, -1):
		var d := _droplets[i]
		d.age += delta
		if d.age >= d.life:
			_droplets.remove_at(i)
			continue
		d.pos += d.vel * delta
		d.vel *= damping


func _is_spraying() -> bool:
	if _power_washer != null and _power_washer.has_method("is_spraying"):
		return bool(_power_washer.call("is_spraying"))
	return false


func stop_and_hide() -> void:
	_droplets.clear()
	_spawn_accum = 0.0
	visible = false
	set_process(false)
