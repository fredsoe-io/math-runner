extends Node

var correct_answer: int
var is_top_correct: bool
var answer_chosen: bool = false

func initialize(question: Question, position: float) -> void:
	correct_answer = question.correct_answer
	set_formular(question.text)
	randomize_answers(question)
	set_position(position)

func randomize_answers(question: Question) -> void:
	# Randomly decide if top or bottom gets correct answer
	is_top_correct = randf() < 0.5

	if is_top_correct:
		set_top_answer(question.correct_answer)
		set_bottom_answer(question.incorrect_answer)
	else:
		set_top_answer(question.incorrect_answer)
		set_bottom_answer(question.correct_answer)

func set_top_answer(value: int):
	$AnswerTop/Label.text = str(value)
	
func set_bottom_answer(value: int):
	$AnswerBottom/Label.text = str(value)

func set_formular(value: String):
	$Formular.text = value

func set_position(value: float):
	$AnswerTop.position.x = value + GlobalConfig.head_start_range
	$AnswerBottom.position.x = value + GlobalConfig.head_start_range
	$Formular.position.x = value

func move(delta: float, speed: float):
	$AnswerTop.position.x -= speed * delta * 0.25
	$AnswerBottom.position.x -= speed * delta * 0.25
	$Formular.position.x += speed * delta

func get_position() -> Vector2:
	return $AnswerBottom.position

func _on_answer_top_body_entered(_body: Node2D) -> void:
	if answer_chosen:
		return
	answer_chosen = true
	get_tree().root.get_node("Main").report_score(is_top_correct, correct_answer)
	show_result(is_top_correct)
func _on_answer_bottom_body_entered(_body: Node2D) -> void:
	if answer_chosen:
		return
	answer_chosen = true
	get_tree().root.get_node("Main").report_score(!is_top_correct, correct_answer)
	show_result(!is_top_correct)

func show_result(chose_correct: bool):
	var correct = $AnswerTop if is_top_correct else $AnswerBottom
	var wrong = $AnswerBottom if is_top_correct else $AnswerTop

	wrong.visible = false
	if chose_correct:
		# The correct number explodes: 3 bursts on top of each other, 0.1 s apart.
		# Spawned on the camera so they stay on screen
		correct.visible = false
		for i in 3:
			ParticleSpawner.spawn_burst(get_viewport().get_camera_2d(), correct.global_position, Color.GOLD, 14, 300, 8, i * 0.1)
	else:
		# Show what the right answer was
		correct.scale = Vector2(1.5, 1.5)
