extends Control

func _ready() -> void:
	_show_language_button()
	# Keyboard navigation only works once something has focus.
	# Start on the knight that was played last.
	for knight_button in %Knights.get_children():
		if knight_button.problem_type == GlobalConfig.problem_type:
			knight_button.grab_focus()

func _on_knight_selected(problem_type: Constants.ProblemType) -> void:
	GlobalConfig.set_problem_type(problem_type)
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_language_button_pressed() -> void:
	GlobalConfig.set_language("en" if GlobalConfig.language == "da" else "da")
	_show_language_button()

# The button names the language it switches to, in that language
func _show_language_button() -> void:
	%LanguageButton.text = "English" if GlobalConfig.language == "da" else "Dansk"
