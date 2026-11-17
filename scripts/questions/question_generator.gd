class_name QuestionGenerator
extends RefCounted
## Base class for the question types (the "strategy").
## To plug in a new type: extend this class and override generate_question().

var min_value: int
var max_value: int
var answer_range: int = 5 # Maximum difference between correct and wrong answer
var min_answer_distance: int = 1 # Minimum difference between correct and wrong answer
var avoid_negative_numbers: bool = true

func _init(new_min_value: int = 0, new_max_value: int = 10) -> void:
	min_value = new_min_value
	max_value = new_max_value

func generate_question() -> Question:
	push_error("generate_question() must be overridden")
	return null

func random_number() -> int:
	return randi_range(min_value, max_value)

# Builds a question with a wrong answer close to the correct one
func make_question(text: String, correct_answer: int) -> Question:
	return Question.new(text, correct_answer, make_incorrect_answer(correct_answer))

func make_incorrect_answer(correct_answer: int) -> int:
	# Generate wrong answer within ±range of correct answer, but not too close
	var incorrect_answer = correct_answer
	while abs(incorrect_answer - correct_answer) < min_answer_distance or (avoid_negative_numbers and incorrect_answer < 0):
		incorrect_answer = correct_answer + randi_range(-answer_range, answer_range)
	return incorrect_answer
