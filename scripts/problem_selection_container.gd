extends GridContainer


func _on_select_addition_pressed() -> void:
	GlobalConfig.set_problem_type(Constants.ProblemType.ADDITION)


func _on_select_subtraction_pressed() -> void:
	GlobalConfig.set_problem_type(Constants.ProblemType.SUBTRACTION)


func _on_select_division_pressed() -> void:
	GlobalConfig.set_problem_type(Constants.ProblemType.DIVISION)


func _on_select_multiplication_pressed() -> void:
	GlobalConfig.set_problem_type(Constants.ProblemType.MULTIPLICATION)
