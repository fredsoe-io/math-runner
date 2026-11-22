extends Control

func _ready() -> void:
	# Keyboard navigation only works once something has focus.
	# Start on the knight that was played last.
	for knight_button in %Knights.get_children():
		if knight_button.problem_type == GlobalConfig.problem_type:
			knight_button.grab_focus()

func _on_knight_selected(problem_type: Constants.ProblemType) -> void:
	GlobalConfig.set_problem_type(problem_type)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
