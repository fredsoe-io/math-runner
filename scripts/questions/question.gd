class_name Question
extends RefCounted
## One question: the text to show and its two possible answers.
## Whoever displays it decides which answer goes on top and which on the bottom.

var text: String
var correct_answer: int
var incorrect_answer: int

func _init(new_text: String, new_correct_answer: int, new_incorrect_answer: int) -> void:
	text = new_text
	correct_answer = new_correct_answer
	incorrect_answer = new_incorrect_answer
