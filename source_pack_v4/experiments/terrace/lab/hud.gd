extends CanvasLayer
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused and event.is_action_pressed("pause"):
		get_parent().resume_game()
		get_viewport().set_input_as_handled()
