extends CanvasLayer

@export var cleaning_path: NodePath
@export var initial_money := 3270

@onready var _money_label: Label = %MoneyLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	set_money(initial_money)
	set_progress(0.0)

	if cleaning_path != NodePath():
		var cleaning := get_node_or_null(cleaning_path)
		if cleaning != null:
			if cleaning.has_signal("progress_changed"):
				cleaning.progress_changed.connect(_on_progress_changed)
			if cleaning.has_method("get_progress_ratio"):
				set_progress(float(cleaning.call("get_progress_ratio")))


func set_money(value: int) -> void:
	_money_label.text = _format_money(value)


func set_progress(ratio: float) -> void:
	_progress_bar.value = clampf(ratio, 0.0, 1.0)


func _on_progress_changed(ratio: float) -> void:
	set_progress(ratio)


func _format_money(value: int) -> String:
	var s := str(maxi(value, 0))
	var out := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i != 0:
			out = "," + out
	return out
