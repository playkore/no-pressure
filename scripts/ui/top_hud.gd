extends CanvasLayer

signal pause_pressed

@export var cleaning_path: NodePath
@export var timer_path: NodePath

@onready var _money_label: Label = %MoneyLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _pause_button: BaseButton = %PauseButton

var _timer_node: Node


func _ready() -> void:
	_money_label.text = "0.0s"
	set_progress(0.0)
	_pause_button.pressed.connect(func() -> void: pause_pressed.emit())

	if cleaning_path != NodePath():
		var cleaning := get_node_or_null(cleaning_path)
		if cleaning != null:
			if cleaning.has_signal("progress_changed"):
				cleaning.progress_changed.connect(_on_progress_changed)
			if cleaning.has_method("get_progress_ratio"):
				set_progress(float(cleaning.call("get_progress_ratio")))

	if timer_path != NodePath():
		_timer_node = get_node_or_null(timer_path)


func _process(_delta: float) -> void:
	if _timer_node == null:
		return
	if _timer_node.has_method("get_elapsed_seconds"):
		var seconds := float(_timer_node.call("get_elapsed_seconds"))
		_money_label.text = "%.1fs" % seconds


func set_progress(ratio: float) -> void:
	_progress_bar.value = clampf(ratio, 0.0, 1.0)


func _on_progress_changed(ratio: float) -> void:
	set_progress(ratio)
