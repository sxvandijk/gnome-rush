extends Node
## Autoload "Game": which level is being played and scene switching. Saved
## progress and the level map come in M4.

const RUN_SCENE := "res://game/scenes/run.tscn"
const SELECT_SCENE := "res://game/scenes/level_select.tscn"

var current_level := 1


func _ready() -> void:
	# Development: `godot -- --level=25` starts straight in level 25
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			play.call_deferred(int(arg.get_slice("=", 1)))


func play(n: int) -> void:
	current_level = clampi(n, 1, LevelLoader.LEVEL_COUNT)
	get_tree().change_scene_to_file(RUN_SCENE)


func has_next() -> bool:
	return current_level < LevelLoader.LEVEL_COUNT


func play_next() -> void:
	play(current_level + 1)


func show_levels() -> void:
	get_tree().change_scene_to_file(SELECT_SCENE)
