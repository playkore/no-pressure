extends Control

@export_range(2, 12, 1) var segment_count := 6:
	set(value):
		segment_count = value
		queue_redraw()

@export var line_color := Color(0.2, 0.35, 0.12, 0.7)
@export_range(1.0, 8.0, 1.0) var line_width := 4.0
@export_range(0.0, 64.0, 1.0) var inset := 12.0


func _draw() -> void:
	if segment_count <= 1:
		return

	var r := Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0)
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return

	for i in range(1, segment_count):
		var t := float(i) / float(segment_count)
		var x := r.position.x + r.size.x * t
		draw_line(Vector2(x, r.position.y), Vector2(x, r.position.y + r.size.y), line_color, line_width, true)

