extends Control

func _ready() -> void:
	# Keyboard navigation only works once something has focus.
	# Start on the dino that was played last.
	for dino_button in %Dinos.get_children():
		if dino_button.problem_type == GlobalConfig.problem_type:
			dino_button.grab_focus()

func _on_dino_selected(problem_type: Constants.ProblemType) -> void:
	GlobalConfig.set_problem_type(problem_type)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
