extends CanvasLayer

var _app: Node

@onready var _stars: Label = %Stars
@onready var _time: Label = %Time
@onready var _retry: Button = %Retry
@onready var _levels: Button = %Levels
@onready var _continue: Button = %Continue


func set_app(app: Node) -> void:
	_app = app


func _ready() -> void:
	_retry.pressed.connect(_on_retry)
	_levels.pressed.connect(_on_levels)
	_continue.pressed.connect(_on_continue)


func setup(time_ms: int, stars: int) -> void:
	_stars.text = _format_stars(stars)
	_time.text = "Time: %s" % _format_time(time_ms)


func _on_retry() -> void:
	if _app != null and _app.has_method("restart_level"):
		_app.call("restart_level")
	queue_free()


func _on_levels() -> void:
	if _app != null and _app.has_method("go_to_level_select"):
		_app.call("go_to_level_select")
	queue_free()


func _on_continue() -> void:
	if _app != null and _app.has_method("go_to_level_select"):
		_app.call("go_to_level_select")
	queue_free()


func _format_stars(stars: int) -> String:
	stars = clampi(stars, 0, 3)
	return "★".repeat(stars) + "☆".repeat(3 - stars)


func _format_time(ms: int) -> String:
	if ms <= 0:
		return "—"
	return "%.2fs" % (float(ms) / 1000.0)

