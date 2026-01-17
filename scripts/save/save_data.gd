extends Node

const SAVE_PATH := "user://save.cfg"
const SECTION_LEVELS := "levels"

var _cfg := ConfigFile.new()


func _ready() -> void:
	_cfg.load(SAVE_PATH)


func get_level_progress(level_id: String) -> Dictionary:
	var key := "level_%s" % level_id
	var data := _cfg.get_value(SECTION_LEVELS, key, {}) as Dictionary
	return {
		"best_stars": int(data.get("best_stars", 0)),
		"best_time_ms": int(data.get("best_time_ms", 0)),
	}


func set_level_result(level_id: String, stars: int, time_ms: int) -> void:
	stars = clampi(stars, 0, 3)
	time_ms = maxi(time_ms, 0)

	var prev := get_level_progress(level_id)
	var best_stars := maxi(int(prev.get("best_stars", 0)), stars)

	var prev_time := int(prev.get("best_time_ms", 0))
	var best_time_ms := prev_time
	if prev_time <= 0:
		best_time_ms = time_ms
	elif time_ms > 0 and time_ms < prev_time:
		best_time_ms = time_ms

	var key := "level_%s" % level_id
	_cfg.set_value(SECTION_LEVELS, key, {
		"best_stars": best_stars,
		"best_time_ms": best_time_ms,
	})
	_cfg.save(SAVE_PATH)

