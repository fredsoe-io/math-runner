extends Node

# Player physics
var gravity: float = 2500.0
var jump_velocity: float = -1200.0

# Problem generation
var problem_type: Constants.ProblemType = Constants.ProblemType.ADDITION
var head_start_range: float = 1500.0
var answer_range: int = 5 # Maximum difference between correct and wrong answer
# Multiplication gives bigger numbers, so its wrong answer is further off
var multiplication_min_answer_distance: int = 3
var multiplication_answer_range: int = 10
var number_range_min: int = 0
var number_range_max: int = 10
var avoid_negative_numbers: bool = true
var question_generator: QuestionGenerator # The one the game asks for questions

# Knights
# Each problem type has its own knight color and weapon. The color is the
# hue_shift for knight_color.gdshader (0.0 = the original red knight)
var knight_hue_shifts: Dictionary = {
	Constants.ProblemType.ADDITION: 0.0,
	Constants.ProblemType.SUBTRACTION: 0.6,
	Constants.ProblemType.MULTIPLICATION: 0.3,
	Constants.ProblemType.DIVISION: 0.8,
}
var weapons: Dictionary = {
	Constants.ProblemType.ADDITION: Weapon.Kind.SWORD,
	Constants.ProblemType.SUBTRACTION: Weapon.Kind.SPEAR,
	Constants.ProblemType.MULTIPLICATION: Weapon.Kind.MACE,
	Constants.ProblemType.DIVISION: Weapon.Kind.AXE,
}

# Scoreboard (github.com/fredsoe-io/scoreboard), one board per knight.
# On the web the game uses the site it was loaded from. Set scoreboard_url to
# e.g. "http://localhost:8000" to try it from the editor; empty = off there.
var scoreboard_url: String = ""
var scoreboard_boards: Dictionary = {
	Constants.ProblemType.ADDITION: "addition",
	Constants.ProblemType.SUBTRACTION: "subtraction",
	Constants.ProblemType.MULTIPLICATION: "multiplication",
	Constants.ProblemType.DIVISION: "division",
}

# Game balance
# The scoreboard rejects scores higher than these rules allow for the time
# played (games.py in the scoreboard repo), so update it when they change
var initial_lives: int = 3
var initial_speed: float = 300.0
var max_speed: float = 1000.0
var acceleration: float = 5.0 # Speed increase per second
var speed_multiplier_step: float = 100.0 # Every 100 speed increase adds 1x to multiplier
var score_per_second: float = 1.0

# UI Settings
var life_size: Vector2 = Vector2(24, 24)

func _ready() -> void:
	question_generator = create_question_generator(problem_type)

func set_problem_type(type: Constants.ProblemType) -> void:
	print("Setting problem type to: ", type)
	problem_type = type
	question_generator = create_question_generator(type)

func get_knight_hue_shift(type: Constants.ProblemType = problem_type) -> float:
	return knight_hue_shifts[type]

func get_weapon(type: Constants.ProblemType = problem_type) -> Weapon.Kind:
	return weapons[type]

func get_scoreboard_board(type: Constants.ProblemType = problem_type) -> String:
	return scoreboard_boards[type]

func create_question_generator(type: Constants.ProblemType) -> QuestionGenerator:
	var generator: QuestionGenerator
	match type:
		Constants.ProblemType.SUBTRACTION:
			generator = SubtractionGenerator.new(number_range_min, number_range_max)
		Constants.ProblemType.MULTIPLICATION:
			generator = MultiplicationGenerator.new(number_range_min, number_range_max)
		Constants.ProblemType.DIVISION:
			generator = DivisionGenerator.new(number_range_min, number_range_max)
		_:
			generator = AdditionGenerator.new(number_range_min, number_range_max)
	generator.answer_range = answer_range
	generator.avoid_negative_numbers = avoid_negative_numbers
	if type == Constants.ProblemType.MULTIPLICATION:
		generator.min_answer_distance = multiplication_min_answer_distance
		generator.answer_range = multiplication_answer_range
	return generator
