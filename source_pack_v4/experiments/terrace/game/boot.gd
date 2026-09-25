extends Node
func _ready() -> void:
	# Export templates omit the editor --script flag. QA explicitly supplies an external
	# SceneTree harness; no tests are bundled and ordinary launches never take this path.
	if "--test" in OS.get_cmdline_user_args():
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--qa-script="):
				var script = load(argument.trim_prefix("--qa-script="))
				if script == null:
					get_tree().quit(2)
					return
				get_tree().set_script(script)
				get_tree().call_deferred("_initialize")
				return
	get_tree().change_scene_to_file.call_deferred("res://lab/journey.tscn")
