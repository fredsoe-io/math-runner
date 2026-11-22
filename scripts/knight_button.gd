extends Button
## A knight you can pick in the main menu. There is one for each problem type.

signal knight_selected(problem_type: Constants.ProblemType)

@export var problem_type: Constants.ProblemType
@export var knight_name: String
@export var symbol: String

func _ready() -> void:
	$VBoxContainer/NameLabel.text = knight_name
	$VBoxContainer/SymbolLabel.text = symbol
	$VBoxContainer/KnightSlot/Knight.hue_shift = GlobalConfig.get_knight_hue_shift(problem_type)
	$VBoxContainer/KnightSlot/Knight.weapon = GlobalConfig.get_weapon(problem_type)

func _pressed() -> void:
	knight_selected.emit(problem_type)

# Connected to mouse_entered and focus_entered: show off the weapon
func _on_hovered() -> void:
	$VBoxContainer/KnightSlot/Knight.swing()
