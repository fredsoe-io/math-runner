extends Button
## A dino you can pick in the main menu. There is one for each problem type.

signal dino_selected(problem_type: Constants.ProblemType)

@export var problem_type: Constants.ProblemType
@export var dino_name: String
@export var symbol: String

func _ready() -> void:
	$VBoxContainer/NameLabel.text = dino_name
	$VBoxContainer/SymbolLabel.text = symbol
	$VBoxContainer/Dino.material.set_shader_parameter("hue_shift", GlobalConfig.get_dino_hue_shift(problem_type))

func _pressed() -> void:
	dino_selected.emit(problem_type)
