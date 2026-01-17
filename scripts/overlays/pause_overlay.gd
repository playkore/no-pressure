extends CanvasLayer

var _app: Node

@onready var _continue: Button = %Continue
@onready var _levels: Button = %Levels


func set_app(app: Node) -> void:
	_app = app


func _ready() -> void:
	_continue.pressed.connect(_on_continue)
	_levels.pressed.connect(_on_levels)


func _on_continue() -> void:
	if _app != null and _app.has_method("hide_pause_menu"):
		_app.call("hide_pause_menu")
	queue_free()


func _on_levels() -> void:
	if _app != null and _app.has_method("go_to_level_select"):
		_app.call("go_to_level_select")
	queue_free()

